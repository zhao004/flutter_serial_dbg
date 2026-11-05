import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/ble_gatt.dart';
import '../../models/connection_config.dart';
import '../../models/transport_event.dart';
import '../../services/ble/ble_permission_service.dart';
import '../../services/ble/ble_gatt_resolver.dart';
import '../../services/ble/ble_gatt_session.dart';
import '../../utils/ble_uuid.dart';
import '../../utils/constants.dart';
import 'transport.dart';

/// BLE 通用透传 Transport。
///
/// 未指定 UUID 时自动选择首个可写特征，并优先搭配可用通知特征。当前按
/// FlutterBluePlus 的非营利许可模式实现；商业使用必须显式切换许可证。
final class BleTransport
    with TransportEventEmitter
    implements Transport, BleGattSession {
  factory BleTransport({required BlePermissionService permissionService}) {
    return BleTransport._(permissionService);
  }

  BleTransport._(this._permissionService);

  final BlePermissionService _permissionService;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  final Map<String, StreamSubscription<List<int>>> _gattNotifySubscriptions =
      <String, StreamSubscription<List<int>>>{};
  final Set<String> _notifiedCharacteristicKeys = <String>{};
  final StreamController<BleGattValue> _gattValueController =
      StreamController<BleGattValue>.broadcast(sync: true);
  List<BluetoothService> _services = const <BluetoothService>[];
  List<BleGattServiceInfo> _gattServices = const <BleGattServiceInfo>[];
  BleConfig? _config;
  bool _connected = false;
  bool _disposed = false;
  bool _disconnecting = false;
  bool _writeWithoutResponse = false;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _connected;

  @override
  List<BleGattServiceInfo> get gattServices => _gattServices;

  @override
  Stream<BleGattValue> get gattValues => _gattValueController.stream;

  @override
  Set<String> get notifiedGattKeys =>
      Set<String>.unmodifiable(_notifiedCharacteristicKeys);

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_disposed) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        '传输通道已释放',
      );
    }
    if (_connected || _device != null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 已经连接',
      );
    }
    if (config is! BleConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 配置类型不匹配',
      );
    }

    await _ensureReady();
    final device = BluetoothDevice.fromId(config.remoteId);
    _device = device;
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected && _connected) {
        _handleUnexpectedDisconnect('BLE 设备已断开');
      }
    });

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: BleDefaults.connectTimeout,
        mtu: null,
      );
      final services = await device.discoverServices(
        timeout: BleDefaults.connectTimeout.inSeconds,
      );
      _services = services;
      _gattServices = _buildGattServices(services);
      final selection = _resolveGatt(services, config);
      _writeCharacteristic = selection.write.value;
      _notifyCharacteristic = selection.notify?.value;
      _writeWithoutResponse =
          !selection.write.value.properties.write &&
          selection.write.value.properties.writeWithoutResponse;

      final notify = _notifyCharacteristic;
      if (notify != null) {
        final notifyKey = _characteristicKey(
          selection.service.value.serviceUuid.str,
          notify.characteristicUuid.str,
        );
        _notifiedCharacteristicKeys.add(notifyKey);
        _notifySubscription = notify.onValueReceived.listen(
          (data) {
            _emitGattValue(
              selection.service.value.serviceUuid.str,
              notify.characteristicUuid.str,
              data,
            );
            emitEvent(TransportDataReceived(bytes: Uint8List.fromList(data)));
          },
          onError: (Object error, StackTrace stackTrace) {
            emitEvent(const TransportFailure('BLE 通知数据接收异常'));
            unawaited(disconnect());
          },
        );
        await notify.setNotifyValue(true);
      }

      _config = BleConfig(
        remoteId: config.remoteId,
        serviceUuid: selection.service.value.serviceUuid.str,
        writeCharacteristicUuid: selection.write.value.characteristicUuid.str,
        notifyCharacteristicUuid: notify?.characteristicUuid.str,
      );
      _connected = true;
      final name = device.platformName.trim().isEmpty
          ? 'BLE 设备'
          : device.platformName.trim();
      emitEvent(TransportConnected(name));
    } catch (error) {
      await _cleanupDevice();
      if (error is TransportException) {
        rethrow;
      }
      throw const TransportException(
        TransportErrorKind.connection,
        'BLE 连接或服务发现失败',
      );
    }
  }

  Future<void> _ensureReady() async {
    final permission = await _permissionService.request();
    switch (permission) {
      case BlePermissionOutcome.granted:
        break;
      case BlePermissionOutcome.denied:
        throw const TransportException(
          TransportErrorKind.connection,
          'BLE 权限被拒绝，无法扫描或连接设备',
        );
      case BlePermissionOutcome.permanentlyDenied:
        throw const TransportException(
          TransportErrorKind.connection,
          'BLE 权限被永久拒绝，请在系统设置中启用',
        );
      case BlePermissionOutcome.unsupported:
        throw const TransportException(
          TransportErrorKind.unsupported,
          '当前设备或系统不支持 BLE',
        );
    }
    try {
      final adapterState = await FlutterBluePlus.adapterState.first.timeout(
        BleDefaults.connectTimeout,
      );
      if (adapterState != BluetoothAdapterState.on) {
        throw const TransportException(TransportErrorKind.connection, '蓝牙未开启');
      }
    } on TimeoutException {
      throw const TransportException(TransportErrorKind.connection, '读取蓝牙状态超时');
    }
  }

  BleGattSelection<BluetoothService, BluetoothCharacteristic> _resolveGatt(
    List<BluetoothService> services,
    BleConfig config,
  ) {
    return resolveBleGatt<BluetoothService, BluetoothCharacteristic>(
      services: services.map((service) {
        return BleGattServiceCandidate<
          BluetoothService,
          BluetoothCharacteristic
        >(
          value: service,
          uuid: service.serviceUuid.str,
          characteristics: service.characteristics
              .map((characteristic) {
                final properties = characteristic.properties;
                return BleGattCharacteristicCandidate<BluetoothCharacteristic>(
                  value: characteristic,
                  uuid: characteristic.characteristicUuid.str,
                  writable: properties.write || properties.writeWithoutResponse,
                  notifiable: properties.notify || properties.indicate,
                );
              })
              .toList(growable: false),
        );
      }),
      config: config,
    );
  }

  @override
  Future<void> send(Uint8List data) async {
    final characteristic = _writeCharacteristic;
    final device = _device;
    if (!_connected || characteristic == null || device == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 尚未连接',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    final chunkSize = math.max<int>(20, device.mtuNow - 3);
    try {
      for (var offset = 0; offset < data.length; offset += chunkSize) {
        final end = math.min<int>(offset + chunkSize, data.length);
        await characteristic.write(
          data.sublist(offset, end),
          withoutResponse: _writeWithoutResponse,
          timeout: BleDefaults.connectTimeout.inSeconds,
        );
      }
    } catch (_) {
      throw const TransportException(TransportErrorKind.send, 'BLE 特征写入失败');
    }
  }

  @override
  Future<BleGattValue> readGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final target = _findCharacteristic(serviceUuid, characteristicUuid);
    if (target == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 特征不存在或尚未完成服务发现',
      );
    }
    final properties = target.characteristic.properties;
    if (!properties.read) {
      throw const TransportException(
        TransportErrorKind.unsupported,
        '该 BLE 特征不支持读取',
      );
    }
    try {
      final data = await target.characteristic.read(
        timeout: BleDefaults.connectTimeout.inSeconds,
      );
      final value = BleGattValue(
        serviceUuid: target.service.serviceUuid.str,
        characteristicUuid: target.characteristic.characteristicUuid.str,
        bytes: Uint8List.fromList(data),
        receivedAt: DateTime.now(),
      );
      if (!_gattValueController.isClosed) {
        _gattValueController.add(value);
      }
      return value;
    } catch (_) {
      throw const TransportException(TransportErrorKind.receive, 'BLE 特征读取失败');
    }
  }

  @override
  Future<void> writeGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    final target = _findCharacteristic(serviceUuid, characteristicUuid);
    if (target == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 特征不存在或尚未完成服务发现',
      );
    }
    final properties = target.characteristic.properties;
    if (!properties.write && !properties.writeWithoutResponse) {
      throw const TransportException(
        TransportErrorKind.unsupported,
        '该 BLE 特征不支持写入',
      );
    }
    if (withResponse && !properties.write) {
      throw const TransportException(
        TransportErrorKind.unsupported,
        '该 BLE 特征不支持带响应写入',
      );
    }
    final device = _device;
    if (device == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 尚未连接',
      );
    }
    final chunkSize = math.max<int>(20, device.mtuNow - 3);
    try {
      for (var offset = 0; offset < data.length; offset += chunkSize) {
        final end = math.min<int>(offset + chunkSize, data.length);
        await target.characteristic.write(
          data.sublist(offset, end),
          withoutResponse: !withResponse,
          timeout: BleDefaults.connectTimeout.inSeconds,
        );
      }
    } catch (_) {
      throw const TransportException(TransportErrorKind.send, 'BLE 特征写入失败');
    }
  }

  @override
  Future<void> setGattNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    final target = _findCharacteristic(serviceUuid, characteristicUuid);
    if (target == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'BLE 特征不存在或尚未完成服务发现',
      );
    }
    final properties = target.characteristic.properties;
    if (!properties.notify && !properties.indicate) {
      throw const TransportException(
        TransportErrorKind.unsupported,
        '该 BLE 特征不支持通知或指示',
      );
    }

    final resolvedServiceUuid = target.service.serviceUuid.str;
    final resolvedCharacteristicUuid =
        target.characteristic.characteristicUuid.str;
    final key = _characteristicKey(
      resolvedServiceUuid,
      resolvedCharacteristicUuid,
    );
    if (!enabled) {
      final primaryNotify = _notifyCharacteristic;
      if (primaryNotify != null &&
          bleUuidMatches(
            resolvedCharacteristicUuid,
            primaryNotify.characteristicUuid.str,
          )) {
        await _notifySubscription?.cancel();
        _notifySubscription = null;
      }
      final subscription = _gattNotifySubscriptions.remove(key);
      await subscription?.cancel();
      _notifiedCharacteristicKeys.remove(key);
      try {
        await target.characteristic.setNotifyValue(false);
      } catch (_) {
        throw const TransportException(
          TransportErrorKind.receive,
          '关闭 BLE 通知失败',
        );
      }
      return;
    }

    if (_notifiedCharacteristicKeys.contains(key)) {
      return;
    }
    final primaryNotify = _notifyCharacteristic;
    final isPrimary =
        primaryNotify != null &&
        bleUuidMatches(
          resolvedServiceUuid,
          _config?.serviceUuid ?? resolvedServiceUuid,
        ) &&
        bleUuidMatches(
          resolvedCharacteristicUuid,
          primaryNotify.characteristicUuid.str,
        );
    final subscription = target.characteristic.onValueReceived.listen(
      (data) {
        _emitGattValue(resolvedServiceUuid, resolvedCharacteristicUuid, data);
        if (isPrimary) {
          emitEvent(TransportDataReceived(bytes: Uint8List.fromList(data)));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_gattValueController.isClosed) {
          _gattValueController.addError(
            const TransportException(
              TransportErrorKind.receive,
              'BLE 特征通知接收异常',
            ),
          );
        }
      },
    );
    if (isPrimary) {
      _notifySubscription = subscription;
    } else {
      _gattNotifySubscriptions[key] = subscription;
    }
    _notifiedCharacteristicKeys.add(key);
    try {
      await target.characteristic.setNotifyValue(true);
    } catch (_) {
      _notifiedCharacteristicKeys.remove(key);
      await _gattNotifySubscriptions.remove(key)?.cancel();
      if (isPrimary) {
        await _notifySubscription?.cancel();
        _notifySubscription = null;
      }
      throw const TransportException(TransportErrorKind.receive, '开启 BLE 通知失败');
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disconnecting) {
      return;
    }
    _disconnecting = true;
    _connected = false;
    final notify = _notifyCharacteristic;
    if (notify != null) {
      try {
        await notify.setNotifyValue(false);
      } catch (_) {
        // 设备可能已经断开，关闭通知失败无需阻断资源释放。
      }
    }
    await _cleanupDevice();
    if (!_disposed) {
      emitEvent(const TransportDisconnected());
    }
    _disconnecting = false;
  }

  Future<void> _cleanupDevice() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    final gattSubscriptions = _gattNotifySubscriptions.values.toList(
      growable: false,
    );
    _gattNotifySubscriptions.clear();
    _notifiedCharacteristicKeys.clear();
    for (final subscription in gattSubscriptions) {
      await subscription.cancel();
    }
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _device;
    _device = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _services = const <BluetoothService>[];
    _gattServices = const <BleGattServiceInfo>[];
    _config = null;
    _connected = false;
    if (device != null && !device.isDisconnected) {
      try {
        await device.disconnect();
      } catch (_) {
        // 断开期间设备可能已自行离线。
      }
    }
  }

  void _handleUnexpectedDisconnect(String message) {
    if (_disconnecting || !_connected) {
      return;
    }
    _connected = false;
    emitEvent(TransportDisconnected(reason: message));
    unawaited(_cleanupDevice());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await disconnect();
    _disposed = true;
    await closeEventStream();
    await _gattValueController.close();
  }

  List<BleGattServiceInfo> _buildGattServices(List<BluetoothService> services) {
    return services
        .map(
          (service) => BleGattServiceInfo(
            uuid: service.serviceUuid.str,
            characteristics: service.characteristics.map((characteristic) {
              final properties = characteristic.properties;
              return BleGattCharacteristicInfo(
                serviceUuid: service.serviceUuid.str,
                uuid: characteristic.characteristicUuid.str,
                properties: <BleGattProperty>[
                  if (properties.read) BleGattProperty.read,
                  if (properties.write) BleGattProperty.write,
                  if (properties.writeWithoutResponse)
                    BleGattProperty.writeWithoutResponse,
                  if (properties.notify) BleGattProperty.notify,
                  if (properties.indicate) BleGattProperty.indicate,
                ],
              );
            }),
          ),
        )
        .toList(growable: false);
  }

  ({BluetoothService service, BluetoothCharacteristic characteristic})?
  _findCharacteristic(String serviceUuid, String characteristicUuid) {
    for (final service in _services) {
      if (!bleUuidMatches(serviceUuid, service.serviceUuid.str)) {
        continue;
      }
      for (final characteristic in service.characteristics) {
        if (bleUuidMatches(
          characteristicUuid,
          characteristic.characteristicUuid.str,
        )) {
          return (service: service, characteristic: characteristic);
        }
      }
    }
    return null;
  }

  String _characteristicKey(String serviceUuid, String characteristicUuid) {
    return '${serviceUuid.toLowerCase()}|${characteristicUuid.toLowerCase()}';
  }

  void _emitGattValue(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  ) {
    if (_gattValueController.isClosed) {
      return;
    }
    _gattValueController.add(
      BleGattValue(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        bytes: Uint8List.fromList(data),
        receivedAt: DateTime.now(),
      ),
    );
  }
}
