import 'package:flutter/material.dart';

import '../../alice_event_store.dart';
import '../../alice_events/alice_event_engine.dart';
import '../../core_store.dart';
import '../../../models/alice_special_event.dart';
import '../../../utils/calendario_formatters.dart';
import '../view_models/alice_school_day_view_model.dart';
import 'alice_event_conflict_builder.dart';
import 'alice_event_tile_view_model_builder.dart';
import 'effective_school_day_timing_reader.dart';

class AliceSchoolDayViewModelBuilder {
  final CoreStore coreStore;

  const AliceSchoolDayViewModelBuilder(this.coreStore);

  AliceSchoolDayViewModel build({
    required DateTime day,
    required Set<String> expandedEventIds,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final timing = EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(normalizedDay);
    final period = coreStore.aliceEventStore.getEventForDay(normalizedDay);
    final schoolActive = coreStore.schoolStore.hasSchoolOn(normalizedDay);
    final specialCamp = coreStore.summerCampSpecialEventStore.getForDay(
      normalizedDay,
    );
    final events = [
      ...coreStore.aliceSpecialEventStore.eventsForDay(normalizedDay),
    ]..sort((a, b) => _minutes(a.start).compareTo(_minutes(b.start)));
    final engine = AliceEventEngine();
    final eventModels = events
        .map((event) {
          final conflict = const AliceEventConflictBuilder().build(
            event: event,
            allEvents: events,
          );
          final category = _categoryOption(event.category);
          final tile = const AliceEventTileViewModelBuilder().build(
            event: event,
            isConflict: conflict.isConflict,
            isExpanded: expandedEventIds.contains(event.id),
            requiresLogistics: engine.requiresLogistics(event),
            categoryIcon: category.icon,
            categoryLabel: category.label,
          );
          return AliceSchoolEventViewModel(
            event: event,
            tile: tile,
            conflictWith: conflict.conflictWith,
            categoryText: 'Categoria: ${category.label}',
            timeText:
                'Orario: ${fmtTimeOfDay(event.start)}–${fmtTimeOfDay(event.end)}',
            noteText: event.note.trim().isEmpty ? null : 'Nota: ${event.note}',
          );
        })
        .toList(growable: false);

    final earlyExit = timing.earlySchoolExitAt;
    final entry = period?.summerCampStart ?? timing.schoolEntryAt;
    final displayedEnd = earlyExit ?? timing.schoolExitAt;
    final exit = period?.summerCampEnd ?? timing.schoolExitAt;
    final exitWindowEnd = TimeOfDay(
      hour: ((_minutes(exit) + 20) ~/ 60) % 24,
      minute: (_minutes(exit) + 20) % 60,
    );
    final accompaniment = TimeOfDay(
      hour: ((_minutes(entry) - 20) ~/ 60) % 24,
      minute: (_minutes(entry) - 20) % 60,
    );
    final state = _statePresentation(period?.type);
    final stateLabel = specialCamp != null && specialCamp.enabled
        ? specialCamp.label
        : eventModels.isNotEmpty
        ? eventModels.first.event.label
        : state.label ?? (schoolActive ? 'Scuola' : 'A casa');
    final visible = eventModels
        .take(AliceSchoolDayViewModel.maxVisibleEvents)
        .toList(growable: false);

    return AliceSchoolDayViewModel(
      title: 'Alice / Scuola',
      subtitle: 'Orari scuola + uscita anticipata rapida (con orario).',
      stateLabel: stateLabel,
      stateColor: state.color,
      stateIcon: state.icon,
      periodLabel: period != null && period.type != AliceEventType.schoolNormal
          ? state.label
          : null,
      periodColor: state.color,
      periodIcon: state.periodIcon,
      schoolHoursLabel:
          'Orario: ${fmtTimeOfDay(entry)}–${fmtTimeOfDay(displayedEnd)}',
      hasEarlySchoolExit: earlyExit != null,
      hasEventConflict: eventModels.any((event) => event.tile.isConflict),
      events: eventModels,
      visibleEvents: visible,
      hiddenEventsCount: eventModels.length - visible.length,
      showSummerCampSpecialCard: coreStore.coverageEngine
          .isAliceSummerCampOperationalDay(normalizedDay),
      schoolPeriodLabel:
          coreStore.schoolStore.activePeriodForDay(normalizedDay)?.name ??
          'Nessun periodo attivo',
      isSchoolDayActive: schoolActive,
      schoolWeekdayLabel: const [
        'Lunedì',
        'Martedì',
        'Mercoledì',
        'Giovedì',
        'Venerdì',
        'Sabato',
        'Domenica',
      ][normalizedDay.weekday - 1],
      accompanimentStart: accompaniment,
      schoolEntryAt: entry,
      schoolExitAt: exit,
      schoolExitWindowEnd: exitWindowEnd,
      schoolOutStart: timing.schoolExitAt,
      schoolOutEnd: period?.summerCampEnd ?? timing.schoolPickupWindowEnd,
      hasCustomSchoolOut:
          coreStore.daySettingsStore.schoolOutStartForDay(normalizedDay) !=
              null ||
          coreStore.daySettingsStore.schoolOutEndForDay(normalizedDay) != null,
      categoryOptions: AliceSpecialEventCategory.values
          .map(_categoryOption)
          .toList(growable: false),
    );
  }

  _AliceStatePresentation _statePresentation(AliceEventType? type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return const _AliceStatePresentation(
          label: null,
          color: Colors.grey,
          icon: Icons.menu_book_rounded,
          periodIcon: Icons.info_outline,
        );
      case AliceEventType.vacation:
        return const _AliceStatePresentation(
          label: 'Vacanza',
          color: Colors.teal,
          icon: Icons.beach_access_outlined,
          periodIcon: Icons.beach_access_outlined,
        );
      case AliceEventType.schoolClosure:
        return const _AliceStatePresentation(
          label: 'Scuola chiusa',
          color: Colors.orange,
          icon: Icons.event_busy_outlined,
          periodIcon: Icons.event_busy_outlined,
        );
      case AliceEventType.sickness:
        return const _AliceStatePresentation(
          label: 'Malattia',
          color: Colors.red,
          icon: Icons.sick_outlined,
          periodIcon: Icons.sick_outlined,
        );
      case AliceEventType.summerCamp:
        return const _AliceStatePresentation(
          label: 'Centro estivo',
          color: Colors.green,
          icon: Icons.park_outlined,
          periodIcon: Icons.park_outlined,
        );
      case null:
        return const _AliceStatePresentation(
          label: null,
          color: Colors.grey,
          icon: Icons.school_outlined,
          periodIcon: Icons.info_outline,
        );
    }
  }

