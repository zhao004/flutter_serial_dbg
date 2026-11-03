/// Ping 操作结果分类。
enum PingStatus { success, timeout, unreachable, error }

/// 网络诊断 Ping 的不可变结果。
final class PingResult {
  PingResult({
    required String target,
    required this.status,
    required this.duration,
    this.message,
  }) : target = _validateTarget(target) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', '不能为负数');
    }
  }

  final String target;
  final PingStatus status;
  final Duration duration;
  final String? message;
}

String _validateTarget(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'target', '不能为空');
  }
  return normalized;
}
