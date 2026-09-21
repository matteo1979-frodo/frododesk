import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultDueDate = Object();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows title and empty state without a call to action', (
    tester,
  ) async {
    await _pump(tester, ExpectedExpenseAggregate.empty());

    expect(find.text('Spese future'), findsOneWidget);
    expect(find.text('Nessuna spesa futura aperta.'), findsOneWidget);
  });

  testWidgets(
    'shows pending forecast and known-unpaid, excludes closed items, preserves order',
    (tester) async {
      await _pump(
        tester,
        _aggregate([
          _fixture(
            'Prima',
            knowledgeState: ExpectedExpenseKnowledgeState.forecast,
          ),
          _fixture(
            'Seconda',
            knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
            knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
            relationshipStatus: ExpenseRelationshipStatus.terminated,
          ),
          _fixture('Risolta', status: ExpectedExpenseOccurrenceStatus.resolved),
          _fixture(
            'Cancellata',
            status: ExpectedExpenseOccurrenceStatus.cancelled,
          ),
        ]),
      );

      expect(find.textContaining('Prima · Provider Prima'), findsOneWidget);
      expect(find.textContaining('Seconda · Provider Seconda'), findsOneWidget);
      expect(find.textContaining('Risolta'), findsNothing);
      expect(find.textContaining('Cancellata'), findsNothing);
      final first = tester.getTopLeft(find.textContaining('Prima · Provider'));
      final second = tester.getTopLeft(
        find.textContaining('Seconda · Provider'),
      );
      expect(first.dy, lessThan(second.dy));
    },
  );

  testWidgets('renders Hera-like user preference as insufficient', (
    tester,
  ) async {
    await _pump(
      tester,
      _aggregate([
        _fixture(
          'Energia',
          provider: 'Hera',
          mode: PaymentExecutionMode.unknown,
          paymentWindow: _window(
            ExpectedPaymentWindowSemantic.userPreferred,
            DateTime(2099, 11, 5),
            DateTime(2099, 11, 14),
          ),
          dueDate: DateTime(2099, 11, 14),
          dueCertainty: ExpectedExpenseDateCertainty.known,
        ),
      ]),
    );

    expect(find.text('Energia · Hera'), findsOneWidget);
    expect(find.text('€123,45 · Importo stimato/provvisorio'), findsOneWidget);
    expect(find.text('Scadenza certa: 14/11/2099'), findsOneWidget);
    expect(find.text('Modalità da definire'), findsOneWidget);
    expect(
      find.text('Impatto economico non ancora collocabile'),
      findsOneWidget,
    );
    expect(find.textContaining('05/11/2099'), findsNothing);
  });

  testWidgets(
    'renders planned impact and expected debit without collapsing ranges',
    (tester) async {
      await _pump(
        tester,
        _aggregate([
          _fixture(
            'Pianificata',
            plannedImpact: PlannedEconomicImpact(
              start: DateTime(2099, 12, 5),
              end: DateTime(2099, 12, 5),
              origin: PlannedEconomicImpactOrigin.userDecision,
            ),
            paymentWindow: _window(
              ExpectedPaymentWindowSemantic.expectedDebit,
              DateTime(2099, 11, 10),
              DateTime(2099, 11, 12),
            ),
          ),
          _fixture(
            'Addebito',
            paymentWindow: _window(
              ExpectedPaymentWindowSemantic.expectedDebit,
              DateTime(2099, 12, 10),
              DateTime(2099, 12, 12),
            ),
          ),
        ]),
      );

      expect(find.text('Impatto pianificato: 05/12/2099'), findsOneWidget);
      expect(
        find.text('Addebito atteso: 10/12/2099 – 12/12/2099'),
        findsOneWidget,
      );
      expect(find.textContaining('10/11/2099'), findsNothing);
    },
  );

  testWidgets('renders execution modes, due certainty and qualified overdue', (
    tester,
  ) async {
    await _pump(
      tester,
      _aggregate([
        _fixture(
          'Manuale',
          mode: PaymentExecutionMode.requiresUserAction,
          dueDate: DateTime(2000, 1, 1),
          dueCertainty: ExpectedExpenseDateCertainty.known,
        ),
        _fixture(
          'Automatica',
          mode: PaymentExecutionMode.automatic,
          dueDate: DateTime(2000, 1, 2),
          dueCertainty: ExpectedExpenseDateCertainty.estimated,
        ),
        _fixture(
          'Programmata',
          mode: PaymentExecutionMode.scheduled,
          dueDate: DateTime(2000, 1, 3),
          dueCertainty: ExpectedExpenseDateCertainty.legacyUnspecified,
        ),
        _fixture(
          'Senza scadenza',
          mode: PaymentExecutionMode.unknown,
          dueDate: null,
        ),
        _fixture(
          'Futura',
          dueDate: DateTime(2099, 1, 1),
          dueCertainty: ExpectedExpenseDateCertainty.known,
        ),
      ]),
    );

    expect(find.text('Richiede pagamento'), findsOneWidget);
    expect(find.text('Pagamento automatico'), findsOneWidget);
    expect(find.text('Pagamento programmato'), findsOneWidget);
    expect(find.text('Modalità da definire'), findsNWidgets(2));
    expect(find.text('Scadenza certa superata'), findsOneWidget);
    expect(find.text('Data di scadenza stimata superata'), findsOneWidget);
    expect(
      find.text('Data di scadenza superata (certezza non specificata)'),
      findsOneWidget,
    );
    expect(find.text('Scadenza non indicata'), findsOneWidget);
    expect(find.text('Scadenza certa: 01/01/2099'), findsOneWidget);
  });

  testWidgets(
    'future cards open completion using the selected projection IDs',
    (tester) async {
      await _pump(
        tester,
        _aggregate([
          _fixture('Prima', mode: PaymentExecutionMode.automatic),
          _fixture('Seconda', mode: PaymentExecutionMode.scheduled),
        ]),
      );

      await tester.tap(find.text('Seconda · Provider Seconda'));
      await tester.pumpAndSettle();

      expect(find.text('Completa previsione'), findsOneWidget);
      final dropdown = tester
          .widget<DropdownButtonFormField<PaymentExecutionMode>>(
            find.byKey(const Key('completion-payment-execution-mode')),
          );
      expect(dropdown.initialValue, PaymentExecutionMode.scheduled);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);

      final page = File('lib/screens/spese_page.dart').readAsStringSync();
      expect(page, isNot(contains('recurringItems')));
      expect(page, contains('expense.source.relationshipId'));
      expect(page, contains('expense.source.occurrenceId'));
    },
  );

  testWidgets(
    'Hera-like completion rebuilds the card from FutureExpenseReader',
    (tester) async {
      final aggregate = _aggregate([
        _fixture(
          'Acqua',
          provider: 'Hera',
          expectedAmount: 59.63,
          dueDate: DateTime(2026, 11, 14),
          dueCertainty: ExpectedExpenseDateCertainty.estimated,
          paymentWindow: _window(
            ExpectedPaymentWindowSemantic.userPreferred,
            DateTime(2026, 11, 5),
            DateTime(2026, 11, 14),
          ),
        ),
      ]);
      final store = await _pump(tester, aggregate);

      expect(
        find.text('Impatto economico non ancora collocabile'),
        findsOneWidget,
      );
      expect(find.text('Modalità da definire'), findsOneWidget);

      await tester.tap(find.text('Acqua · Hera'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('completion-preferred-day')),
        '5',
      );
      final mode = find.byKey(const Key('completion-payment-execution-mode'));
      await tester.ensureVisible(mode);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Richiede una mia azione').last);
      await tester.pumpAndSettle();
      final planned = find.byKey(const Key('completion-planned-impact-date'));
      await tester.ensureVisible(planned);
      await tester.tap(planned);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('save-completed-expected-expense'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Acqua · Hera'), findsOneWidget);
      expect(find.text('Scadenza stimata: 14/11/2026'), findsOneWidget);
      expect(find.text('Impatto pianificato: 05/12/2026'), findsOneWidget);
      expect(find.text('Richiede pagamento'), findsOneWidget);
      final occurrence = store.expectedExpenseAggregate.occurrences.single;
      expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
      expect(
        occurrence.expectedPaymentWindow?.semantic,
        ExpectedPaymentWindowSemantic.userPreferred,
      );
    },
  );
}

