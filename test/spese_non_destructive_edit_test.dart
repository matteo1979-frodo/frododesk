import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/logic/spese/expense_replacement_coordinator.dart';
import 'package:frododesk/logic/spese/expense_replacement_persistence.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/expense_replacement_intent.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
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
    expect(await fixture.replacementPersistence.load(), isEmpty);
  });

  testWidgets(
    'expense editor shows current balance and preserves unchanged context',
    (tester) async {
      final fixture = await _fixture(
        SpeseCommandKind.expense,
        initialAmount: 2417.47,
        expenseAmount: 13.30,
        description: 'Farmacia',
        category: 'Salute',
        subject: FinanceSubject.matteo,
        occurredAt: DateTime(2026, 9, 14, 18, 30),
        balanceName: 'Banca di Imola',
      );

      await _pumpPage(tester, fixture);
      await _openEditForm(tester, fixture.originalDescription);

      expect(find.text('Saldo attuale: €2.404,17'), findsOneWidget);
      expect(find.text('👨 Matteo'), findsOneWidget);
      expect(find.text('👨‍👩‍👧 Condiviso'), findsNothing);

      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();

      expect(
        fixture.financeStore.balances.single.currentAmount,
        closeTo(2404.17, 0.000001),
      );
      final replacement = fixture.expenseStore.all.single;
      expect(replacement.amount, 13.30);
      expect(replacement.description, 'Farmacia');
      expect(replacement.category, 'Salute');
      expect(replacement.subject, FinanceSubject.matteo);
      expect(replacement.balanceId, 'account');
      expect(replacement.balanceName, 'Banca di Imola');
      expect(replacement.date, DateTime(2026, 9, 14, 18, 30));
    },
  );

  testWidgets('ordinary expense edit is single-flight', (tester) async {
    final fixture = await _fixture(SpeseCommandKind.expense);
    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');

    await tester.tap(find.text('Salva modifiche'));
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    _expectCompletedEdit(fixture, expectedBalance: 85);
    expect(await fixture.replacementPersistence.load(), isEmpty);
  });

  testWidgets('Finance failure keeps intent and retry reuses its identity', (
    tester,
  ) async {
    var rejectFinance = false;
    final fixture = await _fixture(
      SpeseCommandKind.expense,
      financeSave: (key, value) {
        if (rejectFinance) {
          return Future.value(
            const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            ),
          );
        }
        return _saveVerified(key, value);
      },
    );
    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');
    rejectFinance = true;

    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    final pending = (await fixture.replacementPersistence.load()).single;
    expect(fixture.financeStore.balances.single.currentAmount, 90);
    expect(fixture.financeStore.transactions, hasLength(1));
    expect(fixture.expenseStore.all.single.id, 'original');

    rejectFinance = false;
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    _expectCompletedEdit(fixture, expectedBalance: 85);
    expect(
      fixture.financeStore.transactions.last.id,
      pending.identities.replacementTransactionId,
    );
    expect(await fixture.replacementPersistence.load(), isEmpty);
  });

  testWidgets('Expense failure retries without duplicate Finance facts', (
    tester,
  ) async {
    var rejectExpense = false;
    final fixture = await _fixture(
      SpeseCommandKind.expense,
      expenseSave: (key, value) {
        if (rejectExpense) {
          return Future.value(
            const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            ),
          );
        }
        return _saveVerified(key, value);
      },
    );
    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');
    rejectExpense = true;

    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    final pending = (await fixture.replacementPersistence.load()).single;
    expect(fixture.financeStore.balances.single.currentAmount, 85);
    expect(fixture.financeStore.transactions, hasLength(3));
    expect(fixture.expenseStore.all.single.id, 'original');

    rejectExpense = false;
    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    _expectCompletedEdit(fixture, expectedBalance: 85);
    expect(
      fixture.financeStore.transactions.last.id,
      pending.identities.replacementTransactionId,
    );
    expect(await fixture.replacementPersistence.load(), isEmpty);
  });

  testWidgets('matching pending intent is reused and preserves occurredAt', (
    tester,
  ) async {
    final occurredAt = DateTime(2026, 9, 14, 18, 30);
    final fixture = await _fixture(
      SpeseCommandKind.expense,
      occurredAt: occurredAt,
    );
    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    await tester.enterText(find.byType(TextField).first, '15');
    final original = fixture.expenseStore.all.single;
    final intent = ExpenseReplacementIntent(
      replacementId: 'existing-replacement',
      originalExpense: original,
      replacementPayload: ExpenseReplacementPayload(
        balanceId: original.balanceId,
        balanceName: original.balanceName,
        amount: 15,
        description: original.description,
        category: original.category,
        preparedAt: DateTime(2026, 9, 16, 12),
        occurredAt: occurredAt,
        personId: original.subject.name,
      ),
    );
    await fixture.replacementPersistence.add(intent);

    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    expect(
      fixture.financeStore.transactions.last.id,
      intent.identities.replacementTransactionId,
    );
    expect(fixture.financeStore.transactions.last.date, occurredAt);
    expect(fixture.expenseStore.all.single.date, occurredAt);
    expect(await fixture.replacementPersistence.load(), isEmpty);
  });

  testWidgets('different pending payload reports conflict without mutation', (
    tester,
  ) async {
    final fixture = await _fixture(SpeseCommandKind.expense);
    await _pumpPage(tester, fixture);
    await _openEditForm(tester, fixture.originalDescription);
    final original = fixture.expenseStore.all.single;
    final intent = ExpenseReplacementIntent(
      replacementId: 'conflicting-replacement',
      originalExpense: original,
      replacementPayload: ExpenseReplacementPayload(
        balanceId: original.balanceId,
        balanceName: original.balanceName,
        amount: 99,
        description: original.description,
        category: original.category,
        preparedAt: DateTime(2026, 9, 16, 12),
        occurredAt: original.date,
        personId: original.subject.name,
      ),
    );
    await fixture.replacementPersistence.add(intent);
    final before = fixture.capture();

    await tester.tap(find.text('Salva modifiche'));
    await tester.pumpAndSettle();

    expect(fixture.capture(), before);
    expect(
      (await fixture.replacementPersistence.load()).single.replacementId,
      intent.replacementId,
    );
    expect(find.textContaining('modifica pendente'), findsOneWidget);
  });

  for (final subject in [
    FinanceSubject.matteo,
    FinanceSubject.chiara,
    FinanceSubject.shared,
  ]) {
    testWidgets('expense editor prefills ${subject.name} canonically', (
      tester,
    ) async {
      final fixture = await _fixture(
        SpeseCommandKind.expense,
        subject: subject,
      );

      await _pumpPage(tester, fixture);
      await _openEditForm(tester, fixture.originalDescription);

      final dropdown = tester.widget<DropdownButtonFormField<FinanceSubject>>(
        find.byType(DropdownButtonFormField<FinanceSubject>),
      );
      expect(dropdown.initialValue, subject);
    });
  }

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
  double initialAmount = 100,
  double expenseAmount = 10,
  String? description,
  String? category,
  FinanceSubject subject = FinanceSubject.matteo,
  DateTime? occurredAt,
  String? balanceName,
  Future<PersistenceWriteVerification> Function(String, String)? financeSave,
  Future<PersistenceWriteVerification> Function(String, String)? expenseSave,
}) async {
  final balance = _balance(
    balanceType,
    personId: subject.name,
    initialAmount: initialAmount,
    name: balanceName,
  );
  final portfolio = FinancePortfolioV3(
    balances: [balance],
    funds: const [],
    assetMovements: const [],
    transactions: const [],
    fundTransactions: const [],
    linkedItems: const [],
  );
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final financeStore = FinanceStore(
    portfolioV3Writer: FinancePortfolioV3Writer(
      saveVerified: financeSave ?? _saveVerified,
    ),
  );
  expect(await financeStore.loadSavedPortfolioV3(), isTrue);
  final expenseStore = ExpenseStore(saveVerified: expenseSave);
  await expenseStore.load();
  final cashWalletStore = CashWalletStore();
  final coordinator = SpeseMutationCoordinator(
    financeStore: financeStore,
    expenseStore: expenseStore,
    cashWalletStore: cashWalletStore,
  );
  final command = _command(
    kind,
    id: 'original',
    amount: expenseAmount,
    description: description,
    category: category,
    subject: subject,
    occurredAt: occurredAt,
    balanceName: balanceName,
  );
  await coordinator.execute(command);
  final replacementPersistence = ExpenseReplacementPersistence();
  final replacementCoordinator = ExpenseReplacementCoordinator(
    financeStore: financeStore,
    expenseStore: expenseStore,
    persistence: replacementPersistence,
  );

  return _Fixture(
    financeStore: financeStore,
    expenseStore: expenseStore,
    cashWalletStore: cashWalletStore,
    replacementPersistence: replacementPersistence,
    replacementCoordinator: replacementCoordinator,
    originalDescription: command.description,
  );
}

