import '../../models/finite_financial_plan.dart';
import 'finite_financial_plan_forecast_adapter.dart';

class FiniteFinancialPlanForecastReader {
  final FiniteFinancialPlanForecastAdapter adapter;

  const FiniteFinancialPlanForecastReader({
    this.adapter = const FiniteFinancialPlanForecastAdapter(),
  });

  double projectedOutflowForMonth(
    Iterable<FiniteFinancialPlan> plans,
    DateTime month,
  ) {
    return plans.fold<double>(
      0,
      (total, plan) =>
          total +
          adapter
              .itemsForMonth(plan, month)
              .fold<double>(0, (sum, item) => sum + item.expectedAmount),
    );
  }
}
