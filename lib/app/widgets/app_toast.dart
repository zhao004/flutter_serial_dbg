import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_theme.dart';

/// 应用统一 Toast 的语义类型。
enum AppToastKind { info, success, warning, error }

/// 应用内所有临时提示的统一入口。
abstract final class AppToast {
  /// 在顶部显示一条自动关闭的 Toast。
  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) {
    final colors = context.appColors;
    final (type, background, foreground) = switch (kind) {
      AppToastKind.info => (
        ToastificationType.info,
        colors.primarySoft,
        colors.primaryDeep,
      ),
      AppToastKind.success => (
        ToastificationType.success,
        colors.successSoft,
        colors.success,
      ),
      AppToastKind.warning => (
        ToastificationType.warning,
        colors.warningSoft,
        colors.warning,
      ),
      AppToastKind.error => (
        ToastificationType.error,
        colors.errorSoft,
        colors.error,
      ),
    };

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 220),
      title: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: background,
      foregroundColor: foreground,
      primaryColor: foreground,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      showIcon: true,
      dragToClose: true,
      sizeConstraints: const BoxConstraints(maxWidth: 480),
    );
  }

  /// 显示信息提示。
  static void info(BuildContext context, String message) {
    show(context, message);
  }

  /// 显示成功提示。
  static void success(BuildContext context, String message) {
    show(context, message, kind: AppToastKind.success);
  }

  /// 显示警告提示。
  static void warning(BuildContext context, String message) {
    show(context, message, kind: AppToastKind.warning);
  }

  /// 显示错误提示。
  static void error(BuildContext context, String message) {
    show(context, message, kind: AppToastKind.error);
  }
}

/// 监听可空错误信号，并在错误出现时转为 Toast。
class ErrorToastListener extends StatefulWidget {
  const ErrorToastListener({super.key, required this.readError, this.onShown});

  final String? Function() readError;
  final VoidCallback? onShown;

  @override
  State<ErrorToastListener> createState() => _ErrorToastListenerState();
}

class _ErrorToastListenerState extends State<ErrorToastListener> {
  String? _scheduledMessage;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final message = widget.readError();
        if (message != null && message != _scheduledMessage) {
          _scheduledMessage = message;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || widget.readError() != message || !context.mounted) {
              _scheduledMessage = null;
              return;
            }
            AppToast.error(context, message);
            widget.onShown?.call();
            _scheduledMessage = null;
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}
