import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/ble_device_info.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/connection_state.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/log_session_summary.dart';
import 'package:flutter_serial_dbg/app/models/ping_result.dart';
import 'package:flutter_serial_dbg/app/models/protocol_profile.dart';
import 'package:flutter_serial_dbg/app/models/text_encoding.dart';
import 'package:flutter_serial_dbg/app/models/transport_event.dart';
import 'package:flutter_serial_dbg/app/models/usb_serial_device_info.dart';
import 'package:flutter_serial_dbg/app/pages/home/home_controller.dart';
import 'package:flutter_serial_dbg/app/pages/home/ble_gatt_controller.dart';
import 'package:flutter_serial_dbg/app/pages/home/protocol_controller.dart';
import 'package:flutter_serial_dbg/app/pages/settings/communication_settings_controller.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_permission_service.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_scanner.dart';
import 'package:flutter_serial_dbg/app/services/diagnostics/network_diagnostics.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_exporter.dart';
import 'package:flutter_serial_dbg/app/services/transport/transport.dart';
import 'package:flutter_serial_dbg/app/services/transport/transport_factory.dart';
import 'package:flutter_serial_dbg/app/services/usb/usb_serial_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeTransport transport;
  late FakeTransportFactory factory;
  late FakeAppRepository repository;
  late FakeLogExporter exporter;
  late FakeBleScanner bleScanner;
  late FakeBlePermissionService blePermissionService;
  late FakeUsbSerialService usbSerialService;
  late CommunicationSettingsController settingsController;
  late BleGattController bleGattController;
  late ProtocolController protocolController;
  late HomeController controller;

  setUp(() {
    transport = FakeTransport();
    factory = FakeTransportFactory(transport);
    repository = FakeAppRepository();
    exporter = FakeLogExporter();
    bleScanner = FakeBleScanner();
    blePermissionService = FakeBlePermissionService();
    usbSerialService = FakeUsbSerialService();
    settingsController = CommunicationSettingsController(repository);
    bleGattController = BleGattController();
    protocolController = ProtocolController(repository);
    addTearDown(bleScanner.dispose);
    addTearDown(usbSerialService.dispose);
    controller = HomeController(
      transportFactory: factory,
      diagnostics: const FakeNetworkDiagnostics(),
      repository: repository,
      logExporter: exporter,
      bleScanner: bleScanner,
      blePermissionService: blePermissionService,
      usbSerialService: usbSerialService,
      settingsController: settingsController,
      bleGattController: bleGattController,
      protocolController: protocolController,
      clock: () => DateTime.utc(2026),
    );
  });

  tearDown(() {
    controller.dispose();
    settingsController.dispose();
    bleGattController.dispose();
    protocolController.dispose();
  });

  test('connects, sends encoded text and records sent logs', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
    controller.appendCrlf.value = true;

    expect(controller.connectionState.value.status, TransportStatus.connected);
    expect(await controller.sendInput('OK'), isTrue);
    expect(transport.sent.single, <int>[0x4F, 0x4B, 0x0D, 0x0A]);
    expect(controller.logs.value.single.direction, LogDirection.sent);
  });

  test('sends text with the selected ASCII encoding', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
    controller.setTextEncoding(TextEncoding.ascii);

    expect(await controller.sendInput('OK'), isTrue);
    expect(transport.sent.single, <int>[0x4F, 0x4B]);
  });

  test('records received data with the current receive format', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
    controller.receiveFormat.value = PayloadFormat.hex;

    transport.emitData(<int>[0xDE, 0xAD]);

    final entry = controller.logs.value.single;
    expect(entry.direction, LogDirection.received);
    expect(entry.format, PayloadFormat.hex);
    expect(entry.bytes, <int>[0xDE, 0xAD]);
  });

  test('rejects invalid hex without sending bytes', () async {
    await controller.connect(UdpClientConfig(host: '192.0.2.1', port: 9000));
    controller.payloadFormat.value = PayloadFormat.hex;

    expect(await controller.sendInput('GG'), isFalse);
    expect(transport.sent, isEmpty);
    expect(controller.lastError.value, isNotNull);
    expect(controller.logs.value.single.direction, LogDirection.system);
  });

  test('switching mode closes the active transport first', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));

    await controller.selectMode(ConnectionMode.udpClient);

    expect(transport.disconnectCalls, 1);
    expect(controller.selectedMode.value, ConnectionMode.udpClient);
    expect(
      controller.connectionState.value.status,
      TransportStatus.disconnected,
    );
  });

  test('loads and persists preferences and connection profiles', () async {
    repository.preferences = const AppPreferences(
      sendFormat: PayloadFormat.hex,
      appendCrlf: true,
    );
    repository.configs[ConnectionMode.tcpClient] = TcpClientConfig(
      host: '198.51.100.8',
      port: 7000,
    );

    await controller.initialize();

    expect(controller.payloadFormat.value, PayloadFormat.hex);
    expect(controller.appendCrlf.value, isTrue);
    expect(
      await controller.loadSavedConfig(ConnectionMode.tcpClient),
      isA<TcpClientConfig>().having(
        (config) => config.host,
        'host',
        '198.51.100.8',
      ),
    );

    controller.setReceiveFormat(PayloadFormat.hex);
    controller.setAutoScroll(false);
    await Future<void>.delayed(Duration.zero);
    expect(repository.preferences.receiveFormat, PayloadFormat.hex);
    expect(repository.preferences.autoScroll, isFalse);
  });

  test('defaults send format to text and restores the latest switch', () async {
    expect(controller.payloadFormat.value, PayloadFormat.text);
    await controller.initialize();
    expect(controller.payloadFormat.value, PayloadFormat.text);

    controller.setPayloadFormat(PayloadFormat.hex);
    controller.setPayloadFormat(PayloadFormat.text);
    controller.setPayloadFormat(PayloadFormat.hex);
    await Future<void>.delayed(Duration.zero);
    expect(repository.preferences.sendFormat, PayloadFormat.hex);

    final restored = HomeController(
      transportFactory: factory,
      diagnostics: const FakeNetworkDiagnostics(),
      repository: repository,
      logExporter: exporter,
      bleScanner: bleScanner,
      blePermissionService: blePermissionService,
      usbSerialService: usbSerialService,
      settingsController: settingsController,
      bleGattController: bleGattController,
      protocolController: protocolController,
      clock: () => DateTime.utc(2026),
    );
    addTearDown(restored.dispose);

    await restored.initialize();

    expect(restored.payloadFormat.value, PayloadFormat.hex);
  });

  test('persists session logs when the connection closes', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
    await Future<void>.delayed(Duration.zero);
    transport.emitData(<int>[0xAA, 0x55]);

    await controller.disconnect();

    expect(repository.sessions.values.single.single.bytes, <int>[0xAA, 0x55]);
  });

  test(
    'skips database session creation when persistence is disabled',
    () async {
      await settingsController.setPersistSessionLogs(false);
      await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
      transport.emitData(<int>[0x01]);

      await controller.disconnect();

      expect(repository.sessions, isEmpty);
      expect(controller.logs.value, isNotEmpty);
    },
  );

  test('uses the configured retention count when a session ends', () async {
    await settingsController.setLogRetentionSessions(10);
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));

    await controller.disconnect();

    expect(repository.lastTrimKeep, 10);
  });

  test('feeds received bytes into the selected protocol profile', () async {
    protocolController.selectProfile(
      ProtocolProfile(name: '测试协议', header: const <int>[0xAA, 0x55]),
    );
    final frame = protocolController.encode(
      command: 0x42,
      payload: Uint8List.fromList(<int>[0x10, 0x20]),
    )!;
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));

    transport.emitData(frame);

    expect(protocolController.observations.value, hasLength(1));

    await controller.disconnect();

    expect(protocolController.observations.value, hasLength(1));
  });

  test('exports current memory logs with the selected format', () async {
    await controller.connect(TcpClientConfig(host: '192.0.2.1', port: 8080));
    transport.emitData(<int>[0xAA, 0x55]);
    controller.setReceiveFormat(PayloadFormat.hex);

    final outcome = await controller.exportLogs();

    expect(outcome, LogExportOutcome.saved);
    expect(exporter.exportedEntries, hasLength(1));
    expect(exporter.exportedFormat, PayloadFormat.hex);
  });

  test('scans BLE devices after permission and adapter checks', () async {
    await controller.startBleScan();

    expect(blePermissionService.requestCalls, 1);
    expect(bleScanner.startCalls, 1);
    expect(controller.isBleScanning.value, isTrue);

    bleScanner.emitDevices(<BleDeviceInfo>[
      BleDeviceInfo(remoteId: 'AA:BB:CC:DD:EE:FF', name: 'Demo', rssi: -42),
    ]);
    expect(controller.bleDevices.value.single.displayName, 'Demo');

    await controller.stopBleScan();
    expect(bleScanner.stopCalls, 1);
    expect(controller.isBleScanning.value, isFalse);
  });

  test('reports denied BLE permission without starting scan', () async {
    blePermissionService.outcome = BlePermissionOutcome.denied;

    await controller.startBleScan();

    expect(bleScanner.startCalls, 0);
    expect(controller.lastError.value, contains('BLE 权限被拒绝'));
  });

  test('refreshes USB devices and keeps a valid selection', () async {
    final first = UsbSerialDeviceInfo(
      deviceId: '/dev/bus/usb/001/007',
      deviceName: '/dev/bus/usb/001/007',
      vendorId: 0x1A86,
      productId: 0x7523,
      productName: 'CH340',
    );
    final second = UsbSerialDeviceInfo(
      deviceId: '/dev/bus/usb/001/003',
      deviceName: '/dev/bus/usb/001/003',
      vendorId: 0x10C4,
      productId: 0xEA60,
      productName: 'CP210x',
    );
    usbSerialService.devices = <UsbSerialDeviceInfo>[first, second];

    await controller.refreshUsbDevices();

    expect(
      controller.usbDevices.value.map((device) => device.displayName),
      <String>['CH340', 'CP210x'],
    );
    controller.selectUsbDevice(first);

    await controller.refreshUsbDevices();

    expect(controller.selectedUsbDevice.value?.deviceId, first.deviceId);
    expect(controller.isUsbRefreshing.value, isFalse);
  });

  test('reports a USB enumeration failure without stale devices', () async {
    usbSerialService.listError = const UsbSerialException('读取 USB 设备列表失败');

    await controller.refreshUsbDevices();

    expect(controller.lastError.value, '读取 USB 设备失败');
    expect(controller.usbDevices.value, isEmpty);
  });

  test('clears a selected USB device when its detach event arrives', () async {
    final device = UsbSerialDeviceInfo(
      deviceId: '/dev/bus/usb/001/009',
      deviceName: '/dev/bus/usb/001/009',
    );
    controller.selectUsbDevice(device);
    await controller.refreshUsbDevices();

    usbSerialService.emit(
      UsbSerialDeviceEvent(
        type: UsbSerialDeviceEventType.detached,
        device: device,
      ),
    );

    expect(controller.selectedUsbDevice.value, isNull);
  });
}

