import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_gatt_resolver.dart';
import 'package:flutter_serial_dbg/app/services/transport/transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects with a write-only GATT characteristic', () {
    final service = BleGattServiceCandidate<String, String>(
      value: 'service',
      uuid: '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        const BleGattCharacteristicCandidate<String>(
          value: 'write',
          uuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          writable: true,
          notifiable: false,
        ),
      ],
    );

    final selection = resolveBleGatt<String, String>(
      services: <BleGattServiceCandidate<String, String>>[service],
      config: BleConfig(remoteId: 'device'),
    );

    expect(selection.write.value, 'write');
    expect(selection.notify, isNull);
  });

  test('prefers a service that also supports notifications', () {
    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    const writeUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
    const notifyUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';
    final services = <BleGattServiceCandidate<String, String>>[
      const BleGattServiceCandidate<String, String>(
        value: 'write-only',
        uuid: serviceUuid,
        characteristics: <BleGattCharacteristicCandidate<String>>[
          BleGattCharacteristicCandidate<String>(
            value: 'write',
            uuid: writeUuid,
            writable: true,
            notifiable: false,
          ),
        ],
      ),
      const BleGattServiceCandidate<String, String>(
        value: 'bidirectional',
        uuid: serviceUuid,
        characteristics: <BleGattCharacteristicCandidate<String>>[
          BleGattCharacteristicCandidate<String>(
            value: 'write',
            uuid: writeUuid,
            writable: true,
            notifiable: false,
          ),
          BleGattCharacteristicCandidate<String>(
            value: 'notify',
            uuid: notifyUuid,
            writable: false,
            notifiable: true,
          ),
        ],
      ),
    ];

    final selection = resolveBleGatt<String, String>(
      services: services,
      config: BleConfig(remoteId: 'device'),
    );

    expect(selection.service.value, 'bidirectional');
    expect(selection.notify?.value, 'notify');
  });

  test('skips standard GATT services during automatic selection', () {
    const gattService = BleGattServiceCandidate<String, String>(
      value: 'gatt-internal',
      uuid: '00001801-0000-1000-8000-00805f9b34fb',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'client-features',
          uuid: '00002b29-0000-1000-8000-00805f9b34fb',
          writable: true,
          notifiable: false,
        ),
      ],
    );
    const applicationService = BleGattServiceCandidate<String, String>(
      value: 'application',
      uuid: '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'message-write',
          uuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          writable: true,
          notifiable: false,
        ),
      ],
    );

    final selection = resolveBleGatt<String, String>(
      services: const <BleGattServiceCandidate<String, String>>[
        gattService,
        applicationService,
      ],
      config: BleConfig(remoteId: 'device'),
    );

    expect(selection.service.value, 'application');
    expect(selection.write.value, 'message-write');
  });

  test('ignores a stale standard GATT service configuration', () {
    const gattService = BleGattServiceCandidate<String, String>(
      value: 'gatt-internal',
      uuid: '00001801-0000-1000-8000-00805f9b34fb',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'client-features',
          uuid: '00002b29-0000-1000-8000-00805f9b34fb',
          writable: true,
          notifiable: false,
        ),
      ],
    );
    const applicationService = BleGattServiceCandidate<String, String>(
      value: 'application',
      uuid: '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'message-write',
          uuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          writable: true,
          notifiable: false,
        ),
      ],
    );

    final selection = resolveBleGatt<String, String>(
      services: const <BleGattServiceCandidate<String, String>>[
        gattService,
        applicationService,
      ],
      config: BleConfig(
        remoteId: 'device',
        serviceUuid: '1801',
        writeCharacteristicUuid: '2B29',
      ),
    );

    expect(selection.service.value, 'application');
    expect(selection.write.value, 'message-write');
  });

  test('rejects a configured notification characteristic that is absent', () {
    const service = BleGattServiceCandidate<String, String>(
      value: 'service',
      uuid: '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'write',
          uuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          writable: true,
          notifiable: false,
        ),
      ],
    );

    expect(
      () => resolveBleGatt<String, String>(
        services: const <BleGattServiceCandidate<String, String>>[service],
        config: BleConfig(
          remoteId: 'device',
          notifyCharacteristicUuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a9',
        ),
      ),
      throwsA(
        isA<TransportException>().having(
          (error) => error.message,
          'message',
          '未找到通知或指示 BLE 特征',
        ),
      ),
    );
  });

  test('rejects a profile without a writable characteristic', () {
    const service = BleGattServiceCandidate<String, String>(
      value: 'service',
      uuid: '4fafc201-1fb5-459e-8fcc-c5c9c331914b',
      characteristics: <BleGattCharacteristicCandidate<String>>[
        BleGattCharacteristicCandidate<String>(
          value: 'notify',
          uuid: 'beb5483e-36e1-4688-b7f5-ea07361b26a8',
          writable: false,
          notifiable: true,
        ),
      ],
    );

    expect(
      () => resolveBleGatt<String, String>(
        services: const <BleGattServiceCandidate<String, String>>[service],
        config: BleConfig(remoteId: 'device'),
      ),
      throwsA(
        isA<TransportException>().having(
          (error) => error.message,
          'message',
          '未找到可写 BLE 特征',
        ),
      ),
    );
  });
}
