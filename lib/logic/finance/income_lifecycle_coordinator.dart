import 'dart:convert';

import '../../models/balance_posting_mode.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/finance_transaction.dart';
import '../../models/income.dart';
import '../../stores/finance_store.dart';
import 'finance_portfolio_v3_contract.dart';

class IncomeCreditRequest {
  final String operationId;
  final String? relationshipId;
  final DateTime occurredAt;
  final double totalAmount;
  final FinanceSubject subject;
  final String? payer;
  final String destinationBalanceId;
  final BalancePostingMode postingMode;
  final List<IncomeReconciliationAllocation> allocations;

  const IncomeCreditRequest({
    required this.operationId,
    this.relationshipId,
    required this.occurredAt,
    required this.totalAmount,
    required this.subject,
    this.payer,
    required this.destinationBalanceId,
    required this.postingMode,
    required this.allocations,
  });
}

class IncomeLifecycleCoordinator {
  final FinanceStore financeStore;

  const IncomeLifecycleCoordinator({required this.financeStore});

  Future<void> addCustomCategory(IncomeCustomCategory category) async {
    final current = financeStore.incomeAggregate;
    final existing = current.customCategories
        .where((item) => item.id == category.id)
        .toList();
    if (existing.isNotEmpty) {
      if (existing.single.label == category.label) return;
      throw StateError('Custom income category identity conflict');
    }
    await financeStore.saveIncomeAggregate(
      IncomeAggregate(
        relationships: current.relationships,
        occurrences: current.occurrences,
        reconciliations: current.reconciliations,
        customCategories: [...current.customCategories, category],
      ),
    );
  }

  Future<void> addRelationship(IncomeRelationship relationship) async {
    final current = financeStore.incomeAggregate;
    final existing = current.relationships
        .where((item) => item.relationshipId == relationship.relationshipId)
        .toList();
    if (existing.isNotEmpty) {
      if (_relationshipJson(existing.single) ==
          _relationshipJson(relationship)) {
        return;
      }
      throw StateError('Income relationship identity conflict');
    }
    if (relationship.customCategoryId != null &&
        !current.customCategories.any(
          (item) => item.id == relationship.customCategoryId,
        )) {
      throw StateError('Custom income category is missing');
    }
    await financeStore.saveIncomeAggregate(
      IncomeAggregate(
        relationships: [...current.relationships, relationship],
        occurrences: current.occurrences,
        reconciliations: current.reconciliations,
        customCategories: current.customCategories,
      ),
    );
  }

  Future<void> updateRelationship(IncomeRelationship relationship) async {
    final current = financeStore.incomeAggregate;
    if (!current.relationships.any(
      (item) => item.relationshipId == relationship.relationshipId,
    )) {
      throw StateError('Income relationship not found');
    }
    if (relationship.customCategoryId != null &&
        !current.customCategories.any(
          (item) => item.id == relationship.customCategoryId,
        )) {
      throw StateError('Custom income category is missing');
    }
    await financeStore.saveIncomeAggregate(
      IncomeAggregate(
        relationships: current.relationships
            .map(
              (item) => item.relationshipId == relationship.relationshipId
                  ? relationship
                  : item,
            )
            .toList(),
        occurrences: current.occurrences,
        reconciliations: current.reconciliations,
        customCategories: current.customCategories,
      ),
    );
  }

  Future<void> addOccurrence(ExpectedIncomeOccurrence occurrence) async {
    final current = financeStore.incomeAggregate;
    if (!current.relationships.any(
      (item) => item.relationshipId == occurrence.relationshipId,
    )) {
      throw StateError('Income relationship is missing');
    }
    final existing = current.occurrences
        .where((item) => item.occurrenceId == occurrence.occurrenceId)
        .toList();
    if (existing.isNotEmpty) {
      if (_occurrenceJson(existing.single) == _occurrenceJson(occurrence)) {
        return;
      }
      throw StateError('Income occurrence identity conflict');
    }
    if (occurrence.cycleSequence != null &&
        current.occurrences.any(
          (item) =>
              item.relationshipId == occurrence.relationshipId &&
              item.cycleSequence == occurrence.cycleSequence,
        )) {
      throw StateError('Income cycle identity conflict');
    }
    await financeStore.saveIncomeAggregate(
      IncomeAggregate(
        relationships: current.relationships,
        occurrences: [...current.occurrences, occurrence],
        reconciliations: current.reconciliations,
        customCategories: current.customCategories,
      ),
    );
  }