Future<PersistenceWriteVerification> _saveVerified(
  String key,
  String value,
) async {
  final prefs = await SharedPreferences.getInstance();
  final accepted = await prefs.setString('frododesk_$key', value);
  return PersistenceWriteVerification(
    backendAccepted: accepted,
    readBack: prefs.getString('frododesk_$key'),
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
        expenseReplacementPersistence: fixture.replacementPersistence,
        expenseReplacementCoordinator: fixture.replacementCoordinator,
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

FinanceBalance _balance(
  FinanceBalanceType type, {
  required String personId,
  required double initialAmount,
  String? name,
}) => FinanceBalance(
  personId: personId,
  balanceId: 'account',
  name:
      name ?? (type == FinanceBalanceType.prepaidCard ? 'Prepagata' : 'Conto'),
  initialAmount: initialAmount,
  currentAmount: initialAmount,
  updatedAt: DateTime(2026, 9, 14),
  balanceType: type,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

SpeseCommand _command(
  SpeseCommandKind kind, {
  required String id,
  double amount = 10,
  String? description,
  String? category,
  FinanceSubject subject = FinanceSubject.matteo,
  DateTime? occurredAt,
  String? balanceName,
}) {
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
    occurredAt: occurredAt ?? DateTime.now(),
    origin: income
        ? external
        : SpeseCommandEndpoint(
            kind: account.kind,
            referenceId: account.referenceId,
            label: balanceName ?? account.label,
          ),
    destination: income ? account : (cash ? wallet : external),
    amount: amount,
    category:
        category ??
        (income
            ? 'Entrata extra'
            : (cash ? 'Portafoglio contanti' : 'Alimentazione')),
    personId: subject.name,
    description:
        description ??
        switch (kind) {
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
  final ExpenseReplacementPersistence replacementPersistence;
  final ExpenseReplacementCoordinator replacementCoordinator;
  final String originalDescription;

  const _Fixture({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    required this.replacementPersistence,
    required this.replacementCoordinator,
    required this.originalDescription,
  });

  String capture() => [
    financeStore.balances.single.currentAmount,
    financeStore.transactions.length,
    expenseStore.all.map((expense) => expense.id).join(','),
    cashWalletStore.findById('wallet_matteo')!.currentAmount,
  ].join('|');
}
