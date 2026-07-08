import '../../../models/alice_special_event.dart';

class AliceEventConflictResult {
  final bool isConflict;
  final List<String> conflictWith;

  const AliceEventConflictResult({
    required this.isConflict,
    required this.conflictWith,
  });
}

class AliceEventConflictBuilder {
  const AliceEventConflictBuilder();

  AliceEventConflictResult build({
    required AliceSpecialEvent event,
    required List<AliceSpecialEvent> allEvents,
  }) {
    final conflictWith = <String>[];

    for (final other in allEvents) {
      if (other.id == event.id) continue;

      final overlap =
          event.start.hour * 60 + event.start.minute <
              other.end.hour * 60 + other.end.minute &&
          other.start.hour * 60 + other.start.minute <
              event.end.hour * 60 + event.end.minute;

      if (overlap) {
        conflictWith.add(other.label);
      }
    }

    return AliceEventConflictResult(
      isConflict: conflictWith.isNotEmpty,
      conflictWith: conflictWith,
    );
  }
}
