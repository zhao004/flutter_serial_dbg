import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/database/database.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/protocol_event.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_serial_dbg/app/pages/home/protocol_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftAppRepository repository;
  late ProtocolController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
    controller = ProtocolController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('encodes and incrementally decodes a custom profile', () async {
    await controller.initialize();
    controller.selectProfile(
      ProtocolProfile(name: '测试协议', header: const <int>[0xAA, 0x55]),
    );
    final frame = controller.encode(
      command: 0x42,
      payload: Uint8List.fromList(<int>[0x10, 0x20]),
    );

    expect(frame, isNotNull);
    controller.addChunk(frame!.sublist(0, 2));
    expect(controller.observations.value, isEmpty);
    controller.addChunk(frame.sublist(2));

    final event = controller.observations.value.single.event;
    expect(event, isA<ProtocolFrameReceived>());
    expect((event as ProtocolFrameReceived).command, 0x42);
    expect(event.payload, <int>[0x10, 0x20]);
  });

  test(
    'persists custom profiles and reparses historical received logs',
    () async {
      await controller.initialize();
      final saved = await controller.saveProfile(
        ProtocolProfile(
          name: '设备协议',
          header: const <int>[0x7E],
          commandOffset: 1,
          lengthOffset: 2,
          payloadOffset: 3,
          checksumStartOffset: 1,
        ),
      );

      expect(saved?.id, isNotNull);
      expect(controller.profiles.value.single.name, '设备协议');

      final codec = controller.selectedProfile.value!;
      final frame = Uint8List.fromList(<int>[0x7E, 0x05, 0x01, 0xAA, 0xAE]);
      final observations = controller.decodeEntries(<LogEntry>[
        LogEntry(
          timestamp: DateTime.utc(2026),
          direction: LogDirection.received,
          format: PayloadFormat.hex,
          channel: 'test',
          bytes: frame,
        ),
      ], codec);

      expect(observations.single.event, isA<ProtocolFrameReceived>());
      expect(await controller.deleteProfile(saved!.id!), isTrue);
      expect(controller.profiles.value, isEmpty);
    },
  );
}
