import '../models/fourth_shift_period.dart';
import 'turn_engine.dart';

class FourthShiftCycleLogic {
  const FourthShiftCycleLogic();

  /// Ritorna l'indice settimana ciclo 1..4 per il [day],
  /// basandosi su:
  /// - startDate del periodo
  /// - initialCycleWeek
  /// - settimane lette sempre lunedì → domenica
  int cycleWeekNumberForDay(FourthShiftPeriod period, DateTime day) {
    if (!period.containsDay(day)) {
      throw ArgumentError('day is outside FourthShiftPeriod');
    }

    final startWeekMonday = _mondayOf(period.startDate);
    final targetWeekMonday = _mondayOf(day);

    final diffDays = targetWeekMonday.difference(startWeekMonday).inDays;
    final diffWeeks = diffDays ~/ 7;

    final startWeek = period.initialCycleWeek.number; // 1..4
    final zeroBased = (startWeek - 1 + diffWeeks) % 4;

    return zeroBased + 1;
  }

  FourthShiftCycleWeek cycleWeekForDay(FourthShiftPeriod period, DateTime day) {
    return FourthShiftCycleWeekX.fromNumber(cycleWeekNumberForDay(period, day));
  }

  /// Turno teorico Quarta Squadra del giorno.
  /// Se il giorno è domenica, torna OFF.
  /// Se il pattern di quella settimana prevede riposo, torna OFF.
  TurnType turnTypeForDay(FourthShiftPeriod period, DateTime day) {
    if (!period.containsDay(day)) {
      throw ArgumentError('day is outside FourthShiftPeriod');
    }

    final week = cycleWeekNumberForDay(period, day);
    final wd = day.weekday; // lun=1 ... dom=7

    switch (week) {
      case 1:
        // Settimana 1 = 6 mattine (lun-sab), dom off
        if (wd >= DateTime.monday && wd <= DateTime.saturday) {
          return TurnType.mattina;
        }
        return TurnType.off;

      case 2:
        // Settimana 2:
        // lun-mar pomeriggio
        // mer off
        // gio-sab notte
        // dom off
        if (wd == DateTime.monday || wd == DateTime.tuesday) {
          return TurnType.pomeriggio;
        }
        if (wd == DateTime.wednesday) {
          return TurnType.off;
        }
        if (wd >= DateTime.thursday && wd <= DateTime.saturday) {
          return TurnType.notte;
        }
        return TurnType.off;

      case 3:
        // Settimana 3 = mer-sab pomeriggio, resto off
        if (wd >= DateTime.wednesday && wd <= DateTime.saturday) {
          return TurnType.pomeriggio;
        }
        return TurnType.off;

      case 4:
        // Settimana 4 = lun-mer notte, resto off
        if (wd >= DateTime.monday && wd <= DateTime.wednesday) {
          return TurnType.notte;
        }
        return TurnType.off;

      default:
        throw StateError('Invalid cycle week: $week');
    }
  }

  DateTime _mondayOf(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final delta = d.weekday - DateTime.monday;
    return d.subtract(Duration(days: delta));
  }
}