  Future<IncomeReconciliation> recordCredit(IncomeCreditRequest request) async {
    final reconciliation = _reconciliation(request);
    final aggregate = financeStore.incomeAggregate;
    final existing = aggregate.reconciliations
        .where(
          (item) => item.reconciliationId == reconciliation.reconciliationId,
        )
        .toList();
    if (existing.isNotEmpty) {
      if (_reconciliationJson(existing.single) ==
          _reconciliationJson(reconciliation)) {
        return existing.single;
      }
      throw StateError('Income operation identity conflict');
    }
    _validateReferences(aggregate, reconciliation);
    final transaction = _transaction(reconciliation);
    final transactionMatches = financeStore.transactions
        .where(
          (item) =>
              item.id == transaction.id ||
              item.economicFactId == transaction.economicFactId,
        )
        .toList();
    if (transactionMatches.isEmpty) {
      final result = await financeStore.commitPortfolioV3Candidate(
        (current) => _withPostedCredit(current, transaction),
      );
      if (!result.isSuccess) {
        throw StateError(
          'Income portfolio write failed: ${result.errors.join('; ')}',
        );
      }
    } else if (transactionMatches.length != 1 ||
        !_sameTransaction(transactionMatches.single, transaction)) {
      throw StateError('Income economic fact identity conflict');
    }
    await _saveReconciliation(aggregate, reconciliation);
    return reconciliation;
  }

  Future<IncomeReconciliation> correctCredit({
    required String reconciliationId,
    required DateTime occurredAt,
    required double totalAmount,
    required FinanceSubject subject,
    required String destinationBalanceId,
    required List<IncomeReconciliationAllocation> allocations,
    String? payer,
    String? relationshipId,
    bool replaceRelationship = false,
  }) async {
    final aggregate = financeStore.incomeAggregate;
    final original = aggregate.reconciliations.firstWhere(
      (item) => item.reconciliationId == reconciliationId,
      orElse: () => throw StateError('Income reconciliation not found'),
    );
    final replacement = IncomeReconciliation(
      reconciliationId: original.reconciliationId,
      economicFactId: original.economicFactId,
      transactionId: original.transactionId,
      relationshipId: replaceRelationship
          ? relationshipId
          : original.relationshipId,
      occurredAt: occurredAt,
      totalAmount: totalAmount,
      subject: subject,
      payer: payer,
      destinationBalanceId: destinationBalanceId,
      postingMode: original.postingMode,
      allocations: allocations,
    );
    _validateReferences(aggregate, replacement);
    final originalTransaction = financeStore.transactions.singleWhere(
      (item) => item.economicFactId == original.economicFactId,
      orElse: () => throw StateError('Income FinanceTransaction not found'),
    );
    final replacementTransaction = _transaction(replacement);
    if (!_sameTransaction(originalTransaction, replacementTransaction)) {
      final result = await financeStore.commitPortfolioV3Candidate(
        (current) => _withCorrectedCredit(
          current,
          originalTransaction,
          replacementTransaction,
          original.postingMode,
        ),
      );
      if (!result.isSuccess) {
        throw StateError(
          'Income correction failed: ${result.errors.join('; ')}',
        );
      }
    }
    final nextReconciliations = aggregate.reconciliations
        .map(
          (item) =>
              item.reconciliationId == reconciliationId ? replacement : item,
        )
        .toList();
    await financeStore.saveIncomeAggregate(
      _rebuildAggregate(aggregate, nextReconciliations),
    );
    return replacement;
  }

  IncomeReconciliation _reconciliation(IncomeCreditRequest request) =>
      IncomeReconciliation(
        reconciliationId: 'income-reconciliation:${request.operationId}',
        economicFactId: 'economic-fact:income:${request.operationId}',
        transactionId: 'income-transaction:${request.operationId}',
        relationshipId: request.relationshipId,
        occurredAt: request.occurredAt,
        totalAmount: request.totalAmount,
        subject: request.subject,
        payer: request.payer,
        destinationBalanceId: request.destinationBalanceId,
        postingMode: request.postingMode,
        allocations: request.allocations,
      );

  FinanceTransaction _transaction(IncomeReconciliation reconciliation) =>
      FinanceTransaction(
        id: reconciliation.transactionId,
        balanceId: reconciliation.destinationBalanceId,
        amount: reconciliation.totalAmount,
        date: reconciliation.occurredAt,
        isIncome: true,
        subject: reconciliation.subject,
        description: reconciliation.payer == null
            ? 'Entrata'
            : 'Entrata da ${reconciliation.payer}',
        type: FinanceTransactionType.income,
        origin: FinanceTransactionOrigin.manual,
        economicFactId: reconciliation.economicFactId,
        balancePostingMode: reconciliation.postingMode,
      );

  FinancePortfolioV3 _withPostedCredit(
    FinancePortfolioV3 current,
    FinanceTransaction transaction,
  ) {
    final balances = List<FinanceBalance>.of(current.balances);
    final index = balances.indexWhere(
      (item) => item.balanceId == transaction.balanceId,
    );
    if (index < 0) throw StateError('Destination balance not found');
    if (transaction.balancePostingMode ==
        BalancePostingMode.affectsCurrentBalance) {
      balances[index] = _withBalanceAmount(
        balances[index],
        balances[index].currentAmount + transaction.amount,
      );
    }
    return _portfolio(current, balances, [
      ...current.transactions,
      transaction,
    ]);
  }

