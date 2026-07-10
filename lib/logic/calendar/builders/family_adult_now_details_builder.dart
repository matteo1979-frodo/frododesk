import '../../../models/real_event.dart';
import '../../../utils/status_visual.dart';
import '../view_models/family_adult_now_details_view_model.dart';

class FamilyAdultNowDetailsBuilder {
  const FamilyAdultNowDetailsBuilder();

  FamilyAdultNowDetailsViewModel build({
    required String name,
    required String personKey,
    required DateTime day,
    required DateTime now,
    required String nowLabel,
    required String turnLabel,
    required StatusVisual visual,
    required List<RealEvent> events,
  }) {
    final personEvents = events
        .where((event) => event.involvesPerson(personKey))
        .toList();

    final pastEvents = personEvents.where((event) {
      if (event.endTime == null) return false;

      final eventEnd = DateTime(
        day.year,
        day.month,
        day.day,
        event.endTime!.hour,
        event.endTime!.minute,
      );

      return now.isAfter(eventEnd);
    }).toList();

    final currentEvents = personEvents.where((event) {
      if (event.startTime == null || event.endTime == null) {
        return false;
      }

      final eventStart = DateTime(
        day.year,
        day.month,
        day.day,
        event.startTime!.hour,
        event.startTime!.minute,
      );

      final eventEnd = DateTime(
        day.year,
        day.month,
        day.day,
        event.endTime!.hour,
        event.endTime!.minute,
      );

      return now.isAfter(eventStart) && now.isBefore(eventEnd);
    }).toList();

    final futureEvents = personEvents.where((event) {
      if (event.startTime == null) return false;

      final eventStart = DateTime(
        day.year,
        day.month,
        day.day,
        event.startTime!.hour,
        event.startTime!.minute,
      );

      return now.isBefore(eventStart);
    }).toList();

    return FamilyAdultNowDetailsViewModel(
      name: name,
      nowLabel: nowLabel,
      turnLabel: turnLabel,
      visual: visual,
      pastEvents: pastEvents,
      currentEvents: currentEvents,
      futureEvents: futureEvents,
    );
  }
}