final class FakeTransportFactory implements TransportFactory {
  FakeTransportFactory(this.transport);

  final FakeTransport transport;

  @override
  Transport create(ConnectionMode mode) => transport;
}

final class FakeTransport with TransportEventEmitter implements Transport {
  final List<List<int>> sent = <List<int>>[];
  ConnectionConfig? _config;
  bool _connected = false;
  bool _disposed = false;
  int disconnectCalls = 0;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(ConnectionConfig config) async {
    _config = config;
    _connected = true;
    emitEvent(TransportConnected('${config.mode.name}:test'));
  }

  @override
  Future<void> send(Uint8List data) async {
    if (!_connected) {
      throw const TransportException(TransportErrorKind.invalidState, '尚未连接');
    }
    sent.add(Uint8List.fromList(data));
  }

  void emitData(List<int> bytes) {
    emitEvent(TransportDataReceived(bytes: Uint8List.fromList(bytes)));
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _connected = false;
    _config = null;
    if (!_disposed) {
      emitEvent(const TransportDisconnected());
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    if (_connected) {
      await disconnect();
    }
    _disposed = true;
    await closeEventStream();
  }
}

final class FakeAppRepository implements AppRepository {
  AppPreferences preferences = const AppPreferences();
  final Map<ConnectionMode, ConnectionConfig> configs =
      <ConnectionMode, ConnectionConfig>{};
  final Map<int, List<LogEntry>> sessions = <int, List<LogEntry>>{};
  final List<ProtocolProfile> protocolProfiles = <ProtocolProfile>[];
  int? lastTrimKeep;
  int _nextSessionId = 1;

