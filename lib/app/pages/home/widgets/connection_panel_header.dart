import 'package:material_ui/material_ui.dart';

import '../../../models/connection_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_status_badge.dart';

/// 连接配置面板共用的标题、图标和状态栏。
class ConnectionPanelHeader extends StatelessWidget {
  const ConnectionPanelHeader({
    super.key,
    required this.status,
    this.title = '连接配置',
  });

  /// 当前传输状态。
  final TransportStatus status;

  /// 面板标题。
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 17,
            color: colors.primaryDeep,
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        AppStatusBadge(status: status),
      ],
    );
  }
}
