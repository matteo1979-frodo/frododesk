import '../../../models/finance_recurring_item.dart';

enum PlannerDecisionType {
  payNow,
  keepCovered,
  waitIncome,
  delay,
  useFunds,
  blocked,
  monitor,
}

class PlannerDecision {
  final FinanceRecurringItem item;
  final PlannerDecisionType type;
  final String reason;
  final int score;

  const PlannerDecision({
    required this.item,
    required this.type,
    required this.reason,
    required this.score,
  });

  bool get isActionable {
    return type == PlannerDecisionType.payNow ||
        type == PlannerDecisionType.delay ||
        type == PlannerDecisionType.useFunds;
  }

  bool get isBlocked {
    return type == PlannerDecisionType.blocked ||
        type == PlannerDecisionType.keepCovered;
  }
}
