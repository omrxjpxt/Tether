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
    final colors = theme.colorScheme;
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
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Review',
                            style: AppTypography.headingLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateRange,
                            style: AppTypography.caption.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 22),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref.read(reviewWeekProvider.notifier).state =
                                  DateUtilsLocal.addDays(weekStart, -7);
                            },
                            tooltip: 'Previous week',
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 22),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref.read(reviewWeekProvider.notifier).state =
                                  DateUtilsLocal.addDays(weekStart, 7);
                            },
                            tooltip: 'Next week',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              habitsAsync.when(
                data: (habits) {
                  final now = DateTime.now();
                  final currentWeekStart = DateUtilsLocal.startOfWeek(now);
                  final isFutureWeek = weekStart.isAfter(currentWeekStart);

                  if (isFutureWeek) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              "This week hasn't started yet.",
                              style: AppTypography.body.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check back once this week begins.',
                              style: AppTypography.caption.copyWith(
                                color: colors.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (habits.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              'Your week is just getting started.',
                              style: AppTypography.body.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create habits from the Today tab to see your review here.',
                              style: AppTypography.caption.copyWith(
                                color: colors.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                      final d = DateUtilsLocal.addDays(weekStart, i);
                      if (HabitService.isHabitCompletedOnDate(habit, d)) {
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
                          const SizedBox(height: 32),

                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'COMPLETED',
                                      style: AppTypography.metadata.copyWith(
                                        color: colors.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$totalCompleted / $totalExpected',
                                      style: AppTypography.headingLarge.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RATE',
                                    style: AppTypography.metadata.copyWith(
                                      color: colors.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$rate%',
                                    style: AppTypography.headingLarge.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Consistency
                          Text(
                            'CONSISTENCY',
                            style: AppTypography.metadata.copyWith(
                              color: colors.outline,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < 7; i++)
                                Column(
                                  children: [
                                    Text(
                                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                      style: AppTypography.metadata.copyWith(
                                        color: colors.outline,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: weekConsistency[i]
                                            ? colors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: weekConsistency[i]
                                              ? colors.primary
                                              : theme.dividerColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Habits breakdown
                          Text(
                            'HABITS',
                            style: AppTypography.metadata.copyWith(
                              color: colors.outline,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          ...habits.map((h) {
                            final exp = HabitService.expectedCompletions(h, weekStart, weekEnd);
                            final act = HabitService.actualCompletions(h, weekStart, weekEnd);
                            final pct = exp == 0 ? 0 : (act / exp * 100).round();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.m),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'After I ${h.trigger}, I will ${h.action}.',
                                      style: AppTypography.body.copyWith(fontSize: 15),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$act / $exp',
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '$pct%',
                                        style: AppTypography.caption.copyWith(
                                          color: colors.outline,
                                          fontSize: 12,
                                        ),
                                      ),
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
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
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
                            Text(
                              'FOCUS',
                              style: AppTypography.metadata.copyWith(
                                color: colors.outline,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              'No focus sessions this week.',
                              style: AppTypography.body.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
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
                          Text(
                            'FOCUS',
                            style: AppTypography.metadata.copyWith(
                              color: colors.outline,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SESSIONS',
                                      style: AppTypography.metadata.copyWith(
                                        color: colors.outline,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${weekSessions.length}',
                                      style: AppTypography.headingLarge.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TIME',
                                    style: AppTypography.metadata.copyWith(
                                      color: colors.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    timeStr,
                                    style: AppTypography.headingLarge.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REFLECT',
                        style: AppTypography.metadata.copyWith(
                          color: colors.outline,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'What worked this week?\nWhat should I change next week?',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
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
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          child: Text(
                            'Save Review',
                            style: AppTypography.secondary.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
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
