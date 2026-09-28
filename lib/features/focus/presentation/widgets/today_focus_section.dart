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
    final colors = theme.colorScheme;
    final dateKey = ref.watch(currentDateKeyProvider);
    final now = DateUtilsLocal.parseDateKey(dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S FOCUS',
          style: AppTypography.metadata.copyWith(
            color: colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        focusAsync.when(
          data: (focus) {
            if (focus == null || _isEditing) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(14),
                  color: colors.surface,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: AppTypography.body,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _save(ref),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
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
                borderRadius: BorderRadius.circular(14),
                color: colors.surface,
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(dailyFocusProvider.notifier).toggleCompleted();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: focus.completed ? colors.primary : Colors.transparent,
                              border: Border.all(
                                color: focus.completed ? colors.primary : theme.dividerColor,
                                width: 1.5,
                              ),
                            ),
                            child: focus.completed 
                                ? Icon(Icons.check, size: 14, color: colors.onPrimary)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              focus.priorityText,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                                decoration: focus.completed ? TextDecoration.lineThrough : null,
                                color: focus.completed ? colors.onSurfaceVariant : null,
                              ),
                            ),
                            if (todaySessions > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '$todaySessions session${todaySessions == 1 ? '' : 's'} · $todayDuration min',
                                style: AppTypography.caption.copyWith(
                                  color: colors.outline,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: colors.outline,
                        ),
                        padding: EdgeInsets.zero,
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
                  const SizedBox(height: AppSpacing.m),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
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
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: colors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      child: Text(
                        'Start Focus',
                        style: AppTypography.secondary.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, stack) => const Text('Error loading focus'),
        ),
      ],
    );
  }
}
