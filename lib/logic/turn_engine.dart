// lib/logic/turn_engine.dart
import 'package:flutter/material.dart';
import '../models/work_shift.dart';
import '../models/fourth_shift_period.dart';
import '../models/real_event.dart';
import '../models/turn_override.dart';
import '../models/rotation_override.dart';
import 'fourth_shift_store.dart';
import 'fourth_shift_cycle_logic.dart';
import 'turn_override_store.dart';
import 'rotation_override_store.dart';

enum TurnPerson { matteo, chiara }

/// ✅ COMPATIBILITÀ UI
/// La UI vecchia ragiona con TurnType + TurnPlan.
enum TurnType { mattina, pomeriggio, notte, off }

/// Piano turno “leggibile” (solo dati, niente logica)
@immutable
class TurnPlan {
  final TurnType type;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isOff;

  const TurnPlan._({
    required this.type,
    required this.start,
    required this.end,
    required this.isOff,
  });

  const TurnPlan.mattina()
    : this._(
        type: TurnType.mattina,
        start: const TimeOfDay(hour: 6, minute: 0),
        end: const TimeOfDay(hour: 14, minute: 0),
        isOff: false,
      );

  const TurnPlan.pomeriggio()
    : this._(
        type: TurnType.pomeriggio,
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 22, minute: 0),
        isOff: false,
      );

  const TurnPlan.notte()
    : this._(
        type: TurnType.notte,
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 6, minute: 0),
        isOff: false,
      );

  const TurnPlan.off()
    : this._(
        type: TurnType.off,
        start: const TimeOfDay(hour: 0, minute: 0),
        end: const TimeOfDay(hour: 0, minute: 0),
        isOff: true,
      );
}

@immutable
class TurnConflictInfo {
  final DateTime day;
  final TurnType matteoTurn;
  final TurnType chiaraTurn;
  final bool hasConflict;
  final String? conflictCode;

  const TurnConflictInfo({
    required this.day,
    required this.matteoTurn,
    required this.chiaraTurn,
    required this.hasConflict,
    required this.conflictCode,
  });

  String get label {
    switch (conflictCode) {
      case 'mattina_mattina':
        return 'Conflitto turni: mattina + mattina';
      case 'pomeriggio_pomeriggio':
        return 'Conflitto turni: pomeriggio + pomeriggio';
      case 'notte_notte':
        return 'Conflitto turni: notte + notte';
      default:
        return 'Nessun conflitto turni';
    }
  }
}

@immutable
class TurnEventConflictInfo {
  final DateTime day;
  final TurnPerson person;
  final List<RealEvent> conflictingEvents;

  const TurnEventConflictInfo({
    required this.day,
    required this.person,
    required this.conflictingEvents,
  });

  bool get hasConflict => conflictingEvents.isNotEmpty;
}

/// Interno: tipo rotazione
enum _TurnoTipo { mattina, pomeriggio, notte, off }

class _TurnoOrari {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isOff;

  const _TurnoOrari({required this.start, required this.end}) : isOff = false;

  const _TurnoOrari.off()
    : start = const TimeOfDay(hour: 0, minute: 0),
      end = const TimeOfDay(hour: 0, minute: 0),
      isOff = true;
}

/// TurnEngine = unico “motore turni”
/// (rotazione + viaggio + notte cross-day + riposo post-notte)
class TurnEngine {
  // Turni base
  static const TimeOfDay _mattinaStart = TimeOfDay(hour: 6, minute: 0);
  static const TimeOfDay _mattinaEnd = TimeOfDay(hour: 14, minute: 0);

  static const TimeOfDay _pomeriggioStart = TimeOfDay(hour: 14, minute: 0);
  static const TimeOfDay _pomeriggioEnd = TimeOfDay(hour: 22, minute: 0);

  static const TimeOfDay _notteStart = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay _notteEnd = TimeOfDay(hour: 6, minute: 0);

  /// ✅ Monday di riferimento per la rotazione (settimana “0”)
  /// NOTA: per evitare DST, le date di rotazione vengono gestite in UTC a mezzogiorno.
  final DateTime refWeekMonday;

