import 'dart:async';
import 'dart:typed_data';

import 'package:signals/signals.dart';

import '../../models/ble_gatt.dart';
import '../../services/ble/ble_gatt_session.dart';
import '../../services/transport/transport.dart';

/// 当前 BLE 连接的 GATT 浏览和特征操作状态。
class BleGattController {
  /// 已发现服务列表。
  final Signal<List<BleGattServiceInfo>> services =
      signal<List<BleGattServiceInfo>>(<BleGattServiceInfo>[]);

  /// 是否正在执行特征操作。
  final Signal<bool> isWorking = signal(false);

  /// 最近一次 GATT 操作错误。
  final Signal<String?> lastError = signal<String?>(null);

  /// 按服务与特征组合键保存最近一次读取或通知值。
  final Signal<Map<String, BleGattValue>> values =
      signal<Map<String, BleGattValue>>(<String, BleGattValue>{});

  /// 已开启通知的特征组合键。
  final Signal<Set<String>> notifiedKeys = signal<Set<String>>(<String>{});

  BleGattSession? _session;
  StreamSubscription<BleGattValue>? _valueSubscription;
  bool _disposed = false;

  /// 当前是否绑定了 BLE 连接。
  bool get isBound => _session != null;

  /// 绑定 HomeController 当前持有的 BLE 会话。
  void bind(BleGattSession session) {
    if (_disposed || identical(_session, session)) {
      return;
    }
    _cancelValueSubscription();
    _session = session;
    services.value = List<BleGattServiceInfo>.unmodifiable(
      session.gattServices,
    );
    values.value = <String, BleGattValue>{};
    notifiedKeys.value = Set<String>.unmodifiable(session.notifiedGattKeys);
    _valueSubscription = session.gattValues.listen(
      (value) {
        if (_disposed || !identical(_session, session)) {
          return;
        }
        values.value = <String, BleGattValue>{
          ...values.value,
          characteristicKey(value.serviceUuid, value.characteristicUuid): value,
        };
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_disposed) {
          lastError.value = _message(error, 'BLE 特征通知接收异常');
        }
      },
    );
  }

  /// 在断开连接时解除指定会话。
  void unbind([BleGattSession? expected]) {
    if (expected != null && !identical(_session, expected)) {
      return;
    }
    _session = null;
    _cancelValueSubscription();
    if (!_disposed) {
      services.value = const <BleGattServiceInfo>[];
      values.value = <String, BleGattValue>{};
      notifiedKeys.value = <String>{};
      isWorking.value = false;
    }
  }

  /// 读取指定特征。
  Future<BleGattValue?> read({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final session = _requireSession();
    if (session == null) {
      return null;
    }
    return _runOperation(() async {
      final value = await session.readGattCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      if (!_disposed) {
        values.value = <String, BleGattValue>{
          ...values.value,
          characteristicKey(serviceUuid, characteristicUuid): value,
        };
      }
      return value;
    });
  }

  /// 写入指定特征。
  Future<bool> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {
    final session = _requireSession();
    if (session == null) {
      return false;
    }
    final result = await _runOperation<bool>(() async {
      await session.writeGattCharacteristic(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        data: data,
        withResponse: withResponse,
      );
      return true;
    });
    return result ?? false;
  }

  /// 开启或关闭指定特征通知。
  Future<bool> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {
    final session = _requireSession();
    if (session == null) {
      return false;
    }
    final key = characteristicKey(serviceUuid, characteristicUuid);
    final result = await _runOperation<bool>(() async {
      await session.setGattNotify(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        enabled: enabled,
      );
      if (_disposed) {
        return false;
      }
      final next = Set<String>.of(notifiedKeys.value);
      if (enabled) {
        next.add(key);
      } else {
        next.remove(key);
      }
      notifiedKeys.value = Set<String>.unmodifiable(next);
      return true;
    });
    return result ?? false;
  }

  /// 查询特征最近一次读取或通知值。
  BleGattValue? valueFor(String serviceUuid, String characteristicUuid) {
    return values.value[characteristicKey(serviceUuid, characteristicUuid)];
  }

  /// 清除错误。
  void dismissError() {
    lastError.value = null;
  }

  BleGattSession? _requireSession() {
    if (_session == null) {
      lastError.value = 'BLE GATT 尚未连接';
    }
    return _session;
  }

  Future<T?> _runOperation<T>(Future<T> Function() operation) async {
    if (isWorking.value) {
      lastError.value = '上一条 GATT 操作仍在执行';
      return null;
    }
    isWorking.value = true;
    lastError.value = null;
    try {
      return await operation();
    } catch (error) {
      if (!_disposed) {
        lastError.value = _message(error, 'BLE GATT 操作失败');
      }
      return null;
    } finally {
      if (!_disposed) {
        isWorking.value = false;
      }
    }
  }

  void _cancelValueSubscription() {
    final subscription = _valueSubscription;
    _valueSubscription = null;
    unawaited(subscription?.cancel());
  }

  String _message(Object error, String fallback) {
    return error is TransportException ? error.message : fallback;
  }

  /// 释放 GATT 状态和值订阅。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _session = null;
    _cancelValueSubscription();
    services.dispose();
    isWorking.dispose();
    lastError.dispose();
    values.dispose();
    notifiedKeys.dispose();
  }
}

/// 生成服务与特征组合键。
String characteristicKey(String serviceUuid, String characteristicUuid) {
  return '${serviceUuid.toLowerCase()}|${characteristicUuid.toLowerCase()}';
}
