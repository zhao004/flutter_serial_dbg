import 'package:drift/drift.dart';

import '../models/appearance_preferences.dart';
import '../models/app_preferences.dart';
import '../models/connection_config.dart';
import '../models/connection_mode.dart';
import '../models/log_entry.dart';
import 'database.dart';

/// 连接配置、应用设置和日志的持久化边界。
abstract interface class AppRepository {
  /// 读取指定模式最近一次成功使用的配置。
  Future<ConnectionConfig?> loadConnectionConfig(ConnectionMode mode);

  /// 保存指定模式的配置，并替换同模式旧记录。
  Future<void> saveConnectionConfig(ConnectionConfig config);

  /// 读取应用设置；无记录时返回默认值。
  Future<AppPreferences> loadPreferences();

  /// 保存应用设置。
  Future<void> savePreferences(AppPreferences preferences);

  /// 读取主题外观设置；无记录时返回默认值。
  Future<AppearancePreferences> loadAppearancePreferences();

  /// 保存主题外观设置。
  Future<void> saveAppearancePreferences(AppearancePreferences preferences);

  /// 创建日志会话并返回数据库主键。
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt);

  /// 标记日志会话结束。
  Future<void> endLogSession(int sessionId, DateTime endedAt);

  /// 批量追加会话日志。
  Future<void> appendLogEntries(int sessionId, Iterable<LogEntry> entries);

  /// 按时间顺序读取一个会话的日志。
  Future<List<LogEntry>> loadSessionEntries(int sessionId);

  /// 仅保留最近指定数量的日志会话。
  Future<void> trimLogSessions({int keep = 20});

  /// 关闭底层数据库。
  Future<void> close();
}

/// 基于 Drift 的应用数据仓库。
final class DriftAppRepository implements AppRepository {
  factory DriftAppRepository({
    required AppDatabase database,
    DateTime Function()? clock,
  }) {
    return DriftAppRepository._(database, clock ?? DateTime.now);
  }

