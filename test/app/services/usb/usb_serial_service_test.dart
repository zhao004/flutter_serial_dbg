import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/services/usb/usb_serial_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skio_usb_serial/platform_interface.dart';
import 'package:skio_usb_serial/skio_usb_serial.dart';

void main() {
  late UsbSerialPlatform originalPlatform;
  late _FakeUsbSerialPlatform platform;
  late FlutterUsbSerialService service;

  setUp(() {
    originalPlatform = UsbSerialPlatform.instance;
    platform = _FakeUsbSerialPlatform();
    UsbSerialPlatform.instance = platform;
    service = FlutterUsbSerialService();
  });

  tearDown(() async {
    await service.dispose();
    await platform.dispose();
    UsbSerialPlatform.instance = originalPlatform;
  });

  test('maps serial handles without retaining serial numbers', () async {
    platform.devices = <DeviceHandle>[
      const DeviceHandle(
        id: '/dev/bus/usb/001/031',
        name: 'CH340',
        vendorId: 0x1A86,
        productId: 0x7523,
        serialNumber: 'private-serial',
      ),
    ];

    final devices = await service.listDevices();

    expect(devices.single.deviceId, '/dev/bus/usb/001/031');
    expect(devices.single.displayName, 'CH340');
    expect(devices.single.hardwareId, 'VID 0x1A86 / PID 0x7523');
  });

  test('requests USB access and forwards serial parameters', () async {
    final device = const DeviceHandle(
      id: '/dev/bus/usb/001/032',
      name: 'CP210x',
      vendorId: 0x10C4,
      productId: 0xEA60,
    );
    platform
      ..devices = <DeviceHandle>[device]
      ..checkAccessReport = const AccessReport(AccessStatus.denied)
      ..requestAccessReport = const AccessReport(AccessStatus.granted);

    final connection = await service.open(
      UsbSerialConfig(
        deviceId: device.id,
        baudRate: 921600,
        dataBits: 7,
        stopBits: UsbStopBits.two,
        parity: UsbParity.odd,
      ),
    );

    expect(platform.requestAccessCalls, 1);
    expect(platform.openedConfig?.baudRate, 921600);
    expect(platform.openedConfig?.dataBits, 7);
    expect(platform.openedConfig?.stopBits, StopBits.two);
    expect(platform.openedConfig?.parity, Parity.odd);
    await connection.close();
  });

  test('maps denied permission and busy ports to stable errors', () async {
    final device = const DeviceHandle(id: '/dev/bus/usb/001/033');
    platform
      ..devices = <DeviceHandle>[device]
      ..checkAccessReport = const AccessReport(AccessStatus.denied)
      ..requestAccessReport = const AccessReport(AccessStatus.denied);

    await expectLater(
      service.open(UsbSerialConfig(deviceId: device.id)),
      throwsA(
        isA<UsbSerialException>().having(
          (error) => error.message,
          'message',
          contains('权限被拒绝'),
        ),
      ),
    );

    platform
      ..checkAccessReport = const AccessReport(AccessStatus.granted)
      ..openError = DeviceBusy('busy', device: device);
    await expectLater(
      service.open(UsbSerialConfig(deviceId: device.id)),
      throwsA(
        isA<UsbSerialException>().having(
          (error) => error.message,
          'message',
          contains('其他应用占用'),
        ),
      ),
    );
  });

  test('maps attach and detach events', () async {
    const device = DeviceHandle(id: '/dev/bus/usb/001/034', name: 'FTDI');
    final eventFuture = service.events.take(2).toList();

    platform
      ..emit(const DeviceAttached(device))
      ..emit(const DeviceDetached(device));

    final events = await eventFuture;
    expect(events.first.type, UsbSerialDeviceEventType.attached);
    expect(events.last.type, UsbSerialDeviceEventType.detached);
    expect(events.last.device.displayName, 'FTDI');
  });
}

final class _FakeUsbSerialPlatform extends UsbSerialPlatform {
  final StreamController<DeviceEvent> _events =
      StreamController<DeviceEvent>.broadcast(sync: true);
  List<DeviceHandle> devices = const <DeviceHandle>[];
  AccessReport checkAccessReport = const AccessReport(AccessStatus.granted);
  AccessReport requestAccessReport = const AccessReport(AccessStatus.granted);
  Object? openError;
  SerialConfig? openedConfig;
  int requestAccessCalls = 0;
  bool _disposed = false;

  @override
  bool get requiresUserSelection => false;

  @override
  Future<AccessReport> checkAccess([DeviceHandle? device]) async {
    return checkAccessReport;
  }

  @override
  Future<AccessReport> requestAccess([DeviceHandle? device]) async {
    requestAccessCalls++;
    return requestAccessReport;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<List<DeviceHandle>> list() async {
    return List<DeviceHandle>.of(devices);
  }

  @override
  Future<DeviceHandle?> request(List<DeviceFilter> filters) async => null;

  @override
  Stream<DeviceEvent> get events => _events.stream;

  @override
  Future<SerialConnection> open(
    DeviceHandle device,
    SerialConfig config,
  ) async {
    final error = openError;
    if (error != null) {
      throw error;
    }
    openedConfig = config;
    return _FakeSerialConnection();
  }

  void emit(DeviceEvent event) {
    _events.add(event);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _events.close();
  }
}

final class _FakeSerialConnection implements SerialConnection {
  _FakeSerialConnection();

  final StreamController<Uint8List> _input =
      StreamController<Uint8List>.broadcast(sync: true);
  bool _closed = false;

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  Future<void> write(Uint8List data, Duration timeout) async {}

  @override
  Future<void> setSignals({bool? dtr, bool? rts}) async {}

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _input.close();
  }
}
