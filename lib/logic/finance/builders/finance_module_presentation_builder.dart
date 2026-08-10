import '../../../models/finance_module_presentation.dart';
import '../../../models/home_finance_snapshot.dart';

class FinanceModulePresentationBuilder {
  const FinanceModulePresentationBuilder();

  FinanceModulePresentation build(HomeFinanceSnapshot snapshot) {
    return FinanceModulePresentation(
      subtitle:
          'Saldo €${snapshot.totalBalance.toStringAsFixed(0)} • '
          'Margine €${snapshot.projectedMonthlyMargin.toStringAsFixed(0)}',
      badgeText: snapshot.underPressure ? 'Pressione' : 'Stabile',
      state: snapshot.underPressure
          ? FinanceModuleState.pressure
          : FinanceModuleState.stable,
    );
  }
}
