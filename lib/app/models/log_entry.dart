import 'dart:collection';
import 'dart:typed_data';

/// 日志条目的传输方向。
enum LogDirection { sent, received, system }

/// 负载在界面中的展示或输入格式。
enum PayloadFormat { text, hex }

/// 单条通信日志的不可变模型。
final class LogEntry {
  LogEntry({
    this.id,
    required this.timestamp,
    required this.direction,
    required this.format,
    required String channel,
    required Uint8List bytes,
  }) : channel = _validateChannel(channel),
       _bytes = UnmodifiableListView<int>(Uint8List.fromList(bytes)) {
    if (id != null && id! < 0) {
      throw ArgumentError.value(id, 'id', '不能小于 0');
    }
  }

  final int? id;
  final DateTime timestamp;
  final LogDirection direction;
  final PayloadFormat format;
  final String channel;
  final UnmodifiableListView<int> _bytes;

  /// 以只读视图暴露原始字节。
  List<int> get bytes => _bytes;

  /// 返回供传输或持久化使用的独立字节副本。
  Uint8List copyBytes() => Uint8List.fromList(_bytes);

  @override
  String toString() {
    return 'LogEntry('
        'id: $id, '
        'direction: $direction, '
        'format: $format, '
        'channel: $channel, '
        'byteLength: ${_bytes.length}'
        ')';
  }
}

String _validateChannel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'channel', '不能为空');
  }
  return normalized;
}
