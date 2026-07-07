import '../../../logic/core_store.dart';
import '../../../logic/coverage_engine.dart';
import '../../../logic/ferie_period_store.dart';
import '../../../logic/turn_engine.dart';
import '../../../models/day_override.dart';
import '../../../models/disease_period.dart';
import '../../../utils/calendario_formatters.dart';
import '../models/family_now_snapshot.dart';
import '../models/person_now_status.dart';

class FamilyNowSnapshotBuilder {
  const FamilyNowSnapshotBuilder();

  PersonNowStatus buildMatteoStatus({
    required CoreStore coreStore,
    required DateTime selectedDay,
    required DateTime now,
    required DayOverrides overrides,
    required CoverageEngine engine,
    required TurnEngine turns,
  }) {
    final nowDay = DateTime(now.year, now.month, now.day);

    final matteoOverride = overrides.matteo;
    final matteoDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'matteo',
      nowDay,
    );

    final matteoOnHoliday = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.matteo,
      nowDay,
    );

    final matteoBedSick =
        matteoOverride?.status == OverrideStatus.malattiaALetto ||
        matteoDisease?.type == DiseaseType.bed;

    final matteoEventsNow = coreStore.realEventStore
        .eventsForDay(nowDay)
        .where((e) => e.personKey == 'matteo');

    bool matteoBusyForEventNow = false;

    for (final event in matteoEventsNow) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        matteoBusyForEventNow = true;
        break;
      }
    }

    final matteoBusyForTurn = engine.isMatteoBusyBetween(
      now,
      now.add(const Duration(minutes: 1)),
    );

    final matteoPlan = turns.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: selectedDay,
    );

    String matteoTurnLabel = "Turno non previsto";

    if (!matteoPlan.isOff) {
      matteoTurnLabel =
          "Turno ${fmtTimeOfDay(matteoPlan.start)}–${fmtTimeOfDay(matteoPlan.end)}";
    }

    final matteoBusyNow =
        matteoBedSick || matteoBusyForTurn || matteoBusyForEventNow;

    final String matteoNowLabel;

    if (matteoDisease?.type == DiseaseType.mild) {
      matteoNowLabel = "malattia leggera";
    } else if (matteoBedSick) {
      matteoNowLabel = "occupato • malattia a letto";
    } else if (matteoOnHoliday) {
      matteoNowLabel = "libero • ferie";
    } else if (matteoBusyForEventNow) {
      matteoNowLabel = "occupato • evento";
    } else if (matteoBusyForTurn) {
      matteoNowLabel = "occupato • turno";
    } else {
      matteoNowLabel = "libero";
    }

    return PersonNowStatus(
      busyNow: matteoBusyNow,
      label: matteoNowLabel,
      turnLabel: matteoTurnLabel,
    );
  }

  FamilyNowSnapshot build() {
    throw UnimplementedError(
      'FamilyNowSnapshotBuilder non è ancora collegato al calendario.',
    );
  }
}
