import 'dart:typed_data';

import '../../models/protocol_event.dart';
import '../../utils/constants.dart';
import 'frame_parser.dart';

/// 串口数据负载协议的统一接口。
abstract interface class SerialProtocol {
  /// 将命令和负载编码为完整协议帧。
  Uint8List encode({required int command, required Uint8List payload});

  /// 解析一段可能跨包到达的接收字节。
  List<ProtocolEvent> decode(Uint8List chunk);

  /// 清空跨包解析状态。
  void reset();
}

/// 临时 AA55 帧布局，仅在原 APK 基线缺失期间使用。
///
/// 默认布局为 `AA 55 | CMD | LEN | PAYLOAD | XOR`。其中 LEN 是单字节
/// 负载长度，XOR 覆盖从 CMD 到 PAYLOAD 的字节，不包含帧头与校验字节。
final class Aa55FrameProfile {
  Aa55FrameProfile({
    List<int> header = const <int>[0xAA, 0x55],
    this.commandOffset = 2,
    this.lengthOffset = 3,
    this.payloadOffset = 4,
    this.checksumStartOffset = 2,
    this.maxPayloadBytes = ProtocolLimits.maxAa55PayloadBytes,
  }) : header = List<int>.unmodifiable(List<int>.from(header)) {
    if (header.isEmpty) {
      throw ArgumentError.value(header, 'header', '帧头不能为空');
    }
    if (header.any((byte) => byte < 0 || byte > 0xFF)) {
      throw ArgumentError.value(header, 'header', '帧头必须由单字节值组成');
    }
    if (commandOffset < header.length ||
        lengthOffset < header.length ||
        payloadOffset != lengthOffset + 1) {
      throw ArgumentError('AA55 profile 的命令、长度和负载偏移无效');
    }
    if (commandOffset == lengthOffset ||
        checksumStartOffset < 0 ||
        checksumStartOffset >= payloadOffset) {
      throw ArgumentError('AA55 profile 的校验范围无效');
    }
    if (maxPayloadBytes <= 0 || maxPayloadBytes > 0xFF) {
      throw ArgumentError.value(
        maxPayloadBytes,
        'maxPayloadBytes',
        '必须位于 1 到 255 之间',
      );
    }
  }

  final List<int> header;
  final int commandOffset;
  final int lengthOffset;
  final int payloadOffset;
  final int checksumStartOffset;
  final int maxPayloadBytes;

  /// 根据长度字段计算包含校验字节的完整帧长度。
  int? resolveFrameLength(List<int> bytes) {
    if (bytes.length <= lengthOffset) {
      return null;
    }
    final payloadLength = bytes[lengthOffset];
    if (payloadLength > maxPayloadBytes) {
      throw const FormatException('协议负载长度超过 Profile 上限');
    }
    return payloadOffset + payloadLength + 1;
  }

  /// 验证候选帧的 XOR 校验字节。
  FrameRejectionReason? validateFrame(List<int> frame) {
    if (frame.length <= payloadOffset) {
      return FrameRejectionReason.invalidFrame;
    }
    final checksumIndex = frame.length - 1;
    if (checksumIndex < checksumStartOffset) {
      return FrameRejectionReason.invalidFrame;
    }
    var checksum = 0;
    for (var index = checksumStartOffset; index < checksumIndex; index++) {
      checksum ^= frame[index];
    }
    return checksum == frame[checksumIndex]
        ? null
        : FrameRejectionReason.checksumMismatch;
  }

  /// 将完整帧转换为应用层原始帧事件。
  ProtocolEvent createFrameEvent(Uint8List frame) {
    final checksumIndex = frame.length - 1;
    return ProtocolFrameReceived(
      command: frame[commandOffset],
      payload: Uint8List.fromList(frame.sublist(payloadOffset, checksumIndex)),
      rawFrame: frame,
    );
  }
}

/// 使用临时 AA55 profile 的串口协议实现。
final class Aa55SerialProtocol implements SerialProtocol {
  factory Aa55SerialProtocol({
    Aa55FrameProfile? profile,
    int maxBufferedBytes = ProtocolLimits.maxFrameBufferBytes,
  }) {
    final resolvedProfile = profile ?? Aa55FrameProfile();
    return Aa55SerialProtocol._(
      resolvedProfile,
      FrameParser(
        config: FrameParserConfig(
          header: resolvedProfile.header,
          resolveFrameLength: resolvedProfile.resolveFrameLength,
          validateFrame: resolvedProfile.validateFrame,
          createFrameEvent: resolvedProfile.createFrameEvent,
          maxBufferedBytes: maxBufferedBytes,
        ),
      ),
    );
  }

  Aa55SerialProtocol._(this.profile, this._parser);

  final Aa55FrameProfile profile;
  final FrameParser _parser;

  @override
  Uint8List encode({required int command, required Uint8List payload}) {
    if (command < 0 || command > 0xFF) {
      throw ArgumentError.value(command, 'command', '必须是单字节值');
    }
    if (payload.length > profile.maxPayloadBytes) {
      throw ArgumentError.value(
        payload.length,
        'payload',
        '协议 Profile 负载不能超过 ${profile.maxPayloadBytes} 字节',
      );
    }

    final frame = Uint8List(profile.payloadOffset + payload.length + 1);
    frame.setRange(0, profile.header.length, profile.header);
    frame[profile.commandOffset] = command;
    frame[profile.lengthOffset] = payload.length;
    frame.setRange(
      profile.payloadOffset,
      profile.payloadOffset + payload.length,
      payload,
    );

    var checksum = 0;
    final checksumIndex = frame.length - 1;
    for (
      var index = profile.checksumStartOffset;
      index < checksumIndex;
      index++
    ) {
      checksum ^= frame[index];
    }
    frame[checksumIndex] = checksum;
    return frame;
  }

  @override
  List<ProtocolEvent> decode(Uint8List chunk) => _parser.add(chunk);

  @override
  void reset() => _parser.reset();
}
