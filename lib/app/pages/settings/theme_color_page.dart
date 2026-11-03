import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/appearance_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'appearance_controller.dart';

/// 独立的应用配色选择页。
class ThemeColorPage extends StatefulWidget {
  const ThemeColorPage({super.key});

  @override
  State<ThemeColorPage> createState() => _ThemeColorPageState();
}

class _ThemeColorPageState extends State<ThemeColorPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppThemePreset> get _filteredPresets {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return AppThemePreset.values;
    }
    return AppThemePreset.values
        .where((preset) {
          return preset.label.toLowerCase().contains(query) ||
              preset.description.toLowerCase().contains(query) ||
              preset.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = getIt<AppearanceController>();
    return SignalBuilder(
      builder: (context) {
        final colors = context.appColors;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyle(context),
          child: Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: colors.background,
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
                '主题配色',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: colors.pageGradient),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: TextField(
                        key: const ValueKey<String>('theme-color-search'),
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '搜索配色',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清除搜索',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _query = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredPresets.isEmpty
                          ? Center(
                              child: Text(
                                '没有匹配的配色',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                2,
                                12,
                                24 + MediaQuery.viewPaddingOf(context).bottom,
                              ),
                              itemCount: _filteredPresets.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final preset = _filteredPresets[index];
                                return _ThemePresetCard(
                                  preset: preset,
                                  selected:
                                      controller.themePreset.value == preset,
                                  onTap: () {
                                    unawaited(
                                      _selectPreset(
                                        context,
                                        controller,
                                        preset,
                                      ),
                                    );
                                  },
                                );
                              },
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

  Future<void> _selectPreset(
    BuildContext context,
    AppearanceController controller,
    AppThemePreset preset,
  ) async {
    final saved = await controller.setThemePreset(preset);
    if (saved || !context.mounted) {
      return;
    }
    AppToast.error(context, '保存主题设置失败');
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = selected ? colors.onPrimary : colors.ink;
    final secondaryForeground = selected
        ? colors.onPrimary.withValues(alpha: 0.82)
        : colors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.label}配色',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('theme-${preset.name}'),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceMuted,
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                _PalettePreview(colors: preset.previewColors),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        preset.label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        preset.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryForeground,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SelectionIndicator(
                  selected: selected,
                  foreground: foreground,
                  outline: colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            top: 17,
            child: _SwatchCircle(color: colors[0], size: 38),
          ),
          Positioned(
            left: 17,
            top: 0,
            child: _SwatchCircle(color: colors[1], size: 40),
          ),
          Positioned(
            left: 33,
            top: 22,
            child: _SwatchCircle(color: colors[2], size: 39),
          ),
        ],
      ),
    );
  }
}

class _SwatchCircle extends StatelessWidget {
  const _SwatchCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.appColors.surface.withValues(alpha: 0.72),
          width: 1.5,
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.selected,
    required this.foreground,
    required this.outline,
  });

  final bool selected;
  final Color foreground;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? foreground : outline,
          width: selected ? 0 : 1.8,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 20, color: foreground)
          : null,
    );
  }
}
