import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/repositories/habit_repository.dart';
import 'package:tether/features/habits/data/repositories/shared_prefs_habit_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsHabitRepository(prefs);
});

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  late HabitRepository _repository;

  @override
  Future<List<Habit>> build() async {
    _repository = ref.watch(habitRepositoryProvider);
    return await _repository.getHabits();
  }

  Future<void> addHabit(Habit habit) async {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncValue.data([...current, habit]);
      try {
        await _repository.addHabit(habit);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
        state = AsyncValue.data(current); // Revert
      }
    }
  }

  Future<void> updateHabit(Habit habit) async {
    if (state is AsyncData) {
      final current = state.value!;
      final index = current.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        final updated = List<Habit>.from(current);
        updated[index] = habit;
        state = AsyncValue.data(updated);
        try {
          await _repository.updateHabit(habit);
        } catch (e, st) {
          state = AsyncValue.error(e, st);
          state = AsyncValue.data(current); // Revert
        }
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    if (state is AsyncData) {
      final current = state.value!;
      final updated = current.where((h) => h.id != id).toList();
      state = AsyncValue.data(updated);
      try {
        await _repository.deleteHabit(id);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
        state = AsyncValue.data(current); // Revert
      }
    }
  }
}
