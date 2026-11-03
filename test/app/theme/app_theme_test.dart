import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppTheme', () {
    test('builds matched light and dark themes for every preset', () {
      for (final preset in AppThemePreset.values) {
        final light = AppTheme.light(preset);
        final dark = AppTheme.dark(preset);

        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(light.extension<AppColors>(), isNotNull);
        expect(dark.extension<AppColors>(), isNotNull);
        expect(
          light.scaffoldBackgroundColor,
          isNot(dark.scaffoldBackgroundColor),
        );
      }
    });

    test('maps every preset to a distinct FlexScheme value', () {
      final schemes = AppThemePreset.values
          .map((preset) => preset.flexScheme)
          .toSet();

      expect(schemes, hasLength(AppThemePreset.values.length));
      expect(AppThemePreset.values, hasLength(67));
      for (final preset in AppThemePreset.values) {
        expect(preset.flexScheme.name, preset.name);
      }
    });

    test('exposes labels, descriptions and three preview colors', () {
      for (final preset in AppThemePreset.values) {
        expect(preset.label, isNotEmpty);
        expect(preset.description, isNotEmpty);
        expect(preset.previewColors, hasLength(3));
      }
    });

    test('maps persisted modes to Material theme modes', () {
      expect(AppThemeMode.system.materialMode, ThemeMode.system);
      expect(AppThemeMode.light.materialMode, ThemeMode.light);
      expect(AppThemeMode.dark.materialMode, ThemeMode.dark);
    });
  });
}
