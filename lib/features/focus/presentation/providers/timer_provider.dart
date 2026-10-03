import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:uuid/uuid.dart';

enum TimerState { idle, running, paused, completed }

class TimerData {
  final TimerState state;
  final int targetDurationMinutes;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final int elapsedSecondsBeforePause;
  final int currentElapsedSeconds;

  const TimerData({
    this.state = TimerState.idle,
    this.targetDurationMinutes = 25,
    this.startedAt,
    this.pausedAt,
    this.elapsedSecondsBeforePause = 0,
    this.currentElapsedSeconds = 0,
  });

  TimerData update({
    TimerState? state,
    int? targetDurationMinutes,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? elapsedSecondsBeforePause,
    int? currentElapsedSeconds,
  }) {
    return TimerData(
      state: state ?? this.state,
      targetDurationMinutes: targetDurationMinutes ?? this.targetDurationMinutes,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      elapsedSecondsBeforePause: elapsedSecondsBeforePause ?? this.elapsedSecondsBeforePause,
      currentElapsedSeconds: currentElapsedSeconds ?? this.currentElapsedSeconds,
    );
  }

  int get remainingSeconds {
    final targetSeconds = targetDurationMinutes * 60;
    final remaining = targetSeconds - currentElapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerData>(() {
  return TimerNotifier();
});

class TimerNotifier extends Notifier<TimerData> {
  Timer? _ticker;
  static const String _activeTimerKey = 'active_timer_v1';

  @override
  TimerData build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final savedJson = prefs.getString(_activeTimerKey);
    if (savedJson != null) {
      try {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        final savedState = map['state'] as String?;
        final targetMinutes = map['targetDurationMinutes'] as int? ?? 25;
        final elapsedBeforePause = map['elapsedSecondsBeforePause'] as int? ?? 0;
        final startedAtStr = map['startedAt'] as String?;
        final pausedAtStr = map['pausedAt'] as String?;
        final startedAt = startedAtStr != null ? DateTime.tryParse(startedAtStr) : null;
        final pausedAt = pausedAtStr != null ? DateTime.tryParse(pausedAtStr) : null;

        if (savedState == 'paused') {
          return TimerData(
            state: TimerState.paused,
            targetDurationMinutes: targetMinutes,
            startedAt: startedAt,
            pausedAt: pausedAt,
            elapsedSecondsBeforePause: elapsedBeforePause,
            currentElapsedSeconds: elapsedBeforePause,
          );
        } else if (savedState == 'running' && startedAt != null) {
          final now = DateTime.now();
          final elapsedSinceStart = now.difference(startedAt).inSeconds;
          final totalElapsed = elapsedBeforePause + elapsedSinceStart;
          final targetSeconds = targetMinutes * 60;

          if (totalElapsed >= targetSeconds) {
            // Completed while app was inactive/killed
            _persistClear();
            Future.microtask(() async {
              final session = FocusSession(
                id: const Uuid().v4(),
                date: startedAt,
                durationMinutes: targetMinutes,
                completed: true,
                createdAt: DateTime.now(),
              );
              await ref.read(focusRepositoryProvider).addFocusSession(session);
              ref.read(focusSessionsProvider.notifier).refresh();
            });
            return TimerData(
              state: TimerState.completed,
              targetDurationMinutes: targetMinutes,
              currentElapsedSeconds: targetSeconds,
            );
          } else {
            // Still running!
            _startTicker();
            return TimerData(
              state: TimerState.running,
              targetDurationMinutes: targetMinutes,
              startedAt: startedAt,
              elapsedSecondsBeforePause: elapsedBeforePause,
              currentElapsedSeconds: totalElapsed,
            );
          }
        }
      } catch (_) {}
    }

    return const TimerData();
  }

  void setDuration(int minutes) {
    if (state.state == TimerState.idle || state.state == TimerState.completed) {
      state = state.update(targetDurationMinutes: minutes, currentElapsedSeconds: 0, state: TimerState.idle);
    }
  }

  void start() {
    if (state.state == TimerState.idle || state.state == TimerState.completed) {
      final now = DateTime.now();
      HapticFeedback.lightImpact();
      state = state.update(
        state: TimerState.running,
        startedAt: now,
        clearPausedAt: true,
        elapsedSecondsBeforePause: 0,
        currentElapsedSeconds: 0,
      );
      _persistRunning(now, 0);
      _startTicker();
    }
  }

  void pause() {
    if (state.state == TimerState.running) {
      _ticker?.cancel();
      final now = DateTime.now();
      HapticFeedback.selectionClick();
      state = state.update(
        state: TimerState.paused,
        pausedAt: now,
      );
      _persistPaused(state.currentElapsedSeconds);
    }
  }

  void resume() {
    if (state.state == TimerState.paused) {
      final now = DateTime.now();
      HapticFeedback.lightImpact();
      state = state.update(
        state: TimerState.running,
        startedAt: now,
        clearPausedAt: true,
        elapsedSecondsBeforePause: state.currentElapsedSeconds,
      );
      _persistRunning(now, state.currentElapsedSeconds);
      _startTicker();
    }
  }

  void cancelTimer() {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    _persistClear();
    state = const TimerData();
  }

  void refreshFromLifecycle() {
    if (state.state == TimerState.running) {
      _updateElapsed();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    if (state.state != TimerState.running) return;

    final now = DateTime.now();
    final elapsedSinceStart = now.difference(state.startedAt!).inSeconds;
    final totalElapsed = state.elapsedSecondsBeforePause + elapsedSinceStart;

    if (totalElapsed >= state.targetDurationMinutes * 60) {
      _complete();
    } else {
      state = state.update(currentElapsedSeconds: totalElapsed);
    }
  }

  void _complete() async {
    if (state.state != TimerState.running) return;
    _ticker?.cancel();
    state = state.update(
      state: TimerState.completed,
      currentElapsedSeconds: state.targetDurationMinutes * 60,
    );
    HapticFeedback.mediumImpact();
    await _persistClear();

    final session = FocusSession(
      id: const Uuid().v4(),
      date: state.startedAt ?? DateTime.now(),
      durationMinutes: state.targetDurationMinutes,
      completed: true,
      createdAt: DateTime.now(),
    );
    
    await ref.read(focusRepositoryProvider).addFocusSession(session);
    ref.read(focusSessionsProvider.notifier).refresh();
  }

  Future<void> _persistRunning(DateTime startedAt, int elapsedBeforePause) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final data = {
      'state': 'running',
      'targetDurationMinutes': state.targetDurationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'elapsedSecondsBeforePause': elapsedBeforePause,
    };
    await prefs.setString(_activeTimerKey, jsonEncode(data));
  }

  Future<void> _persistPaused(int currentElapsed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final data = {
      'state': 'paused',
      'targetDurationMinutes': state.targetDurationMinutes,
      'pausedAt': DateTime.now().toIso8601String(),
      'elapsedSecondsBeforePause': currentElapsed,
    };
    await prefs.setString(_activeTimerKey, jsonEncode(data));
  }

  Future<void> _persistClear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_activeTimerKey);
  }
}
