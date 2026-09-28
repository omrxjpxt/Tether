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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: AppTypography.metadata.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _getGreeting(),
                          style: AppTypography.headingLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: TodayFocusSection(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
                habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      );
                    }
                    
                    final completedCount = habits.where((h) => HabitService.isHabitCompletedToday(h, now)).length;
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: Text(
                                '$completedCount of ${habits.length} done today',
                                style: AppTypography.metadata.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            );
                          }
                          final habit = habits[index - 1];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                            child: HabitListItem(habit: habit, now: now),
                          );
                        },
                        childCount: habits.length + 1,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'No habits yet.',
            style: AppTypography.headingSection,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Connect a small action to something you already do.',
            style: AppTypography.body.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
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
          Text('SUGGESTED', style: AppTypography.metadata, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.m),
          _buildSuggestion(context, 'sit at my desk', 'write my top 1 priority for the next hour'),
          const SizedBox(height: AppSpacing.s),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('After I $trigger', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 4),
            Text('→ I will $action', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
