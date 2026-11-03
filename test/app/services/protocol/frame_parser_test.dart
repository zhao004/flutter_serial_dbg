import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/protocol_event.dart';
import 'package:flutter_serial_dbg/app/services/protocol/frame_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a custom fixed length frame across chunks', () {
    final parser = FrameParser(config: _fixedLengthConfig());

    expect(parser.add(Uint8List.fromList(<int>[0xDE, 0xAD, 0x01])), isEmpty);
    final events = parser.add(
      Uint8List.fromList(<int>[0x02, 0xDE, 0xAD, 0x03, 0x04]),
    );
    final frames = events.whereType<ProtocolFrameReceived>().toList();

    expect(frames, hasLength(2));
    expect(frames[0].command, 0x01);
    expect(frames[0].payload, <int>[0x02]);
    expect(frames[1].command, 0x03);
    expect(frames[1].payload, <int>[0x04]);
  });

  test('reports invalid length and recovers at the next header', () {
    final parser = FrameParser(
      config: FrameParserConfig(
        header: const <int>[0xDE, 0xAD],
        resolveFrameLength: (bytes) {
          if (bytes.length < 3) {
            return null;
          }
          if (bytes[2] == 0xFF) {
            throw const FormatException('invalid length');
          }
          return 4;
        },
        createFrameEvent: _createFixedLengthEvent,
      ),
    );

    final events = parser.add(
      Uint8List.fromList(<int>[0xDE, 0xAD, 0xFF, 0xDE, 0xAD, 0x01, 0x02]),
    );

    expect(events, hasLength(2));
    expect(
      events.first,
      isA<ProtocolFrameRejected>().having(
        (event) => event.reason,
        'reason',
        FrameRejectionReason.invalidLength,
      ),
    );
    expect(events.last, isA<ProtocolFrameReceived>());
  });

  test('drops buffered data after exceeding the configured limit', () {
    final parser = FrameParser(
      config: FrameParserConfig(
        header: const <int>[0xAA, 0x55],
        resolveFrameLength: (_) => null,
        createFrameEvent: _createFixedLengthEvent,
        maxBufferedBytes: 4,
      ),
    );

    final events = parser.add(
      Uint8List.fromList(<int>[0xAA, 0x55, 0x01, 0x02, 0x03]),
    );

    expect(events, hasLength(1));
    expect(
      events.single,
      isA<ProtocolFrameRejected>().having(
        (event) => event.reason,
        'reason',
        FrameRejectionReason.bufferOverflow,
      ),
    );
  });

  test('reset removes an incomplete frame', () {
    final parser = FrameParser(config: _fixedLengthConfig());
    parser.add(Uint8List.fromList(<int>[0xDE, 0xAD, 0x01]));

    parser.reset();

    expect(parser.add(Uint8List.fromList(<int>[0x02, 0x03, 0x04])), isEmpty);
  });
}

FrameParserConfig _fixedLengthConfig() {
  return FrameParserConfig(
    header: const <int>[0xDE, 0xAD],
    resolveFrameLength: (bytes) => bytes.length < 4 ? null : 4,
    createFrameEvent: _createFixedLengthEvent,
  );
}

ProtocolEvent _createFixedLengthEvent(Uint8List frame) {
  return ProtocolFrameReceived(
    command: frame[2],
    payload: Uint8List.fromList(<int>[frame[3]]),
    rawFrame: frame,
  );
}
