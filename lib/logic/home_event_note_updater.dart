import '../models/home_event_view_model.dart';
import 'alice_special_event_store.dart';
import 'real_event_store.dart';

class HomeEventNoteUpdater {
  final RealEventStore realEventStore;
  final AliceSpecialEventStore aliceSpecialEventStore;

  const HomeEventNoteUpdater({
    required this.realEventStore,
    required this.aliceSpecialEventStore,
  });

  bool update(HomeEventViewModel event, String description) {
    if (!event.isEditable) return false;

    switch (event.source) {
      case HomeEventSource.realEvent:
        final record = event.realEventRecord;
        if (record == null || record.id != event.id) return false;
        realEventStore.updateEventNotes(id: record.id, notes: description);
        return true;
      case HomeEventSource.aliceSpecialEvent:
        final record = event.aliceSpecialEventRecord;
        if (record == null || record.id != event.id) return false;

        final events = aliceSpecialEventStore.eventsForDay(event.day);
        var found = false;
        final updated = events.map((candidate) {
          if (candidate.id != record.id) return candidate;
          found = true;
          return candidate.copyWith(note: description);
        }).toList();

        if (!found) return false;
        aliceSpecialEventStore.replaceEventsForDay(event.day, updated);
        return true;
    }
  }
}
