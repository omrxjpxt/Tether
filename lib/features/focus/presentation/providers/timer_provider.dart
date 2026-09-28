import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
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

  @override
  TimerData build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const TimerData();
  }

  void setDuration(int minutes) {
    if (state.state == TimerState.idle || state.state == TimerState.completed) {
      state = state.update(targetDurationMinutes: minutes, currentElapsedSeconds: 0, state: TimerState.idle);
    }
  }

  void start() {
    if (state.state == TimerState.idle || state.state == TimerState.completed) {
      state = state.update(
        state: TimerState.running,
        startedAt: DateTime.now(),
        clearPausedAt: true,
        elapsedSecondsBeforePause: 0,
        currentElapsedSeconds: 0,
      );
      _startTicker();
    }
  }

  void pause() {
    if (state.state == TimerState.running) {
      _ticker?.cancel();
      final now = DateTime.now();
      state = state.update(
        state: TimerState.paused,
        pausedAt: now,
      );
    }
  }

  void resume() {
    if (state.state == TimerState.paused) {
      final now = DateTime.now();
      state = state.update(
        state: TimerState.running,
        startedAt: now,
        clearPausedAt: true,
        elapsedSecondsBeforePause: state.currentElapsedSeconds,
      );
      _startTicker();
    }
  }

  void cancelTimer() {
    _ticker?.cancel();
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
    _ticker?.cancel();
    state = state.update(
      state: TimerState.completed,
      currentElapsedSeconds: state.targetDurationMinutes * 60,
    );

    final session = FocusSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      durationMinutes: state.targetDurationMinutes,
      completed: true,
      createdAt: DateTime.now(),
    );
    
    await ref.read(focusRepositoryProvider).addFocusSession(session);
    ref.read(focusSessionsProvider.notifier).refresh();
  }
}
