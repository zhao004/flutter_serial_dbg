import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../models/log_entry.dart';
import '../protocol/hex_codec.dart';

/// 将当前日志交给系统文件选择器导出。
abstract interface class LogExporter {
  /// 返回实际保存路径；用户取消时返回 null。
  Future<String?> export(
    List<LogEntry> entries, {
    required PayloadFormat format,
  });
}

/// 使用 Android Storage Access Framework 的文件导出实现。
final class FileSelectorLogExporter implements LogExporter {
  const FileSelectorLogExporter([this._clock]);

  final DateTime Function()? _clock;

  @override
  Future<String?> export(
    List<LogEntry> entries, {
    required PayloadFormat format,
  }) async {
    final timestamp = (_clock ?? DateTime.now)();
    final suggestedName = 'serial-debug-${_fileTimestamp(timestamp)}.log';
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'Log files',
          extensions: <String>['log', 'txt'],
          mimeTypes: <String>['text/plain'],
        ),
      ],
    );
    if (location == null) {
      return null;
    }
    final text = LogTextFormatter.format(entries, format: format);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(text)),
      mimeType: 'text/plain',
      name: suggestedName,
    );
    await file.saveTo(location.path);
    return location.path;
  }
}

/// 纯文本日志格式，便于单元测试和跨平台复用。
abstract final class LogTextFormatter {
  /// 每行包含时间、方向、通道和当前格式的负载。
  static String format(
    List<LogEntry> entries, {
    required PayloadFormat format,
  }) {
    final buffer = StringBuffer();
    for (final entry in entries) {
      final payload = switch (format) {
        PayloadFormat.text => _escapeText(
          PayloadCodec.format(entry.copyBytes(), format: PayloadFormat.text),
        ),
        PayloadFormat.hex => HexCodec.format(entry.copyBytes()),
      };
      buffer.writeln(
        '${entry.timestamp.toUtc().toIso8601String()} '
        '[${entry.direction.name}] '
        '[${entry.channel}] '
        '$payload',
      );
    }
    return buffer.toString();
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t');
  }
}

String _fileTimestamp(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$year$month$day-$hour$minute$second';
}
