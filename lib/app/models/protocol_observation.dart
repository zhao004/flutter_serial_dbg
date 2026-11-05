import 'protocol_event.dart';

/// 带发生时间的协议解析结果，仅用于当前界面展示。
final class ProtocolObservation {
  const ProtocolObservation({required this.occurredAt, required this.event});

  final DateTime occurredAt;
  final ProtocolEvent event;
}
