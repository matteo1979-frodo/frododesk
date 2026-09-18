import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/expected_expense_from_real_expense_page.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('eligibility accepts main facts and rejects accessories', () {
    expect(canCreateExpectedExpensePrediction(_expense()), isTrue);
    expect(
      canCreateExpectedExpensePrediction(
        _expense(
          metadata: EconomicOperationMetadata(
            operationId: 'utility_1',
            role: OperationRole.accessory,
            context: OperationContext.utilityBill,
            accessoryCostType: AccessoryCostType.bankCommission,
          ),
        ),
      ),
      isFalse,
    );
    expect(
      canCreateExpectedExpensePrediction(_expense(economicFactId: null)),
      isFalse,
    );
  });

  testWidgets('form asks date semantic instead of inferring expense date', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_store(), _expense()));

    expect(find.byKey(const Key('expected-date-semantic')), findsOneWidget);
    expect(find.text('Emissione'), findsOneWidget);
    expect(find.text('Data evidenza'), findsOneWidget);
    expect(find.text('16/09/2026'), findsOneWidget);
  });

  testWidgets('Hera submit reuses amount, fact, subject and balance', (
    tester,
  ) async {
    final store = _store();
    await tester.pumpWidget(_app(store, _expense()));

    await tester.enterText(
      find.byKey(const Key('expected-service')),
      'Acqua',
    );
    await tester.enterText(
      find.byKey(const Key('expected-provider')),
      'Hera',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    final relationship = store.expectedExpenseAggregate.relationships.single;
    final occurrence = store.expectedExpenseAggregate.occurrences.single;
    expect(relationship.service, 'Acqua');
    expect(relationship.provider, 'Hera');
    expect(relationship.subject, FinanceSubject.matteo);
    expect(relationship.paymentConfiguration.expectedBalanceId, 'balance_1');
    expect(occurrence.expectedAmount, 59.63);
    expect(occurrence.evidenceEconomicFactIds, ['economic_fact_main']);
    expect(occurrence.expectedIssueDate, DateTime(2026, 10, 16));
    expect(
      occurrence.expectedIssueDateSource,
      ExpectedExpenseDateSource.calculatedFromPeriodicity,
    );
    expect(occurrence.provisional, isTrue);
  });

  testWidgets('supports yearly and custom two-month periodicity', (
    tester,
  ) async {
    for (final entry in const [
      ('Annuale', FinanceRecurringType.yearly, 12),
      ('Personalizzata in mesi', FinanceRecurringType.custom, 2),
    ]) {
      final store = _store();
      await tester.pumpWidget(_app(store, _expense()));
      await tester.enterText(
        find.byKey(const Key('expected-service')),
        'Acqua',
      );
      await tester.enterText(
        find.byKey(const Key('expected-provider')),
        'Hera',
      );
      await tester.tap(find.byKey(const Key('expected-periodicity')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.$1).last);
      await tester.pumpAndSettle();
      await _tapSave(tester);
      await tester.pumpAndSettle();

      final periodicity =
          store.expectedExpenseAggregate.relationships.single.periodicity;
      expect(periodicity.type, entry.$2);
      expect(
        store.expectedExpenseAggregate.occurrences.single.expectedIssueDate,
        DateTime(2026, 9 + entry.$3, 16),
      );
    }
  });

  testWidgets('due semantic produces only an expected due date', (
    tester,
  ) async {
    final store = _store();
    await tester.pumpWidget(_app(store, _expense()));
    await tester.enterText(
      find.byKey(const Key('expected-service')),
      'Acqua',
    );
    await tester.enterText(
      find.byKey(const Key('expected-provider')),
      'Hera',
    );
    await tester.tap(find.byKey(const Key('expected-date-semantic')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scadenza').last);
    await tester.pumpAndSettle();
    await _tapSave(tester);
    await tester.pumpAndSettle();

    final occurrence = store.expectedExpenseAggregate.occurrences.single;
    expect(occurrence.expectedIssueDate, isNull);
    expect(occurrence.expectedDueDate, DateTime(2026, 10, 16));
  });

  testWidgets('explicit next date is passed through without recalculation', (
    tester,
  ) async {
    final store = _store();
    await tester.pumpWidget(_app(store, _expense()));
    await tester.enterText(
      find.byKey(const Key('expected-service')),
      'Acqua',
    );
    await tester.enterText(
      find.byKey(const Key('expected-provider')),
      'Hera',
    );
    await tester.tap(find.byKey(const Key('expected-next-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('23').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tapSave(tester);
    await tester.pumpAndSettle();

    final occurrence = store.expectedExpenseAggregate.occurrences.single;
    expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
    expect(
      occurrence.expectedIssueDateSource,
      ExpectedExpenseDateSource.explicit,
    );
  });

  testWidgets('write failure keeps the form open and shows no success', (
    tester,
  ) async {
    final store = FinanceStore(
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    await tester.pumpWidget(_app(store, _expense()));
    await tester.enterText(
      find.byKey(const Key('expected-service')),
      'Acqua',
    );
    await tester.enterText(
      find.byKey(const Key('expected-provider')),
      'Hera',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Previsione non salvata'), findsOneWidget);
    expect(store.expectedExpenseAggregate.relationships, isEmpty);
    expect(store.balances, isEmpty);
    expect(store.transactions, isEmpty);
  });
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('save-expected-expense')),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const Key('save-expected-expense')));
}

Widget _app(FinanceStore store, RealExpense expense) => MaterialApp(
  key: UniqueKey(),
  home: ExpectedExpenseFromRealExpensePage(
    expense: expense,
    financeStore: store,
    relationshipId: 'relationship_explicit',
    occurrenceId: 'occurrence_explicit',
  ),
);

FinanceStore _store() => FinanceStore(
  expectedExpensePersistence: ExpectedExpensePersistence(
    saveVerified: (_, value) async => PersistenceWriteVerification(
      backendAccepted: true,
      readBack: value,
    ),
  ),
);

RealExpense _expense({
  String? economicFactId = 'economic_fact_main',
  EconomicOperationMetadata? metadata,
}) => RealExpense(
  id: 'expense_1',
  balanceId: 'balance_1',
  balanceName: 'Banca di Imola',
  amount: 59.63,
  description: 'Bolletta acqua Hera',
  category: 'Acqua',
  date: DateTime(2026, 9, 16),
  subject: FinanceSubject.matteo,
  economicFactId: economicFactId,
  operationMetadata: metadata,
);
