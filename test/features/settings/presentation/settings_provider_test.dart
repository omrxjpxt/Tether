import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsNotifier', () {
    test('initializes with default values if no preferences are saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final settings = container.read(appSettingsProvider);
      expect(settings.themeMode, 'system');
      expect(settings.isFirstLaunch, true);
      expect(settings.notificationsEnabled, false);
    });

    test('loads saved preferences from SharedPreferences immediately', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({
          'themeMode': 'dark',
          'isFirstLaunch': false,
          'notificationsEnabled': true,
        }),
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final settings = container.read(appSettingsProvider);
      expect(settings.themeMode, 'dark');
      expect(settings.isFirstLaunch, false);
      expect(settings.notificationsEnabled, true);
    });

    test('updateThemeMode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await container.read(appSettingsProvider.notifier).updateThemeMode('light');

      expect(container.read(appSettingsProvider).themeMode, 'light');
      final savedStr = prefs.getString('app_settings_v1');
      expect(savedStr, contains('"themeMode":"light"'));

      await container.read(appSettingsProvider.notifier).updateThemeMode('dark');
      expect(container.read(appSettingsProvider).themeMode, 'dark');
      expect(prefs.getString('app_settings_v1'), contains('"themeMode":"dark"'));
    });

    test('completeOnboarding sets isFirstLaunch to false and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(container.read(appSettingsProvider).isFirstLaunch, true);

      await container.read(appSettingsProvider.notifier).completeOnboarding();

      expect(container.read(appSettingsProvider).isFirstLaunch, false);
      expect(prefs.getString('app_settings_v1'), contains('"isFirstLaunch":false'));
    });
  });
}
