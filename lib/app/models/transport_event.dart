import 'dart:collection';
import 'dart:typed_data';

/// Transport 生命周期和数据事件的基类。
sealed class TransportEvent {
  const TransportEvent();
}

/// 传输通道已建立或服务端已开始监听。
final class TransportConnected extends TransportEvent {
  const TransportConnected(this.endpoint);

  /// 不包含敏感凭据的远端或监听端点摘要。
  final String endpoint;
}

/// 传输通道已关闭。
final class TransportDisconnected extends TransportEvent {
  const TransportDisconnected({this.reason});

  final String? reason;
}

/// 收到一段原始传输数据。
final class TransportDataReceived extends TransportEvent {
  TransportDataReceived({
    required Uint8List bytes,
    this.remoteAddress,
    this.remotePort,
  }) : _bytes = UnmodifiableListView<int>(Uint8List.fromList(bytes));

  final UnmodifiableListView<int> _bytes;
  final String? remoteAddress;
  final int? remotePort;

  /// 接收到的原始字节只读视图。
  List<int> get bytes => _bytes;

  /// 返回供日志或上层处理使用的独立字节副本。
  Uint8List copyBytes() => Uint8List.fromList(_bytes);

  @override
  String toString() {
    return 'TransportDataReceived('
        'remote: $remoteAddress:$remotePort, '
        'byteLength: ${_bytes.length}'
        ')';
  }
}

/// 非预期传输异常，异常消息不得包含原始通信内容。
final class TransportFailure extends TransportEvent {
  const TransportFailure(this.message);

  final String message;
}
