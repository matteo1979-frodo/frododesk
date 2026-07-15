import '../models/alice_day_context.dart';
import '../view_models/alice_now_details_view_model.dart';
import '../view_models/alice_now_event_view_model.dart';
import '../../../utils/status_visual.dart';

class AliceNowDetailsBuilder {
  const AliceNowDetailsBuilder();

  AliceNowDetailsViewModel build({
    required AliceDayContext context,
    required DateTime day,
    required DateTime now,
    required String nowLabel,
    required StatusVisual visual,
  }) {
    DateTime toDateTime(AliceNowEventViewModel event, {required bool useEnd}) {
      final time = useEnd ? event.end : event.start;

      if (time == null) {
        return DateTime(
          day.year,
          day.month,
          day.day,
          useEnd ? 23 : 0,
          useEnd ? 59 : 0,
        );
      }

      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }

    final pastEvents = context.events.where((event) {
      final end = toDateTime(event, useEnd: true);

      return now.isAfter(end);
    }).toList();

    final currentEvents = context.events.where((event) {
      final start = toDateTime(event, useEnd: false);

      final end = toDateTime(event, useEnd: true);

      return now.isAfter(start) && now.isBefore(end);
    }).toList();

    final futureEvents = context.events.where((event) {
      final start = toDateTime(event, useEnd: false);

      return now.isBefore(start);
    }).toList();

    return AliceNowDetailsViewModel(
      nowLabel: nowLabel,
      dayStateLabel: context.dayStateLabel,
      visual: visual,
      pastEvents: pastEvents,
      currentEvents: currentEvents,
      futureEvents: futureEvents,
    );
  }
}
