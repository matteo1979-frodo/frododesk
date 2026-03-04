// lib/logic/turn_engine.dart
import 'package:flutter/material.dart';
import '../models/work_shift.dart';

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

  TurnEngine({DateTime? refWeekMonday})
      : refWeekMonday = _mondayOf(
          _rotUTCNoon(refWeekMonday ?? DateTime(2026, 3, 2)),
        );

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

  /// API “motore”: busy shifts = turno + viaggio + riposo post-notte
  List<WorkShift> busyShiftsForPerson({
    required TurnPerson person,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);
    final shifts = <WorkShift>[];

    // 1) turno di oggi (con viaggio)
    final today = _turnoGiorno(person, d0);
    if (!today.isOff) {
      shifts.add(_shiftConViaggio(baseDay: d0, turno: today));
    }

    // 2) se ieri era NOTTE: aggiungi shift di ieri + riposo 00:00->14:30
    final ieri = d0.subtract(const Duration(days: 1));
    final ieriTipo = _turnoTipoGiorno(person, ieri);

    if (ieriTipo == _TurnoTipo.notte) {
      final tIeri = _turnoGiorno(person, ieri);
      if (!tIeri.isOff) {
        shifts.add(_shiftConViaggio(baseDay: ieri, turno: tIeri));
      }

      // riposo post-notte (regola consolidata)
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

  _TurnoTipo _turnoTipoGiorno(TurnPerson p, DateTime day) {
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