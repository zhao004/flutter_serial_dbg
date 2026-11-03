import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../models/connection_config.dart';
import '../../models/transport_event.dart';
import '../../utils/constants.dart';
import 'transport.dart';

/// UDP 客户端，只接收配置远端地址和端口的数据报。
final class UdpClientTransport with TransportEventEmitter implements Transport {
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  InternetAddress? _remoteAddress;
  UdpClientConfig? _config;
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
        'UDP 客户端已经连接',
      );
    }
    if (config is! UdpClientConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 客户端配置类型不匹配',
      );
    }

    _config = config;
    try {
      final addresses = await InternetAddress.lookup(config.host)
          .timeout(NetworkDefaults.connectTimeout);
      if (addresses.isEmpty) {
        throw const SocketException('远端地址无解析结果');
      }
      final remoteAddress = addresses.first;
      final bindAddress = remoteAddress.type == InternetAddressType.IPv6
          ? InternetAddress.anyIPv6
          : InternetAddress.anyIPv4;
      final socket = await RawDatagramSocket.bind(bindAddress, 0);
      if (_disposed) {
        socket.close();
        throw const TransportException(
          TransportErrorKind.invalidState,
          '连接完成前传输通道已释放',
        );
      }
      _remoteAddress = remoteAddress;
      _socket = socket;
      _connected = true;
      _subscription = socket.listen(
        _handleSocketEvent,
        onError: (Object error, StackTrace stackTrace) {
          _handleUnexpectedDisconnect('UDP 接收异常，连接已断开');
        },
        onDone: () {
          _handleUnexpectedDisconnect('UDP 客户端已断开');
        },
      );
      emitEvent(TransportConnected('${remoteAddress.address}:${config.port}'));
    } on TransportException {
      rethrow;
    } on SocketException {
      await _closeSocket();
      _config = null;
      throw const TransportException(
        TransportErrorKind.connection,
        'UDP 地址解析或本地绑定失败',
      );
    } on TimeoutException {
      await _closeSocket();
      _config = null;
      throw const TransportException(
        TransportErrorKind.connection,
        'UDP 地址解析超时',
      );
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final socket = _socket;
    final remoteAddress = _remoteAddress;
    final config = _config;
    if (socket == null || remoteAddress == null || config == null) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        return;
      }
      if (datagram.address.address != remoteAddress.address ||
          datagram.port != config.port) {
        continue;
      }
      emitEvent(
        TransportDataReceived(
          bytes: datagram.data,
          remoteAddress: datagram.address.address,
          remotePort: datagram.port,
        ),
      );
    }
  }

  @override
  Future<void> send(Uint8List data) async {
    final socket = _socket;
    final remoteAddress = _remoteAddress;
    final config = _config;
    if (!_connected ||
        socket == null ||
        remoteAddress == null ||
        config == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 客户端尚未连接',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    if (data.length > NetworkDefaults.maxUdpPayloadBytes) {
      throw const TransportException(
        TransportErrorKind.send,
        'UDP 单次发送不能超过 65507 字节',
      );
    }
    final sent = socket.send(data, remoteAddress, config.port);
    if (sent != data.length) {
      throw const TransportException(
        TransportErrorKind.send,
        'UDP 数据未完整写入本地套接字',
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
    _remoteAddress = null;
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
    _socket?.close();
    _socket = null;
  }

  void _handleUnexpectedDisconnect(String reason) {
    if (_disconnecting || !_connected) {
      return;
    }
    _connected = false;
    _subscription = null;
    _socket?.close();
    _socket = null;
    _remoteAddress = null;
    _config = null;
    emitEvent(TransportDisconnected(reason: reason));
  }
}

/// UDP 服务端，回复最近一次收到数据报的远端地址。
final class UdpServerTransport with TransportEventEmitter implements Transport {
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  InternetAddress? _lastRemoteAddress;
  int? _lastRemotePort;
  UdpServerConfig? _config;
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
    if (_listening || _socket != null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 服务端已经在监听',
      );
    }
    if (config is! UdpServerConfig) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 服务端配置类型不匹配',
      );
    }

    _config = config;
    try {
      final socket = await RawDatagramSocket.bind(
        config.bindAddress,
        config.port,
      ).timeout(NetworkDefaults.connectTimeout);
      _socket = socket;
      _listening = true;
      _subscription = socket.listen(
        _handleSocketEvent,
        onError: (Object error, StackTrace stackTrace) {
          _handleUnexpectedDisconnect('UDP 监听异常，服务已停止');
        },
        onDone: () {
          _handleUnexpectedDisconnect('UDP 服务端已停止');
        },
      );
      emitEvent(TransportConnected('${socket.address.address}:${socket.port}'));
    } on SocketException {
      _socket = null;
      _config = null;
      throw const TransportException(
        TransportErrorKind.connection,
        'UDP 监听失败，端口可能已被占用',
      );
    } on TimeoutException {
      _socket = null;
      _config = null;
      throw const TransportException(TransportErrorKind.connection, 'UDP 监听超时');
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final socket = _socket;
    if (socket == null) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        return;
      }
      _lastRemoteAddress = datagram.address;
      _lastRemotePort = datagram.port;
      emitEvent(
        TransportDataReceived(
          bytes: datagram.data,
          remoteAddress: datagram.address.address,
          remotePort: datagram.port,
        ),
      );
    }
  }

  @override
  Future<void> send(Uint8List data) async {
    final socket = _socket;
    final remoteAddress = _lastRemoteAddress;
    final remotePort = _lastRemotePort;
    if (!_listening || socket == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 服务端尚未监听',
      );
    }
    if (remoteAddress == null || remotePort == null) {
      throw const TransportException(
        TransportErrorKind.invalidState,
        'UDP 服务端尚未收到可用于回复的远端地址',
      );
    }
    if (data.isEmpty) {
      throw const TransportException(TransportErrorKind.send, '不能发送空数据');
    }
    if (data.length > NetworkDefaults.maxUdpPayloadBytes) {
      throw const TransportException(
        TransportErrorKind.send,
        'UDP 单次发送不能超过 65507 字节',
      );
    }
    final sent = socket.send(data, remoteAddress, remotePort);
    if (sent != data.length) {
      throw const TransportException(
        TransportErrorKind.send,
        'UDP 数据未完整写入本地套接字',
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
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    _socket?.close();
    _socket = null;
    _lastRemoteAddress = null;
    _lastRemotePort = null;
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

  void _handleUnexpectedDisconnect(String reason) {
    if (_disconnecting || !_listening) {
      return;
    }
    _listening = false;
    _subscription = null;
    _socket?.close();
    _socket = null;
    _lastRemoteAddress = null;
    _lastRemotePort = null;
    _config = null;
    emitEvent(TransportDisconnected(reason: reason));
  }
}
