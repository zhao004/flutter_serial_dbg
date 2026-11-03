import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:signals/signals.dart';

import '../../database/app_repository.dart';
import '../../models/app_preferences.dart';
import '../../models/ble_device_info.dart';
import '../../models/connection_config.dart';
import '../../models/connection_mode.dart';
import '../../models/connection_state.dart';
import '../../models/log_entry.dart';
import '../../models/ping_result.dart';
import '../../models/text_encoding.dart';
import '../../models/transport_event.dart';
import '../../models/usb_serial_device_info.dart';
import '../../services/diagnostics/network_diagnostics.dart';
import '../../services/ble/ble_permission_service.dart';
import '../../services/ble/ble_scanner.dart';
import '../../services/logging/log_buffer.dart';
import '../../services/logging/log_exporter.dart';
import '../../services/logging/log_session_recorder.dart';
import '../../services/protocol/hex_codec.dart';
import '../../services/transport/transport.dart';
import '../../services/transport/transport_factory.dart';
import '../../services/usb/usb_serial_service.dart';

/// 首页通信工作台状态编排器。
///
/// 控制器负责传输生命周期、数据收发、日志和诊断；Widget 只负责输入与展示。
class HomeController {
  factory HomeController({
    required TransportFactory transportFactory,
    required NetworkDiagnostics diagnostics,
    required AppRepository repository,
    required LogExporter logExporter,
    required BleScanner bleScanner,
    required BlePermissionService blePermissionService,
    required UsbSerialService usbSerialService,
    DateTime Function()? clock,
    LogBuffer? logBuffer,
    LogSessionRecorder? logSessionRecorder,
  }) {
    late final HomeController controller;
    final recorder =
        logSessionRecorder ??
        LogSessionRecorder(
          repository: repository,
          onError: (message) => controller._handleStorageError(message),
        );
    controller = HomeController._(
      transportFactory,
      diagnostics,
      repository,
      logExporter,
      bleScanner,
      blePermissionService,
      usbSerialService,
      clock ?? DateTime.now,
      logBuffer ?? LogBuffer(),
      recorder,
    );
    return controller;
  }

  HomeController._(
    this._transportFactory,
    this._diagnostics,
    this._repository,
    this._logExporter,
    this._bleScanner,
    this._blePermissionService,
    this._usbSerialService,
    this._clock,
    this._logBuffer,
    this._logSessionRecorder,
  ) {
    connectionState = signal<ConnectionSnapshot>(
      ConnectionSnapshot.disconnected(changedAt: _clock()),
    );
  }

  final TransportFactory _transportFactory;
  final NetworkDiagnostics _diagnostics;
  final AppRepository _repository;
  final LogExporter _logExporter;
  final BleScanner _bleScanner;
  final BlePermissionService _blePermissionService;
  final UsbSerialService _usbSerialService;
  final DateTime Function() _clock;
  final LogBuffer _logBuffer;
  final LogSessionRecorder _logSessionRecorder;

  Transport? _transport;
  StreamSubscription<TransportEvent>? _transportSubscription;
  StreamSubscription<List<BleDeviceInfo>>? _bleScanResultsSubscription;
  StreamSubscription<bool>? _bleScanStateSubscription;
  StreamSubscription<UsbSerialDeviceEvent>? _usbDeviceEventSubscription;
  ConnectionConfig? _activeConfig;
  int _generation = 0;
  bool _disposed = false;
  bool _usbRefreshQueued = false;
  Future<void>? _initialization;
  Future<void> _preferenceWrite = Future<void>.value();
  AppPreferences _preferences = const AppPreferences();

  /// 当前选择的连接模式。
  final Signal<ConnectionMode> selectedMode = signal(ConnectionMode.usbSerial);

  /// 发送负载格式。
  final Signal<PayloadFormat> payloadFormat = signal(PayloadFormat.text);

  /// 接收日志展示格式。
  final Signal<PayloadFormat> receiveFormat = signal(PayloadFormat.text);

