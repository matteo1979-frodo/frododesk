import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/spese_command.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opening an edit and going back performs zero mutations', (
    tester,
  ) async {
    final fixture = await _fixture(SpeseCommandKind.expense);
    final before = fixture.capture();

    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);

    expect(fixture.capture(), before);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(fixture.capture(), before);
  });

  for (final type in [
    FinanceBalanceType.bankAccount,
    FinanceBalanceType.prepaidCard,
  ]) {
    testWidgets('editing an expense from ${type.name} replaces it on save', (
      tester,
    ) async {
      final fixture = await _fixture(
        SpeseCommandKind.expense,
        balanceType: type,
      );

      await _pumpPage(tester, fixture);
      await _openEditForm(tester, fixture.originalDescription);
      await tester.enterText(find.byType(TextField).first, '15');
      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();

      _expectCompletedEdit(fixture, expectedBalance: 85);
    });
  }

  testWidgets('editing an extra income replaces it only when saved', (
    tester,
  ) async {
    final fixture = await _fixture(SpeseCommandKind.extraIncome);

    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    _expectCompletedEdit(fixture, expectedBalance: 115);
  });

  testWidgets('editing a cash withdrawal replaces Finance and wallet effects', (
    tester,
  ) async {
    final fixture = await _fixture(SpeseCommandKind.cashWithdrawal);

    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    _expectCompletedEdit(fixture, expectedBalance: 85);
    expect(
      fixture.cashWalletStore.findById('wallet_matteo')!.currentAmount,
      15,
    );
  });
}

Future<_Fixture> _fixture(
  SpeseCommandKind kind, {
  FinanceBalanceType balanceType = FinanceBalanceType.bankAccount,
}) async {
  final financeStore = FinanceStore(initialBalances: [_balance(balanceType)]);
  final expenseStore = ExpenseStore();
  final cashWalletStore = CashWalletStore();
  final coordinator = SpeseMutationCoordinator(
    financeStore: financeStore,
    expenseStore: expenseStore,
    cashWalletStore: cashWalletStore,
  );
  final command = _command(kind, id: 'original');
  await coordinator.execute(command);

  return _Fixture(
    financeStore: financeStore,
    expenseStore: expenseStore,
    cashWalletStore: cashWalletStore,
    originalDescription: command.description,
  );
}

Future<void> _pumpPage(WidgetTester tester, _Fixture fixture) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: SpesePage(
        financeStore: fixture.financeStore,
        expenseStore: fixture.expenseStore,
        cashWalletStore: fixture.cashWalletStore,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openEditForm(WidgetTester tester, String description) async {
  await tester.tap(find.text('Vedi storico mese'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(description));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Modifica'));
  await tester.pumpAndSettle();

  if (find.text('Continua').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
  }
}

void _expectCompletedEdit(_Fixture fixture, {required double expectedBalance}) {
  expect(fixture.financeStore.balances.single.currentAmount, expectedBalance);
  expect(fixture.expenseStore.all, hasLength(1));
  final replacement = fixture.expenseStore.all.single;
  expect(replacement.id, isNot('original'));
  expect(replacement.amount, 15);

  expect(fixture.financeStore.transactions, hasLength(3));
  final facts = fixture.financeStore.transactions
      .map((transaction) => transaction.economicFactId)
      .toList();
  expect(facts.first, 'economic_fact_spese_original');
  expect(facts[1], isNot(facts.first));
  expect(facts.last, replacement.economicFactId);
  expect(facts.toSet(), hasLength(3));

  final events = const EconomicEventCollector().collect(
    transactions: fixture.financeStore.transactions,
    assetMovements: fixture.financeStore.assetMovements,
    realExpenses: fixture.expenseStore.all,
    observedAt: DateTime.now(),
  );
  final canonical = const EconomicEventCorrelator().correlate(events);
  expect(canonical, hasLength(3));
  expect(
    canonical.where(
      (event) => event.economicFactId == replacement.economicFactId,
    ),
    hasLength(1),
  );
}

FinanceBalance _balance(FinanceBalanceType type) => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: type == FinanceBalanceType.prepaidCard ? 'Prepagata' : 'Conto',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 9, 14),
  balanceType: type,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

SpeseCommand _command(SpeseCommandKind kind, {required String id}) {
  final income = kind == SpeseCommandKind.extraIncome;
  final cash = kind == SpeseCommandKind.cashWithdrawal;
  const account = SpeseCommandEndpoint(
    kind: EconomicEndpointKind.account,
    referenceId: 'account',
    label: 'Conto',
  );
  const external = SpeseCommandEndpoint(
    kind: EconomicEndpointKind.external,
    label: 'Esterno',
  );
  const wallet = SpeseCommandEndpoint(
    kind: EconomicEndpointKind.cash,
    referenceId: 'wallet_matteo',
    label: 'Portafoglio Matteo',
  );
  return SpeseCommand(
    id: id,
    kind: kind,
    action: SpeseCommandAction.create,
    preparedAt: DateTime.now(),
    occurredAt: DateTime.now(),
    origin: income ? external : account,
    destination: income ? account : (cash ? wallet : external),
    amount: 10,
    category: income
        ? 'Entrata extra'
        : (cash ? 'Portafoglio contanti' : 'Alimentazione'),
    personId: 'matteo',
    description: switch (kind) {
      SpeseCommandKind.expense => 'Spesa originale',
      SpeseCommandKind.extraIncome => 'Entrata originale',
      SpeseCommandKind.cashWithdrawal => 'Prelievo contanti',
    },
  );
}

class _Fixture {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final String originalDescription;

  const _Fixture({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    required this.originalDescription,
  });

  String capture() => [
    financeStore.balances.single.currentAmount,
    financeStore.transactions.length,
    expenseStore.all.map((expense) => expense.id).join(','),
    cashWalletStore.findById('wallet_matteo')!.currentAmount,
  ].join('|');
}
