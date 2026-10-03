
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
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: timerData.state == TimerState.running || timerData.state == TimerState.paused
            ? IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: _confirmCancel,
              )
            : IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                Text(
                  'Focus',
                  style: AppTypography.metadata.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                focusAsync.when(
                  data: (focus) => Text(
                    focus?.priorityText ?? 'General Focus',
                    style: AppTypography.headingSection.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                ),
                
                const Spacer(flex: 2),
                
                if (timerData.state == TimerState.completed) ...[
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Session complete',
                    style: AppTypography.headingSection.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${timerData.targetDurationMinutes} minutes',
                    style: AppTypography.body.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Done',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    _formatTime(timerData.remainingSeconds),
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -3,
                      color: colors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxxl),
                  
                  if (timerData.state == TimerState.idle) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DurationButton(
                          minutes: 25,
                          isSelected: timerData.targetDurationMinutes == 25,
                          onTap: () => ref.read(timerProvider.notifier).setDuration(25),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        _DurationButton(
                          minutes: 50,
                          isSelected: timerData.targetDurationMinutes == 50,
                          onTap: () => ref.read(timerProvider.notifier).setDuration(50),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        _DurationButton(
                          minutes: 90,
                          isSelected: timerData.targetDurationMinutes == 90,
                          onTap: () => ref.read(timerProvider.notifier).setDuration(90),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () => ref.read(timerProvider.notifier).start(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          'Start',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ] else if (timerData.state == TimerState.running) ...[
                    SizedBox(
                      width: 180,
                      child: OutlinedButton(
                        onPressed: () => ref.read(timerProvider.notifier).pause(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Text(
                          'Pause',
                          style: AppTypography.body.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ] else if (timerData.state == TimerState.paused) ...[
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () => ref.read(timerProvider.notifier).resume(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text(
                          'Resume',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                
                const Spacer(flex: 3),
              ],
            ),
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
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$minutes minutes focus session duration',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
          ),
          child: Text(
            '$minutes m',
            style: AppTypography.secondary.copyWith(
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
