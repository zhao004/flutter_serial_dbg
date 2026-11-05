import 'dart:collection';
import 'dart:typed_data';

/// BLE GATT 特征支持的操作。
enum BleGattProperty {
  read,
  write,
  writeWithoutResponse,
  notify,
  indicate;

  /// 面向界面的属性名称。
  String get label => switch (this) {
    BleGattProperty.read => '读取',
    BleGattProperty.write => '写入',
    BleGattProperty.writeWithoutResponse => '无响应写入',
    BleGattProperty.notify => '通知',
    BleGattProperty.indicate => '指示',
  };
}

/// 一个已发现 GATT 特征的不可变摘要。
final class BleGattCharacteristicInfo {
  BleGattCharacteristicInfo({
    required this.serviceUuid,
    required this.uuid,
    required Iterable<BleGattProperty> properties,
  }) : properties = Set<BleGattProperty>.unmodifiable(properties);

  final String serviceUuid;
  final String uuid;
  final Set<BleGattProperty> properties;

  bool get canRead => properties.contains(BleGattProperty.read);

  bool get canWrite =>
      properties.contains(BleGattProperty.write) ||
      properties.contains(BleGattProperty.writeWithoutResponse);

  bool get canNotify =>
      properties.contains(BleGattProperty.notify) ||
      properties.contains(BleGattProperty.indicate);
}

/// 一个已发现 GATT 服务及其特征。
final class BleGattServiceInfo {
  BleGattServiceInfo({
    required this.uuid,
    required Iterable<BleGattCharacteristicInfo> characteristics,
  }) : characteristics = List<BleGattCharacteristicInfo>.unmodifiable(
         characteristics,
       );

  final String uuid;
  final List<BleGattCharacteristicInfo> characteristics;
}

/// GATT 通知、指示或主动读取返回的数据。
final class BleGattValue {
  BleGattValue({
    required this.serviceUuid,
    required this.characteristicUuid,
    required Uint8List bytes,
    required this.receivedAt,
  }) : _bytes = UnmodifiableListView<int>(Uint8List.fromList(bytes));

  final String serviceUuid;
  final String characteristicUuid;
  final DateTime receivedAt;
  final UnmodifiableListView<int> _bytes;

  List<int> get bytes => _bytes;

  Uint8List copyBytes() => Uint8List.fromList(_bytes);
}
