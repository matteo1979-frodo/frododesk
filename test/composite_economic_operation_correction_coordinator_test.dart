import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/composite_correction_intent_persistence.dart';
import 'package:frododesk/logic/finance/composite_economic_operation_coordinator.dart';
import 'package:frododesk/logic/finance/composite_economic_operation_correction_coordinator.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/composite_correction_intent.dart';
import 'package:frododesk/models/composite_economic_operation.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final accessories in <Map<AccessoryCostType, double>>[
    {},
    {AccessoryCostType.bankCommission: 2},
    {AccessoryCostType.postalAcceptanceCharge: 1},
    {
      AccessoryCostType.bankCommission: 2,
      AccessoryCostType.postalAcceptanceCharge: 1,
    },
  ]) {
    test('corrects main with ${accessories.length} accessory types', () async {
      final harness = await _Harness.create(initialAccessories: accessories);
      final target = <AccessoryCostType, double>{
        ...accessories,
        if (!accessories.containsKey(AccessoryCostType.bankCommission))
          AccessoryCostType.bankCommission: 3,
      };

      final result = await harness.correct(
        target: target,
        mainAmount: 70,
        correctionId: 'correction-${accessories.length}',
      );

      expect(result.status, CompositeCorrectionStatus.completed);
      expect(harness.expenses.all, hasLength(1 + target.length));
      expect(
        harness.expenses.all.map((item) => item.operationMetadata?.role),
        contains(OperationRole.main),
      );
      expect(
        harness.expenses.all.map((item) => item.economicFactId).toSet().length,
        harness.expenses.all.length,
      );
      expect(
        harness.finance.transactions.where(
          (item) => item.compositeCorrectionMetadata != null,
        ),
        hasLength((1 + accessories.length) + (1 + target.length)),
      );
    });
  }

  test('adds, removes and changes accessory in one Expense write', () async {
    final harness = await _Harness.create(
      initialAccessories: const {
        AccessoryCostType.bankCommission: 2,
        AccessoryCostType.postalAcceptanceCharge: 1,
      },
    );
    var expenseWrites = 0;
    harness.expensesSaveObserver = () => expenseWrites++;

    final result = await harness.correct(
      target: const {AccessoryCostType.bankCommission: 4},
      mainAmount: 60,
      correctionId: 'accessory-transform',
    );

    expect(result.isSuccess, isTrue);
    expect(expenseWrites, 1);
    expect(harness.expenses.all, hasLength(2));
    expect(
      harness.expenses.all
          .where(
            (item) => item.operationMetadata?.role == OperationRole.accessory,
          )
          .single
          .amount,
      4,
    );
  });

  test('same account applies old total minus new total exactly once', () async {
    final harness = await _Harness.create(
      initialAccessories: const {AccessoryCostType.bankCommission: 2},
    );
    expect(harness.finance.balances.first.currentAmount, 938);

    expect(
      (await harness.correct(
        target: const {AccessoryCostType.bankCommission: 5},
        mainAmount: 70,
        correctionId: 'same-account',
      )).isSuccess,
      isTrue,
    );
    expect(harness.finance.balances.first.currentAmount, 925);
  });

  test('account change restores old and debits new account', () async {
    final harness = await _Harness.create();
    final result = await harness.correct(
      target: const {},
      mainAmount: 80,
      correctionId: 'account-change',
      balanceId: 'balance-second',
      balanceName: 'Secondo conto',
    );

    expect(result.isSuccess, isTrue);
    expect(
      harness.finance.balances
          .singleWhere((item) => item.balanceId == 'balance-bank')
          .currentAmount,
      1000,
    );
    expect(
      harness.finance.balances
          .singleWhere((item) => item.balanceId == 'balance-second')
          .currentAmount,
      420,
    );
  });

  test('historical correction never changes either balance', () async {
    final harness = await _Harness.create(
      mode: BalancePostingMode.alreadyIncludedInCurrentBalance,
      initialAccessories: const {AccessoryCostType.bankCommission: 2},
    );
    final result = await harness.correct(
      target: const {AccessoryCostType.postalAcceptanceCharge: 9},
      mainAmount: 90,
      correctionId: 'historical',
      balanceId: 'balance-second',
      balanceName: 'Secondo conto',
      mode: BalancePostingMode.alreadyIncludedInCurrentBalance,
    );

    expect(result.isSuccess, isTrue);
    expect(harness.finance.balances.map((item) => item.currentAmount), [
      1000,
      500,
    ]);
    expect(
      harness.expenses.all.map((item) => item.balancePostingMode).toSet(),
      {BalancePostingMode.alreadyIncludedInCurrentBalance},
    );
  });

  test('posting mode change fails closed before mutation', () async {
    final harness = await _Harness.create();
    final beforeTransactions = harness.finance.transactions.length;
    final result = await harness.correct(
      target: const {},
      mainAmount: 60,
      correctionId: 'mode-conflict',
      mode: BalancePostingMode.alreadyIncludedInCurrentBalance,
    );
    expect(result.status, CompositeCorrectionStatus.conflict);
    expect(harness.finance.transactions, hasLength(beforeTransactions));
    expect(harness.finance.balances.first.currentAmount, 940);
  });

  test(
    'unrelated legacy expense without economicFactId is preserved',
    () async {
      final harness = await _Harness.create(addLegacyExpense: true);
      final result = await harness.correct(
        target: const {},
        mainAmount: 65,
        correctionId: 'legacy-safe',
      );
      expect(result.isSuccess, isTrue);
      expect(
        harness.expenses.all.where((item) => item.id == 'legacy'),
        hasLength(1),
      );
      expect(
        harness.expenses.all
            .singleWhere((item) => item.id == 'legacy')
            .economicFactId,
        isNull,
      );
    },
  );

  test('retry continues after Finance writer failure', () async {
    final harness = await _Harness.create(failCorrectionFinanceOnce: true);
    final first = await harness.correct(
      target: const {},
      mainAmount: 65,
      correctionId: 'finance-retry',
    );
    expect(first.status, CompositeCorrectionStatus.failed);
    expect(harness.expenses.all.single.amount, 60);
    final retry = await harness.correct(
      target: const {},
      mainAmount: 65,
      correctionId: 'finance-retry',
    );
    expect(retry.isSuccess, isTrue);
    expect(harness.expenses.all.single.amount, 65);
    expect(harness.finance.balances.first.currentAmount, 935);
  });

  test('retry continues after Finance committed and Expense failed', () async {
    final harness = await _Harness.create(failCorrectionExpenseOnce: true);
    final first = await harness.correct(
      target: const {},
      mainAmount: 65,
      correctionId: 'expense-retry',
    );
    expect(first.status, CompositeCorrectionStatus.failed);
    expect(harness.finance.balances.first.currentAmount, 935);
    expect(harness.expenses.all.single.amount, 60);
    final retry = await harness.correct(
      target: const {},
      mainAmount: 65,
      correctionId: 'expense-retry',
    );
    expect(retry.isSuccess, isTrue);
    expect(harness.finance.balances.first.currentAmount, 935);
    expect(harness.expenses.all.single.amount, 65);
  });
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;
  final CompositeCorrectionIntentPersistence intents;
  final BalancePostingMode mode;
  void Function()? expensesSaveObserver;

  _Harness(this.finance, this.expenses, this.intents, this.mode);

  static Future<_Harness> create({
    Map<AccessoryCostType, double> initialAccessories = const {},
    BalancePostingMode mode = BalancePostingMode.affectsCurrentBalance,
    bool addLegacyExpense = false,
    bool failCorrectionFinanceOnce = false,
    bool failCorrectionExpenseOnce = false,
  }) async {
    final seed = FinancePortfolioV3(
      balances: [
        _balance('balance-bank', 'Banca', 1000),
        _balance('balance-second', 'Secondo conto', 500),
      ],
      funds: const [],
      assetMovements: const [],
      transactions: const [],
      fundTransactions: const [],
      linkedItems: const [],
    );
    expect((await FinancePortfolioV3Writer().write(seed)).isSuccess, isTrue);
    var financeWrites = 0;
    final finance = FinanceStore(
      portfolioV3Writer: FinancePortfolioV3Writer(
        saveVerified: (key, value) async {
          financeWrites++;
          if (failCorrectionFinanceOnce && financeWrites == 2) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceStore.saveStringVerified(key, value);
        },
      ),
    );
    await finance.loadSavedPortfolioV3();
    late final _Harness harness;
    var expenseWrites = 0;
    final expenses = ExpenseStore(
      saveVerified: (key, value) async {
        expenseWrites++;
        harness.expensesSaveObserver?.call();
        if (failCorrectionExpenseOnce && expenseWrites == 2) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        return PersistenceStore.saveStringVerified(key, value);
      },
    );
    await expenses.load();
    harness = _Harness(
      finance,
      expenses,
      CompositeCorrectionIntentPersistence(),
      mode,
    );
    final operation = CompositeEconomicOperation(
      operationId: 'operation-utility',
      context: OperationContext.utilityBill,
      mainEconomicFactId: 'fact-main',
      mainAmount: 60,
      accessories: [
        for (final entry in initialAccessories.entries)
          (
            economicFactId: 'fact-${entry.key.name}',
            amount: entry.value,
            accessoryCostType: entry.key,
          ),
      ],
    );
    final creation =
        await CompositeEconomicOperationCoordinator(
          financeStore: finance,
          expenseStore: expenses,
        ).record(
          CompositeEconomicOperationPosting(
            operation: operation,
            debitBalanceId: 'balance-bank',
            subject: FinanceSubject.matteo,
            economicDate: DateTime(2026, 9, 1),
            description: 'Bolletta iniziale',
            category: 'Utenze',
            balancePostingMode: mode,
          ),
        );
    expect(creation.status, CompositeEconomicOperationStatus.completed);
    if (addLegacyExpense) {
      await expenses.addExpense(
        RealExpense(
          id: 'legacy',
          balanceId: 'legacy-account',
          balanceName: 'Legacy',
          amount: 1,
          description: 'Legacy',
          category: 'Altro',
          date: DateTime(2020),
        ),
      );
    }
    harness.expensesSaveObserver = null;
    return harness;
  }

  Future<CompositeCorrectionResult> correct({
    required Map<AccessoryCostType, double> target,
    required double mainAmount,
    required String correctionId,
    String balanceId = 'balance-bank',
    String balanceName = 'Banca',
    BalancePostingMode? mode,
  }) =>
      CompositeEconomicOperationCorrectionCoordinator(
        financeStore: finance,
        expenseStore: expenses,
        persistence: intents,
      ).correct(
        operationId: 'operation-utility',
        correctionId: correctionId,
        payload: CompositeCorrectionPayload(
          balanceId: balanceId,
          balanceName: balanceName,
          mainAmount: mainAmount,
          economicDate: DateTime(2026, 10, 1),
          description: 'Bolletta corretta',
          category: 'Casa',
          subject: FinanceSubject.matteo,
          accessories: target,
          balancePostingMode: mode ?? this.mode,
        ),
      );
}

FinanceBalance _balance(String id, String name, double amount) =>
    FinanceBalance(
      personId: 'matteo',
      balanceId: id,
      name: name,
      initialAmount: amount,
      currentAmount: amount,
      updatedAt: DateTime(2026, 8, 1),
      balanceType: FinanceBalanceType.bankAccount,
      operational: true,
      active: true,
      reservedAmount: 0,
      warningThreshold: 0,
      persistentStressDays: 0,
      recoveryDays: 0,
    );
