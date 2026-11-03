import 'dart:async';

import '../../database/app_repository.dart';
import '../../models/connection_mode.dart';
import '../../models/log_entry.dart';

/// 将内存日志分批写入 Drift，避免每条报文触发一次磁盘事务。
final class LogSessionRecorder {
  factory LogSessionRecorder({
    required AppRepository repository,
    int batchSize = 100,
    Duration flushInterval = const Duration(milliseconds: 300),
    int maxPendingEntries = 1000,
    void Function(String message)? onError,
  }) {
    return LogSessionRecorder._(
      repository,
      batchSize,
      flushInterval,
      maxPendingEntries,
      onError,
    );
  }

  LogSessionRecorder._(
    this._repository,
    this.batchSize,
    this.flushInterval,
    this.maxPendingEntries,
    this._onError,
  );

  final AppRepository _repository;
  final int batchSize;
  final Duration flushInterval;
  final int maxPendingEntries;
  final void Function(String message)? _onError;
  final List<LogEntry> _pending = <LogEntry>[];
  Timer? _flushTimer;
  Future<void>? _activeFlush;
  int? _sessionId;
  bool _active = false;
  bool _overflowReported = false;
  DateTime? _stopRequestedAt;

  /// 当前是否存在未结束的日志会话。
  bool get isActive => _active;

  /// 当前数据库会话主键，供测试和诊断使用。
  int? get sessionId => _sessionId;

  /// 开始新的日志会话。
  Future<void> start(ConnectionMode mode, DateTime startedAt) async {
    if (_active) {
      return;
    }
    _active = true;
    _overflowReported = false;
    _stopRequestedAt = null;
    _pending.clear();
    try {
      final sessionId = await _repository.startLogSession(mode, startedAt);
      _sessionId = sessionId;
      if (!_active) {
        await _repository.endLogSession(
          sessionId,
          _stopRequestedAt ?? startedAt,
        );
        _sessionId = null;
        _pending.clear();
        return;
      }
      if (_pending.length >= batchSize) {
        unawaited(flush());
      } else if (_pending.isNotEmpty) {
        _scheduleFlush();
      }
    } catch (_) {
      _active = false;
      _sessionId = null;
      _pending.clear();
      rethrow;
    }
  }

  /// 添加一条日志并安排批量落库。
  void add(LogEntry entry) {
    if (!_active) {
      return;
    }
    _pending.add(entry);
    if (_pending.length > maxPendingEntries) {
      _pending.removeAt(0);
      if (!_overflowReported) {
        _overflowReported = true;
        _onError?.call('日志写入速度超过存储能力，部分旧日志未落库');
      }
    }
    if (_pending.length >= batchSize) {
      unawaited(flush());
    } else {
      _scheduleFlush();
    }
  }

  /// 立即写入全部待处理日志。
  Future<void> flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    final activeFlush = _activeFlush;
    if (activeFlush != null) {
      return activeFlush;
    }
    final operation = _flushPending();
    _activeFlush = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_activeFlush, operation)) {
          _activeFlush = null;
        }
      }),
    );
    return operation;
  }

  /// 刷新待写日志、结束会话并清理超量历史会话。
  Future<void> stop(DateTime endedAt) async {
    if (!_active) {
      return;
    }
    _active = false;
    _stopRequestedAt = endedAt;
    await flush();
    final sessionId = _sessionId;
    _sessionId = null;
    _pending.clear();
    if (sessionId == null) {
      return;
    }
    _stopRequestedAt = null;
    try {
      await _repository.endLogSession(sessionId, endedAt);
      await _repository.trimLogSessions();
    } catch (_) {
      _onError?.call('日志会话收尾失败');
    }
  }

  Future<void> _flushPending() async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    while (_pending.isNotEmpty) {
      final batch = List<LogEntry>.of(_pending);
      _pending.clear();
      try {
        await _repository.appendLogEntries(sessionId, batch);
      } catch (_) {
        _pending.insertAll(0, batch);
        _onError?.call('日志保存失败，将在下次连接时重试');
        return;
      }
    }
  }

  void _scheduleFlush() {
    if (_flushTimer?.isActive ?? false) {
      return;
    }
    _flushTimer = Timer(flushInterval, () {
      unawaited(flush());
    });
  }
}
