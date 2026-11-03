import 'dart:collection';
import 'dart:typed_data';

import '../../models/protocol_event.dart';
import '../../utils/constants.dart';

/// 从候选帧起始位置解析完整帧长度。
///
/// 返回 null 表示当前数据不足，无法确定长度；非法长度应抛出
/// [FormatException]。
typedef FrameLengthResolver = int? Function(List<int> bytes);

/// 校验完整候选帧。
///
/// 返回 null 表示通过，否则返回稳定的拒绝原因。
typedef FrameValidator = FrameRejectionReason? Function(List<int> frame);

/// 将已校验的完整帧转换为协议事件。
typedef FrameEventFactory = ProtocolEvent Function(Uint8List frame);

/// 可配置增量帧解析器配置。
final class FrameParserConfig {
  FrameParserConfig({
    required List<int> header,
    required this.resolveFrameLength,
    required this.createFrameEvent,
    this.validateFrame,
    this.maxBufferedBytes = ProtocolLimits.maxFrameBufferBytes,
  }) : header = UnmodifiableListView<int>(List<int>.from(header)) {
    if (header.isEmpty) {
      throw ArgumentError.value(header, 'header', '帧头不能为空');
    }
    if (header.any((byte) => byte < 0 || byte > 0xFF)) {
      throw ArgumentError.value(header, 'header', '帧头必须由单字节值组成');
    }
    if (maxBufferedBytes < header.length) {
      throw ArgumentError.value(
        maxBufferedBytes,
        'maxBufferedBytes',
        '不能小于帧头长度',
      );
    }
  }

  final UnmodifiableListView<int> header;
  final FrameLengthResolver resolveFrameLength;
  final FrameEventFactory createFrameEvent;
  final FrameValidator? validateFrame;
  final int maxBufferedBytes;
}

/// 支持分包、粘包和噪声恢复的增量帧解析器。
final class FrameParser {
  FrameParser({required this.config});

  final FrameParserConfig config;
  final List<int> _buffer = <int>[];

  /// 写入一段新字节并返回本次可确定的协议事件。
  List<ProtocolEvent> add(Uint8List chunk) {
    final events = <ProtocolEvent>[];
    for (final byte in chunk) {
      _buffer.add(byte);
      _drain(events);
      if (_buffer.length > config.maxBufferedBytes) {
        events.add(
          ProtocolFrameRejected(
            reason: FrameRejectionReason.bufferOverflow,
            discardedBytes: Uint8List.fromList(_buffer),
          ),
        );
        _buffer.clear();
      }
    }
    return events;
  }

  /// 清空未完成帧和噪声数据。
  void reset() {
    _buffer.clear();
  }

  void _drain(List<ProtocolEvent> events) {
    while (_buffer.isNotEmpty) {
      _discardNoise();
      if (_buffer.isEmpty) {
        return;
      }

      final int? expectedLength;
      try {
        expectedLength = config.resolveFrameLength(
          UnmodifiableListView<int>(_buffer),
        );
      } on FormatException {
        _rejectInvalidLength(events);
        continue;
      }
      if (expectedLength == null) {
        return;
      }
      if (expectedLength <= config.header.length ||
          expectedLength > config.maxBufferedBytes) {
        _rejectInvalidLength(events);
        continue;
      }
      if (_buffer.length < expectedLength) {
        return;
      }

      final frame = Uint8List.fromList(_buffer.sublist(0, expectedLength));
      _buffer.removeRange(0, expectedLength);
      final rejection = config.validateFrame?.call(frame);
      if (rejection != null) {
        events.add(
          ProtocolFrameRejected(reason: rejection, discardedBytes: frame),
        );
        continue;
      }
      events.add(config.createFrameEvent(frame));
    }
  }

  void _rejectInvalidLength(List<ProtocolEvent> events) {
    final discardedLength = _buffer.length < config.header.length
        ? _buffer.length
        : config.header.length;
    events.add(
      ProtocolFrameRejected(
        reason: FrameRejectionReason.invalidLength,
        discardedBytes: Uint8List.fromList(
          _buffer.take(discardedLength).toList(growable: false),
        ),
      ),
    );
    _buffer.removeAt(0);
  }

  void _discardNoise() {
    final headerIndex = _indexOfHeader();
    if (headerIndex >= 0) {
      if (headerIndex > 0) {
        _buffer.removeRange(0, headerIndex);
      }
      return;
    }

    final keepLength = _matchingHeaderSuffixLength();
    final discardLength = _buffer.length - keepLength;
    if (discardLength > 0) {
      _buffer.removeRange(0, discardLength);
    }
  }

  int _indexOfHeader() {
    final maxStart = _buffer.length - config.header.length;
    for (var start = 0; start <= maxStart; start++) {
      var matches = true;
      for (var offset = 0; offset < config.header.length; offset++) {
        if (_buffer[start + offset] != config.header[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return start;
      }
    }
    return -1;
  }

  int _matchingHeaderSuffixLength() {
    final maximum = _buffer.length < config.header.length - 1
        ? _buffer.length
        : config.header.length - 1;
    for (var length = maximum; length > 0; length--) {
      var matches = true;
      final bufferStart = _buffer.length - length;
      for (var offset = 0; offset < length; offset++) {
        if (_buffer[bufferStart + offset] != config.header[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return length;
      }
    }
    return 0;
  }
}
