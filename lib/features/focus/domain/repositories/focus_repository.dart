import 'package:tether/features/focus/domain/models/daily_focus.dart';

abstract class FocusRepository {
  Future<DailyFocus?> getDailyFocus(String dateKey);
  Future<void> saveDailyFocus(DailyFocus focus);
  Future<void> deleteDailyFocus(String dateKey);
}
