import 'package:go_router/go_router.dart';

import '../pages/home/home_view.dart';
import '../pages/home/ble_gatt_page.dart';
import '../pages/home/protocol_profiles_page.dart';
import '../pages/history/session_detail_page.dart';
import '../pages/history/session_history_page.dart';
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
        path: Routes.bleGatt,
        name: 'bleGatt',
        builder: (context, state) => const BleGattPage(),
      ),
      GoRoute(
        path: Routes.protocolProfiles,
        name: 'protocolProfiles',
        builder: (context, state) => const ProtocolProfilesPage(),
      ),
      GoRoute(
        path: Routes.sessions,
        name: 'sessions',
        builder: (context, state) => const SessionHistoryPage(),
      ),
      GoRoute(
        path: '${Routes.sessions}/:sessionId',
        name: 'sessionDetail',
        builder: (context, state) {
          final sessionId = int.tryParse(
            state.pathParameters['sessionId'] ?? '',
          );
          if (sessionId == null || sessionId < 0) {
            return const SessionHistoryPage();
          }
          return SessionDetailPage(sessionId: sessionId);
        },
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
