import 'finance_transaction.dart';
import 'finance_asset_movement.dart';

enum FinanceLedgerTypeFilter { all, income, expense, transfer }

enum FinanceLedgerOriginFilter { all, recurringItem, manual, fund, adjustment }

class FinanceLedgerEntryViewData {
  final FinanceTransaction transaction;
  final String balanceName;
  final String ownerName;
  final String typeLabel;
  final String description;
  final String accountRoleLabel;

  const FinanceLedgerEntryViewData({
    required this.transaction,
    required this.balanceName,
    required this.ownerName,
    required this.typeLabel,
    required this.description,
    required this.accountRoleLabel,
  });
}

class FinanceLedgerPartyViewData {
  final String name;
  final String? ownerName;
  final double amount;

  const FinanceLedgerPartyViewData({
    required this.name,
    this.ownerName,
    required this.amount,
  });
}

class FinanceFundOperationViewData {
  final FinanceAssetMovement movement;
  final String typeLabel;
  final String description;
  final List<FinanceLedgerPartyViewData> origins;
  final List<FinanceLedgerPartyViewData> destinations;
  final double amount;

  const FinanceFundOperationViewData({
    required this.movement,
    required this.typeLabel,
    required this.description,
    required this.origins,
    required this.destinations,
    required this.amount,
  });
}

class FinanceLedgerViewData {
  final List<FinanceLedgerEntryViewData> entries;
  final List<FinanceFundOperationViewData> fundOperations;

  const FinanceLedgerViewData({
    required this.entries,
    required this.fundOperations,
  });
}
