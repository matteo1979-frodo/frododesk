import 'dart:collection';

import '../../models/economic_event.dart';
import '../../models/finance_asset_movement.dart';
import '../../models/finance_transaction.dart';
import '../../models/real_expense.dart';
import '../economics/adapters/finance_asset_movement_event_adapter.dart';
import '../economics/adapters/finance_transaction_event_adapter.dart';
import '../economics/adapters/real_expense_event_adapter.dart';

class EconomicEventCollector {
  final FinanceTransactionEventAdapter transactionAdapter;
  final FinanceAssetMovementEventAdapter assetMovementAdapter;
  final RealExpenseEventAdapter realExpenseAdapter;

  const EconomicEventCollector({
    this.transactionAdapter = const FinanceTransactionEventAdapter(),
    this.assetMovementAdapter = const FinanceAssetMovementEventAdapter(),
    this.realExpenseAdapter = const RealExpenseEventAdapter(),
  });

  UnmodifiableListView<EconomicEvent> collect({
    required Iterable<FinanceTransaction> transactions,
    required Iterable<FinanceAssetMovement> assetMovements,
    required Iterable<RealExpense> realExpenses,
    required DateTime observedAt,
  }) {
    final events = <EconomicEvent>[
      ...transactions.map(
        (source) => transactionAdapter.adapt(source, observedAt: observedAt),
      ),
      ...assetMovements.map(
        (source) => assetMovementAdapter.adapt(source, observedAt: observedAt),
      ),
      ...realExpenses.map(
        (source) => realExpenseAdapter.adapt(source, observedAt: observedAt),
      ),
    ];
    return UnmodifiableListView(events);
  }
}
