import '../models/connection_mode.dart';

/// 返回面向界面的连接模式名称。
String connectionModeLabel(ConnectionMode mode) {
  return switch (mode) {
    ConnectionMode.tcpClient => 'TCP 客户端',
    ConnectionMode.tcpServer => 'TCP 服务端',
    ConnectionMode.udpClient => 'UDP 客户端',
    ConnectionMode.udpServer => 'UDP 服务端',
    ConnectionMode.ble => 'BLE',
    ConnectionMode.usbSerial => 'USB 串口',
  };
}
