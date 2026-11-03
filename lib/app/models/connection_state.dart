import 'connection_config.dart';

/// 传输通道的生命周期状态。
enum TransportStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  failed;

  /// 是否正在执行连接或断开操作。
  bool get isBusy =>
      this == TransportStatus.connecting ||
      this == TransportStatus.disconnecting;
}

/// 页面可观察的不可变连接快照。
final class ConnectionSnapshot {
  ConnectionSnapshot({
    required this.status,
    required this.changedAt,
    this.config,
    this.message,
  }) {
    if ((status == TransportStatus.connecting ||
            status == TransportStatus.connected ||
            status == TransportStatus.disconnecting) &&
        config == null) {
      throw ArgumentError('进行中的连接状态必须包含连接配置');
    }
    if (status == TransportStatus.failed &&
        (message == null || message!.trim().isEmpty)) {
      throw ArgumentError('失败状态必须包含可展示的错误信息');
    }
  }

  factory ConnectionSnapshot.disconnected({required DateTime changedAt}) {
    return ConnectionSnapshot(
      status: TransportStatus.disconnected,
      changedAt: changedAt,
    );
  }

  final TransportStatus status;
  final DateTime changedAt;
  final ConnectionConfig? config;
  final String? message;
}
