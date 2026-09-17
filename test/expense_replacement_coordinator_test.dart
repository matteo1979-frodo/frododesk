import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/logic/spese/expense_replacement_coordinator.dart';
import 'package:frododesk/logic/spese/expense_replacement_persistence.dart';
import 'package:frododesk/models/expense_replacement_intent.dart';
import 'package:frododesk/models/expense_replacement_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('happy path applies net delta, identities and cleanup once', () async {
    final harness = await _Harness.create();

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.status, ExpenseReplacementStatus.completed);
    expect(harness.finance.balances.single.currentAmount, 95);
    expect(harness.finance.transactions, hasLength(2));
    expect(harness.finance.transactions.map((item) => item.id), [
      harness.intent.identities.compensationTransactionId,
      harness.intent.identities.replacementTransactionId,
    ]);
    final compensationMetadata =
        harness.finance.transactions.first.expenseReplacementMetadata!;
    final replacementMetadata =
        harness.finance.transactions.last.expenseReplacementMetadata!;
    expect(compensationMetadata.originalEconomicFactId, 'old-fact');
    expect(
      compensationMetadata.replacementEconomicFactId,
      harness.intent.identities.replacementEconomicFactId,
    );
    expect(compensationMetadata.role, ExpenseReplacementRole.compensation);
    expect(replacementMetadata.originalEconomicFactId, 'old-fact');
    expect(replacementMetadata.role, ExpenseReplacementRole.replacement);
    expect(
      harness.expenses.all.single.id,
      harness.intent.identities.replacementCommandId,
    );
    expect(
      harness.expenses.all.single.date,
      harness.intent.replacementPayload.occurredAt,
    );
    expect(
      harness.finance.transactions.last.date,
      harness.intent.replacementPayload.occurredAt,
    );
    expect(await harness.persistence.load(), isEmpty);

    final events = const EconomicEventCorrelator().correlate(
      const EconomicEventCollector().collect(
        transactions: harness.finance.transactions,
        assetMovements: const [],
        realExpenses: harness.expenses.all,
        observedAt: DateTime(2026, 9, 16),
      ),
    );
    expect(
      events.where(
        (event) =>
            event.economicFactId ==
            harness.intent.identities.replacementEconomicFactId,
      ),
      hasLength(1),
    );
  });

  test('Finance failure leaves all state ready and retry is exact', () async {
    var reject = true;
    final harness = await _Harness.create(
      financeSave: (key, value) async {
        if (reject) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        return _save(key, value);
      },
    );
    var financeNotifications = 0;
    var expenseNotifications = 0;
    harness.finance.addListener(() => financeNotifications++);
    harness.expenses.addListener(() => expenseNotifications++);

    final failed = await harness.coordinator.complete(harness.intent);
    expect(failed.reason, ExpenseReplacementReason.financeWriteFailed);
    expect(failed.state, ExpenseReplacementState.ready);
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all.single.id, 'old-expense');
    expect(await harness.persistence.load(), hasLength(1));
    expect(financeNotifications, 0);
    expect(expenseNotifications, 0);

    reject = false;
    final completed = await harness.coordinator.complete(harness.intent);
    expect(completed.status, ExpenseReplacementStatus.completed);
    expect(harness.finance.balances.single.currentAmount, 95);
    expect(harness.finance.transactions, hasLength(2));
  });

  test(
    'Expense failure leaves Finance applied and retry does not duplicate',
    () async {
      var rejectExpense = true;
      Future<PersistenceWriteVerification> expenseWriter(
        String key,
        String value,
      ) async {
        if (rejectExpense) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        return _save(key, value);
      }

      final harness = await _Harness.create(expenseSave: expenseWriter);

      final failed = await harness.coordinator.complete(harness.intent);
      expect(failed.reason, ExpenseReplacementReason.expenseWriteFailed);
      expect(failed.state, ExpenseReplacementState.financeApplied);
      expect(harness.finance.balances.single.currentAmount, 95);
      expect(harness.finance.transactions, hasLength(2));
      expect(harness.expenses.all.single.id, 'old-expense');

      rejectExpense = false;
      final financeAfterRestart = FinanceStore(
        portfolioV3Writer: FinancePortfolioV3Writer(saveVerified: _save),
      );
      expect(await financeAfterRestart.loadSavedPortfolioV3(), isTrue);
      final expensesAfterRestart = ExpenseStore(saveVerified: expenseWriter);
      await expensesAfterRestart.load();
      final coordinatorAfterRestart = ExpenseReplacementCoordinator(
        financeStore: financeAfterRestart,
        expenseStore: expensesAfterRestart,
        persistence: harness.persistence,
      );
      final completed = await coordinatorAfterRestart.complete(harness.intent);
      expect(completed.status, ExpenseReplacementStatus.completed);
      expect(financeAfterRestart.balances.single.currentAmount, 95);
      expect(financeAfterRestart.transactions, hasLength(2));
      expect(
        expensesAfterRestart.all.single.id,
        harness.intent.identities.replacementCommandId,
      );
    },
  );

  test('complete state with marker retries cleanup only', () async {
    var rejectCleanup = true;
    String? intentStorage;
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => intentStorage,
      saveVerified: (_, value) async {
        final decoded = jsonDecode(value) as Map<String, dynamic>;
        if (rejectCleanup && (decoded['intents'] as List).isEmpty) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        intentStorage = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    final harness = await _Harness.create(persistence: persistence);

    final failed = await harness.coordinator.complete(harness.intent);
    expect(failed.reason, ExpenseReplacementReason.intentCleanupFailed);
    expect(failed.state, ExpenseReplacementState.complete);
    final balance = harness.finance.balances.single.currentAmount;
    final transactionIds = harness.finance.transactions
        .map((item) => item.id)
        .toList();

    rejectCleanup = false;
    final retried = await harness.coordinator.complete(harness.intent);
    expect(retried.status, ExpenseReplacementStatus.alreadyComplete);
    expect(harness.finance.balances.single.currentAmount, balance);
    expect(harness.finance.transactions.map((item) => item.id), transactionIds);
    expect(await persistence.load(), isEmpty);
  });

  test('retry after cleanup is explicit and inert', () async {
    final harness = await _Harness.create();
    await harness.coordinator.complete(harness.intent);
    final balance = harness.finance.balances.single.currentAmount;

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.status, ExpenseReplacementStatus.alreadyComplete);
    expect(harness.finance.balances.single.currentAmount, balance);
    expect(harness.finance.transactions, hasLength(2));
  });

  test('mutated original Expense conflicts before Finance', () async {
    final harness = await _Harness.create(
      storedExpense: _oldExpense(amount: 11),
    );

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.expenseConflict);
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, isEmpty);
  });

  test('incompatible compensation identity conflicts', () async {
    final intent = _intent();
    final conflict = _compensation(intent, amount: 999);
    final harness = await _Harness.create(initialTransactions: [conflict]);

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.financeConflict);
    expect(harness.finance.balances.single.currentAmount, 100);
  });

  test('incompatible replacement Finance identity conflicts', () async {
    final intent = _intent();
    final conflict = _replacementTransaction(intent, amount: 999);
    final harness = await _Harness.create(initialTransactions: [conflict]);

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.financeConflict);
    expect(harness.finance.balances.single.currentAmount, 100);
  });

  test('incompatible replacement Expense identity conflicts', () async {
    final intent = _intent();
    final harness = await _Harness.create(
      additionalExpenses: [_replacementExpense(intent, amount: 999)],
    );

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.expenseConflict);
    expect(harness.finance.transactions, isEmpty);
  });

  test('both original and replacement absent is not recoverable', () async {
    final harness = await _Harness.create(includeOriginalExpense: false);

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.expenseConflict);
    expect(harness.finance.transactions, isEmpty);
  });

  test('corrupt intent storage fails explicitly without mutation', () async {
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => '{broken',
    );
    final harness = await _Harness.create(
      persistence: persistence,
      persistIntent: false,
    );

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.intentReadFailed);
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.expenses.all.single.id, 'old-expense');
  });

  test('persisted intent with incompatible content conflicts', () async {
    final harness = await _Harness.create(persistIntent: false);
    final incompatible = ExpenseReplacementIntent(
      replacementId: harness.intent.replacementId,
      originalExpense: harness.intent.originalExpense,
      replacementPayload: ExpenseReplacementPayload(
        balanceId: 'account',
        balanceName: 'Account',
        amount: 99,
        description: 'Different',
        category: 'Food',
        preparedAt: DateTime(2026, 9, 16, 12),
        occurredAt: DateTime(2026, 9, 15, 11),
        personId: 'matteo',
      ),
    );
    await harness.persistence.add(incompatible);

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.intentConflict);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all.single.id, 'old-expense');
  });

  test(
    'legacy original without economicFactId is replaced without rewriting it',
    () async {
      final legacy = _oldExpense(economicFactId: null);
      final harness = await _Harness.create(intent: _intent(original: legacy));

      final result = await harness.coordinator.complete(harness.intent);

      expect(result.status, ExpenseReplacementStatus.completed);
      expect(
        harness.expenses.all.single.economicFactId,
        harness.intent.identities.replacementEconomicFactId,
      );
      expect(harness.finance.balances.single.currentAmount, 95);
      expect(
        harness.finance.transactions.every(
          (item) => item.expenseReplacementMetadata == null,
        ),
        isTrue,
      );
    },
  );

  test('modern partial Finance state without metadata conflicts', () async {
    final intent = _intent();
    final harness = await _Harness.create(
      initialTransactions: [
        _compensation(intent, amount: 10, includeMetadata: false),
        _replacementTransaction(intent, amount: 15, includeMetadata: false),
      ],
    );

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.financeConflict);
    expect(harness.finance.balances.single.currentAmount, 100);
  });

  test(
    'keeps the original Finance transaction byte-for-byte unchanged',
    () async {
      final original = FinanceTransaction(
        id: 'original-transaction',
        balanceId: 'account',
        amount: 10,
        date: DateTime(2026, 9, 14, 10),
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: 'Old expense',
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Food',
        economicFactId: 'old-fact',
      );
      final before = jsonEncode(original.toJson());
      final harness = await _Harness.create(initialTransactions: [original]);

      final result = await harness.coordinator.complete(harness.intent);

      expect(result.status, ExpenseReplacementStatus.completed);
      expect(jsonEncode(harness.finance.transactions.first.toJson()), before);
      expect(
        harness.finance.transactions.first.expenseReplacementMetadata,
        isNull,
      );
    },
  );

  test('successive replacements form A to B to C without skipping B', () async {
    final harness = await _Harness.create();
    final first = await harness.coordinator.complete(harness.intent);
    final factB = harness.intent.identities.replacementEconomicFactId;
    final currentExpense = harness.expenses.all.single;
    final secondIntent = ExpenseReplacementIntent(
      replacementId: 'replacement-2',
      originalExpense: currentExpense,
      replacementPayload: ExpenseReplacementPayload(
        balanceId: 'account',
        balanceName: 'Account',
        amount: 15,
        description: 'Newest expense',
        category: 'Food',
        preparedAt: DateTime(2026, 9, 17, 12),
        occurredAt: DateTime(2026, 9, 15, 11),
        personId: 'matteo',
      ),
    );
    await harness.persistence.add(secondIntent);

    final second = await harness.coordinator.complete(secondIntent);

    expect(first.status, ExpenseReplacementStatus.completed);
    expect(second.status, ExpenseReplacementStatus.completed);
    final factC = secondIntent.identities.replacementEconomicFactId;
    final secondPair = harness.finance.transactions.skip(2).toList();
    expect(secondPair, hasLength(2));
    expect(
      secondPair.map(
        (item) => item.expenseReplacementMetadata?.originalEconomicFactId,
      ),
      everyElement(factB),
    );
    expect(
      secondPair.map(
        (item) => item.expenseReplacementMetadata?.replacementEconomicFactId,
      ),
      everyElement(factC),
    );
    expect(factB, isNot('old-fact'));
  });

  test('incompatible replacement provenance conflicts', () async {
    final intent = _intent();
    final harness = await _Harness.create(
      initialTransactions: [
        _compensation(intent, amount: 10),
        _replacementTransaction(
          intent,
          amount: 15,
          originalEconomicFactId: 'different-original',
        ),
      ],
    );

    final result = await harness.coordinator.complete(harness.intent);

    expect(result.reason, ExpenseReplacementReason.financeConflict);
    expect(harness.finance.balances.single.currentAmount, 100);
  });
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;
  final ExpenseReplacementPersistence persistence;
  final ExpenseReplacementIntent intent;
  final ExpenseReplacementCoordinator coordinator;

  const _Harness({
    required this.finance,
    required this.expenses,
    required this.persistence,
    required this.intent,
    required this.coordinator,
  });

  static Future<_Harness> create({
    ExpenseReplacementIntent? intent,
    ExpenseReplacementPersistence? persistence,
    ExpenseVerifiedSave? expenseSave,
    FinancePortfolioV3VerifiedSave? financeSave,
    RealExpense? storedExpense,
    List<RealExpense> additionalExpenses = const [],
    List<FinanceTransaction> initialTransactions = const [],
    bool includeOriginalExpense = true,
    bool persistIntent = true,
  }) async {
    final value = intent ?? _intent();
    final portfolio = FinancePortfolioV3(
      balances: [_balance()],
      funds: const [],
      assetMovements: const [],
      transactions: initialTransactions,
      fundTransactions: const [],
      linkedItems: const [],
    );
    final expenses = <RealExpense>[
      if (includeOriginalExpense) storedExpense ?? value.originalExpense,
      ...additionalExpenses,
    ];
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(portfolio),
      ),
      'frododesk_real_expenses_v1': jsonEncode(
        expenses.map((item) => item.toJson()).toList(),
      ),
    });
    final finance = FinanceStore(
      portfolioV3Writer: FinancePortfolioV3Writer(
        saveVerified: financeSave ?? _save,
      ),
    );
    expect(await finance.loadSavedPortfolioV3(), isTrue);
    final expenseStore = ExpenseStore(saveVerified: expenseSave);
    await expenseStore.load();
    final intentPersistence = persistence ?? ExpenseReplacementPersistence();
    if (persistIntent) await intentPersistence.add(value);
    final coordinator = ExpenseReplacementCoordinator(
      financeStore: finance,
      expenseStore: expenseStore,
      persistence: intentPersistence,
    );
    return _Harness(
      finance: finance,
      expenses: expenseStore,
      persistence: intentPersistence,
      intent: value,
      coordinator: coordinator,
    );
  }
}

