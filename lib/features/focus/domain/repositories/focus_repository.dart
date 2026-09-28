import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';

abstract class FocusRepository {
  Future<DailyFocus?> getDailyFocus(String dateKey);
  Future<void> saveDailyFocus(DailyFocus focus);
  Future<void> deleteDailyFocus(String dateKey);
  
  Future<List<FocusSession>> getFocusSessions();
  Future<void> saveFocusSessions(List<FocusSession> sessions);
  Future<void> addFocusSession(FocusSession session);
}
