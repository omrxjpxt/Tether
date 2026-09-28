import 'package:flutter_test/flutter_test.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/habits/domain/services/habit_service.dart';

void main() {
  group('HabitService', () {
    final now = DateTime(2026, 9, 28, 12, 0); // Monday
    final yesterday = now.subtract(const Duration(days: 1));
    final habit = Habit(
      id: '1',
      trigger: 'Wake up',
      action: 'Drink water',
      frequency: HabitFrequency.daily(),
      createdAt: now.subtract(const Duration(days: 10)),
      completedDates: [],
    );

    test('isHabitExpectedOnDate daily', () {
      expect(HabitService.isHabitExpectedOnDate(habit, now), isTrue);
    });

    test('isHabitExpectedOnDate weekdays', () {
      final weekdayHabit = habit.copyWith(frequency: HabitFrequency.weekdays());
      expect(HabitService.isHabitExpectedOnDate(weekdayHabit, now), isTrue); // Monday
      expect(HabitService.isHabitExpectedOnDate(weekdayHabit, now.subtract(const Duration(days: 1))), isFalse); // Sunday
    });

    test('toggleHabitToday adds and removes completion', () {
      var h = HabitService.toggleHabitToday(habit, now);
      expect(HabitService.isHabitCompletedToday(h, now), isTrue);
      h = HabitService.toggleHabitToday(h, now);
      expect(HabitService.isHabitCompletedToday(h, now), isFalse);
    });

    test('currentStreak daily', () {
      // Completed yesterday and today
      final h = habit.copyWith(completedDates: [
        DateUtilsLocal.yesterdayKey(now),
        DateUtilsLocal.todayKey(now),
      ]);
      expect(HabitService.currentStreak(h, now), 2);
    });

    test('currentStreak not completed today uses yesterday', () {
      // Completed day before yesterday and yesterday
      final h = habit.copyWith(completedDates: [
        DateUtilsLocal.dateKey(now.subtract(const Duration(days: 2))),
        DateUtilsLocal.yesterdayKey(now),
      ]);
      expect(HabitService.currentStreak(h, now), 2);
    });

    test('missedYesterday and recoveredToday', () {
      final h1 = habit.copyWith(completedDates: []);
      expect(HabitService.missedYesterday(h1, now), isTrue); // Expected daily, not completed yesterday

      final h2 = h1.copyWith(completedDates: [DateUtilsLocal.todayKey(now)]);
      expect(HabitService.recoveredToday(h2, now), isTrue);
    });

    test('consecutiveMisses', () {
      final h = habit.copyWith(completedDates: [
        DateUtilsLocal.dateKey(now.subtract(const Duration(days: 3))),
      ]);
      // Missed yesterday (day 1) and day before yesterday (day 2)
      expect(HabitService.consecutiveMisses(h, now), 2);
    });
  });
}
