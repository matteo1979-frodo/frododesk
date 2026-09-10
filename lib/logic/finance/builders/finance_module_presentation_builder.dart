import '../../../models/finance_module_presentation.dart';
import '../../../models/home_finance_snapshot.dart';
import '../../../utils/euro_formatter.dart';

class FinanceModulePresentationBuilder {
  const FinanceModulePresentationBuilder();

  FinanceModulePresentation build(HomeFinanceSnapshot snapshot) {
    return FinanceModulePresentation(
      subtitle:
          'Saldo ${EuroFormatter.format(snapshot.totalBalance)} • '
          'Margine ${EuroFormatter.format(snapshot.projectedMonthlyMargin)}',
      badgeText: snapshot.underPressure ? 'Pressione' : 'Stabile',
      state: snapshot.underPressure
          ? FinanceModuleState.pressure
          : FinanceModuleState.stable,
    );
  }
}
