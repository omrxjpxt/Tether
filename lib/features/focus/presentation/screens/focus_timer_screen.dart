
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/focus/presentation/providers/timer_provider.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(timerProvider.notifier).refreshFromLifecycle();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop focus session?'),
        content: const Text('This session will not be saved if you stop now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Stop session'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(timerProvider.notifier).cancelTimer();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerData = ref.watch(timerProvider);
    final focusAsync = ref.watch(dailyFocusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: timerData.state == TimerState.running || timerData.state == TimerState.paused
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _confirmCancel,
              )
            : IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Focus',
                style: AppTypography.metadata.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              focusAsync.when(
                data: (focus) => Text(
                  focus?.priorityText ?? 'General Focus',
                  style: AppTypography.headingLarge,
                  textAlign: TextAlign.center,
                ),
                loading: () => const SizedBox(),
                error: (err, stack) => const SizedBox(),
              ),
              const SizedBox(height: AppSpacing.xxl * 2),
              
              if (timerData.state == TimerState.completed) ...[
                Text(
                  'Focus session complete',
                  style: AppTypography.headingSection,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '${timerData.targetDurationMinutes} min',
                  style: AppTypography.body.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done'),
                ),
              ] else ...[
                Text(
                  _formatTime(timerData.remainingSeconds),
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -2,
                    color: theme.textTheme.bodyLarge?.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                if (timerData.state == TimerState.idle) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DurationButton(
                        minutes: 25,
                        isSelected: timerData.targetDurationMinutes == 25,
                        onTap: () => ref.read(timerProvider.notifier).setDuration(25),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _DurationButton(
                        minutes: 50,
                        isSelected: timerData.targetDurationMinutes == 50,
                        onTap: () => ref.read(timerProvider.notifier).setDuration(50),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _DurationButton(
                        minutes: 90,
                        isSelected: timerData.targetDurationMinutes == 90,
                        onTap: () => ref.read(timerProvider.notifier).setDuration(90),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: () => ref.read(timerProvider.notifier).start(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: Text('Start Focus', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
                  ),
                ] else if (timerData.state == TimerState.running) ...[
                  OutlinedButton(
                    onPressed: () => ref.read(timerProvider.notifier).pause(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: Text('Pause', style: AppTypography.body),
                  ),
                ] else if (timerData.state == TimerState.paused) ...[
                  ElevatedButton(
                    onPressed: () => ref.read(timerProvider.notifier).resume(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: Text('Resume', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimary)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          '$minutes m',
          style: AppTypography.body.copyWith(
            color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
