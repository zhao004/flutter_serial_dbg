import 'dart:async';

import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/log_session_summary.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_serial_dbg/app/pages/settings/appearance_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads saved appearance preferences', () async {
    final repository = _AppearanceRepository()
      ..appearance = const AppearancePreferences(
        mode: AppThemeMode.dark,
        preset: AppThemePreset.orangeM3,
      );
    final controller = AppearanceController(repository);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.themeMode.value, AppThemeMode.dark);
    expect(controller.themePreset.value, AppThemePreset.orangeM3);
  });

  test('keeps defaults when loading appearance fails', () async {
    final repository = _AppearanceRepository()
      ..loadError = StateError('database unavailable');
    final controller = AppearanceController(repository);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.themeMode.value, AppThemeMode.system);
    expect(controller.themePreset.value, AppThemePreset.indigoM3);
    expect(controller.lastError.value, '读取主题设置失败，已使用默认外观');
  });

  test('updates signals before queued persistence completes', () async {
    final repository = _AppearanceRepository()..holdWrites = true;
    final controller = AppearanceController(repository);
    addTearDown(controller.dispose);

    final modeWrite = controller.setThemeMode(AppThemeMode.light);
    final presetWrite = controller.setThemePreset(AppThemePreset.tealM3);

    expect(controller.themeMode.value, AppThemeMode.light);
    expect(controller.themePreset.value, AppThemePreset.tealM3);
    expect(repository.appearance.mode, AppThemeMode.system);

    await Future<void>.delayed(Duration.zero);
    repository.completeWrites();
    expect(await modeWrite, isTrue);
    expect(await presetWrite, isTrue);
    expect(repository.appearance.mode, AppThemeMode.light);
    expect(repository.appearance.preset, AppThemePreset.tealM3);
  });

  test(
    'reports a persistence failure and keeps the current selection',
    () async {
      final repository = _AppearanceRepository()
        ..writeError = StateError('disk');
      final controller = AppearanceController(repository);
      addTearDown(controller.dispose);

      final saved = await controller.setThemePreset(AppThemePreset.greenM3);

      expect(saved, isFalse);
      expect(controller.themePreset.value, AppThemePreset.greenM3);
      expect(controller.lastError.value, isNull);
    },
  );
}

final class _AppearanceRepository implements AppRepository {
  AppearancePreferences appearance = const AppearancePreferences();
  bool holdWrites = false;
  Object? loadError;
  Object? writeError;
  Completer<void>? _writeCompleter;

  @override
  Future<void> appendLogEntries(
    int sessionId,
    Iterable<LogEntry> entries,
  ) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> endLogSession(int sessionId, DateTime endedAt) async {}

  @override
  Future<AppearancePreferences> loadAppearancePreferences() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return appearance;
  }

  @override
  Future<ConnectionConfig?> loadConnectionConfig(ConnectionMode mode) async {
    return null;
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    return const AppPreferences();
  }

  @override
  Future<List<LogEntry>> loadSessionEntries(int sessionId) async {
    return const <LogEntry>[];
  }

  @override
  Future<List<LogSessionSummary>> loadLogSessionSummaries({
    ConnectionMode? mode,
    int limit = 50,
    int offset = 0,
  }) async {
    return const <LogSessionSummary>[];
  }

  @override
  Future<void> deleteLogSession(int sessionId) async {}

  @override
  Future<void> deleteAllLogSessions() async {}

  @override
  Future<List<ProtocolProfile>> loadProtocolProfiles() async {
    return const <ProtocolProfile>[];
  }

  @override
  Future<ProtocolProfile> saveProtocolProfile(ProtocolProfile profile) async {
    return profile;
  }

  @override
  Future<void> deleteProtocolProfile(int profileId) async {}

  @override
  Future<void> saveAppearancePreferences(
    AppearancePreferences preferences,
  ) async {
    if (holdWrites) {
      _writeCompleter ??= Completer<void>();
      await _writeCompleter!.future;
    }
    final error = writeError;
    if (error != null) {
      throw error;
    }
    appearance = preferences;
  }

  @override
  Future<void> saveConnectionConfig(ConnectionConfig config) async {}

  @override
  Future<void> savePreferences(AppPreferences preferences) async {}

  @override
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt) async {
    return 1;
  }

  @override
  Future<void> trimLogSessions({int keep = 20}) async {}

  void completeWrites() {
    _writeCompleter?.complete();
  }
}
