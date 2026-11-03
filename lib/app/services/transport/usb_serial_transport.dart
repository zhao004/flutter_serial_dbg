import 'dart:async';
import 'dart:typed_data';

import '../../models/connection_config.dart';
import '../../models/transport_event.dart';
import '../usb/usb_serial_service.dart';
import 'transport.dart';

/// 基于 Android USB Host 的串口 Transport。
///
/// 插拔事件与接收流使用独立订阅，任一底层通道结束都会释放串口句柄。
final class UsbSerialTransport with TransportEventEmitter implements Transport {
  UsbSerialTransport(this._usbSerialService);

  final UsbSerialService _usbSerialService;
  UsbSerialConnection? _connection;
  StreamSubscription<UsbSerialDeviceEvent>? _deviceEventSubscription;
  StreamSubscription<Uint8List>? _inputSubscription;
  UsbSerialConfig? _config;
  bool _connected = false;
  bool _disposed = false;
  bool _disconnecting = false;
  bool _deviceDetached = false;
  Future<void>? _cleanupOperation;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_disposed) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        '传输通道已释放',
      );
    }
    if (_connected || _connection != null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'USB 串口已经连接',
      );
    }
    if (config is! UsbSerialConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'USB 串口配置类型不匹配',
      );
    }

    _config = config;
    _deviceDetached = false;
    _deviceEventSubscription = _usbSerialService.events.listen(
      _handleDeviceEvent,
      onError: (Object error, StackTrace stackTrace) {
        _handleUnexpectedDisconnect('USB 设备事件监听异常，串口已断开');
      },
    );

    try {
      final connection = await _usbSerialService.open(config);
      if (_disposed || _deviceDetached) {
        await connection.close();
        throw TransportException(
          _deviceDetached
              ? TransportErrorKind.connection
              : TransportErrorKind.invalidState,
          _deviceDetached ? 'USB 串口设备已拔出' : '连接完成前传输通道已释放',
        );
      }
      _connection = connection;
      _inputSubscription = connection.inputStream.listen(
        (data) {
          emitEvent(TransportDataReceived(bytes: data));
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleUnexpectedDisconnect('USB 串口接收异常，连接已断开');
        },
        onDone: () {
          _handleUnexpectedDisconnect('USB 串口数据流已关闭');
        },
        cancelOnError: true,
      );
      _connected = true;
      emitEvent(TransportConnected(connection.endpoint));
    } on TransportException {
      await _cleanupResources();
      rethrow;
    } on UsbSerialException catch (error) {
      await _cleanupResources();
      throw TransportException(TransportErrorKind.connection, error.message);
    } catch (_) {
      await _cleanupResources();
      throw const TransportException(
        TransportErrorKind.connection,
        'USB 串口连接失败',
      );
    }
  }

  @override
  Future<void> send(Uint8List data) async {
    final connection = _connection;
    if (!_connected || connection == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'USB 串口尚未连接',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    try {
      await connection.write(data);
    } on UsbSerialException catch (error) {
      _handleUnexpectedDisconnect('USB 串口写入失败，连接已断开');
      throw TransportException(TransportErrorKind.send, error.message);
    } catch (_) {
      _handleUnexpectedDisconnect('USB 串口写入失败，连接已断开');
      throw const TransportException(
        TransportErrorKind.send,
        'USB 串口发送失败，设备可能已经断开',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disconnecting) {
      return;
    }
    _disconnecting = true;
    _connected = false;
    await _cleanupResources();
    if (!_disposed) {
      emitEvent(const TransportDisconnected());
    }
    _disconnecting = false;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await disconnect();
    _disposed = true;
    await closeEventStream();
  }

  void _handleDeviceEvent(UsbSerialDeviceEvent event) {
    final config = _config;
    if (event.type != UsbSerialDeviceEventType.detached ||
        config == null ||
        event.device.deviceId != config.deviceId) {
      return;
    }
    _deviceDetached = true;
    _handleUnexpectedDisconnect('USB 串口设备已拔出');
  }

  void _handleUnexpectedDisconnect(String reason) {
    if (_disconnecting || !_connected) {
      return;
    }
    _connected = false;
    emitEvent(TransportDisconnected(reason: reason));
    unawaited(_cleanupResources());
  }

  Future<void> _cleanupResources() {
    final active = _cleanupOperation;
    if (active != null) {
      return active;
    }
    final operation = _performCleanup();
    _cleanupOperation = operation;
    return operation.whenComplete(() {
      if (identical(_cleanupOperation, operation)) {
        _cleanupOperation = null;
      }
    });
  }

  Future<void> _performCleanup() async {
    final inputSubscription = _inputSubscription;
    _inputSubscription = null;
    await inputSubscription?.cancel();
    final deviceEventSubscription = _deviceEventSubscription;
    _deviceEventSubscription = null;
    await deviceEventSubscription?.cancel();
    final connection = _connection;
    _connection = null;
    _config = null;
    _connected = false;
    await connection?.close();
  }
}
