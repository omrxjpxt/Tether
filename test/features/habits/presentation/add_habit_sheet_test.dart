import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/core/services/notification_providers.dart';
import 'package:tether/core/services/notification_service.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/habits/presentation/widgets/add_habit_sheet.dart';

class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> isPermissionGranted() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleHabitReminder(Habit habit) async {}
  @override
  Future<void> cancelHabitReminder(String habitId) async {}
  @override
  Future<void> rescheduleAllHabitReminders(List<Habit> habits) async {}
  @override
  Future<void> handleHabitCompletionChanged(Habit habit, bool isCompletedToday) async {}
}

void main() {
  testWidgets('AddHabitSheet renders fields and reminder section on native', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddHabitSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New habit'), findsOneWidget);
    expect(find.text('AFTER I'), findsOneWidget);
    expect(find.text('I WILL'), findsOneWidget);
    expect(find.text('FREQUENCY'), findsOneWidget);
    expect(find.text('REMINDER'), findsOneWidget);
    // On native VM test environment (kIsWeb is false)
    expect(find.text('Set a daily reminder'), findsOneWidget);
    expect(find.text('Save habit'), findsOneWidget);
  });
}
