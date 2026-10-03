import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/finance_balance.dart';
import '../models/balance_posting_mode.dart';
import '../models/finance_fund.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_snapshot.dart';
import 'finance_demo_data.dart';
import '../logic/persistence_store.dart';
import '../models/fund_transaction.dart';
import '../models/finance_month_projection.dart';
import '../models/finance_transaction.dart';
import '../models/finance_account_linked_item.dart';
import '../models/finance_asset_movement.dart';
import '../models/finance_fund_mutation_plan.dart';
import '../logic/economics/economic_fact_id_generator.dart';
import '../logic/finance/finance_portfolio_v3_contract.dart';
import '../logic/finance/finance_portfolio_v3_commit.dart';
import '../logic/finance/finance_portfolio_v3_writer.dart';
import '../logic/finance/finance_prepaid_creation.dart';
import '../logic/finance/expected_expense_persistence.dart';
import '../logic/finance/documentary_obligation_persistence.dart';
import '../logic/finance/finite_financial_plan_persistence.dart';
import '../logic/finance/income_persistence.dart';
import '../models/finite_financial_plan.dart';
import '../models/income.dart';

enum FinancePortfolioV3PromotionStatus {
  promoted,
  alreadyAuthoritative,
  notReady,
  invalidCandidate,
  writerFailed,
}

class FinancePortfolioV3PromotionResult {
  final FinancePortfolioV3PromotionStatus status;
  final FinancePortfolioV3WriteResult? writeResult;
  final List<String> errors;

