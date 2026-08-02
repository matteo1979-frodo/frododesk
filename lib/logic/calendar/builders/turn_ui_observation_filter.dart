import '../../../models/real_event.dart';

class TurnUiObservationFilter {
  const TurnUiObservationFilter();

  List<RealEvent> visibleEvents({
    required List<RealEvent> events,
    required DateTime selectedDay,
    required DateTime observedAt,
  }) {
    if (!_isSameDay(selectedDay, observedAt)) {
      return List.unmodifiable(events);
    }

    return events.where((event) {
      final endTime = event.endTime;
      if (endTime == null) return true;

      final end = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        endTime.hour,
        endTime.minute,
      );

      return end.isAfter(observedAt);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
