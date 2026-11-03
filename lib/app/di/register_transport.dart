import '../services/ble/ble_permission_service.dart';
import '../services/transport/transport_factory.dart';
import '../services/usb/usb_serial_service.dart';
import 'injector.dart';

/// 注册通信传输工厂。
void registerTransport() {
  if (getIt.isRegistered<TransportFactory>()) {
    return;
  }
  getIt.registerLazySingleton<TransportFactory>(
    () => DefaultTransportFactory(
      getIt<BlePermissionService>(),
      getIt<UsbSerialService>(),
    ),
  );
}
