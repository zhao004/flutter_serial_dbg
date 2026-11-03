import 'dart:collection';

import '../../models/log_entry.dart';
import '../../utils/constants.dart';

/// 同时受条目数和总字节数约束的有界日志缓冲。
final class LogBuffer {
  LogBuffer({
    this.maxEntries = LogLimits.maxEntries,
    this.maxBytes = LogLimits.maxBytes,
  }) {
    if (maxEntries <= 0 || maxBytes <= 0) {
      throw ArgumentError('日志上限必须大于 0');
    }
  }

  final int maxEntries;
  final int maxBytes;
  final List<LogEntry> _entries = <LogEntry>[];
  int _byteLength = 0;

  /// 当前日志只读快照。
  List<LogEntry> get entries => UnmodifiableListView<LogEntry>(_entries);

  /// 添加日志并按上限淘汰最早条目。
  void add(LogEntry entry) {
    _entries.add(entry);
    _byteLength += entry.bytes.length;
    while (_entries.length > maxEntries || _byteLength > maxBytes) {
      final removed = _entries.removeAt(0);
      _byteLength -= removed.bytes.length;
    }
  }

  /// 清空全部内存日志。
  void clear() {
    _entries.clear();
    _byteLength = 0;
  }
}
