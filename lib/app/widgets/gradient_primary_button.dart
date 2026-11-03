import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// 使用品牌渐变的完整主操作按钮。
///
/// 按钮在禁用时降为中性底色，并通过 [isLoading] 展示进行中状态。
class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  /// 按钮文案。
  final String label;

  /// 文案前的操作图标。
  final IconData icon;

  /// 点击回调；为空时按钮禁用。
  final VoidCallback? onPressed;

  /// 是否显示加载指示器并阻止重复点击。
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final colors = context.appColors;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: enabled ? colors.primaryGradient : null,
            color: enabled ? null : colors.disabledFill,
            borderRadius: BorderRadius.circular(11),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isLoading
                    ? SizedBox.square(
                        key: const ValueKey<String>('loading'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Row(
                        key: const ValueKey<String>('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            icon,
                            size: 21,
                            color: enabled ? colors.onPrimary : colors.inkMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: TextStyle(
                              color: enabled
                                  ? colors.onPrimary
                                  : colors.inkMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
