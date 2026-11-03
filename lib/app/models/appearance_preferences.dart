/// 应用主题的明暗模式。
enum AppThemeMode {
  /// 跟随系统外观。
  system,

  /// 始终使用浅色主题。
  light,

  /// 始终使用深色主题。
  dark;

  /// 从持久化字符串恢复模式；无法识别时返回跟随系统。
  static AppThemeMode fromStorage(String? value) {
    for (final mode in values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return system;
  }
}

/// FlexColorScheme 提供的全部可直接使用配色，不含 `custom` 占位项。
enum AppThemePreset {
  material,
  materialHc,
  blue,
  indigo,
  hippieBlue,
  aquaBlue,
  brandBlue,
  deepBlue,
  sakura,
  mandyRed,
  red,
  redWine,
  purpleBrown,
  green,
  money,
  jungle,
  greyLaw,
  wasabi,
  gold,
  mango,
  amber,
  vesuviusBurn,
  deepPurple,
  ebonyClay,
  barossa,
  shark,
  bigStone,
  damask,
  bahamaBlue,
  mallardGreen,
  espresso,
  outerSpace,
  blueWhale,
  sanJuanBlue,
  rosewood,
  blumineBlue,
  flutterDash,
  materialBaseline,
  verdunHemlock,
  dellGenoa,
  redM3,
  pinkM3,
  purpleM3,
  indigoM3,
  blueM3,
  cyanM3,
  tealM3,
  greenM3,
  limeM3,
  yellowM3,
  orangeM3,
  deepOrangeM3,
  blackWhite,
  greys,
  sepia,
  shadBlue,
  shadGray,
  shadGreen,
  shadNeutral,
  shadOrange,
  shadRed,
  shadRose,
  shadSlate,
  shadStone,
  shadViolet,
  shadYellow,
  shadZinc;

  static const String _storagePrefix = 'scheme:';

  /// 当前版本写入数据库时使用的稳定值。
  String get storageValue => '$_storagePrefix$name';

  /// 从持久化字符串恢复配色，并兼容早期未加前缀的名称。
  static AppThemePreset fromStorage(String? value) {
    if (value == null) {
      return indigoM3;
    }
    if (value.startsWith(_storagePrefix)) {
      return _byName(value.substring(_storagePrefix.length)) ?? indigoM3;
    }
    final legacy = switch (value) {
      'blue' => blueM3,
      'cyan' => cyanM3,
      'indigo' => indigoM3,
      'teal' => tealM3,
      'green' => greenM3,
      'purple' => purpleM3,
      'pink' => pinkM3,
      'orange' => orangeM3,
      _ => null,
    };
    return legacy ?? _byName(value) ?? indigoM3;
  }

  static AppThemePreset? _byName(String value) {
    for (final preset in values) {
      if (preset.name == value) {
        return preset;
      }
    }
    return null;
  }
}

/// 可持久化的主题外观偏好。
final class AppearancePreferences {
  const AppearancePreferences({
    this.mode = AppThemeMode.system,
    this.preset = AppThemePreset.indigoM3,
  });

  /// 当前明暗模式。
  final AppThemeMode mode;

  /// 当前配色预设。
  final AppThemePreset preset;

  /// 返回更新后的不可变外观设置快照。
  AppearancePreferences copyWith({AppThemeMode? mode, AppThemePreset? preset}) {
    return AppearancePreferences(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
    );
  }
}