  /// ✅ NEW: Quarta Squadra
  final FourthShiftStore fourthShiftStore;
  final FourthShiftCycleLogic fourthShiftCycleLogic;

  /// ✅ NEW: Override turni
  final TurnOverrideStore turnOverrideStore;
  final RotationOverrideStore rotationOverrideStore;

  // Matteo: NOTTE -> POMERIGGIO -> MATTINA (ciclo 3 settimane)
  final List<_TurnoTipo> _cicloMatteo = const [
    _TurnoTipo.notte,
    _TurnoTipo.pomeriggio,
    _TurnoTipo.mattina,
  ];

  // Chiara: POMERIGGIO -> MATTINA -> NOTTE (ciclo 3 settimane)
  final List<_TurnoTipo> _cicloChiara = const [
    _TurnoTipo.pomeriggio,
    _TurnoTipo.mattina,
    _TurnoTipo.notte,
  ];

  TurnEngine({
    DateTime? refWeekMonday,
    FourthShiftStore? fourthShiftStore,
    FourthShiftCycleLogic? fourthShiftCycleLogic,
    TurnOverrideStore? turnOverrideStore,
    RotationOverrideStore? rotationOverrideStore,
  }) : refWeekMonday = _mondayOf(
         _rotUTCNoon(refWeekMonday ?? DateTime(2026, 3, 2)),
       ),
       fourthShiftStore = fourthShiftStore ?? FourthShiftStore(),
       fourthShiftCycleLogic =
           fourthShiftCycleLogic ?? const FourthShiftCycleLogic(),
       turnOverrideStore = turnOverrideStore ?? TurnOverrideStore(),
       rotationOverrideStore = rotationOverrideStore ?? RotationOverrideStore();

  /// ✅ API COMPATIBILITÀ: usata dalla UI vecchia
  TurnPlan turnPlanForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final tipo = _turnoTipoGiorno(person, d0);

