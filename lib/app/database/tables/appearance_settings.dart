import 'package:drift/drift.dart';

import '../type/utc_date_time_converter.dart';

/// 单例主题外观设置。
@DataClassName('AppearanceSettingRecord')
class AppearanceSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  TextColumn get themePreset => text().withDefault(const Constant('indigo'))();

  DateTimeColumn get updatedAt =>
      dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
