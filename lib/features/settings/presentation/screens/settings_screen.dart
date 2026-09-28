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
                elevation: 0,
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
    final colors = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            children: [
              Text('Settings', style: AppTypography.headingLarge),
              const SizedBox(height: 36),

              // APPEARANCE SECTION
              _SectionLabel('APPEARANCE'),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
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
                    Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
                    _ThemeOptionTile(
                      label: 'Light',
                      subtitle: 'Warm and minimal',
                      isSelected: settings.themeMode == 'light',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appSettingsProvider.notifier).updateThemeMode('light');
                      },
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
                    _ThemeOptionTile(
                      label: 'Dark',
                      subtitle: 'Calm and focused',
                      isSelected: settings.themeMode == 'dark',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appSettingsProvider.notifier).updateThemeMode('dark');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // NOTIFICATIONS SECTION
              _SectionLabel('NOTIFICATIONS'),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      _notificationsPermissionGranted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: _notificationsPermissionGranted
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habit Reminders',
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _notificationsPermissionGranted
                                ? 'Scheduled per habit'
                                : 'Disabled in system settings',
                            style: AppTypography.caption.copyWith(
                              color: colors.outline,
                              fontSize: 12,
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

              const SizedBox(height: 32),

              // DATA & BACKUP SECTION
              _SectionLabel('DATA & BACKUP'),
              const SizedBox(height: AppSpacing.s),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.upload_file_outlined,
                      title: 'Export backup',
                      subtitle: 'Save habits, sessions, and reviews',
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colors.outline,
                            ),
                      onTap: _isExporting ? null : _exportBackup,
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
                    _SettingsRow(
                      icon: Icons.download_outlined,
                      title: 'Import backup',
                      subtitle: 'Restore from a JSON file',
                      trailing: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colors.outline,
                            ),
                      onTap: _isImporting ? null : _importBackup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ABOUT
              Center(
                child: Column(
                  children: [
                    Text(
                      'Tether',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build habits that stick.',
                      style: AppTypography.caption.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Calm, offline-first habit tracking.\nAll data stays on your device.',
                      style: AppTypography.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.metadata.copyWith(
                        color: colors.outline,
                        fontSize: 11,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.metadata.copyWith(
        color: Theme.of(context).colorScheme.outline,
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
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: colors.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: colors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: colors.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
