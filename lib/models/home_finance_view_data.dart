import 'finance_module_presentation.dart';
import 'finance_pressure_presentation.dart';

class HomeFinanceViewData {
  final FinancePressurePresentation pressurePresentation;
  final FinanceModulePresentation modulePresentation;

  const HomeFinanceViewData({
    required this.pressurePresentation,
    required this.modulePresentation,
  });
}
