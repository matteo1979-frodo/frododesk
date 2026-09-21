import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
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

  testWidgets('shows Expected Expense and finite-plan installment together', (
    tester,
  ) async {
    await _pump(
      tester,
      _aggregate([
        _fixture(
          'Acqua',
          provider: 'Hera',
          plannedImpact: _impact(DateTime(2026, 11, 10)),
          expectedAmount: 59.63,
        ),
      ]),
      referenceTime: DateTime(2026, 9, 20),
      finitePlans: [_inpsPlan()],
    );

    await tester.tap(find.text('Mesi futuri'));
    await tester.pumpAndSettle();
    expect(find.text('Novembre 2026'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Novembre 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Acqua · Hera'), findsOneWidget);
    expect(find.text('INPS'), findsOneWidget);
    expect(find.text('Rata 5 di 12'), findsOneWidget);
    expect(find.text('Data prevista 15/11/2026'), findsOneWidget);
    expect(find.textContaining('Impatto pianificato'), findsNothing);
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
    expect(find.text('€123,45'), findsOneWidget);
    expect(find.text('stimato'), findsOneWidget);
    expect(find.text('Scadenza 14/11/2099'), findsOneWidget);
    expect(find.text('Da pianificare'), findsOneWidget);
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

      await tester.tap(find.text('Mesi futuri'));
      await tester.pumpAndSettle();
      expect(find.text('Dicembre 2099'), findsOneWidget);
      await tester.tap(find.text('Dicembre 2099'));
      await tester.pumpAndSettle();
      expect(find.text('Impatto 05/12/2099'), findsOneWidget);
      expect(find.text('Addebito 10/12/2099 – 12/12/2099'), findsOneWidget);
      expect(find.textContaining('10/11/2099'), findsNothing);
    },
  );

  testWidgets('renders compact attention without hiding open occurrences', (
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

    expect(find.textContaining('Manuale ·'), findsOneWidget);
    expect(find.textContaining('Automatica ·'), findsOneWidget);
    expect(find.textContaining('Programmata ·'), findsOneWidget);
    expect(find.text('Da pianificare'), findsNWidgets(5));
    expect(find.text('Scadenza superata'), findsNothing);
    expect(find.byKey(const Key('future-expenses-unplaced')), findsOneWidget);
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

      expect(find.text('Spesa futura'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit-future-expense')));
      await tester.pumpAndSettle();
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

  testWidgets('groups future months and exposes only non-empty month badges', (
    tester,
  ) async {
    await _pump(
      tester,
      _aggregate([
        _fixture('Corrente', plannedImpact: _impact(DateTime(2099, 11, 20))),
        _fixture('Dicembre uno', plannedImpact: _impact(DateTime(2099, 12, 2))),
        _fixture('Dicembre due', plannedImpact: _impact(DateTime(2099, 12, 9))),
        _fixture('Febbraio', plannedImpact: _impact(DateTime(2100, 2, 3))),
        _fixture('Senza data', dueDate: null),
      ]),
    );

    expect(find.textContaining('Corrente ·'), findsOneWidget);
    expect(find.text('Mesi futuri'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('future-expenses-months')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('future-expenses-unplaced')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('future-expenses-unplaced')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Dicembre uno ·'), findsNothing);

    await tester.tap(find.text('Mesi futuri'));
    await tester.pumpAndSettle();
    expect(find.text('Dicembre 2099'), findsOneWidget);
    expect(find.text('Febbraio 2100'), findsOneWidget);
    expect(find.text('Gennaio 2100'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('future-expense-month-2099-12')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Dicembre 2099'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dicembre uno ·'), findsOneWidget);
    expect(find.textContaining('Dicembre due ·'), findsOneWidget);
    expect(find.textContaining('Febbraio ·'), findsNothing);
    await tester.tap(find.textContaining('Dicembre due ·'));
    await tester.pumpAndSettle();
    expect(find.text('Spesa futura'), findsOneWidget);
  });

  testWidgets(
    'global unplaced list contains only occurrences without a month',
    (tester) async {
      await _pump(
        tester,
        _aggregate([
          _fixture('Senza data', dueDate: null),
          _fixture('Con scadenza', dueDate: DateTime(2099, 11, 18)),
        ]),
      );

      await tester.tap(find.byKey(const Key('future-expenses-unplaced')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Senza data ·'), findsOneWidget);
      expect(find.textContaining('Con scadenza ·'), findsNothing);
      await tester.tap(find.textContaining('Senza data ·'));
      await tester.pumpAndSettle();
      expect(find.text('Spesa futura'), findsOneWidget);
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
      final store = await _pump(
        tester,
        aggregate,
        referenceTime: DateTime(2026, 11, 1),
      );

      expect(find.text('Da pianificare'), findsOneWidget);

      await tester.tap(find.text('Acqua · Hera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit-future-expense')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('completion-preferred-day')),
        '5',
      );
      final mode = find
          .byKey(const Key('completion-payment-execution-mode'))
          .last;
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Richiede una mia azione').last);
      await tester.pumpAndSettle();
      final planned = find
          .byKey(const Key('completion-planned-impact-date'))
          .last;
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.tap(planned);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final save = find
          .byKey(const Key('save-completed-expected-expense'))
          .last;
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Acqua · Hera'), findsNothing);
      expect(find.text('Mesi futuri'), findsOneWidget);
      await tester.tap(find.text('Mesi futuri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dicembre 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Acqua · Hera'), findsOneWidget);
      expect(find.text('Impatto 05/12/2026'), findsOneWidget);
      expect(find.text('Richiede azione'), findsOneWidget);
      final occurrence = store.expectedExpenseAggregate.occurrences.single;
      expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
      expect(
        occurrence.expectedPaymentWindow?.semantic,
        ExpectedPaymentWindowSemantic.userPreferred,
      );
    },
  );

  testWidgets('cancelling a future occurrence refreshes month counters', (
    tester,
  ) async {
    final store = await _pump(
      tester,
      _aggregate([_fixture('Da annullare', dueDate: DateTime(2099, 12, 10))]),
    );

    expect(find.text('Mesi futuri'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('Mesi futuri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dicembre 2099'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Da annullare ·'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('remove-future-expense')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('remove-current-forecast')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla previsione'));
    await tester.pumpAndSettle();

    expect(
      store.expectedExpenseAggregate.occurrences.single.status,
      ExpectedExpenseOccurrenceStatus.cancelled,
    );
    expect(find.textContaining('Da annullare ·'), findsNothing);
  });
}

Future<FinanceStore> _pump(
  WidgetTester tester,
  ExpectedExpenseAggregate aggregate, {
  DateTime? referenceTime,
  Iterable<FiniteFinancialPlan> finitePlans = const [],
}) async {
  final store = FinanceStore(
    initialExpectedExpenseAggregate: aggregate,
    initialFiniteFinancialPlans: finitePlans,
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
        futureExpenseReferenceTime: referenceTime ?? DateTime(2099, 11, 1),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

FiniteFinancialPlan _inpsPlan() => FiniteFinancialPlan(
  id: 'plan_inps',
  name: 'INPS',
  subject: FinanceSubject.matteo,
  debitBalanceId: 'balance_banca',
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: 3,
);

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

PlannedEconomicImpact _impact(DateTime date) => PlannedEconomicImpact(
  start: date,
  end: date,
  origin: PlannedEconomicImpactOrigin.userDecision,
);

class _Fixture {
  final ExpenseRelationship relationship;
  final ExpectedExpenseOccurrence occurrence;

  const _Fixture(this.relationship, this.occurrence);
}
