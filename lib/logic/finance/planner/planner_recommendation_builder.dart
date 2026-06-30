import '../../../models/frodo_observation.dart';
import 'planner_decision.dart';

class PlannerRecommendationBuilder {
  static List<FrodoObservationRecommendation> build({
    required List<PlannerDecision> decisions,
  }) {
    final recommendations = <FrodoObservationRecommendation>[];

    final blocked = decisions.where((d) => d.isBlocked).toList();
    final payNow = decisions
        .where((d) => d.type == PlannerDecisionType.payNow)
        .toList();
    final delay = decisions
        .where((d) => d.type == PlannerDecisionType.delay)
        .toList();
    final income = decisions
        .where((d) => d.type == PlannerDecisionType.waitIncome)
        .toList();
    final monitor = decisions
        .where((d) => d.type == PlannerDecisionType.monitor)
        .toList();

    if (blocked.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Non spostare ${_names(blocked)}',
          description: _description(
            fallback: 'Sono RID, addebiti automatici o spese non manovrabili.',
            decisions: blocked,
          ),
          priority: 110,
        ),
      );
    }

    if (payNow.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Dai priorità a ${_names(payNow)}',
          description: _description(
            fallback: 'Sono spese critiche, obbligatorie o con priorità alta.',
            decisions: payNow,
          ),
          priority: 100,
        ),
      );
    }

    if (income.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Aspetta ${_names(income)}',
          description: _description(
            fallback: 'Le entrate imminenti possono evitare l’uso dei fondi.',
            decisions: income,
          ),
          priority: 95,
        ),
      );
    }

    if (delay.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Puoi rimandare ${_names(delay)}',
          description: _description(
            fallback:
                'Sono spese flessibili: possono aiutare a recuperare margine.',
            decisions: delay,
          ),
          priority: 90,
        ),
      );
    }

    if (monitor.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Monitora ${_names(monitor)}',
          description: _description(
            fallback: 'Sono voci che richiedono attenzione prima di decidere.',
            decisions: monitor,
          ),
          priority: 85,
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const FrodoObservationRecommendation(
          title: 'Mantieni il piano attuale',
          description:
              'Non emergono azioni correttive immediate dalle regole attive.',
          priority: 80,
        ),
      );
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations;
  }

  static String _description({
    required String fallback,
    required List<PlannerDecision> decisions,
  }) {
    final traceMessages = decisions
        .expand((decision) => decision.decisionTrace)
        .where(
          (trace) =>
              trace.level == PlannerDecisionTraceLevel.warning ||
              trace.level == PlannerDecisionTraceLevel.critical,
        )
        .map((trace) => trace.message)
        .toSet()
        .take(3)
        .toList();

    if (traceMessages.isEmpty) {
      return fallback;
    }

    return traceMessages.join(' ');
  }

  static String _names(List<PlannerDecision> decisions) {
    final names = decisions
        .take(3)
        .map((decision) => decision.item.name)
        .toList();

    final remaining = decisions.length - names.length;

    if (remaining > 0) {
      return '${names.join(', ')} +$remaining';
    }

    return names.join(', ');
  }
}
