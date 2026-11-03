import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/protocol_event.dart';
import 'package:flutter_serial_dbg/app/services/protocol/hex_codec.dart';
import 'package:flutter_serial_dbg/app/services/protocol/serial_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes the documented provisional AA55 profile', () {
    final protocol = Aa55SerialProtocol();

    final frame = protocol.encode(
      command: 0x02,
      payload: Uint8List.fromList(<int>[0x0A, 0x0B, 0x0C]),
    );

    expect(HexCodec.format(frame), 'AA 55 02 03 0A 0B 0C 0C');
  });

  test('decodes an encoded frame without losing bytes', () {
    final protocol = Aa55SerialProtocol();
    final payload = Uint8List.fromList(<int>[0x10, 0x20, 0x30]);
    final frame = protocol.encode(command: 0x42, payload: payload);

    final events = protocol.decode(frame);
    final received = events.single as ProtocolFrameReceived;

    expect(received.command, 0x42);
    expect(received.payload, payload);
    expect(received.rawFrame, frame);
  });

  test('rejects payloads that exceed the provisional length field', () {
    final protocol = Aa55SerialProtocol();

    expect(
      () => protocol.encode(command: 0x01, payload: Uint8List(256)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('reset discards an incomplete frame', () {
    final protocol = Aa55SerialProtocol();
    protocol.decode(Uint8List.fromList(<int>[0xAA, 0x55, 0x10]));

    protocol.reset();

    expect(protocol.decode(Uint8List.fromList(<int>[0x01])), isEmpty);
  });
}
