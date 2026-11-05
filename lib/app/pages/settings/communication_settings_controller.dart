import 'package:signals/signals.dart';

import '../../database/app_repository.dart';
import '../../models/app_preferences.dart';
import '../../models/log_entry.dart';

/// 通信格式与日志持久化偏好的唯一状态和写入口。
class CommunicationSettingsController {
  CommunicationSettingsController(this._repository);

  final AppRepository _repository;

  /// 发送负载格式。
  final Signal<PayloadFormat> sendFormat = signal(PayloadFormat.text);

  /// 接收日志展示格式。
  final Signal<PayloadFormat> receiveFormat = signal(PayloadFormat.text);

  /// 发送文本时是否追加 CRLF。
  final Signal<bool> appendCrlf = signal(false);

  /// 新日志到达后是否自动滚动。
  final Signal<bool> autoScroll = signal(true);

  /// 是否将通信会话写入本地数据库。
  final Signal<bool> persistSessionLogs = signal(true);

  /// 本地保留的日志会话数量。
  final Signal<int> logRetentionSessions = signal(
    AppPreferences.defaultLogRetentionSessions,
  );

  /// 最近一次设置读写错误。
  final Signal<String?> lastError = signal<String?>(null);

  Future<void>? _initialization;
  Future<void> _writeQueue = Future<void>.value();
  bool _disposed = false;

  /// 加载已保存通信偏好；重复调用复用同一初始化过程。
  Future<void> initialize() {
    return _initialization ??= _load();
  }

  /// 更新发送格式并异步保存。
  Future<bool> setSendFormat(PayloadFormat format) {
    if (sendFormat.value == format) {
      return Future<bool>.value(true);
    }
    sendFormat.value = format;
    return _queuePersist();
  }

  /// 更新接收展示格式并异步保存。
  Future<bool> setReceiveFormat(PayloadFormat format) {
    if (receiveFormat.value == format) {
      return Future<bool>.value(true);
    }
    receiveFormat.value = format;
    return _queuePersist();
  }

  /// 更新 CRLF 选项并异步保存。
  Future<bool> setAppendCrlf(bool enabled) {
    if (appendCrlf.value == enabled) {
      return Future<bool>.value(true);
    }
    appendCrlf.value = enabled;
    return _queuePersist();
  }

  /// 更新自动滚动选项并异步保存。
  Future<bool> setAutoScroll(bool enabled) {
    if (autoScroll.value == enabled) {
      return Future<bool>.value(true);
    }
    autoScroll.value = enabled;
    return _queuePersist();
  }

  /// 更新会话持久化开关并异步保存。
  Future<bool> setPersistSessionLogs(bool enabled) {
    if (persistSessionLogs.value == enabled) {
      return Future<bool>.value(true);
    }
    persistSessionLogs.value = enabled;
    return _queuePersist();
  }

  /// 更新日志会话保留数量并异步保存。
  Future<bool> setLogRetentionSessions(int count) {
    if (!AppPreferences.supportedLogRetentionSessions.contains(count)) {
      throw ArgumentError.value(count, 'count', '不是受支持的保留数量');
    }
    if (logRetentionSessions.value == count) {
      return Future<bool>.value(true);
    }
    logRetentionSessions.value = count;
    return _queuePersist();
  }

  /// 清除最近一次设置错误。
  void dismissError() {
    lastError.value = null;
  }

  Future<void> _load() async {
    try {
      final preferences = await _repository.loadPreferences();
      if (_disposed) {
        return;
      }
      sendFormat.value = preferences.sendFormat;
      receiveFormat.value = preferences.receiveFormat;
      appendCrlf.value = preferences.appendCrlf;
      autoScroll.value = preferences.autoScroll;
      persistSessionLogs.value = preferences.persistSessionLogs;
      logRetentionSessions.value =
          AppPreferences.supportedLogRetentionSessions.contains(
            preferences.logRetentionSessions,
          )
          ? preferences.logRetentionSessions
          : AppPreferences.defaultLogRetentionSessions;
    } catch (_) {
      if (!_disposed) {
        lastError.value = '读取通信设置失败，已使用默认设置';
      }
    }
  }

  Future<bool> _queuePersist() {
    final snapshot = AppPreferences(
      sendFormat: sendFormat.value,
      receiveFormat: receiveFormat.value,
      appendCrlf: appendCrlf.value,
      autoScroll: autoScroll.value,
      persistSessionLogs: persistSessionLogs.value,
      logRetentionSessions: logRetentionSessions.value,
    );
    final operation = _writeQueue.then((_) async {
      try {
        await _repository.savePreferences(snapshot);
        if (!_disposed) {
          lastError.value = null;
        }
        return true;
      } catch (_) {
        if (!_disposed) {
          lastError.value = '保存通信设置失败';
        }
        return false;
      }
    });
    _writeQueue = operation.then<void>((_) {});
    return operation;
  }

  /// 释放响应式信号。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    sendFormat.dispose();
    receiveFormat.dispose();
    appendCrlf.dispose();
    autoScroll.dispose();
    persistSessionLogs.dispose();
    logRetentionSessions.dispose();
    lastError.dispose();
  }
}
