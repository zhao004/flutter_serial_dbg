import 'connection_mode.dart';

/// 日志历史列表使用的会话摘要。
final class LogSessionSummary {
  LogSessionSummary({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.entryCount,
    required this.byteCount,
    this.endedAt,
  }) {
    if (id < 0) {
      throw ArgumentError.value(id, 'id', '不能小于 0');
    }
    if (entryCount < 0) {
      throw ArgumentError.value(entryCount, 'entryCount', '不能小于 0');
    }
    if (byteCount < 0) {
      throw ArgumentError.value(byteCount, 'byteCount', '不能小于 0');
    }
    final ended = endedAt;
    if (ended != null && ended.isBefore(startedAt)) {
      throw ArgumentError.value(endedAt, 'endedAt', '不能早于开始时间');
    }
  }

  final int id;
  final ConnectionMode mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int entryCount;
  final int byteCount;

  /// 会话是否尚未正常结束。
  bool get isActive => endedAt == null;

  /// 已结束会话的实际时长；进行中的会话返回 null。
  Duration? get duration => endedAt?.difference(startedAt);
}
