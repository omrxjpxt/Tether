import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/core/services/notification_providers.dart';
import 'package:tether/core/services/notification_service.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/settings/presentation/screens/settings_screen.dart';

class FakeNotificationService implements NotificationService {
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen renders all sections and switches theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify top headers
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('NOTIFICATIONS'), findsOneWidget);

    // Verify Appearance options
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    // Tap "Dark"
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Verify dark mode is persisted
    expect(prefs.getString('app_settings_v1'), contains('"themeMode":"dark"'));

    // Scroll to bottom to verify DATA & BACKUP and ABOUT
    await tester.scrollUntilVisible(find.text('ABOUT'), 100);
    await tester.pumpAndSettle();

    expect(find.text('DATA & BACKUP'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
  });
}
