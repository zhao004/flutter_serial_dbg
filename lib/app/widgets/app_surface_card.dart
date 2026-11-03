import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// 应用内统一的高亮内容容器。
///
/// 卡片只负责背景、描边、圆角和阴影，不约束内部布局或交互。
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderRadius = 18,
    this.showShadow = true,
  });

  /// 卡片内容。
  final Widget child;

  /// 内容与卡片边缘之间的留白。
  final EdgeInsetsGeometry padding;

  /// 卡片背景色。
  final Color? color;

  /// 卡片圆角半径。
  final double borderRadius;

  /// 是否显示低对比柔和阴影。
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
