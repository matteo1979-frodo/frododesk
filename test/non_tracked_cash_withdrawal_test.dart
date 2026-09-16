import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/adapters/real_expense_event_adapter.dart';
import 'package:frododesk/logic/spese/builders/spese_command_builder.dart';
import 'package:frododesk/logic/spese/builders/spese_month_snapshot_builder.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/models/spese_command.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  const fallbackCategory = 'Contanti / non tracciato';
  final occurredAt = DateTime(2026, 9, 12, 11);

  group('nuovi prelievi cash non tracciati', () {
    late List<String> operations;
    late _FinanceSpy finance;
    late _ExpenseSpy expenses;
    late _WalletSpy wallets;
    late SpeseMutationCoordinator coordinator;

    setUp(() {
      operations = [];
      finance = _FinanceSpy(operations);
      expenses = _ExpenseSpy(operations);
      wallets = _WalletSpy(operations);
      coordinator = SpeseMutationCoordinator(
        financeStore: finance,
        expenseStore: expenses,
        cashWalletStore: wallets,
      );
    });

    test(
      'generic withdrawal records one expense and never credits cash',
      () async {
        final command = _nonTrackedCommand(
          amount: 40,
          occurredAt: occurredAt,
          category: fallbackCategory,
          description: 'Prelievo contanti',
        );

        await coordinator.execute(command);

        expect(operations, ['finance.expense', 'expenses.add']);
        expect(finance.amount, 40);
        expect(wallets.amount, 0);
        expect(expenses.added, hasLength(1));
        final expense = expenses.added.single;
        expect(expense.isCashWithdrawal, isTrue);
        expect(expense.nonTrackedCash, isTrue);
        expect(expense.cashWalletId, isNull);
        expect(expense.category, fallbackCategory);
        expect(expense.description, 'Prelievo contanti');
        expect(expense.subject, FinanceSubject.matteo);
        expect(expense.balanceId, 'account_matteo');
        expect(expense.date, occurredAt);
        expect(expense.economicFactId, finance.economicFactId);
      },
    );

    test(
      'meaningful withdrawal preserves category and note exactly once',
      () async {
        await coordinator.execute(
          _nonTrackedCommand(
            amount: 200,
            occurredAt: occurredAt,
            category: 'Salute',
            description: 'Fisioterapista',
          ),
        );

        expect(finance.amount, 200);
        expect(wallets.amount, 0);
        expect(expenses.added, hasLength(1));
        expect(expenses.added.single.category, 'Salute');
        expect(expenses.added.single.description, 'Fisioterapista');

        final snapshot = const SpeseMonthSnapshotBuilder().build(
          expenses: expenses.added,
          cashWallets: const [],
          balances: const [],
          categories: const ['Salute'],
          observations: const [],
          observedAt: DateTime(2026, 9, 12, 12),
        );
        expect(snapshot.currentMonthTotal, 200);
        expect(snapshot.last7DaysTotal, 200);
        expect(snapshot.movementCount, 1);
        expect(snapshot.categoryTotals, {'Salute': 200});
      },
    );

    test(
      'edit removal and delete restore Finance without touching cash',
      () async {
        final expense = _nonTrackedExpense();
        expenses.current = expense;
        const builder = SpeseCommandBuilder();
        final registry = _registry();

        for (final action in [
          SpeseCommandAction.removeForEdit,
          SpeseCommandAction.delete,
        ]) {
          operations.clear();
          expenses.current = expense;
          final command = builder.buildExistingMovement(
            expense: expense,
            action: action,
            preparedAt: DateTime(2026, 9, 13),
            registry: registry,
          );

          expect(command.destination.kind, EconomicEndpointKind.external);
          await coordinator.execute(command);
          expect(operations, ['finance.restore', 'expenses.remove']);
        }
        expect(wallets.amount, 0);
      },
    );

    test('historical tracked withdrawal keeps wallet behavior', () async {
      final create = _trackedCommand();
      await coordinator.execute(create);

      expect(operations, ['finance.expense', 'wallet.add', 'expenses.add']);
      expect(wallets.amount, 40);
      final historical = expenses.added.single;
      expect(historical.nonTrackedCash, isFalse);
      expect(historical.cashWalletId, 'wallet_matteo');

      operations.clear();
      expenses.current = historical;
      final removal = const SpeseCommandBuilder().buildExistingMovement(
        expense: historical,
        action: SpeseCommandAction.delete,
        preparedAt: DateTime(2026, 9, 13),
        registry: _registry(),
      );
      await coordinator.execute(removal);
      expect(operations, [
        'finance.restore',
        'wallet.remove',
        'expenses.remove',
      ]);
      expect(wallets.amount, 0);
    });
  });

  test(
    'Ledger maps new cash to one outflow and historical cash to transfer',
    () {
      const adapter = RealExpenseEventAdapter();
      final observedAt = DateTime(2026, 9, 14);
      final current = adapter.adapt(
        _nonTrackedExpense(),
        observedAt: observedAt,
      );
      final historical = adapter.adapt(
        _trackedExpense(),
        observedAt: observedAt,
      );

      expect(current.nature, EconomicNature.outflow);
      expect(current.origins.single.kind, EconomicEndpointKind.account);
      expect(current.origins.single.referenceId, 'account_matteo');
      expect(current.destinations.single.kind, EconomicEndpointKind.external);
      expect(current.destinations.single.referenceId, isNull);
      expect(current.economicFactId, 'fact_cash');
      expect(current.sourceLinks, hasLength(1));
      expect(historical.nature, EconomicNature.internalTransfer);
      expect(historical.destinations.single.kind, EconomicEndpointKind.cash);
      expect(historical.destinations.single.referenceId, 'wallet_matteo');
    },
  );

  test('JSON reload preserves new and historical formats', () {
    final current = RealExpense.fromJson(_nonTrackedExpense().toJson());
    final historical = RealExpense.fromJson(_trackedExpense().toJson());

    expect(current.nonTrackedCash, isTrue);
    expect(current.cashWalletId, isNull);
    expect(historical.nonTrackedCash, isFalse);
    expect(historical.cashWalletId, 'wallet_matteo');

    final legacyJson = Map<String, dynamic>.from(_trackedExpense().toJson())
      ..remove('nonTrackedCash');
    expect(RealExpense.fromJson(legacyJson).nonTrackedCash, isFalse);
  });

  test('UI exposes optional metadata and creates external cash commands', () {
    final page = File('lib/screens/spese_page.dart').readAsStringSync();

    expect(page, contains("labelText: 'Categoria (facoltativa)'"));
    expect(page, contains("labelText: 'Nota / descrizione (facoltativa)'"));
    expect(page, contains("'Contanti / non tracciato'"));
    expect(page, contains("kind: EconomicEndpointKind.external"));
    expect(
      page,
      isNot(contains("final walletId = 'wallet_\${widget.balancePersonId}'")),
    );
  });
}

