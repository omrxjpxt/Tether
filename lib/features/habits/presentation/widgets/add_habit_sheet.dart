import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/services/notification_providers.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/shared/widgets/app_button.dart';
import 'package:uuid/uuid.dart';

class AddHabitSheet extends ConsumerStatefulWidget {
  final Habit? existingHabit;
  const AddHabitSheet({super.key, this.existingHabit});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  late TextEditingController _triggerController;
  late TextEditingController _actionController;
  FrequencyType _frequencyType = FrequencyType.daily;
  int _timesPerWeek = 4;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _triggerController = TextEditingController(text: widget.existingHabit?.trigger ?? '');
    _actionController = TextEditingController(text: widget.existingHabit?.action ?? '');
    if (widget.existingHabit != null) {
      _frequencyType = widget.existingHabit!.frequency.type;
      if (_frequencyType == FrequencyType.timesPerWeek) {
        _timesPerWeek = widget.existingHabit!.frequency.timesPerWeek ?? 4;
      }
      _reminderTime = widget.existingHabit!.reminderTime;
    }
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    HapticFeedback.selectionClick();
    final notifService = ref.read(notificationServiceProvider);
    bool granted = await notifService.isPermissionGranted();
    if (!granted) {
      granted = await notifService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications are disabled. You can enable them in system settings.'),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final initial = _reminderTime ?? const TimeOfDay(hour: 8, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _save() {
    final trigger = _triggerController.text.trim();
    final action = _actionController.text.trim();
    if (trigger.isEmpty || action.isEmpty) return;

    HabitFrequency frequency;
    switch (_frequencyType) {
      case FrequencyType.daily:
        frequency = HabitFrequency.daily();
        break;
      case FrequencyType.weekdays:
        frequency = HabitFrequency.weekdays();
        break;
      case FrequencyType.timesPerWeek:
        frequency = HabitFrequency.timesPerWeek(_timesPerWeek);
        break;
      case FrequencyType.custom:
        frequency = HabitFrequency.daily();
        break;
    }

    HapticFeedback.lightImpact();

    if (widget.existingHabit != null) {
      final updated = widget.existingHabit!.copyWith(
        trigger: trigger,
        action: action,
        frequency: frequency,
        reminderTime: _reminderTime,
      );
      ref.read(habitsProvider.notifier).updateHabit(updated);
      if (_reminderTime != null) {
        ref.read(notificationServiceProvider).scheduleHabitReminder(updated);
      } else {
        ref.read(notificationServiceProvider).cancelHabitReminder(updated.id);
      }
    } else {
      final habit = Habit(
        id: const Uuid().v4(),
        trigger: trigger,
        action: action,
        frequency: frequency,
        reminderTime: _reminderTime,
        createdAt: DateTime.now(),
      );
      ref.read(habitsProvider.notifier).addHabit(habit);
      if (_reminderTime != null) {
        ref.read(notificationServiceProvider).scheduleHabitReminder(habit);
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingHabit != null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit habit' : 'New habit',
                  style: AppTypography.headingSection.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final deletedHabit = widget.existingHabit!;
                      ref.read(habitsProvider.notifier).deleteHabit(deletedHabit.id);
                      ref.read(notificationServiceProvider).cancelHabitReminder(deletedHabit.id);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Habit removed'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref.read(habitsProvider.notifier).addHabit(deletedHabit);
                              if (deletedHabit.reminderTime != null) {
                                ref.read(notificationServiceProvider).scheduleHabitReminder(deletedHabit);
                              }
                            },
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: colors.error,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'AFTER I',
              style: AppTypography.metadata.copyWith(
                color: colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _triggerController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'sit down at my desk',
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            Text(
              'I WILL',
              style: AppTypography.metadata.copyWith(
                color: colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _actionController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                hintText: 'write my top priority for the next hour',
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            Text(
              'FREQUENCY',
              style: AppTypography.metadata.copyWith(
                color: colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Daily', FrequencyType.daily),
                _buildChip('Weekdays', FrequencyType.weekdays),
                _buildChip('Times per week', FrequencyType.timesPerWeek),
              ],
            ),
            if (_frequencyType == FrequencyType.timesPerWeek) ...[
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Text(
                    'Target: $_timesPerWeek×',
                    style: AppTypography.body.copyWith(fontSize: 15),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 180,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: theme.dividerColor,
                        thumbColor: colors.primary,
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: _timesPerWeek.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        onChanged: (val) => setState(() => _timesPerWeek = val.toInt()),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.l),

            // REMINDER SECTION
            Text(
              'REMINDER',
              style: AppTypography.metadata.copyWith(
                color: colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickReminderTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reminderTime != null
                        ? colors.primary.withValues(alpha: 0.3)
                        : theme.dividerColor,
                    width: 0.5,
                  ),
                  color: _reminderTime != null
                      ? colors.primary.withValues(alpha: 0.04)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _reminderTime != null ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
                      color: _reminderTime != null
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _reminderTime != null
                                ? 'Reminder at ${_reminderTime!.format(context)}'
                                : 'Set a daily reminder',
                            style: AppTypography.body.copyWith(
                              fontWeight: _reminderTime != null ? FontWeight.w500 : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                          if (_reminderTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _frequencyType == FrequencyType.timesPerWeek
                                  ? 'Daily reminder to reach your target'
                                  : (_frequencyType == FrequencyType.weekdays
                                      ? 'Monday to Friday'
                                      : 'Every day'),
                              style: AppTypography.caption.copyWith(
                                color: colors.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_reminderTime != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _reminderTime = null);
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colors.outline,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: isEditing ? 'Save changes' : 'Save habit',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, FrequencyType type) {
    final isSelected = _frequencyType == type;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _frequencyType = type);
      },
      selectedColor: colors.primary.withValues(alpha: 0.08),
      checkmarkColor: colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.3)
              : theme.dividerColor,
          width: 0.5,
        ),
      ),
    );
  }
}
