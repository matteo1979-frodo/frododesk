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

  bool isFutureAutonomous(AliceSpecialEvent event) {
    return event.behavior.isFutureAutonomous;
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
