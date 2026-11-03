import 'package:material_ui/material_ui.dart';

import '../models/connection_state.dart';
import '../theme/app_theme.dart';

/// 跨页面复用的连接状态徽标。
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.status});

  /// 需要展示的传输状态。
  final TransportStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (label, color, background) = switch (status) {
      TransportStatus.disconnected => (
        '未连接',
        colors.inkMuted,
        colors.surfaceMuted,
      ),
      TransportStatus.connecting => ('连接中', colors.warning, colors.warningSoft),
      TransportStatus.connected => (
        '已连接',
        colors.primaryDeep,
        colors.primarySoft,
      ),
      TransportStatus.disconnecting => (
        '断开中',
        colors.warning,
        colors.warningSoft,
      ),
      TransportStatus.failed => ('连接失败', colors.error, colors.errorSoft),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
