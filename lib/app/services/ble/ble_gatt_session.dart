import 'dart:typed_data';

import '../../models/ble_gatt.dart';

/// 当前 BLE 连接上的 GATT 浏览和特征操作能力。
abstract interface class BleGattSession {
  /// 已发现服务与特征快照。
  List<BleGattServiceInfo> get gattServices;

  /// 主动读取、通知和指示产生的特征值。
  Stream<BleGattValue> get gattValues;

  /// 当前已开启通知或指示的特征组合键。
  Set<String> get notifiedGattKeys;

  /// 读取指定特征。
  Future<BleGattValue> readGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  });

  /// 写入指定特征。
  Future<void> writeGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  });

  /// 开启或关闭指定特征的通知/指示。
  Future<void> setGattNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  });
}
