import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
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
            final updated = HabitService.toggleHabitToday(habit, now);
            ref.read(habitsProvider.notifier).updateHabit(updated);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompletedToday ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isCompletedToday ? theme.colorScheme.primary : theme.dividerColor,
                  width: 2,
                ),
              ),
              child: isCompletedToday 
                  ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
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
                color: theme.textTheme.bodyLarge?.color,
              ),
              children: [
                TextSpan(
                  text: 'After I ${habit.trigger}, ',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                TextSpan(
                  text: 'I will ${habit.action}.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: last7Days.map((isCompleted) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? theme.colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? theme.colorScheme.primary : theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      trailing: Text(
        streakText,
        style: AppTypography.metadata.copyWith(
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
