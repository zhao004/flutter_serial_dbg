import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../models/app_update.dart';
import '../../theme/app_theme.dart';
import 'update_controller.dart';

/// 展示可复用的新版本检查、下载和安装弹窗。
Future<void> showUpdateDialog({
  required BuildContext context,
  required UpdateController controller,
}) {
  final colors = context.appColors;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.barrier,
    builder: (context) => Dialog(
      backgroundColor: context.appColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _UpdateDialog(controller: controller),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.controller});

  final UpdateController controller;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _closeScheduled = false;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final state = widget.controller.state.value;
        final update = state.update;
        if (state.status == UpdateStatus.awaitingInstall) {
          _scheduleClose(context);
        }
        if (update == null) {
          return const SizedBox.shrink();
        }
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _UpdateDialogHeader(
                  canClose: !state.isBusy,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                _VersionTransition(
                  installed: state.installed?.displayVersion ?? '未知',
                  latest: update.tagName,
                ),
                const SizedBox(height: 18),
                Text(
                  '更新内容',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 190),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    update.releaseNotes,
                    style: TextStyle(
                      color: context.appColors.ink,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatBytes(update.asset.sizeBytes)} · '
                  '${update.asset.abi}',
                  style: TextStyle(
                    color: context.appColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _UpdateError(message: state.errorMessage!),
                ],
                if (state.status == UpdateStatus.downloading) ...<Widget>[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '正在下载 ${((state.progress ?? 0) * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.inkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _UpdateActions(
                  state: state,
                  onCancelDownload: () {
                    unawaited(widget.controller.cancelDownload());
                  },
                  onLater: state.isBusy
                      ? null
                      : () => Navigator.of(context).pop(),
                  onInstall: state.isBusy
                      ? null
                      : () {
                          unawaited(widget.controller.downloadAndInstall());
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleClose(BuildContext context) {
    if (_closeScheduled) {
      return;
    }
    _closeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _UpdateDialogHeader extends StatelessWidget {
  const _UpdateDialogHeader({required this.canClose, required this.onClose});

  final bool canClose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.system_update_alt_rounded,
            color: colors.primaryDeep,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '发现新版本',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '下载完成后由系统确认安装',
                style: TextStyle(color: colors.inkMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '关闭',
          onPressed: canClose ? onClose : null,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _VersionTransition extends StatelessWidget {
  const _VersionTransition({required this.installed, required this.latest});

  final String installed;
  final String latest;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _VersionLabel(label: '当前', value: installed),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: colors.primaryDeep,
              size: 20,
            ),
          ),
          Expanded(
            child: _VersionLabel(label: '最新', value: latest, alignEnd: true),
          ),
        ],
      ),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(color: colors.inkMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UpdateError extends StatelessWidget {
  const _UpdateError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateActions extends StatelessWidget {
  const _UpdateActions({
    required this.state,
    required this.onCancelDownload,
    required this.onLater,
    required this.onInstall,
  });

  final UpdateState state;
  final VoidCallback onCancelDownload;
  final VoidCallback? onLater;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    if (state.status == UpdateStatus.downloading) {
      return OutlinedButton.icon(
        key: const ValueKey<String>('update-cancel-download'),
        onPressed: onCancelDownload,
        icon: const Icon(Icons.close_rounded),
        label: const Text('取消下载'),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          key: const ValueKey<String>('update-later'),
          onPressed: onLater,
          child: const Text('稍后'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: const ValueKey<String>('update-install'),
          onPressed: onInstall,
          icon: const Icon(Icons.download_rounded),
          label: Text(state.status == UpdateStatus.failed ? '重试' : '立即更新'),
        ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  const bytesPerKilobyte = 1024;
  const bytesPerMegabyte = bytesPerKilobyte * 1024;
  if (bytes >= bytesPerMegabyte) {
    return '${(bytes / bytesPerMegabyte).toStringAsFixed(1)} MB';
  }
  return '${(bytes / bytesPerKilobyte).ceil()} KB';
}
