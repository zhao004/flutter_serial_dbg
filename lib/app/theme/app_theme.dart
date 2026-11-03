import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/appearance_preferences.dart';

/// 应用主题模式与 Material 模式的映射。
extension AppThemeModeMaterial on AppThemeMode {
  /// 设置页展示名称。
  String get label {
    return switch (this) {
      AppThemeMode.system => '跟随系统',
      AppThemeMode.light => '浅色',
      AppThemeMode.dark => '深色',
    };
  }

  /// 返回 MaterialApp 使用的主题模式。
  ThemeMode get materialMode {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}

const Map<AppThemePreset, String> _themePresetLabels = <AppThemePreset, String>{
  AppThemePreset.material: 'Material 经典',
  AppThemePreset.materialHc: 'Material 高对比',
  AppThemePreset.blue: '经典蓝',
  AppThemePreset.indigo: '经典靛',
  AppThemePreset.hippieBlue: '嬉皮蓝',
  AppThemePreset.aquaBlue: '水蓝',
  AppThemePreset.brandBlue: '品牌蓝',
  AppThemePreset.deepBlue: '深海蓝',
  AppThemePreset.sakura: '樱花',
  AppThemePreset.mandyRed: '曼迪红',
  AppThemePreset.red: '经典红',
  AppThemePreset.redWine: '酒红',
  AppThemePreset.purpleBrown: '紫褐',
  AppThemePreset.green: '经典绿',
  AppThemePreset.money: '财富绿',
  AppThemePreset.jungle: '丛林绿',
  AppThemePreset.greyLaw: '灰律',
  AppThemePreset.wasabi: '芥末绿',
  AppThemePreset.gold: '日落金',
  AppThemePreset.mango: '芒果',
  AppThemePreset.amber: '琥珀',
  AppThemePreset.vesuviusBurn: '火山橙',
  AppThemePreset.deepPurple: '深紫',
  AppThemePreset.ebonyClay: '乌木灰',
  AppThemePreset.barossa: '巴罗萨',
  AppThemePreset.shark: '鲨鱼灰',
  AppThemePreset.bigStone: '大石蓝',
  AppThemePreset.damask: '锦缎红',
  AppThemePreset.bahamaBlue: '巴哈马蓝',
  AppThemePreset.mallardGreen: '野鸭绿',
  AppThemePreset.espresso: '浓缩棕',
  AppThemePreset.outerSpace: '外太空',
  AppThemePreset.blueWhale: '蓝鲸',
  AppThemePreset.sanJuanBlue: '圣胡安蓝',
  AppThemePreset.rosewood: '红木',
  AppThemePreset.blumineBlue: '蓝花蓝',
  AppThemePreset.flutterDash: 'Flutter Dash',
  AppThemePreset.materialBaseline: 'Material 基线',
  AppThemePreset.verdunHemlock: '凡尔登绿',
  AppThemePreset.dellGenoa: '戴尔绿',
  AppThemePreset.redM3: 'M3 红',
  AppThemePreset.pinkM3: '樱粉',
  AppThemePreset.purpleM3: '紫藤',
  AppThemePreset.indigoM3: '靛蓝',
  AppThemePreset.blueM3: '海蓝',
  AppThemePreset.cyanM3: '晴青',
  AppThemePreset.tealM3: '青绿',
  AppThemePreset.greenM3: '森绿',
  AppThemePreset.limeM3: 'M3 青柠',
  AppThemePreset.yellowM3: 'M3 黄',
  AppThemePreset.orangeM3: '暖橙',
  AppThemePreset.deepOrangeM3: 'M3 深橙',
  AppThemePreset.blackWhite: '黑白',
  AppThemePreset.greys: '灰度',
  AppThemePreset.sepia: '棕褐',
  AppThemePreset.shadBlue: 'Shad 蓝',
  AppThemePreset.shadGray: 'Shad 灰',
  AppThemePreset.shadGreen: 'Shad 绿',
  AppThemePreset.shadNeutral: 'Shad 中性',
  AppThemePreset.shadOrange: 'Shad 橙',
  AppThemePreset.shadRed: 'Shad 红',
  AppThemePreset.shadRose: 'Shad 玫红',
  AppThemePreset.shadSlate: 'Shad 石板灰',
  AppThemePreset.shadStone: 'Shad 石色',
  AppThemePreset.shadViolet: 'Shad 紫',
  AppThemePreset.shadYellow: 'Shad 黄',
  AppThemePreset.shadZinc: 'Shad 锌灰',
};

/// 应用配色预设的展示信息与 FlexColorScheme 映射。
extension AppThemePresetTheme on AppThemePreset {
  /// 设置页展示名称。
  String get label => _themePresetLabels[this] ?? flexScheme.data.name;

