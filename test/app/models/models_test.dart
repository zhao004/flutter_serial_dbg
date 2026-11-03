import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/connection_state.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/ping_result.dart';
import 'package:flutter_serial_dbg/app/models/protocol_event.dart';
import 'package:flutter_serial_dbg/app/models/usb_serial_device_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('connection configs', () {
    test('normalizes text and exposes the selected mode', () {
      final config = TcpClientConfig(host: ' 192.0.2.1 ', port: 9000);

      expect(config.host, '192.0.2.1');
      expect(config.port, 9000);
      expect(config.mode, ConnectionMode.tcpClient);
    });

    test('rejects invalid ports and BLE identifiers', () {
      expect(() => UdpServerConfig(port: 0), throwsA(isA<ArgumentError>()));
      expect(
        () => BleConfig(remoteId: 'device', serviceUuid: 'not-a-uuid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts standard USB serial parameters', () {
      final config = UsbSerialConfig(
        deviceId: '/dev/bus/usb/001/004',
        baudRate: 115200,
      );

      expect(config.mode, ConnectionMode.usbSerial);
      expect(config.stopBits, UsbStopBits.one);
      expect(config.parity, UsbParity.none);
    });

    test('rejects USB baud rates outside the transport boundary', () {
      expect(
        () => UsbSerialConfig(deviceId: '  '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => UsbSerialConfig(deviceId: 'usb-port', baudRate: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => UsbSerialConfig(deviceId: 'usb-port', baudRate: 4000001),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('builds a USB device summary without exposing a serial number', () {
      final device = UsbSerialDeviceInfo(
        deviceId: '/dev/bus/usb/001/004',
        deviceName: '/dev/bus/usb/001/004',
        vendorId: 0x1A86,
        productId: 0x7523,
        productName: ' CH340 ',
        manufacturerName: ' WCH ',
      );

      expect(device.displayName, 'CH340');
      expect(device.manufacturerName, 'WCH');
      expect(device.hardwareId, 'VID 0x1A86 / PID 0x7523');
    });
  });

  group('connection snapshots', () {
    test('requires an error message when failed', () {
      expect(
        () => ConnectionSnapshot(
          status: TransportStatus.failed,
          changedAt: DateTime.utc(2026),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('requires a config while connected', () {
      expect(
        () => ConnectionSnapshot(
          status: TransportStatus.connected,
          changedAt: DateTime.utc(2026),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('log redaction', () {
    test('copies input bytes and exposes a read-only view', () {
      final input = Uint8List.fromList(<int>[0x01, 0x02]);
      final entry = LogEntry(
        timestamp: DateTime.utc(2026),
        direction: LogDirection.sent,
        format: PayloadFormat.hex,
        channel: 'tcp',
        bytes: input,
      );

      input[0] = 0xAA;

      expect(entry.bytes, <int>[0x01, 0x02]);
      expect(() => entry.bytes[0] = 0xBB, throwsUnsupportedError);
      expect(entry.copyBytes(), <int>[0x01, 0x02]);
      expect(entry.toString(), isNot(contains('1, 2')));
    });

    test('protocol events do not stringify payload bytes', () {
      final frame = ProtocolFrameReceived(
        command: 0x10,
        payload: Uint8List.fromList(<int>[0xDE, 0xAD]),
        rawFrame: Uint8List.fromList(<int>[0xAA, 0x55]),
      );

      expect(frame.toString(), contains('command: 0x10'));
      expect(frame.toString(), isNot(contains('DE')));
      expect(frame.toString(), isNot(contains('222')));
    });
  });

  test('rejects negative ping durations', () {
    expect(
      () => PingResult(
        target: '192.0.2.1',
        status: PingStatus.error,
        duration: const Duration(seconds: -1),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
