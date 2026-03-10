import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';
import '../models/disease_period.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'turn_engine.dart';
import 'day_settings_store.dart';
import 'support_network_store.dart';
import 'disease_period_store.dart';

// ✅ NEW: Ferie lunghe
import 'ferie_period_store.dart';

// ✅ NEW: Eventi Alice
import 'alice_event_store.dart';

// ✅ NEW: Centro estivo settimanale
import 'summer_camp_schedule_store.dart';

// ✅ NEW: Eventi speciali centro estivo
import 'summer_camp_special_event_store.dart';

class CoverageEngine {
  final TurnEngine turnEngine;
  final DaySettingsStore daySettingsStore;
  final SupportNetworkStore supportNetworkStore;
  final DiseasePeriodStore diseasePeriodStore;

  // ✅ NEW: Eventi Alice (aggancio strutturale)
  final AliceEventStore aliceEventStore;

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
    AliceEventStore? aliceEventStore,
    SummerCampScheduleStore? summerCampScheduleStore,
    SummerCampSpecialEventStore? summerCampSpecialEventStore,
    TimeOfDay? sandraCambioMattinaStart,
    TimeOfDay? sandraCambioMattinaEnd,
    TimeOfDay? sandraPranzoStart,
    TimeOfDay? sandraPranzoEnd,
    TimeOfDay? sandraSeraStart,
    TimeOfDay? sandraSeraEnd,
  }) : turnEngine = turnEngine ?? TurnEngine(),
       daySettingsStore = daySettingsStore ?? DaySettingsStore(),
       supportNetworkStore = supportNetworkStore ?? SupportNetworkStore(),
       diseasePeriodStore = diseasePeriodStore ?? DiseasePeriodStore(),
       aliceEventStore = aliceEventStore ?? AliceEventStore(),
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
    return aliceEventStore.hasSummerCampPeriodForDay(day);
  }

  AliceEventType? getAliceEventTypeForDay(DateTime day) {
    return aliceEventStore.getEventTypeForDay(day);
  }

  AliceEventPeriod? getSummerCampPeriodForDay(DateTime day) {
    return aliceEventStore.getSummerCampPeriodForDay(day);
  }

  SummerCampDayConfig getSummerCampConfigForDay(DateTime day) {
    return summerCampScheduleStore.getConfigForDay(day);
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

    final eveningStart = _atTime(d0, sandraSeraStart);
    final eveningEnd = _atTime(d0, sandraSeraEnd);

    final bool serveMattina = !_isFasciaCovered(
      day: d0,
      fasciaStart: morningStart,
      fasciaEnd: morningEnd,
      allowSandra: false,
      sandraMattinaAvailable: false,
      sandraPranzoAvailable: false,
      sandraSeraAvailable: false,
      isHomePresenceWindow: true,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    final bool serveSera = !_isFasciaCovered(
      day: d0,
      fasciaStart: eveningStart,
      fasciaEnd: eveningEnd,
      allowSandra: false,
      sandraMattinaAvailable: false,
      sandraPranzoAvailable: false,
      sandraSeraAvailable: false,
      isHomePresenceWindow: true,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    bool servePranzo = false;

    if (uscita13 && lunchCover == SchoolCoverChoice.none) {
      final lunchStartTime = uscitaAnticipataAt ?? sandraPranzoStart;
      final lunchStart = _atTime(d0, lunchStartTime);
      final lunchEnd = _atTime(d0, sandraPranzoEnd);

      servePranzo = !_isFasciaCovered(
        day: d0,
        fasciaStart: lunchStart,
        fasciaEnd: lunchEnd,
        allowSandra: false,
        sandraMattinaAvailable: false,
        sandraPranzoAvailable: false,
        sandraSeraAvailable: false,
        isHomePresenceWindow: false,
        overrides: overrides,
        ferieStore: ferieStore,
      );
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
    final bool isWeekend =
        d0.weekday == DateTime.saturday || d0.weekday == DateTime.sunday;
    final bool aliceSchoolNormal = isAliceSchoolNormalDay(d0) && !isWeekend;
    final bool aliceSummerCamp = isAliceSummerCampOperationalDay(d0);

    final AliceEventPeriod? activeSummerCampPeriod = getSummerCampPeriodForDay(
      d0,
    );

    if (aliceAtHome) {
      final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
      final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 16, 25);

      final okAliceHome = _isFasciaCovered(
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

      if (!okAliceHome) {
        entries.add(
          _CoverageGapEntry(
            label: "Alice a casa: 07:30–16:25",
            fasciaStart: aliceHomeStart,
            fasciaEnd: aliceHomeEnd,
            isHomePresenceWindow: true,
            allowSandra: true,
          ),
        );
      }
    }

    if (aliceSchoolNormal) {
      final schoolInStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
      final schoolInEnd = _atTime(d0, schoolStart);
      final labelSchoolIn = "Alice ingresso: 07:30–${_fmt(schoolStart)}";
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
      }

      if (!uscita13) {
        final schoolOutStartDt = _atTime(d0, schoolOutStart);
        final schoolOutEndDt = _atTime(d0, schoolOutEnd);
        final labelSchoolOut =
            "Alice uscita: ${_fmt(schoolOutStart)}–${_fmt(schoolOutEnd)}";
        if (schoolOutCover == SchoolCoverChoice.none) {
          entries.add(
            _CoverageGapEntry(
              label: labelSchoolOut,
              fasciaStart: schoolOutStartDt,
              fasciaEnd: schoolOutEndDt,
              isHomePresenceWindow: false,
              allowSandra: true,
            ),
          );
        }
      }

      if (uscita13) {
        final startLunch = uscitaAnticipataAt ?? sandraPranzoStart;
        final lunchStart = _atTime(d0, startLunch);
        final lunchEnd = _atTime(d0, sandraPranzoEnd);

        final lunchCoveredBySandra =
            effSandraPranzo &&
            _isSandraWindowCoveringRange(
              day: d0,
              fasciaStart: lunchStart,
              fasciaEnd: lunchEnd,
              sandraMattinaAvailable: effSandraMattina,
              sandraPranzoAvailable: effSandraPranzo,
              sandraSeraAvailable: effSandraSera,
            );

        final labelLunch =
            "Alice pranzo: ${_fmt(startLunch)}–${_fmt(sandraPranzoEnd)}";

        if (lunchCover == SchoolCoverChoice.none && !lunchCoveredBySandra) {
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
    }

    if (aliceSummerCamp && activeSummerCampPeriod != null) {
      final specialEvent = getSummerCampSpecialEventForDay(d0);
      final dayConfig = getSummerCampConfigForDay(d0);

      final bool effectiveEnabled = specialEvent?.enabled ?? dayConfig.enabled;
      final TimeOfDay effectiveStart =
          summerCampStart ?? specialEvent?.start ?? dayConfig.start;
      final TimeOfDay effectiveEnd =
          summerCampEnd ?? specialEvent?.end ?? dayConfig.end;

      if (effectiveEnabled) {
        if (specialEvent != null) {
          final specialStart = _atTime(d0, effectiveStart);
          final specialEnd = _atTime(d0, effectiveEnd);
          entries.add(
            _CoverageGapEntry(
              label:
                  "Centro estivo speciale: ${specialEvent.label} ${_fmt(effectiveStart)}–${_fmt(effectiveEnd)}",
              fasciaStart: specialStart,
              fasciaEnd: specialEnd,
              isHomePresenceWindow: false,
              allowSandra: false,
            ),
          );
        }

        final campInStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
        final campInEnd = _atTime(d0, effectiveStart);
        final labelCampIn =
            "Alice centro estivo ingresso: 07:30–${_fmt(effectiveStart)}";
        entries.add(
          _CoverageGapEntry(
            label: labelCampIn,
            fasciaStart: campInStart,
            fasciaEnd: campInEnd,
            isHomePresenceWindow: false,
            allowSandra: true,
          ),
        );

        final campOutStart = _atTime(d0, effectiveEnd);
        final campOutEnd = DateTime(d0.year, d0.month, d0.day, 18, 0);
        final labelCampOut =
            "Alice centro estivo uscita: ${_fmt(effectiveEnd)}–18:00";
        entries.add(
          _CoverageGapEntry(
            label: labelCampOut,
            fasciaStart: campOutStart,
            fasciaEnd: campOutEnd,
            isHomePresenceWindow: false,
            allowSandra: true,
          ),
        );
      } else {
        final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
        final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 16, 25);

        final okAliceHome = _isFasciaCovered(
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

        if (!okAliceHome) {
          entries.add(
            _CoverageGapEntry(
              label: "Alice a casa: 07:30–16:25",
              fasciaStart: aliceHomeStart,
              fasciaEnd: aliceHomeEnd,
              isHomePresenceWindow: true,
              allowSandra: true,
            ),
          );
        }
      }
    }

    final fMattinaStart = _atTime(d0, sandraCambioMattinaStart);
    final fMattinaEnd = _atTime(d0, sandraCambioMattinaEnd);

    final okCambioMattina = _isFasciaCovered(
      day: d0,
      fasciaStart: fMattinaStart,
      fasciaEnd: fMattinaEnd,
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
          label: _labelRange(sandraCambioMattinaStart, sandraCambioMattinaEnd),
          fasciaStart: fMattinaStart,
          fasciaEnd: fMattinaEnd,
          isHomePresenceWindow: true,
          allowSandra: true,
        ),
      );
    }

    final fSeraStart = _atTime(d0, sandraSeraStart);
    final fSeraEnd = _atTime(d0, sandraSeraEnd);

    final okSera = _isFasciaCovered(
      day: d0,
      fasciaStart: fSeraStart,
      fasciaEnd: fSeraEnd,
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
          label: _labelRange(sandraSeraStart, sandraSeraEnd),
          fasciaStart: fSeraStart,
          fasciaEnd: fSeraEnd,
          isHomePresenceWindow: true,
          allowSandra: true,
        ),
      );
    }

    final gaps = <String>[];
    final details = <CoverageGapDetail>[];

    for (final entry in entries) {
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

    final matteoBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: baseBusyMatteo,
      personOverride: overrides.matteo,
    );
    final chiaraBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: baseBusyChiara,
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
  }) {
    if (status == OverrideStatus.malattiaALetto) {
      if (isHomePresenceWindow) {
        return "$personName è a casa ma non può coprire questa fascia perché è a letto per malattia.";
      }
      return "$personName è a casa ma non può accompagnare Alice perché è a letto per malattia.";
    }

    if (status == OverrideStatus.malattiaLeggera) {
      final overlapsImps = _overlapsImps(
        day: day,
        start: fasciaStart,
        end: fasciaEnd,
      );

      if (isHomePresenceWindow) {
        return "$personName potrebbe coprire da casa (malattia leggera).";
      }

      if (overlapsImps) {
        return "$personName ha malattia leggera ma in questa fascia deve restare a casa per reperibilità INPS.";
      }

      return "$personName potrebbe coprire questa fascia (malattia leggera).";
    }

    if (status == OverrideStatus.ferie) {
      return "$personName risulta disponibile in questa fascia (ferie).";
    }

    final isFree = isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
      PersonAvailability(busyShifts: busyShifts.cast()),
    ]);

    if (isFree) {
      return "$personName risulta disponibile in questa fascia.";
    }

    if (_isPostNightForPersonDay(person: person, day: day)) {
      return "$personName è in riposo post-notte.";
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

    final matteoBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: baseBusyMatteo,
      personOverride: overrides.matteo,
    );
    final chiaraBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: baseBusyChiara,
      personOverride: overrides.chiara,
    );

    final coveredByParents =
        isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
          PersonAvailability(busyShifts: matteoBusy),
          PersonAvailability(busyShifts: chiaraBusy),
        ]);
    if (coveredByParents) return true;

    final m =
        overrides.matteo?.status ??
        matteoDiseaseStatus ??
        (matteoHoliday ? OverrideStatus.ferie : OverrideStatus.normal);
    final c =
        overrides.chiara?.status ??
        chiaraDiseaseStatus ??
        (chiaraHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    final hasLeggera =
        (m == OverrideStatus.malattiaLeggera) ||
        (c == OverrideStatus.malattiaLeggera);

    final hasALetto =
        (m == OverrideStatus.malattiaALetto) ||
        (c == OverrideStatus.malattiaALetto);

    final overlapsImps = _overlapsImps(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
    );

    if (hasALetto && isHomePresenceWindow) return true;

    if (hasLeggera) {
      if (!isHomePresenceWindow && overlapsImps) {
        // vincolo INPS: deve stare a casa
      } else {
        return true;
      }
    }

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

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _atTime(DateTime d0, TimeOfDay t) =>
      DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);

  String _labelRange(TimeOfDay a, TimeOfDay b) => "${_fmt(a)}–${_fmt(b)}";

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
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
