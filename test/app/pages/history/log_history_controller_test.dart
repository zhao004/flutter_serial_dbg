import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/database/database.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/pages/history/log_history_controller.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftAppRepository repository;
  late _CapturingExporter exporter;
  late LogHistoryController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
    exporter = _CapturingExporter();
    controller = LogHistoryController(
      repository: repository,
      exporter: exporter,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('loads, filters, exports and deletes persisted sessions', () async {
    final tcpSession = await repository.startLogSession(
      ConnectionMode.tcpClient,
      DateTime.utc(2026, 1, 1),
    );
    await repository.appendLogEntries(tcpSession, <LogEntry>[
      _entry(<int>[0x01]),
    ]);
    await repository.endLogSession(tcpSession, DateTime.utc(2026, 1, 1, 0, 1));
    final bleSession = await repository.startLogSession(
      ConnectionMode.ble,
      DateTime.utc(2026, 1, 2),
    );
    await repository.appendLogEntries(bleSession, <LogEntry>[
      _entry(<int>[0xAA, 0x55]),
    ]);
    await repository.endLogSession(bleSession, DateTime.utc(2026, 1, 2, 0, 2));

    await controller.loadSessions();
    expect(controller.sessions.value, hasLength(2));

    await controller.setMode(ConnectionMode.ble);
    expect(controller.sessions.value.single.id, bleSession);

    expect(
      await controller.exportSession(bleSession, format: PayloadFormat.hex),
      isTrue,
    );
    expect(exporter.entries.single.bytes, <int>[0xAA, 0x55]);

    expect(await controller.deleteSession(bleSession), isTrue);
    expect(controller.sessions.value, isEmpty);
  });

  test('clears every persisted session', () async {
    final sessionId = await repository.startLogSession(
      ConnectionMode.udpClient,
      DateTime.utc(2026),
    );
    await repository.appendLogEntries(sessionId, <LogEntry>[
      _entry(<int>[0x10]),
    ]);

    expect(await controller.deleteAll(), isTrue);

    expect(await repository.loadLogSessionSummaries(), isEmpty);
    expect(await repository.loadSessionEntries(sessionId), isEmpty);
  });
}

LogEntry _entry(List<int> bytes) {
  return LogEntry(
    timestamp: DateTime.utc(2026),
    direction: LogDirection.received,
    format: PayloadFormat.hex,
    channel: 'test',
    bytes: Uint8List.fromList(bytes),
  );
}

final class _CapturingExporter implements LogExporter {
  List<LogEntry> entries = const <LogEntry>[];
  PayloadFormat? format;

  @override
  Future<String?> export(
    List<LogEntry> entries, {
    required PayloadFormat format,
  }) async {
    this.entries = List<LogEntry>.of(entries);
    this.format = format;
    return '/tmp/session.log';
  }
}
