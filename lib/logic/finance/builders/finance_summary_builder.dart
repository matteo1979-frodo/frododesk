import '../../../models/home_finance_snapshot.dart';
import '../../../models/home_observed_at.dart';
import '../../../stores/finance_store.dart';

class FinanceSummaryBuilder {
  const FinanceSummaryBuilder();

  HomeFinanceSnapshot build({
    required FinanceStore financeStore,
    required HomeObservedAt observedAt,
  }) {
    return HomeFinanceSnapshot(
      totalBalance: financeStore.totalBalance(),
      projectedMonthlyMargin: financeStore.projectedMonthlyMargin(),
      underPressure: financeStore.isUnderPressure(),
      economicPressureScore: financeStore.economicPressureScore(
        observedAt: observedAt.observedAt,
      ),
    );
  }
}