  /// 文本发送和文本日志展示使用的编码。
  final Signal<TextEncoding> textEncoding = signal(TextEncoding.utf8);

  /// 发送时是否追加 CRLF。
  final Signal<bool> appendCrlf = signal(false);

  /// 新日志到达后是否自动滚动到底部。
  final Signal<bool> autoScroll = signal(true);

  /// 是否正在写入发送缓冲。
  final Signal<bool> isSending = signal(false);

  /// 最近一次可展示错误。
  final Signal<String?> lastError = signal<String?>(null);

  /// 当前内存日志快照。
  final Signal<List<LogEntry>> logs = signal(<LogEntry>[]);

  /// 当前 BLE 扫描结果。
  final Signal<List<BleDeviceInfo>> bleDevices = signal(<BleDeviceInfo>[]);

  /// BLE 是否正在扫描。
  final Signal<bool> isBleScanning = signal(false);

  /// 用户当前选中的 BLE 设备。
  final Signal<BleDeviceInfo?> selectedBleDevice = signal<BleDeviceInfo?>(null);

  /// 当前已连接的 USB 设备。
  final Signal<List<UsbSerialDeviceInfo>> usbDevices = signal(
    <UsbSerialDeviceInfo>[],
  );

  /// USB 设备列表是否正在刷新。
  final Signal<bool> isUsbRefreshing = signal(false);

  /// 用户当前选中的 USB 设备。
  final Signal<UsbSerialDeviceInfo?> selectedUsbDevice =
      signal<UsbSerialDeviceInfo?>(null);

  /// 当前连接状态。
  late final Signal<ConnectionSnapshot> connectionState;

  /// 加载持久化设置；重复调用复用同一个初始化过程。
  Future<void> initialize() {
    return _initialization ??= _loadPreferences();
  }

  /// 读取指定模式最近一次成功保存的连接配置。
  Future<ConnectionConfig?> loadSavedConfig(ConnectionMode mode) async {
    try {
      return await _repository.loadConnectionConfig(mode);
    } catch (_) {
      _setError('读取连接配置失败');
      return null;
    }
  }

  /// 申请权限并开始一次 BLE 扫描。
  Future<void> startBleScan() async {
    if (_disposed || isBleScanning.value) {
      return;
    }
    try {
      final permission = await _blePermissionService.request();
      switch (permission) {
        case BlePermissionOutcome.granted:
          break;
        case BlePermissionOutcome.denied:
          _setError('BLE 权限被拒绝，无法扫描设备');
          return;
        case BlePermissionOutcome.permanentlyDenied:
          _setError('BLE 权限被永久拒绝，请在系统设置中启用');
          return;
        case BlePermissionOutcome.unsupported:
          _setError('当前设备或系统不支持 BLE');
          return;
      }
      if (!await _bleScanner.isAdapterOn()) {
        _setError('蓝牙未开启');
        return;
      }

      bleDevices.value = const <BleDeviceInfo>[];
      _bleScanResultsSubscription ??= _bleScanner.results.listen((devices) {
        bleDevices.value = devices;
      });
      _bleScanStateSubscription ??= _bleScanner.isScanning.listen((scanning) {
        isBleScanning.value = scanning;
      });
      await _bleScanner.start();
      isBleScanning.value = true;
    } catch (_) {
      await stopBleScan();
      _setError('BLE 扫描启动失败，请检查权限和蓝牙状态');
    }
  }

  /// 停止 BLE 扫描并释放扫描订阅。
  Future<void> stopBleScan() async {
    try {
      await _bleScanner.stop();
    } catch (_) {
      // 插件可能在适配器关闭时自行停止扫描。
    }
    if (_disposed) {
      return;
    }
    isBleScanning.value = false;
    await _bleScanResultsSubscription?.cancel();
    await _bleScanStateSubscription?.cancel();
    _bleScanResultsSubscription = null;
    _bleScanStateSubscription = null;
  }