  AliceSchoolCategoryOptionViewModel _categoryOption(
    AliceSpecialEventCategory category,
  ) {
    switch (category) {
      case AliceSpecialEventCategory.school:
        return const AliceSchoolCategoryOptionViewModel(
          value: AliceSpecialEventCategory.school,
          label: 'Scuola',
          icon: Icons.school_outlined,
        );
      case AliceSpecialEventCategory.sport:
        return const AliceSchoolCategoryOptionViewModel(
          value: AliceSpecialEventCategory.sport,
          label: 'Sport',
          icon: Icons.sports_volleyball_outlined,
        );
      case AliceSpecialEventCategory.health:
        return const AliceSchoolCategoryOptionViewModel(
          value: AliceSpecialEventCategory.health,
          label: 'Salute',
          icon: Icons.medical_information_outlined,
        );
      case AliceSpecialEventCategory.activity:
        return const AliceSchoolCategoryOptionViewModel(
          value: AliceSpecialEventCategory.activity,
          label: 'Attività',
          icon: Icons.event_outlined,
        );
      case AliceSpecialEventCategory.other:
        return const AliceSchoolCategoryOptionViewModel(
          value: AliceSpecialEventCategory.other,
          label: 'Altro',
          icon: Icons.label_outline,
        );
    }
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
}

class _AliceStatePresentation {
  final String? label;
  final Color color;
  final IconData icon;
  final IconData periodIcon;

  const _AliceStatePresentation({
    required this.label,
    required this.color,
    required this.icon,
    required this.periodIcon,
  });
}
