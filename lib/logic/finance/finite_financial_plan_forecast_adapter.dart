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
      plan.remainingSchedule.map((installment) => _toItem(plan, installment)),
    );
  }

  List<FiniteFinancialPlanForecastItem> itemsInRange({
    required FiniteFinancialPlan plan,
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }

    final monthOffset =
        (start.year - plan.firstInstallmentDate.year) * 12 +
        start.month -
        plan.firstInstallmentDate.month;
    var number = monthOffset + 1;
    if (number < 1) number = 1;
    final firstRemaining = plan.completedInstallments + 1;
    if (number < firstRemaining) number = firstRemaining;

    final result = <FiniteFinancialPlanForecastItem>[];
    while (number <= plan.totalInstallments) {
      final installment = plan.installment(number)!;
      if (installment.dueDate.isBefore(start)) {
        number++;
        continue;
      }
      if (installment.dueDate.isAfter(end)) break;
      result.add(_toItem(plan, installment));
      number++;
    }
    return List.unmodifiable(result);
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

  FiniteFinancialPlanForecastItem _toItem(
    FiniteFinancialPlan plan,
    FiniteFinancialPlanInstallment installment,
  ) => FiniteFinancialPlanForecastItem(
    planId: plan.id,
    installmentNumber: installment.number,
    date: installment.dueDate,
    expectedAmount: installment.expectedAmount,
    name: plan.name,
    description: plan.description,
    subject: plan.subject,
    debitBalanceId: plan.debitBalanceId,
  );
}
