import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_ledger_coordinator.dart';
import 'package:frododesk/logic/finance/finance_ledger_presentation_coordinator.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_ledger_view_data.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/screens/finance/finance_ledger_page.dart';

void main() {
  test('ledger sorts, searches and filters the global family transactions', () {
    final store = FinanceStore(
      initialBalances: [
        FinanceBalance(
          balanceId: 'b1',
          personId: 'matteo',
          name: 'Conto casa',
          active: true,
          initialAmount: 0,
          currentAmount: 0,
          updatedAt: DateTime(2026),
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          reservedAmount: 0,
          warningThreshold: 0,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
      ],
      initialTransactions: [
        _transaction(
          'old',
          DateTime(2026, 1, 1),
          FinanceTransactionType.expense,
          FinanceTransactionOrigin.manual,
          'Spesa casa',
        ),
        _transaction(
          'new',
          DateTime(2026, 2, 1),
          FinanceTransactionType.income,
          FinanceTransactionOrigin.recurringItem,
          'Stipendio',
        ),
      ],
    );
    final coordinator = FinanceLedgerCoordinator(financeStore: store);

    expect(coordinator.build().entries.map((entry) => entry.transaction.id), [
      'new',
      'old',
    ]);
    expect(
      coordinator.build(query: 'spesa').entries.single.transaction.id,
      'old',
    );
    expect(
      coordinator
          .build(
            type: FinanceLedgerTypeFilter.income,
            origin: FinanceLedgerOriginFilter.recurringItem,
          )
          .entries
          .single
          .transaction
          .id,
      'new',
    );
  });

  testWidgets('ledger page exposes search filters and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceLedgerPage(
          coordinator: _presentationCoordinator(FinanceStore()),
        ),
      ),
    );

    expect(find.text('Movimenti della famiglia'), findsOneWidget);
    expect(find.text('Cerca descrizione, conto, fondo o note'), findsOneWidget);
    expect(find.text('Nessun movimento disponibile'), findsOneWidget);
    expect(find.text('Tutte le origini'), findsNothing);
  });

  test('presentation describes every account in a multi-account transfer', () {
    final store = FinanceStore(
      initialBalances: [
        _balance('matteo-account', 'matteo', 'Conto Matteo'),
        _balance('chiara-account', 'chiara', 'Conto Chiara'),
      ],
      initialFunds: const [
        FinanceFund(
          id: 'vacanze',
          name: 'Fondo Vacanze',
          description: '',
          amount: 700,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
      ],
      initialAssetMovements: [
        FinanceAssetMovement(
          id: 'allocation',
          fundId: 'vacanze',
          kind: FinanceAssetMovementKind.fundAllocation,
          description: '',
          occurredAt: DateTime(2026, 8, 12),
          legs: const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.balance,
              referenceId: 'matteo-account',
              delta: -100,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.balance,
              referenceId: 'chiara-account',
              delta: -600,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'vacanze',
              delta: 700,
            ),
          ],
        ),
      ],
    );

    final operation = FinanceLedgerCoordinator(
      financeStore: store,
    ).build().fundOperations.single;

    expect(operation.typeLabel, 'Trasferimento al fondo');
    expect(operation.description, 'Trasferimento al fondo');
    expect(operation.origins.map((item) => item.name), [
      'Conto Matteo',
      'Conto Chiara',
    ]);
    expect(operation.origins.map((item) => item.ownerName), [
      'Matteo',
      'Chiara',
    ]);
    expect(operation.origins.map((item) => item.amount), [100, 600]);
    expect(operation.destinations.single.name, 'Fondo Vacanze');
  });

  test('fund-to-fund history appears once in the global ledger', () {
    final occurredAt = DateTime(2026, 8, 12);
    const legs = [
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'vacanze',
        delta: -200,
      ),
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'auto',
        delta: 200,
      ),
    ];
    final store = FinanceStore(
      initialFunds: const [
        FinanceFund(
          id: 'vacanze',
          name: 'Vacanze',
          description: '',
          amount: 300,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
        FinanceFund(
          id: 'auto',
          name: 'Fondo Auto',
          description: '',
          amount: 300,
          protected: false,
          category: FinanceFundCategory.auto,
        ),
      ],
      initialAssetMovements: [
        FinanceAssetMovement(
          id: 'transfer-out',
          fundId: 'vacanze',
          kind: FinanceAssetMovementKind.fundTransferOut,
          description: 'Cambio obiettivo',
          occurredAt: occurredAt,
          legs: legs,
        ),
        FinanceAssetMovement(
          id: 'transfer-in',
          fundId: 'auto',
          kind: FinanceAssetMovementKind.fundTransferIn,
          description: 'Cambio obiettivo',
          occurredAt: occurredAt,
          legs: legs,
        ),
      ],
    );

    final operations = FinanceLedgerCoordinator(
      financeStore: store,
    ).build().fundOperations;

    expect(operations, hasLength(1));
    expect(operations.single.typeLabel, 'Trasferimento tra fondi');
    expect(operations.single.amount, 200);
    expect(operations.single.origins.single.name, 'Vacanze');
    expect(operations.single.destinations.single.name, 'Fondo Auto');
  });

  testWidgets('fund ledger uses transfer icon and visual fund names', (
    tester,
  ) async {
    final store = FinanceStore(
      initialFunds: const [
        FinanceFund(
          id: 'vacanze',
          name: 'vacanze',
          description: '',
          amount: 300,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
        FinanceFund(
          id: 'auto',
          name: 'fondo Auto',
          description: '',
          amount: 300,
          protected: false,
          category: FinanceFundCategory.auto,
        ),
      ],
      initialAssetMovements: [
        FinanceAssetMovement(
          id: 'transfer-out',
          fundId: 'vacanze',
          kind: FinanceAssetMovementKind.fundTransferOut,
          description: 'Cambio obiettivo',
          occurredAt: DateTime(2026, 8, 17),
          legs: const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'vacanze',
              delta: -200,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'auto',
              delta: 200,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceLedgerPage(coordinator: _presentationCoordinator(store)),
      ),
    );

    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.textContaining('vacanze → fondo Auto'), findsOneWidget);
    expect(find.text('vacanze'), findsNothing);
  });

  test(
    'normal expense has a meaningful fallback and identifies its account',
    () {
      final store = FinanceStore(
        initialBalances: [_balance('b1', 'matteo', 'Banca di Imola')],
        initialTransactions: [
          _transaction(
            'imu',
            DateTime(2026, 6, 16),
            FinanceTransactionType.expense,
            FinanceTransactionOrigin.manual,
            '',
          ),
        ],
      );

      final entry = FinanceLedgerCoordinator(
        financeStore: store,
      ).build().entries.single;

      expect(entry.typeLabel, 'Uscita');
      expect(entry.description, 'Pagamento dal conto');
      expect(entry.accountRoleLabel, 'Pagato con');
      expect(entry.balanceName, 'Banca di Imola');
      expect(entry.ownerName, 'Matteo');
    },
  );

  testWidgets('history renders type, account, owner, date and amount', (
    tester,
  ) async {
    final store = FinanceStore(
      initialBalances: [_balance('b1', 'matteo', 'Banca di Imola')],
      initialTransactions: [
        _transaction(
          'imu',
          DateTime(2026, 6, 16),
          FinanceTransactionType.expense,
          FinanceTransactionOrigin.manual,
          'IMU',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceLedgerPage(coordinator: _presentationCoordinator(store)),
      ),
    );

    expect(find.text('IMU'), findsOneWidget);
    expect(find.textContaining('Banca di Imola →'), findsOneWidget);
    expect(find.textContaining('16/06/2026'), findsOneWidget);
    expect(find.text('-€10,00'), findsOneWidget);
  });

  testWidgets('visible legacy ledger uses Italian euro presentation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = FinanceStore(
      initialBalances: [_balance('b1', 'matteo', 'Banca di Imola')],
      initialTransactions: [
        _transaction(
          'income-100',
          DateTime(2026, 8, 21),
          FinanceTransactionType.income,
          FinanceTransactionOrigin.manual,
          'Entrata intera',
          amount: 100,
        ),
        _transaction(
          'expense-cents',
          DateTime(2026, 8, 20),
          FinanceTransactionType.expense,
          FinanceTransactionOrigin.manual,
          'Uscita precisa',
          amount: 100.25,
        ),
        _transaction(
          'transfer-large',
          DateTime(2026, 8, 19),
          FinanceTransactionType.transfer,
          FinanceTransactionOrigin.manual,
          'Trasferimento grande',
          amount: 1234.56,
        ),
        _transaction(
          'zero',
          DateTime(2026, 8, 18),
          FinanceTransactionType.expense,
          FinanceTransactionOrigin.manual,
          'Zero',
          amount: -0.0,
        ),
      ],
      initialFunds: const [
        FinanceFund(
          id: 'fund',
          name: 'Fondo grande',
          description: '',
          amount: 1234567.89,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
      ],
      initialAssetMovements: [
        FinanceAssetMovement(
          id: 'fund-large',
          fundId: 'fund',
          kind: FinanceAssetMovementKind.fundOpening,
          description: 'Apertura fondo',
          occurredAt: DateTime(2026, 8, 17),
          legs: const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.openingBalance,
              delta: -1234567.89,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'fund',
              delta: 1234567.89,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceLedgerPage(coordinator: _presentationCoordinator(store)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('+€100,00'), findsOneWidget);
    expect(find.text('-€100,25'), findsOneWidget);
    expect(find.text('€1.234,56'), findsOneWidget);
    expect(find.text('€0,00'), findsOneWidget);
    expect(find.text('€1.234.567,89'), findsWidgets);

    await tester.tap(find.text('Uscita precisa'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Importo'), findsOneWidget);
    expect(find.text('€100,25'), findsOneWidget);
  });
}

FinanceLedgerPresentationCoordinator _presentationCoordinator(
  FinanceStore store,
) => FinanceLedgerPresentationCoordinator(
  financeStore: store,
  expenseStore: ExpenseStore(),
  cashWalletStore: CashWalletStore(),
);

FinanceBalance _balance(String id, String personId, String name) =>
    FinanceBalance(
      balanceId: id,
      personId: personId,
      name: name,
      active: true,
      initialAmount: 1000,
      currentAmount: 1000,
      updatedAt: DateTime(2026),
      balanceType: FinanceBalanceType.bankAccount,
      operational: true,
      reservedAmount: 0,
      warningThreshold: 0,
      persistentStressDays: 0,
      recoveryDays: 0,
    );

FinanceTransaction _transaction(
  String id,
  DateTime date,
  FinanceTransactionType type,
  FinanceTransactionOrigin origin,
  String description, {
  double amount = 10,
}) {
  return FinanceTransaction(
    id: id,
    balanceId: 'b1',
    amount: amount,
    date: date,
    isIncome: type == FinanceTransactionType.income,
    subject: FinanceSubject.shared,
    description: description,
    type: type,
    origin: origin,
  );
}
