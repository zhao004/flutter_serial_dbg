import 'package:drift/native.dart';
import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/database/database.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/pages/settings/communication_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftAppRepository repository;
  late CommunicationSettingsController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
    controller = CommunicationSettingsController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('loads defaults and persists every communication preference', () async {
    await controller.initialize();

    expect(controller.persistSessionLogs.value, isTrue);
    expect(controller.logRetentionSessions.value, 20);

    await controller.setSendFormat(PayloadFormat.hex);
    await controller.setReceiveFormat(PayloadFormat.hex);
    await controller.setAppendCrlf(true);
    await controller.setAutoScroll(false);
    await controller.setPersistSessionLogs(false);
    await controller.setLogRetentionSessions(50);

    final saved = await repository.loadPreferences();
    expect(saved.sendFormat, PayloadFormat.hex);
    expect(saved.receiveFormat, PayloadFormat.hex);
    expect(saved.appendCrlf, isTrue);
    expect(saved.autoScroll, isFalse);
    expect(saved.persistSessionLogs, isFalse);
    expect(saved.logRetentionSessions, 50);
  });

  test('rejects unsupported retention counts', () {
    expect(() => controller.setLogRetentionSessions(25), throwsArgumentError);
  });

  test('falls back to the supported retention value from storage', () async {
    await repository.savePreferences(
      const AppPreferences(logRetentionSessions: 37),
    );

    await controller.initialize();

    expect(
      controller.logRetentionSessions.value,
      AppPreferences.defaultLogRetentionSessions,
    );
  });
}
