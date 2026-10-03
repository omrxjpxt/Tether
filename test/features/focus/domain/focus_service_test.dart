import 'package:flutter_test/flutter_test.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/focus/domain/services/focus_service.dart';

void main() {
  group('FocusService', () {
    final now = DateTime(2026, 9, 28, 14, 30); // Monday
    final sessions = [
      FocusSession(
        id: '1',
        date: DateTime(2026, 9, 28, 9, 0),
        durationMinutes: 25,
        completed: true,
        createdAt: DateTime(2026, 9, 28, 9, 25),
      ),
      FocusSession(
        id: '2',
        date: DateTime(2026, 9, 28, 15, 0),
        durationMinutes: 50,
        completed: true,
        createdAt: DateTime(2026, 9, 28, 15, 50),
      ),
      FocusSession(
        id: '3',
        date: DateTime(2026, 10, 4, 21, 30), // Sunday late evening
        durationMinutes: 25,
        completed: true,
        createdAt: DateTime(2026, 10, 4, 21, 55),
      ),
      FocusSession(
        id: '4',
        date: DateTime(2026, 10, 5, 8, 0), // Next Monday
        durationMinutes: 25,
        completed: true,
        createdAt: DateTime(2026, 10, 5, 8, 25),
      ),
    ];

    test('getTotalDuration calculates total minutes correctly', () {
      expect(FocusService.getTotalDuration(sessions.sublist(0, 2)), 75);
    });

    test('getSessionsForDate filters correctly for local calendar day', () {
      final mondaySessions = FocusService.getSessionsForDate(sessions, now);
      expect(mondaySessions.length, 2);
      expect(mondaySessions.map((s) => s.id), containsAll(['1', '2']));
    });

    test('getSessionsForDateRange covers full boundary through Sunday night', () {
      final weekStart = DateTime(2026, 9, 28); // Monday
      final weekEnd = DateTime(2026, 10, 4); // Sunday

      final weekSessions = FocusService.getSessionsForDateRange(sessions, weekStart, weekEnd);
      expect(weekSessions.length, 3);
      expect(weekSessions.map((s) => s.id), containsAll(['1', '2', '3']));
      // Next Monday's session (id: 4) should NOT be included
      expect(weekSessions.any((s) => s.id == '4'), isFalse);
    });
  });
}
