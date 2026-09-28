import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/focus/domain/services/focus_service.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/focus/presentation/providers/timer_provider.dart';
import 'package:tether/features/focus/presentation/screens/focus_timer_screen.dart';

class TodayFocusSection extends ConsumerStatefulWidget {
  const TodayFocusSection({super.key});

  @override
  ConsumerState<TodayFocusSection> createState() => _TodayFocusSectionState();
}

class _TodayFocusSectionState extends ConsumerState<TodayFocusSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(WidgetRef ref) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(dailyFocusProvider.notifier).setFocus(text);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusAsync = ref.watch(dailyFocusProvider);
    final sessionsAsync = ref.watch(focusSessionsProvider);
    final theme = Theme.of(context);
    final dateKey = ref.watch(currentDateKeyProvider);
    final now = DateUtilsLocal.parseDateKey(dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S FOCUS',
          style: AppTypography.metadata.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        focusAsync.when(
          data: (focus) {
            if (focus == null || _isEditing) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(ref),
                        decoration: const InputDecoration(
                          hintText: 'What matters most today?',
                          border: InputBorder.none,
                        ),
                        style: AppTypography.body,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _save(ref),
                      child: const Text('Set'),
                    ),
                  ],
                ),
              );
            }

            int todaySessions = 0;
            int todayDuration = 0;
            sessionsAsync.whenData((sessions) {
              final todayList = FocusService.getSessionsForDate(sessions, now);
              todaySessions = todayList.length;
              todayDuration = FocusService.getTotalDuration(todayList);
            });

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(dailyFocusProvider.notifier).toggleCompleted();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: focus.completed ? theme.colorScheme.primary : Colors.transparent,
                            border: Border.all(
                              color: focus.completed ? theme.colorScheme.primary : theme.dividerColor,
                              width: 2,
                            ),
                          ),
                          child: focus.completed 
                              ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          focus.priorityText,
                          style: AppTypography.body.copyWith(
                            decoration: focus.completed ? TextDecoration.lineThrough : null,
                            color: focus.completed ? theme.textTheme.bodyMedium?.color : null,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _controller.text = focus.priorityText;
                            setState(() {
                              _isEditing = true;
                            });
                          } else if (val == 'clear') {
                            ref.read(dailyFocusProvider.notifier).clearFocus();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'clear', child: Text('Clear')),
                        ],
                      ),
                    ],
                  ),
                  if (todaySessions > 0) ...[
                    const SizedBox(height: AppSpacing.s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$todaySessions session${todaySessions == 1 ? '' : 's'} · $todayDuration min',
                        style: AppTypography.metadata.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (ref.read(timerProvider).state == TimerState.completed) {
                          ref.read(timerProvider.notifier).cancelTimer();
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => const FocusTimerScreen(),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Start Focus', style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error loading focus'),
        ),
      ],
    );
  }
}
