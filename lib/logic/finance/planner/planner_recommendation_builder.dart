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

    if (blocked.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Non spostare ${_names(blocked)}',
          description: 'Sono RID, addebiti automatici o spese non manovrabili.',
          priority: 110,
        ),
      );
    }

    if (payNow.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Dai priorità a ${_names(payNow)}',
          description: 'Sono spese critiche, obbligatorie o con priorità alta.',
          priority: 100,
        ),
      );
    }

    if (income.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Aspetta ${_names(income)}',
          description: 'Le entrate imminenti possono evitare l’uso dei fondi.',
          priority: 95,
        ),
      );
    }

    if (delay.isNotEmpty) {
      recommendations.add(
        FrodoObservationRecommendation(
          title: 'Puoi rimandare ${_names(delay)}',
          description:
              'Sono spese flessibili: possono aiutare a recuperare margine.',
          priority: 90,
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