  FinancePortfolioV3PromotionResult._({
    required this.status,
    required this.writeResult,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory FinancePortfolioV3PromotionResult.promoted(
    FinancePortfolioV3WriteResult writeResult,
  ) => FinancePortfolioV3PromotionResult._(
    status: FinancePortfolioV3PromotionStatus.promoted,
    writeResult: writeResult,
    errors: const [],
  );

  factory FinancePortfolioV3PromotionResult.alreadyAuthoritative() =>
      FinancePortfolioV3PromotionResult._(
        status: FinancePortfolioV3PromotionStatus.alreadyAuthoritative,
        writeResult: null,
        errors: const [],
      );

  factory FinancePortfolioV3PromotionResult.failed({
    required FinancePortfolioV3PromotionStatus status,
    required Iterable<String> errors,
    FinancePortfolioV3WriteResult? writeResult,
  }) => FinancePortfolioV3PromotionResult._(
    status: status,
    writeResult: writeResult,
    errors: errors,
  );

  bool get isSuccess =>
      status == FinancePortfolioV3PromotionStatus.promoted ||
      status == FinancePortfolioV3PromotionStatus.alreadyAuthoritative;
}

class FinanceStore extends ChangeNotifier {
  final EconomicFactIdGenerator economicFactIdGenerator;
  final FinancePortfolioV3Writer portfolioV3Writer;
  final FinancePrepaidCreationBuilder prepaidCreationBuilder;
  final FiniteFinancialPlanPersistence finiteFinancialPlanPersistence;
  final ExpectedExpensePersistence expectedExpensePersistence;
  final DocumentaryObligationPersistence documentaryObligationPersistence;
  final IncomePersistence incomePersistence;

  FinanceStore({
    EconomicFactIdGenerator? economicFactIdGenerator,
    FinancePortfolioV3Writer? portfolioV3Writer,
    FinancePrepaidCreationBuilder? prepaidCreationBuilder,
    FiniteFinancialPlanPersistence? finiteFinancialPlanPersistence,
    ExpectedExpensePersistence? expectedExpensePersistence,
    DocumentaryObligationPersistence? documentaryObligationPersistence,
    IncomePersistence? incomePersistence,
    Iterable<FinanceBalance> initialBalances = const [],
    Iterable<FinanceAccountLinkedItem> initialLinkedItems = const [],
    Iterable<FinanceTransaction> initialTransactions = const [],
    Iterable<FinanceRecurringItem> initialRecurringItems = const [],
    Iterable<FinanceSnapshot> initialSnapshots = const [],
    Iterable<FinanceFund> initialFunds = const [],
    Iterable<FundTransaction> initialFundTransactions = const [],
    Iterable<FinanceAssetMovement> initialAssetMovements = const [],
    Iterable<FiniteFinancialPlan> initialFiniteFinancialPlans = const [],
    ExpectedExpenseAggregate? initialExpectedExpenseAggregate,
    DocumentaryObligationAggregate? initialDocumentaryObligationAggregate,
    IncomeAggregate? initialIncomeAggregate,
  }) : economicFactIdGenerator =
           economicFactIdGenerator ?? EconomicFactIdGenerator.timestamped(),
       portfolioV3Writer = portfolioV3Writer ?? FinancePortfolioV3Writer(),
       prepaidCreationBuilder =
           prepaidCreationBuilder ?? FinancePrepaidCreationBuilder(),
       finiteFinancialPlanPersistence =
           finiteFinancialPlanPersistence ?? FiniteFinancialPlanPersistence(),
       expectedExpensePersistence =
           expectedExpensePersistence ?? ExpectedExpensePersistence(),
       documentaryObligationPersistence =
           documentaryObligationPersistence ??
           DocumentaryObligationPersistence(),
       incomePersistence = incomePersistence ?? IncomePersistence(),
       _balances = List<FinanceBalance>.of(initialBalances),
       _linkedItems = List<FinanceAccountLinkedItem>.of(initialLinkedItems),
       _transactions = List<FinanceTransaction>.of(initialTransactions),
       _recurringItems = List<FinanceRecurringItem>.of(initialRecurringItems),
       _snapshots = List<FinanceSnapshot>.of(initialSnapshots),
       _funds = List<FinanceFund>.of(initialFunds),
       _fundTransactions = List<FundTransaction>.of(initialFundTransactions),
       _assetMovements = List<FinanceAssetMovement>.of(initialAssetMovements),
       _finiteFinancialPlans = List<FiniteFinancialPlan>.of(
         initialFiniteFinancialPlans,
       ),
       _expectedExpenseAggregate =
           initialExpectedExpenseAggregate ?? ExpectedExpenseAggregate.empty(),
       _documentaryObligationAggregate =
           initialDocumentaryObligationAggregate ??
           DocumentaryObligationAggregate.empty(),
       _incomeAggregate = initialIncomeAggregate ?? IncomeAggregate.empty();

  final List<FinancePerson> people = const [
    FinancePerson(id: 'matteo', name: 'Matteo'),
    FinancePerson(id: 'chiara', name: 'Chiara'),
    FinancePerson(id: 'alice', name: 'Alice'),
  ];

  final List<FinanceBalance> _balances;
  final List<FinanceFund> _funds;
  final List<FinanceRecurringItem> _recurringItems;
  final List<FinanceSnapshot> _snapshots;
  final List<FundTransaction> _fundTransactions;
  final List<FinanceTransaction> _transactions;
  final List<FinanceAccountLinkedItem> _linkedItems;
  final List<FinanceAssetMovement> _assetMovements;
  final List<FiniteFinancialPlan> _finiteFinancialPlans;
  ExpectedExpenseAggregate _expectedExpenseAggregate;
  DocumentaryObligationAggregate _documentaryObligationAggregate;
  IncomeAggregate _incomeAggregate;
  bool _portfolioReady = false;
  bool _portfolioV3Authoritative = false;
  bool _legacyLinkedItemsHydrated = false;
  int _notificationBatchDepth = 0;
  bool _hasPendingNotification = false;
  bool _isDisposed = false;

  UnmodifiableListView<FinanceBalance> get balances =>
      UnmodifiableListView(_balances);

  UnmodifiableListView<FinanceAccountLinkedItem> get linkedItems =>
      UnmodifiableListView(_linkedItems);

  UnmodifiableListView<FinanceTransaction> get transactions =>
      UnmodifiableListView(_transactions);

  UnmodifiableListView<FinanceRecurringItem> get recurringItems =>
      UnmodifiableListView(_recurringItems);

  UnmodifiableListView<FinanceSnapshot> get snapshots =>
      UnmodifiableListView(_snapshots);

  UnmodifiableListView<FinanceFund> get funds => UnmodifiableListView(_funds);

  UnmodifiableListView<FundTransaction> get fundTransactions =>
      UnmodifiableListView(_fundTransactions);

  UnmodifiableListView<FinanceAssetMovement> get assetMovements =>
      UnmodifiableListView(_assetMovements);

  UnmodifiableListView<FiniteFinancialPlan> get finiteFinancialPlans =>
      UnmodifiableListView(_finiteFinancialPlans);

  ExpectedExpenseAggregate get expectedExpenseAggregate =>
      _expectedExpenseAggregate;

  DocumentaryObligationAggregate get documentaryObligationAggregate =>
      _documentaryObligationAggregate;

  IncomeAggregate get incomeAggregate => _incomeAggregate;

  bool get isPortfolioV3Authoritative => _portfolioV3Authoritative;

  Future<T> runInNotificationBatch<T>(Future<T> Function() action) async {
    _notificationBatchDepth++;
    try {
      return await action();
    } finally {
      _notificationBatchDepth--;
      assert(_notificationBatchDepth >= 0);
      if (_notificationBatchDepth == 0 && _hasPendingNotification) {
        _hasPendingNotification = false;
        notifyListeners();
      }
    }
  }

  void _markChanged() {
    if (_isDisposed) return;
    if (_notificationBatchDepth > 0) {
      _hasPendingNotification = true;
      return;
    }
    notifyListeners();
  }

  Future<T> _runObservableLoad<T>(Future<T> Function() action) async {
    return runInNotificationBatch(() async {
      final before = _observableStateFingerprint();
      try {
        return await action();
      } finally {
        if (before != _observableStateFingerprint()) {
          _markChanged();
        }
      }
    });
  }

  String _observableStateFingerprint() => jsonEncode({
    'balances': _balances.map((item) => item.toJson()).toList(),
    'linkedItems': _linkedItems.map((item) => item.toJson()).toList(),
    'transactions': _transactions.map((item) => item.toJson()).toList(),
    'recurringItems': _recurringItems.map((item) => item.toJson()).toList(),
    'snapshots': _snapshots.map((item) => item.toJson()).toList(),
    'funds': _funds.map((item) => item.toJson()).toList(),
    'fundTransactions': _fundTransactions.map((item) => item.toJson()).toList(),
    'assetMovements': _assetMovements.map((item) => item.toJson()).toList(),
    'finiteFinancialPlans': _finiteFinancialPlans
        .map((item) => item.toJson())
        .toList(),
    'expectedExpenseRelationships': _expectedExpenseAggregate.relationships
        .map((item) => item.toJson())
        .toList(),
    'expectedExpenseOccurrences': _expectedExpenseAggregate.occurrences
        .map((item) => item.toJson())
        .toList(),
    'documentaryObligations': _documentaryObligationAggregate.obligations
        .map((item) => item.toJson())
        .toList(),
    'expectedDocuments': _documentaryObligationAggregate.expectedDocuments
        .map((item) => item.toJson())
        .toList(),
    'incomeRelationships': _incomeAggregate.relationships
        .map((item) => item.toJson())
        .toList(),
    'incomeOccurrences': _incomeAggregate.occurrences
        .map((item) => item.toJson())
        .toList(),
    'incomeReconciliations': _incomeAggregate.reconciliations
        .map((item) => item.toJson())
        .toList(),
    'incomeCustomCategories': _incomeAggregate.customCategories
        .map((item) => item.toJson())
        .toList(),
  });

  Future<void> loadSavedIncomes() => _runObservableLoad(_loadSavedIncomes);

  Future<void> _loadSavedIncomes() async {
    _incomeAggregate = await incomePersistence.load();
  }

  Future<bool> saveIncomeAggregate(IncomeAggregate candidate) async {
    final before = _incomeFingerprint(_incomeAggregate);
    final result = await incomePersistence.write(candidate);
    if (!result.isSuccess) {
      throw StateError('Income write failed: ${result.errors.join('; ')}');
    }
    final changed = before != _incomeFingerprint(candidate);
    _incomeAggregate = candidate;
    if (changed) _markChanged();
    return changed;
  }

  String _incomeFingerprint(IncomeAggregate aggregate) => jsonEncode({
    'relationships': aggregate.relationships
        .map((item) => item.toJson())
        .toList(),
    'occurrences': aggregate.occurrences.map((item) => item.toJson()).toList(),
    'reconciliations': aggregate.reconciliations
        .map((item) => item.toJson())
        .toList(),
    'customCategories': aggregate.customCategories
        .map((item) => item.toJson())
        .toList(),
  });

  Future<void> loadSavedDocumentaryObligations() =>
      _runObservableLoad(_loadSavedDocumentaryObligations);

  Future<void> _loadSavedDocumentaryObligations() async {
    _documentaryObligationAggregate = await documentaryObligationPersistence
        .load();
  }

  Future<bool> saveDocumentaryObligationAggregate(
    DocumentaryObligationAggregate candidate,
  ) async {
    final before = jsonEncode(
      _documentaryObligationAggregate.obligations
              .map((item) => item.toJson())
              .toList() +
          _documentaryObligationAggregate.expectedDocuments
              .map((item) => item.toJson())
              .toList(),
    );
    await documentaryObligationPersistence.write(candidate);
    final after = jsonEncode(
      candidate.obligations.map((item) => item.toJson()).toList() +
          candidate.expectedDocuments.map((item) => item.toJson()).toList(),
    );
    _documentaryObligationAggregate = candidate;
    if (before != after) _markChanged();
    return before != after;
  }

  Future<void> loadSavedExpectedExpenses() =>
      _runObservableLoad(_loadSavedExpectedExpenses);

  Future<void> _loadSavedExpectedExpenses() async {
    final loaded = await expectedExpensePersistence.load();
    _expectedExpenseAggregate = loaded;
  }

  Future<bool> saveExpectedExpenseAggregate(
    ExpectedExpenseAggregate candidate,
  ) async {
    final before = _expectedExpenseAggregateFingerprint(
      _expectedExpenseAggregate,
    );
    final result = await expectedExpensePersistence.write(candidate);
    if (!result.isSuccess) {
      throw StateError(
        'Expected expenses write failed: ${result.errors.join('; ')}',
      );
    }

    final changed = before != _expectedExpenseAggregateFingerprint(candidate);
    _expectedExpenseAggregate = candidate;
    if (changed) _markChanged();
    return changed;
  }

  String _expectedExpenseAggregateFingerprint(
    ExpectedExpenseAggregate aggregate,
  ) => jsonEncode({
    'relationships': aggregate.relationships
        .map((item) => item.toJson())
        .toList(),
    'occurrences': aggregate.occurrences.map((item) => item.toJson()).toList(),
  });

  Future<bool> addFiniteFinancialPlan(FiniteFinancialPlan plan) async {
    if (_finiteFinancialPlans.any((item) => item.id == plan.id)) return false;
    final candidate = [..._finiteFinancialPlans, plan];
    final result = await finiteFinancialPlanPersistence.write(candidate);
    if (!result.isSuccess) {
      throw StateError(
        'Finite financial plan write failed: ${result.errors.join('; ')}',
      );
    }
    _finiteFinancialPlans
      ..clear()
      ..addAll(candidate);
    _markChanged();
    return true;
  }

  Future<bool> updateFiniteFinancialPlan(FiniteFinancialPlan plan) async {
    final index = _finiteFinancialPlans.indexWhere(
      (item) => item.id == plan.id,
    );
    if (index == -1) return false;
    if (jsonEncode(_finiteFinancialPlans[index].toJson()) ==
        jsonEncode(plan.toJson())) {
      return false;
    }
    final candidate = List<FiniteFinancialPlan>.of(_finiteFinancialPlans);
    candidate[index] = plan;
    final result = await finiteFinancialPlanPersistence.write(candidate);
    if (!result.isSuccess) {
      throw StateError(
        'Finite financial plan write failed: ${result.errors.join('; ')}',
      );
    }
    _finiteFinancialPlans
      ..clear()
      ..addAll(candidate);
    _markChanged();
    return true;
  }

  Future<void> loadSavedFiniteFinancialPlans() =>
      _runObservableLoad(_loadSavedFiniteFinancialPlans);

  Future<void> _loadSavedFiniteFinancialPlans() async {
    final loaded = await finiteFinancialPlanPersistence.load();
    _finiteFinancialPlans
      ..clear()
      ..addAll(loaded);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> addBalance(FinanceBalance balance) async {
    if (_balances.any((item) => item.balanceId == balance.balanceId)) {
      return false;
    }
    if (_portfolioV3Authoritative) {
      await _commitBalanceCandidate([..._balances, balance]);
      return true;
    }
    _balances.add(balance);
    try {
      await saveBalances();
    } finally {
      _markChanged();
    }
    return true;
  }

  Future<bool> replaceBalance(FinanceBalance balance) async {
    final index = _balances.indexWhere(
      (item) => item.balanceId == balance.balanceId,
    );
    if (index == -1 || _sameBalance(_balances[index], balance)) return false;
    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[index] = balance;
      await _commitBalanceCandidate(candidateBalances);
      return true;
    }
    _balances[index] = balance;
    try {
      await saveBalances();
    } finally {
      _markChanged();
    }
    return true;
  }

  Future<void> _commitBalanceCandidate(
    Iterable<FinanceBalance> candidateBalances,
  ) async {
    final result = await commitPortfolioV3Candidate(
      (current) => FinancePortfolioV3(
        balances: candidateBalances,
        funds: current.funds,
        assetMovements: current.assetMovements,
        transactions: current.transactions,
        fundTransactions: current.fundTransactions,
        linkedItems: current.linkedItems,
      ),
    );
    if (!result.isSuccess) {
      throw StateError(
        'Finance V3 balance commit failed: ${result.errors.join('; ')}',
      );
    }
  }

  Future<bool> setBalanceActive(String balanceId, bool active) async {
    final index = _balances.indexWhere((item) => item.balanceId == balanceId);
    if (index == -1 || _balances[index].active == active) return false;
    final current = _balances[index];
    return replaceBalance(
      FinanceBalance(
        balanceId: current.balanceId,
        personId: current.personId,
        name: current.name,
        initialAmount: current.initialAmount,
        currentAmount: current.currentAmount,
        updatedAt: current.updatedAt,
        balanceType: current.balanceType,
        operational: current.operational,
        active: active,
        reservedAmount: current.reservedAmount,
        warningThreshold: current.warningThreshold,
        persistentStressDays: current.persistentStressDays,
        recoveryDays: current.recoveryDays,
      ),
    );
  }

  Future<bool> updateBalanceDetailsAndAmount({
    required FinanceBalance details,
    required double newAmount,
  }) async {
    final index = _balances.indexWhere(
      (item) => item.balanceId == details.balanceId,
    );
    if (index == -1) return false;
    final current = _balances[index];
    final profile = FinanceBalance(
      balanceId: current.balanceId,
      personId: details.personId,
      name: details.name,
      initialAmount: current.initialAmount,
      currentAmount: current.currentAmount,
      updatedAt: details.updatedAt,
      balanceType: details.balanceType,
      operational: details.operational,
      active: details.active,
      reservedAmount: details.reservedAmount,
      warningThreshold: details.warningThreshold,
      persistentStressDays: details.persistentStressDays,
      recoveryDays: details.recoveryDays,
    );
    final profileChanged = !_sameBalance(current, profile);
    final amountChanged = current.currentAmount != newAmount;
    if (!profileChanged && !amountChanged) return false;
    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      final candidateTransactions = List<FinanceTransaction>.of(_transactions);
      if (amountChanged) {
        candidateBalances[index] = _balanceWithAmount(profile, newAmount);
        candidateTransactions.add(
          _adjustmentTransaction(current, newAmount - current.currentAmount),
        );
      } else {
        candidateBalances[index] = profile;
      }
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return true;
    }
    _balances[index] = profile;
    if (amountChanged) {
      await updateBalance(balanceId: current.balanceId, newAmount: newAmount);
    } else {
      try {
        await saveBalances();
      } finally {
        _markChanged();
      }
    }
    return true;
  }

  Future<bool> addLinkedItem(FinanceAccountLinkedItem item) async {
    if (_linkedItems.any((current) => current.id == item.id)) return false;
    if (_portfolioV3Authoritative) {
      await _commitLinkedItemsCandidate([..._linkedItems, item]);
      return true;
    }
    _linkedItems.add(item);
    try {
      await saveLinkedItems();
    } finally {
      _markChanged();
    }
    return true;
  }

  Future<bool> replaceLinkedItem(FinanceAccountLinkedItem item) async {
    final index = _linkedItems.indexWhere((current) => current.id == item.id);
    if (index == -1 || _sameLinkedItem(_linkedItems[index], item)) {
      return false;
    }
    if (_portfolioV3Authoritative) {
      final candidateLinkedItems = List<FinanceAccountLinkedItem>.of(
        _linkedItems,
      );
      candidateLinkedItems[index] = item;
      await _commitLinkedItemsCandidate(candidateLinkedItems);
      return true;
    }
    _linkedItems[index] = item;
    try {
      await saveLinkedItems();
    } finally {
      _markChanged();
    }
    return true;
  }

  Future<void> _commitLinkedItemsCandidate(
    Iterable<FinanceAccountLinkedItem> candidateLinkedItems,
  ) async {
    final result = await commitPortfolioV3Candidate(
      (current) => FinancePortfolioV3(
        balances: current.balances,
        funds: current.funds,
        assetMovements: current.assetMovements,
        transactions: current.transactions,
        fundTransactions: current.fundTransactions,
        linkedItems: candidateLinkedItems,
      ),
    );
    if (!result.isSuccess) {
      throw StateError(
        'Finance V3 linked item commit failed: ${result.errors.join('; ')}',
      );
    }
  }

  Future<bool> setLinkedItemActive(String itemId, bool active) async {
    final index = _linkedItems.indexWhere((item) => item.id == itemId);
    if (index == -1 || _linkedItems[index].active == active) return false;
    return replaceLinkedItem(_linkedItems[index].copyWith(active: active));
  }

  Future<FinancePrepaidCreationResult> createLinkedPrepaid(
    FinancePrepaidCreationInput input,
  ) async {
    if (!_portfolioV3Authoritative) {
      return FinancePrepaidCreationResult.failed(
        failure: FinancePrepaidCreationFailure.v3Required,
        errors: const ['Finance Portfolio V3 must be authoritative'],
      );
    }
    final parent = _balances.where(
      (balance) => balance.balanceId == input.parentBalanceId,
    );
    if (parent.isEmpty) {
      return FinancePrepaidCreationResult.failed(
        failure: FinancePrepaidCreationFailure.parentNotFound,
        errors: ['Parent balance not found: ${input.parentBalanceId}'],
      );
    }
    if (parent.single.personId != input.personId) {
      return FinancePrepaidCreationResult.failed(
        failure: FinancePrepaidCreationFailure.personMismatch,
        errors: [
          'Person ${input.personId} does not own parent balance '
              '${input.parentBalanceId}',
        ],
      );
    }

    final records = prepaidCreationBuilder.build(input);
    final result = await commitPortfolioV3Candidate(
      (current) => FinancePortfolioV3(
        balances: [...current.balances, records.balance],
        funds: current.funds,
        assetMovements: current.assetMovements,
        transactions: current.transactions,
        fundTransactions: current.fundTransactions,
        linkedItems: [...current.linkedItems, records.linkedItem],
      ),
    );
    if (!result.isSuccess) {
      return FinancePrepaidCreationResult.failed(
        failure: FinancePrepaidCreationFailure.commitFailed,
        errors: result.errors,
      );
    }
    return FinancePrepaidCreationResult.success(records);
  }

  Future<FinancePortfolioV3CommitResult> updateLinkedPrepaidPair({
    required String linkedItemId,
    required String name,
    required String description,
    required DateTime? expirationDate,
    required double? amount,
  }) async {
    if (!isPortfolioV3Authoritative) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: const ['Finance Portfolio V3 must be authoritative'],
      );
    }

