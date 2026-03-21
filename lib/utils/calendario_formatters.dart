import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/work_shift.dart';
import '../models/real_event.dart';
import '../screens/calendario_screen_stepa.dart';

String fmtTimeOfDay(TimeOfDay t) =>
    "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

String fmtDateTimeHHmm(DateTime dt) =>
    "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

String fmtShortDate(DateTime dt) => DateFormat('dd/MM', 'it_IT').format(dt);

DateTime atDayTime(DateTime day, TimeOfDay t) {
  final d0 = DateTime(day.year, day.month, day.day);
  return DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);
}
String cleanGapTitle(String label) {
  final lower = label.toLowerCase();

  if (lower.contains('alice ingresso')) {
    return 'Ingresso scuola';
  }

  if (lower.contains('alice uscita')) {
    return 'Uscita scuola';
  }

  if (lower.contains('pranzo')) {
    return 'Pranzo';
  }

  if (lower.contains('sera')) {
    return 'Sera';
  }

  if (lower.contains('mattina')) {
    return 'Mattina';
  }

  return label;
}
String realEventText(RealEvent event) {
  if (event.startTime != null && event.endTime != null) {
    return "${event.title} ${fmtTimeOfDay(event.startTime!)}–${fmtTimeOfDay(event.endTime!)}";
  }

  if (event.startTime != null) {
    return "${event.title} ${fmtTimeOfDay(event.startTime!)}";
  }

  return "${event.title} • Tutto il giorno";
}
String conflictStateLabel(TurnEventConflictState state) {
  switch (state) {
    case TurnEventConflictState.open:
      return "Conflitto aperto";
    case TurnEventConflictState.partial:
      return "Parzialmente coperto";
    case TurnEventConflictState.resolved:
      return "Risolto";
  }
}
Color conflictStateColor(TurnEventConflictState state) {
  switch (state) {
    case TurnEventConflictState.open:
      return Colors.red;
    case TurnEventConflictState.partial:
      return Colors.orange;
    case TurnEventConflictState.resolved:
      return Colors.green;
  }
}