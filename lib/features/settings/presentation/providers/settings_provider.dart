import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:tether/features/settings/domain/models/app_settings.dart';
import 'package:tether/features/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsSettingsRepository(prefs);
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends Notifier<AppSettings> {
  late SettingsRepository _repository;

  @override
  AppSettings build() {
    _repository = ref.watch(settingsRepositoryProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString('app_settings_v1');
    if (jsonString != null) {
      try {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      } catch (_) {}
    }
    return const AppSettings();
  }

  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    state = updated;
    await _repository.saveSettings(updated);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _repository.saveSettings(updated);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(isFirstLaunch: false);
    state = updated;
    await _repository.saveSettings(updated);
  }

  Future<void> reload() async {
    final loaded = await _repository.getSettings();
    state = loaded;
  }
}
