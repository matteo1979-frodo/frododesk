// lib/logic/alice_events/alice_event_behavior.dart

enum AliceEventBehavior {
  passive,
  logistic,
  accompanied,
  futureAutonomous,
}

extension AliceEventBehaviorX on AliceEventBehavior {
  bool get isLogistic => this == AliceEventBehavior.logistic;
  bool get isPassive => this == AliceEventBehavior.passive;
  bool get isAccompanied => this == AliceEventBehavior.accompanied;
  bool get isFutureAutonomous =>
      this == AliceEventBehavior.futureAutonomous;
}