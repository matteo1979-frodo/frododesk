import 'finance_fund.dart';
import 'finance_asset_movement.dart';
import 'fund_transaction.dart';

class FinanceFundViewData {
  final FinanceFund fund;
  final List<FundTransaction> transactions;
  final List<FinanceAssetMovement> assetMovements;

  const FinanceFundViewData({
    required this.fund,
    required this.transactions,
    required this.assetMovements,
  });
}

class FinanceFundSourceViewData {
  final String balanceId;
  final String name;
  final String ownerName;
  final double availableAmount;

  const FinanceFundSourceViewData({
    required this.balanceId,
    required this.name,
    required this.ownerName,
    required this.availableAmount,
  });
}

class FinanceFundsViewData {
  final double totalAmount;
  final List<FinanceFundViewData> funds;
  final List<FinanceFundSourceViewData> sources;
  final double familyNetWorth;

  const FinanceFundsViewData({
    required this.totalAmount,
    required this.funds,
    required this.sources,
    required this.familyNetWorth,
  });
}
