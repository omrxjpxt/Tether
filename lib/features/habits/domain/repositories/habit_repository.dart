import 'package:tether/features/habits/domain/models/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<void> saveHabits(List<Habit> habits);
  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String id);
  Future<void> clearHabits();
}
