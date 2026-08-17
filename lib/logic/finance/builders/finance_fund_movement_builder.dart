import '../../../models/finance_asset_movement.dart';
import '../../../models/finance_balance.dart';
import '../../../models/finance_fund.dart';
import '../../../models/finance_fund_mutation_plan.dart';
import '../../../models/finance_recurring_item.dart';
import '../../../models/finance_transaction.dart';

class FinanceFundMovementBuilder {
  const FinanceFundMovementBuilder();

  FinanceFundMutationPlan open({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required FinanceFund fund,
    required List<FinanceMoneyPortion> sources,
    required bool preExisting,
    required DateTime occurredAt,
    String? economicFactId,
  }) {
    _requirePositive(fund.amount);
    if (preExisting && sources.isNotEmpty) {
      throw ArgumentError('Un saldo già esistente non usa conti sorgente');
    }
    if (!preExisting) _requirePortions(sources, fund.amount);
    final updatedBalances = _applyBalances(
      balances,
      sources
          .map(
            (source) => FinanceMoneyPortion(
              balanceId: source.balanceId,
              amount: -source.amount,
            ),
          )
          .toList(),
      occurredAt,
      enforceAvailability: true,
    );
    final openedFund = _copyFund(
      fund,
      openingKind: preExisting
          ? FinanceFundOpeningKind.preExisting
          : FinanceFundOpeningKind.fundedFromAccounts,
      openedAt: occurredAt,
    );
    final legs = preExisting
        ? [
            FinanceAssetLeg(
              type: FinanceAssetLegType.openingBalance,
              delta: -fund.amount,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: fund.id,
              delta: fund.amount,
            ),
          ]
        : [
            ...sources.map(
              (source) => FinanceAssetLeg(
                type: FinanceAssetLegType.balance,
                referenceId: source.balanceId,
                delta: -source.amount,
              ),
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: fund.id,
              delta: fund.amount,
            ),
          ];
    return _plan(
      updatedBalances,
      [...funds, openedFund],
      movements,
      transactions,
      _movement(
        fund.id,
        preExisting
            ? FinanceAssetMovementKind.fundOpening
            : FinanceAssetMovementKind.fundAllocation,
        'Apertura ${fund.name}',
        occurredAt,
        legs,
        economicFactId: economicFactId,
      ),
    );
  }

