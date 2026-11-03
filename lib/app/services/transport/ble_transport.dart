import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/connection_config.dart';
import '../../models/transport_event.dart';
import '../../services/ble/ble_permission_service.dart';
import '../../services/ble/ble_gatt_resolver.dart';
import '../../utils/constants.dart';
import 'transport.dart';

/// BLE 通用透传 Transport。
///
/// 未指定 UUID 时自动选择首个可写特征，并优先搭配可用通知特征。当前按
/// FlutterBluePlus 的非营利许可模式实现；商业使用必须显式切换许可证。
final class BleTransport with TransportEventEmitter implements Transport {
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
      final selection = _resolveGatt(services, config);
      _writeCharacteristic = selection.write.value;
      _notifyCharacteristic = selection.notify?.value;
      _writeWithoutResponse =
          !selection.write.value.properties.write &&
          selection.write.value.properties.writeWithoutResponse;

      final notify = _notifyCharacteristic;
      if (notify != null) {
        _notifySubscription = notify.onValueReceived.listen(
          (data) {
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
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _device;
    _device = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
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
  }
}
