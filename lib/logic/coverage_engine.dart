import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'turn_engine.dart';
import 'day_settings_store.dart';

// ✅ NEW: Ferie lunghe
import 'ferie_period_store.dart';

// ✅ NEW: Eventi Alice
import 'alice_event_store.dart';

// ✅ NEW: Centro estivo settimanale
import 'summer_camp_schedule_store.dart';

class CoverageEngine {
  final TurnEngine turnEngine;

  // ✅ NEW: Eventi Alice (aggancio strutturale)
  final AliceEventStore aliceEventStore;

  // ✅ NEW: Centro estivo settimanale (aggancio strutturale)
  final SummerCampScheduleStore summerCampScheduleStore;

  // Finestre Sandra (mutabili: UI le edita)
  TimeOfDay sandraCambioMattinaStart;
  TimeOfDay sandraCambioMattinaEnd;

  TimeOfDay sandraPranzoStart;
  TimeOfDay sandraPranzoEnd;

  TimeOfDay sandraSeraStart;
  TimeOfDay sandraSeraEnd;

  CoverageEngine({
    TurnEngine? turnEngine,
    AliceEventStore? aliceEventStore,
    SummerCampScheduleStore? summerCampScheduleStore,
    TimeOfDay? sandraCambioMattinaStart,
    TimeOfDay? sandraCambioMattinaEnd,
    TimeOfDay? sandraPranzoStart,
    TimeOfDay? sandraPranzoEnd,
    TimeOfDay? sandraSeraStart,
    TimeOfDay? sandraSeraEnd,
  }) : turnEngine = turnEngine ?? TurnEngine(),
       aliceEventStore = aliceEventStore ?? AliceEventStore(),
       summerCampScheduleStore =
           summerCampScheduleStore ?? SummerCampScheduleStore(),
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

  List<String> gapsForDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraAvailable,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    TimeOfDay? schoolOutStart,
    TimeOfDay? schoolOutEnd,
    TimeOfDay? uscitaAnticipataAt,

