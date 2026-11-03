import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../models/connection_config.dart';
import '../../models/transport_event.dart';
import '../../utils/constants.dart';
import 'transport.dart';

/// TCP 客户端连接。
final class TcpClientTransport with TransportEventEmitter implements Transport {
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;
  TcpClientConfig? _config;
  bool _connected = false;
  bool _disposed = false;
  bool _disconnecting = false;

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
    if (_connected || _socket != null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 客户端已经连接',
      );
    }
    if (config is! TcpClientConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 客户端配置类型不匹配',
      );
    }

    _config = config;
    try {
      final socket = await Socket.connect(
        config.host,
        config.port,
        timeout: NetworkDefaults.connectTimeout,
      );
      if (_disposed) {
        socket.destroy();
        throw const TransportException(
          TransportErrorKind.invalidState,
          '连接完成前传输通道已释放',
        );
      }
      socket.setOption(SocketOption.tcpNoDelay, true);
      _socket = socket;
      _connected = true;
      _subscription = socket.listen(
        (data) {
          emitEvent(
            TransportDataReceived(
              bytes: data,
              remoteAddress: socket.remoteAddress.address,
              remotePort: socket.remotePort,
            ),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleUnexpectedDisconnect('TCP 接收异常，连接已断开');
        },
        onDone: () {
          _handleUnexpectedDisconnect('远端已断开 TCP 连接');
        },
        cancelOnError: true,
      );
      emitEvent(
        TransportConnected(
          '${socket.remoteAddress.address}:${socket.remotePort}',
        ),
      );
    } on TransportException {
      rethrow;
    } on SocketException {
      await _closeSocket();
      _config = null;
      throw const TransportException(
        TransportErrorKind.connection,
        'TCP 连接失败，请检查地址、端口和网络状态',
      );
    } on TimeoutException {
      await _closeSocket();
      _config = null;
      throw const TransportException(TransportErrorKind.connection, 'TCP 连接超时');
    }
  }

  @override
  Future<void> send(Uint8List data) async {
    final socket = _socket;
    if (!_connected || socket == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 客户端尚未连接',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    try {
      socket.add(data);
      await socket.flush();
    } on SocketException {
      _handleUnexpectedDisconnect('TCP 发送异常，连接已断开');
      throw const TransportException(
        TransportErrorKind.send,
        'TCP 发送失败，连接可能已经断开',
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
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _closeSocket();
    _config = null;
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

  Future<void> _closeSocket() async {
    final socket = _socket;
    _socket = null;
    socket?.destroy();
  }

  void _handleUnexpectedDisconnect(String reason) {
    if (_disconnecting || !_connected) {
      return;
    }
    _connected = false;
    _subscription = null;
    _closeSocket();
    _config = null;
    emitEvent(TransportDisconnected(reason: reason));
  }
}

/// TCP 服务端监听并接受单个客户端。
final class TcpServerTransport with TransportEventEmitter implements Transport {
  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _serverSubscription;
  Socket? _peer;
  StreamSubscription<Uint8List>? _peerSubscription;
  TcpServerConfig? _config;
  bool _listening = false;
  bool _disposed = false;
  bool _disconnecting = false;

  @override
  ConnectionConfig? get config => _config;

  @override
  bool get isConnected => _listening;

  @override
  Future<void> connect(ConnectionConfig config) async {
    if (_disposed) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        '传输通道已释放',
      );
    }
    if (_listening || _serverSocket != null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 服务端已经在监听',
      );
    }
    if (config is! TcpServerConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 服务端配置类型不匹配',
      );
    }

    _config = config;
    try {
      final server = await ServerSocket.bind(
        config.bindAddress,
        config.port,
        shared: false,
      ).timeout(NetworkDefaults.connectTimeout);
      _serverSocket = server;
      _listening = true;
      emitEvent(TransportConnected('${server.address.address}:${server.port}'));
      _serverSubscription = server.listen(
        (peer) {
          unawaited(_handleAcceptedPeer(server, peer));
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!_disconnecting && _listening) {
            _handlePeerClosed('TCP 监听异常，服务已停止');
          }
        },
      );
    } on SocketException {
      _serverSocket = null;
      _config = null;
      throw const TransportException(
        TransportErrorKind.connection,
        'TCP 监听失败，端口可能已被占用',
      );
    } on TimeoutException {
      _serverSocket = null;
      _config = null;
      throw const TransportException(TransportErrorKind.connection, 'TCP 监听超时');
    }
  }

  Future<void> _handleAcceptedPeer(ServerSocket server, Socket peer) async {
    if (_disposed || _serverSocket != server || !_listening) {
      peer.destroy();
      return;
    }
    final serverSubscription = _serverSubscription;
    _serverSubscription = null;
    await serverSubscription?.cancel();
    await server.close();
    _serverSocket = null;
    _peer = peer;
    _peerSubscription = peer.listen(
      (data) {
        emitEvent(
          TransportDataReceived(
            bytes: data,
            remoteAddress: peer.remoteAddress.address,
            remotePort: peer.remotePort,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _handlePeerClosed('TCP 客户端连接异常');
      },
      onDone: () {
        _handlePeerClosed('TCP 客户端已断开');
      },
      cancelOnError: true,
    );
    emitEvent(
      TransportConnected('${peer.remoteAddress.address}:${peer.remotePort}'),
    );
  }

  @override
  Future<void> send(Uint8List data) async {
    final peer = _peer;
    if (!_listening || peer == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'TCP 服务端尚无已连接客户端',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    try {
      peer.add(data);
      await peer.flush();
    } on SocketException {
      _handlePeerClosed('TCP 发送异常，客户端连接已断开');
      throw const TransportException(
        TransportErrorKind.send,
        'TCP 发送失败，客户端可能已经断开',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_disconnecting) {
      return;
    }
    _disconnecting = true;
    _listening = false;
    final subscription = _peerSubscription;
    _peerSubscription = null;
    await subscription?.cancel();
    final serverSubscription = _serverSubscription;
    _serverSubscription = null;
    await serverSubscription?.cancel();
    _peer?.destroy();
    _peer = null;
    await _serverSocket?.close();
    _serverSocket = null;
    _config = null;
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

  void _handlePeerClosed(String reason) {
    if (_disconnecting || !_listening) {
      return;
    }
    _listening = false;
    _peerSubscription = null;
    _serverSubscription?.cancel();
    _serverSubscription = null;
    _peer?.destroy();
    _peer = null;
    _serverSocket?.close();
    _serverSocket = null;
    _config = null;
    emitEvent(TransportDisconnected(reason: reason));
  }
}
