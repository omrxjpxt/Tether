class FocusSession {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final bool completed;
  final DateTime createdAt;

  const FocusSession({
    required this.id,
    required this.date,
    required this.durationMinutes,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      durationMinutes: json['durationMinutes'] as int,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
