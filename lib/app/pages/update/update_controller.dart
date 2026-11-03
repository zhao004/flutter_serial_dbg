import 'dart:async';

import 'package:signals/signals.dart';

import '../../models/app_update.dart';
import '../../services/update/app_update_service.dart';

/// 全局自动更新状态与命令编排器。
class UpdateController {
  UpdateController(this._service);

  final AppUpdateService _service;

  /// 当前更新流程快照。
  final Signal<UpdateState> state = signal(const UpdateState());

  /// 供页面展示一次的提示。
  final Signal<UpdateNotice?> notice = signal<UpdateNotice?>(null);

  Future<void>? _initialization;
  bool _startupCheckStarted = false;
  bool _checkInProgress = false;
  bool _installStartPending = false;
  bool _disposed = false;

  /// 读取当前安装版本；重复调用复用同一初始化过程。
  Future<void> initialize() {
    return _initialization ??= _loadInstalledInfo();
  }

  /// 每个应用进程仅执行一次启动检查。
  Future<UpdateCheckResult?> checkAtStartup() async {
    await initialize();
    if (_startupCheckStarted || _disposed) {
      return null;
    }
    _startupCheckStarted = true;
    return checkForUpdates(trigger: UpdateCheckTrigger.automatic);
  }

  /// 检查稳定版 Release，并在手动检查时发布结果提示。
  Future<UpdateCheckResult?> checkForUpdates({
    required UpdateCheckTrigger trigger,
  }) async {
    if (_disposed || _checkInProgress || state.value.isBusy) {
      return null;
    }
    _checkInProgress = true;
    try {
      return await _checkForUpdates(trigger);
    } finally {
      _checkInProgress = false;
    }
  }

  Future<UpdateCheckResult?> _checkForUpdates(
    UpdateCheckTrigger trigger,
  ) async {
    await initialize();
    if (_disposed) {
      return null;
    }

    final installed = state.value.installed;
    state.value = UpdateState(
      status: UpdateStatus.checking,
      installed: installed,
    );
    try {
      final result = await _service.checkForUpdate();
      if (_disposed) {
        return null;
      }
      if (result.hasUpdate) {
        state.value = UpdateState(
          status: UpdateStatus.available,
          installed: result.installed,
          update: result.update,
        );
      } else {
        state.value = UpdateState(
          status: UpdateStatus.upToDate,
          installed: result.installed,
        );
        if (trigger == UpdateCheckTrigger.manual) {
          _showNotice('当前已是最新版本', UpdateNoticeKind.info);
        }
      }
      return result;
    } on AppUpdateException catch (error) {
      if (_disposed) {
        return null;
      }
      state.value = UpdateState(
        status: trigger == UpdateCheckTrigger.manual
            ? UpdateStatus.failed
            : UpdateStatus.idle,
        installed: installed,
        errorMessage: trigger == UpdateCheckTrigger.manual
            ? error.message
            : null,
      );
      if (trigger == UpdateCheckTrigger.manual) {
        _showNotice(error.message, UpdateNoticeKind.error);
      }
      return null;
    } catch (_) {
      if (_disposed) {
        return null;
      }
      const message = '检查更新失败，请稍后重试';
      state.value = UpdateState(
        status: trigger == UpdateCheckTrigger.manual
            ? UpdateStatus.failed
            : UpdateStatus.idle,
        installed: installed,
        errorMessage: trigger == UpdateCheckTrigger.manual ? message : null,
      );
      if (trigger == UpdateCheckTrigger.manual) {
        _showNotice(message, UpdateNoticeKind.error);
      }
      return null;
    }
  }

  /// 下载 APK 并拉起 Android 系统安装界面。
  Future<void> downloadAndInstall() async {
    final update = state.value.update;
    if (_disposed ||
        update == null ||
        state.value.isBusy ||
        _installStartPending) {
      return;
    }
    _installStartPending = true;
    try {
      await _downloadAndInstall(update);
    } finally {
      _installStartPending = false;
    }
  }