    final linkedIndex = _linkedItems.indexWhere(
      (item) => item.id == linkedItemId,
    );
    if (linkedIndex == -1) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Linked prepaid not found: $linkedItemId'],
      );
    }

    final linked = _linkedItems[linkedIndex];
    if (linked.type != FinanceAccountLinkedItemType.prepaidCard) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Linked item is not prepaidCard: $linkedItemId'],
      );
    }

    final autonomousBalanceId = linked.autonomousBalanceId;
    if (autonomousBalanceId == null) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Linked prepaid has no autonomous balance: $linkedItemId'],
      );
    }

    final balanceIndex = _balances.indexWhere(
      (balance) => balance.balanceId == autonomousBalanceId,
    );
    if (balanceIndex == -1) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Autonomous prepaid balance not found: $autonomousBalanceId'],
      );
    }

    final autonomousBalance = _balances[balanceIndex];
    if (autonomousBalance.balanceType != FinanceBalanceType.prepaidCard) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Autonomous balance is not prepaidCard: $autonomousBalanceId'],
      );
    }

    return commitPortfolioV3Candidate((current) {
      final candidateBalances = List<FinanceBalance>.of(current.balances);
      candidateBalances[balanceIndex] = FinanceBalance(
        balanceId: autonomousBalance.balanceId,
        personId: autonomousBalance.personId,
        name: name,
        initialAmount: autonomousBalance.initialAmount,
        currentAmount: autonomousBalance.currentAmount,
        updatedAt: autonomousBalance.updatedAt,
        balanceType: autonomousBalance.balanceType,
        operational: autonomousBalance.operational,
        active: autonomousBalance.active,
        reservedAmount: autonomousBalance.reservedAmount,
        warningThreshold: autonomousBalance.warningThreshold,
        persistentStressDays: autonomousBalance.persistentStressDays,
        recoveryDays: autonomousBalance.recoveryDays,
      );

      final candidateLinkedItems = List<FinanceAccountLinkedItem>.of(
        current.linkedItems,
      );
      candidateLinkedItems[linkedIndex] = FinanceAccountLinkedItem(
        id: linked.id,
        balanceId: linked.balanceId,
        autonomousBalanceId: autonomousBalanceId,
        type: linked.type,
        name: name,
        description: description,
        expirationDate: expirationDate,
        amount: amount,
        active: linked.active,
      );

      return FinancePortfolioV3(
        balances: candidateBalances,
        funds: current.funds,
        assetMovements: current.assetMovements,
        transactions: current.transactions,
        fundTransactions: current.fundTransactions,
        linkedItems: candidateLinkedItems,
      );
    });
  }

  bool _sameBalance(FinanceBalance left, FinanceBalance right) =>
      left.balanceId == right.balanceId &&
      left.personId == right.personId &&
      left.name == right.name &&
      left.initialAmount == right.initialAmount &&
      left.currentAmount == right.currentAmount &&
      left.updatedAt == right.updatedAt &&
      left.balanceType == right.balanceType &&
      left.operational == right.operational &&
      left.active == right.active &&
      left.reservedAmount == right.reservedAmount &&
      left.warningThreshold == right.warningThreshold &&
      left.persistentStressDays == right.persistentStressDays &&
      left.recoveryDays == right.recoveryDays;

  bool _sameLinkedItem(
    FinanceAccountLinkedItem left,
    FinanceAccountLinkedItem right,
  ) =>
      left.id == right.id &&
      left.balanceId == right.balanceId &&
      left.autonomousBalanceId == right.autonomousBalanceId &&
      left.type == right.type &&
      left.name == right.name &&
      left.description == right.description &&
      left.expirationDate == right.expirationDate &&
      left.amount == right.amount &&
      left.active == right.active;

  double totalBalance() {
    return balances
        .where((balance) => balance.active)
        .fold(0.0, (sum, balance) => sum + balance.availableAmount);
  }

  double grossTotalBalance() {
    return balances.fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  double operationalBalance() {
    return balances
        .where((balance) => balance.operational)
        .fold(0.0, (sum, balance) => sum + balance.availableAmount);
  }

  bool hasOperationalWarning() {
    return balances.any(
      (balance) => balance.operational && balance.isUnderWarning,
    );
  }

  double operationalStressRatio() {
    final total = operationalBalance();

    if (total <= 0) {
      return 1;
    }

    final reserved = balances
        .where((b) => b.operational)
        .fold(0.0, (sum, balance) => sum + balance.reservedAmount);

    return reserved / total;
  }

  String operationalStressLevel() {
    final ratio = operationalStressRatio();

    if (ratio >= 1.0) {
      return 'apnea';
    }

    if (ratio >= 0.75) {
      return 'critical';
    }

    if (ratio >= 0.50) {
      return 'warning';
    }

    if (ratio >= 0.25) {
      return 'attention';
    }

    return 'stable';
  }

  bool isOperationalStressCritical() {
    final level = operationalStressLevel();

    return level == 'critical' || level == 'apnea';
  }

  double totalFunds() {
    return funds.fold(0.0, (sum, fund) => sum + fund.amount);
  }

  double familyNetWorth() => grossTotalBalance() + totalFunds();

  double projectedMonthlyExpenses() {
    return recurringItems
        .where((item) => !item.isIncome)
        .fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double projectedMonthlyIncome() {
    return recurringItems
        .where((item) => item.isIncome)
        .fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double projectedMonthlyMargin() {
    return projectedMonthlyIncome() - projectedMonthlyExpenses();
  }

  double availableThisMonth() {
    final monthItems = itemsForProjectionMonth(DateTime.now());

    double income = 0;
    double expenses = 0;

    for (final item in monthItems) {
      if (item.isIncome) {
        income += item.expectedAmount;
      } else {
        expenses += item.expectedAmount;
      }
    }

    return income - expenses;
  }

  double availableThisMonthForOwner(FinancePaymentOwner owner) {
    final monthItems = itemsForProjectionMonth(DateTime.now());

    final personId = owner.name;

    double forecast = balanceForPerson(personId);

    for (final item in monthItems) {
      if (item.confirmed) continue;

      double amount = 0;

      if (item.hasCustomSplits) {
        for (final split in item.splits) {
          if (split.personId == personId) {
            amount += split.amount;
          }
        }
      } else {
        if (item.paymentOwner == owner) {
          amount = item.expectedAmount;
        } else if (item.paymentOwner == FinancePaymentOwner.shared) {
          amount = item.expectedAmount / 2;
        }
      }

      if (item.isIncome) {
        forecast += amount;
      } else {
        forecast -= amount;
      }
    }

    return forecast;
  }

  bool isRecurringItemDueToday(FinanceRecurringItem item) {
    final now = DateTime.now();

    return item.nextDueDate.year == now.year &&
        item.nextDueDate.month == now.month &&
        item.nextDueDate.day == now.day;
  }

  bool isRecurringItemOverdue(FinanceRecurringItem item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueDay = DateTime(
      item.nextDueDate.year,
      item.nextDueDate.month,
      item.nextDueDate.day,
    );

    return dueDay.isBefore(today) && !item.confirmed;
  }

  bool isRecurringItemUpcoming(
    FinanceRecurringItem item, {
    int withinDays = 7,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueDay = DateTime(
      item.nextDueDate.year,
      item.nextDueDate.month,
      item.nextDueDate.day,
    );

    final limit = today.add(Duration(days: withinDays));

    return !item.confirmed &&
        dueDay.isAfter(today) &&
        (dueDay.isBefore(limit) || dueDay == limit);
  }

  DateTime nextDueDateAfterConfirmation(FinanceRecurringItem item) {
    final base = item.nextDueDate;

    switch (item.recurringType) {
      case FinanceRecurringType.monthly:
        return DateTime(base.year, base.month + 1, base.day);

      case FinanceRecurringType.yearly:
        return DateTime(base.year + 1, base.month, base.day);

      case FinanceRecurringType.oneShot:
        return base;

      case FinanceRecurringType.custom:
        final interval = item.customInterval ?? 1;
        final unit = item.customIntervalUnit ?? 'months';

        if (unit == 'days') {
          return base.add(Duration(days: interval));
        }

        if (unit == 'years') {
          return DateTime(base.year + interval, base.month, base.day);
        }

        return DateTime(base.year, base.month + interval, base.day);
    }
  }

  bool isUnderPressure() {
    return projectedMonthlyMargin() < 0;
  }

  int _priorityWeight(FinancePaymentPriority priority) {
    switch (priority) {
      case FinancePaymentPriority.low:
        return 1;

      case FinancePaymentPriority.normal:
        return 2;

      case FinancePaymentPriority.high:
        return 3;

      case FinancePaymentPriority.critical:
        return 4;
    }
  }

  List<FinanceRecurringItem> pastRecurringItems() {
    final items = recurringItems.where((item) => item.confirmed).toList();

    items.sort((a, b) {
      final dateCompare = b.nextDueDate.compareTo(a.nextDueDate);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));
    });

    return items;
  }

  List<FinanceRecurringItem> presentRecurringItems() {
    final items = recurringItems.where((item) {
      return !item.confirmed &&
          (isRecurringItemDueToday(item) || isRecurringItemOverdue(item));
    }).toList();

    items.sort((a, b) {
      final priorityCompare = _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.nextDueDate.compareTo(b.nextDueDate);
    });

    return items;
  }

  List<FinanceRecurringItem> futureRecurringItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = recurringItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return !item.confirmed && dueDay.isAfter(today);
    }).toList();

    items.sort((a, b) {
      final priorityCompare = _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.nextDueDate.compareTo(b.nextDueDate);
    });

    return items;
  }

  FinanceSnapshot createSnapshot(DateTime date) {
    return FinanceSnapshot(
      date: date,
      totalBalance: totalBalance(),
      totalFunds: totalFunds(),
      familyNetWorth: familyNetWorth(),
      projectedMonthlyIncome: projectedMonthlyIncome(),
      projectedMonthlyExpenses: projectedMonthlyExpenses(),
      projectedMonthlyMargin: projectedMonthlyMargin(),
      underPressure: isUnderPressure(),
      operationalBalance: operationalBalance(),
      operationalStressRatio: operationalStressRatio(),
      operationalStressLevel: operationalStressLevel(),
      vitalityState: balances.isEmpty ? 'stable' : balances.first.vitalityState,
      economicTrend: economicHealthTrend(),
      resilienceRatio: balances.isEmpty ? 1 : balances.first.resilienceRatio,
      recovering: balances.isNotEmpty && balances.first.isRecovering,
      fatigued: balances.isNotEmpty && balances.first.isFatigued,
      degrading: balances.isNotEmpty && balances.first.isDegrading,
      losingControl: balances.isNotEmpty && balances.first.isLosingControl,
      drowning: balances.isNotEmpty && balances.first.isDrowning,
    );
  }

  Future<void> saveSnapshot(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);

    final snapshot = createSnapshot(day);

    final existingIndex = snapshots.indexWhere((s) {
      final existingDay = DateTime(s.date.year, s.date.month, s.date.day);

      return existingDay == day;
    });

    if (existingIndex == -1) {
      _snapshots.add(snapshot);
    } else {
      if (jsonEncode(_snapshots[existingIndex].toJson()) ==
          jsonEncode(snapshot.toJson())) {
        return;
      }
      _snapshots[existingIndex] = snapshot;
    }

    try {
      await saveSnapshots();
    } finally {
      _markChanged();
    }
  }

  FinanceSnapshot? latestSnapshot() {
    if (snapshots.isEmpty) {
      return null;
    }

    return snapshots.last;
  }

  String economicHealthTrend() {
    if (snapshots.length < 3) {
      return 'unknown';
    }

    final recent = snapshots.sublist(snapshots.length - 3);

    final criticalCount = recent
        .where((snapshot) => snapshot.drowning || snapshot.losingControl)
        .length;

    if (criticalCount >= 1) {
      return 'critical';
    }

    final degradingCount = recent
        .where((snapshot) => snapshot.degrading)
        .length;

    if (degradingCount >= 2) {
      return 'worsening';
    }

    final fatiguedCount = recent.where((snapshot) => snapshot.fatigued).length;

    if (fatiguedCount >= 2) {
      return 'fatigued';
    }

    final recoveringCount = recent
        .where((snapshot) => snapshot.recovering)
        .length;

    if (recoveringCount >= 2) {
      return 'recovering';
    }

    final pressureCount = recent
        .where((snapshot) => snapshot.underPressure)
        .length;

    if (pressureCount == 0) {
      return 'stable';
    }

    return 'watch';
  }

  double balanceForPerson(String personId) {
    return balances
        .where((balance) => balance.personId == personId && balance.active)
        .fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  Future<void> updateBalance({
    required String balanceId,
    required double newAmount,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];
    final difference = newAmount - old.currentAmount;

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[index] = _balanceWithAmount(old, newAmount);
      final candidateTransactions = List<FinanceTransaction>.of(_transactions);
      if (difference != 0) {
        candidateTransactions.add(_adjustmentTransaction(old, difference));
      }
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    _balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      active: old.active,
      initialAmount: old.initialAmount,
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    if (difference != 0) {
      _transactions.add(
        FinanceTransaction(
          id: 'adjustment_${DateTime.now().microsecondsSinceEpoch}',
          balanceId: old.balanceId,
          amount: difference.abs(),
          date: DateTime.now(),
          isIncome: difference > 0,
          subject: _subjectForPersonId(old.personId),
          description: 'Correzione saldo ${old.name}',
          type: difference > 0
              ? FinanceTransactionType.income
              : FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.adjustment,
          economicFactId: economicFactIdGenerator.next(),
          notes: 'Saldo modificato manualmente',
        ),
      );
    }

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  FinanceBalance _balanceWithAmount(FinanceBalance current, double newAmount) =>
      FinanceBalance(
        balanceId: current.balanceId,
        personId: current.personId,
        name: current.name,
        active: current.active,
        initialAmount: current.initialAmount,
        currentAmount: newAmount,
        updatedAt: DateTime.now(),
        balanceType: current.balanceType,
        operational: current.operational,
        reservedAmount: current.reservedAmount,
        warningThreshold: current.warningThreshold,
        persistentStressDays: current.persistentStressDays,
        recoveryDays: current.recoveryDays,
      );

  FinanceTransaction _adjustmentTransaction(
    FinanceBalance balance,
    double difference,
  ) => FinanceTransaction(
    id: 'adjustment_${DateTime.now().microsecondsSinceEpoch}',
    balanceId: balance.balanceId,
    amount: difference.abs(),
    date: DateTime.now(),
    isIncome: difference > 0,
    subject: _subjectForPersonId(balance.personId),
    description: 'Correzione saldo ${balance.name}',
    type: difference > 0
        ? FinanceTransactionType.income
        : FinanceTransactionType.expense,
    origin: FinanceTransactionOrigin.adjustment,
    economicFactId: economicFactIdGenerator.next(),
    notes: 'Saldo modificato manualmente',
  );

  Future<void> _commitBalanceAndTransactionsCandidate({
    required Iterable<FinanceBalance> candidateBalances,
    required Iterable<FinanceTransaction> candidateTransactions,
  }) async {
    final result = await commitPortfolioV3Candidate(
      (current) => FinancePortfolioV3(
        balances: candidateBalances,
        funds: current.funds,
        assetMovements: current.assetMovements,
        transactions: candidateTransactions,
        fundTransactions: current.fundTransactions,
        linkedItems: current.linkedItems,
      ),
    );
    if (!result.isSuccess) {
      throw StateError(
        'Finance V3 balance adjustment commit failed: '
        '${result.errors.join('; ')}',
      );
    }
  }

  Future<void> registerRealExpense({
    required String balanceId,
    required double amount,
    required String description,
    String? notes,
    String? economicFactId,
    DateTime? occurredAt,
    String? transactionId,
    BalancePostingMode balancePostingMode =
        BalancePostingMode.affectsCurrentBalance,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      if (balancePostingMode == BalancePostingMode.affectsCurrentBalance) {
        candidateBalances[index] = _balanceWithAmount(
          old,
          old.currentAmount - amount,
        );
      }
      final candidateTransactions = List<FinanceTransaction>.of(_transactions)
        ..add(
          FinanceTransaction(
            id:
                transactionId ??
                'real_expense_${DateTime.now().microsecondsSinceEpoch}',
            balanceId: old.balanceId,
            amount: amount,
            date: occurredAt ?? DateTime.now(),
            isIncome: false,
            subject: _subjectForPersonId(old.personId),
            description: description,
            type: FinanceTransactionType.expense,
            origin: FinanceTransactionOrigin.manual,
            notes: notes,
            economicFactId: economicFactId ?? economicFactIdGenerator.next(),
            balancePostingMode: balancePostingMode,
          ),
        );
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    if (balancePostingMode == BalancePostingMode.affectsCurrentBalance) {
      _balances[index] = FinanceBalance(
        balanceId: old.balanceId,
        personId: old.personId,
        name: old.name,
        active: old.active,
        initialAmount: old.initialAmount,
        currentAmount: old.currentAmount - amount,
        updatedAt: DateTime.now(),
        balanceType: old.balanceType,
        operational: old.operational,
        reservedAmount: old.reservedAmount,
        warningThreshold: old.warningThreshold,
        persistentStressDays: old.persistentStressDays,
        recoveryDays: old.recoveryDays,
      );
    }

    _transactions.add(
      FinanceTransaction(
        id:
            transactionId ??
            'real_expense_${DateTime.now().microsecondsSinceEpoch}',
        balanceId: old.balanceId,
        amount: amount,
        date: occurredAt ?? DateTime.now(),
        isIncome: false,
        subject: _subjectForPersonId(old.personId),
        description: description,
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
        notes: notes,
        economicFactId: economicFactId ?? economicFactIdGenerator.next(),
        balancePostingMode: balancePostingMode,
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> registerExtraIncome({
    required String balanceId,
    required double amount,
    required String description,
    String? notes,
    String? economicFactId,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[index] = _balanceWithAmount(
        old,
        old.currentAmount + amount,
      );
      final candidateTransactions = List<FinanceTransaction>.of(_transactions)
        ..add(
          FinanceTransaction(
            id: 'extra_income_${DateTime.now().microsecondsSinceEpoch}',
            balanceId: old.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: true,
            subject: _subjectForPersonId(old.personId),
            description: description,
            type: FinanceTransactionType.income,
            origin: FinanceTransactionOrigin.manual,
            notes: notes,
            economicFactId: economicFactId ?? economicFactIdGenerator.next(),
          ),
        );
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    _balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      active: old.active,
      initialAmount: old.initialAmount,
      currentAmount: old.currentAmount + amount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    _transactions.add(
      FinanceTransaction(
        id: 'extra_income_${DateTime.now().microsecondsSinceEpoch}',
        balanceId: old.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: true,
        subject: _subjectForPersonId(old.personId),
        description: description,
        type: FinanceTransactionType.income,
        origin: FinanceTransactionOrigin.manual,
        notes: notes,
        economicFactId: economicFactId ?? economicFactIdGenerator.next(),
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> removeExtraIncome({
    required String balanceId,
    required double amount,
    required String description,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[index] = _balanceWithAmount(
        old,
        old.currentAmount - amount,
      );
      final candidateTransactions = List<FinanceTransaction>.of(_transactions)
        ..add(
          FinanceTransaction(
            id: 'remove_extra_income_${DateTime.now().microsecondsSinceEpoch}',
            balanceId: old.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: false,
            subject: _subjectForPersonId(old.personId),
            description: "Annullamento $description",
            type: FinanceTransactionType.expense,
            origin: FinanceTransactionOrigin.manual,
            notes: 'Rimozione entrata extra',
            economicFactId: economicFactIdGenerator.next(),
          ),
        );
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    _balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      active: old.active,
      initialAmount: old.initialAmount,
      currentAmount: old.currentAmount - amount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    _transactions.add(
      FinanceTransaction(
        id: 'remove_extra_income_${DateTime.now().microsecondsSinceEpoch}',
        balanceId: old.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: false,
        subject: _subjectForPersonId(old.personId),
        description: "Annullamento $description",
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Rimozione entrata extra',
        economicFactId: economicFactIdGenerator.next(),
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> restoreRealExpense({
    required String balanceId,
    required double amount,
    required String description,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[index] = _balanceWithAmount(
        old,
        old.currentAmount + amount,
      );
      final candidateTransactions = List<FinanceTransaction>.of(_transactions)
        ..add(
          FinanceTransaction(
            id: 'restore_expense_${DateTime.now().microsecondsSinceEpoch}',
            balanceId: old.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: true,
            subject: _subjectForPersonId(old.personId),
            description: "Annullamento $description",
            type: FinanceTransactionType.income,
            origin: FinanceTransactionOrigin.manual,
            notes: 'Ripristino movimento eliminato',
            economicFactId: economicFactIdGenerator.next(),
            semanticRole: FinanceTransactionSemanticRole.balanceCompensation,
          ),
        );
      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    _balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      active: old.active,
      initialAmount: old.initialAmount,
      currentAmount: old.currentAmount + amount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    _transactions.add(
      FinanceTransaction(
        id: 'restore_expense_${DateTime.now().microsecondsSinceEpoch}',
        balanceId: old.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: true,
        subject: _subjectForPersonId(old.personId),
        description: "Annullamento $description",
        type: FinanceTransactionType.income,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Ripristino movimento eliminato',
        economicFactId: economicFactIdGenerator.next(),
        semanticRole: FinanceTransactionSemanticRole.balanceCompensation,
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> transferBetweenBalances({
    required String fromBalanceId,
    required String toBalanceId,
    required double amount,
    String description = 'Trasferimento',
  }) async {
    final fromIndex = balances.indexWhere((b) => b.balanceId == fromBalanceId);

    final toIndex = balances.indexWhere((b) => b.balanceId == toBalanceId);

    if (fromIndex == -1 || toIndex == -1) {
      return;
    }

    final fromBalance = balances[fromIndex];
    final toBalance = balances[toIndex];

    if (_portfolioV3Authoritative) {
      final candidateBalances = List<FinanceBalance>.of(_balances);
      candidateBalances[fromIndex] = FinanceBalance(
        balanceId: fromBalance.balanceId,
        personId: fromBalance.personId,
        name: fromBalance.name,
        active: fromBalance.active,
        initialAmount: fromBalance.initialAmount,
        currentAmount: fromBalance.currentAmount - amount,
        updatedAt: DateTime.now(),
        balanceType: fromBalance.balanceType,
        operational: fromBalance.operational,
        reservedAmount: fromBalance.reservedAmount,
        warningThreshold: fromBalance.warningThreshold,
        persistentStressDays: fromBalance.persistentStressDays,
        recoveryDays: fromBalance.recoveryDays,
      );
      candidateBalances[toIndex] = FinanceBalance(
        balanceId: toBalance.balanceId,
        personId: toBalance.personId,
        name: toBalance.name,
        active: toBalance.active,
        initialAmount: toBalance.initialAmount,
        currentAmount: toBalance.currentAmount + amount,
        updatedAt: DateTime.now(),
        balanceType: toBalance.balanceType,
        operational: toBalance.operational,
        reservedAmount: toBalance.reservedAmount,
        warningThreshold: toBalance.warningThreshold,
        persistentStressDays: toBalance.persistentStressDays,
        recoveryDays: toBalance.recoveryDays,
      );

      final transferId = DateTime.now().microsecondsSinceEpoch.toString();
      final economicFactId = economicFactIdGenerator.next();
      final candidateTransactions = List<FinanceTransaction>.of(_transactions)
        ..add(
          FinanceTransaction(
            id: 'transfer_out_$transferId',
            balanceId: fromBalance.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: false,
            subject: _subjectForPersonId(fromBalance.personId),
            description: description,
            type: FinanceTransactionType.transfer,
            origin: FinanceTransactionOrigin.manual,
            notes: 'Trasferimento verso ${toBalance.name}',
            economicFactId: economicFactId,
          ),
        )
        ..add(
          FinanceTransaction(
            id: 'transfer_in_$transferId',
            balanceId: toBalance.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: true,
            subject: _subjectForPersonId(toBalance.personId),
            description: description,
            type: FinanceTransactionType.transfer,
            origin: FinanceTransactionOrigin.manual,
            notes: 'Trasferimento da ${fromBalance.name}',
            economicFactId: economicFactId,
          ),
        );

      await _commitBalanceAndTransactionsCandidate(
        candidateBalances: candidateBalances,
        candidateTransactions: candidateTransactions,
      );
      return;
    }

    _balances[fromIndex] = FinanceBalance(
      balanceId: fromBalance.balanceId,
      personId: fromBalance.personId,
      name: fromBalance.name,
      active: fromBalance.active,
      initialAmount: fromBalance.initialAmount,
      currentAmount: fromBalance.currentAmount - amount,
      updatedAt: DateTime.now(),
      balanceType: fromBalance.balanceType,
      operational: fromBalance.operational,
      reservedAmount: fromBalance.reservedAmount,
      warningThreshold: fromBalance.warningThreshold,
      persistentStressDays: fromBalance.persistentStressDays,
      recoveryDays: fromBalance.recoveryDays,
    );

    _balances[toIndex] = FinanceBalance(
      balanceId: toBalance.balanceId,
      personId: toBalance.personId,
      name: toBalance.name,
      active: toBalance.active,
      initialAmount: toBalance.initialAmount,
      currentAmount: toBalance.currentAmount + amount,
      updatedAt: DateTime.now(),
      balanceType: toBalance.balanceType,
      operational: toBalance.operational,
      reservedAmount: toBalance.reservedAmount,
      warningThreshold: toBalance.warningThreshold,
      persistentStressDays: toBalance.persistentStressDays,
      recoveryDays: toBalance.recoveryDays,
    );

    final transferId = DateTime.now().microsecondsSinceEpoch.toString();
    final economicFactId = economicFactIdGenerator.next();

    _transactions.add(
      FinanceTransaction(
        id: 'transfer_out_$transferId',
        balanceId: fromBalance.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: false,
        subject: _subjectForPersonId(fromBalance.personId),
        description: description,
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Trasferimento verso ${toBalance.name}',
        economicFactId: economicFactId,
      ),
    );

    _transactions.add(
      FinanceTransaction(
        id: 'transfer_in_$transferId',
        balanceId: toBalance.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: true,
        subject: _subjectForPersonId(toBalance.personId),
        description: description,
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Trasferimento da ${fromBalance.name}',
        economicFactId: economicFactId,
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  void loadDemoData() {
    final before = _observableStateFingerprint();
    _balances
      ..clear()
      ..addAll(demoBalances);

    _funds
      ..clear()
      ..addAll(demoFunds);

    _recurringItems
      ..clear()
      ..addAll(demoRecurringItems);
    if (before != _observableStateFingerprint()) {
      _markChanged();
    }
  }

  Future<void> loadInitialRealData() =>
      _runObservableLoad(_loadInitialRealData);

  Future<void> _loadInitialRealData() async {
    if (await loadSavedPortfolioV3()) {
      await loadSavedRecurringItems();
      await loadSavedSnapshots();
      return;
    }
    if (await loadSavedPortfolio()) {
      await loadSavedRecurringItems();
      await loadSavedSnapshots();
      await loadSavedLinkedItems();
      return;
    }
    final now = DateTime.now();

    final loaded = await loadSavedBalances();

    if (loaded) {
      final allBalancesZero = balances.every((b) => b.currentAmount == 0);

      if (!allBalancesZero) {
        final fundsLoaded = await loadSavedFunds();
        await loadSavedFundTransactions();
        await loadSavedTransactions();
        await loadSavedSnapshots();
        await loadSavedLinkedItems();

        if (!fundsLoaded) {
          _funds
            ..clear()
            ..addAll(demoFunds);

          await saveFunds();
        }

        final recurringItemsLoaded = await loadSavedRecurringItems();

        if (!recurringItemsLoaded) {
          _recurringItems
            ..clear()
            ..addAll(demoRecurringItems);

          await saveRecurringItems();
        }

        await migrateLegacyPortfolio();
        return;
      }
      for (int i = 0; i < balances.length; i++) {
        final old = balances[i];

        if (old.name == old.balanceId) {
          _balances[i] = FinanceBalance(
            balanceId: old.balanceId,
            personId: old.personId,
            name: old.personId == 'matteo'
                ? 'Conto principale Matteo'
                : old.personId == 'chiara'
                ? 'Conto principale Chiara'
                : old.name,
            initialAmount: old.initialAmount,
            currentAmount: old.currentAmount,
            updatedAt: old.updatedAt,
            balanceType: old.balanceType,
            operational: old.operational,
            active: old.active,
            reservedAmount: old.reservedAmount,
            warningThreshold: old.warningThreshold,
            persistentStressDays: old.persistentStressDays,
            recoveryDays: old.recoveryDays,
          );
        }
      }

      await saveBalances();
    }

    _balances
      ..clear()
      ..addAll([
        FinanceBalance(
          balanceId: 'balance_matteo',
          personId: 'matteo',
          name: 'Conto principale Matteo',
          active: true,
          initialAmount: 993.32,
          currentAmount: 993.32,
          updatedAt: now,
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          reservedAmount: 0,
          warningThreshold: 200,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
        FinanceBalance(
          balanceId: 'balance_chiara',
          personId: 'chiara',
          name: 'Conto principale Chiara',
          active: true,
          initialAmount: 1400,
          currentAmount: 1400,
          updatedAt: now,
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          reservedAmount: 0,
          warningThreshold: 200,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
      ]);

    await saveBalances();

    final fundsLoaded = await loadSavedFunds();
    await loadSavedFundTransactions();
    await loadSavedTransactions();
    await loadSavedSnapshots();
    await loadSavedLinkedItems();

    if (!fundsLoaded) {
      _funds
        ..clear()
        ..addAll(demoFunds);

      await saveFunds();
    }

    _recurringItems
      ..clear()
      ..addAll(demoRecurringItems);
    await saveRecurringItems();
    await migrateLegacyPortfolio();
  }

  Future<bool> loadSavedPortfolio() => _runObservableLoad(_loadSavedPortfolio);

  Future<FinancePortfolioV3WriteResult> writePortfolioV3() {
    return portfolioV3Writer.write(
      FinancePortfolioV3(
        balances: balances,
        funds: funds,
        assetMovements: assetMovements,
        transactions: transactions,
        fundTransactions: fundTransactions,
        linkedItems: linkedItems,
      ),
    );
  }

  Future<FinancePortfolioV3PromotionResult> promotePortfolioV3() async {
    if (_portfolioV3Authoritative) {
      return FinancePortfolioV3PromotionResult.alreadyAuthoritative();
    }
    if (!_portfolioReady || !_legacyLinkedItemsHydrated) {
      return FinancePortfolioV3PromotionResult.failed(
        status: FinancePortfolioV3PromotionStatus.notReady,
        errors: const ['Finance portfolio is not ready for V3 promotion'],
      );
    }

    final candidate = FinancePortfolioV3(
      balances: List<FinanceBalance>.of(_balances),
      funds: List<FinanceFund>.of(_funds),
      assetMovements: List<FinanceAssetMovement>.of(_assetMovements),
      transactions: List<FinanceTransaction>.of(_transactions),
      fundTransactions: List<FundTransaction>.of(_fundTransactions),
      linkedItems: List<FinanceAccountLinkedItem>.of(_linkedItems),
    );
    final validation = FinancePortfolioV3Validator.validate(candidate);
    if (!validation.isValid) {
      return FinancePortfolioV3PromotionResult.failed(
        status: FinancePortfolioV3PromotionStatus.invalidCandidate,
        errors: validation.errors,
      );
    }

    final writeResult = await portfolioV3Writer.write(candidate);
    if (!writeResult.isSuccess) {
      return FinancePortfolioV3PromotionResult.failed(
        status: FinancePortfolioV3PromotionStatus.writerFailed,
        errors: writeResult.errors,
        writeResult: writeResult,
      );
    }

    _portfolioReady = false;
    _portfolioV3Authoritative = true;
    return FinancePortfolioV3PromotionResult.promoted(writeResult);
  }

  Future<FinancePortfolioV3CommitResult> commitPortfolioV3Candidate(
    FinancePortfolioV3Transformation transform,
  ) async {
    final current = FinancePortfolioV3(
      balances: _balances,
      funds: _funds,
      assetMovements: _assetMovements,
      transactions: _transactions,
      fundTransactions: _fundTransactions,
      linkedItems: _linkedItems,
    );

    late final FinancePortfolioV3 candidate;
    try {
      candidate = transform(current);
    } catch (error) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Portfolio V3 candidate transformation failed: $error'],
      );
    }

    final validation = FinancePortfolioV3Validator.validate(candidate);
    if (!validation.isValid) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.validationFailed,
        errors: validation.errors,
      );
    }

    final writeResult = await portfolioV3Writer.write(candidate);
    if (!writeResult.isSuccess) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.writerFailed,
        errors: writeResult.errors,
        writeResult: writeResult,
      );
    }

    _balances
      ..clear()
      ..addAll(candidate.balances);
    _funds
      ..clear()
      ..addAll(candidate.funds);
    _assetMovements
      ..clear()
      ..addAll(candidate.assetMovements);
    _transactions
      ..clear()
      ..addAll(candidate.transactions);
    _fundTransactions
      ..clear()
      ..addAll(candidate.fundTransactions);
    _linkedItems
      ..clear()
      ..addAll(candidate.linkedItems);
    _portfolioReady = false;
    _portfolioV3Authoritative = true;
    _markChanged();

    return FinancePortfolioV3CommitResult.success(writeResult);
  }

  Future<FinancePortfolioV3CommitResult> commitPortfolioV3CandidateVerified({
    required Map<String, dynamic> expectedCurrent,
    required FinancePortfolioV3Transformation transform,
  }) async {
    final current = FinancePortfolioV3(
      balances: _balances,
      funds: _funds,
      assetMovements: _assetMovements,
      transactions: _transactions,
      fundTransactions: _fundTransactions,
      linkedItems: _linkedItems,
    );
    if (jsonEncode(FinancePortfolioV3Contract.build(current)) !=
        jsonEncode(expectedCurrent)) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.snapshotConflict,
        errors: const [
          'Portfolio V3 memory differs from the expected snapshot',
        ],
      );
    }
    late final FinancePortfolioV3 candidate;
    try {
      candidate = transform(current);
    } catch (error) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.transformationFailed,
        errors: ['Portfolio V3 candidate transformation failed: $error'],
      );
    }
    final validation = FinancePortfolioV3Validator.validate(candidate);
    if (!validation.isValid) {
      return FinancePortfolioV3CommitResult.failed(
        failure: FinancePortfolioV3CommitFailure.validationFailed,
        errors: validation.errors,
      );
    }
    final writeResult = await portfolioV3Writer.writeIfCurrent(
      expectedCurrent: expectedCurrent,
      candidate: candidate,
    );
    if (!writeResult.isSuccess) {
      return FinancePortfolioV3CommitResult.failed(
        failure:
            writeResult.failure == FinancePortfolioV3WriteFailure.invalidPayload
            ? FinancePortfolioV3CommitFailure.snapshotConflict
            : FinancePortfolioV3CommitFailure.writerFailed,
        errors: writeResult.errors,
        writeResult: writeResult,
      );
    }
    _balances
      ..clear()
      ..addAll(candidate.balances);
    _funds
      ..clear()
      ..addAll(candidate.funds);
    _assetMovements
      ..clear()
      ..addAll(candidate.assetMovements);
    _transactions
      ..clear()
      ..addAll(candidate.transactions);
    _fundTransactions
      ..clear()
      ..addAll(candidate.fundTransactions);
    _linkedItems
      ..clear()
      ..addAll(candidate.linkedItems);
    _portfolioReady = false;
    _portfolioV3Authoritative = true;
    _markChanged();
    return FinancePortfolioV3CommitResult.success(writeResult);
  }

  Future<bool> loadSavedPortfolioV3() =>
      _runObservableLoad(_loadSavedPortfolioV3);

  Future<bool> _loadSavedPortfolioV3() async {
    final raw = await PersistenceStore.loadString('finance_portfolio_v3');
    if (raw == null || raw.isEmpty) {
      _portfolioV3Authoritative = false;
      return false;
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FormatException('Invalid Finance Portfolio V3: ${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Invalid Finance Portfolio V3: root must be an object',
      );
    }

    final result = FinancePortfolioV3Contract.parse(
      Map<String, dynamic>.from(decoded),
    );
    if (!result.isSuccess) {
      throw FormatException(
        'Invalid Finance Portfolio V3: ${result.errors.join('; ')}',
      );
    }

    final portfolio = result.value!;
    _balances
      ..clear()
      ..addAll(portfolio.balances);
    _funds
      ..clear()
      ..addAll(portfolio.funds);
    _assetMovements
      ..clear()
      ..addAll(portfolio.assetMovements);
    _transactions
      ..clear()
      ..addAll(portfolio.transactions);
    _fundTransactions
      ..clear()
      ..addAll(portfolio.fundTransactions);
    _linkedItems
      ..clear()
      ..addAll(portfolio.linkedItems);
    _portfolioReady = false;
    _portfolioV3Authoritative = true;
    return true;
  }

  Future<bool> _loadSavedPortfolio() async {
    final json = await PersistenceStore.loadJsonMap('finance_portfolio_v2');
    if (json == null || json['version'] != 2) {
      return false;
    }
    _balances
      ..clear()
      ..addAll(
        (json['balances'] as List).map(
          (item) => FinanceBalance.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    _funds
      ..clear()
      ..addAll(
        (json['funds'] as List).map(
          (item) => FinanceFund.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    _assetMovements
      ..clear()
      ..addAll(
        (json['assetMovements'] as List).map(
          (item) =>
              FinanceAssetMovement.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    _transactions
      ..clear()
      ..addAll(
        (json['transactions'] as List).map(
          (item) =>
              FinanceTransaction.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    _fundTransactions
      ..clear()
      ..addAll(
        (json['fundTransactions'] as List? ?? const []).map(
          (item) => FundTransaction.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    _portfolioReady = true;
    _portfolioV3Authoritative = false;
    return true;
  }

  Future<void> migrateLegacyPortfolio() =>
      _runObservableLoad(_migrateLegacyPortfolio);

  Future<void> _migrateLegacyPortfolio() async {
    if (assetMovements.isEmpty) {
      final migratedAt = DateTime.now();
      for (var index = 0; index < funds.length; index++) {
        final fund = funds[index];
        _funds[index] = FinanceFund(
          id: fund.id,
          name: fund.name,
          description: fund.description,
          amount: fund.amount,
          protected: fund.protected,
          category: fund.category,
          status: fund.status,
          openingKind: FinanceFundOpeningKind.legacyImported,
          openedAt: fund.openedAt ?? migratedAt,
          closedAt: fund.closedAt,
        );
        if (fund.amount > 0) {
          _assetMovements.add(
            FinanceAssetMovement(
              id: 'legacy_${fund.id}',
              fundId: fund.id,
              kind: FinanceAssetMovementKind.legacyOpening,
              description: 'Saldo precedente',
              occurredAt: migratedAt,
              legs: [
                FinanceAssetLeg(
                  type: FinanceAssetLegType.openingBalance,
                  delta: -fund.amount,
                ),
                FinanceAssetLeg(
                  type: FinanceAssetLegType.fund,
                  referenceId: fund.id,
                  delta: fund.amount,
                ),
              ],
            ),
          );
        }
      }
    }
    final migratedIds = assetMovements.map((item) => item.id).toSet();
    for (final transaction in fundTransactions) {
      final movementId = 'legacy_fund_tx_${transaction.id}';
      if (migratedIds.contains(movementId)) continue;
      final fundDelta = transaction.type == FundTransactionType.deposit
          ? transaction.amount
          : -transaction.amount;
      _assetMovements.add(
        FinanceAssetMovement(
          id: movementId,
          fundId: transaction.fundId,
          kind: FinanceAssetMovementKind.legacyUnclassified,
          description: transaction.description.isEmpty
              ? 'Operazione precedente'
              : transaction.description,
          occurredAt: transaction.date,
          legs: [
            FinanceAssetLeg(
              type: FinanceAssetLegType.legacyCounterpart,
              delta: -fundDelta,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: transaction.fundId,
              delta: fundDelta,
            ),
          ],
        ),
      );
    }
    _portfolioReady = true;
    await savePortfolio();
  }

  Future<void> savePortfolio() => PersistenceStore.saveJsonMap(
    'finance_portfolio_v2',
    _portfolioJson(balances, funds, assetMovements, transactions),
  );

  Future<void> commitFundPlan(FinanceFundMutationPlan plan) async {
    final current = jsonEncode(
      _portfolioJson(balances, funds, assetMovements, transactions),
    );
    final next = jsonEncode(
      _portfolioJson(
        plan.balances,
        plan.funds,
        plan.movements,
        plan.transactions,
      ),
    );
    if (current == next) return;

    if (_portfolioV3Authoritative) {
      final result = await commitPortfolioV3Candidate(
        (current) => FinancePortfolioV3(
          balances: plan.balances,
          funds: plan.funds,
          assetMovements: plan.movements,
          transactions: plan.transactions,
          fundTransactions: current.fundTransactions,
          linkedItems: current.linkedItems,
        ),
      );
      if (!result.isSuccess) {
        throw StateError(
          'Finance V3 fund plan commit failed: ${result.errors.join('; ')}',
        );
      }
      return;
    }

    await runInNotificationBatch(() async {
      _balances
        ..clear()
        ..addAll(plan.balances);
      _funds
        ..clear()
        ..addAll(plan.funds);
      _assetMovements
        ..clear()
        ..addAll(plan.movements);
      _transactions
        ..clear()
        ..addAll(plan.transactions);
      try {
        await savePortfolio();
        _portfolioReady = true;
      } finally {
        _markChanged();
      }
    });
  }

  Map<String, dynamic> _portfolioJson(
    List<FinanceBalance> nextBalances,
    List<FinanceFund> nextFunds,
    List<FinanceAssetMovement> nextMovements,
    List<FinanceTransaction> nextTransactions,
  ) => {
    'version': 2,
    'balances': nextBalances.map((item) => item.toJson()).toList(),
    'funds': nextFunds.map((item) => item.toJson()).toList(),
    'assetMovements': nextMovements.map((item) => item.toJson()).toList(),
    'transactions': nextTransactions.map((item) => item.toJson()).toList(),
    'fundTransactions': fundTransactions.map((item) => item.toJson()).toList(),
  };

  Future<void> saveBalances() async {
    final jsonList = balances.map((b) => b.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_balances', jsonList);
    if (_portfolioReady) await savePortfolio();
  }

  Future<bool> loadSavedBalances() => _runObservableLoad(_loadSavedBalances);

  Future<bool> _loadSavedBalances() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_balances');

    if (jsonList.isEmpty) {
      return false;
    }

    _balances
      ..clear()
      ..addAll(jsonList.map(FinanceBalance.fromJson));

    return true;
  }

  Future<bool> loadSavedFunds() => _runObservableLoad(_loadSavedFunds);

  Future<bool> _loadSavedFunds() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_funds');

    if (jsonList.isEmpty) {
      return false;
    }

    _funds
      ..clear()
      ..addAll(jsonList.map(FinanceFund.fromJson));

    return true;
  }

  Future<bool> loadSavedFundTransactions() =>
      _runObservableLoad(_loadSavedFundTransactions);

  Future<bool> _loadSavedFundTransactions() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_fund_transactions',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    _fundTransactions
      ..clear()
      ..addAll(jsonList.map(FundTransaction.fromJson));

    return true;
  }

  Future<void> saveTransactions() async {
    final jsonList = transactions.map((t) => t.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_transactions', jsonList);
    if (_portfolioReady) await savePortfolio();
  }

  Future<void> saveLinkedItems() async {
    final jsonList = linkedItems.map((item) => item.toJson()).toList();

    await PersistenceStore.saveJsonList(
      'finance_account_linked_items',
      jsonList,
    );
  }

  Future<bool> loadSavedLinkedItems() =>
      _runObservableLoad(_loadSavedLinkedItems);

  Future<bool> _loadSavedLinkedItems() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_account_linked_items',
    );
    _legacyLinkedItemsHydrated = true;

    if (jsonList.isEmpty) {
      return false;
    }

    _linkedItems
      ..clear()
      ..addAll(jsonList.map(FinanceAccountLinkedItem.fromJson));

    return true;
  }

  Future<void> saveSnapshots() async {
    final jsonList = snapshots.map((s) => s.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_snapshots', jsonList);
  }

  Future<bool> loadSavedTransactions() =>
      _runObservableLoad(_loadSavedTransactions);

  Future<bool> _loadSavedTransactions() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_transactions',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    _transactions
      ..clear()
      ..addAll(jsonList.map(FinanceTransaction.fromJson));

    return true;
  }

  Future<bool> loadSavedSnapshots() => _runObservableLoad(_loadSavedSnapshots);

  Future<bool> _loadSavedSnapshots() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_snapshots');

    if (jsonList.isEmpty) {
      return false;
    }

    _snapshots
      ..clear()
      ..addAll(jsonList.map(FinanceSnapshot.fromJson));

    return true;
  }

  @Deprecated('Usa FinanceFundLifecycleCoordinator')
  Future<void> updateFundAmount({
    required String fundId,
    required double newAmount,
  }) async {
    final index = funds.indexWhere((f) => f.id == fundId);

    if (index == -1) {
      return;
    }

    final old = funds[index];
    if (old.amount == newAmount) return;

    _funds[index] = FinanceFund(
      id: old.id,
      name: old.name,
      description: old.description,
      amount: newAmount,
      protected: old.protected,
      category: old.category,
    );

    try {
      await saveFunds();
    } finally {
      _markChanged();
    }
  }

  Future<void> updateFund(FinanceFund updatedFund) async {
    final index = funds.indexWhere((f) => f.id == updatedFund.id);

    if (index == -1 ||
        jsonEncode(funds[index].toJson()) == jsonEncode(updatedFund.toJson())) {
      return;
    }

    _funds[index] = updatedFund;

    try {
      await saveFunds();
    } finally {
      _markChanged();
    }
  }

  @Deprecated('Usa FinanceFundLifecycleCoordinator con controparti esplicite')
  Future<void> addFundTransaction({
    required String fundId,
    required String description,
    required double amount,
    required FundTransactionType type,
  }) async {
    final fundIndex = funds.indexWhere((f) => f.id == fundId);

    if (fundIndex == -1) {
      return;
    }

    final oldFund = funds[fundIndex];

    double newAmount = oldFund.amount;

    if (type == FundTransactionType.deposit) {
      newAmount += amount;
    } else {
      newAmount -= amount;
    }

    if (newAmount < 0) {
      newAmount = 0;
    }

    _funds[fundIndex] = FinanceFund(
      id: oldFund.id,
      name: oldFund.name,
      description: oldFund.description,
      amount: newAmount,
      protected: oldFund.protected,
      category: oldFund.category,
    );

    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    _fundTransactions.add(
      FundTransaction(
        id: transactionId,
        fundId: fundId,
        description: description,
        amount: amount,
        date: DateTime.now(),
        type: type,
      ),
    );

    _transactions.add(
      FinanceTransaction(
        id: 'fund_$transactionId',
        balanceId: fundId,
        amount: amount,
        date: DateTime.now(),
        isIncome: type == FundTransactionType.deposit,
        subject: FinanceSubject.shared,
        description: description.isEmpty ? oldFund.name : description,
        type: type == FundTransactionType.deposit
            ? FinanceTransactionType.income
            : FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.fund,
        economicFactId: economicFactIdGenerator.next(),
        notes: 'Movimento fondo: ${oldFund.name}',
      ),
    );

    await runInNotificationBatch(() async {
      try {
        await saveFunds();
        await saveFundTransactions();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  @Deprecated('Chiudi il fondo tramite FinanceFundLifecycleCoordinator')
  Future<void> removeFund(String fundId) async {
    final hasChanges =
        _funds.any((fund) => fund.id == fundId) ||
        _fundTransactions.any((transaction) => transaction.fundId == fundId) ||
        _transactions.any((transaction) => transaction.balanceId == fundId);
    if (!hasChanges) return;

    _funds.removeWhere((f) => f.id == fundId);
    _fundTransactions.removeWhere(
      (transaction) => transaction.fundId == fundId,
    );
    _transactions.removeWhere((transaction) => transaction.balanceId == fundId);

    await runInNotificationBatch(() async {
      try {
        await saveFunds();
        await saveFundTransactions();
        await saveTransactions();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> confirmRecurringItem(String itemId, {double? realAmount}) async {
    final index = recurringItems.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      return;
    }

    if (recurringItems[index].confirmed) {
      return;
    }

    if (_portfolioV3Authoritative) {
      await runInNotificationBatch(() async {
        final item = recurringItems[index];
        final amount = realAmount ?? item.expectedAmount;
        if (item.balanceId != null) {
          final balanceIndex = balances.indexWhere(
            (balance) => balance.balanceId == item.balanceId,
          );

          if (balanceIndex != -1) {
            final oldBalance = balances[balanceIndex];
            final candidateBalances = List<FinanceBalance>.of(_balances);
            candidateBalances[balanceIndex] = FinanceBalance(
              balanceId: oldBalance.balanceId,
              personId: oldBalance.personId,
              name: oldBalance.name,
              initialAmount: oldBalance.initialAmount,
              currentAmount: item.isIncome
                  ? oldBalance.currentAmount + amount
                  : oldBalance.currentAmount - amount,
              updatedAt: DateTime.now(),
              balanceType: oldBalance.balanceType,
              operational: oldBalance.operational,
              active: oldBalance.active,
              reservedAmount: oldBalance.reservedAmount,
              warningThreshold: oldBalance.warningThreshold,
              persistentStressDays: oldBalance.persistentStressDays,
              recoveryDays: oldBalance.recoveryDays,
            );
            final candidateTransactions =
                List<FinanceTransaction>.of(_transactions)..add(
                  FinanceTransaction(
                    id: 'transaction_${DateTime.now().microsecondsSinceEpoch}',
                    balanceId: oldBalance.balanceId,
                    amount: amount,
                    date: DateTime.now(),
                    isIncome: item.isIncome,
                    subject: item.subject,
                    description: item.name,
                    type: item.isIncome
                        ? FinanceTransactionType.income
                        : FinanceTransactionType.expense,
                    origin: FinanceTransactionOrigin.recurringItem,
                    recurringItemId: item.id,
                    economicFactId: economicFactIdGenerator.next(),
                    notes: item.description,
                  ),
                );

            await _commitBalanceAndTransactionsCandidate(
              candidateBalances: candidateBalances,
              candidateTransactions: candidateTransactions,
            );
          }
        }

        _recurringItems[index] = item.copyWith(
          confirmed: true,
          realAmount: amount,
        );

        if (item.recurringType != FinanceRecurringType.oneShot) {
          final nextDate = nextDueDateAfterConfirmation(item);
          final now = DateTime.now();

          _recurringItems.add(
            item.copyWith(
              id: 'recurring_${now.microsecondsSinceEpoch}',
              nextDueDate: nextDate,
              confirmed: false,
              realAmount: null,
            ),
          );
        }

        try {
          await saveRecurringItems();
        } finally {
          _markChanged();
        }
      });
      return;
    }

    await runInNotificationBatch(() async {
      final item = recurringItems[index];
      final amount = realAmount ?? item.expectedAmount;
      var changed = false;

      try {
        if (item.balanceId != null) {
          final balanceIndex = balances.indexWhere(
            (balance) => balance.balanceId == item.balanceId,
          );

          if (balanceIndex != -1) {
            final oldBalance = balances[balanceIndex];

            final newAmount = item.isIncome
                ? oldBalance.currentAmount + amount
                : oldBalance.currentAmount - amount;

            _balances[balanceIndex] = FinanceBalance(
              balanceId: oldBalance.balanceId,
              personId: oldBalance.personId,
              name: oldBalance.name,
              initialAmount: oldBalance.initialAmount,
              currentAmount: newAmount,
              updatedAt: DateTime.now(),
              balanceType: oldBalance.balanceType,
              operational: oldBalance.operational,
              active: oldBalance.active,
              reservedAmount: oldBalance.reservedAmount,
              warningThreshold: oldBalance.warningThreshold,
              persistentStressDays: oldBalance.persistentStressDays,
              recoveryDays: oldBalance.recoveryDays,
            );

            _transactions.add(
              FinanceTransaction(
                id: 'transaction_${DateTime.now().microsecondsSinceEpoch}',
                balanceId: oldBalance.balanceId,
                amount: amount,
                date: DateTime.now(),
                isIncome: item.isIncome,
                subject: item.subject,
                description: item.name,
                type: item.isIncome
                    ? FinanceTransactionType.income
                    : FinanceTransactionType.expense,
                origin: FinanceTransactionOrigin.recurringItem,
                recurringItemId: item.id,
                economicFactId: economicFactIdGenerator.next(),
                notes: item.description,
              ),
            );

            changed = true;
            await saveBalances();
            await saveTransactions();
          }
        }

        _recurringItems[index] = item.copyWith(
          confirmed: true,
          realAmount: amount,
        );
        changed = true;

        if (item.recurringType != FinanceRecurringType.oneShot) {
          final nextDate = nextDueDateAfterConfirmation(item);
          final now = DateTime.now();

          _recurringItems.add(
            item.copyWith(
              id: 'recurring_${now.microsecondsSinceEpoch}',
              nextDueDate: nextDate,
              confirmed: false,
              realAmount: null,
            ),
          );
        }

        await saveRecurringItems();
      } finally {
        if (changed) _markChanged();
      }
    });
  }

  Future<void> addRecurringItem(FinanceRecurringItem item) async {
    _recurringItems.add(item);

    try {
      await saveRecurringItems();
    } finally {
      _markChanged();
    }
  }

  Future<void> removeRecurringItem(String itemId) async {
    final itemIndex = recurringItems.indexWhere((item) => item.id == itemId);

    if (itemIndex == -1) {
      return;
    }

    final item = recurringItems[itemIndex];

    final linkedTransactions = transactions
        .where((transaction) => transaction.recurringItemId == item.id)
        .toList();

    if (_portfolioV3Authoritative) {
      await runInNotificationBatch(() async {
        if (linkedTransactions.isNotEmpty) {
          final candidateBalances = List<FinanceBalance>.of(_balances);
          for (final transaction in linkedTransactions) {
            final balanceIndex = candidateBalances.indexWhere(
              (balance) => balance.balanceId == transaction.balanceId,
            );

            if (balanceIndex == -1) continue;

            final oldBalance = candidateBalances[balanceIndex];
            candidateBalances[balanceIndex] = FinanceBalance(
              balanceId: oldBalance.balanceId,
              personId: oldBalance.personId,
              name: oldBalance.name,
              initialAmount: oldBalance.initialAmount,
              currentAmount: transaction.isIncome
                  ? oldBalance.currentAmount - transaction.amount
                  : oldBalance.currentAmount + transaction.amount,
              updatedAt: DateTime.now(),
              balanceType: oldBalance.balanceType,
              operational: oldBalance.operational,
              active: oldBalance.active,
              reservedAmount: oldBalance.reservedAmount,
              warningThreshold: oldBalance.warningThreshold,
              persistentStressDays: oldBalance.persistentStressDays,
              recoveryDays: oldBalance.recoveryDays,
            );
          }
          final candidateTransactions = _transactions
              .where((transaction) => transaction.recurringItemId != item.id)
              .toList();

          await _commitBalanceAndTransactionsCandidate(
            candidateBalances: candidateBalances,
            candidateTransactions: candidateTransactions,
          );
        }

        _recurringItems.removeAt(itemIndex);
        try {
          await saveRecurringItems();
        } finally {
          _markChanged();
        }
      });
      return;
    }

    for (final transaction in linkedTransactions) {
      final balanceIndex = balances.indexWhere(
        (balance) => balance.balanceId == transaction.balanceId,
      );

      if (balanceIndex == -1) continue;

      final oldBalance = balances[balanceIndex];

      final restoredAmount = transaction.isIncome
          ? oldBalance.currentAmount - transaction.amount
          : oldBalance.currentAmount + transaction.amount;

      _balances[balanceIndex] = FinanceBalance(
        balanceId: oldBalance.balanceId,
        personId: oldBalance.personId,
        name: oldBalance.name,
        initialAmount: oldBalance.initialAmount,
        currentAmount: restoredAmount,
        updatedAt: DateTime.now(),
        balanceType: oldBalance.balanceType,
        operational: oldBalance.operational,
        active: oldBalance.active,
        reservedAmount: oldBalance.reservedAmount,
        warningThreshold: oldBalance.warningThreshold,
        persistentStressDays: oldBalance.persistentStressDays,
        recoveryDays: oldBalance.recoveryDays,
      );
    }

    _transactions.removeWhere(
      (transaction) => transaction.recurringItemId == item.id,
    );

    _recurringItems.removeAt(itemIndex);

    await runInNotificationBatch(() async {
      try {
        await saveBalances();
        await saveTransactions();
        await saveRecurringItems();
      } finally {
        _markChanged();
      }
    });
  }

  Future<void> updateRecurringItem(FinanceRecurringItem updatedItem) async {
    final index = recurringItems.indexWhere(
      (item) => item.id == updatedItem.id,
    );

    if (index == -1) {
      return;
    }

    if (jsonEncode(_recurringItems[index].toJson()) ==
        jsonEncode(updatedItem.toJson())) {
      return;
    }

    _recurringItems[index] = updatedItem;

    try {
      await saveRecurringItems();
    } finally {
      _markChanged();
    }
  }

  Future<bool> loadSavedRecurringItems() =>
      _runObservableLoad(_loadSavedRecurringItems);

  Future<bool> _loadSavedRecurringItems() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_recurring_items',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    _recurringItems
      ..clear()
      ..addAll(jsonList.map(FinanceRecurringItem.fromJson));

    return true;
  }

  Future<void> saveFunds() async {
    final jsonList = funds.map((f) => f.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_funds', jsonList);
    if (_portfolioReady) await savePortfolio();
  }

  Future<void> saveFundTransactions() async {
    final jsonList = fundTransactions.map((t) => t.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_fund_transactions', jsonList);
    if (_portfolioReady) await savePortfolio();
  }

  Future<void> saveRecurringItems() async {
    final jsonList = recurringItems.map((item) => item.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_recurring_items', jsonList);
  }

  double totalRecurringAmount(List<FinanceRecurringItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double economicPressureScore({required DateTime observedAt}) {
    double score = 0;

    for (final item in recurringItems) {
      if (item.isIncome) continue;

      double weight = item.expectedAmount;

      final behavior = item.behaviorProfile;

      weight *= 1 + behavior.rigidityScore;
      weight *= 1 + (1 - behavior.maneuverabilityScore);

      if (behavior.lifeGenerated) {
        weight *= 1.15;
      }

      if (behavior.timeSensitive) {
        weight *= 1.20;
      }

      if (!behavior.affectsResilience) {
        weight *= 0.85;
      }

      if (!behavior.affectsOperationalOxygen) {
        weight *= 0.90;
      }

      final matchingProtectedFundsAmount = funds
          .where((fund) {
            if (!fund.protected) return false;

            if (fund.category == FinanceFundCategory.emergency) {
              weight *= 0.80;
              return true;
            }

            if (fund.category == FinanceFundCategory.auto &&
                item.category == FinanceCategory.auto) {
              return true;
            }

            if (fund.category == FinanceFundCategory.home &&
                item.category == FinanceCategory.house) {
              return true;
            }

            if (fund.category == FinanceFundCategory.health &&
                item.category == FinanceCategory.health) {
              return true;
            }

            if (fund.category == FinanceFundCategory.school &&
                item.category == FinanceCategory.school) {
              return true;
            }

            return false;
          })
          .fold<double>(0, (sum, f) => sum + f.amount);

      if (item.protectionLevel == FinanceProtectionLevel.protected &&
          matchingProtectedFundsAmount >= item.expectedAmount) {
        weight *= 0.55;

        final minimumPressure = item.expectedAmount * 0.28;

        if (weight < minimumPressure) {
          weight = minimumPressure;
        }
      }

      switch (item.paymentPriority) {
        case FinancePaymentPriority.low:
          weight *= 0.5;
          break;

        case FinancePaymentPriority.normal:
          weight *= 1.0;
          break;

        case FinancePaymentPriority.high:
          weight *= 1.5;
          break;

        case FinancePaymentPriority.critical:
          weight *= 2.0;
          break;
      }

      final dueDate = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      final days = dueDate.difference(observedAt).inDays;

      if (days <= 30) {
        weight *= 1.8;
      } else if (days <= 90) {
        weight *= 1.4;
      } else if (days <= 180) {
        weight *= 1.1;
      } else if (days <= 365) {
        weight *= 0.8;
      } else {
        weight *= 0.5;
      }

      score += weight;
    }

    final margin = projectedMonthlyMargin();

    if (margin < 0) {
      score *= 1.5;
    }

    return score;
  }

  List<FinanceRecurringItem> itemsForProjectionMonth(DateTime month) {
    return recurringItems.where((item) {
      final firstDueMonth = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        1,
      );

      final currentMonth = DateTime(month.year, month.month, 1);

      if (item.confirmed) {
        return firstDueMonth.year == currentMonth.year &&
            firstDueMonth.month == currentMonth.month;
      }

      if (currentMonth.year < firstDueMonth.year ||
          (currentMonth.year == firstDueMonth.year &&
              currentMonth.month < firstDueMonth.month)) {
        return false;
      }

      switch (item.recurringType) {
        case FinanceRecurringType.monthly:
          return true;

        case FinanceRecurringType.yearly:
          return currentMonth.month == item.nextDueDate.month &&
              currentMonth.year >= item.nextDueDate.year;

        case FinanceRecurringType.oneShot:
          return firstDueMonth.year == currentMonth.year &&
              firstDueMonth.month == currentMonth.month;

        case FinanceRecurringType.custom:
          final interval = item.customInterval ?? 1;
          final unit = item.customIntervalUnit ?? 'months';

          if (unit == 'months') {
            final monthDiff =
                (currentMonth.year - firstDueMonth.year) * 12 +
                (currentMonth.month - firstDueMonth.month);

            return monthDiff >= 0 && monthDiff % interval == 0;
          }

          if (unit == 'years') {
            final yearDiff = currentMonth.year - firstDueMonth.year;

            return currentMonth.month == firstDueMonth.month &&
                yearDiff >= 0 &&
                yearDiff % interval == 0;
          }

          return firstDueMonth.year == currentMonth.year &&
              firstDueMonth.month == currentMonth.month;
      }
    }).toList();
  }

  double projectedAmountForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    double total = 0;

    for (final item in itemsForProjectionMonth(month)) {
      if (item.isIncome) continue;

      if (item.hasCustomSplits) {
        for (final split in item.splits) {
          final splitOwner = FinancePaymentOwner.values.firstWhere(
            (e) => e.name == split.personId,
            orElse: () => FinancePaymentOwner.shared,
          );

          if (splitOwner == owner) {
            total += split.amount;
          }
        }

        continue;
      }

      if (item.paymentOwner == owner) {
        total += item.expectedAmount;
      }

      if (item.paymentOwner == FinancePaymentOwner.shared) {
        total += item.expectedAmount / 2;
      }
    }

    return total;
  }

  double projectedIncomeForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    double total = 0;

    for (final item in itemsForProjectionMonth(month)) {
      if (!item.isIncome) continue;

      if (item.hasCustomSplits) {
        for (final split in item.splits) {
          final splitOwner = FinancePaymentOwner.values.firstWhere(
            (e) => e.name == split.personId,
            orElse: () => FinancePaymentOwner.shared,
          );

          if (splitOwner == owner) {
            total += split.amount;
          }
        }

        continue;
      }

      if (item.paymentOwner == owner) {
        total += item.expectedAmount;
      }

      if (item.paymentOwner == FinancePaymentOwner.shared) {
        total += item.expectedAmount / 2;
      }
    }

    return total;
  }

  double projectedMarginForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    final income = projectedIncomeForOwner(month: month, owner: owner);
    final expenses = projectedAmountForOwner(month: month, owner: owner);

    return income - expenses;
  }

  FinanceMonthSaturation _monthSaturation({
    required double margin,
    required double pressureDensity,
    required int pressureItemCount,
  }) {
    if (margin < 0 && pressureDensity > 800) {
      return FinanceMonthSaturation.critical;
    }

    if (margin < 200 && pressureItemCount >= 8) {
      return FinanceMonthSaturation.high;
    }

    if (pressureDensity > 400 || pressureItemCount >= 5) {
      return FinanceMonthSaturation.medium;
    }

    return FinanceMonthSaturation.low;
  }

  List<FinanceMonthProjection> nextMonthProjections({int months = 12}) {
    final now = DateTime.now();
    final result = <FinanceMonthProjection>[];

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);

      double income = 0;
      double expenses = 0;

      final monthItems = itemsForProjectionMonth(month);

      for (final item in monthItems) {
        if (item.isIncome) {
          income += item.expectedAmount;
        } else {
          expenses += item.expectedAmount;
        }
      }

      final margin = income - expenses;

      double pressure = expenses;

      if (margin < 0) {
        pressure *= 1.5;
      }

      final pressureItems = monthItems.where((item) => !item.isIncome).toList();
      final pressureItemCount = pressureItems.length;
      final pressureDensity = pressureItemCount == 0
          ? 0.0
          : pressure / pressureItemCount;

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
          pressureItemCount: pressureItemCount,
          pressureDensity: pressureDensity,
          saturation: _monthSaturation(
            margin: margin,
            pressureDensity: pressureDensity,
            pressureItemCount: pressureItemCount,
          ),
        ),
      );
    }

    return result;
  }

  List<FinanceMonthProjection> yearProjections(int year) {
    final result = <FinanceMonthProjection>[];

    for (int monthIndex = 1; monthIndex <= 12; monthIndex++) {
      final month = DateTime(year, monthIndex, 1);

      double income = 0;
      double expenses = 0;

      final monthItems = itemsForProjectionMonth(month);

      for (final item in monthItems) {
        if (item.isIncome) {
          income += item.expectedAmount;
        } else {
          expenses += item.expectedAmount;
        }
      }

      final margin = income - expenses;

      double pressure = expenses;

      if (margin < 0) {
        pressure *= 1.5;
      }

      final pressureItems = monthItems.where((item) => !item.isIncome).toList();
      final pressureItemCount = pressureItems.length;
      final pressureDensity = pressureItemCount == 0
          ? 0.0
          : pressure / pressureItemCount;

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
          pressureItemCount: pressureItemCount,
          pressureDensity: pressureDensity,
          saturation: _monthSaturation(
            margin: margin,
            pressureDensity: pressureDensity,
            pressureItemCount: pressureItemCount,
          ),
        ),
      );
    }

    return result;
  }

  String financeSummaryText() {
    return '''
Saldo totale: ${totalBalance().toStringAsFixed(2)}
Fondi: ${totalFunds().toStringAsFixed(2)}
Entrate previste: ${projectedMonthlyIncome().toStringAsFixed(2)}
Uscite previste: ${projectedMonthlyExpenses().toStringAsFixed(2)}
Margine previsto: ${projectedMonthlyMargin().toStringAsFixed(2)}
Pressione: ${isUnderPressure() ? 'SI' : 'NO'}
''';
  }

  String demoSummaryText() {
    loadDemoData();
    saveSnapshot(DateTime.now());
    return financeSummaryText();
  }

  /// Returns the canonical Finance subject for a supported person identity.
  ///
  /// Unlike the legacy internal mapping, this method deliberately has no
  /// `shared` fallback and is therefore suitable for flows that require an
  /// explicitly attributable person.
  FinanceSubject? subjectForPersonIdIfSupported(String personId) {
    switch (personId) {
      case 'matteo':
        return FinanceSubject.matteo;
      case 'chiara':
        return FinanceSubject.chiara;
      case 'alice':
        return FinanceSubject.alice;
      default:
        return null;
    }
  }

  FinanceSubject _subjectForPersonId(String personId) =>
      subjectForPersonIdIfSupported(personId) ?? FinanceSubject.shared;
}
