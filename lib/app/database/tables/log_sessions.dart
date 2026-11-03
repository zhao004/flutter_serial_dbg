import 'package:drift/drift.dart';

import '../../models/connection_mode.dart';
import '../type/utc_date_time_converter.dart';

/// 一次成功传输连接的会话元数据。
@DataClassName('LogSessionRecord')
class LogSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get mode => textEnum<ConnectionMode>()();

  DateTimeColumn get startedAt =>
      dateTime().map(const UtcDateTimeConverter())();

  DateTimeColumn get endedAt =>
      dateTime().map(const UtcDateTimeConverter()).nullable()();
}
