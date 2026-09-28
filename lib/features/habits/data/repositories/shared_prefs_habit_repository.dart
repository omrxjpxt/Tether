import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/repositories/habit_repository.dart';

class SharedPrefsHabitRepository implements HabitRepository {
  static const String _key = 'habits_v1';
  final SharedPreferences _prefs;

  SharedPrefsHabitRepository(this._prefs);

  @override
  Future<List<Habit>> getHabits() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) {
        try {
          return Habit.fromJson(json as Map<String, dynamic>);
        } catch (_) {
          return null; // Skip malformed records
        }
      }).whereType<Habit>().toList();
    } catch (e) {
      // Handle corrupted JSON by returning empty list
      return [];
    }
  }

  @override
  Future<void> saveHabits(List<Habit> habits) async {
    final jsonList = habits.map((h) => h.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(jsonList));
  }

  @override
  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      habits[index] = habit;
      await saveHabits(habits);
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == id);
    await saveHabits(habits);
  }

  @override
  Future<void> clearHabits() async {
    await _prefs.remove(_key);
  }
}
