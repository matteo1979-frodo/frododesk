// lib/logic/alice_events/alice_event_engine.dart

import '../../models/alice_special_event.dart';
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

  bool requiresLogistics(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
  }

  bool requiresAccompaniment(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
  }

  bool requiresPickup(AliceSpecialEvent event) {
    return event.behavior.isLogistic;
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
}