import 'package:material_ui/material_ui.dart';

import '../models/log_entry.dart';
import '../models/text_encoding.dart';
import '../services/protocol/hex_codec.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 将日志条目按指定格式转换为可展示文本。
String formatLogEntry(
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

/// 首页和历史详情共用的只读日志列表。
class AppLogEntryList extends StatelessWidget {
  const AppLogEntryList({
    super.key,
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
          return AppLogEntryRow(
            entry: entries[index],
            format: format,
            textEncoding: textEncoding,
          );
        },
      ),
    );
  }
}

/// 单条通信日志的视觉呈现。
class AppLogEntryRow extends StatelessWidget {
  const AppLogEntryRow({
    super.key,
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
    final text = formatLogEntry(entry, format, textEncoding);
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
