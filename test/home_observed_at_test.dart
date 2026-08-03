import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/home_observed_at.dart';

void main() {
  test('HomeObservedAt derives day, minute and year from one instant', () {
    final instant = DateTime(2026, 8, 3, 14, 37, 12, 345, 678);
    final observedAt = HomeObservedAt(observedAt: instant);

    expect(observedAt.observedAt, same(instant));
    expect(observedAt.day, DateTime(2026, 8, 3));
    expect(observedAt.minuteOfDay, 14 * 60 + 37);
    expect(observedAt.year, 2026);
  });

  test('Home render path creates one clock and has no TimeOfDay.now', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();
    final renderPathStart = source.indexOf(
      'List<CoverageGapDetail> _todayCoverageDetails',
    );
    final renderPathEnd = source.indexOf(
      'Future<void> _showFinancePresentPopup',
    );
    final renderPath = source.substring(renderPathStart, renderPathEnd);

    expect('DateTime.now()'.allMatches(renderPath), hasLength(1));
    expect(renderPath, contains('HomeObservedAt(observedAt: DateTime.now())'));
    expect(renderPath, isNot(contains('TimeOfDay.now()')));
  });

  test('HomeObservedAt is pure and independent from UI and stores', () {
    final source = File('lib/models/home_observed_at.dart').readAsStringSync();

    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Theme')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('DateTime.now')));
  });
}
