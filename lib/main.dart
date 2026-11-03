import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

import 'app/di/injector.dart';
import 'app/pages/home/home_controller.dart';
import 'app/pages/settings/appearance_controller.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Injector.registerAll();
  await Future.wait<void>(<Future<void>>[
    getIt<AppearanceController>().initialize(),
    getIt<HomeController>().initialize(),
  ]);
  runApp(const SerialDebugApp());
}

/// SerialDbg 应用入口，负责全局主题与路由配置。
class SerialDebugApp extends StatelessWidget {
  const SerialDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = getIt<AppearanceController>();
    return ToastificationWrapper(
      config: const ToastificationConfig(
        alignment: Alignment.topCenter,
        itemWidth: 343,
        maxToastLimit: 3,
        blockBackgroundInteraction: false,
      ),
      child: SignalBuilder(
        builder: (context) {
          final preset = appearance.themePreset.value;
          return MaterialApp.router(
            title: '串口调试助手',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(preset),
            darkTheme: AppTheme.dark(preset),
            themeMode: appearance.themeMode.value.materialMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
