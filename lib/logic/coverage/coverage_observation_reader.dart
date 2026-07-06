import '../../core/frododesk_modules.dart';
import '../../models/frodo_observation.dart';
import 'coverage_decision.dart';

class CoverageObservationReader {
  static List<FrodoObservation> fromDecisions(
    List<CoverageDecision> decisions,
  ) {
    final now = DateTime.now();

    return decisions.map((decision) {
      return FrodoObservation(
        id: decision.id,
        module: FrodoModules.coverage,
        category: FrodoObservationCategory.coverage,
        title: decision.title,
        message: decision.message,
        details: _detailsFromDecision(decision),
        impact: _impactFromDecision(decision),
        priority: decision.priority,
        level: _levelFromDecision(decision),
        createdAt: now,
        targetDate: decision.targetDate,
      );
    }).toList();
  }

  static String? _detailsFromDecision(CoverageDecision decision) {
    if (decision.decisionTrace.isEmpty) return null;

    return decision.decisionTrace
        .where((trace) => trace.visibleToUser)
        .map((trace) => '• ${trace.message}')
        .join('\n');
  }

  static String _impactFromDecision(CoverageDecision decision) {
    switch (decision.type) {
      case CoverageDecisionType.aliceUncovered:
        return 'Serve verificare chi può coprire Alice o se attivare un supporto.';

      case CoverageDecisionType.sandraSuggested:
        return 'Sandra può essere una soluzione utile per coprire la fascia scoperta.';

      case CoverageDecisionType.supportAvailable:
        return 'La rete di supporto può aiutare a risolvere la copertura.';

      case CoverageDecisionType.noIssue:
        return 'Non emergono criticità immediate sulla copertura.';

      case CoverageDecisionType.monitor:
        return 'Situazione da tenere sotto controllo.';
    }
  }

  static FrodoObservationLevel _levelFromDecision(CoverageDecision decision) {
    switch (decision.level) {
      case CoverageDecisionLevel.problem:
        return FrodoObservationLevel.problem;

      case CoverageDecisionLevel.attention:
        return FrodoObservationLevel.attention;

      case CoverageDecisionLevel.opportunity:
        return FrodoObservationLevel.opportunity;

      case CoverageDecisionLevel.success:
        return FrodoObservationLevel.success;

      case CoverageDecisionLevel.info:
        return FrodoObservationLevel.info;
    }
  }
}
