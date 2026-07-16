import 'package:flutter/material.dart';

import '../../../models/day_override.dart';
import '../../../models/real_event.dart';
import '../../turn_engine.dart';
import '../models/date_range.dart';
import '../models/turn_event_conflict.dart';

class TurnEventConflictBuilder {
  const TurnEventConflictBuilder();

  List<TurnEventConflictResolution> build({
    required String personKey,
    required DateTime day,
    required TurnPlan turnPlan,
    required String turnSummary,
    required PersonDayOverride? manualOverride,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required List<RealEvent> events,
  }) {
    final normalizedDay = _onlyDate(day);

    final personEvents =
        events.where((event) => event.involvesPerson(personKey)).toList()
          ..sort(_compareEventsByStartTime);

    if (personEvents.isEmpty) {
      return const [];
    }

    /*
     * Malattia a letto:
     * ogni evento della persona è incompatibile con lo stato bloccante,
     * anche quando non esiste un turno di lavoro.
     */
    if (isBedSick) {
      return _buildBedSickConflicts(events: personEvents, day: normalizedDay);
    }

    /*
     * La malattia leggera non produce conflitto turno/evento.
     * Mantiene la stessa regola usata attualmente dal calendario.
     */
    if (isSick || turnPlan.isOff) {
      return const [];
    }

    final turnRange = DateRange(
      start: _atDayTime(normalizedDay, turnPlan.start),
      end: _atDayTime(normalizedDay, turnPlan.end),
    );

    final permissionRange = _permissionRangeFromOverride(
      manualOverride,
      normalizedDay,
    );

    final resolutions = <TurnEventConflictResolution>[];

    for (final event in personEvents) {
      final eventRange = _eventRangeForConflict(event, normalizedDay);

      if (eventRange == null) {
        continue;
      }

      final overlap = _rangeOverlap(turnRange, eventRange);

      if (overlap == null) {
        continue;
      }

      if (isOnHoliday) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.resolved,
            overlapRange: overlap,
            detailText: _resolvedByHolidayDetail(
              turnSummary: turnSummary,
              overlap: overlap,
            ),
          ),
        );

