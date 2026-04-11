import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';
import '../models/disease_period.dart';
import '../models/real_event.dart';
import '../models/work_shift.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'turn_engine.dart';
import 'day_settings_store.dart';
import 'support_network_store.dart';
import 'disease_period_store.dart';
import 'real_event_store.dart';

// ✅ NEW: Ferie lunghe
import 'ferie_period_store.dart';

// ✅ NEW: Eventi Alice
import 'alice_event_store.dart';

import 'alice_special_event_store.dart';
import '../models/alice_special_event.dart';

// ✅ NEW: Centro estivo settimanale
import 'summer_camp_schedule_store.dart';

// ✅ NEW: Eventi speciali centro estivo
import 'summer_camp_special_event_store.dart';

import 'alice_companion_store.dart';

class CoverageEngine {
  final TurnEngine turnEngine;
  final DaySettingsStore daySettingsStore;
  final SupportNetworkStore supportNetworkStore;
  final DiseasePeriodStore diseasePeriodStore;

  // ✅ NEW: Eventi reali
  final RealEventStore realEventStore;

  final AliceCompanionStore aliceCompanionStore;

  // ✅ NEW: Eventi Alice (aggancio strutturale)
  final AliceEventStore aliceEventStore;

  final AliceSpecialEventStore aliceSpecialEventStore;

  // ✅ NEW: Centro estivo settimanale (aggancio strutturale)
  final SummerCampScheduleStore summerCampScheduleStore;

  // ✅ NEW: Eventi speciali centro estivo (aggancio strutturale)
  final SummerCampSpecialEventStore summerCampSpecialEventStore;

  // Finestre Sandra (mutabili: UI le edita)
  TimeOfDay sandraCambioMattinaStart;
  TimeOfDay sandraCambioMattinaEnd;

  TimeOfDay sandraPranzoStart;
  TimeOfDay sandraPranzoEnd;

  TimeOfDay sandraSeraStart;
  TimeOfDay sandraSeraEnd;

  CoverageEngine({
    TurnEngine? turnEngine,
    DaySettingsStore? daySettingsStore,
    SupportNetworkStore? supportNetworkStore,
    DiseasePeriodStore? diseasePeriodStore,
    RealEventStore? realEventStore,
    AliceCompanionStore? aliceCompanionStore,
    AliceEventStore? aliceEventStore,
    AliceSpecialEventStore? aliceSpecialEventStore,
    SummerCampScheduleStore? summerCampScheduleStore,
    SummerCampSpecialEventStore? summerCampSpecialEventStore,
    TimeOfDay? sandraCambioMattinaStart,
    TimeOfDay? sandraCambioMattinaEnd,
    TimeOfDay? sandraPranzoStart,
    TimeOfDay? sandraPranzoEnd,
    TimeOfDay? sandraSeraStart,
    TimeOfDay? sandraSeraEnd,
  }) : turnEngine = turnEngine ?? TurnEngine(),
       aliceCompanionStore = aliceCompanionStore!,
       daySettingsStore = daySettingsStore ?? DaySettingsStore(),
       supportNetworkStore = supportNetworkStore ?? SupportNetworkStore(),
       diseasePeriodStore = diseasePeriodStore ?? DiseasePeriodStore(),
       realEventStore = realEventStore ?? RealEventStore(),
       aliceEventStore = aliceEventStore ?? AliceEventStore(),
       aliceSpecialEventStore =
           aliceSpecialEventStore ?? AliceSpecialEventStore(),
       summerCampScheduleStore =
           summerCampScheduleStore ?? SummerCampScheduleStore(),
       summerCampSpecialEventStore =
           summerCampSpecialEventStore ?? SummerCampSpecialEventStore(),
       sandraCambioMattinaStart =
           sandraCambioMattinaStart ?? const TimeOfDay(hour: 5, minute: 0),
       sandraCambioMattinaEnd =
           sandraCambioMattinaEnd ?? const TimeOfDay(hour: 6, minute: 35),
       sandraPranzoStart =
           sandraPranzoStart ?? const TimeOfDay(hour: 13, minute: 0),
       sandraPranzoEnd =
           sandraPranzoEnd ?? const TimeOfDay(hour: 14, minute: 30),
       sandraSeraStart =
           sandraSeraStart ?? const TimeOfDay(hour: 21, minute: 0),
       sandraSeraEnd = sandraSeraEnd ?? const TimeOfDay(hour: 22, minute: 35);

  // Pennina UI
  void setSandraCambioMattina(TimeOfDay start, TimeOfDay end) {
    sandraCambioMattinaStart = start;
    sandraCambioMattinaEnd = end;
  }

  void setSandraPranzo(TimeOfDay start, TimeOfDay end) {
    sandraPranzoStart = start;
    sandraPranzoEnd = end;
  }

  void setSandraSera(TimeOfDay start, TimeOfDay end) {
    sandraSeraStart = start;
    sandraSeraEnd = end;
  }

  bool isAliceAtHomeDay(DateTime day) {
    return aliceEventStore.isAliceAtHomeDay(day);
  }

  bool isAliceExternalActivityDay(DateTime day) {
    return aliceEventStore.isExternalActivityDay(day);
  }

  bool isAliceSchoolNormalDay(DateTime day) {
    return aliceEventStore.isSchoolNormalDay(day);
  }

  bool isAliceSummerCampOperationalDay(DateTime day) {
    final period = aliceEventStore.getSummerCampPeriodForDay(day);
    if (period == null) return false;

    final special = summerCampSpecialEventStore.getForDay(day);
    final config = summerCampScheduleStore.getConfigForDay(day);

    return special?.enabled ?? config.enabled;
  }

  AliceEventType? getAliceEventTypeForDay(DateTime day) {
    return aliceEventStore.getEventTypeForDay(day);
  }

  AliceEventPeriod? getSummerCampPeriodForDay(DateTime day) {
    return aliceEventStore.getSummerCampPeriodForDay(day);
  }

  SummerCampDayConfig getSummerCampConfigForDay(DateTime day) {
    return summerCampScheduleStore.getEffectiveConfigForDay(day);
  }

  SummerCampSpecialEvent? getSummerCampSpecialEventForDay(DateTime day) {
    return summerCampSpecialEventStore.getForDay(day);
  }

  bool hasSummerCampSpecialEventForDay(DateTime day) {
    return summerCampSpecialEventStore.hasEventForDay(day);
  }

  bool isSupportNetworkAvailableForRange({
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final d0 = _onlyDate(day);

    final fasciaStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      start.hour,
      start.minute,
    );

    final fasciaEnd = DateTime(d0.year, d0.month, d0.day, end.hour, end.minute);

    return _isCoveredBySupportNetwork(
      day: d0,
      fasciaStart: fasciaStart,
      fasciaEnd: fasciaEnd,
    );
  }

