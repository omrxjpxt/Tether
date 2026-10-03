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
      id: json['id'] as String? ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 25,
      completed: json['completed'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}
