import 'package:flutter/material.dart';

import '../models/day_override.dart';
import '../models/person_availability.dart';

import 'coverage_logic.dart';
import 'override_apply.dart';
import 'turn_engine.dart';

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
  }) : turnEngine = turnEngine ?? TurnEngine(),
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
  }) {
    return gapsForDayV2(
      day: day,
      uscita13: uscita13,
      sandraMattinaOn: sandraAvailable,
      sandraPranzoOn: sandraAvailable,
      sandraSeraOn: sandraAvailable,
      schoolStart: const TimeOfDay(hour: 8, minute: 25),
      overrides: overrides,
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
  }) {
    final d0 = _onlyDate(day);
    final buchi = <String>[];

    // 1) Alice ingresso 07:30 -> schoolStart (LOGISTICA ESTERNA)
    final schoolInStart = DateTime(d0.year, d0.month, d0.day, 7, 30);
    final schoolInEnd = _atTime(d0, schoolStart);

    final okSchoolIn = _isFasciaCovered(
      day: d0,
      fasciaStart: schoolInStart,
      fasciaEnd: schoolInEnd,
      allowSandra: true,
      sandraAvailable: sandraMattinaOn,
      isHomePresenceWindow: false,
      overrides: overrides,
    );

    final labelSchoolIn = "Alice ingresso: 07:30–${_fmt(schoolStart)}";
    if (!okSchoolIn) buchi.add(labelSchoolIn);

    // 2) 05:00–06:35 (IN CASA) Sandra NON conta
    final fMattinaStart = _atTime(d0, sandraCambioMattinaStart);
    final fMattinaEnd = _atTime(d0, sandraCambioMattinaEnd);

    final okCambioMattina = _isFasciaCovered(
      day: d0,
      fasciaStart: fMattinaStart,
      fasciaEnd: fMattinaEnd,
      allowSandra: false,
      sandraAvailable: false,
      isHomePresenceWindow: true,
      overrides: overrides,
    );

    if (!okCambioMattina) {
      buchi.add(_labelRange(sandraCambioMattinaStart, sandraCambioMattinaEnd));
    }

    // 3) 13:00–14:30 (LOGISTICA ESTERNA) solo se uscita13
    if (uscita13) {
      final fPranzoStart = _atTime(d0, sandraPranzoStart);
      final fPranzoEnd = _atTime(d0, sandraPranzoEnd);

      final okPranzo = _isFasciaCovered(
        day: d0,
        fasciaStart: fPranzoStart,
        fasciaEnd: fPranzoEnd,
        allowSandra: true,
        sandraAvailable: sandraPranzoOn,
        isHomePresenceWindow: false,
        overrides: overrides,
      );

      if (!okPranzo) buchi.add(_labelRange(sandraPranzoStart, sandraPranzoEnd));
    }

    // 4) 21:00–22:35 (IN CASA) Sandra conta solo se toggle ON
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
  }) {
    // 1) busy base da TurnEngine
    final baseBusyMatteo = turnEngine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: day,
    );
    final baseBusyChiara = turnEngine.busyShiftsForPerson(
      person: TurnPerson.chiara,
      day: day,
    );

    // 2) override Step B
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
    final m = overrides.matteo?.status ?? OverrideStatus.normal;
    final c = overrides.chiara?.status ?? OverrideStatus.normal;

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
