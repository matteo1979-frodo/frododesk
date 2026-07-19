import '../../../models/alice_special_event.dart';
import '../../alice_events/alice_event_engine.dart';

class AliceLogisticsStatus {
  final bool hasIncompleteLogistics;
  final bool hasLogisticConflict;

  const AliceLogisticsStatus({
    required this.hasIncompleteLogistics,
    required this.hasLogisticConflict,
  });
}

class AliceLogisticsStatusBuilder {
  const AliceLogisticsStatusBuilder();

  AliceLogisticsStatus build({
    required DateTime day,
    required List<AliceSpecialEvent> logisticEvents,
    required AliceEventEngine aliceEventEngine,
    required bool Function(DateTime start, DateTime end) isMatteoBusy,
    required bool Function(DateTime start, DateTime end) isChiaraBusy,
  }) {
    final hasIncompleteLogistics = logisticEvents.any(
      (event) =>
          !aliceEventEngine.hasDropOffAssigned(event) ||
          !aliceEventEngine.hasPickUpAssigned(event),
    );

    bool isAdultBusyForRange({
      required String? adultKey,
      required DateTime start,
      required DateTime end,
    }) {
      if (adultKey == 'matteo') {
        return isMatteoBusy(start, end);
      }

      if (adultKey == 'chiara') {
        return isChiaraBusy(start, end);
      }

      return false;
    }

    final hasLogisticConflict = logisticEvents.any((event) {
      final eventStart = DateTime(
        day.year,
        day.month,
        day.day,
        event.start.hour,
        event.start.minute,
      );

      final eventEnd = DateTime(
        day.year,
        day.month,
        day.day,
        event.end.hour,
        event.end.minute,
      );

      final dropOffBusy = isAdultBusyForRange(
        adultKey: event.dropOffAdultKey,
        start: eventStart.subtract(const Duration(minutes: 20)),
        end: eventStart,
      );

      final pickUpBusy = isAdultBusyForRange(
        adultKey: event.pickUpAdultKey,
        start: eventEnd,
        end: eventEnd.add(const Duration(minutes: 20)),
      );

      return dropOffBusy || pickUpBusy;
    });

    return AliceLogisticsStatus(
      hasIncompleteLogistics: hasIncompleteLogistics,
      hasLogisticConflict: hasLogisticConflict,
    );
  }
}
