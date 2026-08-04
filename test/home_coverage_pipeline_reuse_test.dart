import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home consumes the shared H6 coverage pipeline', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final pipeline = File(
      'lib/logic/calendar/builders/calendar_day_coverage_pipeline.dart',
    ).readAsStringSync();
    final calendar = File(
      'lib/screens/calendario_screen_stepa.dart',
    ).readAsStringSync();

    expect(home, contains('CalendarDayCoveragePipeline'));
    expect(home, contains('CoverageResultStepA'));
    expect(home, contains('AliceHomeRiskViewModelBuilder'));
    expect(home, contains('CalendarDayStatusBuilder'));
    expect(calendar, contains('CalendarDayCoveragePipeline'));

    expect(pipeline, contains('CalendarDayCoverageInputResolver'));
    expect(pipeline, contains('CalendarDayCoverageCoordinator'));
  });

  test('Home contains no local or adapter coverage decision path', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(home, isNot(contains('aliceHomeRiskDetailsForDay')));
    expect(home, isNot(contains('realGapDetailsForDay')));
    expect(home, isNot(contains('ipsStore.coverage')));
    expect(home, isNot(contains('coverageEngine')));
    expect(home, isNot(contains('_HomeCoverageIssue')));
    expect(home, isNot(contains('supportStart.isAfter')));
    expect(home, isNot(contains('supportEnd.isBefore')));
  });
}
