import '../../../models/alice_special_event.dart';
import '../../alice_events/alice_event_engine.dart';

class AliceEventLogisticsResult {
  final bool sameAdult;
  final bool missingDropOff;
  final bool missingPickUp;

  final bool usesMatteo;
  final bool usesChiara;

  final bool matteoBusy;
  final bool chiaraBusy;

  final bool canSuggestSupport;

  final bool singleAdultManagesEvent;
  final bool splitLogistics;

  final bool dropOffConflict;
  final bool pickUpConflict;

  const AliceEventLogisticsResult({
    required this.sameAdult,
    required this.missingDropOff,
    required this.missingPickUp,
    required this.usesMatteo,
    required this.usesChiara,
    required this.matteoBusy,
    required this.chiaraBusy,
    required this.canSuggestSupport,
    required this.singleAdultManagesEvent,
    required this.splitLogistics,
    required this.dropOffConflict,
    required this.pickUpConflict,
  });
}

class AliceEventLogisticsBuilder {
  const AliceEventLogisticsBuilder();

  AliceEventLogisticsResult build({
    required DateTime day,
    required AliceSpecialEvent event,
    required AliceEventEngine aliceEventEngine,
    required bool Function(DateTime start, DateTime end) isMatteoBusy,
    required bool Function(DateTime start, DateTime end) isChiaraBusy,
    required bool hasEnabledSupport,
  }) {
    final sameAdult =
        aliceEventEngine.hasSameAdultForDropOffAndPickUp(event);

    final missingDropOff =
        !aliceEventEngine.hasDropOffAssigned(event);

    final missingPickUp =
        !aliceEventEngine.hasPickUpAssigned(event);

    final usesMatteo = aliceEventEngine.usesMatteo(event);
    final usesChiara = aliceEventEngine.usesChiara(event);

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

    final dropOffEnd = eventStart.add(
      const Duration(minutes: 20),
    );

    final pickUpStart = eventEnd.subtract(
      const Duration(minutes: 20),
    );

    final matteoDropOffBusy =
        event.dropOffAdultKey == 'matteo' &&
        isMatteoBusy(eventStart, dropOffEnd);

    final matteoPickUpBusy =
        event.pickUpAdultKey == 'matteo' &&
        isMatteoBusy(pickUpStart, eventEnd);

    final chiaraDropOffBusy =
        event.dropOffAdultKey == 'chiara' &&
        isChiaraBusy(eventStart, dropOffEnd);

    final chiaraPickUpBusy =
        event.pickUpAdultKey == 'chiara' &&
        isChiaraBusy(pickUpStart, eventEnd);

    final matteoBusy =
        matteoDropOffBusy || matteoPickUpBusy;

    final chiaraBusy =
        chiaraDropOffBusy || chiaraPickUpBusy;

    final canSuggestSupport =
        (matteoBusy || chiaraBusy) &&
        hasEnabledSupport;

    final singleAdultManagesEvent =
        aliceEventEngine.isManagedBySingleAdult(event);

    final splitLogistics =
        aliceEventEngine.hasSplitLogistics(event);

    final dropOffConflict =
        (event.dropOffAdultKey == 'matteo' && matteoBusy) ||
        (event.dropOffAdultKey == 'chiara' && chiaraBusy);

    final pickUpConflict =
        (event.pickUpAdultKey == 'matteo' && matteoBusy) ||
        (event.pickUpAdultKey == 'chiara' && chiaraBusy);

    return AliceEventLogisticsResult(
      sameAdult: sameAdult,
      missingDropOff: missingDropOff,
      missingPickUp: missingPickUp,
      usesMatteo: usesMatteo,
      usesChiara: usesChiara,
      matteoBusy: matteoBusy,
      chiaraBusy: chiaraBusy,
      canSuggestSupport: canSuggestSupport,
      singleAdultManagesEvent: singleAdultManagesEvent,
      splitLogistics: splitLogistics,
      dropOffConflict: dropOffConflict,
      pickUpConflict: pickUpConflict,
    );
  }
}