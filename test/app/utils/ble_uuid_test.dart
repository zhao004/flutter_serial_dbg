import 'package:flutter_serial_dbg/app/utils/ble_uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches 16-bit BLE UUIDs against their 128-bit form', () {
    expect(
      bleUuidMatches('180D', '0000180D-0000-1000-8000-00805F9B34FB'),
      isTrue,
    );
  });

  test('matches case-insensitive full BLE UUIDs', () {
    expect(
      bleUuidMatches(
        '0000180d-0000-1000-8000-00805f9b34fb',
        '0000180D-0000-1000-8000-00805F9B34FB',
      ),
      isTrue,
    );
  });

  test('rejects different BLE UUIDs', () {
    expect(bleUuidMatches('180D', '180F'), isFalse);
  });
}