SpeseCommand _nonTrackedCommand({
  required double amount,
  required DateTime occurredAt,
  required String category,
  required String description,
}) => SpeseCommand(
  id: 'cash_new',
  kind: SpeseCommandKind.cashWithdrawal,
  action: SpeseCommandAction.create,
  preparedAt: DateTime(2026, 9, 12, 11, 1),
  occurredAt: occurredAt,
  origin: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.account,
    referenceId: 'account_matteo',
    label: 'Banca di Imola',
  ),
  destination: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.external,
    label: 'Contanti non tracciati',
  ),
  amount: amount,
  category: category,
  personId: 'matteo',
  description: description,
);

SpeseCommand _trackedCommand() => SpeseCommand(
  id: 'cash_old',
  kind: SpeseCommandKind.cashWithdrawal,
  action: SpeseCommandAction.create,
  preparedAt: DateTime(2026, 9, 12, 11, 1),
  occurredAt: DateTime(2026, 9, 12, 11),
  origin: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.account,
    referenceId: 'account_matteo',
    label: 'Banca di Imola',
  ),
  destination: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.cash,
    referenceId: 'wallet_matteo',
    label: 'Portafoglio Matteo',
  ),
  amount: 40,
  category: 'Portafoglio contanti',
  personId: 'matteo',
  description: 'Prelievo contanti',
);

RealExpense _nonTrackedExpense() => RealExpense(
  id: 'cash_new',
  economicFactId: 'fact_cash',
  balanceId: 'account_matteo',
  balanceName: 'Banca di Imola',
  amount: 40,
  description: 'Prelievo contanti',
  category: 'Contanti / non tracciato',
  date: DateTime(2026, 9, 12, 11),
  nonTrackedCash: true,
  isCashWithdrawal: true,
  subject: FinanceSubject.matteo,
);

RealExpense _trackedExpense() => RealExpense(
  id: 'cash_old',
  economicFactId: 'fact_old_cash',
  balanceId: 'account_matteo',
  balanceName: 'Banca di Imola',
  amount: 40,
  description: 'Prelievo contanti',
  category: 'Portafoglio contanti',
  date: DateTime(2026, 8, 12, 11),
  isCashWithdrawal: true,
  cashWalletId: 'wallet_matteo',
  subject: FinanceSubject.matteo,
);

SpeseCommandRegistry _registry() => SpeseCommandRegistry(
  accounts: {'account_matteo': 'Banca di Imola'},
  cashWallets: {'wallet_matteo': 'Portafoglio Matteo'},
  categories: {'Contanti / non tracciato', 'Portafoglio contanti', 'Salute'},
  people: {'matteo'},
);

class _FinanceSpy extends FinanceStore {
  final List<String> operations;
  double amount = 0;
  String? economicFactId;

  _FinanceSpy(this.operations);

  @override
  Future<void> registerRealExpense({
    required String balanceId,
    required double amount,
    required String description,
    String? notes,
    String? economicFactId,
    DateTime? occurredAt,
    String? transactionId,
  }) async {
    this.amount += amount;
    this.economicFactId = economicFactId;
    operations.add('finance.expense');
  }

  @override
  Future<void> restoreRealExpense({
    required String balanceId,
    required double amount,
    required String description,
  }) async {
    this.amount -= amount;
    operations.add('finance.restore');
  }
}

class _ExpenseSpy extends ExpenseStore {
  final List<String> operations;
  final List<RealExpense> added = [];
  RealExpense? current;

  _ExpenseSpy(this.operations);

  @override
  RealExpense? findById(String expenseId) =>
      current?.id == expenseId ? current : null;

  @override
  Future<void> addExpense(RealExpense expense) async {
    added.add(expense);
    current = expense;
    operations.add('expenses.add');
  }

  @override
  Future<void> removeExpense(String expenseId) async {
    current = null;
    operations.add('expenses.remove');
  }
}

class _WalletSpy extends CashWalletStore {
  final List<String> operations;
  double amount = 0;

  _WalletSpy(this.operations);

  @override
  Future<void> addCash({
    required String walletId,
    required double amount,
  }) async {
    this.amount += amount;
    operations.add('wallet.add');
  }

  @override
  Future<void> removeCash({
    required String walletId,
    required double amount,
  }) async {
    this.amount -= amount;
    operations.add('wallet.remove');
  }
}
