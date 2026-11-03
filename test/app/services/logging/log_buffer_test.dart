import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('evicts oldest entries when the entry limit is exceeded', () {
    final buffer = LogBuffer(maxEntries: 2, maxBytes: 100);

    buffer
      ..add(_entry(1))
      ..add(_entry(2))
      ..add(_entry(3));

    expect(buffer.entries.map((entry) => entry.id), <int>[2, 3]);
  });

  test('evicts entries until total byte size is within the limit', () {
    final buffer = LogBuffer(maxEntries: 10, maxBytes: 3);

    buffer
      ..add(_entry(1, length: 2))
      ..add(_entry(2, length: 2));

    expect(buffer.entries.single.id, 2);
  });

  test('clear removes all retained entries', () {
    final buffer = LogBuffer()..add(_entry(1));

    buffer.clear();

    expect(buffer.entries, isEmpty);
  });
}

LogEntry _entry(int id, {int length = 1}) {
  return LogEntry(
    id: id,
    timestamp: DateTime.utc(2026),
    direction: LogDirection.received,
    format: PayloadFormat.hex,
    channel: 'test',
    bytes: Uint8List(length),
  );
}
