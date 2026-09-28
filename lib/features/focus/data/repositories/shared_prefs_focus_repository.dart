import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/repositories/focus_repository.dart';

class SharedPrefsFocusRepository implements FocusRepository {
  final SharedPreferences _prefs;
  static const _prefix = 'daily_focus_v1_';

  SharedPrefsFocusRepository(this._prefs);

  @override
  Future<DailyFocus?> getDailyFocus(String dateKey) async {
    final jsonString = _prefs.getString('$_prefix$dateKey');
    if (jsonString == null) return null;
    try {
      return DailyFocus.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDailyFocus(DailyFocus focus) async {
    await _prefs.setString('$_prefix${focus.dateKey}', jsonEncode(focus.toJson()));
  }

  @override
  Future<void> deleteDailyFocus(String dateKey) async {
    await _prefs.remove('$_prefix$dateKey');
  }
}
