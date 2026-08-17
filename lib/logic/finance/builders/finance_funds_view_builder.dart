import '../../../models/finance_funds_view_data.dart';
import '../../../stores/finance_store.dart';

class FinanceFundsViewBuilder {
  const FinanceFundsViewBuilder();

  FinanceFundsViewData build(FinanceStore store) {
    final funds = store.funds.map((fund) {
      final transactions =
          store.fundTransactions
              .where((transaction) => transaction.fundId == fund.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      final assetMovements =
          store.assetMovements
              .where((movement) => movement.fundId == fund.id)
              .toList()
            ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return FinanceFundViewData(
        fund: fund,
        transactions: transactions,
        assetMovements: assetMovements,
      );
    }).toList();

    return FinanceFundsViewData(
      totalAmount: funds.fold(0, (sum, item) => sum + item.fund.amount),
      funds: funds,
      sources: store.balances.where((balance) => balance.active).map((balance) {
        final ownerName = balance.personId == 'matteo'
            ? 'Matteo'
            : balance.personId == 'chiara'
            ? 'Chiara'
            : 'Famiglia';
        return FinanceFundSourceViewData(
          balanceId: balance.balanceId,
          name: balance.name,
          ownerName: ownerName,
          availableAmount: balance.availableAmount,
        );
      }).toList(),
      familyNetWorth: store.familyNetWorth(),
    );
  }
}
