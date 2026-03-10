import 'package:flutter/foundation.dart';

import 'day_override.dart';

/// Settimana iniziale del ciclo Quarta Squadra.
/// Il ciclo è sempre di 4 settimane e poi riparte.
enum FourthShiftCycleWeek { week1, week2, week3, week4 }

extension FourthShiftCycleWeekX on FourthShiftCycleWeek {
  int get number {
    switch (this) {
      case FourthShiftCycleWeek.week1:
        return 1;
      case FourthShiftCycleWeek.week2:
        return 2;
      case FourthShiftCycleWeek.week3:
        return 3;
      case FourthShiftCycleWeek.week4:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case FourthShiftCycleWeek.week1:
        return 'Settimana 1';
      case FourthShiftCycleWeek.week2:
        return 'Settimana 2';
      case FourthShiftCycleWeek.week3:
        return 'Settimana 3';
      case FourthShiftCycleWeek.week4:
        return 'Settimana 4';
    }
  }

  static FourthShiftCycleWeek fromNumber(int value) {
    switch (value) {
      case 1:
        return FourthShiftCycleWeek.week1;
      case 2:
        return FourthShiftCycleWeek.week2;
      case 3:
        return FourthShiftCycleWeek.week3;
      case 4:
        return FourthShiftCycleWeek.week4;
      default:
        throw ArgumentError('FourthShiftCycleWeek must be between 1 and 4');
    }
  }
}

/// Periodo attivo di Quarta Squadra per una persona.
///
/// Regole:
/// - vale solo tra startDate e endDate inclusi
/// - startDate è la data di riferimento del ciclo, anche se quel giorno è festa/off
/// - initialCycleWeek dice da quale settimana del ciclo parte il conteggio
/// - personId resta tecnico/stabile, coerente col sistema attuale
@immutable
class FourthShiftPeriod {
  final String personId; // es: matteo / chiara
  final DateTime startDate; // incluso
  final DateTime endDate; // incluso
  final FourthShiftCycleWeek initialCycleWeek;

  FourthShiftPeriod({
    required this.personId,
    required DateTime startDate,
    required DateTime endDate,
    required this.initialCycleWeek,
  }) : startDate = dayKey(startDate),
       endDate = dayKey(endDate) {
    if (personId.trim().isEmpty) {
      throw ArgumentError('personId cannot be empty');
    }

    if (this.endDate.isBefore(this.startDate)) {
      throw ArgumentError('endDate cannot be before startDate');
    }
  }

  int get weekNumber => initialCycleWeek.number;

  String get personLabel {
    switch (personId) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      default:
        return personId;
    }
  }

  String get dateRangeLabel {
    return '${_fmtDate(startDate)} → ${_fmtDate(endDate)}';
  }

  bool containsDay(DateTime day) {
    final d = dayKey(day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  FourthShiftPeriod copyWith({
    String? personId,
    DateTime? startDate,
    DateTime? endDate,
    FourthShiftCycleWeek? initialCycleWeek,
  }) {
    return FourthShiftPeriod(
      personId: personId ?? this.personId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      initialCycleWeek: initialCycleWeek ?? this.initialCycleWeek,
    );
  }

  @override
  String toString() {
    return 'FourthShiftPeriod('
        'personId=$personId, '
        'startDate=${_fmtDate(startDate)}, '
        'endDate=${_fmtDate(endDate)}, '
        'initialCycleWeek=${initialCycleWeek.label}'
        ')';
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