Future<PersistenceWriteVerification> _save(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  final accepted = await prefs.setString('frododesk_$key', value);
  return PersistenceWriteVerification(
    backendAccepted: accepted,
    readBack: prefs.getString('frododesk_$key'),
  );
}

ExpenseReplacementIntent _intent({RealExpense? original}) =>
    ExpenseReplacementIntent(
      replacementId: 'replacement-1',
      originalExpense: original ?? _oldExpense(),
      replacementPayload: ExpenseReplacementPayload(
        balanceId: 'account',
        balanceName: 'Account',
        amount: 15,
        description: 'New expense',
        category: 'Food',
        preparedAt: DateTime(2026, 9, 16, 12),
        occurredAt: DateTime(2026, 9, 15, 11),
        personId: 'matteo',
      ),
    );

RealExpense _oldExpense({
  double amount = 10,
  String? economicFactId = 'old-fact',
}) => RealExpense(
  id: 'old-expense',
  balanceId: 'account',
  balanceName: 'Account',
  amount: amount,
  description: 'Old expense',
  category: 'Food',
  date: DateTime(2026, 9, 14, 10),
  subject: FinanceSubject.matteo,
  economicFactId: economicFactId,
);

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: 'Account',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 9, 14),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceTransaction _compensation(
  ExpenseReplacementIntent intent, {
  required double amount,
  bool includeMetadata = true,
}) => FinanceTransaction(
  id: intent.identities.compensationTransactionId,
  balanceId: 'account',
  amount: amount,
  date: intent.replacementPayload.preparedAt,
  isIncome: true,
  subject: FinanceSubject.matteo,
  description: 'Annullamento Old expense',
  type: FinanceTransactionType.income,
  origin: FinanceTransactionOrigin.manual,
  notes: 'Ripristino movimento sostituito',
  economicFactId: intent.identities.compensationEconomicFactId,
  expenseReplacementMetadata: includeMetadata
      ? ExpenseReplacementMetadata(
          originalEconomicFactId: intent.originalExpense.economicFactId!,
          replacementEconomicFactId:
              intent.identities.replacementEconomicFactId,
          role: ExpenseReplacementRole.compensation,
        )
      : null,
);

FinanceTransaction _replacementTransaction(
  ExpenseReplacementIntent intent, {
  required double amount,
  bool includeMetadata = true,
  String? originalEconomicFactId,
}) => FinanceTransaction(
  id: intent.identities.replacementTransactionId,
  balanceId: 'account',
  amount: amount,
  date: intent.replacementPayload.occurredAt,
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'New expense',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  notes: 'Food',
  economicFactId: intent.identities.replacementEconomicFactId,
  expenseReplacementMetadata: includeMetadata
      ? ExpenseReplacementMetadata(
          originalEconomicFactId:
              originalEconomicFactId ?? intent.originalExpense.economicFactId!,
          replacementEconomicFactId:
              intent.identities.replacementEconomicFactId,
          role: ExpenseReplacementRole.replacement,
        )
      : null,
);

RealExpense _replacementExpense(
  ExpenseReplacementIntent intent, {
  required double amount,
}) => RealExpense(
  id: intent.identities.replacementCommandId,
  balanceId: 'account',
  balanceName: 'Account',
  amount: amount,
  description: 'New expense',
  category: 'Food',
  date: intent.replacementPayload.occurredAt,
  subject: FinanceSubject.matteo,
  economicFactId: intent.identities.replacementEconomicFactId,
);
