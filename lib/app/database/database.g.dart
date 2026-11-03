// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ConnectionProfilesTable extends ConnectionProfiles
    with TableInfo<$ConnectionProfilesTable, ConnectionProfileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConnectionMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ConnectionMode>($ConnectionProfilesTable.$convertermode);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bindAddressMeta = const VerificationMeta(
    'bindAddress',
  );
  @override
  late final GeneratedColumn<String> bindAddress = GeneratedColumn<String>(
    'bind_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bleRemoteIdMeta = const VerificationMeta(
    'bleRemoteId',
  );
  @override
  late final GeneratedColumn<String> bleRemoteId = GeneratedColumn<String>(
    'ble_remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceUuidMeta = const VerificationMeta(
    'serviceUuid',
  );
  @override
  late final GeneratedColumn<String> serviceUuid = GeneratedColumn<String>(
    'service_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writeCharacteristicUuidMeta =
      const VerificationMeta('writeCharacteristicUuid');
  @override
  late final GeneratedColumn<String> writeCharacteristicUuid =
      GeneratedColumn<String>(
        'write_characteristic_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notifyCharacteristicUuidMeta =
      const VerificationMeta('notifyCharacteristicUuid');
  @override
  late final GeneratedColumn<String> notifyCharacteristicUuid =
      GeneratedColumn<String>(
        'notify_characteristic_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _usbDeviceKeyMeta = const VerificationMeta(
    'usbDeviceKey',
  );
  @override
  late final GeneratedColumn<String> usbDeviceKey = GeneratedColumn<String>(
    'usb_device_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baudRateMeta = const VerificationMeta(
    'baudRate',
  );
  @override
  late final GeneratedColumn<int> baudRate = GeneratedColumn<int>(
    'baud_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataBitsMeta = const VerificationMeta(
    'dataBits',
  );
  @override
  late final GeneratedColumn<int> dataBits = GeneratedColumn<int>(
    'data_bits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stopBitsMeta = const VerificationMeta(
    'stopBits',
  );
  @override
  late final GeneratedColumn<String> stopBits = GeneratedColumn<String>(
    'stop_bits',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parityMeta = const VerificationMeta('parity');
  @override
  late final GeneratedColumn<String> parity = GeneratedColumn<String>(
    'parity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ConnectionProfilesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    host,
    port,
    bindAddress,
    bleRemoteId,
    serviceUuid,
    writeCharacteristicUuid,
    notifyCharacteristicUuid,
    usbDeviceKey,
    baudRate,
    dataBits,
    stopBits,
    parity,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionProfileRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('bind_address')) {
      context.handle(
        _bindAddressMeta,
        bindAddress.isAcceptableOrUnknown(
          data['bind_address']!,
          _bindAddressMeta,
        ),
      );
    }
    if (data.containsKey('ble_remote_id')) {
      context.handle(
        _bleRemoteIdMeta,
        bleRemoteId.isAcceptableOrUnknown(
          data['ble_remote_id']!,
          _bleRemoteIdMeta,
        ),
      );
    }
    if (data.containsKey('service_uuid')) {
      context.handle(
        _serviceUuidMeta,
        serviceUuid.isAcceptableOrUnknown(
          data['service_uuid']!,
          _serviceUuidMeta,
        ),
      );
    }
    if (data.containsKey('write_characteristic_uuid')) {
      context.handle(
        _writeCharacteristicUuidMeta,
        writeCharacteristicUuid.isAcceptableOrUnknown(
          data['write_characteristic_uuid']!,
          _writeCharacteristicUuidMeta,
        ),
      );
    }
    if (data.containsKey('notify_characteristic_uuid')) {
      context.handle(
        _notifyCharacteristicUuidMeta,
        notifyCharacteristicUuid.isAcceptableOrUnknown(
          data['notify_characteristic_uuid']!,
          _notifyCharacteristicUuidMeta,
        ),
      );
    }
    if (data.containsKey('usb_device_key')) {
      context.handle(
        _usbDeviceKeyMeta,
        usbDeviceKey.isAcceptableOrUnknown(
          data['usb_device_key']!,
          _usbDeviceKeyMeta,
        ),
      );
    }
    if (data.containsKey('baud_rate')) {
      context.handle(
        _baudRateMeta,
        baudRate.isAcceptableOrUnknown(data['baud_rate']!, _baudRateMeta),
      );
    }
    if (data.containsKey('data_bits')) {
      context.handle(
        _dataBitsMeta,
        dataBits.isAcceptableOrUnknown(data['data_bits']!, _dataBitsMeta),
      );
    }
    if (data.containsKey('stop_bits')) {
      context.handle(
        _stopBitsMeta,
        stopBits.isAcceptableOrUnknown(data['stop_bits']!, _stopBitsMeta),
      );
    }
    if (data.containsKey('parity')) {
      context.handle(
        _parityMeta,
        parity.isAcceptableOrUnknown(data['parity']!, _parityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionProfileRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionProfileRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: $ConnectionProfilesTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      ),
      bindAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bind_address'],
      ),
      bleRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ble_remote_id'],
      ),
      serviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_uuid'],
      ),
      writeCharacteristicUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}write_characteristic_uuid'],
      ),
      notifyCharacteristicUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notify_characteristic_uuid'],
      ),
      usbDeviceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usb_device_key'],
      ),
      baudRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}baud_rate'],
      ),
      dataBits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_bits'],
      ),
      stopBits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stop_bits'],
      ),
      parity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parity'],
      ),
      updatedAt: $ConnectionProfilesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ConnectionProfilesTable createAlias(String alias) {
    return $ConnectionProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConnectionMode, String, String> $convertermode =
      const EnumNameConverter<ConnectionMode>(ConnectionMode.values);
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class ConnectionProfileRecord extends DataClass
    implements Insertable<ConnectionProfileRecord> {
  final int id;
  final ConnectionMode mode;
  final String? host;
  final int? port;
  final String? bindAddress;
  final String? bleRemoteId;
  final String? serviceUuid;
  final String? writeCharacteristicUuid;
  final String? notifyCharacteristicUuid;
  final String? usbDeviceKey;
  final int? baudRate;
  final int? dataBits;
  final String? stopBits;
  final String? parity;
  final DateTime updatedAt;
  const ConnectionProfileRecord({
    required this.id,
    required this.mode,
    this.host,
    this.port,
    this.bindAddress,
    this.bleRemoteId,
    this.serviceUuid,
    this.writeCharacteristicUuid,
    this.notifyCharacteristicUuid,
    this.usbDeviceKey,
    this.baudRate,
    this.dataBits,
    this.stopBits,
    this.parity,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['mode'] = Variable<String>(
        $ConnectionProfilesTable.$convertermode.toSql(mode),
      );
    }
    if (!nullToAbsent || host != null) {
      map['host'] = Variable<String>(host);
    }
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    if (!nullToAbsent || bindAddress != null) {
      map['bind_address'] = Variable<String>(bindAddress);
    }
    if (!nullToAbsent || bleRemoteId != null) {
      map['ble_remote_id'] = Variable<String>(bleRemoteId);
    }
    if (!nullToAbsent || serviceUuid != null) {
      map['service_uuid'] = Variable<String>(serviceUuid);
    }
    if (!nullToAbsent || writeCharacteristicUuid != null) {
      map['write_characteristic_uuid'] = Variable<String>(
        writeCharacteristicUuid,
      );
    }
    if (!nullToAbsent || notifyCharacteristicUuid != null) {
      map['notify_characteristic_uuid'] = Variable<String>(
        notifyCharacteristicUuid,
      );
    }
    if (!nullToAbsent || usbDeviceKey != null) {
      map['usb_device_key'] = Variable<String>(usbDeviceKey);
    }
    if (!nullToAbsent || baudRate != null) {
      map['baud_rate'] = Variable<int>(baudRate);
    }
    if (!nullToAbsent || dataBits != null) {
      map['data_bits'] = Variable<int>(dataBits);
    }
    if (!nullToAbsent || stopBits != null) {
      map['stop_bits'] = Variable<String>(stopBits);
    }
    if (!nullToAbsent || parity != null) {
      map['parity'] = Variable<String>(parity);
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $ConnectionProfilesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ConnectionProfilesCompanion toCompanion(bool nullToAbsent) {
    return ConnectionProfilesCompanion(
      id: Value(id),
      mode: Value(mode),
      host: host == null && nullToAbsent ? const Value.absent() : Value(host),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      bindAddress: bindAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(bindAddress),
      bleRemoteId: bleRemoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(bleRemoteId),
      serviceUuid: serviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceUuid),
      writeCharacteristicUuid: writeCharacteristicUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(writeCharacteristicUuid),
      notifyCharacteristicUuid: notifyCharacteristicUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(notifyCharacteristicUuid),
      usbDeviceKey: usbDeviceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(usbDeviceKey),
      baudRate: baudRate == null && nullToAbsent
          ? const Value.absent()
          : Value(baudRate),
      dataBits: dataBits == null && nullToAbsent
          ? const Value.absent()
          : Value(dataBits),
      stopBits: stopBits == null && nullToAbsent
          ? const Value.absent()
          : Value(stopBits),
      parity: parity == null && nullToAbsent
          ? const Value.absent()
          : Value(parity),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConnectionProfileRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionProfileRecord(
      id: serializer.fromJson<int>(json['id']),
      mode: $ConnectionProfilesTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      host: serializer.fromJson<String?>(json['host']),
      port: serializer.fromJson<int?>(json['port']),
      bindAddress: serializer.fromJson<String?>(json['bindAddress']),
      bleRemoteId: serializer.fromJson<String?>(json['bleRemoteId']),
      serviceUuid: serializer.fromJson<String?>(json['serviceUuid']),
      writeCharacteristicUuid: serializer.fromJson<String?>(
        json['writeCharacteristicUuid'],
      ),
      notifyCharacteristicUuid: serializer.fromJson<String?>(
        json['notifyCharacteristicUuid'],
      ),
      usbDeviceKey: serializer.fromJson<String?>(json['usbDeviceKey']),
      baudRate: serializer.fromJson<int?>(json['baudRate']),
      dataBits: serializer.fromJson<int?>(json['dataBits']),
      stopBits: serializer.fromJson<String?>(json['stopBits']),
      parity: serializer.fromJson<String?>(json['parity']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(
        $ConnectionProfilesTable.$convertermode.toJson(mode),
      ),
      'host': serializer.toJson<String?>(host),
      'port': serializer.toJson<int?>(port),
      'bindAddress': serializer.toJson<String?>(bindAddress),
      'bleRemoteId': serializer.toJson<String?>(bleRemoteId),
      'serviceUuid': serializer.toJson<String?>(serviceUuid),
      'writeCharacteristicUuid': serializer.toJson<String?>(
        writeCharacteristicUuid,
      ),
      'notifyCharacteristicUuid': serializer.toJson<String?>(
        notifyCharacteristicUuid,
      ),
      'usbDeviceKey': serializer.toJson<String?>(usbDeviceKey),
      'baudRate': serializer.toJson<int?>(baudRate),
      'dataBits': serializer.toJson<int?>(dataBits),
      'stopBits': serializer.toJson<String?>(stopBits),
      'parity': serializer.toJson<String?>(parity),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConnectionProfileRecord copyWith({
    int? id,
    ConnectionMode? mode,
    Value<String?> host = const Value.absent(),
    Value<int?> port = const Value.absent(),
    Value<String?> bindAddress = const Value.absent(),
    Value<String?> bleRemoteId = const Value.absent(),
    Value<String?> serviceUuid = const Value.absent(),
    Value<String?> writeCharacteristicUuid = const Value.absent(),
    Value<String?> notifyCharacteristicUuid = const Value.absent(),
    Value<String?> usbDeviceKey = const Value.absent(),
    Value<int?> baudRate = const Value.absent(),
    Value<int?> dataBits = const Value.absent(),
    Value<String?> stopBits = const Value.absent(),
    Value<String?> parity = const Value.absent(),
    DateTime? updatedAt,
  }) => ConnectionProfileRecord(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    host: host.present ? host.value : this.host,
    port: port.present ? port.value : this.port,
    bindAddress: bindAddress.present ? bindAddress.value : this.bindAddress,
    bleRemoteId: bleRemoteId.present ? bleRemoteId.value : this.bleRemoteId,
    serviceUuid: serviceUuid.present ? serviceUuid.value : this.serviceUuid,
    writeCharacteristicUuid: writeCharacteristicUuid.present
        ? writeCharacteristicUuid.value
        : this.writeCharacteristicUuid,
    notifyCharacteristicUuid: notifyCharacteristicUuid.present
        ? notifyCharacteristicUuid.value
        : this.notifyCharacteristicUuid,
    usbDeviceKey: usbDeviceKey.present ? usbDeviceKey.value : this.usbDeviceKey,
    baudRate: baudRate.present ? baudRate.value : this.baudRate,
    dataBits: dataBits.present ? dataBits.value : this.dataBits,
    stopBits: stopBits.present ? stopBits.value : this.stopBits,
    parity: parity.present ? parity.value : this.parity,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConnectionProfileRecord copyWithCompanion(ConnectionProfilesCompanion data) {
    return ConnectionProfileRecord(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      bindAddress: data.bindAddress.present
          ? data.bindAddress.value
          : this.bindAddress,
      bleRemoteId: data.bleRemoteId.present
          ? data.bleRemoteId.value
          : this.bleRemoteId,
      serviceUuid: data.serviceUuid.present
          ? data.serviceUuid.value
          : this.serviceUuid,
      writeCharacteristicUuid: data.writeCharacteristicUuid.present
          ? data.writeCharacteristicUuid.value
          : this.writeCharacteristicUuid,
      notifyCharacteristicUuid: data.notifyCharacteristicUuid.present
          ? data.notifyCharacteristicUuid.value
          : this.notifyCharacteristicUuid,
      usbDeviceKey: data.usbDeviceKey.present
          ? data.usbDeviceKey.value
          : this.usbDeviceKey,
      baudRate: data.baudRate.present ? data.baudRate.value : this.baudRate,
      dataBits: data.dataBits.present ? data.dataBits.value : this.dataBits,
      stopBits: data.stopBits.present ? data.stopBits.value : this.stopBits,
      parity: data.parity.present ? data.parity.value : this.parity,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionProfileRecord(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('bindAddress: $bindAddress, ')
          ..write('bleRemoteId: $bleRemoteId, ')
          ..write('serviceUuid: $serviceUuid, ')
          ..write('writeCharacteristicUuid: $writeCharacteristicUuid, ')
          ..write('notifyCharacteristicUuid: $notifyCharacteristicUuid, ')
          ..write('usbDeviceKey: $usbDeviceKey, ')
          ..write('baudRate: $baudRate, ')
          ..write('dataBits: $dataBits, ')
          ..write('stopBits: $stopBits, ')
          ..write('parity: $parity, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    host,
    port,
    bindAddress,
    bleRemoteId,
    serviceUuid,
    writeCharacteristicUuid,
    notifyCharacteristicUuid,
    usbDeviceKey,
    baudRate,
    dataBits,
    stopBits,
    parity,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionProfileRecord &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.host == this.host &&
          other.port == this.port &&
          other.bindAddress == this.bindAddress &&
          other.bleRemoteId == this.bleRemoteId &&
          other.serviceUuid == this.serviceUuid &&
          other.writeCharacteristicUuid == this.writeCharacteristicUuid &&
          other.notifyCharacteristicUuid == this.notifyCharacteristicUuid &&
          other.usbDeviceKey == this.usbDeviceKey &&
          other.baudRate == this.baudRate &&
          other.dataBits == this.dataBits &&
          other.stopBits == this.stopBits &&
          other.parity == this.parity &&
          other.updatedAt == this.updatedAt);
}

class ConnectionProfilesCompanion
    extends UpdateCompanion<ConnectionProfileRecord> {
  final Value<int> id;
  final Value<ConnectionMode> mode;
  final Value<String?> host;
  final Value<int?> port;
  final Value<String?> bindAddress;
  final Value<String?> bleRemoteId;
  final Value<String?> serviceUuid;
  final Value<String?> writeCharacteristicUuid;
  final Value<String?> notifyCharacteristicUuid;
  final Value<String?> usbDeviceKey;
  final Value<int?> baudRate;
  final Value<int?> dataBits;
  final Value<String?> stopBits;
  final Value<String?> parity;
  final Value<DateTime> updatedAt;
  const ConnectionProfilesCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.bindAddress = const Value.absent(),
    this.bleRemoteId = const Value.absent(),
    this.serviceUuid = const Value.absent(),
    this.writeCharacteristicUuid = const Value.absent(),
    this.notifyCharacteristicUuid = const Value.absent(),
    this.usbDeviceKey = const Value.absent(),
    this.baudRate = const Value.absent(),
    this.dataBits = const Value.absent(),
    this.stopBits = const Value.absent(),
    this.parity = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConnectionProfilesCompanion.insert({
    this.id = const Value.absent(),
    required ConnectionMode mode,
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.bindAddress = const Value.absent(),
    this.bleRemoteId = const Value.absent(),
    this.serviceUuid = const Value.absent(),
    this.writeCharacteristicUuid = const Value.absent(),
    this.notifyCharacteristicUuid = const Value.absent(),
    this.usbDeviceKey = const Value.absent(),
    this.baudRate = const Value.absent(),
    this.dataBits = const Value.absent(),
    this.stopBits = const Value.absent(),
    this.parity = const Value.absent(),
    required DateTime updatedAt,
  }) : mode = Value(mode),
       updatedAt = Value(updatedAt);
  static Insertable<ConnectionProfileRecord> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? bindAddress,
    Expression<String>? bleRemoteId,
    Expression<String>? serviceUuid,
    Expression<String>? writeCharacteristicUuid,
    Expression<String>? notifyCharacteristicUuid,
    Expression<String>? usbDeviceKey,
    Expression<int>? baudRate,
    Expression<int>? dataBits,
    Expression<String>? stopBits,
    Expression<String>? parity,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (bindAddress != null) 'bind_address': bindAddress,
      if (bleRemoteId != null) 'ble_remote_id': bleRemoteId,
      if (serviceUuid != null) 'service_uuid': serviceUuid,
      if (writeCharacteristicUuid != null)
        'write_characteristic_uuid': writeCharacteristicUuid,
      if (notifyCharacteristicUuid != null)
        'notify_characteristic_uuid': notifyCharacteristicUuid,
      if (usbDeviceKey != null) 'usb_device_key': usbDeviceKey,
      if (baudRate != null) 'baud_rate': baudRate,
      if (dataBits != null) 'data_bits': dataBits,
      if (stopBits != null) 'stop_bits': stopBits,
      if (parity != null) 'parity': parity,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConnectionProfilesCompanion copyWith({
    Value<int>? id,
    Value<ConnectionMode>? mode,
    Value<String?>? host,
    Value<int?>? port,
    Value<String?>? bindAddress,
    Value<String?>? bleRemoteId,
    Value<String?>? serviceUuid,
    Value<String?>? writeCharacteristicUuid,
    Value<String?>? notifyCharacteristicUuid,
    Value<String?>? usbDeviceKey,
    Value<int?>? baudRate,
    Value<int?>? dataBits,
    Value<String?>? stopBits,
    Value<String?>? parity,
    Value<DateTime>? updatedAt,
  }) {
    return ConnectionProfilesCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      host: host ?? this.host,
      port: port ?? this.port,
      bindAddress: bindAddress ?? this.bindAddress,
      bleRemoteId: bleRemoteId ?? this.bleRemoteId,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      writeCharacteristicUuid:
          writeCharacteristicUuid ?? this.writeCharacteristicUuid,
      notifyCharacteristicUuid:
          notifyCharacteristicUuid ?? this.notifyCharacteristicUuid,
      usbDeviceKey: usbDeviceKey ?? this.usbDeviceKey,
      baudRate: baudRate ?? this.baudRate,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $ConnectionProfilesTable.$convertermode.toSql(mode.value),
      );
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (bindAddress.present) {
      map['bind_address'] = Variable<String>(bindAddress.value);
    }
    if (bleRemoteId.present) {
      map['ble_remote_id'] = Variable<String>(bleRemoteId.value);
    }
    if (serviceUuid.present) {
      map['service_uuid'] = Variable<String>(serviceUuid.value);
    }
    if (writeCharacteristicUuid.present) {
      map['write_characteristic_uuid'] = Variable<String>(
        writeCharacteristicUuid.value,
      );
    }
    if (notifyCharacteristicUuid.present) {
      map['notify_characteristic_uuid'] = Variable<String>(
        notifyCharacteristicUuid.value,
      );
    }
    if (usbDeviceKey.present) {
      map['usb_device_key'] = Variable<String>(usbDeviceKey.value);
    }
    if (baudRate.present) {
      map['baud_rate'] = Variable<int>(baudRate.value);
    }
    if (dataBits.present) {
      map['data_bits'] = Variable<int>(dataBits.value);
    }
    if (stopBits.present) {
      map['stop_bits'] = Variable<String>(stopBits.value);
    }
    if (parity.present) {
      map['parity'] = Variable<String>(parity.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $ConnectionProfilesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionProfilesCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('bindAddress: $bindAddress, ')
          ..write('bleRemoteId: $bleRemoteId, ')
          ..write('serviceUuid: $serviceUuid, ')
          ..write('writeCharacteristicUuid: $writeCharacteristicUuid, ')
          ..write('notifyCharacteristicUuid: $notifyCharacteristicUuid, ')
          ..write('usbDeviceKey: $usbDeviceKey, ')
          ..write('baudRate: $baudRate, ')
          ..write('dataBits: $dataBits, ')
          ..write('stopBits: $stopBits, ')
          ..write('parity: $parity, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PayloadFormat, String>
  sendFormat = GeneratedColumn<String>(
    'send_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  ).withConverter<PayloadFormat>($AppSettingsTable.$convertersendFormat);
  @override
  late final GeneratedColumnWithTypeConverter<PayloadFormat, String>
  receiveFormat = GeneratedColumn<String>(
    'receive_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  ).withConverter<PayloadFormat>($AppSettingsTable.$converterreceiveFormat);
  static const VerificationMeta _appendCrlfMeta = const VerificationMeta(
    'appendCrlf',
  );
  @override
  late final GeneratedColumn<bool> appendCrlf = GeneratedColumn<bool>(
    'append_crlf',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("append_crlf" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _autoScrollMeta = const VerificationMeta(
    'autoScroll',
  );
  @override
  late final GeneratedColumn<bool> autoScroll = GeneratedColumn<bool>(
    'auto_scroll',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_scroll" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppSettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sendFormat,
    receiveFormat,
    appendCrlf,
    autoScroll,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('append_crlf')) {
      context.handle(
        _appendCrlfMeta,
        appendCrlf.isAcceptableOrUnknown(data['append_crlf']!, _appendCrlfMeta),
      );
    }
    if (data.containsKey('auto_scroll')) {
      context.handle(
        _autoScrollMeta,
        autoScroll.isAcceptableOrUnknown(data['auto_scroll']!, _autoScrollMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sendFormat: $AppSettingsTable.$convertersendFormat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}send_format'],
        )!,
      ),
      receiveFormat: $AppSettingsTable.$converterreceiveFormat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}receive_format'],
        )!,
      ),
      appendCrlf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}append_crlf'],
      )!,
      autoScroll: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_scroll'],
      )!,
      updatedAt: $AppSettingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PayloadFormat, String, String>
  $convertersendFormat = const EnumNameConverter<PayloadFormat>(
    PayloadFormat.values,
  );
  static JsonTypeConverter2<PayloadFormat, String, String>
  $converterreceiveFormat = const EnumNameConverter<PayloadFormat>(
    PayloadFormat.values,
  );
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class AppSettingRecord extends DataClass
    implements Insertable<AppSettingRecord> {
  final int id;
  final PayloadFormat sendFormat;
  final PayloadFormat receiveFormat;
  final bool appendCrlf;
  final bool autoScroll;
  final DateTime updatedAt;
  const AppSettingRecord({
    required this.id,
    required this.sendFormat,
    required this.receiveFormat,
    required this.appendCrlf,
    required this.autoScroll,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['send_format'] = Variable<String>(
        $AppSettingsTable.$convertersendFormat.toSql(sendFormat),
      );
    }
    {
      map['receive_format'] = Variable<String>(
        $AppSettingsTable.$converterreceiveFormat.toSql(receiveFormat),
      );
    }
    map['append_crlf'] = Variable<bool>(appendCrlf);
    map['auto_scroll'] = Variable<bool>(autoScroll);
    {
      map['updated_at'] = Variable<DateTime>(
        $AppSettingsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      sendFormat: Value(sendFormat),
      receiveFormat: Value(receiveFormat),
      appendCrlf: Value(appendCrlf),
      autoScroll: Value(autoScroll),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRecord(
      id: serializer.fromJson<int>(json['id']),
      sendFormat: $AppSettingsTable.$convertersendFormat.fromJson(
        serializer.fromJson<String>(json['sendFormat']),
      ),
      receiveFormat: $AppSettingsTable.$converterreceiveFormat.fromJson(
        serializer.fromJson<String>(json['receiveFormat']),
      ),
      appendCrlf: serializer.fromJson<bool>(json['appendCrlf']),
      autoScroll: serializer.fromJson<bool>(json['autoScroll']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sendFormat': serializer.toJson<String>(
        $AppSettingsTable.$convertersendFormat.toJson(sendFormat),
      ),
      'receiveFormat': serializer.toJson<String>(
        $AppSettingsTable.$converterreceiveFormat.toJson(receiveFormat),
      ),
      'appendCrlf': serializer.toJson<bool>(appendCrlf),
      'autoScroll': serializer.toJson<bool>(autoScroll),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRecord copyWith({
    int? id,
    PayloadFormat? sendFormat,
    PayloadFormat? receiveFormat,
    bool? appendCrlf,
    bool? autoScroll,
    DateTime? updatedAt,
  }) => AppSettingRecord(
    id: id ?? this.id,
    sendFormat: sendFormat ?? this.sendFormat,
    receiveFormat: receiveFormat ?? this.receiveFormat,
    appendCrlf: appendCrlf ?? this.appendCrlf,
    autoScroll: autoScroll ?? this.autoScroll,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSettingRecord copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRecord(
      id: data.id.present ? data.id.value : this.id,
      sendFormat: data.sendFormat.present
          ? data.sendFormat.value
          : this.sendFormat,
      receiveFormat: data.receiveFormat.present
          ? data.receiveFormat.value
          : this.receiveFormat,
      appendCrlf: data.appendCrlf.present
          ? data.appendCrlf.value
          : this.appendCrlf,
      autoScroll: data.autoScroll.present
          ? data.autoScroll.value
          : this.autoScroll,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRecord(')
          ..write('id: $id, ')
          ..write('sendFormat: $sendFormat, ')
          ..write('receiveFormat: $receiveFormat, ')
          ..write('appendCrlf: $appendCrlf, ')
          ..write('autoScroll: $autoScroll, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sendFormat,
    receiveFormat,
    appendCrlf,
    autoScroll,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRecord &&
          other.id == this.id &&
          other.sendFormat == this.sendFormat &&
          other.receiveFormat == this.receiveFormat &&
          other.appendCrlf == this.appendCrlf &&
          other.autoScroll == this.autoScroll &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRecord> {
  final Value<int> id;
  final Value<PayloadFormat> sendFormat;
  final Value<PayloadFormat> receiveFormat;
  final Value<bool> appendCrlf;
  final Value<bool> autoScroll;
  final Value<DateTime> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.sendFormat = const Value.absent(),
    this.receiveFormat = const Value.absent(),
    this.appendCrlf = const Value.absent(),
    this.autoScroll = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.sendFormat = const Value.absent(),
    this.receiveFormat = const Value.absent(),
    this.appendCrlf = const Value.absent(),
    this.autoScroll = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<AppSettingRecord> custom({
    Expression<int>? id,
    Expression<String>? sendFormat,
    Expression<String>? receiveFormat,
    Expression<bool>? appendCrlf,
    Expression<bool>? autoScroll,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sendFormat != null) 'send_format': sendFormat,
      if (receiveFormat != null) 'receive_format': receiveFormat,
      if (appendCrlf != null) 'append_crlf': appendCrlf,
      if (autoScroll != null) 'auto_scroll': autoScroll,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<PayloadFormat>? sendFormat,
    Value<PayloadFormat>? receiveFormat,
    Value<bool>? appendCrlf,
    Value<bool>? autoScroll,
    Value<DateTime>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      sendFormat: sendFormat ?? this.sendFormat,
      receiveFormat: receiveFormat ?? this.receiveFormat,
      appendCrlf: appendCrlf ?? this.appendCrlf,
      autoScroll: autoScroll ?? this.autoScroll,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sendFormat.present) {
      map['send_format'] = Variable<String>(
        $AppSettingsTable.$convertersendFormat.toSql(sendFormat.value),
      );
    }
    if (receiveFormat.present) {
      map['receive_format'] = Variable<String>(
        $AppSettingsTable.$converterreceiveFormat.toSql(receiveFormat.value),
      );
    }
    if (appendCrlf.present) {
      map['append_crlf'] = Variable<bool>(appendCrlf.value);
    }
    if (autoScroll.present) {
      map['auto_scroll'] = Variable<bool>(autoScroll.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $AppSettingsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('sendFormat: $sendFormat, ')
          ..write('receiveFormat: $receiveFormat, ')
          ..write('appendCrlf: $appendCrlf, ')
          ..write('autoScroll: $autoScroll, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppearanceSettingsTable extends AppearanceSettings
    with TableInfo<$AppearanceSettingsTable, AppearanceSettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppearanceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _themePresetMeta = const VerificationMeta(
    'themePreset',
  );
  @override
  late final GeneratedColumn<String> themePreset = GeneratedColumn<String>(
    'theme_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('indigo'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppearanceSettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, themeMode, themePreset, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appearance_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppearanceSettingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('theme_preset')) {
      context.handle(
        _themePresetMeta,
        themePreset.isAcceptableOrUnknown(
          data['theme_preset']!,
          _themePresetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppearanceSettingRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppearanceSettingRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      themePreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_preset'],
      )!,
      updatedAt: $AppearanceSettingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AppearanceSettingsTable createAlias(String alias) {
    return $AppearanceSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class AppearanceSettingRecord extends DataClass
    implements Insertable<AppearanceSettingRecord> {
  final int id;
  final String themeMode;
  final String themePreset;
  final DateTime updatedAt;
  const AppearanceSettingRecord({
    required this.id,
    required this.themeMode,
    required this.themePreset,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['theme_preset'] = Variable<String>(themePreset);
    {
      map['updated_at'] = Variable<DateTime>(
        $AppearanceSettingsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AppearanceSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppearanceSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      themePreset: Value(themePreset),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppearanceSettingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppearanceSettingRecord(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      themePreset: serializer.fromJson<String>(json['themePreset']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'themePreset': serializer.toJson<String>(themePreset),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppearanceSettingRecord copyWith({
    int? id,
    String? themeMode,
    String? themePreset,
    DateTime? updatedAt,
  }) => AppearanceSettingRecord(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    themePreset: themePreset ?? this.themePreset,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppearanceSettingRecord copyWithCompanion(AppearanceSettingsCompanion data) {
    return AppearanceSettingRecord(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      themePreset: data.themePreset.present
          ? data.themePreset.value
          : this.themePreset,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppearanceSettingRecord(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('themePreset: $themePreset, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, themeMode, themePreset, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppearanceSettingRecord &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.themePreset == this.themePreset &&
          other.updatedAt == this.updatedAt);
}

class AppearanceSettingsCompanion
    extends UpdateCompanion<AppearanceSettingRecord> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<String> themePreset;
  final Value<DateTime> updatedAt;
  const AppearanceSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.themePreset = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppearanceSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.themePreset = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<AppearanceSettingRecord> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<String>? themePreset,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (themePreset != null) 'theme_preset': themePreset,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppearanceSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<String>? themePreset,
    Value<DateTime>? updatedAt,
  }) {
    return AppearanceSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (themePreset.present) {
      map['theme_preset'] = Variable<String>(themePreset.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $AppearanceSettingsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppearanceSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('themePreset: $themePreset, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LogSessionsTable extends LogSessions
    with TableInfo<$LogSessionsTable, LogSessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConnectionMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ConnectionMode>($LogSessionsTable.$convertermode);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> startedAt =
      GeneratedColumn<DateTime>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LogSessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, DateTime> endedAt =
      GeneratedColumn<DateTime>(
        'ended_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($LogSessionsTable.$converterendedAtn);
  @override
  List<GeneratedColumn> get $columns => [id, mode, startedAt, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogSessionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogSessionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogSessionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: $LogSessionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      startedAt: $LogSessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      endedAt: $LogSessionsTable.$converterendedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}ended_at'],
        ),
      ),
    );
  }

  @override
  $LogSessionsTable createAlias(String alias) {
    return $LogSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConnectionMode, String, String> $convertermode =
      const EnumNameConverter<ConnectionMode>(ConnectionMode.values);
  static TypeConverter<DateTime, DateTime> $converterstartedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterendedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, DateTime?> $converterendedAtn =
      NullAwareTypeConverter.wrap($converterendedAt);
}

class LogSessionRecord extends DataClass
    implements Insertable<LogSessionRecord> {
  final int id;
  final ConnectionMode mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  const LogSessionRecord({
    required this.id,
    required this.mode,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['mode'] = Variable<String>(
        $LogSessionsTable.$convertermode.toSql(mode),
      );
    }
    {
      map['started_at'] = Variable<DateTime>(
        $LogSessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(
        $LogSessionsTable.$converterendedAtn.toSql(endedAt),
      );
    }
    return map;
  }

  LogSessionsCompanion toCompanion(bool nullToAbsent) {
    return LogSessionsCompanion(
      id: Value(id),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory LogSessionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogSessionRecord(
      id: serializer.fromJson<int>(json['id']),
      mode: $LogSessionsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>(
        $LogSessionsTable.$convertermode.toJson(mode),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  LogSessionRecord copyWith({
    int? id,
    ConnectionMode? mode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => LogSessionRecord(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  LogSessionRecord copyWithCompanion(LogSessionsCompanion data) {
    return LogSessionRecord(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogSessionRecord(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mode, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogSessionRecord &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class LogSessionsCompanion extends UpdateCompanion<LogSessionRecord> {
  final Value<int> id;
  final Value<ConnectionMode> mode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  const LogSessionsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  LogSessionsCompanion.insert({
    this.id = const Value.absent(),
    required ConnectionMode mode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
  }) : mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<LogSessionRecord> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  LogSessionsCompanion copyWith({
    Value<int>? id,
    Value<ConnectionMode>? mode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
  }) {
    return LogSessionsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $LogSessionsTable.$convertermode.toSql(mode.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(
        $LogSessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(
        $LogSessionsTable.$converterendedAtn.toSql(endedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogSessionsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES log_sessions (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> timestamp =
      GeneratedColumn<DateTime>(
        'timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LogEntriesTable.$convertertimestamp);
  @override
  late final GeneratedColumnWithTypeConverter<LogDirection, String> direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LogDirection>($LogEntriesTable.$converterdirection);
  @override
  late final GeneratedColumnWithTypeConverter<PayloadFormat, String> format =
      GeneratedColumn<String>(
        'format',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PayloadFormat>($LogEntriesTable.$converterformat);
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    timestamp,
    direction,
    format,
    channel,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      timestamp: $LogEntriesTable.$convertertimestamp.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}timestamp'],
        )!,
      ),
      direction: $LogEntriesTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      format: $LogEntriesTable.$converterformat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}format'],
        )!,
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertertimestamp =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<LogDirection, String, String> $converterdirection =
      const EnumNameConverter<LogDirection>(LogDirection.values);
  static JsonTypeConverter2<PayloadFormat, String, String> $converterformat =
      const EnumNameConverter<PayloadFormat>(PayloadFormat.values);
}

class LogEntryRow extends DataClass implements Insertable<LogEntryRow> {
  final int id;
  final int sessionId;
  final DateTime timestamp;
  final LogDirection direction;
  final PayloadFormat format;
  final String channel;
  final Uint8List payload;
  const LogEntryRow({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.direction,
    required this.format,
    required this.channel,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    {
      map['timestamp'] = Variable<DateTime>(
        $LogEntriesTable.$convertertimestamp.toSql(timestamp),
      );
    }
    {
      map['direction'] = Variable<String>(
        $LogEntriesTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['format'] = Variable<String>(
        $LogEntriesTable.$converterformat.toSql(format),
      );
    }
    map['channel'] = Variable<String>(channel);
    map['payload'] = Variable<Uint8List>(payload);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      timestamp: Value(timestamp),
      direction: Value(direction),
      format: Value(format),
      channel: Value(channel),
      payload: Value(payload),
    );
  }

  factory LogEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntryRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      direction: $LogEntriesTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      format: $LogEntriesTable.$converterformat.fromJson(
        serializer.fromJson<String>(json['format']),
      ),
      channel: serializer.fromJson<String>(json['channel']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'direction': serializer.toJson<String>(
        $LogEntriesTable.$converterdirection.toJson(direction),
      ),
      'format': serializer.toJson<String>(
        $LogEntriesTable.$converterformat.toJson(format),
      ),
      'channel': serializer.toJson<String>(channel),
      'payload': serializer.toJson<Uint8List>(payload),
    };
  }

  LogEntryRow copyWith({
    int? id,
    int? sessionId,
    DateTime? timestamp,
    LogDirection? direction,
    PayloadFormat? format,
    String? channel,
    Uint8List? payload,
  }) => LogEntryRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    timestamp: timestamp ?? this.timestamp,
    direction: direction ?? this.direction,
    format: format ?? this.format,
    channel: channel ?? this.channel,
    payload: payload ?? this.payload,
  );
  LogEntryRow copyWithCompanion(LogEntriesCompanion data) {
    return LogEntryRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      direction: data.direction.present ? data.direction.value : this.direction,
      format: data.format.present ? data.format.value : this.format,
      channel: data.channel.present ? data.channel.value : this.channel,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntryRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('direction: $direction, ')
          ..write('format: $format, ')
          ..write('channel: $channel, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    timestamp,
    direction,
    format,
    channel,
    $driftBlobEquality.hash(payload),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntryRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.timestamp == this.timestamp &&
          other.direction == this.direction &&
          other.format == this.format &&
          other.channel == this.channel &&
          $driftBlobEquality.equals(other.payload, this.payload));
}

class LogEntriesCompanion extends UpdateCompanion<LogEntryRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<DateTime> timestamp;
  final Value<LogDirection> direction;
  final Value<PayloadFormat> format;
  final Value<String> channel;
  final Value<Uint8List> payload;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.direction = const Value.absent(),
    this.format = const Value.absent(),
    this.channel = const Value.absent(),
    this.payload = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required DateTime timestamp,
    required LogDirection direction,
    required PayloadFormat format,
    required String channel,
    required Uint8List payload,
  }) : sessionId = Value(sessionId),
       timestamp = Value(timestamp),
       direction = Value(direction),
       format = Value(format),
       channel = Value(channel),
       payload = Value(payload);
  static Insertable<LogEntryRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<DateTime>? timestamp,
    Expression<String>? direction,
    Expression<String>? format,
    Expression<String>? channel,
    Expression<Uint8List>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (timestamp != null) 'timestamp': timestamp,
      if (direction != null) 'direction': direction,
      if (format != null) 'format': format,
      if (channel != null) 'channel': channel,
      if (payload != null) 'payload': payload,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<DateTime>? timestamp,
    Value<LogDirection>? direction,
    Value<PayloadFormat>? format,
    Value<String>? channel,
    Value<Uint8List>? payload,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      direction: direction ?? this.direction,
      format: format ?? this.format,
      channel: channel ?? this.channel,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(
        $LogEntriesTable.$convertertimestamp.toSql(timestamp.value),
      );
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $LogEntriesTable.$converterdirection.toSql(direction.value),
      );
    }
    if (format.present) {
      map['format'] = Variable<String>(
        $LogEntriesTable.$converterformat.toSql(format.value),
      );
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('direction: $direction, ')
          ..write('format: $format, ')
          ..write('channel: $channel, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConnectionProfilesTable connectionProfiles =
      $ConnectionProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AppearanceSettingsTable appearanceSettings =
      $AppearanceSettingsTable(this);
  late final $LogSessionsTable logSessions = $LogSessionsTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    connectionProfiles,
    appSettings,
    appearanceSettings,
    logSessions,
    logEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'log_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('log_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConnectionProfilesTableCreateCompanionBuilder =
    ConnectionProfilesCompanion Function({
      Value<int> id,
      required ConnectionMode mode,
      Value<String?> host,
      Value<int?> port,
      Value<String?> bindAddress,
      Value<String?> bleRemoteId,
      Value<String?> serviceUuid,
      Value<String?> writeCharacteristicUuid,
      Value<String?> notifyCharacteristicUuid,
      Value<String?> usbDeviceKey,
      Value<int?> baudRate,
      Value<int?> dataBits,
      Value<String?> stopBits,
      Value<String?> parity,
      required DateTime updatedAt,
    });
typedef $$ConnectionProfilesTableUpdateCompanionBuilder =
    ConnectionProfilesCompanion Function({
      Value<int> id,
      Value<ConnectionMode> mode,
      Value<String?> host,
      Value<int?> port,
      Value<String?> bindAddress,
      Value<String?> bleRemoteId,
      Value<String?> serviceUuid,
      Value<String?> writeCharacteristicUuid,
      Value<String?> notifyCharacteristicUuid,
      Value<String?> usbDeviceKey,
      Value<int?> baudRate,
      Value<int?> dataBits,
      Value<String?> stopBits,
      Value<String?> parity,
      Value<DateTime> updatedAt,
    });

class $$ConnectionProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConnectionMode, ConnectionMode, String>
  get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bindAddress => $composableBuilder(
    column: $table.bindAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bleRemoteId => $composableBuilder(
    column: $table.bleRemoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceUuid => $composableBuilder(
    column: $table.serviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writeCharacteristicUuid => $composableBuilder(
    column: $table.writeCharacteristicUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notifyCharacteristicUuid => $composableBuilder(
    column: $table.notifyCharacteristicUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usbDeviceKey => $composableBuilder(
    column: $table.usbDeviceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baudRate => $composableBuilder(
    column: $table.baudRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataBits => $composableBuilder(
    column: $table.dataBits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stopBits => $composableBuilder(
    column: $table.stopBits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parity => $composableBuilder(
    column: $table.parity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ConnectionProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bindAddress => $composableBuilder(
    column: $table.bindAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleRemoteId => $composableBuilder(
    column: $table.bleRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceUuid => $composableBuilder(
    column: $table.serviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writeCharacteristicUuid => $composableBuilder(
    column: $table.writeCharacteristicUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notifyCharacteristicUuid => $composableBuilder(
    column: $table.notifyCharacteristicUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usbDeviceKey => $composableBuilder(
    column: $table.usbDeviceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baudRate => $composableBuilder(
    column: $table.baudRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataBits => $composableBuilder(
    column: $table.dataBits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stopBits => $composableBuilder(
    column: $table.stopBits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parity => $composableBuilder(
    column: $table.parity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionProfilesTable> {
  $$ConnectionProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConnectionMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get bindAddress => $composableBuilder(
    column: $table.bindAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bleRemoteId => $composableBuilder(
    column: $table.bleRemoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceUuid => $composableBuilder(
    column: $table.serviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get writeCharacteristicUuid => $composableBuilder(
    column: $table.writeCharacteristicUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notifyCharacteristicUuid => $composableBuilder(
    column: $table.notifyCharacteristicUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usbDeviceKey => $composableBuilder(
    column: $table.usbDeviceKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baudRate =>
      $composableBuilder(column: $table.baudRate, builder: (column) => column);

  GeneratedColumn<int> get dataBits =>
      $composableBuilder(column: $table.dataBits, builder: (column) => column);

  GeneratedColumn<String> get stopBits =>
      $composableBuilder(column: $table.stopBits, builder: (column) => column);

  GeneratedColumn<String> get parity =>
      $composableBuilder(column: $table.parity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConnectionProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionProfilesTable,
          ConnectionProfileRecord,
          $$ConnectionProfilesTableFilterComposer,
          $$ConnectionProfilesTableOrderingComposer,
          $$ConnectionProfilesTableAnnotationComposer,
          $$ConnectionProfilesTableCreateCompanionBuilder,
          $$ConnectionProfilesTableUpdateCompanionBuilder,
          (
            ConnectionProfileRecord,
            BaseReferences<
              _$AppDatabase,
              $ConnectionProfilesTable,
              ConnectionProfileRecord
            >,
          ),
          ConnectionProfileRecord,
          PrefetchHooks Function()
        > {
  $$ConnectionProfilesTableTableManager(
    _$AppDatabase db,
    $ConnectionProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<ConnectionMode> mode = const Value.absent(),
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> bindAddress = const Value.absent(),
                Value<String?> bleRemoteId = const Value.absent(),
                Value<String?> serviceUuid = const Value.absent(),
                Value<String?> writeCharacteristicUuid = const Value.absent(),
                Value<String?> notifyCharacteristicUuid = const Value.absent(),
                Value<String?> usbDeviceKey = const Value.absent(),
                Value<int?> baudRate = const Value.absent(),
                Value<int?> dataBits = const Value.absent(),
                Value<String?> stopBits = const Value.absent(),
                Value<String?> parity = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConnectionProfilesCompanion(
                id: id,
                mode: mode,
                host: host,
                port: port,
                bindAddress: bindAddress,
                bleRemoteId: bleRemoteId,
                serviceUuid: serviceUuid,
                writeCharacteristicUuid: writeCharacteristicUuid,
                notifyCharacteristicUuid: notifyCharacteristicUuid,
                usbDeviceKey: usbDeviceKey,
                baudRate: baudRate,
                dataBits: dataBits,
                stopBits: stopBits,
                parity: parity,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required ConnectionMode mode,
                Value<String?> host = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String?> bindAddress = const Value.absent(),
                Value<String?> bleRemoteId = const Value.absent(),
                Value<String?> serviceUuid = const Value.absent(),
                Value<String?> writeCharacteristicUuid = const Value.absent(),
                Value<String?> notifyCharacteristicUuid = const Value.absent(),
                Value<String?> usbDeviceKey = const Value.absent(),
                Value<int?> baudRate = const Value.absent(),
                Value<int?> dataBits = const Value.absent(),
                Value<String?> stopBits = const Value.absent(),
                Value<String?> parity = const Value.absent(),
                required DateTime updatedAt,
              }) => ConnectionProfilesCompanion.insert(
                id: id,
                mode: mode,
                host: host,
                port: port,
                bindAddress: bindAddress,
                bleRemoteId: bleRemoteId,
                serviceUuid: serviceUuid,
                writeCharacteristicUuid: writeCharacteristicUuid,
                notifyCharacteristicUuid: notifyCharacteristicUuid,
                usbDeviceKey: usbDeviceKey,
                baudRate: baudRate,
                dataBits: dataBits,
                stopBits: stopBits,
                parity: parity,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ConnectionProfilesTable,
                    ConnectionProfileRecord
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ConnectionProfilesTable,
                    ConnectionProfileRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConnectionProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionProfilesTable,
      ConnectionProfileRecord,
      $$ConnectionProfilesTableFilterComposer,
      $$ConnectionProfilesTableOrderingComposer,
      $$ConnectionProfilesTableAnnotationComposer,
      $$ConnectionProfilesTableCreateCompanionBuilder,
      $$ConnectionProfilesTableUpdateCompanionBuilder,
      (
        ConnectionProfileRecord,
        BaseReferences<
          _$AppDatabase,
          $ConnectionProfilesTable,
          ConnectionProfileRecord
        >,
      ),
      ConnectionProfileRecord,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<PayloadFormat> sendFormat,
      Value<PayloadFormat> receiveFormat,
      Value<bool> appendCrlf,
      Value<bool> autoScroll,
      required DateTime updatedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<PayloadFormat> sendFormat,
      Value<PayloadFormat> receiveFormat,
      Value<bool> appendCrlf,
      Value<bool> autoScroll,
      Value<DateTime> updatedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PayloadFormat, PayloadFormat, String>
  get sendFormat => $composableBuilder(
    column: $table.sendFormat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PayloadFormat, PayloadFormat, String>
  get receiveFormat => $composableBuilder(
    column: $table.receiveFormat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get appendCrlf => $composableBuilder(
    column: $table.appendCrlf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoScroll => $composableBuilder(
    column: $table.autoScroll,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendFormat => $composableBuilder(
    column: $table.sendFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiveFormat => $composableBuilder(
    column: $table.receiveFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appendCrlf => $composableBuilder(
    column: $table.appendCrlf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoScroll => $composableBuilder(
    column: $table.autoScroll,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PayloadFormat, String> get sendFormat =>
      $composableBuilder(
        column: $table.sendFormat,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PayloadFormat, String> get receiveFormat =>
      $composableBuilder(
        column: $table.receiveFormat,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get appendCrlf => $composableBuilder(
    column: $table.appendCrlf,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoScroll => $composableBuilder(
    column: $table.autoScroll,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRecord,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRecord,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRecord>,
          ),
          AppSettingRecord,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<PayloadFormat> sendFormat = const Value.absent(),
                Value<PayloadFormat> receiveFormat = const Value.absent(),
                Value<bool> appendCrlf = const Value.absent(),
                Value<bool> autoScroll = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                sendFormat: sendFormat,
                receiveFormat: receiveFormat,
                appendCrlf: appendCrlf,
                autoScroll: autoScroll,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<PayloadFormat> sendFormat = const Value.absent(),
                Value<PayloadFormat> receiveFormat = const Value.absent(),
                Value<bool> appendCrlf = const Value.absent(),
                Value<bool> autoScroll = const Value.absent(),
                required DateTime updatedAt,
              }) => AppSettingsCompanion.insert(
                id: id,
                sendFormat: sendFormat,
                receiveFormat: receiveFormat,
                appendCrlf: appendCrlf,
                autoScroll: autoScroll,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRecord,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRecord,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRecord>,
      ),
      AppSettingRecord,
      PrefetchHooks Function()
    >;
typedef $$AppearanceSettingsTableCreateCompanionBuilder =
    AppearanceSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> themePreset,
      required DateTime updatedAt,
    });
typedef $$AppearanceSettingsTableUpdateCompanionBuilder =
    AppearanceSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> themePreset,
      Value<DateTime> updatedAt,
    });

class $$AppearanceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppearanceSettingsTable> {
  $$AppearanceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themePreset => $composableBuilder(
    column: $table.themePreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AppearanceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppearanceSettingsTable> {
  $$AppearanceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themePreset => $composableBuilder(
    column: $table.themePreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppearanceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppearanceSettingsTable> {
  $$AppearanceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get themePreset => $composableBuilder(
    column: $table.themePreset,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppearanceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppearanceSettingsTable,
          AppearanceSettingRecord,
          $$AppearanceSettingsTableFilterComposer,
          $$AppearanceSettingsTableOrderingComposer,
          $$AppearanceSettingsTableAnnotationComposer,
          $$AppearanceSettingsTableCreateCompanionBuilder,
          $$AppearanceSettingsTableUpdateCompanionBuilder,
          (
            AppearanceSettingRecord,
            BaseReferences<
              _$AppDatabase,
              $AppearanceSettingsTable,
              AppearanceSettingRecord
            >,
          ),
          AppearanceSettingRecord,
          PrefetchHooks Function()
        > {
  $$AppearanceSettingsTableTableManager(
    _$AppDatabase db,
    $AppearanceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppearanceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppearanceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppearanceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> themePreset = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppearanceSettingsCompanion(
                id: id,
                themeMode: themeMode,
                themePreset: themePreset,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> themePreset = const Value.absent(),
                required DateTime updatedAt,
              }) => AppearanceSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                themePreset: themePreset,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AppearanceSettingsTable,
                    AppearanceSettingRecord
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppearanceSettingsTable,
                    AppearanceSettingRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppearanceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppearanceSettingsTable,
      AppearanceSettingRecord,
      $$AppearanceSettingsTableFilterComposer,
      $$AppearanceSettingsTableOrderingComposer,
      $$AppearanceSettingsTableAnnotationComposer,
      $$AppearanceSettingsTableCreateCompanionBuilder,
      $$AppearanceSettingsTableUpdateCompanionBuilder,
      (
        AppearanceSettingRecord,
        BaseReferences<
          _$AppDatabase,
          $AppearanceSettingsTable,
          AppearanceSettingRecord
        >,
      ),
      AppearanceSettingRecord,
      PrefetchHooks Function()
    >;
typedef $$LogSessionsTableCreateCompanionBuilder =
    LogSessionsCompanion Function({
      Value<int> id,
      required ConnectionMode mode,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
    });
typedef $$LogSessionsTableUpdateCompanionBuilder =
    LogSessionsCompanion Function({
      Value<int> id,
      Value<ConnectionMode> mode,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
    });

final class $$LogSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $LogSessionsTable, LogSessionRecord> {
  $$LogSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LogEntriesTable, List<LogEntryRow>>
  _logEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: 'log_sessions__id__log_entries__session_id',
  );

  $$LogEntriesTableProcessedTableManager get logEntriesRefs {
    final manager = $$LogEntriesTableTableManager(
      $_db,
      $_db.logEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LogSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LogSessionsTable> {
  $$LogSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConnectionMode, ConnectionMode, String>
  get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, DateTime> get endedAt =>
      $composableBuilder(
        column: $table.endedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($$LogEntriesTableFilterComposer f) f,
  ) {
    final $$LogEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LogSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LogSessionsTable> {
  $$LogSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogSessionsTable> {
  $$LogSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConnectionMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($$LogEntriesTableAnnotationComposer a) f,
  ) {
    final $$LogEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LogSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogSessionsTable,
          LogSessionRecord,
          $$LogSessionsTableFilterComposer,
          $$LogSessionsTableOrderingComposer,
          $$LogSessionsTableAnnotationComposer,
          $$LogSessionsTableCreateCompanionBuilder,
          $$LogSessionsTableUpdateCompanionBuilder,
          (LogSessionRecord, $$LogSessionsTableReferences),
          LogSessionRecord,
          PrefetchHooks Function({bool logEntriesRefs})
        > {
  $$LogSessionsTableTableManager(_$AppDatabase db, $LogSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<ConnectionMode> mode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => LogSessionsCompanion(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required ConnectionMode mode,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => LogSessionsCompanion.insert(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogSessionsTable, LogSessionRecord>(table),
                  $$LogSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({logEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (logEntriesRefs) db.logEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (logEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      LogSessionRecord,
                      $LogSessionsTable,
                      LogEntryRow,
                      $LogEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$LogSessionsTableReferences
                          ._logEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LogSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).logEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LogSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogSessionsTable,
      LogSessionRecord,
      $$LogSessionsTableFilterComposer,
      $$LogSessionsTableOrderingComposer,
      $$LogSessionsTableAnnotationComposer,
      $$LogSessionsTableCreateCompanionBuilder,
      $$LogSessionsTableUpdateCompanionBuilder,
      (LogSessionRecord, $$LogSessionsTableReferences),
      LogSessionRecord,
      PrefetchHooks Function({bool logEntriesRefs})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  required int sessionId,
  required DateTime timestamp,
  required LogDirection direction,
  required PayloadFormat format,
  required String channel,
  required Uint8List payload,
});
typedef $$LogEntriesTableUpdateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<DateTime> timestamp,
  Value<LogDirection> direction,
  Value<PayloadFormat> format,
  Value<String> channel,
  Value<Uint8List> payload,
});

final class $$LogEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntryRow> {
  $$LogEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LogSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.logSessions.createAlias('log_entries__session_id__log_sessions__id');

  $$LogSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$LogSessionsTableTableManager(
      $_db,
      $_db.logSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get timestamp =>
      $composableBuilder(
        column: $table.timestamp,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LogDirection, LogDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PayloadFormat, PayloadFormat, String>
  get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$LogSessionsTableFilterComposer get sessionId {
    final $$LogSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.logSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogSessionsTableFilterComposer(
            $db: $db,
            $table: $db.logSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$LogSessionsTableOrderingComposer get sessionId {
    final $$LogSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.logSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.logSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LogDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PayloadFormat, String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$LogSessionsTableAnnotationComposer get sessionId {
    final $$LogSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.logSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.logSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntryRow,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntryRow, $$LogEntriesTableReferences),
          LogEntryRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<LogDirection> direction = const Value.absent(),
                Value<PayloadFormat> format = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                direction: direction,
                format: format,
                channel: channel,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required DateTime timestamp,
                required LogDirection direction,
                required PayloadFormat format,
                required String channel,
                required Uint8List payload,
              }) => LogEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                direction: direction,
                format: format,
                channel: channel,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogEntriesTable, LogEntryRow>(table),
                  $$LogEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$LogEntriesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$LogEntriesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntryRow,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntryRow, $$LogEntriesTableReferences),
      LogEntryRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConnectionProfilesTableTableManager get connectionProfiles =>
      $$ConnectionProfilesTableTableManager(_db, _db.connectionProfiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AppearanceSettingsTableTableManager get appearanceSettings =>
      $$AppearanceSettingsTableTableManager(_db, _db.appearanceSettings);
  $$LogSessionsTableTableManager get logSessions =>
      $$LogSessionsTableTableManager(_db, _db.logSessions);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
}
