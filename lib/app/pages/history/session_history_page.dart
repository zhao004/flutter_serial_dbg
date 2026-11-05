import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/connection_mode.dart';
import '../../models/log_session_summary.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/connection_mode_label.dart';
import '../../widgets/app_toast.dart';
import 'log_history_controller.dart';

const int _allHistoryFilterValue = -1;

/// 已持久化通信会话的浏览入口。
class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  late final LogHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<LogHistoryController>();
    unawaited(_controller.loadSessions());
  }

  void _selectModeFilter(int value) {
    if (value == _allHistoryFilterValue) {
      unawaited(_controller.setMode(null));
      return;
    }
    if (value < 0 || value >= ConnectionMode.values.length) {
      return;
    }
    unawaited(_controller.setMode(ConnectionMode.values[value]));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志历史'),
        content: const Text('这会删除全部已保存的通信会话，操作无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await _controller.deleteAll();
    if (!mounted) {
      return;
    }
    if (deleted) {
      AppToast.success(context, '日志历史已清空');
    } else {
      AppToast.error(context, '清空日志历史失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final sessions = _controller.sessions.value;
        final loading = _controller.isLoading.value;
        final selectedMode = _controller.selectedMode.value;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('日志历史'),
            actions: <Widget>[
              PopupMenuButton<int>(
                tooltip: '筛选连接模式',
                initialValue: selectedMode == null
                    ? _allHistoryFilterValue
                    : selectedMode.index,
                onSelected: _selectModeFilter,
                itemBuilder: (context) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(
                    value: _allHistoryFilterValue,
                    child: Text(selectedMode == null ? '✓ 全部模式' : '全部模式'),
                  ),
                  for (final mode in ConnectionMode.values)
                    PopupMenuItem<int>(
                      value: mode.index,
                      child: Text(
                        '${selectedMode == mode ? '✓ ' : ''}'
                        '${connectionModeLabel(mode)}',
                      ),
                    ),
                ],
                icon: Icon(
                  selectedMode == null
                      ? Icons.filter_alt_outlined
                      : Icons.filter_alt_rounded,
                ),
              ),
              if (sessions.isNotEmpty)
                IconButton(
                  tooltip: '清空全部历史',
                  onPressed: () => unawaited(_clearAll()),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: colors.pageGradient),
            child: SafeArea(
              top: false,
              child: loading && sessions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : sessions.isEmpty
                  ? _EmptyHistory(hasFilter: selectedMode != null)
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        14,
                        12,
                        24 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _SessionTile(
                          session: session,
                          onTap: () => unawaited(
                            context.push<void>(
                              Routes.sessionDetail(session.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});

  final LogSessionSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.history_rounded, color: colors.primaryDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            connectionModeLabel(session.mode),
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (session.isActive)
                          Text(
                            '未结束',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(session.startedAt),
                      style: TextStyle(color: colors.inkMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatDuration(session.duration)} · '
                      '${session.entryCount} 条 · '
                      '${_formatBytes(session.byteCount)}',
                      style: TextStyle(color: colors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.history_toggle_off_rounded,
              size: 54,
              color: colors.mutedIcon,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter ? '当前筛选模式下没有历史会话。' : '成功连接后产生的通信日志会显示在这里。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _formatDuration(Duration? duration) {
  if (duration == null) {
    return '进行中';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours} 小时 ${duration.inMinutes % 60} 分';
  }
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes} 分 ${duration.inSeconds % 60} 秒';
  }
  return '${duration.inSeconds} 秒';
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  }
  return '$bytes B';
}
