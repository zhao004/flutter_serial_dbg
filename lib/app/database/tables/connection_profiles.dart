import 'package:drift/drift.dart';

import '../../models/connection_mode.dart';
import '../type/utc_date_time_converter.dart';

/// 每种通信模式保存一条最近使用的连接配置。
@DataClassName('ConnectionProfileRecord')
class ConnectionProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get mode => textEnum<ConnectionMode>()();

  TextColumn get host => text().nullable()();

  IntColumn get port => integer().nullable()();

  TextColumn get bindAddress => text().nullable()();

  TextColumn get bleRemoteId => text().nullable()();

  TextColumn get serviceUuid => text().nullable()();

  TextColumn get writeCharacteristicUuid => text().nullable()();

  TextColumn get notifyCharacteristicUuid => text().nullable()();

  TextColumn get usbDeviceKey => text().nullable()();

  IntColumn get baudRate => integer().nullable()();

  IntColumn get dataBits => integer().nullable()();

  TextColumn get stopBits => text().nullable()();

  TextColumn get parity => text().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().map(const UtcDateTimeConverter())();
}
