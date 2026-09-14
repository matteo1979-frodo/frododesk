import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/models/spese_command.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  late List<String> operations;
  late _TrackingFinanceStore financeStore;
  late _TrackingExpenseStore expenseStore;
  late _TrackingCashWalletStore cashWalletStore;
  late SpeseMutationCoordinator coordinator;

  setUp(() {
    operations = [];
    financeStore = _TrackingFinanceStore(operations);
    expenseStore = _TrackingExpenseStore(operations);
    cashWalletStore = _TrackingCashWalletStore(operations);
    coordinator = SpeseMutationCoordinator(
      financeStore: financeStore,
      expenseStore: expenseStore,
      cashWalletStore: cashWalletStore,
    );
  });

  test('prepare crea un piano senza mutare gli store', () {
    final plan = coordinator.prepare(_command(SpeseCommandKind.expense));

    expect(plan.createsExpense, isTrue);
    expect(plan.removesExpense, isFalse);
    expect(plan.expenseToCreate?.description, 'Descrizione');
    expect(operations, isEmpty);
  });

  test('commit orchestra una spesa reale nel medesimo ordine', () async {
    await coordinator.execute(_command(SpeseCommandKind.expense));

    expect(operations, ['finance.expense', 'expenses.add']);
    expect(expenseStore.lastAdded?.isIncome, isFalse);
    expect(financeStore.lastEconomicFactId, isNotNull);
    expect(
      expenseStore.lastAdded?.economicFactId,
      financeStore.lastEconomicFactId,
    );
  });

  test('commit orchestra una entrata extra nel medesimo ordine', () async {
    await coordinator.execute(_command(SpeseCommandKind.extraIncome));

    expect(operations, ['finance.income', 'expenses.add']);
    expect(expenseStore.lastAdded?.isIncome, isTrue);
    expect(financeStore.lastEconomicFactId, isNotNull);
    expect(
      expenseStore.lastAdded?.economicFactId,
      financeStore.lastEconomicFactId,
    );
  });

  test('commit orchestra conto, portafoglio e storico del prelievo', () async {
    await coordinator.execute(_command(SpeseCommandKind.cashWithdrawal));

    expect(operations, ['finance.expense', 'wallet.add', 'expenses.add']);
    expect(expenseStore.lastAdded?.cashWalletId, 'wallet_matteo');
    expect(financeStore.lastEconomicFactId, isNotNull);
    expect(
      expenseStore.lastAdded?.economicFactId,
      financeStore.lastEconomicFactId,
    );
  });

  test(
    'modifica prepara e committa la rimozione del movimento corrente',
    () async {
      final existing = _expense(isCashWithdrawal: true);
      expenseStore.current = existing;
      final command = _command(
        SpeseCommandKind.cashWithdrawal,
        action: SpeseCommandAction.removeForEdit,
        targetRecordId: existing.id,
      );

      final plan = coordinator.prepare(command);
      expect(plan.command.action, SpeseCommandAction.removeForEdit);
      expect(operations, isEmpty);

      await coordinator.commit(plan);
      expect(operations, [
        'finance.restore',
        'wallet.remove',
        'expenses.remove',
      ]);
    },
  );

  test('eliminazione annulla una entrata e rimuove lo storico', () async {
    final existing = _expense(isIncome: true);
    expenseStore.current = existing;

    await coordinator.execute(
      _command(
        SpeseCommandKind.extraIncome,
        action: SpeseCommandAction.delete,
        targetRecordId: existing.id,
      ),
    );

    expect(operations, ['finance.removeIncome', 'expenses.remove']);
  });

  test('la UI non invoca direttamente le API di mutazione', () {
    final page = File('lib/screens/spese_page.dart').readAsStringSync();

    for (final mutation in [
      '.registerRealExpense(',
      '.registerExtraIncome(',
      '.restoreRealExpense(',
      '.removeExtraIncome(',
      '.addExpense(',
      '.removeExpense(',
      '.addCash(',
      '.removeCash(',
    ]) {
      expect(page, isNot(contains(mutation)));
    }
    expect(page, contains('_executeSpeseCreationOrEdit('));
  });
}

SpeseCommand _command(
  SpeseCommandKind kind, {
  SpeseCommandAction action = SpeseCommandAction.create,
  String? targetRecordId,
}) {
  final isIncome = kind == SpeseCommandKind.extraIncome;
  final isCash = kind == SpeseCommandKind.cashWithdrawal;
  const account = SpeseCommandEndpoint(
    kind: EconomicEndpointKind.account,
    referenceId: 'account_1',
    label: 'Conto',
  );
  final external = const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.external,
    label: 'Esterno',
  );
  final cash = const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.cash,
    referenceId: 'wallet_matteo',
    label: 'Portafoglio Matteo',
  );

  return SpeseCommand(
    id: 'command_1',
    kind: kind,
    action: action,
    targetRecordId: targetRecordId,
    preparedAt: DateTime(2026, 8, 17),
    occurredAt: DateTime(2026, 8, 16),
    origin: isIncome ? external : account,
    destination: isIncome ? account : (isCash ? cash : external),
    amount: 25,
    category: isIncome ? 'Entrata extra' : 'Alimentazione',
    personId: 'matteo',
    description: 'Descrizione',
  );
}

RealExpense _expense({bool isIncome = false, bool isCashWithdrawal = false}) {
  return RealExpense(
    id: 'expense_1',
    balanceId: 'account_1',
    balanceName: 'Conto',
    amount: 25,
    description: 'Descrizione',
    category: 'Alimentazione',
    date: DateTime(2026, 8, 16),
    isIncome: isIncome,
    isCashWithdrawal: isCashWithdrawal,
    cashWalletId: isCashWithdrawal ? 'wallet_matteo' : null,
  );
}

class _TrackingFinanceStore extends FinanceStore {
  final List<String> operations;
  String? lastEconomicFactId;

  _TrackingFinanceStore(this.operations);

  @override
  Future<void> registerRealExpense({
    required String balanceId,
    required double amount,
    required String description,
    String? notes,
    String? economicFactId,
  }) async {
    lastEconomicFactId = economicFactId;
    operations.add('finance.expense');
  }

  @override
  Future<void> registerExtraIncome({
    required String balanceId,
    required double amount,
    required String description,
    String? notes,
    String? economicFactId,
  }) async {
    lastEconomicFactId = economicFactId;
    operations.add('finance.income');
  }

  @override
  Future<void> restoreRealExpense({
    required String balanceId,
    required double amount,
    required String description,
  }) async => operations.add('finance.restore');

  @override
  Future<void> removeExtraIncome({
    required String balanceId,
    required double amount,
    required String description,
  }) async => operations.add('finance.removeIncome');
}

class _TrackingExpenseStore extends ExpenseStore {
  final List<String> operations;
  RealExpense? current;
  RealExpense? lastAdded;

  _TrackingExpenseStore(this.operations);

  @override
  RealExpense? findById(String expenseId) =>
      current?.id == expenseId ? current : null;

  @override
  Future<void> addExpense(RealExpense expense) async {
    lastAdded = expense;
    operations.add('expenses.add');
  }

  @override
  Future<void> removeExpense(String expenseId) async {
    operations.add('expenses.remove');
    current = null;
  }
}

class _TrackingCashWalletStore extends CashWalletStore {
  final List<String> operations;

  _TrackingCashWalletStore(this.operations);

  @override
  Future<void> addCash({
    required String walletId,
    required double amount,
  }) async => operations.add('wallet.add');

  @override
  Future<void> removeCash({
    required String walletId,
    required double amount,
  }) async => operations.add('wallet.remove');
}
