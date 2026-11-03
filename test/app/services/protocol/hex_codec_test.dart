import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/text_encoding.dart';
import 'package:flutter_serial_dbg/app/services/protocol/hex_codec.dart';
import 'package:flutter_serial_dbg/app/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexCodec', () {
    test('decodes compact and whitespace separated bytes', () {
      expect(HexCodec.decode('aa 55\n01\t02'), <int>[0xAA, 0x55, 0x01, 0x02]);
    });

    test('formats bytes as uppercase hexadecimal', () {
      expect(HexCodec.format(<int>[0x00, 0x0A, 0xFF]), '00 0A FF');
    });

    test('accepts the maximum payload size', () {
      final input = List<String>.filled(
        ProtocolLimits.maxPayloadBytes,
        '00',
      ).join(' ');

      expect(HexCodec.decode(input), hasLength(ProtocolLimits.maxPayloadBytes));
    });

    test('rejects one byte over the maximum payload size', () {
      final input = List<String>.filled(
        ProtocolLimits.maxPayloadBytes + 1,
        '00',
      ).join(' ');

      expect(
        () => HexCodec.decode(input),
        throwsA(
          isA<PayloadFormatException>().having(
            (error) => error.error,
            'error',
            PayloadFormatError.inputTooLarge,
          ),
        ),
      );
    });
  });

  group('PayloadCodec', () {
    test('encodes UTF-8 and appends CRLF when requested', () {
      expect(
        PayloadCodec.encode('OK', format: PayloadFormat.text, appendCrlf: true),
        <int>[0x4F, 0x4B, 0x0D, 0x0A],
      );
      expect(PayloadCodec.encode('你好', format: PayloadFormat.text), <int>[
        0xE4,
        0xBD,
        0xA0,
        0xE5,
        0xA5,
        0xBD,
      ]);
    });

    test('appends CRLF to HEX payloads', () {
      expect(
        PayloadCodec.encode(
          '01 02',
          format: PayloadFormat.hex,
          appendCrlf: true,
        ),
        <int>[0x01, 0x02, 0x0D, 0x0A],
      );
    });

    test('encodes and decodes ASCII text when selected', () {
      final bytes = PayloadCodec.encode(
        'OK',
        format: PayloadFormat.text,
        textEncoding: TextEncoding.ascii,
      );

      expect(bytes, <int>[0x4F, 0x4B]);
      expect(
        PayloadCodec.format(
          bytes,
          format: PayloadFormat.text,
          textEncoding: TextEncoding.ascii,
        ),
        'OK',
      );
    });

    test('rejects non-ASCII characters when ASCII is selected', () {
      expect(
        () => PayloadCodec.encode(
          '你好',
          format: PayloadFormat.text,
          textEncoding: TextEncoding.ascii,
        ),
        throwsA(
          isA<PayloadFormatException>().having(
            (error) => error.error,
            'error',
            PayloadFormatError.invalidTextEncoding,
          ),
        ),
      );
    });

    test('rejects empty text instead of sending an empty frame', () {
      expect(
        () => PayloadCodec.encode('', format: PayloadFormat.text),
        throwsA(
          isA<PayloadFormatException>().having(
            (error) => error.error,
            'error',
            PayloadFormatError.empty,
          ),
        ),
      );
    });

    test('formats malformed text without throwing', () {
      expect(
        PayloadCodec.format(
          Uint8List.fromList(<int>[0xFF]),
          format: PayloadFormat.text,
        ),
        isNotEmpty,
      );
    });
  });
}