  @override
  Future<void> appendLogEntries(
    int sessionId,
    Iterable<LogEntry> entries,
  ) async {
    sessions.putIfAbsent(sessionId, () => <LogEntry>[]).addAll(entries);
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> endLogSession(int sessionId, DateTime endedAt) async {}

  @override
  Future<ConnectionConfig?> loadConnectionConfig(ConnectionMode mode) async {
    return configs[mode];
  }

  @override
  Future<AppPreferences> loadPreferences() async => preferences;

  @override
  Future<AppearancePreferences> loadAppearancePreferences() async {
    return const AppearancePreferences();
  }

  @override
  Future<List<LogEntry>> loadSessionEntries(int sessionId) async {
    return List<LogEntry>.of(sessions[sessionId] ?? const <LogEntry>[]);
  }

  @override
  Future<List<LogSessionSummary>> loadLogSessionSummaries({
    ConnectionMode? mode,
    int limit = 50,
    int offset = 0,
  }) async {
    return const <LogSessionSummary>[];
  }

  @override
  Future<void> deleteLogSession(int sessionId) async {
    sessions.remove(sessionId);
  }

  @override
  Future<void> deleteAllLogSessions() async {
    sessions.clear();
  }

  @override
  Future<List<ProtocolProfile>> loadProtocolProfiles() async {
    return List<ProtocolProfile>.of(protocolProfiles);
  }

  @override
  Future<ProtocolProfile> saveProtocolProfile(ProtocolProfile profile) async {
    final saved = profile.id == null
        ? profile.withId(protocolProfiles.length + 1)
        : profile;
    protocolProfiles
      ..removeWhere((existing) => existing.id == saved.id)
      ..add(saved);
    return saved;
  }

  @override
  Future<void> deleteProtocolProfile(int profileId) async {
    protocolProfiles.removeWhere((profile) => profile.id == profileId);
  }

  @override
  Future<void> saveConnectionConfig(ConnectionConfig config) async {
    configs[config.mode] = config;
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    this.preferences = preferences;
  }

  @override
  Future<void> saveAppearancePreferences(
    AppearancePreferences preferences,
  ) async {}

  @override
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt) async {
    final id = _nextSessionId++;
    sessions[id] = <LogEntry>[];
    return id;
  }