  /// 设置页展示说明。
  String get description {
    if (this == AppThemePreset.materialBaseline) {
      return '贴近 Material 3 默认色彩，适合作为稳定对照';
    }
    if (this == AppThemePreset.material) {
      return 'Material 经典配色，层级清晰';
    }
    if (this == AppThemePreset.materialHc) {
      return 'Material 高对比配色，增强内容可读性';
    }
    if (this == AppThemePreset.flutterDash) {
      return 'Flutter 品牌色延伸的明暗主题';
    }
    if (this == AppThemePreset.blackWhite ||
        this == AppThemePreset.greys ||
        this == AppThemePreset.sepia) {
      return '低饱和中性配色，突出内容与状态层级';
    }
    if (name.startsWith('shad')) {
      return 'Shadcn 风格配色，适合低饱和工作界面';
    }
    if (name.endsWith('M3')) {
      return 'Material 3 标准色调，明暗层级清晰';
    }
    return 'FlexColorScheme 经典配色，提供匹配的明暗主题';
  }

  /// 对应的 FlexColorScheme 内置配色。
  FlexScheme get flexScheme => FlexScheme.values.byName(name);

  /// 设置页色板预览使用的三种品牌色。
  List<Color> get previewColors {
    final colors = flexScheme.colors(Brightness.light);
    return <Color>[colors.primary, colors.secondary, colors.tertiary];
  }
}

/// 应用内除 Material 角色色之外的语义颜色。
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.onPrimary,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.selectedBorder,
    required this.disabledFill,
    required this.mutedIcon,
    required this.headerSurface,
    required this.barrier,
    required this.receive,
    required this.primaryGradient,
    required this.pageGradient,
    required this.shadow,
    required this.decorationPrimary,
    required this.decorationLight,
    required this.decorationLine,
    required this.illustrationShadow,
    required this.illustrationLight,
    required this.illustrationMid,
    required this.illustrationLightest,
    required this.illustrationFold,
    required this.illustrationOutline,
  });

  /// 根据 Material 配色和亮度生成完整语义色。
  factory AppColors.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final success = isDark ? const Color(0xFF70E29A) : const Color(0xFF168A45);
    final successSoft = isDark
        ? const Color(0xFF123D25)
        : const Color(0xFFE7F8ED);
    final warning = isDark ? const Color(0xFFFFCC7A) : const Color(0xFFB06400);
    final warningSoft = isDark
        ? const Color(0xFF493113)
        : const Color(0xFFFFF2DD);

    return AppColors(
      background: scheme.surface,
      surface: scheme.surfaceContainerLowest,
      surfaceMuted: scheme.surfaceContainerLow,
      ink: scheme.onSurface,
      inkMuted: scheme.onSurfaceVariant,
      outline: scheme.outlineVariant,
      primary: scheme.primary,
      primaryDeep: scheme.secondary,
      primarySoft: scheme.primaryContainer,
      onPrimary: scheme.onPrimary,
      success: success,
      successSoft: successSoft,
      warning: warning,
      warningSoft: warningSoft,
      error: scheme.error,
      errorSoft: scheme.errorContainer,
      selectedBorder: scheme.primary.withValues(alpha: 0.42),
      disabledFill: scheme.onSurface.withValues(alpha: 0.12),
      mutedIcon: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      headerSurface: scheme.surfaceContainerHighest.withValues(alpha: 0.88),
      barrier: scheme.scrim.withValues(alpha: 0.46),
      receive: isDark ? const Color(0xFF62D8CC) : const Color(0xFF087F78),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[scheme.primary, scheme.secondary],
      ),
      pageGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            scheme.surface,
          ),
          scheme.surface,
        ],
        stops: const <double>[0, 0.42],
      ),
      shadow: scheme.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
      decorationPrimary: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.2),
      decorationLight: scheme.onSurface.withValues(alpha: isDark ? 0.04 : 0.1),
      decorationLine: scheme.onSurface.withValues(alpha: 0.1),
      illustrationShadow: scheme.shadow.withValues(alpha: 0.12),
      illustrationLight: scheme.surfaceContainerHigh,
      illustrationMid: scheme.surfaceContainerHighest,
      illustrationLightest: scheme.surfaceContainerLow,
      illustrationFold: scheme.surfaceContainer,
      illustrationOutline: scheme.outlineVariant,
    );
  }

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color onPrimary;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color selectedBorder;
  final Color disabledFill;
  final Color mutedIcon;
  final Color headerSurface;
  final Color barrier;
  final Color receive;
  final LinearGradient primaryGradient;
  final LinearGradient pageGradient;
  final Color shadow;
  final Color decorationPrimary;
  final Color decorationLight;
  final Color decorationLine;
  final Color illustrationShadow;
  final Color illustrationLight;
  final Color illustrationMid;
  final Color illustrationLightest;
  final Color illustrationFold;
  final Color illustrationOutline;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? outline,
    Color? primary,
    Color? primaryDeep,
    Color? primarySoft,
    Color? onPrimary,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? selectedBorder,
    Color? disabledFill,
    Color? mutedIcon,
    Color? headerSurface,
    Color? barrier,
    Color? receive,
    LinearGradient? primaryGradient,
    LinearGradient? pageGradient,
    Color? shadow,
    Color? decorationPrimary,
    Color? decorationLight,
    Color? decorationLine,
    Color? illustrationShadow,
    Color? illustrationLight,
    Color? illustrationMid,
    Color? illustrationLightest,
    Color? illustrationFold,
    Color? illustrationOutline,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      outline: outline ?? this.outline,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      disabledFill: disabledFill ?? this.disabledFill,
      mutedIcon: mutedIcon ?? this.mutedIcon,
      headerSurface: headerSurface ?? this.headerSurface,
      barrier: barrier ?? this.barrier,
      receive: receive ?? this.receive,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      pageGradient: pageGradient ?? this.pageGradient,
      shadow: shadow ?? this.shadow,
      decorationPrimary: decorationPrimary ?? this.decorationPrimary,
      decorationLight: decorationLight ?? this.decorationLight,
      decorationLine: decorationLine ?? this.decorationLine,
      illustrationShadow: illustrationShadow ?? this.illustrationShadow,
      illustrationLight: illustrationLight ?? this.illustrationLight,
      illustrationMid: illustrationMid ?? this.illustrationMid,
      illustrationLightest: illustrationLightest ?? this.illustrationLightest,
      illustrationFold: illustrationFold ?? this.illustrationFold,
      illustrationOutline: illustrationOutline ?? this.illustrationOutline,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      disabledFill: Color.lerp(disabledFill, other.disabledFill, t)!,
      mutedIcon: Color.lerp(mutedIcon, other.mutedIcon, t)!,
      headerSurface: Color.lerp(headerSurface, other.headerSurface, t)!,
      barrier: Color.lerp(barrier, other.barrier, t)!,
      receive: Color.lerp(receive, other.receive, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      pageGradient: LinearGradient.lerp(pageGradient, other.pageGradient, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      decorationPrimary: Color.lerp(
        decorationPrimary,
        other.decorationPrimary,
        t,
      )!,
      decorationLight: Color.lerp(decorationLight, other.decorationLight, t)!,
      decorationLine: Color.lerp(decorationLine, other.decorationLine, t)!,
      illustrationShadow: Color.lerp(
        illustrationShadow,
        other.illustrationShadow,
        t,
      )!,
      illustrationLight: Color.lerp(
        illustrationLight,
        other.illustrationLight,
        t,
      )!,
      illustrationMid: Color.lerp(illustrationMid, other.illustrationMid, t)!,
      illustrationLightest: Color.lerp(
        illustrationLightest,
        other.illustrationLightest,
        t,
      )!,
      illustrationFold: Color.lerp(
        illustrationFold,
        other.illustrationFold,
        t,
      )!,
      illustrationOutline: Color.lerp(
        illustrationOutline,
        other.illustrationOutline,
        t,
      )!,
    );
  }
}