  FinancePortfolioV3 _withCorrectedCredit(
    FinancePortfolioV3 current,
    FinanceTransaction original,
    FinanceTransaction replacement,
    BalancePostingMode postingMode,
  ) {
    final balances = List<FinanceBalance>.of(current.balances);
    final oldIndex = balances.indexWhere(
      (item) => item.balanceId == original.balanceId,
    );
    final newIndex = balances.indexWhere(
      (item) => item.balanceId == replacement.balanceId,
    );
    if (oldIndex < 0 || newIndex < 0) {
      throw StateError('Income balance not found');
    }
    if (postingMode == BalancePostingMode.affectsCurrentBalance) {
      balances[oldIndex] = _withBalanceAmount(
        balances[oldIndex],
        balances[oldIndex].currentAmount - original.amount,
      );
      final refreshedNewIndex = balances.indexWhere(
        (item) => item.balanceId == replacement.balanceId,
      );
      balances[refreshedNewIndex] = _withBalanceAmount(
        balances[refreshedNewIndex],
        balances[refreshedNewIndex].currentAmount + replacement.amount,
      );
    }
    final transactions = current.transactions
        .map((item) => item.id == original.id ? replacement : item)
        .toList();
    return _portfolio(current, balances, transactions);
  }

  Future<void> _saveReconciliation(
    IncomeAggregate aggregate,
    IncomeReconciliation reconciliation,
  ) async {
    final reconciliations = [...aggregate.reconciliations, reconciliation];
    await financeStore.saveIncomeAggregate(
      _rebuildAggregate(aggregate, reconciliations),
    );
  }

  IncomeAggregate _rebuildAggregate(
    IncomeAggregate aggregate,
    List<IncomeReconciliation> reconciliations,
  ) {
    final occurrences = aggregate.occurrences.map((occurrence) {
      final allocations = reconciliations
          .expand(
            (item) => item.allocations.map((allocation) => (item, allocation)),
          )
          .where((entry) => entry.$2.occurrenceId == occurrence.occurrenceId)
          .toList();
      final total = allocations.fold<double>(
        0,
        (sum, entry) => sum + entry.$2.amount,
      );
      final ids = allocations.map((entry) => entry.$1.reconciliationId).toSet();
      if (occurrence.status == ExpectedIncomeStatus.cancelled && ids.isEmpty) {
        return occurrence;
      }
      return occurrence.withReconciliationState(
        reconciliationIds: ids,
        reconciledTotal: total,
      );
    }).toList();
    return IncomeAggregate(
      relationships: aggregate.relationships,
      occurrences: occurrences,
      reconciliations: reconciliations,
      customCategories: aggregate.customCategories,
    );
  }

  void _validateReferences(
    IncomeAggregate aggregate,
    IncomeReconciliation reconciliation,
  ) {
    if (!financeStore.balances.any(
      (item) => item.balanceId == reconciliation.destinationBalanceId,
    )) {
      throw StateError('Destination balance not found');
    }
    if (reconciliation.relationshipId != null &&
        !aggregate.relationships.any(
          (item) => item.relationshipId == reconciliation.relationshipId,
        )) {
      throw StateError('Income relationship not found');
    }
    for (final allocation in reconciliation.allocations) {
      if (allocation.occurrenceId != null) {
        final occurrence = aggregate.occurrences
            .where((item) => item.occurrenceId == allocation.occurrenceId)
            .firstOrNull;
        if (occurrence == null) {
          throw StateError('Income occurrence not found');
        }
        if (reconciliation.relationshipId == null ||
            occurrence.relationshipId != reconciliation.relationshipId) {
          throw StateError('Income occurrence relationship mismatch');
        }
      }
    }
  }

  FinanceBalance _withBalanceAmount(FinanceBalance source, double amount) =>
      FinanceBalance(
        personId: source.personId,
        balanceId: source.balanceId,
        name: source.name,
        initialAmount: source.initialAmount,
        currentAmount: amount,
        updatedAt: DateTime.now(),
        balanceType: source.balanceType,
        operational: source.operational,
        active: source.active,
        reservedAmount: source.reservedAmount,
        warningThreshold: source.warningThreshold,
        persistentStressDays: source.persistentStressDays,
        recoveryDays: source.recoveryDays,
      );

  FinancePortfolioV3 _portfolio(
    FinancePortfolioV3 source,
    List<FinanceBalance> balances,
    List<FinanceTransaction> transactions,
  ) => FinancePortfolioV3(
    balances: balances,
    funds: source.funds,
    assetMovements: source.assetMovements,
    transactions: transactions,
    fundTransactions: source.fundTransactions,
    linkedItems: source.linkedItems,
  );

  bool _sameTransaction(FinanceTransaction left, FinanceTransaction right) =>
      left.id == right.id &&
      left.economicFactId == right.economicFactId &&
      left.balanceId == right.balanceId &&
      left.amount == right.amount &&
      left.date == right.date &&
      left.subject == right.subject &&
      left.description == right.description &&
      left.isIncome == right.isIncome &&
      left.balancePostingMode == right.balancePostingMode;

  String _relationshipJson(IncomeRelationship value) =>
      jsonEncode(value.toJson());
  String _occurrenceJson(ExpectedIncomeOccurrence value) =>
      jsonEncode(value.toJson());
  String _reconciliationJson(IncomeReconciliation value) =>
      jsonEncode(value.toJson());
}
