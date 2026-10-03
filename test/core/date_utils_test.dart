import 'package:flutter_test/flutter_test.dart';
import 'package:tether/core/utils/date_utils.dart';

void main() {
  group('DateUtilsLocal', () {
    test('todayKey generates correct format', () {
      final date = DateTime(2026, 9, 28, 14, 30);
      expect(DateUtilsLocal.todayKey(date), '2026-09-28');
    });

    test('yesterdayKey generates correct format', () {
      final date = DateTime(2026, 9, 28, 14, 30);
      expect(DateUtilsLocal.yesterdayKey(date), '2026-09-27');
    });

    test('parseDateKey returns correct local DateTime', () {
      final date = DateUtilsLocal.parseDateKey('2026-09-28');
      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 28);
      expect(date.isUtc, false);
    });

    test('isSameLocalDay', () {
      final a = DateTime(2026, 9, 28, 14, 30);
      final b = DateTime(2026, 9, 28, 8, 15);
      final c = DateTime(2026, 9, 29, 8, 15);
      expect(DateUtilsLocal.isSameLocalDay(a, b), isTrue);
      expect(DateUtilsLocal.isSameLocalDay(a, c), isFalse);
    });

    test('daysBetweenLocalDates', () {
      final a = DateTime(2026, 9, 28, 23, 59);
      final b = DateTime(2026, 9, 30, 0, 1);
      expect(DateUtilsLocal.daysBetweenLocalDates(a, b), 2);
      expect(DateUtilsLocal.daysBetweenLocalDates(b, a), -2);
    });
    
    test('startOfWeek and endOfWeek', () {
      final wednesday = DateTime(2026, 9, 30); // Sep 30 2026 is Wednesday
      final start = DateUtilsLocal.startOfWeek(wednesday);
      final end = DateUtilsLocal.endOfWeek(wednesday);
      
      expect(start.year, 2026);
      expect(start.month, 9);
      expect(start.day, 28); // Monday
      
      expect(end.year, 2026);
      expect(end.month, 10);
      expect(end.day, 4); // Sunday
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('addDays handles calendar days across month and year boundaries correctly', () {
      final leapYear = DateTime(2028, 2, 28);
      final leapNext = DateUtilsLocal.addDays(leapYear, 1);
      expect(leapNext.day, 29); // Leap year Feb 29

      final endOfYear = DateTime(2026, 12, 31, 10, 0);
      final newYear = DateUtilsLocal.addDays(endOfYear, 1);
      expect(newYear.year, 2027);
      expect(newYear.month, 1);
      expect(newYear.day, 1);

      final prevDay = DateUtilsLocal.addDays(newYear, -1);
      expect(prevDay.year, 2026);
      expect(prevDay.month, 12);
      expect(prevDay.day, 31);
    });
  });
}