  /// 选择扫描结果中的 BLE 设备。
  void selectBleDevice(BleDeviceInfo device) {
    selectedBleDevice.value = device;
  }

  /// 重新枚举 USB 设备，并在并发请求时合并为一次追加刷新。
  Future<void> refreshUsbDevices() async {
    if (_disposed) {
      return;
    }
    if (isUsbRefreshing.value) {
      _usbRefreshQueued = true;
      return;
    }

    _ensureUsbDeviceMonitoring();
    isUsbRefreshing.value = true;
    do {
      _usbRefreshQueued = false;
      try {
        final devices = await _usbSerialService.listDevices();
        if (_disposed) {
          return;
        }
        final sorted = List<UsbSerialDeviceInfo>.of(devices)
          ..sort((left, right) {
            final nameResult = left.displayName.compareTo(right.displayName);
            return nameResult != 0
                ? nameResult
                : left.deviceId.compareTo(right.deviceId);
          });
        usbDevices.value = List<UsbSerialDeviceInfo>.unmodifiable(sorted);

        final selectedId = selectedUsbDevice.value?.deviceId;
        if (selectedId != null) {
          UsbSerialDeviceInfo? current;
          for (final device in sorted) {
            if (device.deviceId == selectedId) {
              current = device;
              break;
            }
          }
          selectedUsbDevice.value = current;
        }
      } catch (_) {
        _usbRefreshQueued = false;
        if (!_disposed) {
          _setError('读取 USB 设备失败');
        }
      }
    } while (_usbRefreshQueued && !_disposed);

    if (!_disposed) {
      isUsbRefreshing.value = false;
    }
  }

  /// 选择 USB 设备。
  void selectUsbDevice(UsbSerialDeviceInfo device) {
    selectedUsbDevice.value = device;
  }

  /// 更新发送格式并异步保存。
  void setPayloadFormat(PayloadFormat format) {
    if (payloadFormat.value == format) {
      return;
    }
    payloadFormat.value = format;
    _preferences = _preferences.copyWith(sendFormat: format);
    _queuePersistPreferences();
  }

  /// 更新接收展示格式并异步保存。
  void setReceiveFormat(PayloadFormat format) {
    if (receiveFormat.value == format) {
      return;
    }
    receiveFormat.value = format;
    _preferences = _preferences.copyWith(receiveFormat: format);
    _queuePersistPreferences();
  }

  /// 更新当前会话使用的文本编码。
  void setTextEncoding(TextEncoding encoding) {
    textEncoding.value = encoding;
  }

  /// 更新 CRLF 选项并异步保存。
  void setAppendCrlf(bool enabled) {
    if (appendCrlf.value == enabled) {
      return;
    }
    appendCrlf.value = enabled;
    _preferences = _preferences.copyWith(appendCrlf: enabled);
    _queuePersistPreferences();
  }

  /// 更新自动滚动选项并异步保存。
  void setAutoScroll(bool enabled) {
    if (autoScroll.value == enabled) {
      return;
    }
    autoScroll.value = enabled;
    _preferences = _preferences.copyWith(autoScroll: enabled);
    _queuePersistPreferences();
  }

  /// 通过系统文件选择器导出当前内存日志。
  Future<LogExportOutcome> exportLogs() async {
    final entries = logs.value;
    if (entries.isEmpty) {
      _setError('暂无可导出的日志');
      return LogExportOutcome.failed;
    }
    try {
      final path = await _logExporter.export(
        entries,
        format: receiveFormat.value,
      );
      return path == null ? LogExportOutcome.cancelled : LogExportOutcome.saved;
    } catch (_) {
      _setError('日志导出失败');
      return LogExportOutcome.failed;
    }
  }

  /// 切换传输模式；已有连接会先关闭。
  Future<void> selectMode(ConnectionMode mode) async {
    if (selectedMode.value == mode) {
      return;
    }
    if (selectedMode.value == ConnectionMode.ble &&
        mode != ConnectionMode.ble) {
      await stopBleScan();
    }
    if (mode != ConnectionMode.usbSerial) {
      await _stopUsbDeviceMonitoring();
    }
    if (_transport != null ||
        connectionState.value.status != TransportStatus.disconnected) {
      await disconnect();
    }
    selectedMode.value = mode;
  }

