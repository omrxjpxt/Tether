import 'package:intl/intl.dart';

class DateUtilsLocal {
  static final DateFormat _format = DateFormat('yyyy-MM-dd');

  static String todayKey(DateTime now) {
    return _format.format(now);
  }

  static String yesterdayKey(DateTime now) {
    return _format.format(now.subtract(const Duration(days: 1)));
  }

  static String dateKey(DateTime date) {
    return _format.format(date);
  }

  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return _format.parse(key);
  }

  static bool isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date, DateTime now) {
    return isSameLocalDay(date, now);
  }

  static int daysBetweenLocalDates(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateB.difference(dateA).inDays;
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool isWeekday(DateTime date) {
    return !isWeekend(date);
  }

  static DateTime startOfWeek(DateTime date) {
    final daysSinceMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysSinceMonday);
  }

  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return start.add(const Duration(days: 6));
  }
}
