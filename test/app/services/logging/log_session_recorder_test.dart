import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/log_session_summary.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_session_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('batches pending entries and closes the session', () async {
    final repository = _RecordingRepository();
    final recorder = LogSessionRecorder(
      repository: repository,
      batchSize: 10,
      flushInterval: const Duration(hours: 1),
    );

    await recorder.start(ConnectionMode.tcpClient, DateTime.utc(2026));
    recorder
      ..add(_entry(1))
      ..add(_entry(2));
    await recorder.flush();
    await recorder.stop(DateTime.utc(2026, 1, 2));

    expect(repository.entries.map((entry) => entry.id), <int>[1, 2]);
    expect(repository.endedSessionId, 1);
    expect(recorder.isActive, isFalse);
  });

  test('buffers logs that arrive while session creation is pending', () async {
    final repository = _RecordingRepository(sessionStartDelay: true);
    final recorder = LogSessionRecorder(
      repository: repository,
      batchSize: 10,
      flushInterval: const Duration(hours: 1),
    );

    final start = recorder.start(ConnectionMode.udpClient, DateTime.utc(2026));
    recorder.add(_entry(1));
    repository.completeSessionStart();
    await start;
    await recorder.flush();

    expect(repository.entries.single.id, 1);
    await recorder.stop(DateTime.utc(2026, 1, 2));
  });
}

LogEntry _entry(int id) {
  return LogEntry(
    id: id,
    timestamp: DateTime.utc(2026),
    direction: LogDirection.sent,
    format: PayloadFormat.hex,
    channel: 'test',
    bytes: Uint8List.fromList(<int>[id]),
  );
}

final class _RecordingRepository implements AppRepository {
  _RecordingRepository({this.sessionStartDelay = false});

  final bool sessionStartDelay;
  final List<LogEntry> entries = <LogEntry>[];
  int? endedSessionId;
  final Completer<void> _sessionCompleter = Completer<void>();

  @override
  Future<void> appendLogEntries(
    int sessionId,
    Iterable<LogEntry> loggedEntries,
  ) async {
    entries.addAll(loggedEntries);
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> endLogSession(int sessionId, DateTime endedAt) async {
    endedSessionId = sessionId;
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
  Future<AppearancePreferences> loadAppearancePreferences() async {
    return const AppearancePreferences();
  }

  @override
  Future<List<LogEntry>> loadSessionEntries(int sessionId) async {
    return List<LogEntry>.of(entries);
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
  Future<void> saveConnectionConfig(ConnectionConfig config) async {}

  @override
  Future<void> savePreferences(AppPreferences preferences) async {}

  @override
  Future<void> saveAppearancePreferences(
    AppearancePreferences preferences,
  ) async {}

  @override
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt) async {
    if (sessionStartDelay) {
      await _sessionCompleter.future;
    }
    return 1;
  }

  void completeSessionStart() {
    _sessionCompleter.complete();
  }

  @override
  Future<void> trimLogSessions({int keep = 20}) async {}
}