        continue;
      }

      if (permissionRange == null) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.open,
            overlapRange: overlap,
            detailText: _openConflictDetail(
              turnSummary: turnSummary,
              overlap: overlap,
            ),
          ),
        );

        continue;
      }

      final covered = _rangeOverlap(overlap, permissionRange);

      if (covered == null) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.open,
            overlapRange: overlap,
            detailText: _openConflictDetail(
              turnSummary: turnSummary,
              overlap: overlap,
            ),
          ),
        );

        continue;
      }

      final fullyCovered =
          covered.start.isAtSameMomentAs(overlap.start) &&
          covered.end.isAtSameMomentAs(overlap.end);

      if (fullyCovered) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.resolved,
            overlapRange: overlap,
            detailText: _resolvedByPermissionDetail(
              turnSummary: turnSummary,
              overlap: overlap,
              covered: covered,
            ),
          ),
        );

        continue;
      }

      final uncoveredParts = <String>[];

      if (covered.start.isAfter(overlap.start)) {
        uncoveredParts.add(
          _rangeLabel(DateRange(start: overlap.start, end: covered.start)),
        );
      }

      if (covered.end.isBefore(overlap.end)) {
        uncoveredParts.add(
          _rangeLabel(DateRange(start: covered.end, end: overlap.end)),
        );
      }

      resolutions.add(
        TurnEventConflictResolution(
          event: event,
          state: TurnEventConflictState.partial,
          overlapRange: overlap,
          detailText: _partialConflictDetail(
            turnSummary: turnSummary,
            overlap: overlap,
            covered: covered,
            uncoveredParts: uncoveredParts,
          ),
        ),
      );
    }

    return resolutions;
  }

  List<TurnEventConflictResolution> _buildBedSickConflicts({
    required List<RealEvent> events,
    required DateTime day,
  }) {
    final resolutions = <TurnEventConflictResolution>[];

    for (final event in events) {
      final eventRange = _eventRangeForConflict(event, day);

      if (eventRange == null) {
        continue;
      }

      resolutions.add(
        TurnEventConflictResolution(
          event: event,
          state: TurnEventConflictState.open,
          overlapRange: eventRange,
          detailText: _blockingStateConflictDetail(overlap: eventRange),
          hasTurnContext: false,
        ),
      );
    }

    return resolutions;
  }

  DateRange? _permissionRangeFromOverride(
    PersonDayOverride? manualOverride,
    DateTime day,
  ) {
    if (manualOverride == null) {
      return null;
    }

    if (manualOverride.status != OverrideStatus.permesso) {
      return null;
    }

    final dynamic permission = manualOverride.permessoRange;

    if (permission == null) {
      return null;
    }

    final parsedFromDisplay = _permissionRangeFromDisplayString(
      permission,
      day,
    );

    if (parsedFromDisplay != null) {
      return parsedFromDisplay;
    }

    TimeOfDay? start;
    TimeOfDay? end;

    if (permission is Map) {
      final dynamic startValue =
          permission['start'] ?? permission['from'] ?? permission['startTime'];

      final dynamic endValue =
          permission['end'] ?? permission['to'] ?? permission['endTime'];

      if (startValue is TimeOfDay && endValue is TimeOfDay) {
        start = startValue;
        end = endValue;
      }
    } else {
      final directRange = _readDynamicTimeRange(permission);

      start = directRange?.start;
      end = directRange?.end;
    }

    if (start == null || end == null) {
      return null;
    }

    final startDateTime = _atDayTime(day, start);
    final endDateTime = _atDayTime(day, end);

    if (!endDateTime.isAfter(startDateTime)) {
      return null;
    }

    return DateRange(start: startDateTime, end: endDateTime);
  }

  _PermissionTimeRange? _readDynamicTimeRange(dynamic permission) {
    try {
      final dynamic start = permission.start;
      final dynamic end = permission.end;

      if (start is TimeOfDay && end is TimeOfDay) {
        return _PermissionTimeRange(start: start, end: end);
      }
    } catch (_) {}

    try {
      final dynamic start = permission.from;
      final dynamic end = permission.to;

      if (start is TimeOfDay && end is TimeOfDay) {
        return _PermissionTimeRange(start: start, end: end);
      }
    } catch (_) {}

    try {
      final dynamic start = permission.startTime;
      final dynamic end = permission.endTime;

      if (start is TimeOfDay && end is TimeOfDay) {
        return _PermissionTimeRange(start: start, end: end);
      }
    } catch (_) {}

    return null;
  }

  DateRange? _permissionRangeFromDisplayString(
    dynamic permission,
    DateTime day,
  ) {
    try {
      final dynamic displayValue = permission.toDisplayString();

      if (displayValue is! String) {
        return null;
      }

      final parts = displayValue.split(RegExp(r'[–-]'));

      if (parts.length != 2) {
        return null;
      }

      final start = _parseTimeOfDay(parts[0].trim());

      final end = _parseTimeOfDay(parts[1].trim());

      if (start == null || end == null) {
        return null;
      }

      final startDateTime = _atDayTime(day, start);
      final endDateTime = _atDayTime(day, end);

      if (!endDateTime.isAfter(startDateTime)) {
        return null;
      }

      return DateRange(start: startDateTime, end: endDateTime);
    } catch (_) {
      return null;
    }
  }

  DateRange? _eventRangeForConflict(RealEvent event, DateTime day) {
    if (event.startTime == null && event.endTime == null) {
      return DateRange(
        start: DateTime(day.year, day.month, day.day, 0, 0),
        end: DateTime(day.year, day.month, day.day, 23, 59),
      );
    }

    if (event.startTime != null && event.endTime != null) {
      final start = _atDayTime(day, event.startTime!);

      final end = _atDayTime(day, event.endTime!);

      if (!end.isAfter(start)) {
        return null;
      }

      return DateRange(start: start, end: end);
    }

    if (event.startTime != null) {
      final start = _atDayTime(day, event.startTime!);

      return DateRange(
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
    }

    final end = _atDayTime(day, event.endTime!);

    return DateRange(start: end.subtract(const Duration(minutes: 1)), end: end);
  }

  DateRange? _rangeOverlap(DateRange first, DateRange second) {
    final start = first.start.isAfter(second.start)
        ? first.start
        : second.start;

    final end = first.end.isBefore(second.end) ? first.end : second.end;

    if (!end.isAfter(start)) {
      return null;
    }

    return DateRange(start: start, end: end);
  }

  TimeOfDay? _parseTimeOfDay(String text) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);

    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _atDayTime(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  DateTime _onlyDate(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  int _compareEventsByStartTime(RealEvent first, RealEvent second) {
    final firstMinutes = first.startTime == null
        ? 9999
        : first.startTime!.hour * 60 + first.startTime!.minute;

    final secondMinutes = second.startTime == null
        ? 9999
        : second.startTime!.hour * 60 + second.startTime!.minute;

    return firstMinutes.compareTo(secondMinutes);
  }

  String _blockingStateConflictDetail({required DateRange overlap}) {
    return "Evento incompatibile con stato reale bloccante.\n"
        "Stato reale: malattia a letto\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}";
  }

  String _openConflictDetail({
    required String turnSummary,
    required DateRange overlap,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: $turnSummary\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}";
  }

  String _partialConflictDetail({
    required String turnSummary,
    required DateRange overlap,
    required DateRange covered,
    required List<String> uncoveredParts,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: $turnSummary\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Permesso copre: ${_rangeLabel(covered)}\n"
        "Resta scoperto: ${uncoveredParts.join(" + ")}";
  }

  String _resolvedByPermissionDetail({
    required String turnSummary,
    required DateRange overlap,
    required DateRange covered,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: $turnSummary\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Causa risoluzione: permesso ${_rangeLabel(covered)}";
  }

  String _resolvedByHolidayDetail({
    required String turnSummary,
    required DateRange overlap,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: $turnSummary\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Causa risoluzione: ferie";
  }

  String _rangeLabel(DateRange range) {
    return "${_formatDateTime(range.start)}-${_formatDateTime(range.end)}";
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _PermissionTimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const _PermissionTimeRange({required this.start, required this.end});
}
