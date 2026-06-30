import '../../../models/frodo_observation.dart';
import 'planner_decision.dart';

class FinanceObservationExplanationBuilder {
  static List<FrodoObservationExplanation> build({
    required List<PlannerDecision> decisions,
  }) {
    final explanations = <FrodoObservationExplanation>[];
    final seenKeys = <String>{};

    for (final decision in decisions) {
      for (final trace in decision.decisionTrace.where(
        (trace) => trace.visibleToUser,
      )) {
        final metadata = trace.reason.metadata;
        final key = '${trace.reason.name}_${trace.level.name}_${trace.message}';

        if (seenKeys.contains(key)) {
          continue;
        }

        seenKeys.add(key);

        explanations.add(
          FrodoObservationExplanation(
            reasonKey: trace.reason.name,
            level: _mapLevel(trace.level),
            message: '${metadata.icon} ${metadata.title}\n${trace.message}',
          ),
        );
      }
    }

    explanations.sort((a, b) {
      return _levelWeight(b.level).compareTo(_levelWeight(a.level));
    });

    return explanations;
  }

  static FrodoObservationExplanationLevel _mapLevel(
    PlannerDecisionTraceLevel level,
  ) {
    switch (level) {
      case PlannerDecisionTraceLevel.positive:
        return FrodoObservationExplanationLevel.positive;
      case PlannerDecisionTraceLevel.neutral:
        return FrodoObservationExplanationLevel.neutral;
      case PlannerDecisionTraceLevel.warning:
        return FrodoObservationExplanationLevel.warning;
      case PlannerDecisionTraceLevel.critical:
        return FrodoObservationExplanationLevel.critical;
    }
  }

  static int _levelWeight(FrodoObservationExplanationLevel level) {
    switch (level) {
      case FrodoObservationExplanationLevel.critical:
        return 4;
      case FrodoObservationExplanationLevel.warning:
        return 3;
      case FrodoObservationExplanationLevel.positive:
        return 2;
      case FrodoObservationExplanationLevel.neutral:
        return 1;
    }
  }
}
