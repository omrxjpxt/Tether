import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/data/repositories/shared_prefs_habit_repository.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';

void main() {
  group('SharedPrefsHabitRepository', () {
    late SharedPrefsHabitRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getHabits returns empty when no data', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPrefsHabitRepository(prefs);
      final habits = await repository.getHabits();
      expect(habits, isEmpty);
    });

    test('getHabits ignores corrupted json gracefully', () async {
      SharedPreferences.setMockInitialValues({'habits_v1': 'invalid-json'});
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPrefsHabitRepository(prefs);
      final habits = await repository.getHabits();
      expect(habits, isEmpty);
    });

    test('saveHabits and getHabits work correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPrefsHabitRepository(prefs);
      
      final habit = Habit(
        id: '1',
        trigger: 'Test',
        action: 'Test action',
        frequency: HabitFrequency.daily(),
        createdAt: DateTime(2026, 9, 28),
      );
      
      await repository.saveHabits([habit]);
      final habits = await repository.getHabits();
      
      expect(habits.length, 1);
      expect(habits.first.id, '1');
      expect(habits.first.trigger, 'Test');
    });

    test('addHabit adds correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPrefsHabitRepository(prefs);
      
      final habit = Habit(
        id: '1',
        trigger: 'Test',
        action: 'Test action',
        frequency: HabitFrequency.daily(),
        createdAt: DateTime(2026, 9, 28),
      );
      
      await repository.addHabit(habit);
      final habits = await repository.getHabits();
      expect(habits.length, 1);
    });
  });
}
