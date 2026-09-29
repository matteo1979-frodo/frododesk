import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_ledger_presentation_coordinator.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_presentation_data.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/finance/finance_ledger_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Finance route is wired to Ledger 2.0 without removing legacy code', () {
    final finance = File('lib/screens/finance_screen.dart').readAsStringSync();
    final page = File(
      'lib/screens/finance/finance_ledger_page.dart',
    ).readAsStringSync();
    final legacy = File('lib/logic/finance/finance_ledger_coordinator.dart');

    expect(finance, contains('FinanceLedgerPresentationCoordinator('));
    expect(finance, contains('expenseStore: widget.expenseStore'));
    expect(finance, contains('cashWalletStore: widget.cashWalletStore'));
    expect(page, isNot(contains('FinanceLedgerCoordinator')));
    expect(page, isNot(contains('fundOperations')));
    expect(page, isNot(contains('FinanceLedgerOriginFilter')));
    expect(legacy.existsSync(), isTrue);
  });

  test(
    'composition produces canonical entries and never mutates stores',
    () async {
      final fixture = await _fixture();
      final before = fixture.stateJson;

      final data = fixture.coordinator.build(observedAt: DateTime(2026, 9, 14));

      expect(data.state, LedgerPresentationState.results);
      expect(data.entries, hasLength(7));
      expect(
        data.entries.where((entry) => entry.eventId == 'economic_fact:expense'),
        hasLength(1),
      );
      expect(
        data.entries
            .singleWhere(
              (entry) => entry.eventId == 'economic_fact:account-transfer',
            )
            .subtitle,
        'Conto A → Conto B',
      );
      final prepaid = data.entries.singleWhere(
        (entry) => entry.eventId == 'economic_fact:prepaid-transfer',
      );
      expect(prepaid.subtitle, 'Conto A → Prepagata');
      expect(
        prepaid.counterparties.last.balanceType,
        FinanceBalanceType.prepaidCard,
      );
      expect(
        data.entries
            .singleWhere(
              (entry) => entry.eventId == 'economic_fact:fund-transfer',
            )
            .subtitle,
        'Vacanze → Auto',
      );
      expect(
        data.entries.where(
          (entry) =>
              entry.eventId.startsWith('finance_transaction:legacy') ||
              entry.eventId.startsWith('real_expense:legacy'),
        ),
        hasLength(2),
      );
      expect(fixture.stateJson, before);
    },
  );

  testWidgets('page searches notes, filters nature and shows safe detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await _fixture();
    final before = fixture.stateJson;

    await tester.pumpWidget(
      MaterialApp(home: FinanceLedgerPage(coordinator: fixture.coordinator)),
    );
    await tester.pump();

    expect(find.text('Movimenti della famiglia'), findsOneWidget);
    expect(find.text('Tutte le origini'), findsNothing);
    expect(find.textContaining('Conto A → Conto B'), findsOneWidget);
    expect(find.textContaining('Conto A → Prepagata'), findsOneWidget);
    expect(find.textContaining('Vacanze → Auto'), findsOneWidget);

    await tester.tap(find.text('Ricorrenza mensile'));
    await tester.pumpAndSettle();
    expect(find.text('Ricorrente'), findsOneWidget);
    expect(find.text('Nota ricorrente'), findsOneWidget);
    expect(find.text('rule-internal'), findsNothing);
    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nota ricorrente');
    await tester.pump();
    expect(find.text('Ricorrenza mensile'), findsOneWidget);
    expect(find.text('Spesa casa'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byType(DropdownButton<FinanceLedgerNatureFilter>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trasferimenti').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Conto A → Conto B'), findsOneWidget);
    expect(find.text('Spesa casa'), findsNothing);
    expect(fixture.stateJson, before);
  });

  testWidgets(
    'page distinguishes empty, no-results and preserves back navigation',
    (tester) async {
      final empty = _emptyCoordinator();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FinanceLedgerPage(coordinator: empty),
                ),
              ),
              child: const Text('Apri'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
      expect(find.text('Nessun movimento disponibile'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Apri'), findsOneWidget);

      final populated = FinanceLedgerPresentationCoordinator(
        financeStore: FinanceStore(
          initialBalances: [_balance('bank-a', 'Conto A')],
          initialTransactions: [_transaction('income', income: true)],
        ),
        expenseStore: ExpenseStore(),
        cashWalletStore: CashWalletStore(),
      );
      await tester.pumpWidget(
        MaterialApp(home: FinanceLedgerPage(coordinator: populated)),
      );
      await tester.enterText(find.byType(TextField), 'nessuna corrispondenza');
      await tester.pump();
      expect(find.text('Nessun movimento trovato'), findsOneWidget);
    },
  );
}

class _Fixture {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore walletStore;
  final FinanceLedgerPresentationCoordinator coordinator;

  const _Fixture({
    required this.financeStore,
    required this.expenseStore,
    required this.walletStore,
    required this.coordinator,
  });

