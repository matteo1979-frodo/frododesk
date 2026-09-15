import '../../models/finance_recurring_item.dart';
import '../../models/finite_financial_plan.dart';

/// Projection-only representation of an expected finite-plan payment.
///
/// A forecast item is not an economic fact and does not mutate or persist
/// financial state.
class FiniteFinancialPlanForecastItem {
  final String planId;
  final int installmentNumber;
  final DateTime date;
  final double expectedAmount;
  final String name;
  final String description;
  final FinanceSubject subject;
  final String? debitBalanceId;

  const FiniteFinancialPlanForecastItem({
    required this.planId,
    required this.installmentNumber,
    required this.date,
    required this.expectedAmount,
    required this.name,
    required this.description,
    required this.subject,
    required this.debitBalanceId,
  });

  String get identity => '$planId#$installmentNumber';

  bool get isOutflow => true;
}

class FiniteFinancialPlanForecastAdapter {
  const FiniteFinancialPlanForecastAdapter();

  List<FiniteFinancialPlanForecastItem> remainingItems(
    FiniteFinancialPlan plan,
  ) {
    return List.unmodifiable(
      plan.remainingSchedule.map((installment) {
        return FiniteFinancialPlanForecastItem(
          planId: plan.id,
          installmentNumber: installment.number,
          date: installment.dueDate,
          expectedAmount: installment.expectedAmount,
          name: plan.name,
          description: plan.description,
          subject: plan.subject,
          debitBalanceId: plan.debitBalanceId,
        );
      }),
    );
  }

  List<FiniteFinancialPlanForecastItem> itemsForMonth(
    FiniteFinancialPlan plan,
    DateTime month,
  ) {
    return List.unmodifiable(
      remainingItems(plan).where(
        (item) => item.date.year == month.year && item.date.month == month.month,
      ),
    );
  }
}
