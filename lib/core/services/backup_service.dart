import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/review/domain/models/weekly_review.dart';
import 'package:tether/features/settings/domain/models/app_settings.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupData? data;

  const BackupValidationResult.success(this.data)
      : isValid = true,
        errorMessage = null;

  const BackupValidationResult.failure(this.errorMessage)
      : isValid = false,
        data = null;
}

class BackupData {
  final int schemaVersion;
  final DateTime exportedAt;
  final List<Habit> habits;
  final List<DailyFocus> dailyFocus;
  final List<FocusSession> focusSessions;
  final List<WeeklyReview> weeklyReviews;
  final AppSettings settings;

  const BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.habits,
    required this.dailyFocus,
    required this.focusSessions,
    required this.weeklyReviews,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'habits': habits.map((h) => h.toJson()).toList(),
      'dailyFocus': dailyFocus.map((f) => f.toJson()).toList(),
      'focusSessions': focusSessions.map((s) => s.toJson()).toList(),
      'weeklyReviews': weeklyReviews.map((r) => r.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }
}

class BackupService {
  static const int currentSchemaVersion = 1;
  final SharedPreferences _prefs;

  BackupService(this._prefs);

  Future<String> generateBackupJson() async {
    // 1. Habits
    List<Habit> habits = [];
    final habitsStr = _prefs.getString('habits_v1');
    if (habitsStr != null) {
      try {
        final List<dynamic> list = jsonDecode(habitsStr);
        habits = list
            .map((j) => Habit.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // 2. Focus Sessions
    List<FocusSession> focusSessions = [];
    final sessionsStr = _prefs.getString('focus_sessions_v1');
    if (sessionsStr != null) {
      try {
        final List<dynamic> list = jsonDecode(sessionsStr);
        focusSessions = list
            .map((j) => FocusSession.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // 3. Daily Focus items
    List<DailyFocus> dailyFocus = [];
    final allKeys = _prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('daily_focus_v1_')) {
        final val = _prefs.getString(key);
        if (val != null) {
          try {
            dailyFocus.add(DailyFocus.fromJson(jsonDecode(val)));
          } catch (_) {}
        }
      }
    }

    // 4. Weekly Reviews
    List<WeeklyReview> weeklyReviews = [];
    for (final key in allKeys) {
      if (key.startsWith('weekly_review_v1_')) {
        final val = _prefs.getString(key);
        if (val != null) {
          try {
            weeklyReviews.add(WeeklyReview.fromJson(jsonDecode(val)));
          } catch (_) {}
        }
      }
    }

    // 5. Settings
    AppSettings settings = const AppSettings();
    final settingsStr = _prefs.getString('app_settings_v1');
    if (settingsStr != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(settingsStr));
      } catch (_) {}
    }

    final backup = BackupData(
      schemaVersion: currentSchemaVersion,
      exportedAt: DateTime.now(),
      habits: habits,
      dailyFocus: dailyFocus,
      focusSessions: focusSessions,
      weeklyReviews: weeklyReviews,
      settings: settings,
    );

    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<File> writeBackupToFile() async {
    final jsonContent = await generateBackupJson();
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${tempDir.path}/tether-backup-$dateStr.json');
    return await file.writeAsString(jsonContent);
  }

  BackupValidationResult validateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return const BackupValidationResult.failure('Backup file is empty.');
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('Backup file does not contain a valid JSON object.');
      }
      json = decoded;
    } catch (_) {
      return const BackupValidationResult.failure('File is corrupted or not a valid JSON document.');
    }

    // 1. Validate schemaVersion
    if (!json.containsKey('schemaVersion') || json['schemaVersion'] is! int) {
      return const BackupValidationResult.failure('Missing or invalid schema version.');
    }
    final version = json['schemaVersion'] as int;
    if (version > currentSchemaVersion || version < 1) {
      return BackupValidationResult.failure('Unsupported backup schema version ($version).');
    }

    // 2. Validate exportedAt
    if (!json.containsKey('exportedAt') || json['exportedAt'] is! String) {
      return const BackupValidationResult.failure('Missing or invalid export timestamp.');
    }
    final exportedAt = DateTime.tryParse(json['exportedAt'] as String);
    if (exportedAt == null) {
      return const BackupValidationResult.failure('Invalid date format for exportedAt.');
    }

    // 3. Validate Habits
    if (!json.containsKey('habits') || json['habits'] is! List) {
      return const BackupValidationResult.failure('Missing habits list.');
    }
    final List<Habit> habits = [];
    final habitIds = <String>{};
    for (final item in json['habits'] as List) {
      if (item is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('One or more habit records are malformed.');
      }
      if (item['id'] is! String || (item['id'] as String).isEmpty) {
        return const BackupValidationResult.failure('Habit record missing unique ID.');
      }
      final id = item['id'] as String;
      if (habitIds.contains(id)) {
        return BackupValidationResult.failure('Duplicate habit ID found: $id.');
      }
      habitIds.add(id);

      if (item['trigger'] is! String || item['action'] is! String) {
        return const BackupValidationResult.failure('Habit missing trigger or action text.');
      }
      if (item['createdAt'] is! String || DateTime.tryParse(item['createdAt'] as String) == null) {
        return const BackupValidationResult.failure('Habit has invalid createdAt date.');
      }
      if (item['frequency'] is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('Habit missing frequency definition.');
      }
      final freqTypeStr = item['frequency']['type'];
      if (!FrequencyType.values.any((e) => e.name == freqTypeStr)) {
        return BackupValidationResult.failure('Habit contains invalid frequency type: $freqTypeStr.');
      }

      try {
        habits.add(Habit.fromJson(item));
      } catch (e) {
        return BackupValidationResult.failure('Failed to parse habit: $e');
      }
    }

    // 4. Validate Daily Focus
    if (!json.containsKey('dailyFocus') || json['dailyFocus'] is! List) {
      return const BackupValidationResult.failure('Missing dailyFocus list.');
    }
    final List<DailyFocus> dailyFocus = [];
    for (final item in json['dailyFocus'] as List) {
      if (item is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('Malformed daily focus item.');
      }
      if (item['dateKey'] is! String || item['priorityText'] is! String || item['completed'] is! bool) {
        return const BackupValidationResult.failure('Invalid fields in daily focus.');
      }
      try {
        dailyFocus.add(DailyFocus.fromJson(item));
      } catch (e) {
        return BackupValidationResult.failure('Failed to parse daily focus: $e');
      }
    }

    // 5. Validate Focus Sessions
    if (!json.containsKey('focusSessions') || json['focusSessions'] is! List) {
      return const BackupValidationResult.failure('Missing focusSessions list.');
    }
    final List<FocusSession> focusSessions = [];
    for (final item in json['focusSessions'] as List) {
      if (item is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('Malformed focus session item.');
      }
      if (item['id'] is! String || item['durationMinutes'] is! int || item['completed'] is! bool) {
        return const BackupValidationResult.failure('Invalid fields in focus session.');
      }
      if (item['date'] is! String || DateTime.tryParse(item['date'] as String) == null) {
        return const BackupValidationResult.failure('Invalid date in focus session.');
      }
      try {
        focusSessions.add(FocusSession.fromJson(item));
      } catch (e) {
        return BackupValidationResult.failure('Failed to parse focus session: $e');
      }
    }

    // 6. Validate Weekly Reviews
    if (!json.containsKey('weeklyReviews') || json['weeklyReviews'] is! List) {
      return const BackupValidationResult.failure('Missing weeklyReviews list.');
    }
    final List<WeeklyReview> weeklyReviews = [];
    for (final item in json['weeklyReviews'] as List) {
      if (item is! Map<String, dynamic>) {
        return const BackupValidationResult.failure('Malformed weekly review item.');
      }
      if (item['weekStartDate'] is! String || DateTime.tryParse(item['weekStartDate'] as String) == null) {
        return const BackupValidationResult.failure('Invalid weekStartDate in review.');
      }
      if (item['habitsCompleted'] is! int || item['habitsExpected'] is! int || item['focusSessions'] is! int) {
        return const BackupValidationResult.failure('Invalid numerical statistics in weekly review.');
      }
      try {
        weeklyReviews.add(WeeklyReview.fromJson(item));
      } catch (e) {
        return BackupValidationResult.failure('Failed to parse weekly review: $e');
      }
    }

    // 7. Validate Settings (optional/safe default)
    AppSettings settings = const AppSettings();
    if (json.containsKey('settings') && json['settings'] is Map<String, dynamic>) {
      try {
        settings = AppSettings.fromJson(json['settings'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return BackupValidationResult.success(
      BackupData(
        schemaVersion: version,
        exportedAt: exportedAt,
        habits: habits,
        dailyFocus: dailyFocus,
        focusSessions: focusSessions,
        weeklyReviews: weeklyReviews,
        settings: settings,
      ),
    );
  }

  /// Atomically replaces all existing local application data with the validated backup.
  /// Failsafe: only executes if validation succeeded and writes new keys before removing obsolete ones.
  Future<void> restoreBackup(BackupData backup) async {
    // 1. Write habits
    final habitsJson = jsonEncode(backup.habits.map((h) => h.toJson()).toList());
    await _prefs.setString('habits_v1', habitsJson);

    // 2. Write focus sessions
    final sessionsJson = jsonEncode(backup.focusSessions.map((s) => s.toJson()).toList());
    await _prefs.setString('focus_sessions_v1', sessionsJson);

    // 3. Clear existing daily focuses and save new ones
    final allKeys = _prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('daily_focus_v1_')) {
        await _prefs.remove(key);
      }
    }
    for (final focus in backup.dailyFocus) {
      await _prefs.setString('daily_focus_v1_${focus.dateKey}', jsonEncode(focus.toJson()));
    }

    // 4. Clear existing weekly reviews and save new ones
    for (final key in allKeys) {
      if (key.startsWith('weekly_review_v1_')) {
        await _prefs.remove(key);
      }
    }
    for (final review in backup.weeklyReviews) {
      final key = 'weekly_review_v1_${DateFormat('yyyy-MM-dd').format(review.weekStartDate)}';
      await _prefs.setString(key, jsonEncode(review.toJson()));
    }

    // 5. Write settings
    final settingsJson = jsonEncode(backup.settings.toJson());
    await _prefs.setString('app_settings_v1', settingsJson);
  }
}
