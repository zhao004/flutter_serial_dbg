import 'log_entry.dart';

/// 可持久化的界面与发送偏好。
final class AppPreferences {
  const AppPreferences({
    this.sendFormat = PayloadFormat.text,
    this.receiveFormat = PayloadFormat.text,
    this.appendCrlf = false,
    this.autoScroll = true,
    this.persistSessionLogs = true,
    this.logRetentionSessions = defaultLogRetentionSessions,
  }) : assert(logRetentionSessions > 0);

  /// 默认保留的日志会话数量。
  static const int defaultLogRetentionSessions = 20;

  /// 设置界面可选择的日志会话保留数量。
  static const List<int> supportedLogRetentionSessions = <int>[10, 20, 50];

  final PayloadFormat sendFormat;
  final PayloadFormat receiveFormat;
  final bool appendCrlf;
  final bool autoScroll;
  final bool persistSessionLogs;
  final int logRetentionSessions;

  /// 返回更新后的不可变设置快照。
  AppPreferences copyWith({
    PayloadFormat? sendFormat,
    PayloadFormat? receiveFormat,
    bool? appendCrlf,
    bool? autoScroll,
    bool? persistSessionLogs,
    int? logRetentionSessions,
  }) {
    return AppPreferences(
      sendFormat: sendFormat ?? this.sendFormat,
      receiveFormat: receiveFormat ?? this.receiveFormat,
      appendCrlf: appendCrlf ?? this.appendCrlf,
      autoScroll: autoScroll ?? this.autoScroll,
      persistSessionLogs: persistSessionLogs ?? this.persistSessionLogs,
      logRetentionSessions: logRetentionSessions ?? this.logRetentionSessions,
    );
  }
}
