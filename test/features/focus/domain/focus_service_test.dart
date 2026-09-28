import 'package:flutter_test/flutter_test.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/focus/domain/services/focus_service.dart';

void main() {
  test('FocusService calculates total duration', () {
    final sessions = [
      FocusSession(id: '1', date: DateTime.now(), durationMinutes: 25, completed: true, createdAt: DateTime.now()),
      FocusSession(id: '2', date: DateTime.now(), durationMinutes: 50, completed: true, createdAt: DateTime.now()),
    ];

    expect(FocusService.getTotalDuration(sessions), 75);
  });
}
