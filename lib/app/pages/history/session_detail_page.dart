import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../di/injector.dart';
import '../../models/log_entry.dart';
import '../../models/protocol_event.dart';
import '../../models/protocol_observation.dart';
import '../../models/protocol_profile.dart';
import '../../models/text_encoding.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surface_card.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/log_entry_list.dart';
import '../home/protocol_controller.dart';
import 'log_history_controller.dart';

/// 单个持久化会话的搜索、导出和删除页面。
class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late final LogHistoryController _controller;
  late final ProtocolController _protocolController;
  final TextEditingController _searchController = TextEditingController();
  List<LogEntry> _entries = const <LogEntry>[];
  PayloadFormat _format = PayloadFormat.text;
  LogDirection? _direction;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = getIt<LogHistoryController>();
    _protocolController = getIt<ProtocolController>();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final entries = await _controller.loadEntries(widget.sessionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      AppToast.error(context, '读取会话日志失败');
    }
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  List<LogEntry> get _visibleEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _entries
        .where((entry) {
          if (_direction != null && entry.direction != _direction) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return formatLogEntry(
            entry,
            _format,
            TextEncoding.utf8,
          ).toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _export() async {
    final exported = await _controller.exportSession(
      widget.sessionId,
      format: _format,
    );
    if (!mounted || !exported) {
      return;
    }
    AppToast.success(context, '会话日志已导出');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除历史会话'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await _controller.deleteSession(widget.sessionId);
    if (!mounted) {
      return;
    }
    if (deleted) {
      AppToast.success(context, '历史会话已删除');
      context.pop();
    } else {
      AppToast.error(context, '删除历史会话失败');
    }
  }

  Future<void> _openProtocolReparse() async {
    final colors = context.appColors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.82,
        child: _ProtocolReparseSheet(
          controller: _protocolController,
          entries: _entries,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = _visibleEntries;
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
        title: const Text('会话详情'),
        actions: <Widget>[
          IconButton(
            tooltip: '协议解析',
            onPressed: _entries.isEmpty
                ? null
                : () => unawaited(_openProtocolReparse()),
            icon: const Icon(Icons.account_tree_outlined),
          ),
          IconButton(
            tooltip: '导出会话',
            onPressed: _entries.isEmpty ? null : () => unawaited(_export()),
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: '删除会话',
            onPressed: () => unawaited(_delete()),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.pageGradient),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : AppSurfaceCard(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '搜索日志内容',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<PayloadFormat>(
                                initialValue: _format,
                                decoration: const InputDecoration(
                                  labelText: '显示格式',
                                ),
                                items: const <DropdownMenuItem<PayloadFormat>>[
                                  DropdownMenuItem(
                                    value: PayloadFormat.text,
                                    child: Text('文本'),
                                  ),
                                  DropdownMenuItem(
                                    value: PayloadFormat.hex,
                                    child: Text('HEX'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _format = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<LogDirection?>(
                                initialValue: _direction,
                                decoration: const InputDecoration(
                                  labelText: '方向',
                                ),
                                items: const <DropdownMenuItem<LogDirection?>>[
                                  DropdownMenuItem<LogDirection?>(
                                    value: null,
                                    child: Text('全部'),
                                  ),
                                  DropdownMenuItem<LogDirection?>(
                                    value: LogDirection.received,
                                    child: Text('接收'),
                                  ),
                                  DropdownMenuItem<LogDirection?>(
                                    value: LogDirection.sent,
                                    child: Text('发送'),
                                  ),
                                  DropdownMenuItem<LogDirection?>(
                                    value: LogDirection.system,
                                    child: Text('系统'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _direction = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceMuted,
                              border: Border.all(color: colors.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: visible.isEmpty
                                ? Center(
                                    child: Text(
                                      _entries.isEmpty ? '该会话没有日志' : '未找到匹配日志',
                                      style: TextStyle(color: colors.inkMuted),
                                    ),
                                  )
                                : AppLogEntryList(
                                    entries: visible,
                                    format: _format,
                                    textEncoding: TextEncoding.utf8,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolReparseSheet extends StatefulWidget {
  const _ProtocolReparseSheet({
    required this.controller,
    required this.entries,
  });

  final ProtocolController controller;
  final List<LogEntry> entries;

  @override
  State<_ProtocolReparseSheet> createState() => _ProtocolReparseSheetState();
}

class _ProtocolReparseSheetState extends State<_ProtocolReparseSheet> {
  ProtocolProfile? _selectedProfile;
  List<ProtocolObservation> _observations = const <ProtocolObservation>[];

  void _selectProfile(int? profileId) {
    ProtocolProfile? profile;
    if (profileId != null && profileId > 0) {
      for (final candidate in widget.controller.profiles.value) {
        if (candidate.id == profileId) {
          profile = candidate;
          break;
        }
      }
    }
    setState(() {
      _selectedProfile = profile;
      _observations = profile == null
          ? const <ProtocolObservation>[]
          : widget.controller.decodeEntries(widget.entries, profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '历史协议解析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<int>(
            initialValue: 0,
            decoration: const InputDecoration(labelText: '协议 Profile'),
            items: <DropdownMenuItem<int>>[
              const DropdownMenuItem<int>(value: 0, child: Text('不解析')),
              for (final profile in widget.controller.profiles.value)
                DropdownMenuItem<int>(
                  value: profile.id,
                  child: Text(profile.name),
                ),
            ],
            onChanged: _selectProfile,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              border: Border.all(color: colors.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedProfile == null
                ? Center(
                    child: Text(
                      widget.controller.profiles.value.isEmpty
                          ? '暂无协议 Profile，请先在首页新增。'
                          : '选择协议 Profile 以重新解析接收日志。',
                      style: TextStyle(color: colors.inkMuted),
                    ),
                  )
                : _observations.isEmpty
                ? Center(
                    child: Text(
                      '没有可识别的协议帧',
                      style: TextStyle(color: colors.inkMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _observations.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final observation = _observations[index];
                      final event = observation.event;
                      final (icon, text, color) = switch (event) {
                        ProtocolFrameReceived(:final command, :final payload) => (
                          Icons.check_circle_outline_rounded,
                          '命令 0x'
                              '${command.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                              ' · 负载 ${payload.length} 字节',
                          colors.receive,
                        ),
                        ProtocolFrameRejected(
                          :final reason,
                          :final discardedBytes,
                        ) =>
                          (
                            Icons.warning_amber_rounded,
                            '${_rejectionLabel(reason)} · 丢弃 '
                                '${discardedBytes.length} 字节',
                            colors.warning,
                          ),
                      };
                      return Row(
                        children: <Widget>[
                          Icon(icon, size: 18, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: color,
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

String _rejectionLabel(FrameRejectionReason reason) {
  return switch (reason) {
    FrameRejectionReason.invalidLength => '非法长度',
    FrameRejectionReason.checksumMismatch => '校验失败',
    FrameRejectionReason.invalidFrame => '非法帧',
    FrameRejectionReason.bufferOverflow => '缓冲溢出',
  };
}
