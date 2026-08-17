import 'finance_asset_movement.dart';
import 'finance_balance.dart';
import 'finance_fund.dart';
import 'finance_transaction.dart';

class FinanceFundMutationPlan {
  final List<FinanceBalance> balances;
  final List<FinanceFund> funds;
  final List<FinanceAssetMovement> movements;
  final List<FinanceTransaction> transactions;

  const FinanceFundMutationPlan({
    required this.balances,
    required this.funds,
    required this.movements,
    required this.transactions,
  });
}
