import 'dart:collection';
import 'dart:typed_data';

/// 帧被拒绝的原因。
enum FrameRejectionReason {
  invalidLength,
  checksumMismatch,
  invalidFrame,
  bufferOverflow,
}

/// 协议解析产生的不可变事件。
sealed class ProtocolEvent {
  const ProtocolEvent();
}

/// 已通过帧结构校验的原始协议帧。
final class ProtocolFrameReceived extends ProtocolEvent {
  ProtocolFrameReceived({
    required this.command,
    required Uint8List payload,
    required Uint8List rawFrame,
  }) : _payload = UnmodifiableListView<int>(Uint8List.fromList(payload)),
       _rawFrame = UnmodifiableListView<int>(Uint8List.fromList(rawFrame)) {
    if (command < 0 || command > 0xFF) {
      throw ArgumentError.value(command, 'command', '必须是单字节值');
    }
  }

  final int command;
  final UnmodifiableListView<int> _payload;
  final UnmodifiableListView<int> _rawFrame;

  /// 命令对应的负载字节。
  List<int> get payload => _payload;

  /// 包含帧头、命令、长度、负载和校验字节的完整帧。
  List<int> get rawFrame => _rawFrame;

  /// 返回独立负载副本。
  Uint8List copyPayload() => Uint8List.fromList(_payload);

  /// 返回独立完整帧副本。
  Uint8List copyRawFrame() => Uint8List.fromList(_rawFrame);

  @override
  String toString() {
    return 'ProtocolFrameReceived('
        'command: 0x${command.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
        'payloadLength: ${_payload.length}'
        ')';
  }
}

/// 未通过长度或校验检查而被丢弃的数据。
final class ProtocolFrameRejected extends ProtocolEvent {
  ProtocolFrameRejected({
    required this.reason,
    required Uint8List discardedBytes,
  }) : _discardedBytes = UnmodifiableListView<int>(
         Uint8List.fromList(discardedBytes),
       );

  final FrameRejectionReason reason;
  final UnmodifiableListView<int> _discardedBytes;

  /// 被解析器丢弃的字节，仅供测试和诊断使用。
  List<int> get discardedBytes => _discardedBytes;

  /// 返回独立丢弃字节副本。
  Uint8List copyDiscardedBytes() => Uint8List.fromList(_discardedBytes);

  @override
  String toString() {
    return 'ProtocolFrameRejected('
        'reason: $reason, '
        'discardedLength: ${_discardedBytes.length}'
        ')';
  }
}
