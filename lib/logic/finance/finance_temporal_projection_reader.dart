import '../../models/finance_forecast_presentation.dart';
import '../../models/finance_month_projection.dart';
import '../../models/income_forecast_presentation.dart';

class FinanceTemporalProjectionReader {
  const FinanceTemporalProjectionReader();

  List<FinanceMonthProjection> readYear({
    required int year,
    required IncomeForecastOverview incomes,
    required FinanceForecastOverview expenses,
  }) => List.generate(12, (index) {
    final month = DateTime(year, index + 1);
    final income = incomes.totalForMonth(month);
    final outflow = expenses.economicOutflowForMonth(month);
    final margin = income - outflow;
    final expenseItems = expenses.economicItemsForMonth(month);
    final count = expenseItems.length;
    final pressure = margin < 0 ? outflow * 1.5 : outflow;
    final density = count == 0 ? 0.0 : pressure / count;
    return FinanceMonthProjection(
      month: month,
      expectedIncome: income,
      expectedExpenses: outflow,
      expectedMargin: margin,
      pressureScore: pressure,
      pressureItemCount: count,
      pressureDensity: density,
      saturation: _saturation(margin, density, count),
    );
  });

  FinanceMonthSaturation _saturation(double margin, double density, int count) {
    if (margin < 0 && density > 800) {
      return FinanceMonthSaturation.critical;
    }
    if (margin < 200 && count >= 8) return FinanceMonthSaturation.high;
    if (density > 400 || count >= 5) return FinanceMonthSaturation.medium;
    return FinanceMonthSaturation.low;
  }
}
