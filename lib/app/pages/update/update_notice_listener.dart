import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../models/app_update.dart';
import '../../widgets/app_toast.dart';
import 'update_controller.dart';

/// 将更新控制器的一次性提示转换为应用统一 Toast。
class UpdateNoticeListener extends StatefulWidget {
  const UpdateNoticeListener({super.key, required this.controller});

  final UpdateController controller;

  @override
  State<UpdateNoticeListener> createState() => _UpdateNoticeListenerState();
}

class _UpdateNoticeListenerState extends State<UpdateNoticeListener> {
  UpdateNotice? _scheduledNotice;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final notice = widget.controller.notice.value;
        if (notice != null && notice != _scheduledNotice) {
          _scheduledNotice = notice;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                widget.controller.notice.value != notice ||
                !context.mounted) {
              _scheduledNotice = null;
              return;
            }
            _showNotice(context, notice);
            widget.controller.dismissNotice();
            _scheduledNotice = null;
          });
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showNotice(BuildContext context, UpdateNotice notice) {
    final kind = switch (notice.kind) {
      UpdateNoticeKind.info => AppToastKind.info,
      UpdateNoticeKind.success => AppToastKind.success,
      UpdateNoticeKind.warning => AppToastKind.warning,
      UpdateNoticeKind.error => AppToastKind.error,
    };
    AppToast.show(context, notice.message, kind: kind);
  }
}
