import 'dart:convert';
import 'dart:io';

import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/protocol_event.dart';
import 'package:flutter_serial_dbg/app/services/protocol/hex_codec.dart';
import 'package:flutter_serial_dbg/app/services/protocol/serial_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/protocol_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('fixture contains at least twenty explicit vectors', () {
    final total =
        (fixture['hexCases'] as List<dynamic>).length +
        (fixture['invalidHexCases'] as List<dynamic>).length +
        (fixture['textCases'] as List<dynamic>).length +
        (fixture['frameCases'] as List<dynamic>).length;

    expect(total, greaterThanOrEqualTo(20));
  });

  test('all documented HEX vectors match', () {
    for (final item in (fixture['hexCases'] as List<dynamic>).cast<Map>()) {
      final input = item['input'] as String;
      final expected = item['expected'] as String;
      expect(
        HexCodec.format(HexCodec.decode(input)),
        expected,
        reason: item['name'] as String,
      );
    }
  });

  test('all documented invalid HEX vectors expose stable errors', () {
    for (final item
        in (fixture['invalidHexCases'] as List<dynamic>).cast<Map>()) {
      final input = item['input'] as String;
      final expectedError = item['error'] as String;
      expect(
        () => HexCodec.decode(input),
        throwsA(
          isA<PayloadFormatException>().having(
            (error) => error.error.name,
            'error',
            expectedError,
          ),
        ),
        reason: item['name'] as String,
      );
    }
  });

  test('all documented text vectors match', () {
    for (final item in (fixture['textCases'] as List<dynamic>).cast<Map>()) {
      final bytes = PayloadCodec.encode(
        item['input'] as String,
        format: PayloadFormat.text,
        appendCrlf: item['appendCrlf'] as bool,
      );
      expect(
        HexCodec.format(bytes),
        item['expected'],
        reason: item['name'] as String,
      );
    }
  });

  test('all documented provisional AA55 vectors match', () {
    for (final item in (fixture['frameCases'] as List<dynamic>).cast<Map>()) {
      final protocol = Aa55SerialProtocol();
      final events = <ProtocolEvent>[];
      for (final chunk in (item['chunks'] as List<dynamic>).cast<String>()) {
        events.addAll(protocol.decode(HexCodec.decode(chunk)));
      }

      final expectedEvents = (item['events'] as List<dynamic>)
          .cast<Map<dynamic, dynamic>>();
      expect(events, hasLength(expectedEvents.length), reason: item['name']);
      for (var index = 0; index < expectedEvents.length; index++) {
        _expectEvent(
          events[index],
          expectedEvents[index],
          item['name'] as String,
        );
      }
    }
  });
}

void _expectEvent(
  ProtocolEvent event,
  Map<dynamic, dynamic> expected,
  String? reason,
) {
  switch (event) {
    case ProtocolFrameReceived():
      expect(expected['type'], 'frame', reason: reason);
      expect(event.command, expected['command'], reason: reason);
      expect(
        HexCodec.format(event.payload),
        expected['payload'],
        reason: reason,
      );
    case ProtocolFrameRejected():
      expect(expected['type'], 'rejection', reason: reason);
      expect(event.reason.name, expected['reason'], reason: reason);
  }
}
