import 'package:drift/drift.dart';

import '../../models/log_entry.dart';
import '../type/utc_date_time_converter.dart';

/// 单例应用设置。
@DataClassName('AppSettingRecord')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get sendFormat =>
      textEnum<PayloadFormat>().withDefault(const Constant('text'))();

  TextColumn get receiveFormat =>
      textEnum<PayloadFormat>().withDefault(const Constant('text'))();

  BoolColumn get appendCrlf => boolean().withDefault(const Constant(false))();

  BoolColumn get autoScroll => boolean().withDefault(const Constant(true))();

  BoolColumn get persistSessionLogs =>
      boolean().withDefault(const Constant(true))();

  IntColumn get logRetentionSessions =>
      integer().withDefault(const Constant(20))();

  DateTimeColumn get updatedAt =>
      dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
