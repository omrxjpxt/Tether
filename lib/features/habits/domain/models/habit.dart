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
    if (json['reminderTime'] != null && json['reminderTime'] is String) {
      final parts = (json['reminderTime'] as String).split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          parsedReminder = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    DateTime parsedCreated = DateTime.now();
    if (json['createdAt'] != null && json['createdAt'] is String) {
      parsedCreated = DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
    }

    return Habit(
      id: json['id'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      action: json['action'] as String? ?? '',
      frequency: json['frequency'] is Map<String, dynamic>
          ? HabitFrequency.fromJson(json['frequency'] as Map<String, dynamic>)
          : HabitFrequency.daily(),
      createdAt: parsedCreated,
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reminderTime: parsedReminder,
      archived: json['archived'] as bool? ?? false,
    );
  }
}
