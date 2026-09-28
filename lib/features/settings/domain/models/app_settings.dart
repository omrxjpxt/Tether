class AppSettings {
  final String themeMode; // system, light, dark
  final bool isFirstLaunch;
  final bool notificationsEnabled;

  const AppSettings({
    this.themeMode = 'system',
    this.isFirstLaunch = true,
    this.notificationsEnabled = false,
  });

  AppSettings copyWith({
    String? themeMode,
    bool? isFirstLaunch,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'isFirstLaunch': isFirstLaunch,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }
}
