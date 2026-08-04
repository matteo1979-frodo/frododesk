import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home consumes the shared H6 coverage pipeline', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final coordinator = File(
      'lib/logic/home_snapshot_coordinator.dart',
    ).readAsStringSync();
    final pipeline = File(
      'lib/logic/calendar/builders/calendar_day_coverage_pipeline.dart',
    ).readAsStringSync();
    final calendar = File(
      'lib/screens/calendario_screen_stepa.dart',
    ).readAsStringSync();

    expect(home, contains('HomeSnapshotCoordinator'));
    expect(home, contains('HomeSnapshot'));
    expect(coordinator, contains('CalendarDayCoveragePipeline'));
    expect(coordinator, contains('CoverageResultStepA'));
    expect(coordinator, contains('AliceHomeRiskViewModelBuilder'));
    expect(coordinator, contains('CalendarDayStatusBuilder'));
    expect(calendar, contains('CalendarDayCoveragePipeline'));

    expect(pipeline, contains('CalendarDayCoverageInputResolver'));
    expect(pipeline, contains('CalendarDayCoverageCoordinator'));
  });

  test('Home contains no local or adapter coverage decision path', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(home, isNot(contains('CalendarDayCoveragePipeline')));
    expect(home, isNot(contains('CoverageResultStepA')));
    expect(home, isNot(contains('AliceHomeRiskViewModelBuilder')));
    expect(home, isNot(contains('CalendarDayStatusBuilder')));
    expect(home, isNot(contains('aliceHomeRiskDetailsForDay')));
    expect(home, isNot(contains('realGapDetailsForDay')));
    expect(home, isNot(contains('ipsStore.coverage')));
    expect(home, isNot(contains('coverageEngine')));
    expect(home, isNot(contains('_HomeCoverageIssue')));
    expect(home, isNot(contains('supportStart.isAfter')));
    expect(home, isNot(contains('supportEnd.isBefore')));
  });
}
