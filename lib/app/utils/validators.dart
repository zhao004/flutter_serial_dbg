import 'constants.dart';

/// 将用户输入转换为合法的 TCP/UDP 端口。
int? parsePortInput(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final port = int.tryParse(normalized);
  if (port == null || port < 1 || port > 0xFFFF) {
    return null;
  }
  return port;
}

/// 校验主机、IP 或监听地址输入。
String? validateHostInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '请输入地址';
  }
  return null;
}

/// 校验端口输入。
String? validatePortInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '请输入端口';
  }
  if (parsePortInput(value) == null) {
    return '端口范围为 1-65535';
  }
  return null;
}

/// 将用户输入转换为合法的 USB 波特率。
int? parseUsbBaudRateInput(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final baudRate = int.tryParse(normalized);
  if (baudRate == null ||
      baudRate < UsbSerialDefaults.minBaudRate ||
      baudRate > UsbSerialDefaults.maxBaudRate) {
    return null;
  }
  return baudRate;
}

/// 校验 USB 波特率输入。
String? validateUsbBaudRateInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '请输入波特率';
  }
  if (parseUsbBaudRateInput(value) == null) {
    return '范围为 ${UsbSerialDefaults.minBaudRate}-'
        '${UsbSerialDefaults.maxBaudRate}';
  }
  return null;
}
