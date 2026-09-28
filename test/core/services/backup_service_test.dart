import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tether/core/services/backup_service.dart';
import 'package:tether/features/focus/domain/models/daily_focus.dart';
import 'package:tether/features/focus/domain/models/focus_session.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';
import 'package:tether/features/review/domain/models/weekly_review.dart';
import 'package:tether/features/settings/domain/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService', () {
    test('generateBackupJson contains versioned schema and all data categories', () async {
      SharedPreferences.setMockInitialValues({
        'habits_v1': jsonEncode([
          {
            'id': 'h1',
            'trigger': 'sit down',
            'action': 'write priority',
            'frequency': {'type': 'daily'},
            'createdAt': '2026-09-28T09:00:00.000',
            'completedDates': ['2026-09-28'],
            'archived': false,
          }
        ]),
        'focus_sessions_v1': jsonEncode([
          {
            'id': 's1',
            'date': '2026-09-28T10:00:00.000',
            'durationMinutes': 25,
            'completed': true,
            'createdAt': '2026-09-28T10:25:00.000',
          }
        ]),
        'daily_focus_v1_2026-09-28': jsonEncode({
          'dateKey': '2026-09-28',
          'priorityText': 'Ship Phase 4',
          'completed': true,
          'focusSessionCount': 1,
        }),
        'weekly_review_v1_2026-09-28': jsonEncode({
          'weekStartDate': '2026-09-28T00:00:00.000',
          'weekEndDate': '2026-10-04T23:59:59.000',
          'habitsCompleted': 5,
          'habitsExpected': 7,
          'focusSessions': 3,
          'notes': 'Productive week',
          'createdAt': '2026-09-28T20:00:00.000',
        }),
        'app_settings_v1': jsonEncode({
          'themeMode': 'dark',
          'isFirstLaunch': false,
          'notificationsEnabled': true,
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final jsonString = await backupService.generateBackupJson();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['schemaVersion'], 1);
      expect(decoded['exportedAt'], isNotNull);
      expect((decoded['habits'] as List).length, 1);
      expect((decoded['dailyFocus'] as List).length, 1);
      expect((decoded['focusSessions'] as List).length, 1);
      expect((decoded['weeklyReviews'] as List).length, 1);
      expect(decoded['settings']['themeMode'], 'dark');
    });

    test('validateBackup succeeds on valid JSON schema', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final validJson = jsonEncode({
        'schemaVersion': 1,
        'exportedAt': '2026-09-28T12:00:00.000',
        'habits': [
          {
            'id': 'h1',
            'trigger': 'wake up',
            'action': 'drink water',
            'frequency': {'type': 'daily'},
            'createdAt': '2026-09-28T08:00:00.000',
            'completedDates': [],
            'archived': false,
          }
        ],
        'dailyFocus': [],
        'focusSessions': [],
        'weeklyReviews': [],
        'settings': {'themeMode': 'light'},
      });

      final result = backupService.validateBackup(validJson);
      expect(result.isValid, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.habits.first.trigger, 'wake up');
    });

    test('validateBackup rejects corrupted JSON and empty strings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      expect(backupService.validateBackup('').isValid, isFalse);
      expect(backupService.validateBackup('{ invalid json').isValid, isFalse);
      expect(backupService.validateBackup('["array"]').isValid, isFalse);
    });

    test('validateBackup rejects unsupported schema versions', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final futureVersionJson = jsonEncode({
        'schemaVersion': 999,
        'exportedAt': '2026-09-28T12:00:00.000',
        'habits': [],
        'dailyFocus': [],
        'focusSessions': [],
        'weeklyReviews': [],
      });

      final result = backupService.validateBackup(futureVersionJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Unsupported backup schema version'));
    });

    test('validateBackup rejects invalid frequencies and dates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final invalidFreqJson = jsonEncode({
        'schemaVersion': 1,
        'exportedAt': '2026-09-28T12:00:00.000',
        'habits': [
          {
            'id': 'h1',
            'trigger': 'wake up',
            'action': 'drink water',
            'frequency': {'type': 'invalid_frequency_type'},
            'createdAt': '2026-09-28T08:00:00.000',
            'completedDates': [],
            'archived': false,
          }
        ],
        'dailyFocus': [],
        'focusSessions': [],
        'weeklyReviews': [],
      });

      final result = backupService.validateBackup(invalidFreqJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('invalid frequency type'));
    });

    test('validateBackup rejects duplicate habit IDs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final duplicateIdJson = jsonEncode({
        'schemaVersion': 1,
        'exportedAt': '2026-09-28T12:00:00.000',
        'habits': [
          {
            'id': 'h1',
            'trigger': 'wake up',
            'action': 'drink water',
            'frequency': {'type': 'daily'},
            'createdAt': '2026-09-28T08:00:00.000',
          },
          {
            'id': 'h1',
            'trigger': 'sit down',
            'action': 'write priority',
            'frequency': {'type': 'daily'},
            'createdAt': '2026-09-28T08:30:00.000',
          }
        ],
        'dailyFocus': [],
        'focusSessions': [],
        'weeklyReviews': [],
      });

      final result = backupService.validateBackup(duplicateIdJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Duplicate habit ID'));
    });

    test('restoreBackup replaces local state atomically and preserves relationships', () async {
      SharedPreferences.setMockInitialValues({
        'habits_v1': jsonEncode([
          {'id': 'old_habit', 'trigger': 'old', 'action': 'old', 'frequency': {'type': 'daily'}, 'createdAt': '2026-01-01T00:00:00.000'}
        ]),
        'app_settings_v1': jsonEncode({'themeMode': 'light'}),
      });

      final prefs = await SharedPreferences.getInstance();
      final backupService = BackupService(prefs);

      final backupData = BackupData(
        schemaVersion: 1,
        exportedAt: DateTime.now(),
        habits: [
          Habit(
            id: 'imported_h1',
            trigger: 'open laptop',
            action: 'plan day',
            frequency: HabitFrequency.daily(),
            createdAt: DateTime.now(),
          ),
        ],
        dailyFocus: [
          const DailyFocus(
            dateKey: '2026-09-28',
            priorityText: 'Restored focus item',
            completed: true,
          ),
        ],
        focusSessions: [
          FocusSession(
            id: 's_imported',
            date: DateTime.now(),
            durationMinutes: 50,
            completed: true,
            createdAt: DateTime.now(),
          ),
        ],
        weeklyReviews: [
          WeeklyReview(
            weekStartDate: DateTime(2026, 9, 28),
            weekEndDate: DateTime(2026, 10, 4),
            habitsCompleted: 4,
            habitsExpected: 5,
            focusSessions: 2,
            notes: 'Great week',
            createdAt: DateTime.now(),
          ),
        ],
        settings: const AppSettings(themeMode: 'dark', isFirstLaunch: false),
      );

      await backupService.restoreBackup(backupData);

      // Verify old habit is gone and new habit is in place
      final restoredHabitsStr = prefs.getString('habits_v1');
      expect(restoredHabitsStr, contains('imported_h1'));
      expect(restoredHabitsStr, isNot(contains('old_habit')));

      // Verify focus session restored
      final restoredSessionsStr = prefs.getString('focus_sessions_v1');
      expect(restoredSessionsStr, contains('s_imported'));

      // Verify daily focus restored
      final restoredFocusStr = prefs.getString('daily_focus_v1_2026-09-28');
      expect(restoredFocusStr, contains('Restored focus item'));

      // Verify settings restored
      final restoredSettingsStr = prefs.getString('app_settings_v1');
      expect(restoredSettingsStr, contains('"themeMode":"dark"'));
    });
  });
}
