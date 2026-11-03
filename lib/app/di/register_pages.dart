import '../database/app_repository.dart';
import '../pages/home/home_controller.dart';
import '../pages/settings/appearance_controller.dart';
import '../pages/update/update_controller.dart';
import '../services/ble/ble_permission_service.dart';
import '../services/ble/ble_scanner.dart';
import '../services/diagnostics/network_diagnostics.dart';
import '../services/logging/log_exporter.dart';
import '../services/transport/transport_factory.dart';
import '../services/update/app_update_service.dart';
import '../services/usb/usb_serial_service.dart';
import 'injector.dart';

/// 注册页面级控制器。
void registerPages() {
  if (!getIt.isRegistered<AppearanceController>()) {
    getIt.registerLazySingleton<AppearanceController>(
      () => AppearanceController(getIt<AppRepository>()),
      dispose: (controller) => controller.dispose(),
    );
  }
  if (!getIt.isRegistered<HomeController>()) {
    getIt.registerLazySingleton<HomeController>(
      () => HomeController(
        transportFactory: getIt<TransportFactory>(),
        diagnostics: getIt<NetworkDiagnostics>(),
        repository: getIt<AppRepository>(),
        logExporter: getIt<LogExporter>(),
        bleScanner: getIt<BleScanner>(),
        blePermissionService: getIt<BlePermissionService>(),
        usbSerialService: getIt<UsbSerialService>(),
      ),
      dispose: (controller) => controller.dispose(),
    );
  }
  if (!getIt.isRegistered<UpdateController>()) {
    getIt.registerLazySingleton<UpdateController>(
      () => UpdateController(getIt<AppUpdateService>()),
      dispose: (controller) => controller.dispose(),
    );
  }
}
