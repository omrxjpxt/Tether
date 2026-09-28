class DailyFocus {
  final String dateKey;
  final String priorityText;
  final bool completed;
  final int focusSessionCount;

  const DailyFocus({
    required this.dateKey,
    required this.priorityText,
    required this.completed,
    this.focusSessionCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'priorityText': priorityText,
      'completed': completed,
      'focusSessionCount': focusSessionCount,
    };
  }

  factory DailyFocus.fromJson(Map<String, dynamic> json) {
    return DailyFocus(
      dateKey: json['dateKey'] as String,
      priorityText: json['priorityText'] as String,
      completed: json['completed'] as bool,
      focusSessionCount: json['focusSessionCount'] as int? ?? 0,
    );
  }
}
