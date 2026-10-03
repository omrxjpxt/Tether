enum FrequencyType { daily, weekdays, timesPerWeek, custom }

class HabitFrequency {
  final FrequencyType type;
  final int? timesPerWeek;
  final List<int>? customDays; // 1 = Monday, 7 = Sunday

  const HabitFrequency({
    required this.type,
    this.timesPerWeek,
    this.customDays,
  });

  factory HabitFrequency.daily() => const HabitFrequency(type: FrequencyType.daily);
  factory HabitFrequency.weekdays() => const HabitFrequency(type: FrequencyType.weekdays);
  factory HabitFrequency.timesPerWeek(int times) => HabitFrequency(type: FrequencyType.timesPerWeek, timesPerWeek: times);
  factory HabitFrequency.custom(List<int> days) => HabitFrequency(type: FrequencyType.custom, customDays: days);

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (timesPerWeek != null) 'timesPerWeek': timesPerWeek,
      if (customDays != null) 'customDays': customDays,
    };
  }

  factory HabitFrequency.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = FrequencyType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FrequencyType.daily,
    );
    return HabitFrequency(
      type: type,
      timesPerWeek: (json['timesPerWeek'] as num?)?.toInt(),
      customDays: (json['customDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }
}
