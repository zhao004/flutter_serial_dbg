import '../../models/connection_mode.dart';
import '../ble/ble_permission_service.dart';
import '../usb/usb_serial_service.dart';
import 'ble_transport.dart';
import 'tcp_transport.dart';
import 'transport.dart';
import 'udp_transport.dart';
import 'usb_serial_transport.dart';

/// 根据连接模式创建独立的 Transport 实例。
abstract interface class TransportFactory {
  Transport create(ConnectionMode mode);
}

/// 生产环境 Transport 工厂。
final class DefaultTransportFactory implements TransportFactory {
  const DefaultTransportFactory(
    this._permissionService,
    this._usbSerialService,
  );

  final BlePermissionService _permissionService;
  final UsbSerialService _usbSerialService;

  @override
  Transport create(ConnectionMode mode) {
    return switch (mode) {
      ConnectionMode.tcpClient => TcpClientTransport(),
      ConnectionMode.tcpServer => TcpServerTransport(),
      ConnectionMode.udpClient => UdpClientTransport(),
      ConnectionMode.udpServer => UdpServerTransport(),
      ConnectionMode.ble => BleTransport(permissionService: _permissionService),
      ConnectionMode.usbSerial => UsbSerialTransport(_usbSerialService),
    };
  }
}
