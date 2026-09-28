import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/focus/domain/services/focus_service.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/habits/domain/services/habit_service.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/review/presentation/providers/review_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> with WidgetsBindingObserver {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _notesController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final currentStart = DateUtilsLocal.startOfWeek(now);
      if (ref.read(reviewWeekProvider) != currentStart) {
        ref.read(reviewWeekProvider.notifier).state = currentStart;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = ref.watch(reviewWeekProvider);
    final weekEnd = DateUtilsLocal.endOfWeek(weekStart);
    
    final habitsAsync = ref.watch(habitsProvider);
    final sessionsAsync = ref.watch(focusSessionsProvider);
    final reviewAsync = ref.watch(currentWeeklyReviewProvider);

    reviewAsync.whenData((review) {
      if (review != null && _notesController.text.isEmpty && review.notes.isNotEmpty) {
        _notesController.text = review.notes;
      }
    });

    final dateFormat = DateFormat('MMMM d');
    final dateRange = '${dateFormat.format(weekStart)} – ${dateFormat.format(weekEnd)}';

    return SafeArea(
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
                        'Weekly Review',
                        style: AppTypography.headingLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        dateRange,
                        style: AppTypography.metadata.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Your first week is still ahead.',
                          style: AppTypography.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  int totalExpected = 0;
                  int totalCompleted = 0;
                  
                  final List<bool> weekConsistency = List.filled(7, false);

                  for (final habit in habits) {
                    final expected = HabitService.expectedCompletions(habit, weekStart, weekEnd);
                    final actual = HabitService.actualCompletions(habit, weekStart, weekEnd);
                    totalExpected += expected;
                    totalCompleted += actual;

                    for (int i = 0; i < 7; i++) {
                      final d = weekStart.add(Duration(days: i));
                      if (HabitService.isHabitCompletedToday(habit, d)) {
                        weekConsistency[i] = true;
                      }
                    }
                  }

                  final rate = totalExpected == 0 ? 0 : (totalCompleted / totalExpected * 100).round();

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Habits completed', style: AppTypography.metadata),
                                  const SizedBox(height: 4),
                                  Text('$totalCompleted / $totalExpected', style: AppTypography.headingSection),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Completion rate', style: AppTypography.metadata),
                                  const SizedBox(height: 4),
                                  Text('$rate%', style: AppTypography.headingSection),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('CONSISTENCY', style: AppTypography.metadata),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < 7; i++)
                                Column(
                                  children: [
                                    Text(
                                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                      style: AppTypography.metadata.copyWith(
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: weekConsistency[i] ? theme.colorScheme.primary : Colors.transparent,
                                        border: Border.all(
                                          color: weekConsistency[i] ? theme.colorScheme.primary : theme.dividerColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text('HABITS', style: AppTypography.metadata),
                          const SizedBox(height: AppSpacing.s),
                          ...habits.map((h) {
                            final exp = HabitService.expectedCompletions(h, weekStart, weekEnd);
                            final act = HabitService.actualCompletions(h, weekStart, weekEnd);
                            final pct = exp == 0 ? 0 : (act / exp * 100).round();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.m),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'After I ${h.trigger}, I will ${h.action}.',
                                      style: AppTypography.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$act / $exp', style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                                      Text('$pct%', style: AppTypography.metadata.copyWith(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, _) => const SliverToBoxAdapter(child: Text('Error loading habits')),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              sessionsAsync.when(
                data: (sessions) {
                  final weekSessions = FocusService.getSessionsForDateRange(sessions, weekStart, weekEnd);
                  if (weekSessions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FOCUS', style: AppTypography.metadata),
                            const SizedBox(height: AppSpacing.s),
                            Text('No focus sessions yet.', style: AppTypography.body),
                          ],
                        ),
                      ),
                    );
                  }

                  final totalMin = FocusService.getTotalDuration(weekSessions);
                  final h = totalMin ~/ 60;
                  final m = totalMin % 60;
                  final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FOCUS', style: AppTypography.metadata),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sessions', style: AppTypography.metadata),
                                  const SizedBox(height: 4),
                                  Text('${weekSessions.length}', style: AppTypography.headingSection),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Time focused', style: AppTypography.metadata),
                                  const SizedBox(height: 4),
                                  Text(timeStr, style: AppTypography.headingSection),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox()),
                error: (err, _) => const SliverToBoxAdapter(child: SizedBox()),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REFLECT', style: AppTypography.metadata),
                      const SizedBox(height: AppSpacing.s),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'What worked this week?\nWhat should I change next week?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            int exp = 0;
                            int comp = 0;
                            if (habitsAsync is AsyncData) {
                              for (final h in habitsAsync.value!) {
                                exp += HabitService.expectedCompletions(h, weekStart, weekEnd);
                                comp += HabitService.actualCompletions(h, weekStart, weekEnd);
                              }
                            }
                            int sessions = 0;
                            if (sessionsAsync is AsyncData) {
                              sessions = FocusService.getSessionsForDateRange(sessionsAsync.value!, weekStart, weekEnd).length;
                            }
                            ref.read(currentWeeklyReviewProvider.notifier).saveNotes(
                              _notesController.text, exp, comp, sessions,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved')));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Review'),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
