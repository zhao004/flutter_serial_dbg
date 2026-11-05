import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/ble_gatt.dart';
import 'package:flutter_serial_dbg/app/pages/home/ble_gatt_controller.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_gatt_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGattSession session;
  late BleGattController controller;

  setUp(() {
    session = _FakeGattSession();
    controller = BleGattController();
  });

  tearDown(() {
    controller.dispose();
    session.dispose();
  });

  test('binds services and tracks read and notification values', () async {
    controller.bind(session);

    expect(controller.services.value.single.uuid, 'service');

    final read = await controller.read(
      serviceUuid: 'service',
      characteristicUuid: 'readable',
    );
    expect(read?.bytes, <int>[0x01, 0x02]);
    expect(controller.valueFor('service', 'readable')?.bytes, <int>[
      0x01,
      0x02,
    ]);

    session.emit(
      BleGattValue(
        serviceUuid: 'service',
        characteristicUuid: 'notify',
        bytes: Uint8List.fromList(<int>[0xAA, 0x55]),
        receivedAt: DateTime.utc(2026),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.valueFor('service', 'notify')?.bytes, <int>[0xAA, 0x55]);
  });

  test('writes and toggles notifications through the bound session', () async {
    controller.bind(session);

    expect(
      await controller.write(
        serviceUuid: 'service',
        characteristicUuid: 'writable',
        data: Uint8List.fromList(<int>[0x10]),
        withResponse: true,
      ),
      isTrue,
    );
    expect(session.writes.single, <int>[0x10]);

    expect(
      await controller.setNotify(
        serviceUuid: 'service',
        characteristicUuid: 'notify',
        enabled: true,
      ),
      isTrue,
    );
    expect(controller.notifiedKeys.value, contains('service|notify'));

    controller.unbind(session);
    expect(controller.services.value, isEmpty);
    expect(controller.isBound, isFalse);
  });
}

final class _FakeGattSession implements BleGattSession {
  final StreamController<BleGattValue> _values =
      StreamController<BleGattValue>.broadcast(sync: true);
  final List<List<int>> writes = <List<int>>[];

  @override
  List<BleGattServiceInfo> get gattServices => <BleGattServiceInfo>[
    BleGattServiceInfo(
      uuid: 'service',
      characteristics: <BleGattCharacteristicInfo>[
        BleGattCharacteristicInfo(
          serviceUuid: 'service',
          uuid: 'readable',
          properties: const <BleGattProperty>[BleGattProperty.read],
        ),
        BleGattCharacteristicInfo(
          serviceUuid: 'service',
          uuid: 'writable',
          properties: const <BleGattProperty>[BleGattProperty.write],
        ),
        BleGattCharacteristicInfo(
          serviceUuid: 'service',
          uuid: 'notify',
          properties: const <BleGattProperty>[BleGattProperty.notify],
        ),
      ],
    ),
  ];

  @override
  Stream<BleGattValue> get gattValues => _values.stream;

  @override
  Set<String> get notifiedGattKeys => const <String>{};

  void emit(BleGattValue value) {
    _values.add(value);
  }

  @override
  Future<BleGattValue> readGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final value = BleGattValue(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      bytes: Uint8List.fromList(<int>[0x01, 0x02]),
      receivedAt: DateTime.utc(2026),
    );
    _values.add(value);
    return value;
  }

  @override
  Future<void> writeGattCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {
    writes.add(data.toList(growable: false));
  }

  @override
  Future<void> setGattNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enabled,
  }) async {}

  void dispose() {
    unawaited(_values.close());
  }
}
