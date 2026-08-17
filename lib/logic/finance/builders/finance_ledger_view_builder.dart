import '../../../models/finance_asset_movement.dart';
import '../../../models/finance_balance.dart';
import '../../../models/finance_ledger_view_data.dart';
import '../../../models/finance_transaction.dart';
import '../../../stores/finance_store.dart';

class FinanceLedgerViewBuilder {
  const FinanceLedgerViewBuilder();

  FinanceLedgerViewData build({
    required FinanceStore store,
    String query = '',
    FinanceLedgerTypeFilter type = FinanceLedgerTypeFilter.all,
    FinanceLedgerOriginFilter origin = FinanceLedgerOriginFilter.all,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final balanceNames = {
      for (final balance in store.balances) balance.balanceId: balance.name,
      for (final fund in store.funds) fund.id: fund.name,
    };
    final balancesById = {
      for (final balance in store.balances) balance.balanceId: balance,
    };
    final ownerNames = {
      for (final person in store.people) person.id: person.name,
    };
    final fundNames = {for (final fund in store.funds) fund.id: fund.name};

    final entries =
        store.transactions
            .where((transaction) {
              if (transaction.origin == FinanceTransactionOrigin.fund) {
                return false;
              }
              final matchesType =
                  type == FinanceLedgerTypeFilter.all ||
                  transaction.type.name == type.name;
              final matchesOrigin =
                  origin == FinanceLedgerOriginFilter.all ||
                  transaction.origin.name == origin.name;
              final balanceName =
                  balanceNames[transaction.balanceId] ??
                  'Conto non disponibile';
              final ownerName =
                  ownerNames[balancesById[transaction.balanceId]?.personId] ??
                  'Famiglia';
              final description = _transactionDescription(transaction);
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  description.toLowerCase().contains(normalizedQuery) ||
                  balanceName.toLowerCase().contains(normalizedQuery) ||
                  ownerName.toLowerCase().contains(normalizedQuery) ||
                  (transaction.notes?.toLowerCase().contains(normalizedQuery) ??
                      false);
              return matchesType && matchesOrigin && matchesQuery;
            })
            .map((transaction) {
              final balance = balancesById[transaction.balanceId];
              return FinanceLedgerEntryViewData(
                transaction: transaction,
                balanceName:
                    balanceNames[transaction.balanceId] ??
                    'Conto non disponibile',
                ownerName: ownerNames[balance?.personId] ?? 'Famiglia',
                typeLabel: _transactionTypeLabel(transaction),
                description: _transactionDescription(transaction),
                accountRoleLabel: transaction.isIncome
                    ? 'Accreditato su'
                    : 'Pagato con',
              );
            })
            .toList()
          ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    final fundOperations =
        store.assetMovements
            .where((movement) {
              if (movement.kind == FinanceAssetMovementKind.fundTransferIn) {
                return false;
              }
              final description = _fundDescription(movement);
              final involvedNames = movement.legs
                  .map((leg) => balanceNames[leg.referenceId] ?? '')
                  .join(' ')
                  .toLowerCase();
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  description.toLowerCase().contains(normalizedQuery) ||
                  involvedNames.contains(normalizedQuery);
              final movementType = switch (movement.kind) {
                FinanceAssetMovementKind.fundExpense =>
                  FinanceLedgerTypeFilter.expense,
                FinanceAssetMovementKind.fundAllocation ||
                FinanceAssetMovementKind.fundRelease ||
                FinanceAssetMovementKind.fundTransferOut ||
                FinanceAssetMovementKind.fundTransferIn =>
                  FinanceLedgerTypeFilter.transfer,
                _ => FinanceLedgerTypeFilter.all,
              };
              final matchesType =
                  type == FinanceLedgerTypeFilter.all || type == movementType;
              final matchesOrigin =
                  origin == FinanceLedgerOriginFilter.all ||
                  origin == FinanceLedgerOriginFilter.fund;
              return matchesQuery && matchesType && matchesOrigin;
            })
            .map((movement) {
              final origins = <FinanceLedgerPartyViewData>[];
              final destinations = <FinanceLedgerPartyViewData>[];
              for (final leg in movement.legs) {
                final party = _partyForLeg(
                  leg,
                  balanceNames: balanceNames,
                  balancesById: balancesById,
                  ownerNames: ownerNames,
                  fundNames: fundNames,
                );
                if (leg.delta < 0) {
                  origins.add(party);
                } else if (leg.delta > 0) {
                  destinations.add(party);
                }
              }
              return FinanceFundOperationViewData(
                movement: movement,
                typeLabel: _fundTypeLabel(movement.kind),
                description: _fundDescription(movement),
                origins: origins,
                destinations: destinations,
                amount: movement.legs
                    .where(
                      (leg) =>
                          leg.type == FinanceAssetLegType.fund &&
                          leg.referenceId == movement.fundId,
                    )
                    .fold<double>(0, (sum, leg) => sum + leg.delta)
                    .abs(),
              );
            })
            .toList()
          ..sort(
            (a, b) => b.movement.occurredAt.compareTo(a.movement.occurredAt),
          );

    return FinanceLedgerViewData(
      entries: entries,
      fundOperations: fundOperations,
    );
  }

  String _transactionTypeLabel(FinanceTransaction transaction) =>
      switch (transaction.type) {
        FinanceTransactionType.income => 'Entrata',
        FinanceTransactionType.expense => 'Uscita',
        FinanceTransactionType.transfer => 'Trasferimento',
      };

  String _transactionDescription(FinanceTransaction transaction) {
    final description = transaction.description.trim();
    if (description.isNotEmpty) return description;
    return switch (transaction.type) {
      FinanceTransactionType.income => 'Entrata sul conto',
      FinanceTransactionType.expense => 'Pagamento dal conto',
      FinanceTransactionType.transfer => 'Trasferimento di denaro',
    };
  }

  String _fundTypeLabel(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening => 'Apertura del fondo',
    FinanceAssetMovementKind.fundAllocation => 'Trasferimento al fondo',
    FinanceAssetMovementKind.fundRelease => 'Prelievo dal fondo',
    FinanceAssetMovementKind.fundExpense => 'Spesa dal fondo',
    FinanceAssetMovementKind.fundTransferOut => 'Trasferimento tra fondi',
    FinanceAssetMovementKind.fundTransferIn => 'Trasferimento tra fondi',
    FinanceAssetMovementKind.legacyOpening => 'Saldo iniziale del fondo',
    FinanceAssetMovementKind.legacyUnclassified => 'Operazione precedente',
  };

  String _fundDescription(FinanceAssetMovement movement) {
    final description = movement.description.trim();
    return description.isNotEmpty ? description : _fundTypeLabel(movement.kind);
  }

  FinanceLedgerPartyViewData _partyForLeg(
    FinanceAssetLeg leg, {
    required Map<String, String> balanceNames,
    required Map<String, FinanceBalance> balancesById,
    required Map<String, String> ownerNames,
    required Map<String, String> fundNames,
  }) {
    final amount = leg.delta.abs();
    switch (leg.type) {
      case FinanceAssetLegType.balance:
        final balance = balancesById[leg.referenceId];
        return FinanceLedgerPartyViewData(
          name: balanceNames[leg.referenceId] ?? 'Conto non disponibile',
          ownerName: ownerNames[balance?.personId] ?? 'Famiglia',
          amount: amount,
        );
      case FinanceAssetLegType.fund:
        return FinanceLedgerPartyViewData(
          name: fundNames[leg.referenceId] ?? 'Fondo',
          amount: amount,
        );
      case FinanceAssetLegType.openingBalance:
        return FinanceLedgerPartyViewData(
          name: 'Saldo già esistente',
          amount: amount,
        );
      case FinanceAssetLegType.expense:
        return FinanceLedgerPartyViewData(
          name: 'Spesa sostenuta',
          amount: amount,
        );
      case FinanceAssetLegType.legacyCounterpart:
        return FinanceLedgerPartyViewData(
          name: 'Provenienza precedente',
          amount: amount,
        );
    }
  }
}
