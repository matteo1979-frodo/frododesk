import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/turn_ui_observation_filter.dart';
import 'package:frododesk/logic/calendar/models/date_range.dart';
import 'package:frododesk/logic/calendar/models/turn_event_conflict.dart';
import 'package:frododesk/models/real_event.dart';

void main() {
  const filter = TurnUiObservationFilter();
  final day = DateTime(2026, 8, 2);

  RealEvent event(String id, int startHour, int endHour) => RealEvent(
    id: id,
    startDate: day,
    endDate: day,
    title: id,
    startTime: TimeOfDay(hour: startHour, minute: 0),
    endTime: TimeOfDay(hour: endHour, minute: 0),
    personKey: 'matteo',
  );

  group('turn UI observes the render instant', () {
    test('screen acquires once and propagates the render instant', () {
      final source = File(
        'lib/screens/calendario_screen_stepa.dart',
      ).readAsStringSync();
      final buildSource = source.substring(
        source.indexOf('  Widget build(BuildContext context) {'),
        source.indexOf('  Widget _weekNavBar()'),
      );

      expect('DateTime.now()'.allMatches(buildSource), hasLength(1));
      expect(
        buildSource,
        contains('_buildFamilyNowSnapshot(observedAt: observedAt)'),
      );
      expect(
        buildSource,
        contains(
          '_buildDayCoverage(day: _selectedDay, observedAt: observedAt)',
        ),
      );
      expect(buildSource, contains('observedAt: observedAt'));

      final conflictHelper = source.substring(
        source.indexOf('  Widget _turnEventConflictBox({'),
        source.indexOf('  Widget _turnRow('),
      );
      final rowHelper = source.substring(
        source.indexOf('  Widget _turnRow('),
        source.indexOf('  Widget _familyEventsBlock('),
      );

      expect(conflictHelper, isNot(contains('DateTime.now()')));
      expect(rowHelper, isNot(contains('DateTime.now()')));
      expect(conflictHelper, contains('now: observedAt'));
      expect(rowHelper, contains('observedAt: observedAt'));
    });

    test('current day before, during and after an event', () {
      final events = [event('turn-event', 8, 16)];

      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day,
          observedAt: DateTime(2026, 8, 2, 7, 59),
        ),
        hasLength(1),
      );
      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day,
          observedAt: DateTime(2026, 8, 2, 12),
        ),
        hasLength(1),
      );
      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day,
          observedAt: DateTime(2026, 8, 2, 16),
        ),
        isEmpty,
      );
    });

    test('past and future selected days preserve all events', () {
      final events = [event('ended', 8, 9)];
      final observedAt = DateTime(2026, 8, 2, 12);

      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day.subtract(const Duration(days: 1)),
          observedAt: observedAt,
        ),
        hasLength(1),
      );
      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day.add(const Duration(days: 1)),
          observedAt: observedAt,
        ),
        hasLength(1),
      );
    });

    test('conflict is visible only until its overlap ends today', () {
      final conflict = TurnEventConflictResolution(
        event: event('conflict', 9, 11),
        state: TurnEventConflictState.open,
        overlapRange: DateRange(
          start: DateTime(2026, 8, 2, 9),
          end: DateTime(2026, 8, 2, 11),
        ),
      );

      expect(
        [conflict].visibleAt(selectedDay: day, now: DateTime(2026, 8, 2, 10)),
        hasLength(1),
      );
      expect(
        [conflict].visibleAt(selectedDay: day, now: DateTime(2026, 8, 2, 11)),
        isEmpty,
      );
    });

    test('overnight conflict remains visible after midnight', () {
      final overnight = TurnEventConflictResolution(
        event: event('overnight', 22, 23),
        state: TurnEventConflictState.open,
        overlapRange: DateRange(
          start: DateTime(2026, 8, 2, 22),
          end: DateTime(2026, 8, 3, 6),
        ),
      );

      expect(
        [overnight].visibleAt(
          selectedDay: DateTime(2026, 8, 3),
          now: DateTime(2026, 8, 3, 2),
        ),
        hasLength(1),
      );
    });

    test('event outside the turn window does not create a conflict', () {
      final visible = filter.visibleEvents(
        events: [event('outside', 18, 19)],
        selectedDay: day,
        observedAt: DateTime(2026, 8, 2, 10),
      );

      expect(visible.single.id, 'outside');
    });

    test('rapid selected-day changes always use the supplied instant', () {
      final events = [event('ended', 8, 9)];
      final observedAt = DateTime(2026, 8, 2, 12);

      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day,
          observedAt: observedAt,
        ),
        isEmpty,
      );
      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day.add(const Duration(days: 1)),
          observedAt: observedAt,
        ),
        hasLength(1),
      );
      expect(
        filter.visibleEvents(
          events: events,
          selectedDay: day,
          observedAt: observedAt,
        ),
        isEmpty,
      );
    });
  });
}
