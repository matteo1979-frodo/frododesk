import '../../../models/day_override.dart';
import '../../../utils/calendario_formatters.dart';
import '../../core_store.dart';
import '../../ferie_period_store.dart';
import '../../turn_engine.dart';
import '../models/family_day_overview_snapshot.dart';
import 'person_effective_status_builder.dart';
import 'alice_day_context_builder.dart';

class FamilyDayOverviewSnapshotBuilder {
  const FamilyDayOverviewSnapshotBuilder();

  FamilyDayOverviewSnapshot build({
    required CoreStore coreStore,
    required DateTime day,
    required DayOverrides overrides,
  }) {
    final selectedDay = DateTime(day.year, day.month, day.day);

    final matteoDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'matteo',
      selectedDay,
    );

    final matteoIsInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.matteo,
      selectedDay,
    );

    final matteoEffectiveStatus = const PersonEffectiveStatusBuilder().build(
      manualOverride: overrides.matteo,
      diseasePeriod: matteoDisease,
      isInHolidayPeriod: matteoIsInHolidayPeriod,
    );

    final chiaraDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'chiara',
      selectedDay,
    );

    final chiaraIsInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.chiara,
      selectedDay,
    );

    final chiaraEffectiveStatus = const PersonEffectiveStatusBuilder().build(
      manualOverride: overrides.chiara,
      diseasePeriod: chiaraDisease,
      isInHolidayPeriod: chiaraIsInHolidayPeriod,
    );

    final matteoPlan = coreStore.turnEngine.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: selectedDay,
    );

    final chiaraPlan = coreStore.turnEngine.turnPlanForPersonDay(
      person: TurnPerson.chiara,
      day: selectedDay,
    );

    final matteoTurnLabel = const PersonEffectiveStatusBuilder().buildTurnLabel(
      isOff: matteoPlan.isOff,
      startText: fmtTimeOfDay(matteoPlan.start),
      endText: fmtTimeOfDay(matteoPlan.end),
    );

    final chiaraTurnLabel = const PersonEffectiveStatusBuilder().buildTurnLabel(
      isOff: chiaraPlan.isOff,
      startText: fmtTimeOfDay(chiaraPlan.start),
      endText: fmtTimeOfDay(chiaraPlan.end),
    );

    final aliceDayContext = AliceDayContextBuilder(
      coreStore,
    ).build(selectedDay);

    return FamilyDayOverviewSnapshot(
      day: selectedDay,
      matteoEffectiveStatus: matteoEffectiveStatus,
      chiaraEffectiveStatus: chiaraEffectiveStatus,
      matteoTurnLabel: matteoTurnLabel,
      chiaraTurnLabel: chiaraTurnLabel,
      aliceDayContext: aliceDayContext,
    );
  }
}