    // ✅ opzionali: se passati, prevalgono sullo store
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,

    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
  }) {
    return gapsForDayV2(
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
    final d0 = _onlyDate(day);
    final buchi = <String>[];
    final bool aliceAtHome = isAliceAtHomeDay(d0);
    final bool aliceSchoolNormal = isAliceSchoolNormalDay(d0);
    final bool aliceSummerCamp = isAliceSummerCampOperationalDay(d0);

    final AliceEventPeriod? activeSummerCampPeriod = getSummerCampPeriodForDay(
      d0,
    );

    // ✅ Alice a casa = finestra domestica dedicata
    if (aliceAtHome) {
      final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
      final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 16, 25);

      final okAliceHome = _isFasciaCovered(
        day: d0,
        fasciaStart: aliceHomeStart,
        fasciaEnd: aliceHomeEnd,
        allowSandra: true,
        sandraAvailable: sandraMattinaOn || sandraPranzoOn || sandraSeraOn,
        isHomePresenceWindow: true,
        overrides: overrides,
        ferieStore: ferieStore,
      );

      if (!okAliceHome) {
        buchi.add("Alice a casa: 07:30–16:25");
      }
    }

    // ✅ Scuola normale implicita
    if (aliceSchoolNormal) {
      final labelSchoolIn = "Alice ingresso: 07:30–${_fmt(schoolStart)}";
      if (schoolInCover == SchoolCoverChoice.none) {
        buchi.add(labelSchoolIn);
      }

      if (!uscita13) {
        final labelSchoolOut =
            "Alice uscita: ${_fmt(schoolOutStart)}–${_fmt(schoolOutEnd)}";
        if (schoolOutCover == SchoolCoverChoice.none) {
          buchi.add(labelSchoolOut);
        }
      }

      if (uscita13) {
        final startLunch = uscitaAnticipataAt ?? sandraPranzoStart;
        final labelLunch =
            "Alice pranzo: ${_fmt(startLunch)}–${_fmt(sandraPranzoEnd)}";
        if (lunchCover == SchoolCoverChoice.none) {
          buchi.add(labelLunch);
        }
      }
    }

    // ✅ Centro estivo: adesso legge davvero dallo store settimanale
    if (aliceSummerCamp && activeSummerCampPeriod != null) {
      final dayConfig = getSummerCampConfigForDay(d0);

      if (dayConfig.enabled) {
        final campStart = summerCampStart ?? dayConfig.start;
        final campEnd = summerCampEnd ?? dayConfig.end;

        final labelCampIn =
            "Alice centro estivo ingresso: 07:30–${_fmt(campStart)}";
        buchi.add(labelCampIn);

        final labelCampOut =
            "Alice centro estivo uscita: ${_fmt(campEnd)}–18:00";
        buchi.add(labelCampOut);
      } else {
        final aliceHomeStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
        final aliceHomeEnd = DateTime(d0.year, d0.month, d0.day, 16, 25);

        final okAliceHome = _isFasciaCovered(
          day: d0,
          fasciaStart: aliceHomeStart,
          fasciaEnd: aliceHomeEnd,
          allowSandra: true,
          sandraAvailable: sandraMattinaOn || sandraPranzoOn || sandraSeraOn,
          isHomePresenceWindow: true,
          overrides: overrides,
          ferieStore: ferieStore,
        );

        if (!okAliceHome) {
          buchi.add("Alice a casa: 07:30–16:25");
        }
      }
    }

    // 2) 05:00–06:35 (IN CASA)
    final fMattinaStart = _atTime(d0, sandraCambioMattinaStart);
    final fMattinaEnd = _atTime(d0, sandraCambioMattinaEnd);

    final okCambioMattina = _isFasciaCovered(
      day: d0,
      fasciaStart: fMattinaStart,
      fasciaEnd: fMattinaEnd,
      allowSandra: true,
      sandraAvailable: sandraMattinaOn,
      isHomePresenceWindow: true,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    if (!okCambioMattina) {
      buchi.add(_labelRange(sandraCambioMattinaStart, sandraCambioMattinaEnd));
    }

    // 4) 21:00–22:35 (IN CASA)
    final fSeraStart = _atTime(d0, sandraSeraStart);
    final fSeraEnd = _atTime(d0, sandraSeraEnd);

    final okSera = _isFasciaCovered(
      day: d0,
      fasciaStart: fSeraStart,
      fasciaEnd: fSeraEnd,
      allowSandra: true,
      sandraAvailable: sandraSeraOn,
      isHomePresenceWindow: true,
      overrides: overrides,
      ferieStore: ferieStore,
    );

    if (!okSera) buchi.add(_labelRange(sandraSeraStart, sandraSeraEnd));

    return buchi;
  }

  bool _isFasciaCovered({
    required DateTime day,
    required DateTime fasciaStart,
    required DateTime fasciaEnd,
    required bool allowSandra,
    required bool sandraAvailable,
    required bool isHomePresenceWindow,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final matteoHasManual = overrides.matteo != null;
    final chiaraHasManual = overrides.chiara != null;

    final matteoHoliday =
        (!matteoHasManual) &&
        (ferieStore?.isOnHoliday(FeriePerson.matteo, day) ?? false);
    final chiaraHoliday =
        (!chiaraHasManual) &&
        (ferieStore?.isOnHoliday(FeriePerson.chiara, day) ?? false);

    var baseBusyMatteo = turnEngine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    var baseBusyChiara = turnEngine.busyShiftsForPerson(
      person: TurnPerson.chiara,
      day: day,
    );

    if (matteoHoliday) baseBusyMatteo = [];
    if (chiaraHoliday) baseBusyChiara = [];

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
        (matteoHoliday ? OverrideStatus.ferie : OverrideStatus.normal);
    final c =
        overrides.chiara?.status ??
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
        // vincolo: deve stare a casa
      } else {
        return true;
      }
    }

    if (allowSandra && sandraAvailable) return true;

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
