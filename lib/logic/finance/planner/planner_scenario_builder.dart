import '../../../models/frodo_observation.dart';
import 'planner_decision.dart';

class PlannerScenarioBuilder {
  static List<FrodoObservationScenario> build({
    required List<PlannerDecision> decisions,
    required double familyForecast,
    double? projectedAfterIncome,
    double? projectedWithFunds,
  }) {
    final steps = decisions
        .take(6)
        .map(_stepForDecision)
        .where((step) => step.trim().isNotEmpty)
        .toList();

    final hasBlocked = decisions.any((d) => d.isBlocked);
    final hasDelayed = decisions.any(
      (d) => d.type == PlannerDecisionType.delay,
    );
    final hasIncome = decisions.any(
      (d) => d.type == PlannerDecisionType.waitIncome,
    );

    final projectedBalance =
        projectedAfterIncome ?? projectedWithFunds ?? familyForecast;

    final level = projectedBalance >= 0
        ? FrodoObservationLevel.success
        : hasBlocked
        ? FrodoObservationLevel.attention
        : FrodoObservationLevel.problem;

    final message = projectedBalance >= 0
        ? 'Questo scenario mantiene il mese sostenibile.'
        : 'Questo scenario richiede attenzione: il saldo resta in pressione.';

    final scenarioSteps = steps.isEmpty
        ? const ['Mantieni monitorata la situazione economica.']
        : steps;

    final scenarios = <FrodoObservationScenario>[
      FrodoObservationScenario(
        title: 'Scenario consigliato',
        message: message,
        projectedBalance: projectedBalance,
        level: level,
        steps: scenarioSteps,
      ),
    ];

    if (hasDelayed || hasIncome) {
      scenarios.add(
        FrodoObservationScenario(
          title: 'Scenario alternativo',
          message:
              'Agire subito su tutto può consumare più margine del necessario.',
          projectedBalance: familyForecast,
          level: familyForecast >= 0
              ? FrodoObservationLevel.attention
              : FrodoObservationLevel.problem,
          steps: const [
            'Pagare tutto subito può ridurre il margine disponibile.',
            'Conviene distinguere tra spese bloccate e spese manovrabili.',
          ],
        ),
      );
    }

    return scenarios;
  }

  static String _stepForDecision(PlannerDecision decision) {
    final item = decision.item;

    switch (decision.type) {
      case PlannerDecisionType.keepCovered:
        return 'Tieni coperto ${item.name}: ${decision.reason}';
      case PlannerDecisionType.payNow:
        return 'Dai priorità a ${item.name}: ${decision.reason}';
      case PlannerDecisionType.waitIncome:
        return 'Attendi ${item.name}: ${decision.reason}';
      case PlannerDecisionType.delay:
        return 'Puoi rimandare ${item.name}: ${decision.reason}';
      case PlannerDecisionType.useFunds:
        return 'Valuta fondi per ${item.name}: ${decision.reason}';
      case PlannerDecisionType.blocked:
        return 'Non modificare ${item.name}: ${decision.reason}';
      case PlannerDecisionType.monitor:
        return 'Monitora ${item.name}: ${decision.reason}';
    }
  }
}