Future<FinanceStore> _pump(
  WidgetTester tester,
  ExpectedExpenseAggregate aggregate,
) async {
  final store = FinanceStore(
    initialExpectedExpenseAggregate: aggregate,
    expectedExpensePersistence: ExpectedExpensePersistence(
      saveVerified: (_, value) async =>
          PersistenceWriteVerification(backendAccepted: true, readBack: value),
    ),
  );
  await tester.binding.setSurfaceSize(const Size(1400, 5000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: SpesePage(
        financeStore: store,
        expenseStore: ExpenseStore(),
        cashWalletStore: CashWalletStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

ExpectedExpenseAggregate _aggregate(List<_Fixture> fixtures) =>
    ExpectedExpenseAggregate(
      relationships: fixtures.map((item) => item.relationship),
      occurrences: fixtures.map((item) => item.occurrence),
    );

_Fixture _fixture(
  String service, {
  String? provider,
  ExpenseRelationshipStatus relationshipStatus =
      ExpenseRelationshipStatus.active,
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  ExpectedExpenseKnowledgeState knowledgeState =
      ExpectedExpenseKnowledgeState.forecast,
  ExpectedExpenseKnowledgeSource knowledgeSource =
      ExpectedExpenseKnowledgeSource.legacyUnspecified,
  PaymentExecutionMode mode = PaymentExecutionMode.unknown,
  Object? dueDate = _defaultDueDate,
  ExpectedExpenseDateCertainty dueCertainty =
      ExpectedExpenseDateCertainty.known,
  ExpectedPaymentWindow? paymentWindow,
  PlannedEconomicImpact? plannedImpact,
  double expectedAmount = 123.45,
}) {
  final token = service.toLowerCase().replaceAll(' ', '_');
  final relationship = ExpenseRelationship(
    relationshipId: 'relationship_$token',
    service: service,
    provider: provider ?? 'Provider $service',
    subject: FinanceSubject.matteo,
    status: relationshipStatus,
    periodicity: ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.monthly,
    ),
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
  );
  final resolvedFact = status == ExpectedExpenseOccurrenceStatus.resolved
      ? 'fact_$token'
      : null;
  final actualDueDate = identical(dueDate, _defaultDueDate)
      ? DateTime(2099, 11, 14)
      : dueDate as DateTime?;
  final occurrence = ExpectedExpenseOccurrence(
    occurrenceId: 'occurrence_$token',
    relationshipId: relationship.relationshipId,
    status: status,
    knowledgeState: knowledgeState,
    knowledgeSource: knowledgeSource,
    expectedIssueDate: DateTime(1999, 1, 1),
    expectedIssueDateSource: ExpectedExpenseDateSource.explicit,
    expectedDueDate: actualDueDate,
    expectedDueDateSource: actualDueDate == null
        ? null
        : ExpectedExpenseDateSource.explicit,
    expectedDueDateCertainty: actualDueDate == null ? null : dueCertainty,
    expectedPaymentWindow: paymentWindow,
    plannedEconomicImpact: plannedImpact,
    expectedAmount: expectedAmount,
    estimationMethod: ExpenseEstimationMethod.manualEstimate,
    confidence: ExpenseEstimateConfidence.low,
    provisional: true,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
    paymentExecutionMode: mode,
    expectedSubject: FinanceSubject.matteo,
    resolvedEconomicFactId: resolvedFact,
  );
  return _Fixture(relationship, occurrence);
}

ExpectedPaymentWindow _window(
  ExpectedPaymentWindowSemantic semantic,
  DateTime start,
  DateTime end,
) => ExpectedPaymentWindow(
  start: start,
  end: end,
  semantic: semantic,
  source: ExpectedExpenseDateSource.explicit,
  confidence: ExpectedTemporalConfidence.high,
  origin: ExpectedPaymentWindowOrigin.occurrenceOverride,
);

class _Fixture {
  final ExpenseRelationship relationship;
  final ExpectedExpenseOccurrence occurrence;

  const _Fixture(this.relationship, this.occurrence);
}
