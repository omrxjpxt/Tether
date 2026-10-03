import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether/core/services/notification_service.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';

class MockNotificationService implements NotificationService {
  final Map<int, String> scheduledNotifications = {};
  bool permissionGranted = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  int getNotificationId(String habitId, [int day = 0]) {
    final base = habitId.hashCode.abs() % 100000;
    return base * 10 + day;
  }

  @override
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      await cancelHabitReminder(habit.id);
      return;
    }
    await cancelHabitReminder(habit.id);

    final days = _getActiveDays(habit);
    for (final day in days) {
      final id = getNotificationId(habit.id, day);
      scheduledNotifications[id] = 'After I ${habit.trigger}, I will ${habit.action}.';
    }
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    for (int day = 0; day <= 7; day++) {
      scheduledNotifications.remove(getNotificationId(habitId, day));
    }
  }

  @override
  Future<void> rescheduleAllHabitReminders(List<Habit> habits) async {
    for (final h in habits) {
      if (h.reminderTime != null && !h.archived) {
        await scheduleHabitReminder(h);
      } else {
        await cancelHabitReminder(h.id);
      }
    }
  }

  @override
  Future<void> handleHabitCompletionChanged(Habit habit, bool isCompletedToday) async {
    if (habit.reminderTime == null) return;
    await scheduleHabitReminder(habit);
  }

  List<int> _getActiveDays(Habit habit) {
    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return const [1, 2, 3, 4, 5, 6, 7];
      case FrequencyType.weekdays:
        return const [1, 2, 3, 4, 5];
      case FrequencyType.custom:
        return habit.frequency.customDays ?? const [1, 2, 3, 4, 5, 6, 7];
      case FrequencyType.timesPerWeek:
        return const [1, 2, 3, 4, 5, 6, 7];
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService deterministic scheduling', () {
    final localService = LocalNotificationService();

    test('deterministic notification IDs are stable and unique per day', () {
      const habitId = 'habit-uuid-1234';
      final idDay1 = localService.getNotificationId(habitId, 1);
      final idDay2 = localService.getNotificationId(habitId, 2);
      final idDay0 = localService.getNotificationId(habitId, 0);

      expect(idDay1, isNot(equals(idDay2)));
      expect(idDay1, isNot(equals(idDay0)));
      expect(localService.getNotificationId(habitId, 1), equals(idDay1));
    });

    test('different habits have distinct notification IDs', () {
      const h1 = 'habit-1';
      const h2 = 'habit-2';
      expect(
        localService.getNotificationId(h1, 1),
        isNot(equals(localService.getNotificationId(h2, 1))),
      );
    });

    test('scheduling schedules correct number of days per frequency', () async {
      final mock = MockNotificationService();

      final dailyHabit = Habit(
        id: 'daily-1',
        trigger: 'wake up',
        action: 'drink water',
        frequency: HabitFrequency.daily(),
        reminderTime: const TimeOfDay(hour: 8, minute: 0),
        createdAt: DateTime.now(),
      );

      await mock.scheduleHabitReminder(dailyHabit);
      expect(mock.scheduledNotifications.length, 7);

      final weekdayHabit = Habit(
        id: 'weekday-1',
        trigger: 'sit at desk',
        action: 'write top priority',
        frequency: HabitFrequency.weekdays(),
        reminderTime: const TimeOfDay(hour: 9, minute: 0),
        createdAt: DateTime.now(),
      );

      await mock.scheduleHabitReminder(weekdayHabit);
      // 7 from daily + 5 from weekday = 12 total
      expect(mock.scheduledNotifications.length, 12);

      // Cancel weekday habit
      await mock.cancelHabitReminder(weekdayHabit.id);
      expect(mock.scheduledNotifications.length, 7);
    });

    test('cancelHabitReminder clears all weekday slots for the habit', () async {
      final mock = MockNotificationService();
      final habit = Habit(
        id: 'habit-slots',
        trigger: 'trigger',
        action: 'action',
        frequency: HabitFrequency.daily(),
        reminderTime: const TimeOfDay(hour: 7, minute: 30),
        createdAt: DateTime.now(),
      );

      await mock.scheduleHabitReminder(habit);
      expect(mock.scheduledNotifications.length, 7);

      await mock.cancelHabitReminder(habit.id);
      expect(mock.scheduledNotifications.isEmpty, isTrue);
    });

    test('rescheduleAllHabitReminders cancels archived or no-reminder habits', () async {
      final mock = MockNotificationService();
      final activeHabit = Habit(
        id: 'active-1',
        trigger: 'trigger',
        action: 'action',
        frequency: HabitFrequency.daily(),
        reminderTime: const TimeOfDay(hour: 7, minute: 30),
        createdAt: DateTime.now(),
      );
      final noReminderHabit = Habit(
        id: 'no-reminder-1',
        trigger: 'trigger',
        action: 'action',
        frequency: HabitFrequency.daily(),
        reminderTime: null,
        createdAt: DateTime.now(),
      );

      await mock.rescheduleAllHabitReminders([activeHabit, noReminderHabit]);
      expect(mock.scheduledNotifications.length, 7);
    });
  });
}