  CoverageSandraDecision sandraDecisionForDay({
    required DateTime day,
    required bool uscita13,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
  }) {
    final d0 = _onlyDate(day);

    final morningStart = _atTime(d0, sandraCambioMattinaStart);
    final morningEnd = _atTime(d0, sandraCambioMattinaEnd);

    final lunchBaseStart = _atTime(
      d0,
      uscita13 ? (uscitaAnticipataAt ?? sandraPranzoStart) : sandraPranzoStart,
    );
    final lunchEnd = _atTime(d0, sandraPranzoEnd);

    final eveningStart = _atTime(d0, sandraSeraStart);
    final eveningEnd = _atTime(d0, sandraSeraEnd);

    final activeSummerCampPeriod = getSummerCampPeriodForDay(d0);
    final specialEvent = getSummerCampSpecialEventForDay(d0);
    final dayConfig = getSummerCampConfigForDay(d0);

    final bool summerCampEnabled =
        activeSummerCampPeriod != null &&
        (specialEvent?.enabled ?? dayConfig.enabled);

    final DateTime? campStart = summerCampEnabled
        ? _atTime(d0, specialEvent?.start ?? dayConfig.start)
        : null;
    final DateTime? campEnd = summerCampEnabled
        ? _atTime(d0, specialEvent?.end ?? dayConfig.end)
        : null;

    DateTime mattinaCheckStart = morningStart;
    DateTime mattinaCheckEnd = morningEnd;

    if (campStart != null && campStart.isBefore(mattinaCheckEnd)) {
      mattinaCheckEnd = campStart;
    }

    final bool serveMattina = mattinaCheckEnd.isAfter(mattinaCheckStart)
        ? !_isFasciaCovered(
            day: d0,
            fasciaStart: mattinaCheckStart,
            fasciaEnd: mattinaCheckEnd,
            allowSandra: false,
            sandraMattinaAvailable: false,
            sandraPranzoAvailable: false,
            sandraSeraAvailable: false,
            isHomePresenceWindow: true,
            overrides: overrides,
            ferieStore: ferieStore,
          )
        : false;

    DateTime seraCheckStart = eveningStart;
    final DateTime seraCheckEnd = eveningEnd;

    if (campEnd != null && campEnd.isAfter(seraCheckStart)) {
      seraCheckStart = campEnd;
    }

    final bool serveSera = seraCheckEnd.isAfter(seraCheckStart)
        ? !_isFasciaCovered(
            day: d0,
            fasciaStart: seraCheckStart,
            fasciaEnd: seraCheckEnd,
            allowSandra: false,
            sandraMattinaAvailable: false,
            sandraPranzoAvailable: false,
            sandraSeraAvailable: false,
            isHomePresenceWindow: true,
            overrides: overrides,
            ferieStore: ferieStore,
          )
        : false;

    bool servePranzo = false;

    final bool aliceAtHomeDay = isAliceAtHomeDay(d0);
    final bool shouldCheckPranzo =
        uscita13 ||
        aliceAtHomeDay ||
        (campEnd != null && campEnd.isBefore(lunchEnd));

    if (shouldCheckPranzo) {
      DateTime lunchCheckStart = lunchBaseStart;

      // 🔥 SE ALICE È ACCOMPAGNATA, PARTI DOPO
      final companionEnd = _getAliceCompanionEnd(
        day: d0,
        start: lunchBaseStart,
        end: lunchEnd,
      );

      if (companionEnd != null && companionEnd.isAfter(lunchCheckStart)) {
        lunchCheckStart = companionEnd;
      }

      if (campEnd != null && campEnd.isAfter(lunchCheckStart)) {
        lunchCheckStart = campEnd;
      }

      if (lunchEnd.isAfter(lunchCheckStart)) {
        DateTime probe = lunchCheckStart;
        DateTime? firstUncoveredStart;

        while (probe.isBefore(lunchEnd)) {
          final nextProbe = probe.add(const Duration(minutes: 5));

          final segEnd = nextProbe.isAfter(lunchEnd) ? lunchEnd : nextProbe;

          final covered = _isFasciaCovered(
            day: d0,
            fasciaStart: probe,
            fasciaEnd: segEnd,
            allowSandra: false,
            sandraMattinaAvailable: false,
            sandraPranzoAvailable: false,
            sandraSeraAvailable: false,
            isHomePresenceWindow: true,
            overrides: overrides,
            ferieStore: ferieStore,
          );

          if (!covered) {
            firstUncoveredStart = probe;
            break;
          }

          probe = segEnd;
        }

        if (firstUncoveredStart != null) {
          servePranzo = true;
        }
      }
    }

    return CoverageSandraDecision(
      serveSandraMattina: serveMattina,
      serveSandraPranzo: servePranzo,
      serveSandraSera: serveSera,
    );
  }

