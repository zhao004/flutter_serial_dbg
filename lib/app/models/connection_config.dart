import 'connection_mode.dart';
import '../utils/constants.dart';

final RegExp _bleIdentifierPattern = RegExp(
  r'^(?:[0-9A-Fa-f]{4}|[0-9A-Fa-f]{8}|'
  r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-'
  r'[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})$',
);

/// 不同传输通道的不可变连接配置。
sealed class ConnectionConfig {
  const ConnectionConfig();

  /// 配置对应的通信方式。
  ConnectionMode get mode;
}

/// TCP 客户端连接配置。
final class TcpClientConfig extends ConnectionConfig {
  TcpClientConfig({required String host, required int port})
    : host = _validateHost(host),
      port = _validatePort(port);

  final String host;
  final int port;

  @override
  ConnectionMode get mode => ConnectionMode.tcpClient;
}

/// TCP 服务端监听配置。
final class TcpServerConfig extends ConnectionConfig {
  TcpServerConfig({String bindAddress = '0.0.0.0', required int port})
    : bindAddress = _validateHost(bindAddress),
      port = _validatePort(port);

  final String bindAddress;
  final int port;

  @override
  ConnectionMode get mode => ConnectionMode.tcpServer;
}

/// UDP 客户端连接配置。
final class UdpClientConfig extends ConnectionConfig {
  UdpClientConfig({required String host, required int port})
    : host = _validateHost(host),
      port = _validatePort(port);

  final String host;
  final int port;

  @override
  ConnectionMode get mode => ConnectionMode.udpClient;
}

/// UDP 服务端监听配置。
final class UdpServerConfig extends ConnectionConfig {
  UdpServerConfig({String bindAddress = '0.0.0.0', required int port})
    : bindAddress = _validateHost(bindAddress),
      port = _validatePort(port);

  final String bindAddress;
  final int port;

  @override
  ConnectionMode get mode => ConnectionMode.udpServer;
}

/// BLE 设备与 GATT 特征配置。
///
/// 特征 UUID 可为空，以兼容连接后执行服务发现的设备。
final class BleConfig extends ConnectionConfig {
  BleConfig({
    required String remoteId,
    String? serviceUuid,
    String? writeCharacteristicUuid,
    String? notifyCharacteristicUuid,
  }) : remoteId = _validateRequiredText(remoteId, 'remoteId'),
       serviceUuid = _validateOptionalBleIdentifier(serviceUuid, 'serviceUuid'),
       writeCharacteristicUuid = _validateOptionalBleIdentifier(
         writeCharacteristicUuid,
         'writeCharacteristicUuid',
       ),
       notifyCharacteristicUuid = _validateOptionalBleIdentifier(
         notifyCharacteristicUuid,
         'notifyCharacteristicUuid',
       );

  final String remoteId;
  final String? serviceUuid;
  final String? writeCharacteristicUuid;
  final String? notifyCharacteristicUuid;

  @override
  ConnectionMode get mode => ConnectionMode.ble;
}

/// USB 停止位。
enum UsbStopBits { one, onePointFive, two }

/// USB 校验位。
enum UsbParity { none, odd, even, mark, space }

/// USB 串口参数。
final class UsbSerialConfig extends ConnectionConfig {
  UsbSerialConfig({
    required String deviceId,
    this.baudRate = 115200,
    this.dataBits = 8,
    this.stopBits = UsbStopBits.one,
    this.parity = UsbParity.none,
  }) : deviceId = _validateRequiredText(deviceId, 'deviceId') {
    if (baudRate < UsbSerialDefaults.minBaudRate ||
        baudRate > UsbSerialDefaults.maxBaudRate) {
      throw ArgumentError.value(
        baudRate,
        'baudRate',
        '必须位于 ${UsbSerialDefaults.minBaudRate} 到 '
            '${UsbSerialDefaults.maxBaudRate} 之间',
      );
    }
    if (dataBits < 5 || dataBits > 8) {
      throw ArgumentError.value(dataBits, 'dataBits', '必须位于 5 到 8 之间');
    }
  }

  final String deviceId;
  final int baudRate;
  final int dataBits;
  final UsbStopBits stopBits;
  final UsbParity parity;

  @override
  ConnectionMode get mode => ConnectionMode.usbSerial;
}

String _validateHost(String value) => _validateRequiredText(value, 'host');

int _validatePort(int port) {
  if (port < 1 || port > 0xFFFF) {
    throw ArgumentError.value(port, 'port', '必须位于 1 到 65535 之间');
  }
  return port;
}

String _validateRequiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '不能为空');
  }
  return normalized;
}

String? _validateOptionalBleIdentifier(String? value, String name) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  if (!_bleIdentifierPattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, name, '必须是 16、32 或 128 位 UUID');
  }
  return normalized;
}
