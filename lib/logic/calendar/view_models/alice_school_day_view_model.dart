import 'package:flutter/material.dart';

import '../../../models/alice_special_event.dart';
import 'alice_event_tile_view_model.dart';

class AliceSchoolEventViewModel {
  final AliceSpecialEvent event;
  final AliceEventTileViewModel tile;
  final List<String> conflictWith;
  final String categoryText;
  final String timeText;
  final String? noteText;

  const AliceSchoolEventViewModel({
    required this.event,
    required this.tile,
    required this.conflictWith,
    required this.categoryText,
    required this.timeText,
    required this.noteText,
  });
}

class AliceSchoolCategoryOptionViewModel {
  final AliceSpecialEventCategory value;
  final String label;
  final IconData icon;

  const AliceSchoolCategoryOptionViewModel({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class AliceSchoolDayViewModel {
  static const maxVisibleEvents = 2;

  final String title;
  final String subtitle;
  final String stateLabel;
  final Color stateColor;
  final IconData stateIcon;
  final String? periodLabel;
  final Color periodColor;
  final IconData periodIcon;
  final String schoolHoursLabel;
  final bool hasEarlySchoolExit;
  final bool hasEventConflict;
  final List<AliceSchoolEventViewModel> events;
  final List<AliceSchoolEventViewModel> visibleEvents;
  final int hiddenEventsCount;
  final bool showSummerCampSpecialCard;
  final String schoolPeriodLabel;
  final bool isSchoolDayActive;
  final String schoolWeekdayLabel;
  final TimeOfDay accompanimentStart;
  final TimeOfDay schoolEntryAt;
  final TimeOfDay schoolExitAt;
  final TimeOfDay schoolExitWindowEnd;
  final TimeOfDay schoolOutStart;
  final TimeOfDay schoolOutEnd;
  final bool hasCustomSchoolOut;
  final List<AliceSchoolCategoryOptionViewModel> categoryOptions;

  const AliceSchoolDayViewModel({
    required this.title,
    required this.subtitle,
    required this.stateLabel,
    required this.stateColor,
    required this.stateIcon,
    required this.periodLabel,
    required this.periodColor,
    required this.periodIcon,
    required this.schoolHoursLabel,
    required this.hasEarlySchoolExit,
    required this.hasEventConflict,
    required this.events,
    required this.visibleEvents,
    required this.hiddenEventsCount,
    required this.showSummerCampSpecialCard,
    required this.schoolPeriodLabel,
    required this.isSchoolDayActive,
    required this.schoolWeekdayLabel,
    required this.accompanimentStart,
    required this.schoolEntryAt,
    required this.schoolExitAt,
    required this.schoolExitWindowEnd,
    required this.schoolOutStart,
    required this.schoolOutEnd,
    required this.hasCustomSchoolOut,
    required this.categoryOptions,
  });
}
