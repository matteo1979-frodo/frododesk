import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/composite_economic_operation_coordinator.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final cases = <({String bank, String postal, int accessories})>[
    (bank: '', postal: '', accessories: 0),
    (bank: '2', postal: '', accessories: 1),
    (bank: '', postal: '1', accessories: 1),
    (bank: '2', postal: '1', accessories: 2),
  ];
  for (final testCase in cases) {
    testWidgets(
      'utility bill builds main plus ${testCase.accessories} accessories',
      (tester) async {
        final fixture = _Fixture.create();
        await _pumpPage(tester, fixture);
        await _openUtilityForm(tester);
        await _fillUtilityForm(
          tester,
          bank: testCase.bank,
          postal: testCase.postal,
        );

        if (testCase.accessories == 2) {
          expect(
            find.text('Totale addebitato al conto: €62,63'),
            findsOneWidget,
          );
        }

        await tester.tap(find.text('Conferma bolletta'));
        await tester.pumpAndSettle();

        expect(fixture.coordinator.calls, 1);
        final operation = fixture.coordinator.postings.single.operation;
        expect(operation.main.amount, 59.63);
        expect(operation.accessories, hasLength(testCase.accessories));
        expect({
          operation.main.economicFactId,
          ...operation.accessories.map((fact) => fact.economicFactId),
        }, hasLength(testCase.accessories + 1));
        expect({
          operation.main.operationMetadata.operationId,
          ...operation.accessories.map(
            (fact) => fact.operationMetadata.operationId,
          ),
        }, hasLength(1));
        if (testCase.accessories == 2) {
          expect(operation.totalAmount, closeTo(62.63, 1e-9));
          expect(
            operation.accessories
                .map((fact) => fact.operationMetadata.accessoryCostType)
                .toList(),
            [
              AccessoryCostType.bankCommission,
              AccessoryCostType.postalAcceptanceCharge,
            ],
          );
        }
      },
    );
  }

  testWidgets('double submit is single-flight and keeps one stable identity', (
    tester,
  ) async {
    final pending = Completer<CompositeEconomicOperationResult>();
    final fixture = _Fixture.create(pending: pending);
    await _pumpPage(tester, fixture);
    await _openUtilityForm(tester);
    await _fillUtilityForm(tester, bank: '2', postal: '1');

    final button = find.text('Conferma bolletta');
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();

    expect(fixture.coordinator.calls, 1);
    expect(find.text('Registrazione in corso...'), findsOneWidget);
    pending.complete(CompositeEconomicOperationResult.completed());
    await tester.pumpAndSettle();

    expect(fixture.coordinator.calls, 1);
    expect(fixture.coordinator.operationIds.toSet(), hasLength(1));
  });

  for (final status in [
    CompositeEconomicOperationStatus.failed,
    CompositeEconomicOperationStatus.inconsistent,
  ]) {
    testWidgets('$status remains visible and never reports success', (
      tester,
    ) async {
      final fixture = _Fixture.create(status: status);
      await _pumpPage(tester, fixture);
      await _openUtilityForm(tester);
      await _fillUtilityForm(tester);

      await tester.tap(find.text('Conferma bolletta'));
      await tester.pumpAndSettle();

      expect(find.text('Importo bolletta'), findsOneWidget);
      expect(find.text('Bolletta registrata.'), findsNothing);
      expect(find.textContaining('Bolletta non registrata:'), findsOneWidget);
    });
  }

  testWidgets('alreadyComplete reports idempotent success without a retry', (
    tester,
  ) async {
    final fixture = _Fixture.create(
      status: CompositeEconomicOperationStatus.alreadyComplete,
    );
    await _pumpPage(tester, fixture);
    await _openUtilityForm(tester);
    await _fillUtilityForm(tester);

    await tester.tap(find.text('Conferma bolletta'));
    await tester.pumpAndSettle();

    expect(fixture.coordinator.calls, 1);
    expect(find.text('Bolletta già registrata.'), findsOneWidget);
  });

  testWidgets('ordinary expense and cash withdrawal choices remain available', (
    tester,
  ) async {
    await _pumpPage(tester, _Fixture.create());

    await tester.tap(find.text('Nuovo movimento'));
    await tester.pumpAndSettle();

    expect(find.text('Spesa reale'), findsOneWidget);
    expect(find.text('Prelievo contanti'), findsOneWidget);
    expect(find.text('Entrata extra'), findsOneWidget);
    expect(find.text('Bolletta con costi accessori'), findsOneWidget);
  });

  final presentationCases =
      <({String name, EconomicOperationMetadata? metadata, String expected})>[
        (name: 'legacy', metadata: null, expected: 'Bolletta acqua Hera'),
        (
          name: 'main',
          metadata: EconomicOperationMetadata(
            operationId: 'operation-hera',
            role: OperationRole.main,
            context: OperationContext.utilityBill,
          ),
          expected: 'Bolletta acqua Hera',
        ),
        (
          name: 'bank commission',
          metadata: EconomicOperationMetadata(
            operationId: 'operation-hera',
            role: OperationRole.accessory,
            context: OperationContext.utilityBill,
            accessoryCostType: AccessoryCostType.bankCommission,
          ),
          expected: 'Commissione bancaria',
        ),
        (
          name: 'postal acceptance',
          metadata: EconomicOperationMetadata(
            operationId: 'operation-hera',
            role: OperationRole.accessory,
            context: OperationContext.utilityBill,
            accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
          ),
          expected: 'Costo accettazione postale',
        ),
      ];
  for (final testCase in presentationCases) {
    testWidgets('expense card presents ${testCase.name} semantically', (
      tester,
    ) async {
      final fixture = _Fixture.create();
      await fixture.expenseStore.addExpense(
        RealExpense(
          id: 'expense-${testCase.name}',
          balanceId: 'account',
          balanceName: 'Conto test',
          amount: 1,
          description: 'Bolletta acqua Hera',
          category: 'Acqua',
          date: DateTime.now(),
          subject: FinanceSubject.matteo,
          economicFactId: 'fact-${testCase.name}',
          operationMetadata: testCase.metadata,
        ),
      );

      await _pumpPage(tester, fixture);

      expect(find.text(testCase.expected), findsOneWidget);
    });
  }

  testWidgets('accessory detail preserves the operation description', (
    tester,
  ) async {
    final fixture = _Fixture.create();
    await fixture.expenseStore.addExpense(
      RealExpense(
        id: 'expense-bank',
        balanceId: 'account',
        balanceName: 'Conto test',
        amount: 2,
        description: 'Bolletta acqua Hera',
        category: 'Acqua',
        date: DateTime.now(),
        subject: FinanceSubject.matteo,
        economicFactId: 'fact-bank',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation-hera',
          role: OperationRole.accessory,
          context: OperationContext.utilityBill,
          accessoryCostType: AccessoryCostType.bankCommission,
        ),
      ),
    );
    await _pumpPage(tester, fixture);

    await tester.tap(find.text('Vedi storico mese'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commissione bancaria'));
    await tester.pumpAndSettle();

    expect(find.text('Operazione: Bolletta acqua Hera'), findsOneWidget);
  });

  testWidgets(
    'new movement picker scrolls without overflow on a short viewport',
    (tester) async {
      await _pumpPage(
        tester,
        _Fixture.create(),
        surfaceSize: const Size(1200, 500),
      );

      await tester.tap(find.text('Nuovo movimento'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Spesa reale'), findsOneWidget);
      expect(find.text('Bolletta con costi accessori'), findsOneWidget);
      expect(find.text('Prelievo contanti'), findsOneWidget);
      expect(find.text('Entrata extra'), findsOneWidget);

      final scrollable = find.descendant(
        of: find.byType(SingleChildScrollView).last,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Entrata extra'),
        150,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Entrata extra'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Bolletta con costi accessori'),
        -150,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Bolletta con costi accessori'));
      await tester.pumpAndSettle();

      expect(find.text('Nuova bolletta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('composite expense detail blocks single-fact edit and delete', (
    tester,
  ) async {
    final fixture = _Fixture.create();
    await fixture.expenseStore.addExpense(
      RealExpense(
        id: 'expense-main',
        balanceId: 'account',
        balanceName: 'Conto test',
        amount: 59.63,
        description: 'Bolletta test',
        category: 'Casa',
        date: DateTime.now(),
        subject: FinanceSubject.matteo,
        economicFactId: 'fact-main',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation-test',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
        ),
      ),
    );
    await _pumpPage(tester, fixture);

    await tester.tap(find.text('Vedi storico mese'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bolletta test'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Operazione composta: modifica ed eliminazione non disponibili.',
      ),
      findsOneWidget,
    );
    expect(find.text('Modifica'), findsNothing);
    expect(find.text('Elimina'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _Fixture fixture, {
  Size surfaceSize = const Size(1200, 1800),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: SpesePage(
        financeStore: fixture.financeStore,
        expenseStore: fixture.expenseStore,
        cashWalletStore: fixture.cashWalletStore,
        compositeCoordinator: fixture.coordinator,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openUtilityForm(WidgetTester tester) async {
  await tester.tap(find.text('Nuovo movimento'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bolletta con costi accessori'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Conto test'));
  await tester.pumpAndSettle();
}

Future<void> _fillUtilityForm(
  WidgetTester tester, {
  String bank = '',
  String postal = '',
}) async {
  await tester.enterText(_field('Importo principale'), '59,63');
  if (bank.isNotEmpty) {
    await tester.enterText(_field('Commissione bancaria (facoltativa)'), bank);
  }
  if (postal.isNotEmpty) {
    await tester.enterText(
      _field('Costo accettazione postale (facoltativo)'),
      postal,
    );
  }
  await tester.enterText(_field('Descrizione'), 'Bolletta test');
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Casa').last);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

class _Fixture {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final _RecordingCoordinator coordinator;

  _Fixture._({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    required this.coordinator,
  });

  factory _Fixture.create({
    CompositeEconomicOperationStatus status =
        CompositeEconomicOperationStatus.completed,
    Completer<CompositeEconomicOperationResult>? pending,
  }) {
    final financeStore = FinanceStore(
      initialBalances: [
        FinanceBalance(
          personId: 'matteo',
          balanceId: 'account',
          name: 'Conto test',
          initialAmount: 1000,
          currentAmount: 1000,
          updatedAt: DateTime(2026, 9, 16),
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          active: true,
          reservedAmount: 0,
          warningThreshold: 0,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
      ],
    );
    final expenseStore = ExpenseStore();
    final cashWalletStore = CashWalletStore();
    return _Fixture._(
      financeStore: financeStore,
      expenseStore: expenseStore,
      cashWalletStore: cashWalletStore,
      coordinator: _RecordingCoordinator(
        financeStore: financeStore,
        expenseStore: expenseStore,
        status: status,
        pending: pending,
      ),
    );
  }
}

class _RecordingCoordinator extends CompositeEconomicOperationCoordinator {
  final CompositeEconomicOperationStatus status;
  final Completer<CompositeEconomicOperationResult>? pending;
  final List<CompositeEconomicOperationPosting> postings = [];

  _RecordingCoordinator({
    required super.financeStore,
    required super.expenseStore,
    required this.status,
    this.pending,
  });

  int get calls => postings.length;

  Iterable<String> get operationIds =>
      postings.map((posting) => posting.operation.operationId);

  @override
  Future<CompositeEconomicOperationResult> record(
    CompositeEconomicOperationPosting posting,
  ) async {
    postings.add(posting);
    if (pending != null) return pending!.future;
    return switch (status) {
      CompositeEconomicOperationStatus.completed =>
        CompositeEconomicOperationResult.completed(),
      CompositeEconomicOperationStatus.alreadyComplete =>
        CompositeEconomicOperationResult.alreadyComplete(),
      CompositeEconomicOperationStatus.inconsistent =>
        CompositeEconomicOperationResult.inconsistent(
          CompositeEconomicOperationReason.financeFactsConflict,
          const ['synthetic inconsistency'],
        ),
      CompositeEconomicOperationStatus.failed =>
        CompositeEconomicOperationResult.failed(
          CompositeEconomicOperationReason.financeWriteFailed,
          const ['synthetic failure'],
        ),
    };
  }
}
