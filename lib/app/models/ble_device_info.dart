/// 扫描到的 BLE 设备摘要。
final class BleDeviceInfo {
  BleDeviceInfo({
    required String remoteId,
    required String name,
    required this.rssi,
  }) : remoteId = _validateRemoteId(remoteId),
       name = _validateName(name);

  final String remoteId;
  final String name;
  final int rssi;

  /// 供列表展示的安全名称，不写入通信日志。
  String get displayName => name.isEmpty ? '未命名 BLE 设备' : name;
}

String _validateRemoteId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'remoteId', '不能为空');
  }
  return normalized;
}

String _validateName(String value) => value.trim();
