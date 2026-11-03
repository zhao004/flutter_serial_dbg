import 'package:flutter_serial_dbg/app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('USB baud rate validation', () {
    test('parses boundary values', () {
      expect(parseUsbBaudRateInput('50'), 50);
      expect(parseUsbBaudRateInput('4000000'), 4000000);
    });

    test('rejects empty and out of range values', () {
      expect(parseUsbBaudRateInput(''), isNull);
      expect(parseUsbBaudRateInput('49'), isNull);
      expect(parseUsbBaudRateInput('4000001'), isNull);
      expect(validateUsbBaudRateInput('invalid'), isNotNull);
    });
  });
}
