import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';

class FocusService {
  static List<FocusSession> getSessionsForDate(List<FocusSession> sessions, DateTime date) {
    return sessions.where((s) => DateUtilsLocal.isSameLocalDay(s.date, date)).toList();
  }

  static List<FocusSession> getSessionsForDateRange(List<FocusSession> sessions, DateTime start, DateTime end) {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return sessions.where((s) => !s.date.isBefore(rangeStart) && !s.date.isAfter(rangeEnd)).toList();
  }

  static int getTotalDuration(List<FocusSession> sessions) {
    return sessions.fold(0, (total, s) => total + s.durationMinutes);
  }
}
