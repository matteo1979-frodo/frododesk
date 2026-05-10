// lib/logic/alice_events/alice_event_engine.dart

import '../../models/alice_special_event.dart';
import '../alice_companion_store.dart';
import 'alice_event_behavior.dart';

class AliceEventEngine {
  const AliceEventEngine();

  AliceEventBehavior defaultBehaviorForCategory(
    AliceSpecialEventCategory category,
  ) {
    switch (category) {
      case AliceSpecialEventCategory.school:
        return AliceEventBehavior.logistic;

      case AliceSpecialEventCategory.sport:
        return AliceEventBehavior.logistic;

      case AliceSpecialEventCategory.health:
        return AliceEventBehavior.logistic;

      case AliceSpecialEventCategory.activity:
        return AliceEventBehavior.passive;

      case AliceSpecialEventCategory.other:
        return AliceEventBehavior.passive;
    }
  }

  AliceCompanionPerson? companionPersonForEvent(AliceSpecialEvent event) {
    if (!event.behavior.isAccompanied) return null;

    switch (event.accompanyingAdultKey) {
      case 'matteo':
        return AliceCompanionPerson.matteo;

      case 'chiara':
        return AliceCompanionPerson.chiara;

      default:
        return null;
    }
  }

  bool requiresLogistics(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
  }

  bool requiresAccompaniment(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
  }

  bool requiresPickup(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
  }

  /// 👇 NUOVO
  /// Adulto che accompagna Alice all'evento logistico.
  String? dropOffAdultKey(AliceSpecialEvent event) {
    if (!event.behavior.isLogistic) return null;

    return event.dropOffAdultKey;
  }

  /// 👇 NUOVO
  /// Adulto che ritira Alice dall'evento logistico.
  String? pickUpAdultKey(AliceSpecialEvent event) {
    if (!event.behavior.isLogistic) return null;

    return event.pickUpAdultKey;
  }

  /// 👇 NUOVO
  /// Evento logistico completamente organizzato.
  bool hasFullLogisticCoverage(AliceSpecialEvent event) {
    if (!event.behavior.isLogistic) return true;

    return event.dropOffAdultKey != null && event.pickUpAdultKey != null;
  }

  bool isAliceOutDuringEvent(AliceSpecialEvent event) {
    return event.behavior.isLogistic ||
        event.behavior.isAccompanied ||
        event.behavior.isFutureAutonomous;
  }

  bool requiresAdultSupervision(AliceSpecialEvent event) {
    return event.behavior.isPassive || event.behavior.isLogistic;
  }

  bool canGenerateCoverageProblem(AliceSpecialEvent event) {
    return requiresAdultSupervision(event) || requiresLogistics(event);
  }

  bool isPassive(AliceSpecialEvent event) {
    return event.behavior.isPassive;
  }

  bool isAccompanied(AliceSpecialEvent event) {
    return event.behavior.isAccompanied;
  }

  bool isManagedBySingleAdult(AliceSpecialEvent event) {
    if (event.dropOffAdultKey == null || event.pickUpAdultKey == null) {
      return false;
    }

    return event.dropOffAdultKey == event.pickUpAdultKey;
  }

  bool hasSplitLogistics(AliceSpecialEvent event) {
    if (event.dropOffAdultKey == null || event.pickUpAdultKey == null) {
      return false;
    }

    return event.dropOffAdultKey != event.pickUpAdultKey;
  }

  bool isFutureAutonomous(AliceSpecialEvent event) {
    return event.behavior.isFutureAutonomous;
  }

  bool hasAssignedAdult(AliceSpecialEvent event) {
    if (!event.behavior.isAccompanied) return false;

    return event.accompanyingAdultKey != null &&
        event.accompanyingAdultKey!.trim().isNotEmpty;
  }

  bool hasDropOffAssigned(AliceSpecialEvent event) {
    return event.dropOffAdultKey != null &&
        event.dropOffAdultKey!.trim().isNotEmpty;
  }

  bool hasPickUpAssigned(AliceSpecialEvent event) {
    return event.pickUpAdultKey != null &&
        event.pickUpAdultKey!.trim().isNotEmpty;
  }

  bool hasSameAdultForDropOffAndPickUp(AliceSpecialEvent event) {
    if (event.dropOffAdultKey == null || event.pickUpAdultKey == null) {
      return false;
    }

    return event.dropOffAdultKey == event.pickUpAdultKey;
  }

  bool usesMatteo(AliceSpecialEvent event) {
    return event.dropOffAdultKey == 'matteo' ||
        event.pickUpAdultKey == 'matteo';
  }

  bool usesChiara(AliceSpecialEvent event) {
    return event.dropOffAdultKey == 'chiara' ||
        event.pickUpAdultKey == 'chiara';
  }

  String realTimeMeaning(AliceSpecialEvent event) {
    switch (event.behavior) {
      case AliceEventBehavior.passive:
        return "Alice è occupata, ma resta nello stesso luogo.";

      case AliceEventBehavior.logistic:
        return "Alice è fuori casa e serve gestione logistica.";

      case AliceEventBehavior.accompanied:
        return "Alice è fuori casa insieme a un adulto.";

      case AliceEventBehavior.futureAutonomous:
        return "Alice è autonoma durante questo evento.";
    }
  }

  String operationalDescription(AliceSpecialEvent event) {
    switch (event.behavior) {
      case AliceEventBehavior.passive:
        return "Non richiede spostamenti.";

      case AliceEventBehavior.logistic:
        return "Richiede accompagnamento e ritiro.";

      case AliceEventBehavior.accompanied:
        return "Alice segue un adulto.";

      case AliceEventBehavior.futureAutonomous:
        return "Evento autonomo futuro.";
    }
  }
}
