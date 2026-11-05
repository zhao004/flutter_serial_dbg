import 'package:signals/signals.dart';

import '../../database/app_repository.dart';
import '../../models/connection_mode.dart';
import '../../models/log_entry.dart';
import '../../models/log_session_summary.dart';
import '../../services/logging/log_exporter.dart';

/// 日志历史列表、详情读取和删除操作的状态编排器。
class LogHistoryController {
  LogHistoryController({
    required AppRepository repository,
    required LogExporter exporter,
  }) : this._(repository, exporter);

  LogHistoryController._(this._repository, this._exporter);

  final AppRepository _repository;
  final LogExporter _exporter;

  /// 当前加载的会话摘要。
  final Signal<List<LogSessionSummary>> sessions =
      signal<List<LogSessionSummary>>(<LogSessionSummary>[]);

  /// 是否正在加载会话列表。
  final Signal<bool> isLoading = signal(false);

  /// 当前筛选模式；null 表示全部。
  final Signal<ConnectionMode?> selectedMode = signal<ConnectionMode?>(null);

  /// 最近一次历史操作错误。
  final Signal<String?> lastError = signal<String?>(null);

  bool _disposed = false;
  int _loadGeneration = 0;

  /// 重新加载当前筛选条件下的会话摘要。
  Future<void> loadSessions() async {
    final generation = ++_loadGeneration;
    if (!_disposed) {
      isLoading.value = true;
    }
    try {
      final result = await _repository.loadLogSessionSummaries(
        mode: selectedMode.value,
      );
      if (_disposed || generation != _loadGeneration) {
        return;
      }
      sessions.value = List<LogSessionSummary>.unmodifiable(result);
      lastError.value = null;
    } catch (_) {
      if (!_disposed && generation == _loadGeneration) {
        lastError.value = '读取日志历史失败';
      }
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        isLoading.value = false;
      }
    }
  }

  /// 更新连接模式筛选并重新加载。
  Future<void> setMode(ConnectionMode? mode) async {
    if (selectedMode.value == mode) {
      return;
    }
    selectedMode.value = mode;
    await loadSessions();
  }

  /// 读取指定会话的完整日志。
  Future<List<LogEntry>> loadEntries(int sessionId) {
    return _repository.loadSessionEntries(sessionId);
  }

  /// 导出指定会话。
  Future<bool> exportSession(
    int sessionId, {
    required PayloadFormat format,
  }) async {
    try {
      final entries = await _repository.loadSessionEntries(sessionId);
      if (entries.isEmpty) {
        lastError.value = '该会话没有可导出的日志';
        return false;
      }
      final path = await _exporter.export(entries, format: format);
      return path != null;
    } catch (_) {
      lastError.value = '导出历史会话失败';
      return false;
    }
  }

  /// 删除指定会话并刷新列表。
  Future<bool> deleteSession(int sessionId) async {
    try {
      await _repository.deleteLogSession(sessionId);
      sessions.value = List<LogSessionSummary>.unmodifiable(
        sessions.value.where((session) => session.id != sessionId),
      );
      return true;
    } catch (_) {
      lastError.value = '删除历史会话失败';
      return false;
    }
  }

  /// 删除全部历史会话。
  Future<bool> deleteAll() async {
    try {
      await _repository.deleteAllLogSessions();
      sessions.value = const <LogSessionSummary>[];
      return true;
    } catch (_) {
      lastError.value = '清空日志历史失败';
      return false;
    }
  }

  /// 清除当前错误。
  void dismissError() {
    lastError.value = null;
  }

  /// 释放响应式信号。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    sessions.dispose();
    isLoading.dispose();
    selectedMode.dispose();
    lastError.dispose();
  }
}
