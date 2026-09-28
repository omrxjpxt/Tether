import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/focus/presentation/widgets/today_focus_section.dart';
import 'package:tether/features/habits/domain/services/habit_service.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/habits/presentation/widgets/add_habit_sheet.dart';
import 'package:tether/features/habits/presentation/widgets/habit_list_item.dart';
import 'package:tether/shared/widgets/app_button.dart';
import 'package:intl/intl.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:uuid/uuid.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> with WidgetsBindingObserver {
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
      ref.read(currentDateKeyProvider.notifier).refresh();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final dateKey = ref.watch(currentDateKeyProvider);
    final now = DateUtilsLocal.parseDateKey(dateKey);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddHabitSheet(),
          );
        },
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 24),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: AppTypography.caption.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getGreeting(),
                          style: AppTypography.headingLarge,
                        ),
                      ],
                    ),
                  ),
                ),

                // Today's Focus
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: TodayFocusSection(),
                  ),
                ),

                // Habit progress label + list
                habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: _buildEmptyState(context),
                        ),
                      );
                    }
                    
                    final completedCount = habits.where((h) => HabitService.isHabitCompletedToday(h, now)).length;
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
                              child: Text(
                                '$completedCount of ${habits.length} complete',
                                style: AppTypography.caption.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          }
                          final habit = habits[index - 1];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                            child: HabitListItem(habit: habit, now: now),
                          );
                        },
                        childCount: habits.length + 1,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 64),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                  error: (err, stack) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $err')),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: AppTypography.headingSection.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Connect a small action to something\nyou already do.',
            style: AppTypography.body.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Create habit',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddHabitSheet(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'OR TRY A SUGGESTION',
            style: AppTypography.metadata.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          _buildSuggestion(context, 'sit at my desk', 'write my top 1 priority for the next hour'),
          const SizedBox(height: AppSpacing.xs),
          _buildSuggestion(context, 'close my laptop for a break', 'stand and stretch for 60 seconds'),
        ],
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, String trigger, String action) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        final habit = Habit(
          id: const Uuid().v4(),
          trigger: trigger,
          action: action,
          frequency: HabitFrequency.daily(),
          createdAt: DateTime.now(),
        );
        ref.read(habitsProvider.notifier).addHabit(habit);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'After I $trigger',
              style: AppTypography.caption.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '→ I will $action',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
