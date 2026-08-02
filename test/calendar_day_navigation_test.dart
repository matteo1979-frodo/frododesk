import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/calendar_day_navigation.dart';
import 'package:frododesk/models/week_identity.dart';

void main() {
  const navigation = CalendarDayNavigation();

  group('calendar arrows navigate by one day', () {
    test('11 August moves to 10 or 12 August', () {
      final selectedDay = DateTime(2026, 8, 11);

      expect(navigation.previous(selectedDay), DateTime(2026, 8, 10));
      expect(navigation.next(selectedDay), DateTime(2026, 8, 12));
    });

    test('Sunday to Monday updates to the following week', () {
      final sunday = DateTime(2026, 8, 16);
      final monday = navigation.next(sunday);

      expect(monday, DateTime(2026, 8, 17));
      expect(WeekIdentity.fromDate(sunday).weekStart, DateTime(2026, 8, 10));
      expect(WeekIdentity.fromDate(monday).weekStart, DateTime(2026, 8, 17));
    });

    test('Monday to Sunday updates to the previous week', () {
      final monday = DateTime(2026, 8, 10);
      final sunday = navigation.previous(monday);

      expect(sunday, DateTime(2026, 8, 9));
      expect(WeekIdentity.fromDate(monday).weekStart, DateTime(2026, 8, 10));
      expect(WeekIdentity.fromDate(sunday).weekStart, DateTime(2026, 8, 3));
    });

    test('crosses month and year boundaries', () {
      expect(navigation.next(DateTime(2026, 8, 31)), DateTime(2026, 9, 1));
      expect(navigation.next(DateTime(2026, 12, 31)), DateTime(2027, 1, 1));
    });

    test('rapid clicks advance exactly once per invocation', () {
      var selectedDay = DateTime(2026, 8, 11);

      selectedDay = navigation.next(selectedDay);
      selectedDay = navigation.next(selectedDay);
      selectedDay = navigation.previous(selectedDay);

      expect(selectedDay, DateTime(2026, 8, 12));
    });

    test('screen keeps header date picker and explicit arrow callbacks', () {
      final source = File(
        'lib/screens/calendario_screen_stepa.dart',
      ).readAsStringSync();

      expect(source, contains('onTap: _pickCalendarDate'));
      expect(source, contains('initialDate: _selectedDay'));
      expect(source, contains('onPressed: _prevDay'));
      expect(source, contains('onPressed: _nextDay'));
      expect(source, contains('_dayNavigation.previous(_selectedDay)'));
      expect(source, contains('_dayNavigation.next(_selectedDay)'));
    });
  });
}
