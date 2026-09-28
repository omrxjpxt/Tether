import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tether/core/services/backup_service.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackupService(prefs);
});
