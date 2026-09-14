import '../../models/ledger_presentation_data.dart';
import '../../stores/cash_wallet_store.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import '../ledger/ledger_coordinator.dart';
import '../ledger/ledger_endpoint_registry_builder.dart';
import '../ledger/ledger_endpoint_resolver.dart';
import '../ledger/ledger_presentation_builder.dart';
import '../ledger/ledger_timeline_builder.dart';

class FinanceLedgerPresentationCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final LedgerEndpointRegistryBuilder registryBuilder;
  final LedgerPresentationBuilder presentationBuilder;

  const FinanceLedgerPresentationCoordinator({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    this.registryBuilder = const LedgerEndpointRegistryBuilder(),
    this.presentationBuilder = const LedgerPresentationBuilder(),
  });

  LedgerPresentationData build({
    required DateTime observedAt,
    String query = '',
    Set<String> selectedFilterIds = const {},
  }) {
    final registry = registryBuilder.build(
      accounts: financeStore.balances,
      funds: financeStore.funds,
      wallets: cashWalletStore.all,
      people: financeStore.people,
    );
    final snapshot =
        LedgerCoordinator(
          timelineBuilder: LedgerTimelineBuilder(
            endpointResolver: LedgerEndpointResolver(registry: registry),
          ),
        ).build(
          transactions: financeStore.transactions,
          assetMovements: financeStore.assetMovements,
          realExpenses: expenseStore.all,
          observedAt: observedAt,
          query: query,
          selectedFilterIds: selectedFilterIds,
        );
    return presentationBuilder.build(snapshot);
  }
}