/// 在 Widget 中读取应用语义色。
extension AppThemeContext on BuildContext {
  /// 当前主题的扩展语义色；缺失时使用当前 ColorScheme 即时推导。
  AppColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        AppColors.fromScheme(theme.colorScheme);
  }
}

/// SerialDbg 使用的 FlexColorScheme Material 3 主题。
abstract final class AppTheme {
  /// 构造指定配色预设的浅色主题。
  static ThemeData light(AppThemePreset preset) {
    return _build(preset, Brightness.light);
  }

  /// 构造指定配色预设的深色主题。
  static ThemeData dark(AppThemePreset preset) {
    return _build(preset, Brightness.dark);
  }

  /// 返回随当前主题亮度变化的系统栏样式。
  static SystemUiOverlayStyle systemOverlayStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _build(AppThemePreset preset, Brightness brightness) {
    final base = brightness == Brightness.light
        ? FlexThemeData.light(
            scheme: preset.flexScheme,
            surfaceMode: FlexSurfaceMode.level,
            blendLevel: 4,
          )
        : FlexThemeData.dark(
            scheme: preset.flexScheme,
            surfaceMode: FlexSurfaceMode.level,
            blendLevel: 6,
          );
    final scheme = base.colorScheme;
    final colors = AppColors.fromScheme(scheme);

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.textTheme.copyWith(
        headlineSmall: TextStyle(
          color: colors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: colors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: colors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 0,
        ),
        titleSmall: TextStyle(
          color: colors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: colors.ink,
          fontSize: 15,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: colors.ink,
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          color: colors.inkMuted,
          fontSize: 12,
          height: 1.4,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: colors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          color: colors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: colors.inkMuted.withValues(alpha: 0.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        constraints: const BoxConstraints(minHeight: 44),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.outline),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: colors.outline, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent;
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size.square(40),
          maximumSize: const Size.square(44),
          padding: const EdgeInsets.all(8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryDeep,
          minimumSize: const Size(0, 46),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        modalBarrierColor: colors.barrier,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.barrier,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.32),
        selectionHandleColor: colors.primary,
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
