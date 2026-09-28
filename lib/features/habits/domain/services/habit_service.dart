import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';

class HabitService {
  static bool isHabitCompletedToday(Habit habit, DateTime now) {
    return habit.completedDates.contains(DateUtilsLocal.todayKey(now));
  }

  static bool isHabitCompletedOnDate(Habit habit, DateTime date) {
    return habit.completedDates.contains(DateUtilsLocal.dateKey(date));
  }

  static bool isHabitExpectedOnDate(Habit habit, DateTime date) {
    final createdAt = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate.isBefore(createdAt)) return false;

    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekdays:
        return DateUtilsLocal.isWeekday(date);
      case FrequencyType.custom:
        return habit.frequency.customDays?.contains(date.weekday) ?? false;
      case FrequencyType.timesPerWeek:
        return false; // No specific day is rigidly expected.
    }
  }

  static Habit toggleHabitToday(Habit habit, DateTime now) {
    final key = DateUtilsLocal.todayKey(now);
    final completed = List<String>.from(habit.completedDates);
    if (completed.contains(key)) {
      completed.remove(key);
    } else {
      completed.add(key);
    }
    return habit.copyWith(completedDates: completed);
  }

  static int currentStreak(Habit habit, DateTime now) {
    bool todayCompleted = isHabitCompletedToday(habit, now);
    DateTime currentDate = todayCompleted ? now : now.subtract(const Duration(days: 1));
    
    int streak = 0;
    while (true) {
      if (currentDate.isBefore(habit.createdAt) && !DateUtilsLocal.isSameLocalDay(currentDate, habit.createdAt)) {
        break;
      }

      bool isCompleted = isHabitCompletedOnDate(habit, currentDate);
      bool isExpected = isHabitExpectedOnDate(habit, currentDate);

      if (isCompleted) {
        streak++;
      } else {
        if (habit.frequency.type == FrequencyType.timesPerWeek) {
          // Check if the week of currentDate met the target.
          final start = DateUtilsLocal.startOfWeek(currentDate);
          final end = DateUtilsLocal.endOfWeek(currentDate);
          
          // Count completions in this week up to 'currentDate' or the whole week?
          // If the week is completely in the past, and we failed the target, we break.
          // If we are currently in this week, and we can still meet the target, we don't break.
          int weekCompletions = 0;
          for (int i = 0; i <= 6; i++) {
            if (isHabitCompletedOnDate(habit, start.add(Duration(days: i)))) {
              weekCompletions++;
            }
          }
          final target = habit.frequency.timesPerWeek ?? 1;
          
          // If the week is over and target not met, break streak.
          if (currentDate.weekday == DateTime.sunday && weekCompletions < target) {
            break;
          }
        } else if (isExpected) {
          break;
        }
      }
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int longestStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;
    int maxStreak = 0;
    for (String dateStr in habit.completedDates) {
      final date = DateUtilsLocal.parseDateKey(dateStr);
      final streak = currentStreak(habit, date);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }
    return maxStreak;
  }

  static bool missedYesterday(Habit habit, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.isBefore(habit.createdAt) && !DateUtilsLocal.isSameLocalDay(yesterday, habit.createdAt)) {
      return false;
    }
    return isHabitExpectedOnDate(habit, yesterday) && !isHabitCompletedOnDate(habit, yesterday);
  }

  static bool recoveredToday(Habit habit, DateTime now) {
    return missedYesterday(habit, now) && isHabitCompletedToday(habit, now);
  }

  static int consecutiveMisses(Habit habit, DateTime now) {
    int misses = 0;
    DateTime currentDate = now.subtract(const Duration(days: 1));
    while (true) {
      if (currentDate.isBefore(habit.createdAt) && !DateUtilsLocal.isSameLocalDay(currentDate, habit.createdAt)) {
        break;
      }
      if (isHabitExpectedOnDate(habit, currentDate)) {
        if (!isHabitCompletedOnDate(habit, currentDate)) {
          misses++;
        } else {
          break;
        }
      }
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    return misses;
  }

  static int actualCompletions(Habit habit, DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (isHabitCompletedOnDate(habit, current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  static int expectedCompletions(Habit habit, DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (isHabitExpectedOnDate(habit, current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    // Handle timesPerWeek roughly by number of weeks
    if (habit.frequency.type == FrequencyType.timesPerWeek) {
      final days = DateUtilsLocal.daysBetweenLocalDates(start, end) + 1;
      final weeks = days / 7.0;
      return (weeks * (habit.frequency.timesPerWeek ?? 1)).round();
    }
    return count;
  }

  static double completionRate(Habit habit, DateTime start, DateTime end) {
    final expected = expectedCompletions(habit, start, end);
    if (expected == 0) return 1.0;
    final actual = actualCompletions(habit, start, end);
    return actual / expected;
  }

  static double weeklyCompletionRate(Habit habit, DateTime dateInWeek) {
    final start = DateUtilsLocal.startOfWeek(dateInWeek);
    final end = DateUtilsLocal.endOfWeek(dateInWeek);
    return completionRate(habit, start, end);
  }

  static List<bool> last7Days(Habit habit, DateTime now) {
    final result = <bool>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      result.add(isHabitCompletedOnDate(habit, date));
    }
    return result;
  }
}