  /// 建立新连接，调用前会自动关闭已有连接。
  Future<void> connect(ConnectionConfig config) async {
    if (_disposed) {
      throw const TransportException(TransportErrorKind.invalidState, '控制器已释放');
    }
    if (connectionState.value.status.isBusy) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        '连接操作正在进行中',
      );
    }
    if (_transport != null) {
      await disconnect();
    }

    final generation = ++_generation;
    final transport = _transportFactory.create(config.mode);
    _transport = transport;
    _activeConfig = config;
    selectedMode.value = config.mode;
    lastError.value = null;
    connectionState.value = ConnectionSnapshot(
      status: TransportStatus.connecting,
      config: config,
      changedAt: _clock(),
    );
    _transportSubscription = transport.events.listen(
      (event) => _handleTransportEvent(generation, transport, event),
      onError: (Object error, StackTrace stackTrace) {
        _handleTransportFailure(generation, transport, '传输事件流发生异常');
      },
    );

    try {
      await transport.connect(config);
      if (generation != _generation ||
          !identical(_transport, transport) ||
          _disposed) {
        return;
      }
      if (connectionState.value.status == TransportStatus.connecting) {
        connectionState.value = ConnectionSnapshot(
          status: TransportStatus.connected,
          config: config,
          changedAt: _clock(),
          message: _configLabel(config),
        );
      }
      unawaited(_saveConnectionConfig(transport.config ?? config));
    } catch (error) {
      if (generation != _generation) {
        return;
      }
      await _releaseTransport();
      _setFailed(_errorMessage(error), config);
    }
  }

  /// 幂等关闭当前连接。
  Future<void> disconnect() async {
    if (_disposed) {
      return;
    }
    final transport = _transport;
    final config = _activeConfig;
    _generation++;
    if (transport == null) {
      _setDisconnected();
      unawaited(_finishLogSession());
      return;
    }
    if (config != null) {
      connectionState.value = ConnectionSnapshot(
        status: TransportStatus.disconnecting,
        config: config,
        changedAt: _clock(),
      );
    }
    await _releaseTransport();
    if (!_disposed) {
      _setDisconnected();
    }
    await _finishLogSession();
  }

  /// 编码并发送当前输入。
  Future<bool> sendInput(String input) async {
    final Uint8List data;
    try {
      data = PayloadCodec.encode(
        input,
        format: payloadFormat.value,
        textEncoding: textEncoding.value,
        appendCrlf: appendCrlf.value,
      );
    } on PayloadFormatException catch (error) {
      _setError(error.message);
      return false;
    }
    return sendBytes(data, format: payloadFormat.value);
  }

  /// 发送已经编码的字节并写入发送日志。
  Future<bool> sendBytes(Uint8List data, {PayloadFormat? format}) async {
    final transport = _transport;
    if (transport == null ||
        connectionState.value.status != TransportStatus.connected) {
      _setError('请先建立连接');
      return false;
    }
    if (isSending.value) {
      _setError('上一条数据仍在发送');
      return false;
    }

    isSending.value = true;
    try {
      await transport.send(data);
      _appendLog(
        direction: LogDirection.sent,
        bytes: data,
        format: format ?? payloadFormat.value,
        channel: _activeConfig?.mode.name ?? 'transport',
      );
      return true;
    } catch (error) {
      _setError(_errorMessage(error));
      return false;
    } finally {
      isSending.value = false;
    }
  }

  /// 清空当前内存日志。
  void clearLogs() {
    _logBuffer.clear();
    logs.value = const <LogEntry>[];
  }

  /// 关闭最近错误提示。
  void dismissError() {
    lastError.value = null;
  }

  /// 获取当前设备 IPv4 地址。
  Future<List<String>> loadLocalIpv4Addresses() {
    return _diagnostics.localIpv4Addresses();
  }

  /// 对指定地址执行 Android 原生 Ping。
  Future<PingResult> ping(String host) {
    return _diagnostics.ping(host);
  }

  void _handleTransportEvent(
    int generation,
    Transport transport,
    TransportEvent event,
  ) {
    if (_disposed ||
        generation != _generation ||
        !identical(_transport, transport)) {
      return;
    }
    switch (event) {
      case TransportConnected():
        final config = _activeConfig;
        if (config == null) {
          return;
        }
        connectionState.value = ConnectionSnapshot(
          status: TransportStatus.connected,
          config: config,
          changedAt: _clock(),
          message: event.endpoint,
        );
        lastError.value = null;
        unawaited(_startLogSession(generation, config.mode));
      case TransportDataReceived():
        _appendLog(
          direction: LogDirection.received,
          bytes: event.copyBytes(),
          format: receiveFormat.value,
          channel: _activeConfig?.mode.name ?? 'transport',
        );
      case TransportFailure():
        _handleTransportFailure(generation, transport, event.message);
      case TransportDisconnected():
        if (connectionState.value.status != TransportStatus.failed) {
          _setDisconnected();
        }
        unawaited(_releaseTransportFor(generation, transport));
        unawaited(_finishLogSession());
    }
  }

  void _handleTransportFailure(
    int generation,
    Transport transport,
    String message,
  ) {
    if (_disposed ||
        generation != _generation ||
        !identical(_transport, transport)) {
      return;
    }
    _setFailed(message, _activeConfig);
    unawaited(_releaseTransportFor(generation, transport));
    unawaited(_finishLogSession());
  }

  Future<void> _releaseTransportFor(int generation, Transport transport) async {
    if (generation != _generation || !identical(_transport, transport)) {
      return;
    }
    await _releaseTransport();
  }

  Future<void> _releaseTransport() async {
    final subscription = _transportSubscription;
    final transport = _transport;
    _transportSubscription = null;
    _transport = null;
    _activeConfig = null;
    await subscription?.cancel();
    await transport?.dispose();
  }

  void _appendLog({
    required LogDirection direction,
    required Uint8List bytes,
    required PayloadFormat format,
    required String channel,
  }) {
    final entry = LogEntry(
      timestamp: _clock(),
      direction: direction,
      format: format,
      channel: channel,
      bytes: bytes,
    );
    _logBuffer.add(entry);
    _logSessionRecorder.add(entry);
    logs.value = _logBuffer.entries.toList(growable: false);
  }

  void _setFailed(String message, ConnectionConfig? config) {
    lastError.value = message;
    if (config != null) {
      connectionState.value = ConnectionSnapshot(
        status: TransportStatus.failed,
        config: config,
        message: message,
        changedAt: _clock(),
      );
    } else {
      _setDisconnected();
    }
    _appendLog(
      direction: LogDirection.system,
      bytes: Uint8List.fromList(utf8.encode(message)),
      format: PayloadFormat.text,
      channel: 'system',
    );
  }

  void _setError(String message) {
    lastError.value = message;
    _appendLog(
      direction: LogDirection.system,
      bytes: Uint8List.fromList(utf8.encode(message)),
      format: PayloadFormat.text,
      channel: 'system',
    );
  }

  void _setDisconnected() {
    connectionState.value = ConnectionSnapshot.disconnected(
      changedAt: _clock(),
    );
  }

  String _errorMessage(Object error) {
    return switch (error) {
      TransportException() => error.message,
      NetworkDiagnosticsException() => error.message,
      _ => '操作失败，请检查输入和当前连接状态',
    };
  }

  String _configLabel(ConnectionConfig config) {
    return switch (config) {
      TcpClientConfig() => '${config.host}:${config.port}',
      TcpServerConfig() => '${config.bindAddress}:${config.port}',
      UdpClientConfig() => '${config.host}:${config.port}',
      UdpServerConfig() => '${config.bindAddress}:${config.port}',
      BleConfig() => 'BLE 设备',
      UsbSerialConfig() => 'USB ${config.deviceId}',
    };
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _repository.loadPreferences();
      if (_disposed) {
        return;
      }
      _preferences = preferences;
      payloadFormat.value = preferences.sendFormat;
      receiveFormat.value = preferences.receiveFormat;
      appendCrlf.value = preferences.appendCrlf;
      autoScroll.value = preferences.autoScroll;
    } catch (_) {
      _handleStorageError('读取本地设置失败，已使用默认设置');
    }
  }

  void _queuePersistPreferences() {
    final snapshot = _preferences;
    _preferenceWrite = _preferenceWrite.then((_) async {
      try {
        await _repository.savePreferences(snapshot);
      } catch (_) {
        _handleStorageError('保存本地设置失败');
      }
    });
  }

  Future<void> _saveConnectionConfig(ConnectionConfig config) async {
    try {
      await _repository.saveConnectionConfig(config);
    } catch (_) {
      _handleStorageError('保存连接配置失败');
    }
  }

  Future<void> _startLogSession(int generation, ConnectionMode mode) async {
    if (_logSessionRecorder.isActive) {
      return;
    }
    try {
      await _logSessionRecorder.start(mode, _clock());
      if (_disposed ||
          generation != _generation ||
          connectionState.value.status != TransportStatus.connected) {
        await _logSessionRecorder.stop(_clock());
      }
    } catch (_) {
      _handleStorageError('创建日志会话失败');
    }
  }

  Future<void> _finishLogSession() async {
    try {
      await _logSessionRecorder.stop(_clock());
    } catch (_) {
      _handleStorageError('结束日志会话失败');
    }
  }

  void _handleStorageError(String message) {
    if (!_disposed) {
      _setError(message);
    }
  }

  void _handleUsbDeviceEvent(UsbSerialDeviceEvent event) {
    if (_disposed) {
      return;
    }
    if (event.type == UsbSerialDeviceEventType.detached &&
        selectedUsbDevice.value?.deviceId == event.device.deviceId) {
      selectedUsbDevice.value = null;
    }
    unawaited(refreshUsbDevices());
  }

  void _ensureUsbDeviceMonitoring() {
    if (_disposed || _usbDeviceEventSubscription != null) {
      return;
    }
    _usbDeviceEventSubscription = _usbSerialService.events.listen(
      _handleUsbDeviceEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (!_disposed) {
          _setError('USB 设备插拔监听异常');
        }
      },
    );
  }

  Future<void> _stopUsbDeviceMonitoring() async {
    final subscription = _usbDeviceEventSubscription;
    _usbDeviceEventSubscription = null;
    await subscription?.cancel();
    if (!_disposed) {
      isUsbRefreshing.value = false;
      _usbRefreshQueued = false;
    }
  }

  /// 释放传输句柄和响应式信号。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation++;
    final subscription = _transportSubscription;
    final transport = _transport;
    _transportSubscription = null;
    _transport = null;
    _activeConfig = null;
    unawaited(subscription?.cancel());
    unawaited(transport?.dispose());
    unawaited(_bleScanResultsSubscription?.cancel());
    unawaited(_bleScanStateSubscription?.cancel());
    unawaited(_bleScanner.stop());
    unawaited(_stopUsbDeviceMonitoring());
    unawaited(_finishLogSession());
    selectedMode.dispose();
    payloadFormat.dispose();
    receiveFormat.dispose();
    textEncoding.dispose();
    appendCrlf.dispose();
    autoScroll.dispose();
    isSending.dispose();
    lastError.dispose();
    logs.dispose();
    bleDevices.dispose();
    isBleScanning.dispose();
    selectedBleDevice.dispose();
    usbDevices.dispose();
    isUsbRefreshing.dispose();
    selectedUsbDevice.dispose();
    connectionState.dispose();
  }
}

/// 日志导出操作的最终结果。
enum LogExportOutcome { saved, cancelled, failed }
