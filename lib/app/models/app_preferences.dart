import 'log_entry.dart';

/// 可持久化的界面与发送偏好。
final class AppPreferences {
  const AppPreferences({
    this.sendFormat = PayloadFormat.text,
    this.receiveFormat = PayloadFormat.text,
    this.appendCrlf = false,
    this.autoScroll = true,
  });

  final PayloadFormat sendFormat;
  final PayloadFormat receiveFormat;
  final bool appendCrlf;
  final bool autoScroll;

  /// 返回更新后的不可变设置快照。
  AppPreferences copyWith({
    PayloadFormat? sendFormat,
    PayloadFormat? receiveFormat,
    bool? appendCrlf,
    bool? autoScroll,
  }) {
    return AppPreferences(
      sendFormat: sendFormat ?? this.sendFormat,
      receiveFormat: receiveFormat ?? this.receiveFormat,
      appendCrlf: appendCrlf ?? this.appendCrlf,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }
}
