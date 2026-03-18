import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String fmtTimeOfDay(TimeOfDay t) =>
    "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

String fmtDateTimeHHmm(DateTime dt) =>
    "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

String fmtShortDate(DateTime dt) => DateFormat('dd/MM', 'it_IT').format(dt);

DateTime atDayTime(DateTime day, TimeOfDay t) {
  final d0 = DateTime(day.year, day.month, day.day);
  return DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);
}
