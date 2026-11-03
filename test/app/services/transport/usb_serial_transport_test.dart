import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/transport_event.dart';
import 'package:flutter_serial_dbg/app/models/usb_serial_device_info.dart';
import 'package:flutter_serial_dbg/app/services/transport/transport.dart';
import 'package:flutter_serial_dbg/app/services/transport/usb_serial_transport.dart';
import 'package:flutter_serial_dbg/app/services/usb/usb_serial_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skio_usb_serial/skio_usb_serial.dart';

void main() {
  late _FakeUsbSerialService service;
  late _FakeUsbSerialConnection connection;
  late UsbSerialDeviceInfo device;

  setUp(() {
    device = UsbSerialDeviceInfo(
      deviceId: '/dev/bus/usb/001/021',
      deviceName: '/dev/bus/usb/001/021',
      vendorId: 0x10C4,
      productId: 0xEA60,
      productName: 'CP210x',
    );
    connection = _FakeUsbSerialConnection(device);
    service = _FakeUsbSerialService(device: device, connection: connection);
  });

  tearDown(() async {
    await service.dispose();
  });

  test('connects, writes and reports USB serial input', () async {
    final transport = UsbSerialTransport(service);
    final events = _TransportEventQueue(transport.events);
    addTearDown(() async {
      await events.dispose();
      await transport.dispose();
    });
    final config = UsbSerialConfig(
      deviceId: device.deviceId,
      baudRate: 921600,
      dataBits: 8,
      stopBits: UsbStopBits.two,
      parity: UsbParity.even,
    );

    await transport.connect(config);
    expect(await events.next(), isA<TransportConnected>());
    expect(service.openedConfig?.baudRate, 921600);
    expect(transport.isConnected, isTrue);

    await transport.send(Uint8List.fromList(<int>[0x41, 0x42]));
    expect(connection.written.single, <int>[0x41, 0x42]);

    connection.emitData(<int>[0x10, 0x20]);
    final received = await events.next();
    expect(received, isA<TransportDataReceived>());
    expect((received as TransportDataReceived).bytes, <int>[0x10, 0x20]);
  });

  test('closes the port when the selected USB device is detached', () async {
    final transport = UsbSerialTransport(service);
    final events = _TransportEventQueue(transport.events);
    addTearDown(() async {
      await events.dispose();
      await transport.dispose();
    });
    await transport.connect(UsbSerialConfig(deviceId: device.deviceId));
    expect(await events.next(), isA<TransportConnected>());

    service.emitDetach(device);

    final disconnected = await events.next();
    expect(disconnected, isA<TransportDisconnected>());
    expect((disconnected as TransportDisconnected).reason, contains('已拔出'));
    await Future<void>.delayed(Duration.zero);
    expect(connection.closeCalls, 1);
    expect(transport.isConnected, isFalse);
  });

  test('maps service failures to a stable connection error', () async {
    service.openError = const UsbSerialException('串口打开失败，设备可能被其他应用占用');
    final transport = UsbSerialTransport(service);
    addTearDown(transport.dispose);

    await expectLater(
      transport.connect(UsbSerialConfig(deviceId: device.deviceId)),
      throwsA(
        isA<TransportException>()
            .having(
              (error) => error.kind,
              'kind',
              TransportErrorKind.connection,
            )
            .having((error) => error.message, 'message', contains('其他应用占用')),
      ),
    );
  });

  test(
    'maps a write failure and moves the transport to disconnected',
    () async {
      final transport = UsbSerialTransport(service);
      final events = _TransportEventQueue(transport.events);
      addTearDown(() async {
        await events.dispose();
        await transport.dispose();
      });
      await transport.connect(UsbSerialConfig(deviceId: device.deviceId));
      expect(await events.next(), isA<TransportConnected>());
      connection.writeError = StateError('device removed');

      await expectLater(
        transport.send(Uint8List.fromList(<int>[0x01])),
        throwsA(
          isA<TransportException>().having(
            (error) => error.kind,
            'kind',
            TransportErrorKind.send,
          ),
        ),
      );

      expect(await events.next(), isA<TransportDisconnected>());
      expect(transport.isConnected, isFalse);
    },
  );

  test('maps USB stop bits and parity to plugin constants', () {
    expect(mapUsbStopBits(UsbStopBits.one), StopBits.one);
    expect(mapUsbStopBits(UsbStopBits.onePointFive), StopBits.onePointFive);
    expect(mapUsbStopBits(UsbStopBits.two), StopBits.two);
    expect(mapUsbParity(UsbParity.none), Parity.none);
    expect(mapUsbParity(UsbParity.odd), Parity.odd);
    expect(mapUsbParity(UsbParity.even), Parity.even);
    expect(mapUsbParity(UsbParity.mark), Parity.mark);
    expect(mapUsbParity(UsbParity.space), Parity.space);
  });
}

