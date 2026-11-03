import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appearance preferences', () {
    test('uses stable defaults', () {
      const preferences = AppearancePreferences();

      expect(preferences.mode, AppThemeMode.system);
      expect(preferences.preset, AppThemePreset.indigoM3);
    });

    test('contains every built-in FlexColorScheme preset', () {
      expect(AppThemePreset.values, hasLength(67));
    });

    test('round-trips every current storage value', () {
      for (final preset in AppThemePreset.values) {
        expect(
          AppThemePreset.fromStorage(preset.storageValue),
          preset,
          reason: preset.name,
        );
      }
    });

    test('maps legacy storage names to their previous M3 colors', () {
      expect(AppThemePreset.fromStorage('blue'), AppThemePreset.blueM3);
      expect(AppThemePreset.fromStorage('cyan'), AppThemePreset.cyanM3);
      expect(AppThemePreset.fromStorage('indigo'), AppThemePreset.indigoM3);
      expect(AppThemePreset.fromStorage('teal'), AppThemePreset.tealM3);
      expect(AppThemePreset.fromStorage('green'), AppThemePreset.greenM3);
      expect(AppThemePreset.fromStorage('purple'), AppThemePreset.purpleM3);
      expect(AppThemePreset.fromStorage('pink'), AppThemePreset.pinkM3);
      expect(AppThemePreset.fromStorage('orange'), AppThemePreset.orangeM3);
    });

    test('distinguishes prefixed classic schemes from legacy aliases', () {
      expect(AppThemePreset.fromStorage('scheme:blue'), AppThemePreset.blue);
      expect(
        AppThemePreset.fromStorage('scheme:indigo'),
        AppThemePreset.indigo,
      );
      expect(AppThemePreset.fromStorage('scheme:green'), AppThemePreset.green);
    });

    test('falls back for unknown or missing storage values', () {
      expect(AppThemeMode.fromStorage('sepia'), AppThemeMode.system);
      expect(AppThemeMode.fromStorage(null), AppThemeMode.system);
      expect(AppThemePreset.fromStorage('unknown'), AppThemePreset.indigoM3);
      expect(
        AppThemePreset.fromStorage('scheme:custom'),
        AppThemePreset.indigoM3,
      );
      expect(AppThemePreset.fromStorage(null), AppThemePreset.indigoM3);
    });

    test('copyWith replaces only requested values', () {
      const original = AppearancePreferences(
        mode: AppThemeMode.dark,
        preset: AppThemePreset.greenM3,
      );

      final updated = original.copyWith(preset: AppThemePreset.orangeM3);

      expect(updated.mode, AppThemeMode.dark);
      expect(updated.preset, AppThemePreset.orangeM3);
      expect(original.preset, AppThemePreset.greenM3);
    });
  });
}
