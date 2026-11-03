import 'package:signals/signals.dart';

import '../../database/app_repository.dart';
import '../../models/appearance_preferences.dart';

/// 全局主题外观状态与持久化编排器。
class AppearanceController {
  AppearanceController(this._repository);

  final AppRepository _repository;

  /// 当前明暗模式。
  final Signal<AppThemeMode> themeMode = signal(AppThemeMode.system);

  /// 当前配色预设。
  final Signal<AppThemePreset> themePreset = signal(AppThemePreset.indigoM3);

  /// 最近一次主题设置读写错误。
  final Signal<String?> lastError = signal<String?>(null);

  Future<void>? _initialization;
  Future<void> _writeQueue = Future<void>.value();
  bool _disposed = false;

  /// 加载已保存外观；重复调用复用同一初始化过程。
  Future<void> initialize() {
    return _initialization ??= _load();
  }

  /// 更新明暗模式并异步保存。
  Future<bool> setThemeMode(AppThemeMode mode) {
    if (themeMode.value == mode) {
      return Future<bool>.value(true);
    }
    themeMode.value = mode;
    return _queuePersist();
  }

  /// 更新配色预设并异步保存。
  Future<bool> setThemePreset(AppThemePreset preset) {
    if (themePreset.value == preset) {
      return Future<bool>.value(true);
    }
    themePreset.value = preset;
    return _queuePersist();
  }

  /// 清除最近一次主题设置错误。
  void dismissError() {
    lastError.value = null;
  }

  Future<void> _load() async {
    try {
      final preferences = await _repository.loadAppearancePreferences();
      if (_disposed) {
        return;
      }
      themeMode.value = preferences.mode;
      themePreset.value = preferences.preset;
    } catch (_) {
      if (!_disposed) {
        lastError.value = '读取主题设置失败，已使用默认外观';
      }
    }
  }

  Future<bool> _queuePersist() {
    final snapshot = AppearancePreferences(
      mode: themeMode.value,
      preset: themePreset.value,
    );
    final operation = _writeQueue.then((_) async {
      try {
        await _repository.saveAppearancePreferences(snapshot);
        if (!_disposed) {
          lastError.value = null;
        }
        return true;
      } catch (_) {
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
    themeMode.dispose();
    themePreset.dispose();
    lastError.dispose();
  }
}
