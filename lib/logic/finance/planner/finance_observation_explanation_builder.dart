import '../../../models/frodo_observation.dart';
import 'planner_decision.dart';

class FinanceObservationExplanationBuilder {
  static List<FrodoObservationExplanation> build({
    required List<PlannerDecision> decisions,
  }) {
    final traces = decisions
        .expand((decision) => decision.decisionTrace)
        .where((trace) => trace.visibleToUser)
        .toList();

    final explanations = <FrodoObservationExplanation>[];
    final seenReasonKeys = <String>{};

    final orderedReasons = <PlannerDecisionReason>[
      PlannerDecisionReason.automaticPayment,
      PlannerDecisionReason.criticalExpense,
      PlannerDecisionReason.protectedExpense,
      PlannerDecisionReason.minimumBalance,
      PlannerDecisionReason.ownerUnderPressure,
      PlannerDecisionReason.incomeForecast,
      PlannerDecisionReason.delayAllowed,
      PlannerDecisionReason.usableFunds,
      PlannerDecisionReason.protectedFunds,
      PlannerDecisionReason.sharedPayment,
      PlannerDecisionReason.familyPriority,
      PlannerDecisionReason.personalPriority,
      PlannerDecisionReason.suggestedAccount,
      PlannerDecisionReason.thirteenthSalary,
      PlannerDecisionReason.fourteenthSalary,
      PlannerDecisionReason.productionBonus,
      PlannerDecisionReason.extraordinaryIncome,
      PlannerDecisionReason.opportunity,
      PlannerDecisionReason.generic,
    ];

    for (final reason in orderedReasons) {
      final matching = traces.where((trace) => trace.reason == reason).toList();

      if (matching.isEmpty) {
        continue;
      }

      final strongest = matching.reduce((a, b) {
        return _traceWeight(a.level) >= _traceWeight(b.level) ? a : b;
      });

      if (seenReasonKeys.contains(reason.name)) {
        continue;
      }

      seenReasonKeys.add(reason.name);

      final metadata = reason.metadata;

      explanations.add(
        FrodoObservationExplanation(
          reasonKey: reason.name,
          level: _mapLevel(strongest.level),
          message: '${metadata.icon} ${metadata.title}\n${strongest.message}',
        ),
      );
    }

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

  static int _traceWeight(PlannerDecisionTraceLevel level) {
    switch (level) {
      case PlannerDecisionTraceLevel.critical:
        return 4;
      case PlannerDecisionTraceLevel.warning:
        return 3;
      case PlannerDecisionTraceLevel.positive:
        return 2;
      case PlannerDecisionTraceLevel.neutral:
        return 1;
    }
  }
}
