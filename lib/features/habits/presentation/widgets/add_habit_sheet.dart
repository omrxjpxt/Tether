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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit habit' : 'Create habit',
                  style: AppTypography.headingSection,
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
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Text('AFTER I', style: AppTypography.metadata),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _triggerController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'sit down at my desk',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('I WILL', style: AppTypography.metadata),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _actionController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'write my top priority for the next hour',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('FREQUENCY', style: AppTypography.metadata),
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
                  Text('Target: $_timesPerWeek times', style: AppTypography.body),
                  const Spacer(),
                  Slider(
                    value: _timesPerWeek.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: (val) => setState(() => _timesPerWeek = val.toInt()),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.l),

            // REMINDER SECTION
            Text('REMINDER', style: AppTypography.metadata),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickReminderTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reminderTime != null ? theme.colorScheme.primary : theme.dividerColor,
                  ),
                  color: _reminderTime != null
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _reminderTime != null ? Icons.notifications_active : Icons.notifications_none,
                      color: _reminderTime != null ? theme.colorScheme.primary : theme.iconTheme.color,
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
                            ),
                          ),
                          if (_reminderTime != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _frequencyType == FrequencyType.timesPerWeek
                                  ? 'Reminds daily to help reach your target'
                                  : (_frequencyType == FrequencyType.weekdays
                                      ? 'Monday to Friday'
                                      : 'Every day'),
                              style: AppTypography.metadata.copyWith(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_reminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _reminderTime = null);
                        },
                      )
                    else
                      const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save habit',
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
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _frequencyType = type);
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      checkmarkColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
    );
  }
}
