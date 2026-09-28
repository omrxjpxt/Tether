import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tether/app/theme/app_spacing.dart';
import 'package:tether/app/theme/app_typography.dart';
import 'package:tether/core/services/backup_provider.dart';
import 'package:tether/core/services/notification_providers.dart';
import 'package:tether/features/focus/presentation/providers/focus_providers.dart';
import 'package:tether/features/habits/presentation/providers/habit_providers.dart';
import 'package:tether/features/review/presentation/providers/review_providers.dart';
import 'package:tether/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _notificationsPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final granted = await ref.read(notificationServiceProvider).isPermissionGranted();
    if (mounted) {
      setState(() {
        _notificationsPermissionGranted = granted;
      });
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();
    try {
      final backupService = ref.read(backupServiceProvider);
      final file = await backupService.writeBackupToFile();
      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final originRect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Tether Backup (${DateFormat.yMMMd().format(DateTime.now())})',
          sharePositionOrigin: originRect,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup ready to export')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    HapticFeedback.lightImpact();
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFile == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final jsonContent = await pickedFile.xFile.readAsString();

      final backupService = ref.read(backupServiceProvider);
      final validation = backupService.validateBackup(jsonContent);

      if (!mounted) return;

      if (!validation.isValid) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Backup'),
            content: Text(
              validation.errorMessage ?? 'The selected file is not a valid Tether backup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      final backupData = validation.data!;
      final dateStr = DateFormat.yMMMd().format(backupData.exportedAt);

      // Confirmation before destructive atomic replacement
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace current data?'),
          content: Text(
            'This will replace your current Tether data with the backup from $dateStr containing ${backupData.habits.length} habits.\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary,
                foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
              ),
              child: const Text('Replace Data'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }

      // Execute atomic restore
      await backupService.restoreBackup(backupData);

      // Invalidate and refresh Riverpod providers
      ref.invalidate(habitsProvider);
      ref.invalidate(focusSessionsProvider);
      ref.invalidate(dailyFocusProvider);
      ref.invalidate(currentWeeklyReviewProvider);
      await ref.read(appSettingsProvider.notifier).reload();

      // Reschedule reminders
      await ref
          .read(notificationServiceProvider)
          .rescheduleAllHabitReminders(backupData.habits);

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            children: [
              Text('Settings', style: AppTypography.headingLarge),
              const SizedBox(height: AppSpacing.xxl),

              // APPEARANCE SECTION
              Text('APPEARANCE', style: AppTypography.metadata),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _ThemeOptionTile(
                      label: 'System',
                      subtitle: 'Match device appearance',
                      isSelected: settings.themeMode == 'system',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appSettingsProvider.notifier).updateThemeMode('system');
                      },
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _ThemeOptionTile(
                      label: 'Light',
                      subtitle: 'Warm and minimal paper look',
                      isSelected: settings.themeMode == 'light',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appSettingsProvider.notifier).updateThemeMode('light');
                      },
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _ThemeOptionTile(
                      label: 'Dark',
                      subtitle: 'Calm and focused dark theme',
                      isSelected: settings.themeMode == 'dark',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appSettingsProvider.notifier).updateThemeMode('dark');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // NOTIFICATIONS SECTION
              Text('NOTIFICATIONS', style: AppTypography.metadata),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _notificationsPermissionGranted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: _notificationsPermissionGranted
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Habit Reminders', style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            _notificationsPermissionGranted
                                ? 'Scheduled according to your habits'
                                : 'Disabled in system settings',
                            style: AppTypography.metadata.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_notificationsPermissionGranted)
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final granted = await ref.read(notificationServiceProvider).requestPermission();
                          if (mounted) {
                            setState(() => _notificationsPermissionGranted = granted);
                            if (!granted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications are disabled. You can enable them in system settings.'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Enable'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // DATA & BACKUP SECTION
              Text('DATA & BACKUP', style: AppTypography.metadata),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file_outlined),
                      title: Text('Export backup', style: AppTypography.body),
                      subtitle: Text(
                        'Save your habits, focus sessions, and reviews to JSON',
                        style: AppTypography.metadata.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: _isExporting ? null : _exportBackup,
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('Import backup', style: AppTypography.body),
                      subtitle: Text(
                        'Restore your Tether data from a JSON backup file',
                        style: AppTypography.metadata.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: _isImporting ? null : _importBackup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ABOUT SECTION
              Text('ABOUT', style: AppTypography.metadata),
              const SizedBox(height: AppSpacing.s),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tether', style: AppTypography.headingSection),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Build habits that stick.',
                      style: AppTypography.body.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'A calm, offline-first personal habit and focus application built around habit stacking. All data stays securely on your device.',
                      style: AppTypography.body.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Version 1.0.0 (Build 1)',
                      style: AppTypography.metadata.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.metadata.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
