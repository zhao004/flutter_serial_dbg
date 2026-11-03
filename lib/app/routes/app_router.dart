import 'package:go_router/go_router.dart';

import '../pages/home/home_view.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/theme_color_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: Routes.themeColor,
        name: 'themeColor',
        builder: (context, state) => const ThemeColorPage(),
      ),
    ],
  );
}
