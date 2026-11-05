import 'package:drift/native.dart';
import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/database/database.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upgrades schema 1 profiles with the USB device key column', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE connection_profiles (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            mode TEXT NOT NULL,
            host TEXT NULL,
            port INTEGER NULL,
            bind_address TEXT NULL,
            ble_remote_id TEXT NULL,
            service_uuid TEXT NULL,
            write_characteristic_uuid TEXT NULL,
            notify_characteristic_uuid TEXT NULL,
            usb_device_id INTEGER NULL,
            baud_rate INTEGER NULL,
            data_bits INTEGER NULL,
            stop_bits TEXT NULL,
            parity TEXT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE app_settings (
            id INTEGER NOT NULL PRIMARY KEY,
            send_format TEXT NOT NULL DEFAULT 'text',
            receive_format TEXT NOT NULL DEFAULT 'text',
            append_crlf INTEGER NOT NULL DEFAULT 0,
            auto_scroll INTEGER NOT NULL DEFAULT 1,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.userVersion = 1;
      },
    );
    final database = AppDatabase.forTesting(executor);
    final repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
    addTearDown(repository.close);

    await repository.saveConnectionConfig(
      UsbSerialConfig(deviceId: '/dev/bus/usb/001/022'),
    );

    final loaded = await repository.loadConnectionConfig(
      ConnectionMode.usbSerial,
    );
    expect(
      loaded,
      isA<UsbSerialConfig>().having(
        (value) => value.deviceId,
        'deviceId',
        '/dev/bus/usb/001/022',
      ),
    );
  });

  test(
    'adds appearance settings without changing schema 2 preferences',
    () async {
      final executor = NativeDatabase.memory(
        setup: (database) {
          database.execute('''
          CREATE TABLE app_settings (
            id INTEGER NOT NULL PRIMARY KEY,
            send_format TEXT NOT NULL DEFAULT 'text',
            receive_format TEXT NOT NULL DEFAULT 'text',
            append_crlf INTEGER NOT NULL DEFAULT 0,
            auto_scroll INTEGER NOT NULL DEFAULT 1,
            updated_at INTEGER NOT NULL
          )
        ''');
          database.execute('''
          INSERT INTO app_settings (
            id,
            send_format,
            receive_format,
            append_crlf,
            auto_scroll,
            updated_at
          ) VALUES (1, 'hex', 'text', 1, 0, 1767225600)
        ''');
          database.userVersion = 2;
        },
      );
      final database = AppDatabase.forTesting(executor);
      final repository = DriftAppRepository(
        database: database,
        clock: () => DateTime.utc(2026),
      );
      addTearDown(repository.close);

      final preferences = await repository.loadPreferences();
      final appearance = await repository.loadAppearancePreferences();

      expect(preferences.sendFormat, PayloadFormat.hex);
      expect(preferences.appendCrlf, isTrue);
      expect(preferences.autoScroll, isFalse);
      expect(appearance.mode, AppThemeMode.system);
      expect(appearance.preset, AppThemePreset.indigoM3);

      await repository.saveAppearancePreferences(
        const AppearancePreferences(
          mode: AppThemeMode.light,
          preset: AppThemePreset.tealM3,
        ),
      );

      final saved = await repository.loadAppearancePreferences();
      expect(saved.mode, AppThemeMode.light);
      expect(saved.preset, AppThemePreset.tealM3);
    },
  );

  test('upgrades schema 3 settings and creates protocol profiles', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE app_settings (
            id INTEGER NOT NULL PRIMARY KEY,
            send_format TEXT NOT NULL DEFAULT 'text',
            receive_format TEXT NOT NULL DEFAULT 'text',
            append_crlf INTEGER NOT NULL DEFAULT 0,
            auto_scroll INTEGER NOT NULL DEFAULT 1,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          INSERT INTO app_settings (
            id,
            send_format,
            receive_format,
            append_crlf,
            auto_scroll,
            updated_at
          ) VALUES (1, 'hex', 'text', 1, 0, 1767225600)
        ''');
        database.userVersion = 3;
      },
    );
    final database = AppDatabase.forTesting(executor);
    final repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
    addTearDown(repository.close);

    final preferences = await repository.loadPreferences();

    expect(preferences.sendFormat, PayloadFormat.hex);
    expect(preferences.persistSessionLogs, isTrue);
    expect(preferences.logRetentionSessions, 20);
    expect(
      await repository.saveProtocolProfile(
        ProtocolProfile(name: '迁移后协议', header: const <int>[0xAA, 0x55]),
      ),
      isA<ProtocolProfile>().having((value) => value.id, 'id', isNotNull),
    );
  });
}