    switch (tipo) {
      case _TurnoTipo.mattina:
        return const TurnPlan.mattina();
      case _TurnoTipo.pomeriggio:
        return const TurnPlan.pomeriggio();
      case _TurnoTipo.notte:
        return const TurnPlan.notte();
      case _TurnoTipo.off:
        return const TurnPlan.off();
    }
  }

  /// ✅ NEW: conflitto turni nello stesso giorno
  TurnConflictInfo sameDayConflictFor(DateTime day) {
    final d0 = _onlyDate(day);

    final matteoPlan = turnPlanForPersonDay(person: TurnPerson.matteo, day: d0);
    final chiaraPlan = turnPlanForPersonDay(person: TurnPerson.chiara, day: d0);

    String? code;

    if (!matteoPlan.isOff &&
        !chiaraPlan.isOff &&
        matteoPlan.type == chiaraPlan.type) {
      switch (matteoPlan.type) {
        case TurnType.mattina:
          code = 'mattina_mattina';
          break;
        case TurnType.pomeriggio:
          code = 'pomeriggio_pomeriggio';
          break;
        case TurnType.notte:
          code = 'notte_notte';
          break;
        case TurnType.off:
          code = null;
          break;
      }
    }

    return TurnConflictInfo(
      day: d0,
      matteoTurn: matteoPlan.type,
      chiaraTurn: chiaraPlan.type,
      hasConflict: code != null,
      conflictCode: code,
    );
  }

  bool hasSameDayConflict(DateTime day) {
    return sameDayConflictFor(day).hasConflict;
  }

  /// ✅ NEW: conflitto vero tra evento reale e turno di lavoro della stessa persona.
  /// Controlla il giorno selezionato, inclusa l’eventuale coda della notte del giorno prima.
  TurnEventConflictInfo eventConflictForPersonDay({
    required TurnPerson person,
    required DateTime day,
    required List<RealEvent> events,
  }) {
    final d0 = _onlyDate(day);
    final personKey = _personIdFor(person);

    final personEvents = events.where((e) => e.personKey == personKey).toList();
    if (personEvents.isEmpty) {
      return TurnEventConflictInfo(
        day: d0,
        person: person,
        conflictingEvents: const [],
      );
    }

    final workRanges = _workRangesForCalendarDay(person: person, day: d0);
    if (workRanges.isEmpty) {
      return TurnEventConflictInfo(
        day: d0,
        person: person,
        conflictingEvents: const [],
      );
    }

    final conflicts = <RealEvent>[];

    for (final event in personEvents) {
      final eventRange = _eventRange(event);
      if (eventRange == null) continue;

      final overlaps = workRanges.any(
        (work) => _rangesOverlap(
          work.start,
          work.end,
          eventRange.start,
          eventRange.end,
        ),
      );

      if (overlaps) {
        conflicts.add(event);
      }
    }

    return TurnEventConflictInfo(
      day: d0,
      person: person,
      conflictingEvents: conflicts,
    );
  }

  bool hasEventConflictForPersonDay({
    required TurnPerson person,
    required DateTime day,
    required List<RealEvent> events,
  }) {
    return eventConflictForPersonDay(
      person: person,
      day: day,
      events: events,
    ).hasConflict;
  }

  /// API “motore”: busy shifts = turno + viaggio + riposo post-notte
  List<WorkShift> busyShiftsForPerson({
    required TurnPerson person,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final shifts = <WorkShift>[];

    // 1) turno di oggi (con viaggio)
    final today = _turnoGiorno(person, d0);
    final todayTipo = _turnoTipoGiorno(person, d0);
    if (!today.isOff) {
      shifts.add(_shiftConViaggio(baseDay: d0, turno: today));
    }

    // 2) se ieri era NOTTE: aggiungi shift di ieri
    final ieri = d0.subtract(const Duration(days: 1));
    final ieriTipo = _turnoTipoGiorno(person, ieri);

    if (ieriTipo == _TurnoTipo.notte) {
      final tIeri = _turnoGiorno(person, ieri);
      if (!tIeri.isOff) {
        shifts.add(_shiftConViaggio(baseDay: ieri, turno: tIeri));
      }
    }

    // 3) riposo post-notte:
    // - se ieri era notte (regola storica)
    // - oppure se oggi è notte (regola reale FrodoDesk: N vale anche come coda notte + post-notte)
    if (ieriTipo == _TurnoTipo.notte || todayTipo == _TurnoTipo.notte) {
      shifts.add(
        WorkShift(
          start: DateTime(d0.year, d0.month, d0.day, 0, 0),
          end: DateTime(d0.year, d0.month, d0.day, 14, 30),
        ),
      );
    }

    return shifts;
  }

  // --------------------------
  // Rotazione (DST SAFE)
  // --------------------------

  /// Data “solo giorno” usata per il motore (locale) per gli shift reali.
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isWeekend(int weekday) =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// ✅ Date per calcoli rotazione: UTC a mezzogiorno (DST safe)
  static DateTime _rotUTCNoon(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day, 12, 0);

  static DateTime _mondayOf(DateTime d) {
    final sd = _rotUTCNoon(d);
    final delta = sd.weekday - DateTime.monday;
    return sd.subtract(Duration(days: delta));
  }

  int _weeksBetween(DateTime aMonday, DateTime bMonday) {
    final a = _rotUTCNoon(aMonday);
    final b = _rotUTCNoon(bMonday);
    final diffDays = b.difference(a).inDays; // DST safe perché UTC
    return diffDays ~/ 7;
  }

  _TurnoTipo _turnoSettimanaMatteo(DateTime day) {
    final weekMon = _mondayOf(day);
    final n = _weeksBetween(refWeekMonday, weekMon);
    final idx = ((n % 3) + 3) % 3;
    return _cicloMatteo[idx];
  }

  _TurnoTipo _turnoSettimanaChiara(DateTime day) {
    final weekMon = _mondayOf(day);
    final n = _weeksBetween(refWeekMonday, weekMon);
    final idx = ((n % 3) + 3) % 3;
    return _cicloChiara[idx];
  }

  String _personIdFor(TurnPerson p) {
    switch (p) {
      case TurnPerson.matteo:
        return 'matteo';
      case TurnPerson.chiara:
        return 'chiara';
    }
  }

  TurnPersonId _personModelFor(TurnPerson p) {
    switch (p) {
      case TurnPerson.matteo:
        return TurnPersonId.matteo;
      case TurnPerson.chiara:
        return TurnPersonId.chiara;
    }
  }

  _TurnoTipo _turnoTipoFromTurnType(TurnType t) {
    switch (t) {
      case TurnType.mattina:
        return _TurnoTipo.mattina;
      case TurnType.pomeriggio:
        return _TurnoTipo.pomeriggio;
      case TurnType.notte:
        return _TurnoTipo.notte;
      case TurnType.off:
        return _TurnoTipo.off;
    }
  }

  _TurnoTipo _turnoTipoFromOverrideShift(TurnOverrideShift s) {
    switch (s) {
      case TurnOverrideShift.mattina:
        return _TurnoTipo.mattina;
      case TurnOverrideShift.pomeriggio:
        return _TurnoTipo.pomeriggio;
      case TurnOverrideShift.notte:
        return _TurnoTipo.notte;
      case TurnOverrideShift.off:
        return _TurnoTipo.off;
    }
  }

  _TurnoTipo? _turnoTipoFourthShift(TurnPerson p, DateTime day) {
    final personId = _personIdFor(p);
    final FourthShiftPeriod? period = fourthShiftStore
        .activePeriodForPersonOnDay(personId, day);

    if (period == null) return null;

    final turnType = fourthShiftCycleLogic.turnTypeForDay(period, day);
    return _turnoTipoFromTurnType(turnType);
  }

  _TurnoTipo? _turnoTipoDailyOverride(TurnPerson p, DateTime day) {
    final override = turnOverrideStore.dailyOverrideFor(
      person: _personModelFor(p),
      day: day,
    );

    if (override == null || override.shift == null) return null;

    return _turnoTipoFromOverrideShift(override.shift!);
  }

  _TurnoTipo? _turnoTipoPeriodOverride(TurnPerson p, DateTime day) {
    final override = turnOverrideStore.periodOverrideFor(
      person: _personModelFor(p),
      day: day,
    );

    if (override == null || override.shift == null) return null;

    return _turnoTipoFromOverrideShift(override.shift!);
  }

  _TurnoTipo _turnoTipoGiorno(TurnPerson p, DateTime day) {
    final dailyOverride = _turnoTipoDailyOverride(p, day);
    if (dailyOverride != null) return dailyOverride;

    final periodOverride = _turnoTipoPeriodOverride(p, day);
    if (periodOverride != null) return periodOverride;

    final rotation = rotationOverrideStore.activeFor(
      person: _personModelFor(p),
      day: day,
    );

    if (rotation != null) {
      final start = DateTime(
        rotation.startDate.year,
        rotation.startDate.month,
        rotation.startDate.day,
      );

      final today = DateTime(day.year, day.month, day.day);

      if (_isWeekend(today.weekday)) return _TurnoTipo.off;

      int workedDays = 0;
      DateTime cursor = start;

      while (cursor.isBefore(today)) {
        if (!_isWeekend(cursor.weekday)) {
          workedDays++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      final cycle = [
        _TurnoTipo.mattina,
        _TurnoTipo.notte,
        _TurnoTipo.pomeriggio,
      ];

      int startIndex;

      switch (rotation.startPoint) {
        case RotationStartPoint.mattina:
          startIndex = 0;
          break;
        case RotationStartPoint.notte:
          startIndex = 1;
          break;
        case RotationStartPoint.pomeriggio:
          startIndex = 2;
          break;
      }

      final idx = (startIndex + (workedDays ~/ 5)) % 3;

      return cycle[idx];
    }

    final fourthShiftTipo = _turnoTipoFourthShift(p, day);
    if (fourthShiftTipo != null) return fourthShiftTipo;

    if (_isWeekend(day.weekday)) return _TurnoTipo.off;
    return (p == TurnPerson.matteo)
        ? _turnoSettimanaMatteo(day)
        : _turnoSettimanaChiara(day);
  }

  _TurnoOrari _orariFromTipo(_TurnoTipo t) {
    switch (t) {
      case _TurnoTipo.mattina:
        return const _TurnoOrari(start: _mattinaStart, end: _mattinaEnd);
      case _TurnoTipo.pomeriggio:
        return const _TurnoOrari(start: _pomeriggioStart, end: _pomeriggioEnd);
      case _TurnoTipo.notte:
        return const _TurnoOrari(start: _notteStart, end: _notteEnd);
      case _TurnoTipo.off:
        return const _TurnoOrari.off();
    }
  }

  _TurnoOrari _turnoGiorno(TurnPerson p, DateTime day) =>
      _orariFromTipo(_turnoTipoGiorno(p, day));

  List<WorkShift> _workRangesForCalendarDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final ranges = <WorkShift>[];

    final todayTurn = _turnoGiorno(person, d0);
    if (!todayTurn.isOff) {
      ranges.add(_shiftSoloLavoro(baseDay: d0, turno: todayTurn));
    }

    final ieri = d0.subtract(const Duration(days: 1));
    final ieriTurn = _turnoGiorno(person, ieri);

    if (!ieriTurn.isOff && _isNightShift(ieriTurn)) {
      ranges.add(_shiftSoloLavoro(baseDay: ieri, turno: ieriTurn));
    }

    return ranges
        .map((r) => _clipRangeToDay(r, d0))
        .where((r) => r != null)
        .cast<WorkShift>()
        .toList();
  }

  WorkShift? _clipRangeToDay(WorkShift range, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day, 0, 0);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final start = range.start.isAfter(dayStart) ? range.start : dayStart;
    final end = range.end.isBefore(dayEnd) ? range.end : dayEnd;

    if (!end.isAfter(start)) return null;

    return WorkShift(start: start, end: end);
  }

  WorkShift _shiftSoloLavoro({
    required DateTime baseDay,
    required _TurnoOrari turno,
  }) {
    final s = DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      turno.start.hour,
      turno.start.minute,
    );

    DateTime e = DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      turno.end.hour,
      turno.end.minute,
    );

    final startMin = turno.start.hour * 60 + turno.start.minute;
    final endMin = turno.end.hour * 60 + turno.end.minute;

    if (!turno.isOff && endMin <= startMin) {
      e = e.add(const Duration(days: 1));
    }

    return WorkShift(start: s, end: e);
  }

  bool _isNightShift(_TurnoOrari turno) {
    final startMin = turno.start.hour * 60 + turno.start.minute;
    final endMin = turno.end.hour * 60 + turno.end.minute;
    return !turno.isOff && endMin <= startMin;
  }

  WorkShift? _eventRange(RealEvent event) {
    final startDate = _onlyDate(event.startDate);
    final endDate = _onlyDate(event.endDate);

    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      event.startTime?.hour ?? 0,
      event.startTime?.minute ?? 0,
    );

    DateTime end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      event.endTime?.hour ?? (event.startTime == null ? 23 : 23),
      event.endTime?.minute ?? (event.startTime == null ? 59 : 59),
    );

    if (event.startTime != null &&
        event.endTime != null &&
        startDate == endDate &&
        !end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    if (!end.isAfter(start)) return null;

    return WorkShift(start: start, end: end);
  }

  bool _rangesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  // Turno + viaggio: 1h prima, 30m dopo. Gestisce NOTTE cross-day.
  WorkShift _shiftConViaggio({
    required DateTime baseDay,
    required _TurnoOrari turno,
  }) {
    final s = DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      turno.start.hour,
      turno.start.minute,
    );

    DateTime e = DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      turno.end.hour,
      turno.end.minute,
    );

    final startMin = turno.start.hour * 60 + turno.start.minute;
    final endMin = turno.end.hour * 60 + turno.end.minute;

    // NOTTE: end <= start => end giorno dopo
    if (!turno.isOff && endMin <= startMin) {
      e = e.add(const Duration(days: 1));
    }

    return WorkShift(
      start: s.subtract(const Duration(hours: 1)),
      end: e.add(const Duration(minutes: 30)),
    );
  }
}
