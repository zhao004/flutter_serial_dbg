import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/log_entry.dart';
import '../../../models/text_encoding.dart';
import '../../../services/protocol/hex_codec.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/app_surface_card.dart';
import '../home_controller.dart';
import 'send_panel.dart';

/// 通信日志展示、搜索、格式切换、导出和发送工作区。
class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key, required this.controller});

  final HomeController controller;

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final ScrollController _scrollController = ScrollController();
  _LogFilter _filter = _LogFilter.all;
  int _lastVisibleCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll(int visibleCount, bool autoScroll) {
    if (!autoScroll || visibleCount == _lastVisibleCount) {
      _lastVisibleCount = visibleCount;
      return;
    }
    _lastVisibleCount = visibleCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _exportLogs() async {
    final outcome = await widget.controller.exportLogs();
    if (!mounted || outcome != LogExportOutcome.saved) {
      return;
    }
    AppToast.success(context, '日志已导出');
  }

  void _clearLogs() {
    setState(() {
      _filter = _LogFilter.all;
    });
    widget.controller.clearLogs();
  }

  List<LogEntry> _filterLogs(List<LogEntry> logs) {
    final directionFiltered = switch (_filter) {
      _LogFilter.all => logs,
      _LogFilter.received =>
        logs
            .where((entry) => entry.direction == LogDirection.received)
            .toList(growable: false),
      _LogFilter.sent =>
        logs
            .where((entry) => entry.direction == LogDirection.sent)
            .toList(growable: false),
    };
    return directionFiltered;
  }

  Future<void> _openFullScreen(
    List<LogEntry> entries,
    PayloadFormat format,
    TextEncoding textEncoding,
  ) {
    final colors = context.appColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _FullScreenLogSheet(
          entries: entries,
          format: format,
          textEncoding: textEncoding,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final logs = widget.controller.logs.value;
        final format = widget.controller.receiveFormat.value;
        final textEncoding = widget.controller.textEncoding.value;
        final autoScroll = widget.controller.autoScroll.value;
        final filtered = _filterLogs(logs);
        _scheduleAutoScroll(filtered.length, autoScroll);
        final hasLogs = logs.isNotEmpty;
        final hasVisibleLogs = filtered.isNotEmpty;
        return AppSurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: <Widget>[
              _LogHeader(
                count: logs.length,
                filter: _filter,
                hasVisibleLogs: hasVisibleLogs,
                onFilterChanged: (filter) {
                  setState(() {
                    _filter = filter;
                  });
                },
                onFullScreen: () =>
                    unawaited(_openFullScreen(filtered, format, textEncoding)),
              ),
              const SizedBox(height: 10),
              Container(
                key: const ValueKey<String>('log-viewport'),
                height: 226,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  border: Border.all(color: colors.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: logs.isEmpty
                    ? const _EmptyLogState()
                    : filtered.isEmpty
                    ? const _FilterEmptyState()
                    : _LogList(
                        entries: filtered,
                        format: format,
                        textEncoding: textEncoding,
                        scrollController: _scrollController,
                      ),
              ),
              const SizedBox(height: 5),
              _DisplayControls(
                format: format,
                textEncoding: textEncoding,
                appendCrlf: widget.controller.appendCrlf.value,
                hasLogs: hasLogs,
                onFormatChanged: widget.controller.setReceiveFormat,
                onEncodingChanged: widget.controller.setTextEncoding,
                onCrlfChanged: (value) {
                  widget.controller.setAppendCrlf(value);
                },
                onExport: () => unawaited(_exportLogs()),
                onClear: _clearLogs,
              ),
              const SizedBox(height: 10),
              SendPanel(controller: widget.controller),
            ],
          ),
        );
      },
    );
  }
}

class _LogHeader extends StatelessWidget {
  const _LogHeader({
    required this.count,
    required this.filter,
    required this.hasVisibleLogs,
    required this.onFilterChanged,
    required this.onFullScreen,
  });

  final int count;
  final _LogFilter filter;
  final bool hasVisibleLogs;
  final ValueChanged<_LogFilter> onFilterChanged;
  final VoidCallback onFullScreen;

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
            Icons.article_outlined,
            size: 17,
            color: colors.primaryDeep,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  '通信日志',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (count > 0) ...<Widget>[
                const SizedBox(width: 4),
                Container(
                  key: const ValueKey<String>('log-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: colors.primaryDeep,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 4),
        _LogFilterMenu(selected: filter, onSelected: onFilterChanged),
        _LogToolButton(
          tooltip: '全屏查看日志',
          icon: Icons.fullscreen_rounded,
          onPressed: hasVisibleLogs ? onFullScreen : null,
        ),
      ],
    );
  }
}

enum _LogFilter {
  all('全部'),
  received('接收'),
  sent('发送');

  const _LogFilter(this.label);

  final String label;
}

class _LogFilterMenu extends StatelessWidget {
  const _LogFilterMenu({required this.selected, required this.onSelected});

