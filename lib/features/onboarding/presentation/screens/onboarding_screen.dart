import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_colors.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/habits/presentation/widgets/add_habit_sheet.dart';
import 'package:tether/features/settings/presentation/providers/settings_provider.dart';
import 'package:tether/shared/widgets/app_button.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _finishOnboarding(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(appSettingsProvider.notifier).completeOnboarding();
  }

  void _addTemplateHabit(
    BuildContext context,
    WidgetRef ref,
    String trigger,
    String action,
  ) {
    HapticFeedback.mediumImpact();
    final habit = Habit(
      id: const Uuid().v4(),
      trigger: trigger,
      action: action,
      frequency: HabitFrequency.daily(),
      createdAt: DateTime.now(),
    );
    ref.read(habitsProvider.notifier).addHabit(habit);
    _finishOnboarding(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => _finishOnboarding(ref),
                      child: Text(
                        'Skip',
                        style: AppTypography.body.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Tether Minimal Icon Symbol
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        size: 34,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Tether',
                    style: AppTypography.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Build habits that stick.',
                    style: AppTypography.body.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    '"Connect a small action to something you already do."',
                    style: AppTypography.body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  Text(
                    'START WITH A TEMPLATE',
                    style: AppTypography.metadata,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  _TemplateCard(
                    trigger: 'sit at my desk',
                    action: 'write my top priority for the next hour',
                    onTap: () => _addTemplateHabit(
                      context,
                      ref,
                      'sit at my desk',
                      'write my top priority for the next hour',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _TemplateCard(
                    trigger: 'finish brushing my teeth',
                    action: 'prepare tomorrow\'s top priority',
                    onTap: () => _addTemplateHabit(
                      context,
                      ref,
                      'finish brushing my teeth',
                      'prepare tomorrow\'s top priority',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _TemplateCard(
                    trigger: 'close my laptop',
                    action: 'stand and stretch for 60 seconds',
                    onTap: () => _addTemplateHabit(
                      context,
                      ref,
                      'close my laptop',
                      'stand and stretch for 60 seconds',
                    ),
                  ),

                  const Spacer(),

                  AppButton(
                    label: 'Create custom habit',
                    onPressed: () {
                      _finishOnboarding(ref);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const AddHabitSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String trigger;
  final String action;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.trigger,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'After I $trigger',
                    style: AppTypography.metadata.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '→ I will $action',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