  @override
  Future<void> trimLogSessions({int keep = 20}) async {
    lastTrimKeep = keep;
  }
}

final class FakeLogExporter implements LogExporter {
  List<LogEntry>? exportedEntries;
  PayloadFormat? exportedFormat;

  @override
  Future<String?> export(
    List<LogEntry> entries, {
    required PayloadFormat format,
  }) async {
    exportedEntries = List<LogEntry>.of(entries);
    exportedFormat = format;
    return '/tmp/serial-debug.log';
  }
}

final class FakeBleScanner implements BleScanner {
  final StreamController<List<BleDeviceInfo>> _results =
      StreamController<List<BleDeviceInfo>>.broadcast(sync: true);
  final StreamController<bool> _scanning = StreamController<bool>.broadcast(
    sync: true,
  );
  bool adapterOn = true;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<bool> get isScanning => _scanning.stream;

  @override
  Stream<List<BleDeviceInfo>> get results => _results.stream;

  @override
  Future<bool> isAdapterOn() async => adapterOn;

  @override
  Future<void> start({Duration timeout = const Duration(seconds: 10)}) async {
    startCalls++;
    _scanning.add(true);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    if (!_scanning.isClosed) {
      _scanning.add(false);
    }
  }

  void emitDevices(List<BleDeviceInfo> devices) {
    _results.add(devices);
  }

  @override
  Future<void> dispose() async {
    await _results.close();
    await _scanning.close();
  }
}

final class FakeBlePermissionService implements BlePermissionService {
  BlePermissionOutcome outcome = BlePermissionOutcome.granted;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<BlePermissionOutcome> request() async {
    requestCalls++;
    return outcome;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}

final class FakeUsbSerialService implements UsbSerialService {
  final StreamController<UsbSerialDeviceEvent> _events =
      StreamController<UsbSerialDeviceEvent>.broadcast(sync: true);
  List<UsbSerialDeviceInfo> devices = <UsbSerialDeviceInfo>[];
  Object? listError;
  bool _disposed = false;

  @override
  Stream<UsbSerialDeviceEvent> get events => _events.stream;

  @override
  Future<List<UsbSerialDeviceInfo>> listDevices() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return List<UsbSerialDeviceInfo>.of(devices);
  }

  @override
  Future<UsbSerialConnection> open(UsbSerialConfig config) async {
    throw const UsbSerialException('测试未配置串口连接');
  }

  void emit(UsbSerialDeviceEvent event) {
    _events.add(event);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _events.close();
  }
}

final class FakeNetworkDiagnostics implements NetworkDiagnostics {
  const FakeNetworkDiagnostics();

  @override
  Future<List<String>> localIpv4Addresses() async => const <String>[
    '192.0.2.10',
  ];

  @override
  Future<PingResult> ping(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return PingResult(
      target: host,
      status: PingStatus.success,
      duration: const Duration(milliseconds: 12),
    );
  }
}
