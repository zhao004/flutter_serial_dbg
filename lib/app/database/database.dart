import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../models/connection_mode.dart';
import '../models/log_entry.dart';
import 'tables/appearance_settings.dart';
import 'tables/app_settings.dart';
import 'tables/connection_profiles.dart';
import 'tables/log_entries.dart';
import 'tables/log_sessions.dart';
import 'type/utc_date_time_converter.dart';

part 'database.g.dart';

/// 连接配置、设置和通信日志的本地数据库。
@DriftDatabase(
  tables: [
    ConnectionProfiles,
    AppSettings,
    AppearanceSettings,
    LogSessions,
    LogEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 为测试注入内存或临时 QueryExecutor。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(
            connectionProfiles,
            connectionProfiles.usbDeviceKey,
          );
        }
        if (from < 3) {
          await migrator.createTable(appearanceSettings);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(
      File('${directory.path}/serial_debug.sqlite'),
      logStatements: false,
    );
  });
}
