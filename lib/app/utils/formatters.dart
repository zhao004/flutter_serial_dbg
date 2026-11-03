import 'constants.dart';

/// 将日志时间格式化为仅保留毫秒的本地时间。
String formatLogTimestamp(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  final millisecond = local.millisecond.toString().padLeft(3, '0');
  return '$hour:$minute:$second.$millisecond';
}

/// 限制单条日志的渲染长度，避免超长报文阻塞列表布局。
String clampRenderedText(String value) {
  if (value.length <= LogLimits.maxRenderedCharacters) {
    return value;
  }
  return '${value.substring(0, LogLimits.maxRenderedCharacters)}…';
}
