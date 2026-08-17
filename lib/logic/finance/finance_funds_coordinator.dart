import '../../models/finance_fund.dart';
import '../../models/finance_funds_view_data.dart';
import '../../stores/finance_store.dart';
import 'builders/finance_funds_view_builder.dart';
import 'finance_fund_lifecycle_coordinator.dart';
import '../../models/finance_asset_movement.dart';

class FinanceFundsCoordinator {
  final FinanceStore financeStore;
  final FinanceFundsViewBuilder viewBuilder;
  final DateTime Function() clock;
  late final FinanceFundLifecycleCoordinator lifecycle =
      FinanceFundLifecycleCoordinator(financeStore: financeStore, clock: clock);

  FinanceFundsCoordinator({
    required this.financeStore,
    this.viewBuilder = const FinanceFundsViewBuilder(),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  FinanceFundsViewData build() => viewBuilder.build(financeStore);

  Future<void> openFund({
    String? id,
    required String name,
    required String description,
    required double amount,
    required bool protected,
    required FinanceFundCategory category,
    required bool preExisting,
    required List<FinanceMoneyPortion> sources,
  }) async {
    final fund = FinanceFund(
      id: id ?? 'fund_${clock().microsecondsSinceEpoch}',
      name: name,
      description: description,
      amount: amount,
      protected: protected,
      category: category,
    );
    if (id != null) throw ArgumentError('Un nuovo fondo non ha un ID');
    await lifecycle.openFund(
      fund: fund,
      sources: sources,
      preExisting: preExisting,
    );
  }

  Future<void> updateDetails({
    required FinanceFund current,
    required String name,
    required String description,
    required bool protected,
    required FinanceFundCategory category,
  }) => lifecycle.updateDetails(
    current: current,
    name: name,
    description: description,
    protected: protected,
    category: category,
  );

  Future<void> addFromAccounts(
    String fundId,
    List<FinanceMoneyPortion> sources,
    String description,
  ) => lifecycle.addFromAccounts(fundId, sources, description);

  Future<void> returnToAccounts(
    String fundId,
    List<FinanceMoneyPortion> destinations,
    String description, {
    bool close = false,
  }) => lifecycle.returnToAccounts(
    fundId,
    destinations,
    description,
    close: close,
  );

  Future<void> spend(
    String fundId,
    double amount,
    String description, {
    bool close = false,
  }) => lifecycle.spend(fundId, amount, description, close: close);

  Future<void> transferBetweenFunds(
    String sourceFundId,
    String destinationFundId,
    double amount,
    String description,
  ) => lifecycle.transferBetweenFunds(
    sourceFundId,
    destinationFundId,
    amount,
    description,
  );

  Future<void> closeEmpty(String fundId) => lifecycle.closeEmpty(fundId);
}