  List<String> gapsForDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    TimeOfDay? schoolOutStart,
    TimeOfDay? schoolOutEnd,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
  }) {
    return analyzeDay(
      day: day,
      uscita13: uscita13,
      sandraAvailable: sandraAvailable,
      overrides: overrides,
      ferieStore: ferieStore,
      schoolOutStart: schoolOutStart,
      schoolOutEnd: schoolOutEnd,
      uscitaAnticipataAt: uscitaAnticipataAt,
      summerCampStart: summerCampStart,
      summerCampEnd: summerCampEnd,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      lunchCover: lunchCover,
    ).gaps;
  }

  List<String> gapsForDayV2({
    required DateTime day,
    required bool uscita13,
    required bool sandraMattinaOn,
    required bool sandraPranzoOn,
    required bool sandraSeraOn,
    required TimeOfDay schoolStart,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 17, minute: 15),
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    return analyzeDayV2(
      day: day,
      uscita13: uscita13,
      sandraMattinaOn: sandraMattinaOn,
      sandraPranzoOn: sandraPranzoOn,
      sandraSeraOn: sandraSeraOn,
      schoolStart: schoolStart,
      overrides: overrides,
      ferieStore: ferieStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: schoolOutStart,
      schoolOutEnd: schoolOutEnd,
      lunchCover: lunchCover,
      uscitaAnticipataAt: uscitaAnticipataAt,
      summerCampStart: summerCampStart,
      summerCampEnd: summerCampEnd,
    ).gaps;
  }

  bool hasAliceHomeRiskForDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraMattinaOn,
    required bool sandraPranzoOn,
    required bool sandraSeraOn,
    required TimeOfDay schoolStart,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 17, minute: 15),
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    final analysis = analyzeDayV2(
      day: day,
      uscita13: uscita13,
      sandraMattinaOn: sandraMattinaOn,
      sandraPranzoOn: sandraPranzoOn,
      sandraSeraOn: sandraSeraOn,
      schoolStart: schoolStart,
      overrides: overrides,
      ferieStore: ferieStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: schoolOutStart,
      schoolOutEnd: schoolOutEnd,
      lunchCover: lunchCover,
      uscitaAnticipataAt: uscitaAnticipataAt,
      summerCampStart: summerCampStart,
      summerCampEnd: summerCampEnd,
    );

    return analysis.details.any(
      (detail) => detail.label.toLowerCase().startsWith('alice a casa'),
    );
  }

  List<CoverageGapDetail> aliceHomeRiskDetailsForDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraMattinaOn,
    required bool sandraPranzoOn,
    required bool sandraSeraOn,
    required TimeOfDay schoolStart,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 17, minute: 15),
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    final analysis = analyzeDayV2(
      day: day,
      uscita13: uscita13,
      sandraMattinaOn: sandraMattinaOn,
      sandraPranzoOn: sandraPranzoOn,
      sandraSeraOn: sandraSeraOn,
      schoolStart: schoolStart,
      overrides: overrides,
      ferieStore: ferieStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: schoolOutStart,
      schoolOutEnd: schoolOutEnd,
      lunchCover: lunchCover,
      uscitaAnticipataAt: uscitaAnticipataAt,
      summerCampStart: summerCampStart,
      summerCampEnd: summerCampEnd,
    );

    return analysis.details
        .where(
          (detail) => detail.label.toLowerCase().startsWith('alice a casa'),
        )
        .toList(growable: false);
  }

  CoverageDayAnalysis analyzeDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    TimeOfDay? schoolOutStart,
    TimeOfDay? schoolOutEnd,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
  }) {
    return analyzeDayV2(
      day: day,
      uscita13: uscita13,
      sandraMattinaOn: sandraAvailable,
      sandraPranzoOn: sandraAvailable,
      sandraSeraOn: sandraAvailable,
      schoolStart: const TimeOfDay(hour: 8, minute: 25),
      overrides: overrides,
      ferieStore: ferieStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      lunchCover: lunchCover,
      schoolOutStart: schoolOutStart ?? const TimeOfDay(hour: 16, minute: 25),
      schoolOutEnd: schoolOutEnd ?? const TimeOfDay(hour: 17, minute: 15),
      uscitaAnticipataAt: uscitaAnticipataAt,
      summerCampStart: summerCampStart,
      summerCampEnd: summerCampEnd,
    );
  }

  bool isMatteoBusyBetween(
    DateTime start,
    DateTime end, {
    DayOverrides? overrides,
    FeriePeriodStore? ferieStore,
    bool isHomePresenceWindow = false,
  }) {
    final available = _canSpecificPersonCoverRange(
      personKey: 'matteo',
      person: TurnPerson.matteo,
      day: start,
      fasciaStart: start,
      fasciaEnd: end,
      isHomePresenceWindow: isHomePresenceWindow,
      overrides: overrides ?? DayOverrides.empty(_onlyDate(start)),
      ferieStore: ferieStore,
    );

    return !available;
  }

  bool isChiaraBusyBetween(
    DateTime start,
    DateTime end, {
    DayOverrides? overrides,
    FeriePeriodStore? ferieStore,
    bool isHomePresenceWindow = false,
  }) {
    final available = _canSpecificPersonCoverRange(
      personKey: 'chiara',
      person: TurnPerson.chiara,
      day: start,
      fasciaStart: start,
      fasciaEnd: end,
      isHomePresenceWindow: isHomePresenceWindow,
      overrides: overrides ?? DayOverrides.empty(_onlyDate(start)),
      ferieStore: ferieStore,
    );

    return !available;
  }

  bool isSomeoneAvailable(
    DateTime start,
    DateTime end, {
    DayOverrides? overrides,
    FeriePeriodStore? ferieStore,
    bool isHomePresenceWindow = false,
  }) {
    final effectiveOverrides =
        overrides ?? DayOverrides.empty(_onlyDate(start));

    final matteoAvailable = _canSpecificPersonCoverRange(
      personKey: 'matteo',
      person: TurnPerson.matteo,
      day: start,
      fasciaStart: start,
      fasciaEnd: end,
      isHomePresenceWindow: isHomePresenceWindow,
      overrides: effectiveOverrides,
      ferieStore: ferieStore,
    );

    if (matteoAvailable) return true;

    final chiaraAvailable = _canSpecificPersonCoverRange(
      personKey: 'chiara',
      person: TurnPerson.chiara,
      day: start,
      fasciaStart: start,
      fasciaEnd: end,
      isHomePresenceWindow: isHomePresenceWindow,
      overrides: effectiveOverrides,
      ferieStore: ferieStore,
    );

    if (chiaraAvailable) return true;

    return false;
  }

  CoverageDayAnalysis analyzeDayV2({
    required DateTime day,
    required bool uscita13,
    required bool sandraMattinaOn,
    required bool sandraPranzoOn,
    required bool sandraSeraOn,
    required TimeOfDay schoolStart,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 17, minute: 15),
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    final d0 = _onlyDate(day);
    final entries = <_CoverageGapEntry>[];

    final bool effSandraMattina = daySettingsStore.effectiveSandraMattina(
      d0,
      fallbackGlobal: sandraMattinaOn,
    );
    final bool effSandraPranzo = daySettingsStore.effectiveSandraPranzo(
      d0,
      fallbackGlobal: sandraPranzoOn,
    );
    final bool effSandraSera = daySettingsStore.effectiveSandraSera(
      d0,
      fallbackGlobal: sandraSeraOn,
    );

    final bool aliceAtHome = isAliceAtHomeDay(d0);
    final aliceType = getAliceEventTypeForDay(d0);

    String _aliceHomeBaseLabel(AliceEventType? aliceType) {
      switch (aliceType) {
        case AliceEventType.vacation:
          return 'Alice a casa (Vacanza)';
        case AliceEventType.sickness:
          return 'Alice a casa (Malata)';
        case AliceEventType.schoolClosure:
          return 'Alice a casa (Scuola chiusa)';
        default:
          return 'Alice a casa';
      }
    }

    final AliceEventType? aliceDayType = getAliceEventTypeForDay(d0);
    final String? aliceDayTypeName = aliceDayType?.name.toLowerCase();

    final aliceSpecialEvents = _enabledTimedAliceEventsForDay(d0);
    final bool hasAliceSpecialEvents = aliceSpecialEvents.isNotEmpty;

    final AliceSpecialEvent? firstAliceEvent = hasAliceSpecialEvents
        ? aliceSpecialEvents.first
        : null;
    final AliceSpecialEvent? lastAliceEvent = hasAliceSpecialEvents
        ? aliceSpecialEvents.last
        : null;

    final bool hasTimedAliceEvent =
        firstAliceEvent != null && lastAliceEvent != null;

    final bool isWeekend =
        d0.weekday == DateTime.saturday || d0.weekday == DateTime.sunday;
    final bool aliceSchoolNormal = isAliceSchoolNormalDay(d0) && !isWeekend;
    final bool aliceSummerCamp =
        isAliceSummerCampOperationalDay(d0) ||
        getSummerCampSpecialEventForDay(d0) != null;

    final AliceEventPeriod? activeSummerCampPeriod = getSummerCampPeriodForDay(
      d0,
    );

    final specialEvent = getSummerCampSpecialEventForDay(d0);
    final dayConfig = getSummerCampConfigForDay(d0);

    final bool summerCampEnabled =
        aliceSummerCamp &&
        activeSummerCampPeriod != null &&
        (specialEvent?.enabled ?? dayConfig.enabled);

    final DateTime? effectiveCampStart = summerCampEnabled
        ? _atTime(d0, summerCampStart ?? specialEvent?.start ?? dayConfig.start)
        : null;

    final DateTime? effectiveCampEnd = summerCampEnabled
        ? _atTime(d0, summerCampEnd ?? specialEvent?.end ?? dayConfig.end)
        : null;

    DateTime? normalSchoolHomeWindowStart;

    String _homeLabelAfterTimedEvents() {
      if (aliceAtHome) {
        if (aliceDayTypeName == 'vacation') {
          return 'Alice a casa (Vacanza)';
        }

        if (aliceDayTypeName == 'sickness') {
          return 'Alice a casa (Malattia)';
        }

        if (aliceDayTypeName == 'schoolclosure' ||
            aliceDayTypeName == 'school_closed' ||
            aliceDayTypeName == 'closure') {
          return 'Alice a casa (Scuola chiusa)';
        }
      }

      final lastLabel = lastAliceEvent?.label ?? 'evento';
      return 'Alice a casa dopo $lastLabel';
    }

    void addAliceTimedEventImpact({
      required DateTime homeWindowStart,
      required DateTime homeWindowEnd,
    }) {
      DateTime cursor = homeWindowStart;

      for (final event in aliceSpecialEvents) {
        final actualStart = _atTime(d0, event.start);
        final actualEnd = _atTime(d0, event.end);

        final accompanimentStart = actualStart.subtract(
          const Duration(minutes: 20),
        );
        final pickupEnd = actualEnd.add(const Duration(minutes: 20));

        final effectiveAccompanimentStart =
            accompanimentStart.isBefore(homeWindowStart)
            ? homeWindowStart
            : accompanimentStart;

        if (effectiveAccompanimentStart.isAfter(cursor)) {
          entries.addAll(
            _uncoveredHomeSegments(
              day: d0,
              windowStart: cursor,
              windowEnd: effectiveAccompanimentStart,
              labelPrefix: 'Alice a casa prima di ${event.label}',
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
              overrides: overrides,
              ferieStore: ferieStore,
            ),
          );
        }

        if (actualStart.isAfter(effectiveAccompanimentStart)) {
          entries.addAll(
            _uncoveredExternalSegments(
              day: d0,
              windowStart: effectiveAccompanimentStart,
              windowEnd: actualStart,
              labelPrefix: 'Accompagnamento Alice ${event.label}',
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
              overrides: overrides,
              ferieStore: ferieStore,
            ),
          );
        }

        if (actualEnd.isAfter(cursor)) {
          cursor = actualEnd;
        }

        final effectivePickupEnd = pickupEnd.isAfter(homeWindowEnd)
            ? homeWindowEnd
            : pickupEnd;

        if (effectivePickupEnd.isAfter(cursor)) {
          entries.addAll(
            _uncoveredExternalSegments(
              day: d0,
              windowStart: cursor,
              windowEnd: effectivePickupEnd,
              labelPrefix: 'Ritiro Alice ${event.label}',
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
              overrides: overrides,
              ferieStore: ferieStore,
            ),
          );
          cursor = effectivePickupEnd;
        }
      }

      if (homeWindowEnd.isAfter(cursor)) {
        entries.addAll(
          _uncoveredHomeSegments(
            day: d0,
            windowStart: cursor,
            windowEnd: homeWindowEnd,
            labelPrefix: _homeLabelAfterTimedEvents(),
            sandraMattinaAvailable: effSandraMattina,
            sandraPranzoAvailable: effSandraPranzo,
            sandraSeraAvailable: effSandraSera,
            overrides: overrides,
            ferieStore: ferieStore,
          ),
        );
      }
    }

    if (aliceAtHome && !hasTimedAliceEvent) {
      final aliceHomeStart = _atTime(d0, sandraCambioMattinaStart);
      final aliceHomeEnd = _atTime(d0, sandraSeraStart);

      _isFasciaCovered(
        day: d0,
        fasciaStart: aliceHomeStart,
        fasciaEnd: aliceHomeEnd,
        allowSandra: true,
        sandraMattinaAvailable: effSandraMattina,
        sandraPranzoAvailable: effSandraPranzo,
        sandraSeraAvailable: effSandraSera,
        isHomePresenceWindow: true,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      entries.addAll(
        _uncoveredHomeSegments(
          day: d0,
          windowStart: aliceHomeStart,
          windowEnd: aliceHomeEnd,
          labelPrefix: _aliceHomeBaseLabel(aliceType),
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          overrides: overrides,
          ferieStore: ferieStore,
        ),
      );
    }

    if (aliceAtHome && hasTimedAliceEvent) {
      final homeWindowStart = _atTime(d0, sandraCambioMattinaStart);
      final homeWindowEnd = _atTime(d0, sandraSeraStart);

      addAliceTimedEventImpact(
        homeWindowStart: homeWindowStart,
        homeWindowEnd: homeWindowEnd,
      );
    }

    if (aliceSchoolNormal) {
      final schoolInStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
      final schoolInEnd = _atTime(d0, schoolStart);
      final schoolInRealStart = schoolInEnd.subtract(
        const Duration(minutes: 20),
      );
      final labelSchoolIn =
          "Alice ingresso: ${_fmtTimeDate(schoolInRealStart)}–${_fmt(schoolStart)}";

      final schoolInCoveredByChoice = _isSchoolCoverChoiceValid(
        choice: schoolInCover,
        day: d0,
        fasciaStart: schoolInStart,
        fasciaEnd: schoolInEnd,
        allowSandra: true,
        sandraMattinaAvailable: effSandraMattina,
        sandraPranzoAvailable: effSandraPranzo,
        sandraSeraAvailable: effSandraSera,
        isHomePresenceWindow: false,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (schoolInCover == SchoolCoverChoice.none) {
        entries.add(
          _CoverageGapEntry(
            label: labelSchoolIn,
            fasciaStart: schoolInStart,
            fasciaEnd: schoolInEnd,
            isHomePresenceWindow: false,
            allowSandra: true,
          ),
        );
      } else {
        if (!schoolInCoveredByChoice) {
          entries.add(
            _CoverageGapEntry(
              label: labelSchoolIn,
              fasciaStart: schoolInStart,
              fasciaEnd: schoolInEnd,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        }
      }

      if (!uscita13) {
        final schoolOutRealDt = _atTime(d0, schoolOutEnd);
        final schoolOutPickupEndDt = schoolOutRealDt.add(
          const Duration(minutes: 20),
        );
        final labelSchoolOut =
            "Alice uscita: ${_fmt(schoolOutEnd)}–${_fmtTimeDate(schoolOutPickupEndDt)}";

        final schoolOutCoveredByChoice = _isSchoolCoverChoiceValid(
          choice: schoolOutCover,
          day: d0,
          fasciaStart: schoolOutRealDt,
          fasciaEnd: schoolOutPickupEndDt,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (schoolOutCover == SchoolCoverChoice.none) {
          entries.add(
            _CoverageGapEntry(
              label: labelSchoolOut,
              fasciaStart: schoolOutRealDt,
              fasciaEnd: schoolOutPickupEndDt,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        } else {
          if (!schoolOutCoveredByChoice) {
            entries.add(
              _CoverageGapEntry(
                label: labelSchoolOut,
                fasciaStart: schoolOutRealDt,
                fasciaEnd: schoolOutPickupEndDt,
                isHomePresenceWindow: false,
                allowSandra: true,
              ),
            );
          }
        }

        normalSchoolHomeWindowStart = schoolOutPickupEndDt;
      }

      if (uscita13) {
        final startLunch = uscitaAnticipataAt ?? sandraPranzoStart;
        final lunchStart = _atTime(d0, startLunch);
        final lunchEnd = lunchStart.add(const Duration(minutes: 20));

        final lunchCoveredByChoice = _isSchoolCoverChoiceValid(
          choice: lunchCover,
          day: d0,
          fasciaStart: lunchStart,
          fasciaEnd: lunchEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        final labelLunch =
            "Alice pranzo: ${_fmt(startLunch)}–${_fmtTimeDate(lunchEnd)}";

        final lunchCoveredInReality = _isFasciaCovered(
          day: d0,
          fasciaStart: lunchStart,
          fasciaEnd: lunchStart.add(const Duration(minutes: 20)),
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (lunchCover == SchoolCoverChoice.none) {
          entries.add(
            _CoverageGapEntry(
              label: labelLunch,
              fasciaStart: lunchStart,
              fasciaEnd: lunchStart.add(const Duration(minutes: 20)),
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        } else {
          if (!lunchCoveredByChoice && !lunchCoveredInReality) {
            entries.add(
              _CoverageGapEntry(
                label: labelLunch,
                fasciaStart: lunchStart,
                fasciaEnd: lunchEnd,
                isHomePresenceWindow: false,
                allowSandra: true,
              ),
            );
          }
        }

        normalSchoolHomeWindowStart = lunchEnd;
      }
    }

    if (aliceSummerCamp && activeSummerCampPeriod != null) {
      final specialEvent = getSummerCampSpecialEventForDay(d0);
      final dayConfig = getSummerCampConfigForDay(d0);

      final bool effectiveEnabled = specialEvent?.enabled ?? dayConfig.enabled;
      final TimeOfDay effectiveStart =
          specialEvent?.start ??
          summerCampStart ??
          activeSummerCampPeriod.summerCampStart ??
          dayConfig.start;

      final TimeOfDay effectiveEnd =
          specialEvent?.end ??
          summerCampEnd ??
          activeSummerCampPeriod.summerCampEnd ??
          dayConfig.end;

      if (effectiveEnabled) {
        final campInStart = _atTime(d0, sandraCambioMattinaEnd);
        final campInEnd = _atTime(d0, effectiveStart);
        final labelCampIn =
            "Alice centro estivo ingresso: ${_fmtTimeDate(campInStart)}–${_fmt(effectiveStart)}";

        final campInCoveredInReality = _isFasciaCovered(
          day: d0,
          fasciaStart: campInStart,
          fasciaEnd: campInEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (!campInCoveredInReality) {
          entries.add(
            _CoverageGapEntry(
              label: labelCampIn,
              fasciaStart: campInStart,
              fasciaEnd: campInEnd,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        }

        final campOutStart = _atTime(d0, effectiveEnd);
        final campOutEnd = DateTime(
          d0.year,
          d0.month,
          d0.day,
          sandraSeraStart.hour,
          sandraSeraStart.minute,
        );
        final labelCampOut =
            "Alice centro estivo uscita: ${_fmt(effectiveEnd)}–18:00";

        final campOutCoveredInReality = _isFasciaCovered(
          day: d0,
          fasciaStart: campOutStart,
          fasciaEnd: campOutEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (!campOutCoveredInReality) {
          entries.add(
            _CoverageGapEntry(
              label: labelCampOut,
              fasciaStart: campOutStart,
              fasciaEnd: campOutEnd,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        }
      } else {
        final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
        final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 16, 25);

        _isFasciaCovered(
          day: d0,
          fasciaStart: aliceHomeStart,
          fasciaEnd: aliceHomeEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: true,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        entries.addAll(
          _uncoveredHomeSegments(
            day: d0,
            windowStart: aliceHomeStart,
            windowEnd: aliceHomeEnd,
            labelPrefix: _aliceHomeBaseLabel(aliceType),
            sandraMattinaAvailable: effSandraMattina,
            sandraPranzoAvailable: effSandraPranzo,
            sandraSeraAvailable: effSandraSera,
            overrides: overrides,
            ferieStore: ferieStore,
          ),
        );
      }
    }

    if (normalSchoolHomeWindowStart != null) {
      final homeWindowEnd = _atTime(d0, sandraSeraStart);

      if (!hasTimedAliceEvent) {
        if (homeWindowEnd.isAfter(normalSchoolHomeWindowStart)) {
          entries.addAll(
            _uncoveredHomeSegments(
              day: d0,
              windowStart: normalSchoolHomeWindowStart,
              windowEnd: homeWindowEnd,
              labelPrefix: _aliceHomeBaseLabel(aliceType),
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
              overrides: overrides,
              ferieStore: ferieStore,
            ),
          );
        }
      } else {
        addAliceTimedEventImpact(
          homeWindowStart: normalSchoolHomeWindowStart,
          homeWindowEnd: homeWindowEnd,
        );
      }
    }

    final fMattinaStart = _atTime(d0, sandraCambioMattinaStart);
    final fMattinaEnd = _atTime(d0, sandraCambioMattinaEnd);

    DateTime mattinaGapStart = fMattinaStart;
    DateTime mattinaGapEnd = fMattinaEnd;

    if (effectiveCampStart != null &&
        effectiveCampStart.isBefore(mattinaGapEnd)) {
      mattinaGapEnd = effectiveCampStart;
    }

    if (mattinaGapEnd.isAfter(mattinaGapStart)) {
      final okCambioMattina = _isFasciaCovered(
        day: d0,
        fasciaStart: mattinaGapStart,
        fasciaEnd: mattinaGapEnd,
        allowSandra: true,
        sandraMattinaAvailable: effSandraMattina,
        sandraPranzoAvailable: effSandraPranzo,
        sandraSeraAvailable: effSandraSera,
        isHomePresenceWindow: true,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (!okCambioMattina) {
        entries.add(
          _CoverageGapEntry(
            label: _homeGapLabel(mattinaGapStart, mattinaGapEnd),
            fasciaStart: mattinaGapStart,
            fasciaEnd: mattinaGapEnd,
            isHomePresenceWindow: true,
            allowSandra: true,
          ),
        );
      }
    }

    if (aliceAtHome && !hasTimedAliceEvent) {
      final fPranzoStart = _atTime(d0, uscitaAnticipataAt ?? sandraPranzoStart);
      final fPranzoEnd = _atTime(d0, sandraPranzoEnd);

      DateTime pranzoGapStart = fPranzoStart;
      final DateTime pranzoGapEnd = fPranzoEnd;

      if (effectiveCampEnd != null &&
          effectiveCampEnd.isAfter(pranzoGapStart)) {
        pranzoGapStart = effectiveCampEnd;
      }

      if (pranzoGapEnd.isAfter(pranzoGapStart)) {
        final okPranzo = _isFasciaCovered(
          day: d0,
          fasciaStart: pranzoGapStart,
          fasciaEnd: pranzoGapEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: true,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (!okPranzo) {
          entries.add(
            _CoverageGapEntry(
              label: _homeGapLabel(pranzoGapStart, pranzoGapEnd),
              fasciaStart: pranzoGapStart,
              fasciaEnd: pranzoGapEnd,
              isHomePresenceWindow: true,
              allowSandra: true,
            ),
          );
        }
      }
    }
    final fSeraStart = _atTime(d0, sandraSeraStart);
    final fSeraEnd = _atTime(d0, sandraSeraEnd);

    DateTime seraGapStart = fSeraStart;
    final DateTime seraGapEnd = fSeraEnd;

    if (effectiveCampEnd != null && effectiveCampEnd.isAfter(seraGapStart)) {
      seraGapStart = effectiveCampEnd;
    }

    if (seraGapEnd.isAfter(seraGapStart)) {
      final okSera = _isFasciaCovered(
        day: d0,
        fasciaStart: seraGapStart,
        fasciaEnd: seraGapEnd,
        allowSandra: true,
        sandraMattinaAvailable: effSandraMattina,
        sandraPranzoAvailable: effSandraPranzo,
        sandraSeraAvailable: effSandraSera,
        isHomePresenceWindow: true,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (!okSera) {
        entries.add(
          _CoverageGapEntry(
            label: _homeGapLabel(seraGapStart, seraGapEnd),
            fasciaStart: seraGapStart,
            fasciaEnd: seraGapEnd,
            isHomePresenceWindow: true,
            allowSandra: true,
          ),
        );
      }
    }

    final normalizedEntries = _dedupeEntriesPreferRichLabel(entries);

    final gaps = <String>[];
    final details = <CoverageGapDetail>[];

    for (final entry in normalizedEntries) {
      if (aliceCompanionStore.isAliceAccompanied(
        day: d0,
        start: entry.fasciaStart,
        end: entry.fasciaEnd,
      )) {
        continue;
      }
      gaps.add(entry.label);
      details.add(
        CoverageGapDetail(
          label: entry.label,
          lines: _buildGapExplanation(
            day: d0,
            fasciaStart: entry.fasciaStart,
            fasciaEnd: entry.fasciaEnd,
            isHomePresenceWindow: entry.isHomePresenceWindow,
            allowSandra: entry.allowSandra,
            sandraMattinaAvailable: effSandraMattina,
            sandraPranzoAvailable: effSandraPranzo,
            sandraSeraAvailable: effSandraSera,
            overrides: overrides,
            ferieStore: ferieStore,
          ),
        ),
      );
    }

    return CoverageDayAnalysis(gaps: gaps, details: details);
  }

  List<_CoverageGapEntry> _uncoveredExternalSegments({
    required DateTime day,
    required DateTime windowStart,
    required DateTime windowEnd,
    required String labelPrefix,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final points = <DateTime>{windowStart, windowEnd};

    void addIfInside(DateTime dt) {
      if (!dt.isBefore(windowStart) && !dt.isAfter(windowEnd)) {
        points.add(dt);
      }
    }

    final matteoBusy = _effectiveBusyShiftsForPerson(
      personKey: 'matteo',
      person: TurnPerson.matteo,
      day: day,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    final chiaraBusy = _effectiveBusyShiftsForPerson(
      personKey: 'chiara',
      person: TurnPerson.chiara,
      day: day,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    for (final shift in matteoBusy) {
      addIfInside(shift.start);
      addIfInside(shift.end);
    }

    for (final shift in chiaraBusy) {
      addIfInside(shift.start);
      addIfInside(shift.end);
    }

    for (final person in supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        day,
        person.id,
      );
      if (!enabledForDay) continue;

      final start = DateTime(
        day.year,
        day.month,
        day.day,
        person.start.hour,
        person.start.minute,
      );

      final end = DateTime(
        day.year,
        day.month,
        day.day,
        person.end.hour,
        person.end.minute,
      );

      addIfInside(start);
      addIfInside(end);
    }

    if (sandraMattinaAvailable) {
      addIfInside(_atTime(day, sandraCambioMattinaStart));
      addIfInside(_atTime(day, sandraCambioMattinaEnd));
    }

    if (sandraPranzoAvailable) {
      addIfInside(_atTime(day, sandraPranzoStart));
      addIfInside(_atTime(day, sandraPranzoEnd));
    }

    if (sandraSeraAvailable) {
      addIfInside(_atTime(day, sandraSeraStart));
      addIfInside(_atTime(day, sandraSeraEnd));
    }

    final ordered = points.toList()..sort((a, b) => a.compareTo(b));

    final result = <_CoverageGapEntry>[];

    for (var i = 0; i < ordered.length - 1; i++) {
      final segStart = ordered[i];
      final segEnd = ordered[i + 1];

      if (!segEnd.isAfter(segStart)) continue;

      final covered = _isFasciaCovered(
        day: day,
        fasciaStart: segStart,
        fasciaEnd: segEnd,
        allowSandra: true,
        sandraMattinaAvailable: sandraMattinaAvailable,
        sandraPranzoAvailable: sandraPranzoAvailable,
        sandraSeraAvailable: sandraSeraAvailable,
        isHomePresenceWindow: false,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (!covered) {
        result.add(
          _CoverageGapEntry(
            label:
                '$labelPrefix: ${_fmtTimeDate(segStart)}–${_fmtTimeDate(segEnd)}',
            fasciaStart: segStart,
            fasciaEnd: segEnd,
            isHomePresenceWindow: false,
            allowSandra: true,
          ),
        );
      }
    }

    return result;
  }

  List<_CoverageGapEntry> _uncoveredHomeSegments({
    required DateTime day,
    required DateTime windowStart,
    required DateTime windowEnd,
    required String labelPrefix,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final points = <DateTime>{windowStart, windowEnd};

    void addIfInside(DateTime dt) {
      if (!dt.isBefore(windowStart) && !dt.isAfter(windowEnd)) {
        points.add(dt);
      }
    }

    final matteoBusy = _effectiveBusyShiftsForPerson(
      personKey: 'matteo',
      person: TurnPerson.matteo,
      day: day,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    final chiaraBusy = _effectiveBusyShiftsForPerson(
      personKey: 'chiara',
      person: TurnPerson.chiara,
      day: day,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    for (final shift in matteoBusy) {
      addIfInside(shift.start);
      addIfInside(shift.end);
    }

    for (final shift in chiaraBusy) {
      addIfInside(shift.start);
      addIfInside(shift.end);
    }

    for (final person in supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        day,
        person.id,
      );
      if (!enabledForDay) continue;

      final start = DateTime(
        day.year,
        day.month,
        day.day,
        person.start.hour,
        person.start.minute,
      );

      final end = DateTime(
        day.year,
        day.month,
        day.day,
        person.end.hour,
        person.end.minute,
      );

      addIfInside(start);
      addIfInside(end);
    }

    if (sandraMattinaAvailable) {
      addIfInside(_atTime(day, sandraCambioMattinaStart));
      addIfInside(_atTime(day, sandraCambioMattinaEnd));
    }

    if (sandraPranzoAvailable) {
      addIfInside(_atTime(day, sandraPranzoStart));
      addIfInside(_atTime(day, sandraPranzoEnd));
    }

    if (sandraSeraAvailable) {
      addIfInside(_atTime(day, sandraSeraStart));
      addIfInside(_atTime(day, sandraSeraEnd));
    }

    final ordered = points.toList()..sort((a, b) => a.compareTo(b));

    final result = <_CoverageGapEntry>[];

    for (var i = 0; i < ordered.length - 1; i++) {
      final segStart = ordered[i];
      final segEnd = ordered[i + 1];

      if (!segEnd.isAfter(segStart)) continue;

      final covered = _isFasciaCovered(
        day: day,
        fasciaStart: segStart,
        fasciaEnd: segEnd,
        allowSandra: true,
        sandraMattinaAvailable: sandraMattinaAvailable,
        sandraPranzoAvailable: sandraPranzoAvailable,
        sandraSeraAvailable: sandraSeraAvailable,
        isHomePresenceWindow: true,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (!covered &&
          !aliceCompanionStore.entriesForDay(day).any((entry) {
            final entryStart = DateTime(
              day.year,
              day.month,
              day.day,
              entry.start.hour,
              entry.start.minute,
            );

            final entryEnd = DateTime(
              day.year,
              day.month,
              day.day,
              entry.end.hour,
              entry.end.minute,
            );

            return entryStart.isBefore(segEnd) && entryEnd.isAfter(segStart);
          })) {
        result.add(
          _CoverageGapEntry(
            label:
                '$labelPrefix: ${_fmtTimeDate(segStart)}–${_fmtTimeDate(segEnd)}',
            fasciaStart: segStart,
            fasciaEnd: segEnd,
            isHomePresenceWindow: true,
            allowSandra: true,
          ),
        );
      }
    }

    return _mergeAdjacentEntries(result);
  }

  List<_CoverageGapEntry> _mergeAdjacentEntries(
    List<_CoverageGapEntry> entries,
  ) {
    if (entries.isEmpty) return entries;

    final sorted = [...entries]
      ..sort((a, b) => a.fasciaStart.compareTo(b.fasciaStart));

    final merged = <_CoverageGapEntry>[];
    var current = sorted.first;

    bool canMergeLabels(_CoverageGapEntry a, _CoverageGapEntry b) {
      final aIsHome = _isAliceHomeLabel(a.label);
      final bIsHome = _isAliceHomeLabel(b.label);

      final aIsEventMove = _isAliceEventMoveLabel(a.label);
      final bIsEventMove = _isAliceEventMoveLabel(b.label);

      if (aIsHome && bIsHome) return true;
      if (aIsEventMove && bIsEventMove) return true;
      if (aIsEventMove && bIsHome) return true;
      if (aIsHome && bIsEventMove) return true;

      return false;
    }

    String mergedLabel(_CoverageGapEntry a, _CoverageGapEntry b) {
      final hasHome = _isAliceHomeLabel(a.label) || _isAliceHomeLabel(b.label);

      if (hasHome) {
        return _homeGapLabel(a.fasciaStart, b.fasciaEnd);
      }

      return 'Gestione Alice evento: ${_labelDateRange(a.fasciaStart, b.fasciaEnd)}';
    }

    for (var i = 1; i < sorted.length; i++) {
      final next = sorted[i];

      final sameKind =
          current.isHomePresenceWindow == next.isHomePresenceWindow &&
          current.allowSandra == next.allowSandra &&
          current.fasciaEnd.isAtSameMomentAs(next.fasciaStart) &&
          canMergeLabels(current, next);

      if (sameKind) {
        current = _CoverageGapEntry(
          label: mergedLabel(current, next),
          fasciaStart: current.fasciaStart,
          fasciaEnd: next.fasciaEnd,
          isHomePresenceWindow: current.isHomePresenceWindow,
          allowSandra: current.allowSandra,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }

    merged.add(current);
    return merged;
  }

  List<_CoverageGapEntry> _dedupeEntriesPreferRichLabel(
    List<_CoverageGapEntry> entries,
  ) {
    final result = <_CoverageGapEntry>[];

    for (final entry in entries) {
      final existingIndex = result.indexWhere(
        (e) =>
            e.fasciaStart.isAtSameMomentAs(entry.fasciaStart) &&
            e.fasciaEnd.isAtSameMomentAs(entry.fasciaEnd) &&
            e.isHomePresenceWindow == entry.isHomePresenceWindow &&
            e.allowSandra == entry.allowSandra,
      );

      if (existingIndex == -1) {
        result.add(entry);
        continue;
      }

      final existing = result[existingIndex];
      final keepExisting =
          _scoreGapLabel(existing.label) >= _scoreGapLabel(entry.label);

      if (!keepExisting) {
        result[existingIndex] = entry;
      }
    }

    return result;
  }

  int _scoreGapLabel(String label) {
    final lower = label.toLowerCase();

    if (_isAliceHomeLabel(lower)) return 100;
    if (lower.startsWith('alice ingresso:')) return 95;
    if (lower.startsWith('alice uscita:')) return 95;
    if (lower.startsWith('alice pranzo:')) return 95;
    if (lower.startsWith('alice centro estivo ingresso:')) return 95;
    if (lower.startsWith('alice centro estivo uscita:')) return 95;
    if (_isAliceEventMoveLabel(lower)) return 90;
    if (lower.startsWith('centro estivo speciale:')) return 90;
    if (label.contains(':')) return 80;

    return 10;
  }

  List<WorkShift> _effectiveBusyShiftsForPerson({
    required String personKey,
    required TurnPerson person,
    required DateTime day,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final personOverride = personKey == 'matteo'
        ? overrides.matteo
        : overrides.chiara;
    final hasManual = personOverride != null;

    final diseaseStatus = hasManual
        ? null
        : _diseaseStatusForPerson(personId: personKey, day: day);

    final isHoliday =
        (!hasManual) &&
        (diseaseStatus == null) &&
        ((personKey == 'matteo'
                ? ferieStore?.isOnHoliday(FeriePerson.matteo, day)
                : ferieStore?.isOnHoliday(FeriePerson.chiara, day)) ??
            false);

    var baseBusy = turnEngine.busyShiftsForPerson(person: person, day: day);

    if (isHoliday || diseaseStatus != null) {
      baseBusy = [];
    }

    final extraBusy = _busyShiftsFromRealEventsForPerson(
      personKey: personKey,
      day: day,
    );

    return OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[...baseBusy.cast<WorkShift>(), ...extraBusy],
      personOverride: personOverride,
    );
  }

  List<String> _buildGapExplanation({
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool isHomePresenceWindow,
    required bool allowSandra,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final lines = <String>[];

    final matteoHasManual = overrides.matteo != null;
    final chiaraHasManual = overrides.chiara != null;

    final matteoDiseaseStatus = matteoHasManual
        ? null
        : _diseaseStatusForPerson(personId: 'matteo', day: day);
    final chiaraDiseaseStatus = chiaraHasManual
        ? null
        : _diseaseStatusForPerson(personId: 'chiara', day: day);

    final matteoHoliday =
        (!matteoHasManual) &&
        (matteoDiseaseStatus == null) &&
        (ferieStore?.isOnHoliday(FeriePerson.matteo, day) ?? false);
    final chiaraHoliday =
        (!chiaraHasManual) &&
        (chiaraDiseaseStatus == null) &&
        (ferieStore?.isOnHoliday(FeriePerson.chiara, day) ?? false);

    var baseBusyMatteo = turnEngine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    var baseBusyChiara = turnEngine.busyShiftsForPerson(
      person: TurnPerson.chiara,
      day: day,
    );

    if (matteoHoliday || matteoDiseaseStatus != null) baseBusyMatteo = [];
    if (chiaraHoliday || chiaraDiseaseStatus != null) baseBusyChiara = [];

    final extraBusyMatteo = _busyShiftsFromRealEventsForPerson(
      personKey: 'matteo',
      day: day,
    );

    final extraBusyChiara = _busyShiftsFromRealEventsForPerson(
      personKey: 'chiara',
      day: day,
    );

    final matteoBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[
        ...baseBusyMatteo.cast<WorkShift>(),
        ...extraBusyMatteo,
      ],
      personOverride: overrides.matteo,
    );

    final chiaraBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[
        ...baseBusyChiara.cast<WorkShift>(),
        ...extraBusyChiara,
      ],
      personOverride: overrides.chiara,
    );

    final matteoStatus =
        overrides.matteo?.status ??
        matteoDiseaseStatus ??
        (matteoHoliday ? OverrideStatus.ferie : OverrideStatus.normal);
    final chiaraStatus =
        overrides.chiara?.status ??
        chiaraDiseaseStatus ??
        (chiaraHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    lines.add(
      _personExplanation(
        person: TurnPerson.matteo,
        personName: 'Matteo',
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
        isHomePresenceWindow: isHomePresenceWindow,
        status: matteoStatus,
        busyShifts: matteoBusy,
        overlappingRealEvent: _overlappingRealEventForPerson(
          personKey: 'matteo',
          day: day,
          fasciaStart: fasciaStart,
          fasciaEnd: fasciaEnd,
        ),
      ),
    );

    lines.add(
      _personExplanation(
        person: TurnPerson.chiara,
        personName: 'Chiara',
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
        isHomePresenceWindow: isHomePresenceWindow,
        status: chiaraStatus,
        busyShifts: chiaraBusy,
        overlappingRealEvent: _overlappingRealEventForPerson(
          personKey: 'chiara',
          day: day,
          fasciaStart: fasciaStart,
          fasciaEnd: fasciaEnd,
        ),
      ),
    );

    final supportAvailable = _isCoveredBySupportNetwork(
      day: day,
      fasciaStart: fasciaStart,
      fasciaEnd: fasciaEnd,
    );

    if (supportAvailable) {
      lines.add("Rete supporto disponibile in questa fascia.");
    } else {
      lines.add("Rete supporto non disponibile in questa fascia.");
    }

    final sandraIsActiveForRange = _isSandraWindowCoveringRange(
      day: day,
      fasciaStart: fasciaStart,
      fasciaEnd: fasciaEnd,
      sandraMattinaAvailable: sandraMattinaAvailable,
      sandraPranzoAvailable: sandraPranzoAvailable,
      sandraSeraAvailable: sandraSeraAvailable,
    );

    if (allowSandra) {
      if (sandraIsActiveForRange) {
        lines.add("Sandra è attiva su questa fascia.");
      } else {
        lines.add("Sandra non è attiva su questa fascia.");
      }
    }

    return lines;
  }

  String _personExplanation({
    required TurnPerson person,
    required String personName,
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool isHomePresenceWindow,
    required OverrideStatus status,
    required List busyShifts,
    RealEvent? overlappingRealEvent,
  }) {
    if (status == OverrideStatus.malattiaALetto) {
      if (overlappingRealEvent != null &&
          overlappingRealEvent.startTime != null &&
          overlappingRealEvent.endTime != null) {
        return "$personName è fuori casa per evento reale: ${overlappingRealEvent.title} (${_fmt(overlappingRealEvent.startTime!)}–${_fmt(overlappingRealEvent.endTime!)}).";
      }

      if (isHomePresenceWindow) {
        return "$personName è a casa e presente, ma non può fare uscite perché è a letto per malattia.";
      }
      return "$personName è a casa ma non può accompagnare Alice perché è a letto per malattia.";
    }

    if (status == OverrideStatus.malattiaLeggera) {
      final overlapsImps = _overlapsImps(
        day: day,
        start: fasciaStart,
        end: fasciaEnd,
      );

      if (overlappingRealEvent != null &&
          overlappingRealEvent.startTime != null &&
          overlappingRealEvent.endTime != null) {
        return "$personName è fuori casa per evento reale: ${overlappingRealEvent.title} (${_fmt(overlappingRealEvent.startTime!)}–${_fmt(overlappingRealEvent.endTime!)}).";
      }

      if (isHomePresenceWindow) {
        return "$personName potrebbe coprire da casa (malattia leggera).";
      }

      if (overlapsImps) {
        return "$personName ha malattia leggera ma in questa fascia deve restare a casa per reperibilità INPS.";
      }

      return "$personName potrebbe coprire questa fascia (malattia leggera).";
    }

    if (status == OverrideStatus.ferie) {
      final hasTimedRealEvent =
          overlappingRealEvent != null &&
          overlappingRealEvent.startTime != null &&
          overlappingRealEvent.endTime != null;

      if (hasTimedRealEvent) {
        final startHour = overlappingRealEvent.startTime!.hour
            .toString()
            .padLeft(2, '0');
        final startMinute = overlappingRealEvent.startTime!.minute
            .toString()
            .padLeft(2, '0');
        final endHour = overlappingRealEvent.endTime!.hour.toString().padLeft(
          2,
          '0',
        );
        final endMinute = overlappingRealEvent.endTime!.minute
            .toString()
            .padLeft(2, '0');

        return "$personName è fuori casa per evento reale: ${overlappingRealEvent.title} ($startHour:$startMinute–$endHour:$endMinute).";
      }

      return "$personName risulta disponibile in questa fascia (ferie).";
    }

    final isFree = isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
      PersonAvailability(busyShifts: busyShifts.cast()),
    ]);

    if (isFree) {
      return "$personName risulta disponibile in questa fascia.";
    }

    if (overlappingRealEvent != null &&
        overlappingRealEvent.startTime != null &&
        overlappingRealEvent.endTime != null) {
      return personName == 'Chiara'
          ? "Chiara è occupata da evento reale: ${overlappingRealEvent.title} (${_fmt(overlappingRealEvent.startTime!)}–${_fmt(overlappingRealEvent.endTime!)})."
          : "Matteo è occupato da evento reale: ${overlappingRealEvent.title} (${_fmt(overlappingRealEvent.startTime!)}–${_fmt(overlappingRealEvent.endTime!)}).";
    }

    if (_isPostNightForPersonDay(person: person, day: day)) {
      final postNightEnd = DateTime(day.year, day.month, day.day, 14, 30);

      if (!fasciaStart.isAfter(postNightEnd) &&
          !fasciaEnd.isAfter(postNightEnd)) {
        return "$personName è in riposo post-notte.";
      }
    }

    return "$personName è al lavoro in questa fascia.";
  }

  bool _isPostNightForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    final plan = turnEngine.turnPlanForPersonDay(person: person, day: day);
    return plan.type == TurnType.notte;
  }

  bool _isFasciaCovered({
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool allowSandra,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required bool isHomePresenceWindow,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final matteoHasManual = overrides.matteo != null;
    final chiaraHasManual = overrides.chiara != null;

    final matteoDiseaseStatus = matteoHasManual
        ? null
        : _diseaseStatusForPerson(personId: 'matteo', day: day);
    final chiaraDiseaseStatus = chiaraHasManual
        ? null
        : _diseaseStatusForPerson(personId: 'chiara', day: day);

    final matteoHoliday =
        (!matteoHasManual) &&
        (matteoDiseaseStatus == null) &&
        (ferieStore?.isOnHoliday(FeriePerson.matteo, day) ?? false);
    final chiaraHoliday =
        (!chiaraHasManual) &&
        (chiaraDiseaseStatus == null) &&
        (ferieStore?.isOnHoliday(FeriePerson.chiara, day) ?? false);

    var baseBusyMatteo = turnEngine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    var baseBusyChiara = turnEngine.busyShiftsForPerson(
      person: TurnPerson.chiara,
      day: day,
    );

    if (matteoHoliday || matteoDiseaseStatus != null) baseBusyMatteo = [];
    if (chiaraHoliday || chiaraDiseaseStatus != null) baseBusyChiara = [];

    final extraBusyMatteo = _busyShiftsFromRealEventsForPerson(
      personKey: 'matteo',
      day: day,
    );

    final extraBusyChiara = _busyShiftsFromRealEventsForPerson(
      personKey: 'chiara',
      day: day,
    );

    final matteoBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[
        ...baseBusyMatteo.cast<WorkShift>(),
        ...extraBusyMatteo,
      ],
      personOverride: overrides.matteo,
    );

    final chiaraBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[
        ...baseBusyChiara.cast<WorkShift>(),
        ...extraBusyChiara,
      ],
      personOverride: overrides.chiara,
    );

    final m =
        overrides.matteo?.status ??
        matteoDiseaseStatus ??
        (matteoHoliday ? OverrideStatus.ferie : OverrideStatus.normal);
    final c =
        overrides.chiara?.status ??
        chiaraDiseaseStatus ??
        (chiaraHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    final overlapsImps = _overlapsImps(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
    );

    bool matteoCanCover = false;
    bool chiaraCanCover = false;

    if (m == OverrideStatus.malattiaALetto) {
      if (isHomePresenceWindow) {
        matteoCanCover = isTimeCovered(
          fasciaStart,
          fasciaEnd,
          <PersonAvailability>[PersonAvailability(busyShifts: matteoBusy)],
        );
      } else {
        matteoCanCover = false;
      }
    } else if (m == OverrideStatus.malattiaLeggera) {
      if (!isHomePresenceWindow && overlapsImps) {
        matteoCanCover = false;
      } else {
        matteoCanCover = isTimeCovered(
          fasciaStart,
          fasciaEnd,
          <PersonAvailability>[PersonAvailability(busyShifts: matteoBusy)],
        );
      }
    } else {
      matteoCanCover = isTimeCovered(
        fasciaStart,
        fasciaEnd,
        <PersonAvailability>[PersonAvailability(busyShifts: matteoBusy)],
      );
    }

    if (c == OverrideStatus.malattiaALetto) {
      if (isHomePresenceWindow) {
        chiaraCanCover = isTimeCovered(
          fasciaStart,
          fasciaEnd,
          <PersonAvailability>[PersonAvailability(busyShifts: chiaraBusy)],
        );
      } else {
        chiaraCanCover = false;
      }
    } else if (c == OverrideStatus.malattiaLeggera) {
      if (!isHomePresenceWindow && overlapsImps) {
        chiaraCanCover = false;
      } else {
        chiaraCanCover = isTimeCovered(
          fasciaStart,
          fasciaEnd,
          <PersonAvailability>[PersonAvailability(busyShifts: chiaraBusy)],
        );
      }
    } else {
      chiaraCanCover = isTimeCovered(
        fasciaStart,
        fasciaEnd,
        <PersonAvailability>[PersonAvailability(busyShifts: chiaraBusy)],
      );
    }

    if (m != OverrideStatus.malattiaALetto &&
        c != OverrideStatus.malattiaALetto) {
      final combinedCover =
          isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
            PersonAvailability(busyShifts: matteoBusy),
            PersonAvailability(busyShifts: chiaraBusy),
          ]);

      if (combinedCover) return true;
    }

    if (aliceCompanionStore.isAliceAccompanied(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
    )) {
      return true;
    }

    if (matteoCanCover || chiaraCanCover) return true;

    if (_isCoveredBySupportNetwork(
      day: day,
      fasciaStart: fasciaStart,
      fasciaEnd: fasciaEnd,
    )) {
      return true;
    }

    if (allowSandra &&
        _isSandraWindowCoveringRange(
          day: day,
          fasciaStart: fasciaStart,
          fasciaEnd: fasciaEnd,
          sandraMattinaAvailable: sandraMattinaAvailable,
          sandraPranzoAvailable: sandraPranzoAvailable,
          sandraSeraAvailable: sandraSeraAvailable,
        )) {
      return true;
    }

    return false;
  }

  bool _isSchoolCoverChoiceValid({
    required SchoolCoverChoice choice,
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool allowSandra,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required bool isHomePresenceWindow,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final choiceName = choice.name.toLowerCase();

    if (choiceName == 'none') return false;

    if (choiceName.contains('matteo')) {
      return _canSpecificPersonCoverRange(
        personKey: 'matteo',
        person: TurnPerson.matteo,
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
        isHomePresenceWindow: isHomePresenceWindow,
        overrides: overrides,
        ferieStore: ferieStore,
      );
    }

    if (choiceName.contains('chiara')) {
      return _canSpecificPersonCoverRange(
        personKey: 'chiara',
        person: TurnPerson.chiara,
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
        isHomePresenceWindow: isHomePresenceWindow,
        overrides: overrides,
        ferieStore: ferieStore,
      );
    }

    if (choiceName.contains('sandra')) {
      if (!allowSandra) return false;

      return _isSandraWindowCoveringRange(
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
        sandraMattinaAvailable: sandraMattinaAvailable,
        sandraPranzoAvailable: sandraPranzoAvailable,
        sandraSeraAvailable: sandraSeraAvailable,
      );
    }

    if (choice == SchoolCoverChoice.altro ||
        choiceName.contains('support') ||
        choiceName.contains('rete')) {
      return _isCoveredBySupportNetwork(
        day: day,
        fasciaStart: fasciaStart,
        fasciaEnd: fasciaEnd,
      );
    }

    return false;
  }

  bool _canSpecificPersonCoverRange({
    required String personKey,
    required TurnPerson person,
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool isHomePresenceWindow,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final personOverride = personKey == 'matteo'
        ? overrides.matteo
        : overrides.chiara;
    final hasManual = personOverride != null;

    final diseaseStatus = hasManual
        ? null
        : _diseaseStatusForPerson(personId: personKey, day: day);

    final isHoliday =
        (!hasManual) &&
        (diseaseStatus == null) &&
        ((personKey == 'matteo'
                ? ferieStore?.isOnHoliday(FeriePerson.matteo, day)
                : ferieStore?.isOnHoliday(FeriePerson.chiara, day)) ??
            false);

    var baseBusy = turnEngine.busyShiftsForPerson(person: person, day: day);

    if (isHoliday || diseaseStatus != null) {
      baseBusy = [];
    }

    final extraBusy = _busyShiftsFromRealEventsForPerson(
      personKey: personKey,
      day: day,
    );

    final effectiveBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[...baseBusy.cast<WorkShift>(), ...extraBusy],
      personOverride: personOverride,
    );

    final lunchChoice = daySettingsStore.lunchCoverForDay(day);

    final isForcedActive =
        ((personKey == 'matteo' && lunchChoice == SchoolCoverChoice.matteo) ||
        (personKey == 'chiara' && lunchChoice == SchoolCoverChoice.chiara));

    final adjustedBusy = isForcedActive ? <WorkShift>[] : effectiveBusy;

    final effectiveStatus =
        personOverride?.status ??
        diseaseStatus ??
        (isHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    if (effectiveStatus == OverrideStatus.malattiaALetto) {
      return isHomePresenceWindow &&
          isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
            PersonAvailability(busyShifts: adjustedBusy),
          ]);
    }

    if (effectiveStatus == OverrideStatus.malattiaLeggera) {
      if (!isHomePresenceWindow &&
          _overlapsImps(day: day, start: fasciaStart, end: fasciaEnd)) {
        return false;
      }
      return isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
        PersonAvailability(busyShifts: adjustedBusy),
      ]);
    }

    return isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
      PersonAvailability(busyShifts: adjustedBusy),
    ]);
  }

  OverrideStatus? _diseaseStatusForPerson({
    required String personId,
    required DateTime day,
  }) {
    final period = diseasePeriodStore.getPeriodForDay(personId, day);
    if (period == null) return null;

    switch (period.type) {
      case DiseaseType.mild:
        return OverrideStatus.malattiaLeggera;
      case DiseaseType.bed:
        return OverrideStatus.malattiaALetto;
    }
  }

  List<WorkShift> _busyShiftsFromRealEventsForPerson({
    required String personKey,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final events = realEventStore.eventsForDay(d0);

    final busy = <WorkShift>[];

    for (final event in events) {
      if (event.personKey != personKey) continue;
      if (event.startTime == null || event.endTime == null) continue;

      final start = _atTime(d0, event.startTime!);
      final end = _atTime(d0, event.endTime!);

      if (!end.isAfter(start)) continue;

      busy.add(WorkShift(start: start, end: end));
    }

    return busy;
  }

  RealEvent? _overlappingRealEventForPerson({
    required String personKey,
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
  }) {
    final d0 = _onlyDate(day);
    final events = realEventStore.eventsForDay(d0);

    for (final event in events) {
      if (event.personKey != personKey) continue;
      if (event.startTime == null || event.endTime == null) continue;

      final eventStart = _atTime(d0, event.startTime!);
      final eventEnd = _atTime(d0, event.endTime!);

      final overlaps =
          eventStart.isBefore(fasciaEnd) && eventEnd.isAfter(fasciaStart);

      if (overlaps) return event;
    }

    return null;
  }

  bool _isSandraWindowCoveringRange({
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
  }) {
    final d0 = _onlyDate(day);

    if (sandraMattinaAvailable) {
      final start = _atTime(d0, sandraCambioMattinaStart);
      final end = _atTime(d0, sandraCambioMattinaEnd);
      final covers = !start.isAfter(fasciaStart) && !end.isBefore(fasciaEnd);
      if (covers) return true;
    }

    if (sandraPranzoAvailable) {
      final start = _atTime(d0, sandraPranzoStart);
      final end = _atTime(d0, sandraPranzoEnd);
      final covers = !start.isAfter(fasciaStart) && !end.isBefore(fasciaEnd);
      if (covers) return true;
    }

    if (sandraSeraAvailable) {
      final start = _atTime(d0, sandraSeraStart);
      final end = _atTime(d0, sandraSeraEnd);
      final covers = !start.isAfter(fasciaStart) && !end.isBefore(fasciaEnd);
      if (covers) return true;
    }

    return false;
  }

  bool _isCoveredBySupportNetwork({
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
  }) {
    final d0 = _onlyDate(day);

    for (final person in supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        d0,
        person.id,
      );
      if (!enabledForDay) continue;

      final supportStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.start.hour,
        person.start.minute,
      );

      final supportEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.end.hour,
        person.end.minute,
      );

      final coversFullRange =
          !supportStart.isAfter(fasciaStart) && !supportEnd.isBefore(fasciaEnd);

      if (coversFullRange) {
        return true;
      }
    }

    return false;
  }

  bool _overlapsImps({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);

    final imps1Start = DateTime(d0.year, d0.month, d0.day, 10, 0);
    final imps1End = DateTime(d0.year, d0.month, d0.day, 12, 0);

    final imps2Start = DateTime(d0.year, d0.month, d0.day, 17, 0);
    final imps2End = DateTime(d0.year, d0.month, d0.day, 19, 0);

    final o1 = start.isBefore(imps1End) && end.isAfter(imps1Start);
    final o2 = start.isBefore(imps2End) && end.isAfter(imps2Start);
    return o1 || o2;
  }

  List<AliceSpecialEvent> _enabledTimedAliceEventsForDay(DateTime day) {
    final events = aliceSpecialEventStore
        .eventsForDay(day)
        .where((event) => event.enabled)
        .toList();

    events.sort((a, b) {
      final aMinutes = a.start.hour * 60 + a.start.minute;
      final bMinutes = b.start.hour * 60 + b.start.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return events;
  }

  DateTime? _getAliceCompanionEnd({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final entries = aliceCompanionStore.entriesForDay(day);

    DateTime? bestEnd;

    for (final entry in entries) {
      final entryStart = DateTime(
        day.year,
        day.month,
        day.day,
        entry.start.hour,
        entry.start.minute,
      );

      final entryEnd = DateTime(
        day.year,
        day.month,
        day.day,
        entry.end.hour,
        entry.end.minute,
      );

      final overlapsWindow =
          entryStart.isBefore(end) && entryEnd.isAfter(start);

      if (!overlapsWindow) continue;

      if (entryStart.isAfter(start)) continue;

      if (bestEnd == null || entryEnd.isAfter(bestEnd)) {
        bestEnd = entryEnd;
      }
    }

    return bestEnd;
  }

  bool _isAliceHomeLabel(String label) {
    final lower = label.toLowerCase();
    return lower.startsWith('alice a casa');
  }

  bool _isAliceEventMoveLabel(String label) {
    final lower = label.toLowerCase();
    return lower.startsWith('accompagnamento alice ') ||
        lower.startsWith('ritiro alice ') ||
        lower.startsWith('gestione alice evento:');
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _atTime(DateTime d0, TimeOfDay t) =>
      DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);

  String _labelRange(TimeOfDay a, TimeOfDay b) => "${_fmt(a)}–${_fmt(b)}";

  String _labelDateRange(DateTime start, DateTime end) =>
      "${_fmtTimeDate(start)}–${_fmtTimeDate(end)}";

  String _homeGapLabel(DateTime start, DateTime end, {String? eventLabel}) {
    if (eventLabel != null && eventLabel.trim().isNotEmpty) {
      return "Alice a casa dopo $eventLabel: ${_fmtTimeDate(start)}–${_fmtTimeDate(end)}";
    }

    return "Alice a casa: ${_fmtTimeDate(start)}–${_fmtTimeDate(end)}";
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  String _fmtTimeDate(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }
}

class CoverageSandraDecision {
  final bool serveSandraMattina;
  final bool serveSandraPranzo;
  final bool serveSandraSera;

  const CoverageSandraDecision({
    required this.serveSandraMattina,
    required this.serveSandraPranzo,
    required this.serveSandraSera,
  });

  bool get any => serveSandraMattina || serveSandraPranzo || serveSandraSera;
}

class CoverageDayAnalysis {
  final List<String> gaps;
  final List<CoverageGapDetail> details;

  const CoverageDayAnalysis({required this.gaps, required this.details});

  CoverageGapDetail? detailFor(String label) {
    for (final detail in details) {
      if (detail.label == label) return detail;
    }
    return null;
  }
}

class CoverageGapDetail {
  final String label;
  final List<String> lines;

  const CoverageGapDetail({required this.label, required this.lines});
}

class _CoverageGapEntry {
  final String label;
  final DateTime fasciaStart;
  final DateTime fasciaEnd;
  final bool isHomePresenceWindow;
  final bool allowSandra;

  const _CoverageGapEntry({
    required this.label,
    required this.fasciaStart,
    required this.fasciaEnd,
    required this.isHomePresenceWindow,
    required this.allowSandra,
  });
}
