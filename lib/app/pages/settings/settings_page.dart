import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/appearance_preferences.dart';
import '../../models/app_update.dart';
import '../../models/app_preferences.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'appearance_controller.dart';
import 'communication_settings_controller.dart';
import '../history/log_history_controller.dart';
import '../update/update_controller.dart';
import '../update/update_dialog.dart';
import '../update/update_notice_listener.dart';

/// 应用设置页。
///
/// 主题模式在当前页通过底部选择器切换，主题配色进入独立页面选择。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<AppearanceController>();
    final communication = getIt<CommunicationSettingsController>();
    final history = getIt<LogHistoryController>();
    final updateController = getIt<UpdateController>();
    return SignalBuilder(
      builder: (context) {
        final colors = context.appColors;
        final updateState = updateController.state.value;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyle(context),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: colors.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              systemOverlayStyle: AppTheme.systemOverlayStyle(context),
              leading: IconButton(
                tooltip: '返回',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                '设置',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontSize: 28),
              ),
            ),
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: colors.pageGradient),
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    kToolbarHeight + 34,
                    12,
                    24 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: <Widget>[
                    ErrorToastListener(
                      readError: () => controller.lastError.value,
                      onShown: controller.dismissError,
                    ),
                    ErrorToastListener(
                      readError: () => communication.lastError.value,
                      onShown: communication.dismissError,
                    ),
                    UpdateNoticeListener(controller: updateController),
                    Text(
                      '偏好',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-theme-mode'),
                      icon: _themeModeIcon(controller.themeMode.value),
                      title: '主题模式',
                      value: controller.themeMode.value.label,
                      onTap: () =>
                          unawaited(_selectThemeMode(context, controller)),
                    ),
                    const SizedBox(height: 12),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-theme-color'),
                      icon: Icons.palette_outlined,
                      title: '主题配色',
                      value: controller.themePreset.value.label,
                      onTap: () =>
                          unawaited(context.push<void>(Routes.themeColor)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '日志与历史',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSwitchTile(
                      key: const ValueKey<String>(
                        'settings-persist-session-logs',
                      ),
                      icon: Icons.save_outlined,
                      title: '保存通信会话',
                      subtitle: '关闭后仍会显示当前日志，但不会写入本地历史',
                      value: communication.persistSessionLogs.value,
                      onChanged: (value) =>
                          unawaited(communication.setPersistSessionLogs(value)),
                    ),
                    const SizedBox(height: 12),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-log-retention'),
                      icon: Icons.auto_delete_outlined,
                      title: '历史保留数量',
                      value:
                          '最近 ${communication.logRetentionSessions.value} 个会话',
                      onTap: () => unawaited(
                        _selectLogRetention(context, communication),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-log-history'),
                      icon: Icons.history_rounded,
                      title: '日志历史',
                      value: '查看、搜索或导出历史会话',
                      onTap: () =>
                          unawaited(context.push<void>(Routes.sessions)),
                    ),
                    const SizedBox(height: 12),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-clear-log-history'),
                      icon: Icons.delete_sweep_outlined,
                      title: '清空日志历史',
                      value: '删除全部已保存的通信会话',
                      onTap: () => unawaited(_clearHistory(context, history)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '应用',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionTile(
                      key: const ValueKey<String>('settings-update-check'),
                      icon: Icons.system_update_alt_rounded,
                      title: '版本更新',
                      value: _updateValue(updateState),
                      loading: updateState.status == UpdateStatus.checking,
                      onTap: updateState.status == UpdateStatus.checking
                          ? null
                          : () => unawaited(
                              _checkForUpdate(context, updateController),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectThemeMode(
    BuildContext context,
    AppearanceController controller,
  ) async {
    final selected = await showModalBottomSheet<AppThemeMode>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appColors.surface,
      barrierColor: context.appColors.barrier,
      builder: (context) =>
          _ThemeModeSheet(selected: controller.themeMode.value),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    final saved = await controller.setThemeMode(selected);
    if (!saved && context.mounted) {
      AppToast.error(context, '保存主题设置失败');
    }
  }

  Future<void> _checkForUpdate(
    BuildContext context,
    UpdateController controller,
  ) async {
    final result = await controller.checkForUpdates(
      trigger: UpdateCheckTrigger.manual,
    );
    if (!context.mounted || result?.hasUpdate != true) {
      return;
    }
    await showUpdateDialog(context: context, controller: controller);
  }

  Future<void> _selectLogRetention(
    BuildContext context,
    CommunicationSettingsController controller,
  ) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('历史保留数量'),
        children: <Widget>[
          for (final count in AppPreferences.supportedLogRetentionSessions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(count),
              child: Row(
                children: <Widget>[
                  Icon(
                    controller.logRetentionSessions.value == count
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text('最近 $count 个会话'),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    final saved = await controller.setLogRetentionSessions(selected);
    if (!saved && context.mounted) {
      AppToast.error(context, '保存日志保留设置失败');
    }
  }

  Future<void> _clearHistory(
    BuildContext context,
    LogHistoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志历史'),
        content: const Text('这会删除全部已保存通信会话，且无法恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final deleted = await controller.deleteAll();
    if (!context.mounted) {
      return;
    }
    if (deleted) {
      AppToast.success(context, '日志历史已清空');
    } else {
      AppToast.error(context, '清空日志历史失败');
    }
  }

  String _updateValue(UpdateState state) {
    return switch (state.status) {
      UpdateStatus.checking => '正在检查...',
      UpdateStatus.available => '可更新至 ${state.update?.tagName ?? '新版本'}',
      UpdateStatus.downloading => '正在下载安装包',
      UpdateStatus.awaitingInstall => '等待系统安装',
      UpdateStatus.failed => '检查失败，点击重试',
      _ when state.installed != null => '当前 ${state.installed!.displayVersion}',
      _ => '当前版本未知',
    };
  }

  IconData _themeModeIcon(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_outlined,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title，$value',
      child: Material(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 29, color: colors.ink),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: TextStyle(
                          color: colors.inkMuted,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (loading)
                  SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colors.primaryDeep,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 28,
                    color: colors.inkMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, size: 29, color: colors.ink),
        title: Text(
          title,
          style: TextStyle(
            color: colors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet({required this.selected});

  final AppThemeMode selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text('主题模式', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final mode in AppThemeMode.values)
            _ThemeModeOption(
              mode: mode,
              selected: mode == selected,
              onTap: () => Navigator.of(context).pop(mode),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_outlined,
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? colors.primarySoft : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-mode-${mode.name}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 22, color: colors.ink),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: selected ? colors.primaryDeep : colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
