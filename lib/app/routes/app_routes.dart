class Routes {
  Routes._();

  static const String home = '/';
  static const String bleGatt = '/ble/gatt';
  static const String protocolProfiles = '/protocols';
  static const String sessions = '/sessions';
  static const String settings = '/settings';
  static const String themeColor = '/settings/theme-color';

  /// 返回指定日志会话详情路由。
  static String sessionDetail(int sessionId) => '$sessions/$sessionId';
}
