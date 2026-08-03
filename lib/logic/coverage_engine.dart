import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';
import '../models/disease_period.dart';
import '../models/real_event.dart';
import '../models/alice_presence_state.dart';
import '../models/work_shift.dart';
import '../models/alice_coverage_window.dart';
import '../models/adult_constraint_interval.dart';
import '../models/coverage_criticality_detail.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'override_store.dart';
import 'turn_engine.dart';
import 'day_settings_store.dart';
import 'support_network_store.dart';
import 'disease_period_store.dart';
import 'real_event_store.dart';
import 'adult_logistics_availability_resolver.dart';

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

import 'alice_presence_engine.dart';

// ✅ NEW: Scuola strutturata
import 'school_store.dart';

class CoverageEngine {
  final TurnEngine turnEngine;
  final OverrideStore? overrideStore;
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

  // ✅ NEW: Scuola strutturata
  final SchoolStore schoolStore;

  // Finestre Sandra (mutabili: UI le edita)
  TimeOfDay sandraCambioMattinaStart;
  TimeOfDay sandraCambioMattinaEnd;

  TimeOfDay sandraPranzoStart;
  TimeOfDay sandraPranzoEnd;

  TimeOfDay sandraSeraStart;
  TimeOfDay sandraSeraEnd;

  CoverageEngine({
    TurnEngine? turnEngine,
    OverrideStore? overrideStore,
    DaySettingsStore? daySettingsStore,
    SupportNetworkStore? supportNetworkStore,
    DiseasePeriodStore? diseasePeriodStore,
    RealEventStore? realEventStore,
    AliceCompanionStore? aliceCompanionStore,
    AliceEventStore? aliceEventStore,
    AliceSpecialEventStore? aliceSpecialEventStore,
    SummerCampScheduleStore? summerCampScheduleStore,
    SummerCampSpecialEventStore? summerCampSpecialEventStore,
    SchoolStore? schoolStore,
    TimeOfDay? sandraCambioMattinaStart,
    TimeOfDay? sandraCambioMattinaEnd,
    TimeOfDay? sandraPranzoStart,
    TimeOfDay? sandraPranzoEnd,
    TimeOfDay? sandraSeraStart,
    TimeOfDay? sandraSeraEnd,
  }) : turnEngine = turnEngine ?? TurnEngine(),
       overrideStore = overrideStore,
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
       schoolStore = schoolStore ?? SchoolStore(),
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
    return _presenceEngine().isAliceAtHomeDay(day);
  }

  bool isAliceExternalActivityDay(DateTime day) {
    return _presenceEngine().isAliceExternalActivityDay(day);
  }

  bool isAliceSchoolNormalDay(DateTime day) {
    return _presenceEngine().isAliceSchoolNormalDay(day);
  }

  bool isAliceSummerCampOperationalDay(DateTime day) {
    return _presenceEngine().isAliceSummerCampOperationalDay(day);
  }

  AliceEventType? getAliceEventTypeForDay(DateTime day) {
    return _presenceEngine().getAliceEventTypeForDay(day);
  }

  AliceEventPeriod? getSummerCampPeriodForDay(DateTime day) {
    return _presenceEngine().getSummerCampPeriodForDay(day);
  }

  SummerCampDayConfig getSummerCampConfigForDay(DateTime day) {
    return _presenceEngine().getSummerCampConfigForDay(day);
  }

  SummerCampSpecialEvent? getSummerCampSpecialEventForDay(DateTime day) {
    return _presenceEngine().getSummerCampSpecialEventForDay(day);
  }

  bool hasSummerCampSpecialEventForDay(DateTime day) {
    return _presenceEngine().hasSummerCampSpecialEventForDay(day);
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

    return _presenceEngine().isCoveredBySupportNetwork(
      day: d0,
      start: fasciaStart,
      end: fasciaEnd,
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
      final companionEnd = _presenceEngine().aliceCompanionEndForRange(
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
    required bool sandraMorningAvailable,
    required bool sandraLunchAvailable,
    required bool sandraEveningAvailable,
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
      sandraMorningAvailable: sandraMorningAvailable,
      sandraLunchAvailable: sandraLunchAvailable,
      sandraEveningAvailable: sandraEveningAvailable,
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
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 16, minute: 25),
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
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 16, minute: 25),
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
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 16, minute: 25),
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
    required bool sandraMorningAvailable,
    required bool sandraLunchAvailable,
    required bool sandraEveningAvailable,
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
      sandraMattinaOn: sandraMorningAvailable,
      sandraPranzoOn: sandraLunchAvailable,
      sandraSeraOn: sandraEveningAvailable,
      schoolStart: (() {
        final cfg = schoolStore
            .activePeriodForDay(_onlyDate(day))
            ?.weekConfig
            .forWeekday(_onlyDate(day).weekday);
        if (cfg == null || !cfg.enabled) {
          return const TimeOfDay(hour: 8, minute: 25);
        }
        return TimeOfDay(
          hour: cfg.entryMinutes ~/ 60,
          minute: cfg.entryMinutes % 60,
        );
      })(),
      overrides: overrides,
      ferieStore: ferieStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      lunchCover: lunchCover,
      schoolOutStart:
          schoolOutStart ??
          (() {
            final cfg = schoolStore
                .activePeriodForDay(_onlyDate(day))
                ?.weekConfig
                .forWeekday(_onlyDate(day).weekday);
            if (cfg == null || !cfg.enabled) {
              return const TimeOfDay(hour: 16, minute: 25);
            }
            return TimeOfDay(
              hour: cfg.exitRealMinutes ~/ 60,
              minute: cfg.exitRealMinutes % 60,
            );
          })(),
      schoolOutEnd:
          schoolOutEnd ??
          (() {
            final cfg = schoolStore
                .activePeriodForDay(_onlyDate(day))
                ?.weekConfig
                .forWeekday(_onlyDate(day).weekday);
            if (cfg == null || !cfg.enabled) {
              return const TimeOfDay(hour: 17, minute: 15);
            }
            final returnMinutes = cfg.returnHomeMinutes;
            return TimeOfDay(
              hour: returnMinutes ~/ 60,
              minute: returnMinutes % 60,
            );
          })(),
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
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 16, minute: 25),
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
    TimeOfDay? uscitaAnticipataAt,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    final d0 = _onlyDate(day);
    final entries = <_CoverageGapEntry>[];

    final bool effSandraMattina = sandraMattinaOn;
    final bool effSandraPranzo = sandraPranzoOn;
    final bool effSandraSera = sandraSeraOn;

    final presenceEngine = _presenceEngine();
    final canonicalTimeline = presenceEngine.coverageTimelineForDay(d0);

    if (canonicalTimeline.isSupported) {
      return _analyzeCanonicalHomeTimeline(
        day: d0,
        windows: canonicalTimeline.windows,
        sandraMattinaAvailable: effSandraMattina,
        sandraPranzoAvailable: effSandraPranzo,
        sandraSeraAvailable: effSandraSera,
        overrides: overrides,
        ferieStore: ferieStore,
      );
    }

    final bool aliceAtHome = presenceEngine.isAliceAtHomeDuringRange(
      day: d0,
      start: DateTime(d0.year, d0.month, d0.day, 7, 30),
      end: DateTime(d0.year, d0.month, d0.day, 23, 59),
    );

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

    final aliceSpecialEvents = _presenceEngine().enabledTimedEventsForDay(d0);
    final bool hasAliceSpecialEvents = aliceSpecialEvents.isNotEmpty;

    final AliceSpecialEvent? firstAliceEvent = hasAliceSpecialEvents
        ? aliceSpecialEvents.first
        : null;
    final AliceSpecialEvent? lastAliceEvent = hasAliceSpecialEvents
        ? aliceSpecialEvents.last
        : null;

    final bool hasTimedAliceEvent =
        firstAliceEvent != null && lastAliceEvent != null;

    final bool aliceSchoolNormal = presenceEngine.isAliceSchoolNormalDay(d0);

    final bool aliceSummerCamp =
        presenceEngine.isAliceSummerCampOperationalDay(d0) ||
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
      final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
      final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 23, 59);

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

      if (schoolInCover == SchoolCoverChoice.none) {
        entries.add(
          _CoverageGapEntry(
            label: labelSchoolIn,
            fasciaStart: schoolInRealStart,
            fasciaEnd: schoolInEnd,
            isHomePresenceWindow: false,
            allowSandra: true,
          ),
        );
      } else {
        final schoolInCoveredByChoice = _isSchoolCoverChoiceValid(
          choice: schoolInCover,
          day: d0,
          fasciaStart: schoolInRealStart,
          fasciaEnd: schoolInEnd,
          allowSandra: true,
          sandraMattinaAvailable: effSandraMattina,
          sandraPranzoAvailable: effSandraPranzo,
          sandraSeraAvailable: effSandraSera,
          isHomePresenceWindow: false,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (!schoolInCoveredByChoice) {
          entries.add(
            _CoverageGapEntry(
              label: labelSchoolIn,
              fasciaStart: schoolInRealStart,
              fasciaEnd: schoolInEnd,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        }
      }

      if (!uscita13) {
        final schoolOutRealDt = _atTime(d0, schoolOutStart);
        final schoolOutPickupEndDt = _atTime(d0, schoolOutEnd);

        final labelSchoolOut =
            "Alice uscita: ${_fmt(schoolOutStart)}–${_fmtTimeDate(schoolOutPickupEndDt)}";

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

        final labelLunch =
            "Alice pranzo: ${_fmt(startLunch)}–${_fmtTimeDate(lunchEnd)}";

        if (lunchCover == SchoolCoverChoice.none) {
          entries.add(
            _CoverageGapEntry(
              label: labelLunch,
              fasciaStart: lunchStart,
              fasciaEnd: lunchEnd,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        } else {
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

          if (!lunchCoveredByChoice) {
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
        final campOutEnd = campOutStart.add(const Duration(minutes: 20));
        final labelCampOut =
            "Alice centro estivo uscita: ${_fmt(effectiveEnd)}–${_fmtTimeDate(campOutEnd)}";

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

        final homeAfterCampStart = campOutEnd;
        final homeAfterCampEnd = _atTime(d0, sandraSeraStart);

        if (homeAfterCampEnd.isAfter(homeAfterCampStart)) {
          entries.addAll(
            _uncoveredHomeSegments(
              day: d0,
              windowStart: homeAfterCampStart,
              windowEnd: homeAfterCampEnd,
              labelPrefix: 'Alice a casa dopo centro estivo',
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
              overrides: overrides,
              ferieStore: ferieStore,
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
      final homeWindowEnd = DateTime(d0.year, d0.month, d0.day, 23, 59);

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

    // 🔥 PRIMA dichiari
    final busyMatteo = _busyShiftsFromRealEventsForPerson(
      personKey: "matteo",
      day: d0,
    );

    // TAGLIO INIZIO
    for (final b in busyMatteo) {
      if (b.start.isAfter(mattinaGapStart) && b.start.isBefore(mattinaGapEnd)) {
        mattinaGapStart = b.start;
      }
    }

    // TAGLIO FINE
    for (final b in busyMatteo) {
      if (b.start.isBefore(mattinaGapEnd) && b.end.isAfter(mattinaGapStart)) {
        mattinaGapEnd = b.end;
      }
    }

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
    DateTime seraGapEnd = fSeraEnd;

    if (effectiveCampEnd != null && effectiveCampEnd.isAfter(seraGapStart)) {
      seraGapStart = effectiveCampEnd;
    }
    final eveningRealEvents = [
      ..._busyShiftsFromRealEventsForPerson(personKey: 'matteo', day: d0),
      ..._busyShiftsFromRealEventsForPerson(personKey: 'chiara', day: d0),
    ];

    for (final eventBusy in eveningRealEvents) {
      final overlapsEvening =
          eventBusy.start.isBefore(seraGapEnd) &&
          eventBusy.end.isAfter(seraGapStart);

      if (overlapsEvening &&
          eventBusy.start.isAtSameMomentAs(seraGapStart) &&
          eventBusy.end.isBefore(seraGapEnd)) {
        seraGapEnd = eventBusy.end;
      }
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
        final hasExistingHomeGapOverlappingSera = entries.any(
          (e) =>
              _isAliceHomeLabel(e.label) &&
              e.fasciaStart.isBefore(seraGapEnd) &&
              e.fasciaEnd.isAfter(seraGapStart),
        );

        if (!hasExistingHomeGapOverlappingSera) {
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
    }

    final normalizedEntries = _dedupeEntriesPreferRichLabel(entries);

    final gaps = <String>[];
    final details = <CoverageGapDetail>[];

    for (final entry in normalizedEntries) {
      final lowerLabel = entry.label.toLowerCase();

      final isSchoolLogisticGap =
          lowerLabel.startsWith('alice ingresso:') ||
          lowerLabel.startsWith('alice uscita:') ||
          lowerLabel.startsWith('alice pranzo:');

      final aliceAlreadyCovered =
          !isSchoolLogisticGap &&
          (_presenceEngine().isAliceAccompaniedDuringRange(
                day: d0,
                start: entry.fasciaStart,
                end: entry.fasciaEnd,
              ) ||
              _presenceEngine().isAliceInsideRealEvent(
                day: d0,
                start: entry.fasciaStart,
                end: entry.fasciaEnd,
              ));

      if (aliceAlreadyCovered) {
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
          start: TimeOfDay(
            hour: entry.fasciaStart.hour,
            minute: entry.fasciaStart.minute,
          ),
          end: TimeOfDay(
            hour: entry.fasciaEnd.hour,
            minute: entry.fasciaEnd.minute,
          ),
        ),
      );
    }

    return CoverageDayAnalysis(gaps: gaps, details: details);
  }

  CoverageDayAnalysis _analyzeCanonicalHomeTimeline({
    required DateTime day,
    required List<AliceCoverageWindow> windows,
    required bool sandraMattinaAvailable,
    required bool sandraPranzoAvailable,
    required bool sandraSeraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final entries = <_CoverageGapEntry>[];
    final criticalities = <CoverageCriticalityDetail>[];
    final availabilityResolver = AdultLogisticsAvailabilityResolver(
      turnEngine: turnEngine,
      diseasePeriodStore: diseasePeriodStore,
      realEventStore: realEventStore,
    );

    List<AdultConstraintInterval> effectiveConstraintsFor({
      required String personKey,
      required TurnPerson person,
    }) {
      final constraints = turnEngine.constraintsForPersonDay(
        person: person,
        day: day,
      );
      final shiftState = availabilityResolver.effectivePlannedShiftState(
        personKey: personKey,
        day: day,
        overrides: overrides,
        ferieStore: ferieStore,
      );
      if (shiftState.isPlannedShiftActive) return constraints;
      return constraints
          .where((constraint) => constraint.kind != AdultConstraintKind.recovery)
          .toList();
    }

    final adultConstraints = <_AdultConstraints>[
      _AdultConstraints(
        personKey: 'matteo',
        person: TurnPerson.matteo,
        constraints: effectiveConstraintsFor(
          personKey: 'matteo',
          person: TurnPerson.matteo,
        ),
      ),
      _AdultConstraints(
        personKey: 'chiara',
        person: TurnPerson.chiara,
        constraints: effectiveConstraintsFor(
          personKey: 'chiara',
          person: TurnPerson.chiara,
        ),
      ),
    ];
    final allConstraints = <AdultConstraintInterval>[
      for (final adult in adultConstraints) ...adult.constraints,
    ];

    for (final window in windows.where((window) => window.requiresAdult)) {
      final points = <DateTime>{window.start, window.end};

      void addIfInside(DateTime point) {
        if (!point.isBefore(window.start) && !point.isAfter(window.end)) {
          points.add(point);
        }
      }

      for (final constraint in allConstraints) {
        addIfInside(constraint.start);
        addIfInside(constraint.end);
      }

      for (final personKey in const ['matteo', 'chiara']) {
        for (final event in _busyShiftsFromRealEventsForPerson(
          personKey: personKey,
          day: day,
        )) {
          addIfInside(event.start);
          addIfInside(event.end);
        }
      }

      for (final person in supportNetworkStore.people) {
        if (!person.enabled ||
            !daySettingsStore.isSupportPersonEnabledForDay(day, person.id)) {
          continue;
        }
        for (final slot in person.effectiveSlots) {
          addIfInside(_atTime(day, slot.start));
          addIfInside(_atTime(day, slot.end));
        }
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

      for (var index = 0; index < ordered.length - 1; index++) {
        final start = ordered[index];
        final end = ordered[index + 1];
        if (!end.isAfter(start)) continue;

        final supportProvider = _supportProviderForRange(
          day: day,
          start: start,
          end: end,
        );
        final sandraCovers = _isSandraWindowCoveringRange(
          day: day,
          fasciaStart: start,
          fasciaEnd: end,
          sandraMattinaAvailable: sandraMattinaAvailable,
          sandraPranzoAvailable: sandraPranzoAvailable,
          sandraSeraAvailable: sandraSeraAvailable,
        );

        final availableAdults = adultConstraints
            .where(
              (adult) => _canSpecificPersonCoverRange(
                personKey: adult.personKey,
                person: adult.person,
                day: day,
                fasciaStart: start,
                fasciaEnd: end,
                isHomePresenceWindow: true,
                overrides: overrides,
                ferieStore: ferieStore,
              ),
            )
            .toList();

        final recoveringAdults = availableAdults
            .where((adult) => adult.isInSacrificableRecovery(start, end))
            .toList();
        final normallyAvailableAdults = availableAdults
            .where((adult) => !adult.isInRecovery(start, end))
            .toList();

        final _CoverageProvider? alternativeProvider;
        if (supportProvider != null) {
          alternativeProvider = _CoverageProvider(
            source: CoverageSource.supportNetwork,
            providerId: supportProvider.providerId,
          );
        } else if (sandraCovers) {
          alternativeProvider = const _CoverageProvider(
            source: CoverageSource.supportNetwork,
            providerId: CoverageProviderIds.sandraLegacy,
          );
        } else if (normallyAvailableAdults.isNotEmpty) {
          final provider = [...normallyAvailableAdults]
            ..sort((a, b) => a.stablePersonId.compareTo(b.stablePersonId));
          alternativeProvider = _CoverageProvider(
            source: CoverageSource.parentNormal,
            providerId: provider.first.stablePersonId,
          );
        } else {
          alternativeProvider = null;
        }

        if (alternativeProvider != null) {
          for (final adult in recoveringAdults) {
            criticalities.add(
              CoverageCriticalityDetail(
                kind: CoverageCriticalityKind.recoveryProtected,
                personId: adult.recoveryPersonId(start, end),
                start: start,
                end: end,
                source: alternativeProvider.source,
                coverageProviderId: alternativeProvider.providerId,
              ),
            );
          }
          continue;
        }

        if (recoveringAdults.isNotEmpty) {
          final orderedRecoveringAdults = [...recoveringAdults]
            ..sort(
              (a, b) => a
                  .recoveryPersonId(start, end)
                  .compareTo(b.recoveryPersonId(start, end)),
            );
          final forcedAdult = orderedRecoveringAdults.first;
          final forcedPersonId = forcedAdult.recoveryPersonId(start, end);
          criticalities.add(
            CoverageCriticalityDetail(
              kind: CoverageCriticalityKind.recoverySacrificed,
              personId: forcedPersonId,
              start: start,
              end: end,
              source: CoverageSource.parentForced,
              coverageProviderId: forcedPersonId,
            ),
          );
          continue;
        }

        if (normallyAvailableAdults.isEmpty) {
          entries.add(
            _CoverageGapEntry(
              label: _homeGapLabel(start, end),
              fasciaStart: start,
              fasciaEnd: end,
              isHomePresenceWindow: true,
              allowSandra: true,
            ),
          );
        }
      }
    }

    final merged = _mergeAdjacentEntries(entries);
    return CoverageDayAnalysis(
      gaps: merged.map((entry) => entry.label).toList(),
      details: merged
          .map(
            (entry) => CoverageGapDetail(
              label: entry.label,
              lines: _buildTypedConstraintExplanation(
                constraints: allConstraints,
                start: entry.fasciaStart,
                end: entry.fasciaEnd,
              ),
              start: TimeOfDay.fromDateTime(entry.fasciaStart),
              end: TimeOfDay.fromDateTime(entry.fasciaEnd),
            ),
          )
          .toList(),
      criticalityDetails: _mergeAdjacentCriticalities(criticalities),
    );
  }

  _SupportCoverageProvider? _supportProviderForRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final providers = <_SupportCoverageProvider>[];
    for (final person in supportNetworkStore.people) {
      if (!person.enabled ||
          !daySettingsStore.isSupportPersonEnabledForDay(day, person.id)) {
        continue;
      }
      for (final slot in person.effectiveSlots) {
        final slotStart = _atTime(day, slot.start);
        final slotEnd = _atTime(day, slot.end);
        if (!slotStart.isAfter(start) && !slotEnd.isBefore(end)) {
          providers.add(
            _SupportCoverageProvider(
              providerId: person.id,
              slotStart: slotStart,
              slotEnd: slotEnd,
            ),
          );
        }
      }
    }
    providers.sort((a, b) {
      final byId = a.providerId.compareTo(b.providerId);
      if (byId != 0) return byId;
      final byStart = a.slotStart.compareTo(b.slotStart);
      if (byStart != 0) return byStart;
      return a.slotEnd.compareTo(b.slotEnd);
    });

    return providers.isEmpty ? null : providers.first;
  }

  List<CoverageCriticalityDetail> _mergeAdjacentCriticalities(
    List<CoverageCriticalityDetail> details,
  ) {
    if (details.isEmpty) return const [];

    final sorted = [...details]
      ..sort((a, b) {
        final byPerson = a.personId.compareTo(b.personId);
        if (byPerson != 0) return byPerson;
        final byKind = a.kind.index.compareTo(b.kind.index);
        if (byKind != 0) return byKind;
        final bySource = a.source.index.compareTo(b.source.index);
        if (bySource != 0) return bySource;
        final byProvider = (a.coverageProviderId ?? '').compareTo(
          b.coverageProviderId ?? '',
        );
        if (byProvider != 0) return byProvider;
        final byStart = a.start.compareTo(b.start);
        if (byStart != 0) return byStart;
        return a.end.compareTo(b.end);
      });

    final merged = <CoverageCriticalityDetail>[];
    var current = sorted.first;
    for (final next in sorted.skip(1)) {
      final identical =
          current.kind == next.kind &&
          current.personId == next.personId &&
          current.source == next.source &&
          current.coverageProviderId == next.coverageProviderId &&
          current.start.isAtSameMomentAs(next.start) &&
          current.end.isAtSameMomentAs(next.end);
      if (identical) continue;

      final sameSemantics =
          current.kind == next.kind &&
          current.personId == next.personId &&
          current.source == next.source &&
          current.coverageProviderId == next.coverageProviderId &&
          current.end.isAtSameMomentAs(next.start);
      if (sameSemantics) {
        current = CoverageCriticalityDetail(
          kind: current.kind,
          personId: current.personId,
          start: current.start,
          end: next.end,
          source: current.source,
          coverageProviderId: current.coverageProviderId,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged..sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      final byEnd = a.end.compareTo(b.end);
      if (byEnd != 0) return byEnd;
      final byPerson = a.personId.compareTo(b.personId);
      if (byPerson != 0) return byPerson;
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      final bySource = a.source.index.compareTo(b.source.index);
      if (bySource != 0) return bySource;
      return (a.coverageProviderId ?? '').compareTo(b.coverageProviderId ?? '');
    });
  }

  List<String> _buildTypedConstraintExplanation({
    required List<AdultConstraintInterval> constraints,
    required DateTime start,
    required DateTime end,
  }) {
    final blockers = constraints
        .where(
          (constraint) =>
              !constraint.canBeSacrificedForCare &&
              constraint.start.isBefore(end) &&
              constraint.end.isAfter(start),
        )
        .toList();

    return blockers
        .map(
          (constraint) =>
              '${adultConstraintPersonDisplayName(constraint.personId)}: '
              '${constraint.kind.italianLabel} '
              '${_fmtTimeDate(constraint.start)}–'
              '${_fmtTimeDate(constraint.end)}.',
        )
        .toList();
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
          !_presenceEngine().isAliceAccompaniedDuringRange(
            day: day,
            start: segStart,
            end: segEnd,
          )) {
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

    final supportAvailable = _presenceEngine().isCoveredBySupportNetwork(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
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
      final busyAdjective = person == TurnPerson.chiara
          ? 'occupata'
          : 'occupato';
      return "$personName è $busyAdjective da evento reale: ${overlappingRealEvent.title} (${_fmt(overlappingRealEvent.startTime!)}–${_fmt(overlappingRealEvent.endTime!)}).";
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
    final previousDay = day.subtract(const Duration(days: 1));
    final plan = turnEngine.turnPlanForPersonDay(
      person: person,
      day: previousDay,
    );

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

    var baseBusyMatteo = _careBlockingShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    var baseBusyChiara = _careBlockingShiftsForPerson(
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

    if (_presenceEngine().isAliceAccompaniedDuringRange(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
    )) {
      return true;
    }

    if (matteoCanCover || chiaraCanCover) return true;

    if (_presenceEngine().isCoveredBySupportNetwork(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
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
      return _presenceEngine().isCoveredBySupportNetwork(
        day: day,
        start: fasciaStart,
        end: fasciaEnd,
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
    return AdultLogisticsAvailabilityResolver(
      turnEngine: turnEngine,
      diseasePeriodStore: diseasePeriodStore,
      realEventStore: realEventStore,
    ).canCoverRange(
      personKey: personKey,
      person: person,
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
      isHomePresenceWindow: isHomePresenceWindow,
      overrides: overrides,
      ferieStore: ferieStore,
      forceAvailableDueToLunchCover:
          (personKey == 'matteo' &&
              daySettingsStore.lunchCoverForDay(day) ==
                  SchoolCoverChoice.matteo) ||
          (personKey == 'chiara' &&
              daySettingsStore.lunchCoverForDay(day) ==
                  SchoolCoverChoice.chiara),
    );
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

  List<WorkShift> _careBlockingShiftsForPerson({
    required TurnPerson person,
    required DateTime day,
  }) {
    return turnEngine
        .constraintsForPersonDay(person: person, day: day)
        .where((constraint) => !constraint.canBeSacrificedForCare)
        .map(
          (constraint) =>
              WorkShift(start: constraint.start, end: constraint.end),
        )
        .toList();
  }

  List<WorkShift> _busyShiftsFromRealEventsForPerson({
    required String personKey,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final events = realEventStore.eventsForDay(d0);

    final busy = <WorkShift>[];

    for (final event in events) {
      if (!event.involvesPerson(personKey)) continue;

      final start = event.startTime == null
          ? DateTime(d0.year, d0.month, d0.day, 0, 0)
          : _atTime(d0, event.startTime!);

      final end = event.endTime == null
          ? DateTime(d0.year, d0.month, d0.day, 23, 59)
          : _atTime(d0, event.endTime!);

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
      if (!event.involvesPerson(personKey)) continue;
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

  AlicePresenceEngine _presenceEngine() {
    return AlicePresenceEngine(
      aliceEventStore: aliceEventStore,
      aliceSpecialEventStore: aliceSpecialEventStore,
      realEventStore: realEventStore,
      schoolStore: schoolStore,
      summerCampScheduleStore: summerCampScheduleStore,
      summerCampSpecialEventStore: summerCampSpecialEventStore,
      aliceCompanionStore: aliceCompanionStore,
      supportNetworkStore: supportNetworkStore,
      daySettingsStore: daySettingsStore,
    );
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
  final List<CoverageCriticalityDetail> criticalityDetails;

  const CoverageDayAnalysis({
    required this.gaps,
    required this.details,
    this.criticalityDetails = const [],
  });

  List<CoverageGapDetail> get gapDetails => details;

  CoverageGapDetail? detailFor(String label) {
    for (final detail in details) {
      if (detail.label == label) return detail;
    }
    return null;
  }
}

class _AdultConstraints {
  final String personKey;
  final TurnPerson person;
  final List<AdultConstraintInterval> constraints;

  const _AdultConstraints({
    required this.personKey,
    required this.person,
    required this.constraints,
  });

  String get stablePersonId =>
      constraints.isEmpty ? personKey : constraints.first.personId;

  bool isInRecovery(DateTime start, DateTime end) {
    return constraints.any(
      (constraint) =>
          constraint.kind == AdultConstraintKind.recovery &&
          constraint.start.isBefore(end) &&
          constraint.end.isAfter(start),
    );
  }

  bool isInSacrificableRecovery(DateTime start, DateTime end) {
    return constraints.any(
      (constraint) =>
          constraint.kind == AdultConstraintKind.recovery &&
          constraint.canBeSacrificedForCare &&
          !constraint.start.isAfter(start) &&
          !constraint.end.isBefore(end),
    );
  }

  String recoveryPersonId(DateTime start, DateTime end) {
    return constraints
        .firstWhere(
          (constraint) =>
              constraint.kind == AdultConstraintKind.recovery &&
              constraint.start.isBefore(end) &&
              constraint.end.isAfter(start),
        )
        .personId;
  }
}

class _CoverageProvider {
  final CoverageSource source;
  final String providerId;

  const _CoverageProvider({required this.source, required this.providerId});
}

class _SupportCoverageProvider {
  final String providerId;
  final DateTime slotStart;
  final DateTime slotEnd;

  const _SupportCoverageProvider({
    required this.providerId,
    required this.slotStart,
    required this.slotEnd,
  });
}

class CoverageGapDetail {
  final String label;
  final List<String> lines;
  final TimeOfDay start;
  final TimeOfDay end;

  const CoverageGapDetail({
    required this.label,
    required this.lines,
    required this.start,
    required this.end,
  });
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
