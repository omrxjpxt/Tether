class WeeklyReview {
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int habitsCompleted;
  final int habitsExpected;
  final int focusSessions;
  final String notes;
  final DateTime createdAt;

  const WeeklyReview({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.habitsCompleted,
    required this.habitsExpected,
    required this.focusSessions,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'habitsCompleted': habitsCompleted,
      'habitsExpected': habitsExpected,
      'focusSessions': focusSessions,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    return WeeklyReview(
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.tryParse(json['weekStartDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      weekEndDate: json['weekEndDate'] != null
          ? DateTime.tryParse(json['weekEndDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      habitsCompleted: (json['habitsCompleted'] as num?)?.toInt() ?? 0,
      habitsExpected: (json['habitsExpected'] as num?)?.toInt() ?? 0,
      focusSessions: (json['focusSessions'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
