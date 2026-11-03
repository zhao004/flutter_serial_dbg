import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats text logs as one escaped line per entry', () {
    final text = LogTextFormatter.format(<LogEntry>[
      LogEntry(
        timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
        direction: LogDirection.received,
        format: PayloadFormat.text,
        channel: 'tcpClient',
        bytes: Uint8List.fromList(<int>[0x4F, 0x4B, 0x0D, 0x0A]),
      ),
    ], format: PayloadFormat.text);

    expect(text, contains('[received] [tcpClient] OK\\r\\n'));
  });

  test('formats hex logs with uppercase spaced bytes', () {
    final text = LogTextFormatter.format(<LogEntry>[
      LogEntry(
        timestamp: DateTime.utc(2026, 1, 2),
        direction: LogDirection.sent,
        format: PayloadFormat.hex,
        channel: 'udpClient',
        bytes: Uint8List.fromList(<int>[0xAA, 0x55]),
      ),
    ], format: PayloadFormat.hex);

    expect(text, contains('[sent] [udpClient] AA 55'));
  });
}
