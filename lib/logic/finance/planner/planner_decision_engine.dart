import '../../../models/finance_recurring_item.dart';
import 'planner_decision.dart';

class PlannerDecisionEngine {
  static List<PlannerDecision> analyze({
    required List<FinanceRecurringItem> items,
  }) {
    final decisions = items.map(_analyzeItem).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return decisions;
  }

  static PlannerDecision _analyzeItem(FinanceRecurringItem item) {
    if (item.isIncome) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.waitIncome,
        reason: 'Entrata prevista: va considerata prima di usare fondi.',
        score: 850,
      );
    }

    if (_isAutomaticOrRid(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.keepCovered,
        reason: 'RID/addebito automatico: non va spostato o rimandato.',
        score: 1000,
      );
    }

    if (_isCritical(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.payNow,
        reason: 'Spesa critica o obbligatoria: va messa tra le priorità.',
        score: 900,
      );
    }

    if (_canBeDelayed(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.delay,
        reason: 'Spesa rimandabile: può aiutare a recuperare margine.',
        score: 500,
      );
    }

    return PlannerDecision(
      item: item,
      type: PlannerDecisionType.monitor,
      reason: 'Spesa da monitorare: non ha una regola forte associata.',
      score: 300,
    );
  }

  static bool _isAutomaticOrRid(FinanceRecurringItem item) {
    final method = item.paymentMethod.name.toLowerCase();

    return !item.requiresManualConfirmation ||
        method.contains('rid') ||
        method.contains('automatic') ||
        method.contains('addebito');
  }

  static bool _isCritical(FinanceRecurringItem item) {
    return item.mandatory ||
        item.paymentPriority == FinancePaymentPriority.critical ||
        item.protectionLevel == FinanceProtectionLevel.critical;
  }

  static bool _canBeDelayed(FinanceRecurringItem item) {
    if (_isAutomaticOrRid(item)) return false;
    if (_isCritical(item)) return false;
    if (!item.behaviorProfile.canBeDelayed) return false;

    return true;
  }
}
