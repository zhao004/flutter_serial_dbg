import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/appearance_preferences.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'appearance_controller.dart';

/// 应用设置页。
///
/// 主题模式在当前页通过底部选择器切换，主题配色进入独立页面选择。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<AppearanceController>();
    return SignalBuilder(
      builder: (context) {
        final colors = context.appColors;
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
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