  final _LogFilter selected;
  final ValueChanged<_LogFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<_LogFilter>(
      tooltip: '筛选日志',
      initialValue: selected,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) {
        return _LogFilter.values
            .map((filter) {
              final isSelected = filter == selected;
              return PopupMenuItem<_LogFilter>(
                value: filter,
                child: Row(
                  children: <Widget>[
                    Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: isSelected ? colors.primaryDeep : colors.inkMuted,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      filter.label,
                      style: TextStyle(
                        color: isSelected ? colors.primaryDeep : colors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(
          selected == _LogFilter.all
              ? Icons.filter_alt_outlined
              : Icons.filter_alt_rounded,
          size: 19,
          color: selected == _LogFilter.all ? colors.ink : colors.primaryDeep,
        ),
      ),
    );
  }
}

class _LogToolButton extends StatelessWidget {
  const _LogToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 36, height: 44),
      padding: const EdgeInsets.all(5),
      icon: Icon(icon, size: 18),
    );
  }
}

class _DisplayControls extends StatelessWidget {
  const _DisplayControls({
    required this.format,
    required this.textEncoding,
    required this.appendCrlf,
    required this.hasLogs,
    required this.onFormatChanged,
    required this.onEncodingChanged,
    required this.onCrlfChanged,
    required this.onExport,
    required this.onClear,
  });

  final PayloadFormat format;
  final TextEncoding textEncoding;
  final bool appendCrlf;
  final bool hasLogs;
  final ValueChanged<PayloadFormat> onFormatChanged;
  final ValueChanged<TextEncoding> onEncodingChanged;
  final ValueChanged<bool> onCrlfChanged;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _FormatToggle(format: format, onChanged: onFormatChanged),
        const SizedBox(width: 3),
        const SizedBox(
          height: 26,
          child: VerticalDivider(width: 1, thickness: 1),
        ),
        const SizedBox(width: 1),
        _EncodingMenu(selected: textEncoding, onSelected: onEncodingChanged),
        const SizedBox(width: 2),
        _CrlfControl(value: appendCrlf, onChanged: onCrlfChanged),
        const Spacer(),
        _InlineLogAction(
          tooltip: '导出日志',
          icon: Icons.file_download_outlined,
          onPressed: hasLogs ? onExport : null,
        ),
        const SizedBox(width: 6),
        _InlineLogAction(
          tooltip: '清空日志',
          icon: Icons.delete_outline_rounded,
          onPressed: hasLogs ? onClear : null,
        ),
      ],
    );
  }
}

