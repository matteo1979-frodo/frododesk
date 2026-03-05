// lib/logic/coverage_engine.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'turn_engine.dart';
import 'day_settings_store.dart';

// ✅ NEW: Ferie lunghe
import 'ferie_period_store.dart';

class CoverageEngine {
  final TurnEngine turnEngine;

  // Finestre Sandra (mutabili: UI le edita)
  TimeOfDay sandraCambioMattinaStart;
  TimeOfDay sandraCambioMattinaEnd;

  TimeOfDay sandraPranzoStart;
  TimeOfDay sandraPranzoEnd;

  TimeOfDay sandraSeraStart;
  TimeOfDay sandraSeraEnd;

  CoverageEngine({
    TurnEngine? turnEngine,
    TimeOfDay? sandraCambioMattinaStart,
    TimeOfDay? sandraCambioMattinaEnd,
    TimeOfDay? sandraPranzoStart,
    TimeOfDay? sandraPranzoEnd,
    TimeOfDay? sandraSeraStart,
    TimeOfDay? sandraSeraEnd,
  })  : turnEngine = turnEngine ?? TurnEngine(),
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

  List<String> gapsForDay({
    required DateTime day,
    required bool uscita13,
    required bool sandraAvailable,
    required DayOverrides overrides,

    // ✅ NEW: ferie lunghe (periodi)
    FeriePeriodStore? ferieStore,
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

    // ✅ NEW: ferie lunghe (periodi)
    FeriePeriodStore? ferieStore,

    // ✅ decisioni scuola (default = Nessuno ⇒ BUCO decisione richiesta)
    SchoolCoverChoice schoolInCover = SchoolCoverChoice.none,
    SchoolCoverChoice schoolOutCover = SchoolCoverChoice.none,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 17, minute: 15),

    // ✅ NUOVO: decisione pranzo (solo se uscita13) — come scuola
    SchoolCoverChoice lunchCover = SchoolCoverChoice.none,
  }) {
    final d0 = _onlyDate(day);
    final buchi = <String>[];

    // 1) Alice ingresso 07:30 -> schoolStart (DECISIONE)
    final labelSchoolIn = "Alice ingresso: 07:30–${_fmt(schoolStart)}";
    if (schoolInCover == SchoolCoverChoice.none) {
      buchi.add(labelSchoolIn);
    }

    // 1b) Alice uscita 16:25 -> 17:15 (DECISIONE)
    final labelSchoolOut =
        "Alice uscita: ${_fmt(schoolOutStart)}–${_fmt(schoolOutEnd)}";
    if (schoolOutCover == SchoolCoverChoice.none) {
      buchi.add(labelSchoolOut);
    }

    // ✅ 1c) Pranzo (solo se uscita13) — DECISIONE come scuola
    if (uscita13) {
      final labelLunch =
          "Alice pranzo: ${_fmt(sandraPranzoStart)}–${_fmt(sandraPranzoEnd)}";
      if (lunchCover == SchoolCoverChoice.none) {
        buchi.add(labelLunch);
      }
    }

    // 2) 05:00–06:35 (IN CASA) — copertura calcolata (genitori + malattia + Sandra)
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

    // 3) (prima era calcolo automatico) → ORA è decisione (vedi sopra)
    //    quindi NON aggiungiamo più qui logica di copertura per 13:00–14:30.

    // 4) 21:00–22:35 (IN CASA) — copertura calcolata
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

    // ✅ NEW: ferie lunghe (periodi)
    FeriePeriodStore? ferieStore,
  }) {
    // ✅ PRIORITÀ: Override manuale (Step B) > Ferie lunghe
    final matteoHasManual = overrides.matteo != null;
    final chiaraHasManual = overrides.chiara != null;

    final matteoHoliday = (!matteoHasManual) &&
        (ferieStore?.isOnHoliday(FeriePerson.matteo, day) ?? false);
    final chiaraHoliday = (!chiaraHasManual) &&
        (ferieStore?.isOnHoliday(FeriePerson.chiara, day) ?? false);

    // 1) busy base da TurnEngine
    var baseBusyMatteo = turnEngine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    var baseBusyChiara = turnEngine.busyShiftsForPerson(
      person: TurnPerson.chiara,
      day: day,
    );

    // ✅ Se ferie lunghe attive (e NON c'è override manuale): persona libera
    if (matteoHoliday) baseBusyMatteo = [];
    if (chiaraHoliday) baseBusyChiara = [];

    // 2) override Step B (se presente)
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

    // 3) genitori coprono se uno è libero per tutta la fascia
    final coveredByParents =
        isTimeCovered(fasciaStart, fasciaEnd, <PersonAvailability>[
      PersonAvailability(busyShifts: matteoBusy),
      PersonAvailability(busyShifts: chiaraBusy),
    ]);
    if (coveredByParents) return true;

    // 4) regole malattia (dominanti)
    // ✅ ferie lunghe: se NON c'è override manuale, lo status effettivo è "ferie"
    final m = overrides.matteo?.status ??
        (matteoHoliday ? OverrideStatus.ferie : OverrideStatus.normal);
    final c = overrides.chiara?.status ??
        (chiaraHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    final hasLeggera = (m == OverrideStatus.malattiaLeggera) ||
        (c == OverrideStatus.malattiaLeggera);

    final hasALetto = (m == OverrideStatus.malattiaALetto) ||
        (c == OverrideStatus.malattiaALetto);

    final overlapsImps = _overlapsImps(
      day: day,
      start: fasciaStart,
      end: fasciaEnd,
    );

    // Malattia a letto: copre SOLO presenza in casa
    if (hasALetto && isHomePresenceWindow) return true;

    // Malattia leggera: copre tutto, ma NON logistica esterna durante IMPS
    if (hasLeggera) {
      if (!isHomePresenceWindow && overlapsImps) {
        // vincolo: deve stare a casa
      } else {
        return true;
      }
    }

    // 5) Sandra
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