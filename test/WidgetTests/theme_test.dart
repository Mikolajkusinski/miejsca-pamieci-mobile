import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo_places_mobile/theme/app_theme.dart';
import 'package:memo_places_mobile/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('light theme matches the web palette', () {
    expect(lightTheme.colorScheme.primary, const Color(0xFF0891B2));
    expect(lightTheme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(lightTheme.colorScheme.surfaceContainerHighest,
        const Color(0xFFF1F5F9));
    expect(lightTheme.colorScheme.outlineVariant, const Color(0xFFE2E8F0));
    expect(lightTheme.colorScheme.onSurface, const Color(0xFF0F172A));
    expect(lightTheme.useMaterial3, isTrue);
  });

  test('dark theme matches the web palette', () {
    expect(darkTheme.colorScheme.primary, const Color(0xFF0891B2));
    expect(darkTheme.colorScheme.surface, const Color(0xFF171717));
    expect(darkTheme.colorScheme.surfaceContainerHighest,
        const Color(0xFF262626));
    expect(darkTheme.colorScheme.outlineVariant, const Color(0xFF404040));
    expect(darkTheme.colorScheme.onSurface, const Color(0xFFFFFFFF));
  });

  group('ThemeProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('defaults to system and cycles system → light → dark → system', () {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
      provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.light);
      provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.dark);
      provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.system);
    });

    test('persists and restores the chosen mode', () async {
      SharedPreferences.setMockInitialValues({});
      ThemeProvider().setThemeMode(ThemeMode.dark);
      // setThemeMode persists asynchronously; let it complete.
      await Future<void>.delayed(Duration.zero);
      expect(await ThemeProvider.loadSavedMode(), ThemeMode.dark);
    });
  });
}
