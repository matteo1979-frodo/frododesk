import '../../../models/day_override.dart';
import '../../core_store.dart';
import '../models/coverage_result_step_a.dart';
import 'calendar_day_coverage_coordinator.dart';
import 'calendar_day_coverage_input_resolver.dart';

/// Shared composition root for the H6 day-coverage pipeline.
///
/// Screens consume [CoverageResultStepA] and do not assemble CoverageEngine
/// inputs or repeat coverage transformations locally.
class CalendarDayCoveragePipeline {
  final CoreStore coreStore;

  const CalendarDayCoveragePipeline({required this.coreStore});

  CoverageResultStepA build({
    required DateTime selectedDay,
    required DateTime observedAt,
    DayOverrides? overrides,
  }) {
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final inputs = CalendarDayCoverageInputResolver(coreStore: coreStore)
        .resolve(
          selectedDay: day,
          overrides: overrides ?? coreStore.overrideStore.getForDay(day),
        );
    final coordinator = CalendarDayCoverageCoordinator(
      analyze: (request) => coreStore.coverageEngine.analyzeDay(
        day: request.day,
        uscita13: request.uscita13,
        sandraMorningAvailable: request.sandraMorningAvailable,
        sandraLunchAvailable: request.sandraLunchAvailable,
        sandraEveningAvailable: request.sandraEveningAvailable,
        overrides: request.overrides,
        ferieStore: request.ferieStore,
        schoolInCover: request.schoolInCover,
        schoolOutCover: request.schoolOutCover,
        schoolOutStart: request.schoolOutStart,
        schoolOutEnd: request.schoolOutEnd,
        lunchCover: request.lunchCover,
        uscitaAnticipataAt: request.uscitaAnticipataAt,
      ),
    );

    return coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      inputs: inputs,
    );
  }
}