  String get stateJson => jsonEncode({
    'balances': financeStore.balances.map((item) => item.toJson()).toList(),
    'funds': financeStore.funds.map((item) => item.toJson()).toList(),
    'transactions': financeStore.transactions
        .map((item) => item.toJson())
        .toList(),
    'movements': financeStore.assetMovements
        .map((item) => item.toJson())
        .toList(),
    'expenses': expenseStore.all.map((item) => item.toJson()).toList(),
    'wallets': walletStore.all.map((item) => item.toJson()).toList(),
  });
}

Future<_Fixture> _fixture() async {
  final finance = FinanceStore(
    initialBalances: [
      _balance('bank-a', 'Conto A'),
      _balance('bank-b', 'Conto B'),
      _balance('prepaid', 'Prepagata', type: FinanceBalanceType.prepaidCard),
    ],
    initialFunds: const [
      FinanceFund(
        id: 'fund-a',
        name: 'Vacanze',
        description: '',
        amount: 20,
        protected: false,
        category: FinanceFundCategory.generic,
      ),
      FinanceFund(
        id: 'fund-b',
        name: 'Auto',
        description: '',
        amount: 20,
        protected: false,
        category: FinanceFundCategory.auto,
      ),
    ],
    initialTransactions: [
      _transaction('expense-tx', factId: 'expense', description: 'Spesa casa'),
      _transaction(
        'account-out',
        factId: 'account-transfer',
        balanceId: 'bank-a',
        type: FinanceTransactionType.transfer,
        description: 'Giroconto',
      ),
      _transaction(
        'account-in',
        factId: 'account-transfer',
        balanceId: 'bank-b',
        type: FinanceTransactionType.transfer,
        income: true,
        description: 'Giroconto',
      ),
      _transaction(
        'prepaid-out',
        factId: 'prepaid-transfer',
        balanceId: 'bank-a',
        type: FinanceTransactionType.transfer,
        description: 'Ricarica',
      ),
      _transaction(
        'prepaid-in',
        factId: 'prepaid-transfer',
        balanceId: 'prepaid',
        type: FinanceTransactionType.transfer,
        income: true,
        description: 'Ricarica',
      ),
      _transaction('legacy-tx', description: 'Legacy transazione'),
      _transaction(
        'recurring',
        factId: 'recurring-fact',
        description: 'Ricorrenza mensile',
        origin: FinanceTransactionOrigin.recurringItem,
        recurringItemId: 'rule-internal',
        notes: 'Nota ricorrente',
      ),
    ],
    initialAssetMovements: [
      _fundMovement('fund-out', FinanceAssetMovementKind.fundTransferOut),
      _fundMovement('fund-in', FinanceAssetMovementKind.fundTransferIn),
    ],
  );
  final expenses = ExpenseStore();
  await expenses.load();
  await expenses.addExpense(
    RealExpense(
      id: 'expense-record',
      economicFactId: 'expense',
      balanceId: 'bank-a',
      balanceName: 'Conto A',
      amount: 20,
      description: 'Spesa casa',
      category: 'Casa',
      date: DateTime(2026, 9, 14),
      subject: FinanceSubject.matteo,
    ),
  );
  await expenses.addExpense(
    RealExpense(
      id: 'legacy-expense',
      balanceId: 'bank-a',
      balanceName: 'Conto A',
      amount: 20,
      description: 'Legacy spesa',
      category: 'Casa',
      date: DateTime(2026, 9, 14),
      subject: FinanceSubject.matteo,
    ),
  );
  final wallets = CashWalletStore();
  return _Fixture(
    financeStore: finance,
    expenseStore: expenses,
    walletStore: wallets,
    coordinator: FinanceLedgerPresentationCoordinator(
      financeStore: finance,
      expenseStore: expenses,
      cashWalletStore: wallets,
    ),
  );
}

FinanceLedgerPresentationCoordinator _emptyCoordinator() =>
    FinanceLedgerPresentationCoordinator(
      financeStore: FinanceStore(),
      expenseStore: ExpenseStore(),
      cashWalletStore: CashWalletStore(),
    );

FinanceBalance _balance(
  String id,
  String name, {
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: name,
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

FinanceTransaction _transaction(
  String id, {
  String? factId,
  String balanceId = 'bank-a',
  bool income = false,
  FinanceTransactionType type = FinanceTransactionType.expense,
  String description = 'Movimento',
  FinanceTransactionOrigin origin = FinanceTransactionOrigin.manual,
  String? recurringItemId,
  String? notes,
}) => FinanceTransaction(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  amount: 20,
  date: DateTime(2026, 9, 14),
  isIncome: income,
  subject: FinanceSubject.matteo,
  description: description,
  type: type,
  origin: origin,
  recurringItemId: recurringItemId,
  notes: notes,
);

FinanceAssetMovement _fundMovement(String id, FinanceAssetMovementKind kind) =>
    FinanceAssetMovement(
      id: id,
      economicFactId: 'fund-transfer',
      fundId: kind == FinanceAssetMovementKind.fundTransferOut
          ? 'fund-a'
          : 'fund-b',
      kind: kind,
      description: 'Cambio fondo',
      occurredAt: DateTime(2026, 9, 14),
      legs: const [
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: 'fund-a',
          delta: -20,
        ),
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: 'fund-b',
          delta: 20,
        ),
      ],
    );
