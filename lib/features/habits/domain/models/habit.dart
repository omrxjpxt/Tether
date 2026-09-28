import 'package:flutter/material.dart';
import 'habit_frequency.dart';

class Habit {
  final String id;
  final String trigger;
  final String action;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final List<String> completedDates;
  final TimeOfDay? reminderTime;
  final bool archived;

  const Habit({
    required this.id,
    required this.trigger,
    required this.action,
    required this.frequency,
    required this.createdAt,
    this.completedDates = const [],
    this.reminderTime,
    this.archived = false,
  });

  Habit copyWith({
    String? id,
    String? trigger,
    String? action,
    HabitFrequency? frequency,
    DateTime? createdAt,
    List<String>? completedDates,
    TimeOfDay? reminderTime,
    bool? archived,
  }) {
    return Habit(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      action: action ?? this.action,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      reminderTime: reminderTime ?? this.reminderTime,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trigger': trigger,
      'action': action,
      'frequency': frequency.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates,
      'reminderTime': reminderTime != null ? '${reminderTime!.hour}:${reminderTime!.minute}' : null,
      'archived': archived,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedReminder;
    if (json['reminderTime'] != null) {
      final parts = (json['reminderTime'] as String).split(':');
      if (parts.length == 2) {
        parsedReminder = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    return Habit(
      id: json['id'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      action: json['action'] as String? ?? '',
      frequency: json['frequency'] != null ? HabitFrequency.fromJson(json['frequency'] as Map<String, dynamic>) : HabitFrequency.daily(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      completedDates: (json['completedDates'] as List<dynamic>?)?.cast<String>() ?? [],
      reminderTime: parsedReminder,
      archived: json['archived'] as bool? ?? false,
    );
  }
}