class _InlineLogAction extends StatelessWidget {
  const _InlineLogAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(30),
        maximumSize: const Size.square(30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _FormatToggle extends StatelessWidget {
  const _FormatToggle({required this.format, required this.onChanged});

  final PayloadFormat format;
  final ValueChanged<PayloadFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      key: const ValueKey<String>('receive-format-toggle'),
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _FormatOption(
            key: const ValueKey<String>('receive-format-text'),
            label: '文本',
            selected: format == PayloadFormat.text,
            onTap: () => onChanged(PayloadFormat.text),
          ),
          _FormatOption(
            key: const ValueKey<String>('receive-format-hex'),
            label: 'HEX',
            selected: format == PayloadFormat.hex,
            onTap: () => onChanged(PayloadFormat.hex),
          ),
        ],
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Container(
          width: 36,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.surface,
            border: Border.all(
              color: selected ? colors.selectedBorder : colors.outline,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primaryDeep : colors.inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EncodingMenu extends StatelessWidget {
  const _EncodingMenu({required this.selected, required this.onSelected});

  final TextEncoding selected;
  final ValueChanged<TextEncoding> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<TextEncoding>(
      key: const ValueKey<String>('encoding-menu'),
      tooltip: '选择编码',
      initialValue: selected,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) {
        return TextEncoding.values
            .map((encoding) {
              final isSelected = encoding == selected;
              return PopupMenuItem<TextEncoding>(
                value: encoding,
                child: Row(
                  children: <Widget>[
                    Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: isSelected ? colors.primaryDeep : colors.inkMuted,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      encoding.label,
                      style: TextStyle(
                        color: isSelected ? colors.primaryDeep : colors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              selected.label,
              style: TextStyle(
                color: colors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: colors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CrlfControl extends StatelessWidget {
  const _CrlfControl({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      key: const ValueKey<String>('crlf-control'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 23,
              height: 23,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'CRLF',
              style: TextStyle(
                color: colors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({
    required this.entries,
    required this.format,
    required this.textEncoding,
    this.scrollController,
  });

  final List<LogEntry> entries;
  final PayloadFormat format;
  final TextEncoding textEncoding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _LogRow(
            entry: entries[index],
            format: format,
            textEncoding: textEncoding,
          );
        },
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.entry,
    required this.format,
    required this.textEncoding,
  });

  final LogEntry entry;
  final PayloadFormat format;
  final TextEncoding textEncoding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = _renderEntry(entry, format, textEncoding);
    final color = switch (entry.direction) {
      LogDirection.sent => colors.primary,
      LogDirection.received => colors.receive,
      LogDirection.system => colors.warning,
    };
    final icon = switch (entry.direction) {
      LogDirection.sent => Icons.arrow_upward_rounded,
      LogDirection.received => Icons.arrow_downward_rounded,
      LogDirection.system => Icons.info_outline_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 83,
            child: Text(
              formatLogTimestamp(entry.timestamp),
              style: TextStyle(
                color: colors.inkMuted,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                height: 1.35,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLogState extends StatelessWidget {
  const _EmptyLogState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 92,
            height: 78,
            child: CustomPaint(painter: _OpenBoxPainter(colors: colors)),
          ),
          const SizedBox(height: 6),
          Text(
            '暂无通信日志',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: 5),
          Text('连接设备后即可收发数据', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.filter_alt_outlined, size: 48, color: colors.mutedIcon),
          const SizedBox(height: 8),
          Text('当前筛选下暂无日志', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _OpenBoxPainter extends CustomPainter {
  const _OpenBoxPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = colors.illustrationShadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.53, size.height * 0.88),
        width: size.width * 0.65,
        height: size.height * 0.13,
      ),
      shadow,
    );

    final left = Path()
      ..moveTo(size.width * 0.27, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.58)
      ..lineTo(size.width * 0.5, size.height * 0.88)
      ..lineTo(size.width * 0.25, size.height * 0.72)
      ..close();
    canvas.drawPath(left, Paint()..color = colors.illustrationMid);

    final right = Path()
      ..moveTo(size.width * 0.5, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.43)
      ..lineTo(size.width * 0.77, size.height * 0.73)
      ..lineTo(size.width * 0.5, size.height * 0.88)
      ..close();
    canvas.drawPath(right, Paint()..color = colors.illustrationOutline);

    final inner = Path()
      ..moveTo(size.width * 0.25, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height * 0.58)
      ..lineTo(size.width * 0.77, size.height * 0.73)
      ..lineTo(size.width * 0.5, size.height * 0.87)
      ..close();
    canvas.drawPath(inner, Paint()..color = colors.illustrationLight);

    final flapLeft = Path()
      ..moveTo(size.width * 0.25, size.height * 0.44)
      ..lineTo(size.width * 0.5, size.height * 0.56)
      ..lineTo(size.width * 0.35, size.height * 0.65)
      ..lineTo(size.width * 0.13, size.height * 0.52)
      ..close();
    canvas.drawPath(flapLeft, Paint()..color = colors.illustrationLightest);

    final flapRight = Path()
      ..moveTo(size.width * 0.5, size.height * 0.56)
      ..lineTo(size.width * 0.76, size.height * 0.4)
      ..lineTo(size.width * 0.93, size.height * 0.53)
      ..lineTo(size.width * 0.67, size.height * 0.68)
      ..close();
    canvas.drawPath(flapRight, Paint()..color = colors.illustrationFold);

    final rayPaint = Paint()
      ..color = colors.illustrationOutline
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.29),
      Offset(size.width * 0.19, size.height * 0.36),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.2, size.height * 0.28),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.29, size.height * 0.14),
      Offset(size.width * 0.27, size.height * 0.24),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OpenBoxPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _FullScreenLogSheet extends StatefulWidget {
  const _FullScreenLogSheet({
    required this.entries,
    required this.format,
    required this.textEncoding,
  });

  final List<LogEntry> entries;
  final PayloadFormat format;
  final TextEncoding textEncoding;

  @override
  State<_FullScreenLogSheet> createState() => _FullScreenLogSheetState();
}

class _FullScreenLogSheetState extends State<_FullScreenLogSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> get _visibleEntries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.entries;
    }
    return widget.entries
        .where((entry) {
          return _renderEntry(
            entry,
            widget.format,
            widget.textEncoding,
          ).toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visibleEntries = _visibleEntries;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 19,
                  color: colors.primaryDeep,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '通信日志(${widget.entries.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: _searchOpen ? '关闭搜索' : '搜索日志',
                onPressed: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchController.clear();
                    }
                  });
                },
                icon: Icon(
                  _searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                ),
              ),
              IconButton(
                tooltip: '关闭全屏日志',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        if (_searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索日志内容',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: () {
                          setState(_searchController.clear);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              border: Border.all(color: colors.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: visibleEntries.isEmpty
                ? const _FullScreenLogEmptyState()
                : _LogList(
                    entries: visibleEntries,
                    format: widget.format,
                    textEncoding: widget.textEncoding,
                  ),
          ),
        ),
      ],
    );
  }
}

class _FullScreenLogEmptyState extends StatelessWidget {
  const _FullScreenLogEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.manage_search_rounded, size: 52, color: colors.mutedIcon),
          const SizedBox(height: 8),
          Text('未找到匹配日志', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _renderEntry(
  LogEntry entry,
  PayloadFormat format,
  TextEncoding textEncoding,
) {
  final payloadFormat = entry.direction == LogDirection.system
      ? PayloadFormat.text
      : format;
  return clampRenderedText(
    PayloadCodec.format(
      entry.copyBytes(),
      format: payloadFormat,
      textEncoding: textEncoding,
    ),
  );
}
