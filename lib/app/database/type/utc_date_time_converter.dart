import 'package:drift/drift.dart';

/// 在 SQLite 中统一存储 UTC 时间，读取后转换为本地时间。
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toLocal();

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
