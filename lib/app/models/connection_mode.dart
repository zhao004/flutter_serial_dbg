/// 当前迁移范围内支持的通信方式。
enum ConnectionMode {
  tcpClient,
  tcpServer,
  udpClient,
  udpServer,
  ble,
  usbSerial;

  /// 是否属于 WiFi 网络传输。
  bool get isWifi => switch (this) {
    ConnectionMode.tcpClient ||
    ConnectionMode.tcpServer ||
    ConnectionMode.udpClient ||
    ConnectionMode.udpServer => true,
    ConnectionMode.ble || ConnectionMode.usbSerial => false,
  };

  /// 是否为服务端监听模式。
  bool get isServer => switch (this) {
    ConnectionMode.tcpServer || ConnectionMode.udpServer => true,
    ConnectionMode.tcpClient ||
    ConnectionMode.udpClient ||
    ConnectionMode.ble ||
    ConnectionMode.usbSerial => false,
  };
}
