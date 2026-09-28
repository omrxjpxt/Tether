import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/settings/domain/models/app_settings.dart';
import 'package:tether/features/settings/domain/repositories/settings_repository.dart';

class SharedPrefsSettingsRepository implements SettingsRepository {
  static const String _key = 'app_settings_v1';
  final SharedPreferences _prefs;

  SharedPrefsSettingsRepository(this._prefs);

  @override
  Future<AppSettings> getSettings() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return const AppSettings();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