  DriftAppRepository._(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<ConnectionConfig?> loadConnectionConfig(ConnectionMode mode) async {
    final row =
        await (_database.select(_database.connectionProfiles)
              ..where((table) => table.mode.equals(mode.name))
              ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _configFromRow(row);
  }

  @override
  Future<void> saveConnectionConfig(ConnectionConfig config) async {
    final companion = _configToCompanion(config);
    await _database.transaction(() async {
      await (_database.delete(
        _database.connectionProfiles,
      )..where((table) => table.mode.equals(config.mode.name))).go();
      await _database.into(_database.connectionProfiles).insert(companion);
    });
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    final row =
        await (_database.select(_database.appSettings)
              ..orderBy([
                (table) => OrderingTerm.desc(table.updatedAt),
                (table) => OrderingTerm.desc(table.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return const AppPreferences();
    }
    return AppPreferences(
      sendFormat: row.sendFormat,
      receiveFormat: row.receiveFormat,
      appendCrlf: row.appendCrlf,
      autoScroll: row.autoScroll,
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    await _database.transaction(() async {
      await _database.delete(_database.appSettings).go();
      await _database
          .into(_database.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              id: const Value(_singletonSettingsId),
              updatedAt: _clock(),
              sendFormat: Value(preferences.sendFormat),
              receiveFormat: Value(preferences.receiveFormat),
              appendCrlf: Value(preferences.appendCrlf),
              autoScroll: Value(preferences.autoScroll),
            ),
          );
    });
  }

  @override
  Future<AppearancePreferences> loadAppearancePreferences() async {
    final row =
        await (_database.select(_database.appearanceSettings)
              ..orderBy([
                (table) => OrderingTerm.desc(table.updatedAt),
                (table) => OrderingTerm.desc(table.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return const AppearancePreferences();
    }
    return AppearancePreferences(
      mode: AppThemeMode.fromStorage(row.themeMode),
      preset: AppThemePreset.fromStorage(row.themePreset),
    );
  }

  @override
  Future<void> saveAppearancePreferences(
    AppearancePreferences preferences,
  ) async {
    await _database.transaction(() async {
      await _database.delete(_database.appearanceSettings).go();
      await _database
          .into(_database.appearanceSettings)
          .insert(
            AppearanceSettingsCompanion.insert(
              id: const Value(_singletonSettingsId),
              updatedAt: _clock(),
              themeMode: Value(preferences.mode.name),
              themePreset: Value(preferences.preset.storageValue),
            ),
          );
    });
  }

  @override
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt) {
    return _database
        .into(_database.logSessions)
        .insert(LogSessionsCompanion.insert(mode: mode, startedAt: startedAt));
  }

  @override
  Future<void> endLogSession(int sessionId, DateTime endedAt) async {
    await (_database.update(_database.logSessions)
          ..where((table) => table.id.equals(sessionId)))
        .write(LogSessionsCompanion(endedAt: Value(endedAt)));
  }

  @override
  Future<void> appendLogEntries(
    int sessionId,
    Iterable<LogEntry> entries,
  ) async {
    final companions = entries
        .map(
          (entry) => LogEntriesCompanion.insert(
            sessionId: sessionId,
            timestamp: entry.timestamp,
            direction: entry.direction,
            format: entry.format,
            channel: entry.channel,
            payload: entry.copyBytes(),
          ),
        )
        .toList(growable: false);
    if (companions.isEmpty) {
      return;
    }
    await _database.batch(
      (batch) => batch.insertAll(_database.logEntries, companions),
    );
  }

  @override
  Future<List<LogEntry>> loadSessionEntries(int sessionId) async {
    final rows =
        await (_database.select(_database.logEntries)
              ..where((table) => table.sessionId.equals(sessionId))
              ..orderBy([
                (table) => OrderingTerm.asc(table.timestamp),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();
    return rows
        .map(
          (row) => LogEntry(
            id: row.id,
            timestamp: row.timestamp,
            direction: row.direction,
            format: row.format,
            channel: row.channel,
            bytes: Uint8List.fromList(row.payload),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> trimLogSessions({int keep = 20}) async {
    if (keep <= 0) {
      throw ArgumentError.value(keep, 'keep', '必须大于 0');
    }
    final rows = await (_database.select(
      _database.logSessions,
    )..orderBy([(table) => OrderingTerm.desc(table.startedAt)])).get();
    if (rows.length <= keep) {
      return;
    }
    final expiredIds = rows.skip(keep).map((row) => row.id).toList();
    await _database.transaction(() async {
      await (_database.delete(
        _database.logEntries,
      )..where((table) => table.sessionId.isIn(expiredIds))).go();
      await (_database.delete(
        _database.logSessions,
      )..where((table) => table.id.isIn(expiredIds))).go();
    });
  }

  @override
  Future<void> close() => _database.close();

  ConnectionProfilesCompanion _configToCompanion(ConnectionConfig config) {
    final common = ConnectionProfilesCompanion(
      mode: Value(config.mode),
      updatedAt: Value(_clock()),
    );
    return switch (config) {
      TcpClientConfig() => common.copyWith(
        host: Value(config.host),
        port: Value(config.port),
      ),
      TcpServerConfig() => common.copyWith(
        bindAddress: Value(config.bindAddress),
        port: Value(config.port),
      ),
      UdpClientConfig() => common.copyWith(
        host: Value(config.host),
        port: Value(config.port),
      ),
      UdpServerConfig() => common.copyWith(
        bindAddress: Value(config.bindAddress),
        port: Value(config.port),
      ),
      BleConfig() => common.copyWith(
        bleRemoteId: Value(config.remoteId),
        serviceUuid: Value(config.serviceUuid),
        writeCharacteristicUuid: Value(config.writeCharacteristicUuid),
        notifyCharacteristicUuid: Value(config.notifyCharacteristicUuid),
      ),
      UsbSerialConfig() => common.copyWith(
        usbDeviceKey: Value(config.deviceId),
        baudRate: Value(config.baudRate),
        dataBits: Value(config.dataBits),
        stopBits: Value(config.stopBits.name),
        parity: Value(config.parity.name),
      ),
    };
  }

  ConnectionConfig? _configFromRow(ConnectionProfileRecord row) {
    return switch (row.mode) {
      ConnectionMode.tcpClient when row.host != null && row.port != null =>
        TcpClientConfig(host: row.host!, port: row.port!),
      ConnectionMode.tcpServer
          when row.bindAddress != null && row.port != null =>
        TcpServerConfig(bindAddress: row.bindAddress!, port: row.port!),
      ConnectionMode.udpClient when row.host != null && row.port != null =>
        UdpClientConfig(host: row.host!, port: row.port!),
      ConnectionMode.udpServer
          when row.bindAddress != null && row.port != null =>
        UdpServerConfig(bindAddress: row.bindAddress!, port: row.port!),
      ConnectionMode.ble when row.bleRemoteId != null => BleConfig(
        remoteId: row.bleRemoteId!,
        serviceUuid: row.serviceUuid,
        writeCharacteristicUuid: row.writeCharacteristicUuid,
        notifyCharacteristicUuid: row.notifyCharacteristicUuid,
      ),
      ConnectionMode.usbSerial
          when row.usbDeviceKey != null &&
              row.baudRate != null &&
              row.dataBits != null =>
        UsbSerialConfig(
          deviceId: row.usbDeviceKey!,
          baudRate: row.baudRate!,
          dataBits: row.dataBits!,
          stopBits:
              _enumByName(UsbStopBits.values, row.stopBits) ?? UsbStopBits.one,
          parity: _enumByName(UsbParity.values, row.parity) ?? UsbParity.none,
        ),
      _ => null,
    };
  }
}

/// 单例设置表的固定主键，避免 SQLite 为省略主键的插入分配新 rowid。
const int _singletonSettingsId = 1;

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) {
    return null;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}
