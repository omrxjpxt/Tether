import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
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

  @override
  Future<List<FocusSession>> getFocusSessions() async {
    final jsonString = _prefs.getString('focus_sessions_v1');
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => FocusSession.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _prefs.setString('focus_sessions_v1', jsonEncode(jsonList));
  }

  @override
  Future<void> addFocusSession(FocusSession session) async {
    final sessions = await getFocusSessions();
    sessions.add(session);
    await saveFocusSessions(sessions);
  }
}