  Future<void> _downloadAndInstall(AvailableUpdate update) async {
    final canInstall = await _service.canRequestPackageInstalls();
    if (!canInstall) {
      final opened = await _service.openInstallPermissionSettings();
      if (_disposed) {
        return;
      }
      const message = '请允许“串口调试助手”安装应用，然后返回重试';
      state.value = UpdateState(
        status: UpdateStatus.available,
        installed: state.value.installed,
        update: update,
        errorMessage: message,
      );
      _showNotice(
        opened ? message : '无法打开安装权限设置，请手动前往系统设置',
        UpdateNoticeKind.warning,
      );
      return;
    }

    state.value = UpdateState(
      status: UpdateStatus.downloading,
      installed: state.value.installed,
      update: update,
      progress: 0,
    );

    var receivedTerminalEvent = false;
    try {
      await for (final event in _service.install(update)) {
        if (_disposed) {
          return;
        }
        switch (event.type) {
          case ApkInstallEventType.downloading:
            state.value = UpdateState(
              status: UpdateStatus.downloading,
              installed: state.value.installed,
              update: update,
              progress: event.progress ?? 0,
            );
          case ApkInstallEventType.installing:
            receivedTerminalEvent = true;
            state.value = UpdateState(
              status: UpdateStatus.awaitingInstall,
              installed: state.value.installed,
              update: update,
            );
            return;
          case ApkInstallEventType.completed:
            receivedTerminalEvent = true;
            state.value = UpdateState(
              status: UpdateStatus.awaitingInstall,
              installed: state.value.installed,
              update: update,
            );
          case ApkInstallEventType.cancelled:
            receivedTerminalEvent = true;
            state.value = UpdateState(
              status: UpdateStatus.available,
              installed: state.value.installed,
              update: update,
            );
          case ApkInstallEventType.failed:
            receivedTerminalEvent = true;
            final message = event.message ?? '更新安装失败，请稍后重试';
            state.value = UpdateState(
              status: UpdateStatus.failed,
              installed: state.value.installed,
              update: update,
              errorMessage: message,
            );
            _showNotice(message, UpdateNoticeKind.error);
        }
      }
    } catch (_) {
      if (!_disposed) {
        const message = '更新安装失败，请稍后重试';
        state.value = UpdateState(
          status: UpdateStatus.failed,
          installed: state.value.installed,
          update: update,
          errorMessage: message,
        );
        _showNotice(message, UpdateNoticeKind.error);
      }
    }

    if (!_disposed && !receivedTerminalEvent) {
      const message = '未收到安装状态，请重试';
      state.value = UpdateState(
        status: UpdateStatus.failed,
        installed: state.value.installed,
        update: update,
        errorMessage: message,
      );
    }
  }

  /// 取消当前 APK 下载。
  Future<void> cancelDownload() async {
    if (state.value.status != UpdateStatus.downloading) {
      return;
    }
    await _service.cancelDownload();
    if (_disposed || state.value.status != UpdateStatus.downloading) {
      return;
    }
    state.value = UpdateState(
      status: UpdateStatus.available,
      installed: state.value.installed,
      update: state.value.update,
    );
  }

  /// 清除已经展示的短暂提示。
  void dismissNotice() {
    if (!_disposed) {
      notice.value = null;
    }
  }

  Future<void> _loadInstalledInfo() async {
    try {
      final installed = await _service.installedInfo();
      if (!_disposed) {
        state.value = UpdateState(installed: installed);
      }
    } catch (_) {
      if (!_disposed) {
        state.value = const UpdateState();
      }
    }
  }

  void _showNotice(String message, UpdateNoticeKind kind) {
    if (!_disposed) {
      notice.value = UpdateNotice(message, kind);
    }
  }

  /// 释放响应式信号并停止当前下载。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    unawaited(_service.cancelDownload());
    state.dispose();
    notice.dispose();
  }
}
