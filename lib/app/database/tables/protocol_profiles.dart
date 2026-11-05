import 'package:drift/drift.dart';

import '../type/utc_date_time_converter.dart';

/// 用户自定义的单字节长度、XOR 校验协议帧。
@DataClassName('ProtocolProfileRecord')
class ProtocolProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  BlobColumn get header => blob()();

  IntColumn get commandOffset => integer()();

  IntColumn get lengthOffset => integer()();

  IntColumn get payloadOffset => integer()();

  IntColumn get checksumStartOffset => integer()();

  IntColumn get maxPayloadBytes => integer().withDefault(const Constant(255))();

  DateTimeColumn get createdAt =>
      dateTime().map(const UtcDateTimeConverter())();

  DateTimeColumn get updatedAt =>
      dateTime().map(const UtcDateTimeConverter())();
}
