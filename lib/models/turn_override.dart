import 'package:flutter/material.dart';
import 'work_shift.dart';

enum TurnOverrideType {
  dailyShiftChange,
  periodShiftChange,
  rotationProfileChange,
}

enum TurnPersonId { matteo, chiara }

enum TurnOverrideShift { mattina, pomeriggio, notte, off }

@immutable
class TurnOverride {
  final TurnOverrideType type;

  final TurnPersonId person;

  /// giorno inizio override
  final DateTime startDate;

  /// opzionale per override periodo
  final DateTime? endDate;

  /// nuovo turno (giornaliero o periodo)
  final TurnOverrideShift? shift;

  /// indice rotazione per nuova rotazione
  final int? rotationIndex;

  const TurnOverride({
    required this.type,
    required this.person,
    required this.startDate,
    this.endDate,
    this.shift,
    this.rotationIndex,
  });

  bool get isDaily => type == TurnOverrideType.dailyShiftChange;

  bool get isPeriod => type == TurnOverrideType.periodShiftChange;

  bool get isRotation => type == TurnOverrideType.rotationProfileChange;

  bool isActiveOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);

    if (endDate == null) {
      return d == s;
    }

    final e = DateTime(endDate!.year, endDate!.month, endDate!.day);

    return !d.isBefore(s) && !d.isAfter(e);
  }
}
