import 'package:drift/drift.dart';

import '../../models/log_entry.dart';
import '../type/utc_date_time_converter.dart';
import 'log_sessions.dart';

/// 会话中的原始通信日志。
@DataClassName('LogEntryRow')
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId =>
      integer().references(LogSessions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get timestamp =>
      dateTime().map(const UtcDateTimeConverter())();

  TextColumn get direction => textEnum<LogDirection>()();

  TextColumn get format => textEnum<PayloadFormat>()();

  TextColumn get channel => text()();

  BlobColumn get payload => blob()();
}
