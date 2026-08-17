import '../../models/finance_asset_movement.dart';
import '../../models/finance_fund.dart';
import '../../models/finance_fund_mutation_plan.dart';
import '../../stores/finance_store.dart';
import '../economics/economic_fact_id_generator.dart';
import 'builders/finance_fund_movement_builder.dart';

class FinanceFundLifecycleCoordinator {
  final FinanceStore financeStore;
  final FinanceFundMovementBuilder movementBuilder;
  final DateTime Function() clock;
  final EconomicFactIdGenerator economicFactIdGenerator;

  FinanceFundLifecycleCoordinator({
    required this.financeStore,
    this.movementBuilder = const FinanceFundMovementBuilder(),
    DateTime Function()? clock,
    EconomicFactIdGenerator? economicFactIdGenerator,
  }) : clock = clock ?? DateTime.now,
       economicFactIdGenerator =
           economicFactIdGenerator ?? EconomicFactIdGenerator.timestamped();

  Future<void> openFund({
    required FinanceFund fund,
    required List<FinanceMoneyPortion> sources,
    required bool preExisting,
  }) => _commit(
    movementBuilder.open(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      fund: fund,
      sources: sources,
      preExisting: preExisting,
      occurredAt: clock(),
      economicFactId: economicFactIdGenerator.next(),
    ),
  );

  Future<void> addFromAccounts(
    String fundId,
    List<FinanceMoneyPortion> sources,
    String description,
  ) => _commit(
    movementBuilder.allocate(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      fundId: fundId,
      sources: sources,
      description: description,
      occurredAt: clock(),
      economicFactId: economicFactIdGenerator.next(),
    ),
  );

  Future<void> returnToAccounts(
    String fundId,
    List<FinanceMoneyPortion> destinations,
    String description, {
    bool close = false,
  }) => _commit(
    movementBuilder.release(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      fundId: fundId,
      destinations: destinations,
      description: description,
      occurredAt: clock(),
      close: close,
      economicFactId: economicFactIdGenerator.next(),
    ),
  );

  Future<void> spend(
    String fundId,
    double amount,
    String description, {
    bool close = false,
  }) => _commit(
    movementBuilder.spend(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      fundId: fundId,
      amount: amount,
      description: description,
      occurredAt: clock(),
      close: close,
      economicFactId: economicFactIdGenerator.next(),
    ),
  );

  Future<void> transferBetweenFunds(
    String sourceFundId,
    String destinationFundId,
    double amount,
    String description,
  ) => _commit(
    movementBuilder.transferBetweenFunds(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      sourceFundId: sourceFundId,
      destinationFundId: destinationFundId,
      amount: amount,
      description: description,
      occurredAt: clock(),
      economicFactId: economicFactIdGenerator.next(),
    ),
  );

  Future<void> closeEmpty(String fundId) => _commit(
    movementBuilder.closeEmpty(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      fundId: fundId,
      occurredAt: clock(),
    ),
  );

  Future<void> updateDetails({
    required FinanceFund current,
    required String name,
    required String description,
    required bool protected,
    required FinanceFundCategory category,
  }) => _commit(
    movementBuilder.updateDetails(
      balances: financeStore.balances,
      funds: financeStore.funds,
      movements: financeStore.assetMovements,
      transactions: financeStore.transactions,
      current: current,
      name: name,
      description: description,
      protected: protected,
      category: category,
    ),
  );

  Future<void> _commit(FinanceFundMutationPlan plan) =>
      financeStore.commitFundPlan(plan);
}
