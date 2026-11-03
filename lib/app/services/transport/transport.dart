import 'dart:async';
import 'dart:typed_data';

import '../../models/connection_config.dart';
import '../../models/transport_event.dart';

/// 所有 WiFi、BLE 和 USB 通道共用的通信接口。
abstract interface class Transport {
  /// 连接、数据和断开事件流。
  Stream<TransportEvent> get events;

  /// 当前连接配置。
  ConnectionConfig? get config;

  /// 是否已经建立可发送连接或正在监听。
  bool get isConnected;

  /// 建立连接或开始监听。
  Future<void> connect(ConnectionConfig config);

  /// 发送一段原始字节。
  Future<void> send(Uint8List data);

  /// 幂等关闭当前连接。
  Future<void> disconnect();

  /// 释放订阅和底层句柄，调用后不可复用。
  Future<void> dispose();
}

/// 传输错误分类，便于控制器映射稳定提示。
enum TransportErrorKind { invalidState, connection, receive, send, unsupported }

/// 不暴露底层堆栈和通信内容的传输异常。
final class TransportException implements Exception {
  const TransportException(this.kind, this.message);

  final TransportErrorKind kind;
  final String message;

  @override
  String toString() => message;
}

/// 为各个 Transport 提供统一的事件流生命周期。
mixin TransportEventEmitter {
  final StreamController<TransportEvent> _eventController =
      StreamController<TransportEvent>.broadcast(sync: true);
  bool _eventStreamClosed = false;

  /// 当前事件流。
  Stream<TransportEvent> get events => _eventController.stream;

  /// 安全发送事件；释放完成后的事件会被忽略。
  void emitEvent(TransportEvent event) {
    if (!_eventStreamClosed) {
      _eventController.add(event);
    }
  }

  /// 关闭事件流。
  Future<void> closeEventStream() async {
    if (_eventStreamClosed) {
      return;
    }
    _eventStreamClosed = true;
    await _eventController.close();
  }
}
