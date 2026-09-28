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
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      habitsCompleted: json['habitsCompleted'] as int,
      habitsExpected: json['habitsExpected'] as int,
      focusSessions: json['focusSessions'] as int,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
