/// 已连接 USB 串口设备的只读摘要。
///
/// 不保留序列号，避免设备标识进入页面状态或诊断日志。
final class UsbSerialDeviceInfo {
  UsbSerialDeviceInfo({
    required String deviceId,
    required String deviceName,
    int? vendorId,
    int? productId,
    String? productName,
    String? manufacturerName,
    int? interfaceCount,
  }) : deviceId = _validateRequiredText(deviceId, 'deviceId'),
       deviceName = _validateRequiredText(deviceName, 'deviceName'),
       productName = _normalizeOptionalText(productName),
       manufacturerName = _normalizeOptionalText(manufacturerName),
       vendorId = _validateOptionalUsbCode(vendorId, 'vendorId'),
       productId = _validateOptionalUsbCode(productId, 'productId'),
       interfaceCount = _validateOptionalNonNegative(
         interfaceCount,
         'interfaceCount',
       );

  final String deviceId;
  final String deviceName;
  final int? vendorId;
  final int? productId;
  final String? productName;
  final String? manufacturerName;
  final int? interfaceCount;

  /// 设备列表中的首选展示名称。
  String get displayName {
    final product = productName;
    if (product != null) {
      return product;
    }
    final manufacturer = manufacturerName;
    if (manufacturer != null) {
      return '$manufacturer USB 串口';
    }
    return 'USB 串口设备';
  }

  /// 不包含设备编号的硬件标识。
  String get hardwareId {
    final vendor = vendorId;
    final product = productId;
    if (vendor != null && product != null) {
      return 'VID ${_hex16(vendor)} / PID ${_hex16(product)}';
    }
    if (vendor != null) {
      return 'VID ${_hex16(vendor)}';
    }
    return '未知 VID/PID';
  }
}

int _validateNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, '不能小于 0');
  }
  return value;
}

int? _validateOptionalNonNegative(int? value, String name) {
  if (value == null) {
    return null;
  }
  return _validateNonNegative(value, name);
}

int? _validateOptionalUsbCode(int? value, String name) {
  if (value == null) {
    return null;
  }
  if (value < 0 || value > 0xFFFF) {
    throw ArgumentError.value(value, name, '必须位于 0 到 65535 之间');
  }
  return value;
}

String _validateRequiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '不能为空');
  }
  return normalized;
}

String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _hex16(int value) =>
    '0x${value.toRadixString(16).toUpperCase().padLeft(4, '0')}';
