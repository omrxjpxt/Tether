import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/focus/presentation/providers/timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('Timer state transitions correctly and persists transitions', () async {
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
    expect(prefs.getString('active_timer_v1'), isNotNull);

    container.read(timerProvider.notifier).pause();
    expect(container.read(timerProvider).state, TimerState.paused);
    expect(container.read(timerProvider).pausedAt, isNotNull);

    container.read(timerProvider.notifier).resume();
    expect(container.read(timerProvider).state, TimerState.running);
    
    container.read(timerProvider.notifier).cancelTimer();
    expect(container.read(timerProvider).state, TimerState.idle);
    expect(prefs.getString('active_timer_v1'), isNull);
  });

  test('Timer recovers running state across process death', () async {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
    final activeTimerJson = jsonEncode({
      'state': 'running',
      'targetDurationMinutes': 25,
      'startedAt': fiveMinutesAgo.toIso8601String(),
      'elapsedSecondsBeforePause': 0,
    });

    SharedPreferences.setMockInitialValues({
      'active_timer_v1': activeTimerJson,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final timer = container.read(timerProvider);
    expect(timer.state, TimerState.running);
    expect(timer.targetDurationMinutes, 25);
    // About 5 minutes elapsed (300 seconds ± a few seconds)
    expect(timer.currentElapsedSeconds, greaterThanOrEqualTo(299));
    expect(timer.remainingSeconds, lessThanOrEqualTo(1201));
    container.read(timerProvider.notifier).cancelTimer();
  });

  test('Timer automatically completes session if time expired during process death', () async {
    final now = DateTime.now();
    final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
    final activeTimerJson = jsonEncode({
      'state': 'running',
      'targetDurationMinutes': 25,
      'startedAt': thirtyMinutesAgo.toIso8601String(),
      'elapsedSecondsBeforePause': 0,
    });

    SharedPreferences.setMockInitialValues({
      'active_timer_v1': activeTimerJson,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final timer = container.read(timerProvider);
    expect(timer.state, TimerState.completed);
    expect(timer.currentElapsedSeconds, 25 * 60);

    // Wait for microtask to save session
    await Future.delayed(const Duration(milliseconds: 50));
    final sessions = await container.read(focusRepositoryProvider).getFocusSessions();
    expect(sessions.length, 1);
    expect(sessions.first.durationMinutes, 25);
    expect(sessions.first.completed, true);
    expect(prefs.getString('active_timer_v1'), isNull);
  });
}
