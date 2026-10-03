import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tether/core/utils/date_utils.dart';
import 'package:tether/features/habits/domain/models/habit.dart';
import 'package:tether/features/habits/domain/models/habit_frequency.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> isPermissionGranted();
  Future<void> scheduleHabitReminder(Habit habit);
  Future<void> cancelHabitReminder(String habitId);
  Future<void> rescheduleAllHabitReminders(List<Habit> habits);
  Future<void> handleHabitCompletionChanged(Habit habit, bool isCompletedToday);
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'tether_reminders';
  static const String channelName = 'Habit Reminders';
  static const String channelDescription = 'Daily reminders for your Tether habit stacks.';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(tz.local.name));
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.areNotificationsEnabled();
        return granted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final permissions = await iosImpl.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
    }
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Deterministic ID generator from habit ID and day of week (0 = general/daily, 1..7 = Monday..Sunday)
  int getNotificationId(String habitId, [int day = 0]) {
    final base = habitId.hashCode.abs() % 100000;
    return base * 10 + day;
  }

  @override
  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      await cancelHabitReminder(habit.id);
      return;
    }

    await cancelHabitReminder(habit.id);

    final notificationDetails = const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final reminder = habit.reminderTime!;
    final body = 'After I ${habit.trigger}, I will ${habit.action}.';

    final daysToSchedule = _getActiveDays(habit);

    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final isCompletedToday = habit.completedDates.contains(DateUtilsLocal.todayKey(now));

    for (final day in daysToSchedule) {
      final id = getNotificationId(habit.id, day);
      final scheduledDate = _nextInstanceOfDayAndTime(day, reminder.hour, reminder.minute);

      tz.TZDateTime finalScheduledDate = scheduledDate;
      if (day == todayWeekday && isCompletedToday) {
        final todayScheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          reminder.hour,
          reminder.minute,
        );
        if (scheduledDate.isBefore(todayScheduled.add(const Duration(minutes: 1)))) {
          finalScheduledDate = scheduledDate.add(const Duration(days: 7));
        }
      }

      await _plugin.zonedSchedule(
        id: id,
        title: 'Tether',
        body: body,
        scheduledDate: finalScheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  @override
  Future<void> cancelHabitReminder(String habitId) async {
    for (int day = 0; day <= 7; day++) {
      final id = getNotificationId(habitId, day);
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<void> rescheduleAllHabitReminders(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.reminderTime != null && !habit.archived) {
        await scheduleHabitReminder(habit);
      } else {
        await cancelHabitReminder(habit.id);
      }
    }
  }

  @override
  Future<void> handleHabitCompletionChanged(Habit habit, bool isCompletedToday) async {
    if (habit.reminderTime == null) return;
    await scheduleHabitReminder(habit);
  }

  List<int> _getActiveDays(Habit habit) {
    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return const [1, 2, 3, 4, 5, 6, 7];
      case FrequencyType.weekdays:
        return const [1, 2, 3, 4, 5];
      case FrequencyType.custom:
        return habit.frequency.customDays ?? const [1, 2, 3, 4, 5, 6, 7];
      case FrequencyType.timesPerWeek:
        return const [1, 2, 3, 4, 5, 6, 7];
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int targetWeekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != targetWeekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
