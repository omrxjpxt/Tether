import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/focus/presentation/providers/timer_provider.dart';

void main() {
  test('Timer initializes correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    final state = container.read(timerProvider);
    expect(state.state, TimerState.idle);
    expect(state.targetDurationMinutes, 25);
  });

  test('Timer state transitions correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    container.read(timerProvider.notifier).setDuration(50);
    expect(container.read(timerProvider).targetDurationMinutes, 50);

    container.read(timerProvider.notifier).start();
    expect(container.read(timerProvider).state, TimerState.running);
    expect(container.read(timerProvider).startedAt, isNotNull);

    container.read(timerProvider.notifier).pause();
    expect(container.read(timerProvider).state, TimerState.paused);
    expect(container.read(timerProvider).pausedAt, isNotNull);

    container.read(timerProvider.notifier).resume();
    expect(container.read(timerProvider).state, TimerState.running);
    
    container.read(timerProvider.notifier).cancelTimer();
    expect(container.read(timerProvider).state, TimerState.idle);
  });
}