final class _FakeUsbSerialService implements UsbSerialService {
  _FakeUsbSerialService({required this.device, required this.connection});

  final UsbSerialDeviceInfo device;
  final _FakeUsbSerialConnection connection;
  final StreamController<UsbSerialDeviceEvent> _events =
      StreamController<UsbSerialDeviceEvent>.broadcast(sync: true);
  UsbSerialConfig? openedConfig;
  Object? openError;
  bool _disposed = false;

  @override
  Stream<UsbSerialDeviceEvent> get events => _events.stream;

  @override
  Future<List<UsbSerialDeviceInfo>> listDevices() async {
    return <UsbSerialDeviceInfo>[device];
  }

  @override
  Future<UsbSerialConnection> open(UsbSerialConfig config) async {
    openedConfig = config;
    final error = openError;
    if (error != null) {
      throw error;
    }
    return connection;
  }

  void emitDetach(UsbSerialDeviceInfo detached) {
    _events.add(
      UsbSerialDeviceEvent(
        type: UsbSerialDeviceEventType.detached,
        device: detached,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _events.close();
  }
}

final class _FakeUsbSerialConnection implements UsbSerialConnection {
  _FakeUsbSerialConnection(UsbSerialDeviceInfo device)
    : endpoint = '${device.displayName} (${device.hardwareId})';

  final StreamController<Uint8List> _input =
      StreamController<Uint8List>.broadcast(sync: true);
  final List<List<int>> written = <List<int>>[];
  Object? writeError;
  int closeCalls = 0;

  @override
  final String endpoint;

  @override
  Stream<Uint8List> get inputStream => _input.stream;

  void emitData(List<int> data) {
    _input.add(Uint8List.fromList(data));
  }

  @override
  Future<void> write(Uint8List data) async {
    final error = writeError;
    if (error != null) {
      throw error;
    }
    written.add(Uint8List.fromList(data));
  }

  @override
  Future<void> close() async {
    closeCalls++;
    if (!_input.isClosed) {
      await _input.close();
    }
  }
}

final class _TransportEventQueue {
  _TransportEventQueue(Stream<TransportEvent> stream) {
    _subscription = stream.listen(
      (event) {
        if (_waiters.isNotEmpty) {
          _waiters.removeFirst().complete(event);
        } else {
          _events.add(event);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        while (_waiters.isNotEmpty) {
          _waiters.removeFirst().completeError(error, stackTrace);
        }
      },
    );
  }

  final Queue<TransportEvent> _events = Queue<TransportEvent>();
  final Queue<Completer<TransportEvent>> _waiters =
      Queue<Completer<TransportEvent>>();
  late final StreamSubscription<TransportEvent> _subscription;

  Future<TransportEvent> next() {
    if (_events.isNotEmpty) {
      return Future<TransportEvent>.value(_events.removeFirst());
    }
    final completer = Completer<TransportEvent>();
    _waiters.add(completer);
    return completer.future.timeout(const Duration(seconds: 3));
  }

  Future<void> dispose() => _subscription.cancel();
}
