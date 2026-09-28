import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/repositories/focus_repository.dart';
import 'package:tether/features/focus/data/repositories/shared_prefs_focus_repository.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsFocusRepository(prefs);
});

final currentDateKeyProvider = NotifierProvider<CurrentDateNotifier, String>(() {
  return CurrentDateNotifier();
});

class CurrentDateNotifier extends Notifier<String> {
  @override
  String build() {
    return DateUtilsLocal.todayKey(DateTime.now());
  }

  void refresh() {
    final newKey = DateUtilsLocal.todayKey(DateTime.now());
    if (state != newKey) {
      state = newKey;
    }
  }
}

final dailyFocusProvider = AsyncNotifierProvider<DailyFocusNotifier, DailyFocus?>(() {
  return DailyFocusNotifier();
});

class DailyFocusNotifier extends AsyncNotifier<DailyFocus?> {
  late FocusRepository _repository;
  late String _dateKey;

  @override
  Future<DailyFocus?> build() async {
    _repository = ref.watch(focusRepositoryProvider);
    _dateKey = ref.watch(currentDateKeyProvider);
    return await _repository.getDailyFocus(_dateKey);
  }

  Future<void> setFocus(String priorityText) async {
    final focus = DailyFocus(dateKey: _dateKey, priorityText: priorityText, completed: false);
    state = AsyncValue.data(focus);
    await _repository.saveDailyFocus(focus);
  }

  Future<void> toggleCompleted() async {
    if (state is AsyncData && state.value != null) {
      final currentFocus = state.value!;
      final updated = DailyFocus(
        dateKey: currentFocus.dateKey,
        priorityText: currentFocus.priorityText,
        completed: !currentFocus.completed,
        focusSessionCount: currentFocus.focusSessionCount,
      );
      state = AsyncValue.data(updated);
      await _repository.saveDailyFocus(updated);
    }
  }

  Future<void> clearFocus() async {
    state = const AsyncValue.data(null);
    await _repository.deleteDailyFocus(_dateKey);
  }
}