  FinanceFundMutationPlan allocate({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required String fundId,
    required List<FinanceMoneyPortion> sources,
    required String description,
    required DateTime occurredAt,
    String? economicFactId,
  }) {
    final fund = _activeFund(funds, fundId);
    final amount = sources.fold<double>(
      0,
      (sum, source) => sum + source.amount,
    );
    _requirePortions(sources, amount);
    final updatedBalances = _applyBalances(
      balances,
      sources
          .map(
            (source) => FinanceMoneyPortion(
              balanceId: source.balanceId,
              amount: -source.amount,
            ),
          )
          .toList(),
      occurredAt,
      enforceAvailability: true,
    );
    final updatedFunds = _replaceFund(
      funds,
      _copyFund(fund, amount: fund.amount + amount),
    );
    final legs = [
      ...sources.map(
        (source) => FinanceAssetLeg(
          type: FinanceAssetLegType.balance,
          referenceId: source.balanceId,
          delta: -source.amount,
        ),
      ),
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: fundId,
        delta: amount,
      ),
    ];
    return _plan(
      updatedBalances,
      updatedFunds,
      movements,
      transactions,
      _movement(
        fundId,
        FinanceAssetMovementKind.fundAllocation,
        description,
        occurredAt,
        legs,
        economicFactId: economicFactId,
      ),
    );
  }

  FinanceFundMutationPlan release({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required String fundId,
    required List<FinanceMoneyPortion> destinations,
    required String description,
    required DateTime occurredAt,
    bool close = false,
    String? economicFactId,
  }) {
    final fund = _activeFund(funds, fundId);
    final amount = destinations.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    _requirePortions(destinations, amount);
    if (amount > fund.amount) throw ArgumentError('Saldo fondo insufficiente');
    if (close && (amount - fund.amount).abs() > 0.001) {
      throw ArgumentError('La chiusura deve destinare tutto il saldo');
    }
    final updatedBalances = _applyBalances(balances, destinations, occurredAt);
    final remaining = fund.amount - amount;
    final updatedFund = _copyFund(
      fund,
      amount: remaining,
      status: close ? FinanceFundStatus.closed : fund.status,
      closedAt: close ? occurredAt : fund.closedAt,
    );
    final legs = [
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: fundId,
        delta: -amount,
      ),
      ...destinations.map(
        (item) => FinanceAssetLeg(
          type: FinanceAssetLegType.balance,
          referenceId: item.balanceId,
          delta: item.amount,
        ),
      ),
    ];
    return _plan(
      updatedBalances,
      _replaceFund(funds, updatedFund),
      movements,
      transactions,
      _movement(
        fundId,
        FinanceAssetMovementKind.fundRelease,
        description,
        occurredAt,
        legs,
        economicFactId: economicFactId,
      ),
    );
  }

  FinanceFundMutationPlan spend({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required String fundId,
    required double amount,
    required String description,
    required DateTime occurredAt,
    bool close = false,
    String? economicFactId,
  }) {
    final fund = _activeFund(funds, fundId);
    _requirePositive(amount);
    if (amount > fund.amount) throw ArgumentError('Saldo fondo insufficiente');
    if (close && (amount - fund.amount).abs() > 0.001) {
      throw ArgumentError('La chiusura deve consumare tutto il saldo');
    }
    final remaining = fund.amount - amount;
    final updatedFund = _copyFund(
      fund,
      amount: remaining,
      status: close ? FinanceFundStatus.closed : fund.status,
      closedAt: close ? occurredAt : fund.closedAt,
    );
    final movement = _movement(
      fundId,
      FinanceAssetMovementKind.fundExpense,
      description,
      occurredAt,
      [
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: fundId,
          delta: -amount,
        ),
        FinanceAssetLeg(type: FinanceAssetLegType.expense, delta: amount),
      ],
      economicFactId: economicFactId,
    );
    final transaction = FinanceTransaction(
      id: 'fund_expense_${occurredAt.microsecondsSinceEpoch}',
      balanceId: fundId,
      amount: amount,
      date: occurredAt,
      isIncome: false,
      subject: FinanceSubject.shared,
      description: description,
      type: FinanceTransactionType.expense,
      origin: FinanceTransactionOrigin.fund,
      notes: 'Spesa dal fondo ${fund.name}',
      economicFactId: economicFactId,
    );
    return _plan(balances, _replaceFund(funds, updatedFund), movements, [
      ...transactions,
      transaction,
    ], movement);
  }

  FinanceFundMutationPlan transferBetweenFunds({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required String sourceFundId,
    required String destinationFundId,
    required double amount,
    required String description,
    required DateTime occurredAt,
    String? economicFactId,
  }) {
    if (sourceFundId == destinationFundId) {
      throw ArgumentError('Il fondo di destinazione deve essere diverso');
    }
    final source = _activeFund(funds, sourceFundId);
    final destination = _activeFund(funds, destinationFundId);
    _requirePositive(amount);
    if (amount > source.amount) {
      throw ArgumentError('Saldo fondo insufficiente');
    }

    final updatedFunds = funds.map((fund) {
      if (fund.id == sourceFundId) {
        return _copyFund(fund, amount: fund.amount - amount);
      }
      if (fund.id == destinationFundId) {
        return _copyFund(fund, amount: fund.amount + amount);
      }
      return fund;
    }).toList();
    final effectiveDescription = description.trim().isEmpty
        ? 'Da ${source.name} a ${destination.name}'
        : description.trim();
    final legs = [
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: sourceFundId,
        delta: -amount,
      ),
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: destinationFundId,
        delta: amount,
      ),
    ];
    final outgoing = _movement(
      sourceFundId,
      FinanceAssetMovementKind.fundTransferOut,
      effectiveDescription,
      occurredAt,
      legs,
      idSuffix: 'out',
      economicFactId: economicFactId,
    );
    final incoming = _movement(
      destinationFundId,
      FinanceAssetMovementKind.fundTransferIn,
      effectiveDescription,
      occurredAt,
      legs,
      idSuffix: 'in',
      economicFactId: economicFactId,
    );
    return _planMany(balances, updatedFunds, movements, transactions, [
      outgoing,
      incoming,
    ]);
  }

  FinanceFundMutationPlan closeEmpty({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required String fundId,
    required DateTime occurredAt,
  }) {
    final fund = _activeFund(funds, fundId);
    if (fund.amount.abs() > 0.001) {
      throw ArgumentError('Il fondo ha ancora un saldo');
    }
    return FinanceFundMutationPlan(
      balances: balances,
      funds: _replaceFund(
        funds,
        _copyFund(
          fund,
          amount: 0,
          status: FinanceFundStatus.closed,
          closedAt: occurredAt,
        ),
      ),
      movements: movements,
      transactions: transactions,
    );
  }

  FinanceFundMutationPlan updateDetails({
    required List<FinanceBalance> balances,
    required List<FinanceFund> funds,
    required List<FinanceAssetMovement> movements,
    required List<FinanceTransaction> transactions,
    required FinanceFund current,
    required String name,
    required String description,
    required bool protected,
    required FinanceFundCategory category,
  }) {
    final updated = FinanceFund(
      id: current.id,
      name: name,
      description: description,
      amount: current.amount,
      protected: protected,
      category: category,
      status: current.status,
      openingKind: current.openingKind,
      openedAt: current.openedAt,
      closedAt: current.closedAt,
    );
    return FinanceFundMutationPlan(
      balances: balances,
      funds: _replaceFund(funds, updated),
      movements: movements,
      transactions: transactions,
    );
  }

  FinanceFundMutationPlan _plan(
    List<FinanceBalance> balances,
    List<FinanceFund> funds,
    List<FinanceAssetMovement> movements,
    List<FinanceTransaction> transactions,
    FinanceAssetMovement movement,
  ) {
    if (movement.accountingDelta.abs() > 0.001) {
      throw StateError('Movimento patrimoniale non bilanciato');
    }
    return FinanceFundMutationPlan(
      balances: balances,
      funds: funds,
      movements: [...movements, movement],
      transactions: transactions,
    );
  }

  FinanceFundMutationPlan _planMany(
    List<FinanceBalance> balances,
    List<FinanceFund> funds,
    List<FinanceAssetMovement> movements,
    List<FinanceTransaction> transactions,
    List<FinanceAssetMovement> newMovements,
  ) {
    for (final movement in newMovements) {
      if (movement.accountingDelta.abs() > 0.001) {
        throw StateError('Movimento patrimoniale non bilanciato');
      }
    }
    return FinanceFundMutationPlan(
      balances: balances,
      funds: funds,
      movements: [...movements, ...newMovements],
      transactions: transactions,
    );
  }

  FinanceAssetMovement _movement(
    String fundId,
    FinanceAssetMovementKind kind,
    String description,
    DateTime occurredAt,
    List<FinanceAssetLeg> legs, {
    String? idSuffix,
    String? economicFactId,
  }) {
    return FinanceAssetMovement(
      id: 'asset_${occurredAt.microsecondsSinceEpoch}${idSuffix == null ? '' : '_$idSuffix'}',
      fundId: fundId,
      kind: kind,
      description: description,
      occurredAt: occurredAt,
      legs: legs,
      economicFactId: economicFactId,
    );
  }

  void _requirePositive(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Importo non valido');
    }
  }

  void _requirePortions(List<FinanceMoneyPortion> portions, double expected) {
    if (portions.isEmpty) throw ArgumentError('Seleziona almeno un conto');
    final ids = portions.map((item) => item.balanceId).toSet();
    if (ids.length != portions.length) throw ArgumentError('Conto duplicato');
    for (final portion in portions) {
      _requirePositive(portion.amount);
    }
    final total = portions.fold<double>(0, (sum, item) => sum + item.amount);
    if ((total - expected).abs() > 0.001) {
      throw ArgumentError('Ripartizione non valida');
    }
  }

  List<FinanceBalance> _applyBalances(
    List<FinanceBalance> balances,
    List<FinanceMoneyPortion> deltas,
    DateTime occurredAt, {
    bool enforceAvailability = false,
  }) {
    final result = List<FinanceBalance>.of(balances);
    for (final delta in deltas) {
      final index = result.indexWhere(
        (item) => item.balanceId == delta.balanceId && item.active,
      );
      if (index < 0) throw ArgumentError('Conto non disponibile');
      final old = result[index];
      if (enforceAvailability && -delta.amount > old.availableAmount) {
        throw ArgumentError('Disponibilità insufficiente');
      }
      result[index] = FinanceBalance(
        balanceId: old.balanceId,
        personId: old.personId,
        name: old.name,
        initialAmount: old.initialAmount,
        currentAmount: old.currentAmount + delta.amount,
        updatedAt: occurredAt,
        balanceType: old.balanceType,
        operational: old.operational,
        active: old.active,
        reservedAmount: old.reservedAmount,
        warningThreshold: old.warningThreshold,
        persistentStressDays: old.persistentStressDays,
        recoveryDays: old.recoveryDays,
      );
    }
    return result;
  }

  FinanceFund _activeFund(List<FinanceFund> funds, String id) {
    final fund = funds.where((item) => item.id == id).firstOrNull;
    if (fund == null || fund.status != FinanceFundStatus.active) {
      throw ArgumentError('Fondo non disponibile');
    }
    return fund;
  }

  List<FinanceFund> _replaceFund(List<FinanceFund> funds, FinanceFund fund) =>
      funds.map((item) => item.id == fund.id ? fund : item).toList();

  FinanceFund _copyFund(
    FinanceFund fund, {
    double? amount,
    FinanceFundStatus? status,
    FinanceFundOpeningKind? openingKind,
    DateTime? openedAt,
    DateTime? closedAt,
  }) {
    return FinanceFund(
      id: fund.id,
      name: fund.name,
      description: fund.description,
      amount: amount ?? fund.amount,
      protected: fund.protected,
      category: fund.category,
      status: status ?? fund.status,
      openingKind: openingKind ?? fund.openingKind,
      openedAt: openedAt ?? fund.openedAt,
      closedAt: closedAt ?? fund.closedAt,
    );
  }
}
