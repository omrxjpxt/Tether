import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/services/notification_providers.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/habits/domain/services/habit_service.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/habits/presentation/widgets/add_habit_sheet.dart';
import 'package:tether/shared/widgets/habit_row_shell.dart';

class HabitListItem extends ConsumerWidget {
  final Habit habit;
  final DateTime now;

  const HabitListItem({super.key, required this.habit, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompletedToday = HabitService.isHabitCompletedToday(habit, now);
    
    // Calculate streak
    final streak = HabitService.currentStreak(habit, now);
    String streakText = '$streak days';
    
    if (habit.frequency.type == FrequencyType.timesPerWeek) {
      final target = habit.frequency.timesPerWeek ?? 1;
      final start = DateUtilsLocal.startOfWeek(now);
      final end = DateUtilsLocal.endOfWeek(now);
      final weekCompletions = HabitService.actualCompletions(habit, start, end);
      streakText = '$weekCompletions / $target this week';
    } else {
      final recovered = HabitService.recoveredToday(habit, now);
      final missed = HabitService.missedYesterday(habit, now);
      final misses = HabitService.consecutiveMisses(habit, now);

      if (missed && !isCompletedToday) {
        if (misses >= 3) {
          streakText = 'Ready to restart?';
        } else {
          streakText = 'Missed yesterday. Back today?';
        }
      } else if (recovered && streak == 1) {
        streakText = 'Back on track';
      }
    }

    // Last 7 days
    final last7Days = HabitService.last7Days(habit, now);

    return HabitRowShell(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddHabitSheet(existingHabit: habit),
        );
      },
      leading: Semantics(
        label: isCompletedToday ? 'Completed today' : 'Mark habit complete for today',
        button: true,
        child: GestureDetector(
          onTap: () {
            if (!isCompletedToday) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.lightImpact();
            }
            final updated = HabitService.toggleHabitToday(habit, now);
            ref.read(habitsProvider.notifier).updateHabit(updated);
            if (!kIsWeb) {
              ref.read(notificationServiceProvider).handleHabitCompletionChanged(updated, !isCompletedToday);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompletedToday ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: isCompletedToday ? colors.primary : theme.dividerColor,
                  width: 1.5,
                ),
              ),
              child: isCompletedToday 
                  ? Icon(Icons.check, size: 14, color: colors.onPrimary)
                  : null,
            ),
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTypography.body.copyWith(
                color: colors.onSurface,
                fontSize: 15,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'After I ${habit.trigger}, ',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                TextSpan(
                  text: 'I will ${habit.action}.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: '7-day history: ${last7Days.where((c) => c).length} of 7 days completed',
            child: Row(
              children: [
                ...last7Days.map((isCompleted) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? colors.primary : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? colors.primary : theme.dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  streakText,
                  style: AppTypography.caption.copyWith(
                    color: colors.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
