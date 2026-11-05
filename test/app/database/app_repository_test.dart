import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/database/database.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftAppRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAppRepository(
      database: database,
      clock: () => DateTime.utc(2026),
    );
  });

  tearDown(() async {
    await repository.close();
  });

  test('saves and reloads WiFi connection profiles', () async {
    final tcp = TcpClientConfig(host: '192.0.2.10', port: 8080);
    final udp = UdpServerConfig(bindAddress: '0.0.0.0', port: 9000);

    await repository.saveConnectionConfig(tcp);
    await repository.saveConnectionConfig(udp);

    expect(
      await repository.loadConnectionConfig(ConnectionMode.tcpClient),
      isA<TcpClientConfig>()
          .having((value) => value.host, 'host', '192.0.2.10')
          .having((value) => value.port, 'port', 8080),
    );
    expect(
      await repository.loadConnectionConfig(ConnectionMode.udpServer),
      isA<UdpServerConfig>()
          .having((value) => value.bindAddress, 'bindAddress', '0.0.0.0')
          .having((value) => value.port, 'port', 9000),
    );
  });

  test('replaces the previous profile for the same mode', () async {
    await repository.saveConnectionConfig(
      TcpClientConfig(host: '192.0.2.10', port: 8080),
    );
    await repository.saveConnectionConfig(
      TcpClientConfig(host: '198.51.100.20', port: 9090),
    );

    final loaded = await repository.loadConnectionConfig(
      ConnectionMode.tcpClient,
    );

    expect(loaded, isA<TcpClientConfig>());
    final tcpConfig = loaded! as TcpClientConfig;
    expect(tcpConfig.host, '198.51.100.20');
    expect(tcpConfig.port, 9090);
  });

  test('saves and reloads a USB serial profile', () async {
    final usb = UsbSerialConfig(
      deviceId: '/dev/bus/usb/001/021',
      baudRate: 921600,
      dataBits: 8,
      stopBits: UsbStopBits.two,
      parity: UsbParity.even,
    );

    await repository.saveConnectionConfig(usb);

    expect(
      await repository.loadConnectionConfig(ConnectionMode.usbSerial),
      isA<UsbSerialConfig>()
          .having((value) => value.deviceId, 'deviceId', '/dev/bus/usb/001/021')
          .having((value) => value.baudRate, 'baudRate', 921600)
          .having((value) => value.stopBits, 'stopBits', UsbStopBits.two)
          .having((value) => value.parity, 'parity', UsbParity.even),
    );
  });

  test('persists and reloads application preferences', () async {
    const preferences = AppPreferences(
      sendFormat: PayloadFormat.hex,
      receiveFormat: PayloadFormat.hex,
      appendCrlf: true,
      autoScroll: false,
      persistSessionLogs: false,
      logRetentionSessions: 10,
    );

    await repository.savePreferences(preferences);
    final loaded = await repository.loadPreferences();

    expect(loaded.sendFormat, PayloadFormat.hex);
    expect(loaded.receiveFormat, PayloadFormat.hex);
    expect(loaded.appendCrlf, isTrue);
    expect(loaded.autoScroll, isFalse);
    expect(loaded.persistSessionLogs, isFalse);
    expect(loaded.logRetentionSessions, 10);
  });

  test('repeated application saves keep the latest singleton row', () async {
    await repository.savePreferences(
      const AppPreferences(
        sendFormat: PayloadFormat.text,
        receiveFormat: PayloadFormat.text,
      ),
    );
    await repository.savePreferences(
      const AppPreferences(
        sendFormat: PayloadFormat.hex,
        receiveFormat: PayloadFormat.hex,
        appendCrlf: true,
        autoScroll: false,
      ),
    );

    final loaded = await repository.loadPreferences();
    final rows = await database.select(database.appSettings).get();

    expect(loaded.sendFormat, PayloadFormat.hex);
    expect(loaded.receiveFormat, PayloadFormat.hex);
    expect(loaded.appendCrlf, isTrue);
    expect(loaded.autoScroll, isFalse);
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
  });

  test('repairs legacy application settings on the next save', () async {
    await database
        .into(database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            updatedAt: DateTime.utc(2026, 1, 1),
            sendFormat: const Value(PayloadFormat.text),
            receiveFormat: const Value(PayloadFormat.text),
          ),
        );
    await database
        .into(database.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(2),
            updatedAt: DateTime.utc(2026, 1, 2),
            sendFormat: const Value(PayloadFormat.hex),
            receiveFormat: const Value(PayloadFormat.hex),
          ),
        );

    final legacy = await repository.loadPreferences();
    expect(legacy.sendFormat, PayloadFormat.hex);
    expect(legacy.receiveFormat, PayloadFormat.hex);

    await repository.savePreferences(const AppPreferences());
    final rows = await database.select(database.appSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
  });

  test('persists and reloads appearance preferences', () async {
    const preferences = AppearancePreferences(
      mode: AppThemeMode.dark,
      preset: AppThemePreset.orangeM3,
    );

    await repository.saveAppearancePreferences(preferences);
    final loaded = await repository.loadAppearancePreferences();

    expect(loaded.mode, AppThemeMode.dark);
    expect(loaded.preset, AppThemePreset.orangeM3);
  });

  test('repeated appearance saves keep the latest singleton row', () async {
    await repository.saveAppearancePreferences(
      const AppearancePreferences(
        mode: AppThemeMode.light,
        preset: AppThemePreset.indigoM3,
      ),
    );
    await repository.saveAppearancePreferences(
      const AppearancePreferences(
        mode: AppThemeMode.dark,
        preset: AppThemePreset.orangeM3,
      ),
    );

    final loaded = await repository.loadAppearancePreferences();
    final rows = await database.select(database.appearanceSettings).get();

    expect(loaded.mode, AppThemeMode.dark);
    expect(loaded.preset, AppThemePreset.orangeM3);
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
  });

  test('repairs legacy appearance settings on the next save', () async {
    await database
        .into(database.appearanceSettings)
        .insert(
          AppearanceSettingsCompanion.insert(
            id: const Value(1),
            updatedAt: DateTime.utc(2026, 1, 1),
            themeMode: const Value('system'),
            themePreset: const Value('scheme:indigoM3'),
          ),
        );
    await database
        .into(database.appearanceSettings)
        .insert(
          AppearanceSettingsCompanion.insert(
            id: const Value(2),
            updatedAt: DateTime.utc(2026, 1, 2),
            themeMode: const Value('dark'),
            themePreset: const Value('scheme:orangeM3'),
          ),
        );

    final legacy = await repository.loadAppearancePreferences();
    expect(legacy.mode, AppThemeMode.dark);
    expect(legacy.preset, AppThemePreset.orangeM3);

    await repository.saveAppearancePreferences(const AppearancePreferences());
    final rows = await database.select(database.appearanceSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 1);
  });

  test('stores session logs and removes expired sessions', () async {
    final firstSession = await repository.startLogSession(
      ConnectionMode.tcpClient,
      DateTime.utc(2026, 1, 1),
    );
    await repository.appendLogEntries(firstSession, <LogEntry>[
      _entry(LogDirection.sent, <int>[0x01]),
    ]);
    await repository.endLogSession(firstSession, DateTime.utc(2026, 1, 1, 1));

    final secondSession = await repository.startLogSession(
      ConnectionMode.udpClient,
      DateTime.utc(2026, 1, 2),
    );
    await repository.appendLogEntries(secondSession, <LogEntry>[
      _entry(LogDirection.received, <int>[0xAA, 0x55]),
    ]);

    expect(await repository.loadSessionEntries(firstSession), hasLength(1));
    expect(
      (await repository.loadSessionEntries(secondSession)).single.bytes,
      <int>[0xAA, 0x55],
    );

    await repository.trimLogSessions(keep: 1);

    expect(await repository.loadSessionEntries(firstSession), isEmpty);
    expect(await repository.loadSessionEntries(secondSession), hasLength(1));
  });

  test(
    'loads session summaries and deletes sessions with their entries',
    () async {
      final sessionId = await repository.startLogSession(
        ConnectionMode.tcpClient,
        DateTime.utc(2026, 1, 1),
      );
      await repository.appendLogEntries(sessionId, <LogEntry>[
        _entry(LogDirection.sent, <int>[0x01, 0x02]),
        _entry(LogDirection.received, <int>[0xAA, 0x55, 0x10]),
      ]);
      await repository.endLogSession(sessionId, DateTime.utc(2026, 1, 1, 0, 1));

      final summaries = await repository.loadLogSessionSummaries();

      expect(summaries, hasLength(1));
      expect(summaries.single.id, sessionId);
      expect(summaries.single.entryCount, 2);
      expect(summaries.single.byteCount, 5);
      expect(summaries.single.duration, const Duration(minutes: 1));

      await repository.deleteLogSession(sessionId);

      expect(await repository.loadLogSessionSummaries(), isEmpty);
      expect(await repository.loadSessionEntries(sessionId), isEmpty);
    },
  );

  test('creates, updates and deletes protocol profiles', () async {
    final created = await repository.saveProtocolProfile(
      ProtocolProfile(
        name: '测试协议',
        header: const <int>[0xAA, 0x55],
        maxPayloadBytes: 64,
      ),
    );

    expect(created.id, isNotNull);
    expect((await repository.loadProtocolProfiles()).single.name, '测试协议');

    final updated = await repository.saveProtocolProfile(
      ProtocolProfile(
        id: created.id,
        name: '更新协议',
        header: const <int>[0x7E],
        commandOffset: 1,
        lengthOffset: 2,
        payloadOffset: 3,
        checksumStartOffset: 1,
        maxPayloadBytes: 32,
      ),
    );

    expect(updated.name, '更新协议');
    expect(
      (await repository.loadProtocolProfiles()).single.maxPayloadBytes,
      32,
    );

    await repository.deleteProtocolProfile(created.id!);

    expect(await repository.loadProtocolProfiles(), isEmpty);
  });
}

LogEntry _entry(LogDirection direction, List<int> bytes) {
  return LogEntry(
    timestamp: DateTime.utc(2026),
    direction: direction,
    format: PayloadFormat.hex,
    channel: 'test',
    bytes: Uint8List.fromList(bytes),
  );
}
