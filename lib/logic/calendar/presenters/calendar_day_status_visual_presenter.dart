import 'package:flutter/material.dart';

import '../models/calendar_day_status.dart';

class CalendarDayStatusVisualPresenter {
  const CalendarDayStatusVisualPresenter();

  Color colorFor(CalendarDayStatus status) => switch (status) {
    CalendarDayStatus.ok => Colors.green,
    CalendarDayStatus.attention => Colors.amber.shade800,
    CalendarDayStatus.problem => Colors.red,
  };
}
