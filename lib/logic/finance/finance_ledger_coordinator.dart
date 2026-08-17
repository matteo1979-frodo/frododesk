import '../../models/finance_ledger_view_data.dart';
import '../../stores/finance_store.dart';
import 'builders/finance_ledger_view_builder.dart';

class FinanceLedgerCoordinator {
  final FinanceStore financeStore;
  final FinanceLedgerViewBuilder viewBuilder;

  const FinanceLedgerCoordinator({
    required this.financeStore,
    this.viewBuilder = const FinanceLedgerViewBuilder(),
  });

  FinanceLedgerViewData build({
    String query = '',
    FinanceLedgerTypeFilter type = FinanceLedgerTypeFilter.all,
    FinanceLedgerOriginFilter origin = FinanceLedgerOriginFilter.all,
  }) {
    return viewBuilder.build(
      store: financeStore,
      query: query,
      type: type,
      origin: origin,
    );
  }
}
