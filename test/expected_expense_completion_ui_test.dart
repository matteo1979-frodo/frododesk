import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/screens/expected_expense_completion_page.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('Spese detail exposes completion action and qualified details', () {
    final source = File('lib/screens/spese_page.dart').readAsStringSync();

    expect(source, contains("label: const Text('Completa previsione')"));
    expect(source, contains("'Scadenza \${_certaintyLabel"));
    expect(source, contains("'Preferenza abituale: dal giorno '"));
    expect(source, contains("'Finestra prevista: '"));
  });

  testWidgets('prefills qualified due date, preference and payment window', (
    tester,
  ) async {
    final harness = _Harness(
      certainty: ExpectedExpenseDateCertainty.estimated,
      preferenceDay: 5,
      window: _window(
        startDay: 5,
        endDay: 14,
        origin: ExpectedPaymentWindowOrigin.relationshipDefault,
      ),
    );

    await tester.pumpWidget(_app(harness.store));

    expect(find.text('Completa previsione'), findsOneWidget);
    expect(find.text('14/11/2026'), findsOneWidget);
    expect(find.text('Stimata'), findsOneWidget);
    expect(find.widgetWithText(TextField, '5'), findsOneWidget);
    expect(
      find.text('Finestra attuale: 05/11/2026 – 14/11/2026'),
      findsOneWidget,
    );
  });

  testWidgets('legacy certainty is not preselected', (tester) async {
    final harness = _Harness(
      certainty: ExpectedExpenseDateCertainty.legacyUnspecified,
    );

    await tester.pumpWidget(_app(harness.store));

    final dropdown = tester
        .widget<DropdownButtonFormField<ExpectedExpenseDateCertainty>>(
          find.byKey(const Key('completion-certainty')),
        );
    expect(dropdown.initialValue, isNull);
  });

  for (final mode in PaymentExecutionMode.values) {
    testWidgets('initializes occurrence execution mode ${mode.name}', (
      tester,
    ) async {
      final harness = _Harness(occurrenceMode: mode);

      await tester.pumpWidget(_app(harness.store));

      final dropdown = tester
          .widget<DropdownButtonFormField<PaymentExecutionMode>>(
            find.byKey(const Key('completion-payment-execution-mode')),
          );
      expect(dropdown.initialValue, mode);
    });

    testWidgets('persists occurrence execution mode ${mode.name}', (
      tester,
    ) async {
      final harness = _Harness(
        certainty: ExpectedExpenseDateCertainty.estimated,
        preferenceDay: 5,
        relationshipMode: PaymentExecutionMode.automatic,
      );
      await tester.pumpWidget(_app(harness.store));

      await _chooseExecutionMode(tester, _executionModeLabel(mode));
      await _tapSave(tester);

      final aggregate = harness.store.expectedExpenseAggregate;
      expect(aggregate.occurrences.single.paymentExecutionMode, mode);
      expect(aggregate.occurrences.single.plannedEconomicImpact, isNull);
      expect(
        aggregate.relationships.single.paymentExecutionMode,
        PaymentExecutionMode.automatic,
      );
    });
  }

  testWidgets('does not infer execution mode from payment method', (
    tester,
  ) async {
    final harness = _Harness(paymentMethod: FinancePaymentMethod.rid);

    await tester.pumpWidget(_app(harness.store));

    final dropdown = tester
        .widget<DropdownButtonFormField<PaymentExecutionMode>>(
          find.byKey(const Key('completion-payment-execution-mode')),
        );
    expect(dropdown.initialValue, PaymentExecutionMode.unknown);
  });

  testWidgets(
    'preserves an existing impact interval when only execution mode changes',
    (tester) async {
      final impact = PlannedEconomicImpact(
        start: DateTime(2026, 12, 5),
        end: DateTime(2026, 12, 7),
        origin: PlannedEconomicImpactOrigin.userDecision,
      );
      final harness = _Harness(
        certainty: ExpectedExpenseDateCertainty.estimated,
        preferenceDay: 5,
        occurrenceMode: PaymentExecutionMode.unknown,
        plannedImpact: impact,
      );
      await tester.pumpWidget(_app(harness.store));

      expect(find.text('05/12/2026 – 07/12/2026'), findsOneWidget);
      await _chooseExecutionMode(tester, 'Richiede una mia azione');
      await _tapSave(tester);

      final occurrence =
          harness.store.expectedExpenseAggregate.occurrences.single;
      expect(
        occurrence.paymentExecutionMode,
        PaymentExecutionMode.requiresUserAction,
      );
      expect(occurrence.plannedEconomicImpact?.toJson(), impact.toJson());
    },
  );

  testWidgets(
    'selects one planned date after due date without changing due or window',
    (tester) async {
      final window = _window(
        startDay: 5,
        endDay: 14,
        origin: ExpectedPaymentWindowOrigin.occurrenceOverride,
      );
      final harness = _Harness(
        certainty: ExpectedExpenseDateCertainty.estimated,
        preferenceDay: 5,
        window: window,
        occurrenceMode: PaymentExecutionMode.automatic,
      );
      await tester.pumpWidget(_app(harness.store));

      await tester.ensureVisible(
        find.byKey(const Key('completion-planned-impact-date')),
      );
      await tester.tap(find.byKey(const Key('completion-planned-impact-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _tapSave(tester);

      final occurrence =
          harness.store.expectedExpenseAggregate.occurrences.single;
      expect(occurrence.occurrenceId, 'occurrence_1');
      expect(occurrence.relationshipId, 'relationship_1');
      expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
      expect(occurrence.expectedPaymentWindow?.toJson(), window.toJson());
      expect(occurrence.paymentExecutionMode, PaymentExecutionMode.automatic);
      expect(occurrence.evidenceEconomicFactIds, ['fact_1']);
      expect(occurrence.plannedEconomicImpact?.start, DateTime(2026, 12, 5));
      expect(occurrence.plannedEconomicImpact?.end, DateTime(2026, 12, 5));
      expect(
        occurrence.plannedEconomicImpact?.origin,
        PlannedEconomicImpactOrigin.userDecision,
      );
    },
  );

  testWidgets('explicitly removes an existing planned impact', (tester) async {
    final harness = _Harness(
      certainty: ExpectedExpenseDateCertainty.estimated,
      preferenceDay: 5,
      plannedImpact: PlannedEconomicImpact(
        start: DateTime(2026, 12, 5),
        end: DateTime(2026, 12, 5),
        origin: PlannedEconomicImpactOrigin.userDecision,
      ),
    );
    await tester.pumpWidget(_app(harness.store));

    await tester.ensureVisible(
      find.byKey(const Key('completion-clear-planned-impact')),
    );
    await tester.tap(find.byKey(const Key('completion-clear-planned-impact')));
    await _tapSave(tester);

    expect(
      harness
          .store
          .expectedExpenseAggregate
          .occurrences
          .single
          .plannedEconomicImpact,
      isNull,
    );
  });

  testWidgets('estimated due date and preference save one combined update', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(_app(harness.store));

    await _chooseCertainty(tester, 'Stimata');
    await tester.enterText(
      find.byKey(const Key('completion-preferred-day')),
      '5',
    );
    await _tapSave(tester);

    final aggregate = harness.store.expectedExpenseAggregate;
    final relationship = aggregate.relationships.single;
    final occurrence = aggregate.occurrences.single;
    expect(harness.writes, 1);
    expect(relationship.relationshipId, 'relationship_1');
    expect(relationship.manualPaymentPreference?.preferredStartDayOfMonth, 5);
    expect(occurrence.occurrenceId, 'occurrence_1');
    expect(
      occurrence.expectedDueDateSource,
      ExpectedExpenseDateSource.explicit,
    );
    expect(
      occurrence.expectedDueDateCertainty,
      ExpectedExpenseDateCertainty.estimated,
    );
    expect(occurrence.knowledgeState, ExpectedExpenseKnowledgeState.forecast);
    expect(occurrence.expectedPaymentWindow?.start, DateTime(2026, 11, 5));
    expect(occurrence.expectedPaymentWindow?.end, DateTime(2026, 11, 14));
    expect(
      occurrence.expectedPaymentWindow?.confidence,
      ExpectedTemporalConfidence.low,
    );
    expect(
      occurrence.expectedPaymentWindow?.origin,
      ExpectedPaymentWindowOrigin.relationshipDefault,
    );
    expect(occurrence.evidenceEconomicFactIds, ['fact_1']);
  });

  testWidgets(
    'known due date materializes high confidence without changing knowledge',
    (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(_app(harness.store));

      await _chooseCertainty(tester, 'Conosciuta');
      await tester.enterText(
        find.byKey(const Key('completion-preferred-day')),
        '5',
      );
      await _tapSave(tester);

      final occurrence =
          harness.store.expectedExpenseAggregate.occurrences.single;
      expect(
        occurrence.expectedDueDateCertainty,
        ExpectedExpenseDateCertainty.known,
      );
      expect(
        occurrence.expectedPaymentWindow?.confidence,
        ExpectedTemporalConfidence.high,
      );
      expect(occurrence.knowledgeState, ExpectedExpenseKnowledgeState.forecast);
    },
  );

  testWidgets('changing estimated due date rematerializes the default window', (
    tester,
  ) async {
    final harness = _Harness(
      certainty: ExpectedExpenseDateCertainty.estimated,
      preferenceDay: 5,
      window: _window(
        startDay: 5,
        endDay: 14,
        origin: ExpectedPaymentWindowOrigin.relationshipDefault,
      ),
    );
    await tester.pumpWidget(_app(harness.store));

    await tester.tap(find.byKey(const Key('completion-due-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _chooseCertainty(tester, 'Conosciuta');
    await _tapSave(tester);

    final occurrence =
        harness.store.expectedExpenseAggregate.occurrences.single;
    expect(occurrence.expectedDueDate, DateTime(2026, 11, 20));
    expect(occurrence.expectedPaymentWindow?.start, DateTime(2026, 11, 5));
    expect(occurrence.expectedPaymentWindow?.end, DateTime(2026, 11, 20));
    expect(
      occurrence.expectedPaymentWindow?.confidence,
      ExpectedTemporalConfidence.high,
    );
  });

  testWidgets('occurrence override is preserved', (tester) async {
    final override = _window(
      startDay: 7,
      endDay: 12,
      origin: ExpectedPaymentWindowOrigin.occurrenceOverride,
    );
    final harness = _Harness(window: override);
    await tester.pumpWidget(_app(harness.store));

    await _chooseCertainty(tester, 'Conosciuta');
    await tester.enterText(
      find.byKey(const Key('completion-preferred-day')),
      '5',
    );
    await _tapSave(tester);

    expect(
      harness
          .store
          .expectedExpenseAggregate
          .occurrences
          .single
          .expectedPaymentWindow
          ?.toJson(),
      override.toJson(),
    );
  });

  testWidgets(
    'preferred day after due date saves no automatic fallback window',
    (tester) async {
      final harness = _Harness(dueDate: DateTime(2026, 11, 8));
      await tester.pumpWidget(_app(harness.store));

      await _chooseCertainty(tester, 'Stimata');
      await tester.enterText(
        find.byKey(const Key('completion-preferred-day')),
        '10',
      );
      await _tapSave(tester);

      final aggregate = harness.store.expectedExpenseAggregate;
      expect(
        aggregate
            .relationships
            .single
            .manualPaymentPreference
            ?.preferredStartDayOfMonth,
        10,
      );
      expect(aggregate.occurrences.single.expectedPaymentWindow, isNull);
    },
  );

  testWidgets(
    'persistence failure does not show success or publish candidates',
    (tester) async {
      final harness = _Harness(failWrites: true);
      final initial = harness.store.expectedExpenseAggregate;
      await tester.pumpWidget(_app(harness.store));

      await _chooseCertainty(tester, 'Stimata');
      await tester.enterText(
        find.byKey(const Key('completion-preferred-day')),
        '5',
      );
      await _chooseExecutionMode(tester, 'Già programmato');
      await _tapSave(tester);

      expect(harness.store.expectedExpenseAggregate, same(initial));
      expect(find.textContaining('Previsione non aggiornata'), findsOneWidget);
      expect(find.text('Previsione aggiornata.'), findsNothing);
    },
  );

  testWidgets('invalid preferred day is rejected before persistence', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(_app(harness.store));
    await _chooseCertainty(tester, 'Stimata');
    await tester.enterText(
      find.byKey(const Key('completion-preferred-day')),
      '32',
    );

    await _tapSave(tester, settle: false);

    expect(harness.writes, 0);
    expect(find.textContaining('compreso tra 1 e 31'), findsOneWidget);
  });

  testWidgets('identical save is idempotent', (tester) async {
    final harness = _Harness(
      certainty: ExpectedExpenseDateCertainty.estimated,
      preferenceDay: 5,
      window: _window(
        startDay: 5,
        endDay: 14,
        origin: ExpectedPaymentWindowOrigin.relationshipDefault,
      ),
    );
    await tester.pumpWidget(_app(harness.store));

    await _tapSave(tester);

    expect(harness.writes, 0);
  });

  testWidgets('double submit is single-flight', (tester) async {
    final completer = Completer<PersistenceWriteVerification>();
    final harness = _Harness(writeCompleter: completer);
    await tester.pumpWidget(_app(harness.store));
    await _chooseCertainty(tester, 'Stimata');
    await tester.enterText(
      find.byKey(const Key('completion-preferred-day')),
      '5',
    );

    final save = find.byKey(const Key('save-completed-expected-expense'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();

    expect(harness.writes, 1);
    completer.complete(
      const PersistenceWriteVerification(backendAccepted: true, readBack: null),
    );
    await tester.pumpAndSettle();
  });
}

Future<void> _chooseCertainty(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('completion-certainty')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _chooseExecutionMode(WidgetTester tester, String label) async {
  final field = find.byKey(const Key('completion-payment-execution-mode'));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester, {bool settle = true}) async {
  final save = find.byKey(const Key('save-completed-expected-expense'));
  await tester.ensureVisible(save);
  await tester.tap(save);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

String _executionModeLabel(PaymentExecutionMode mode) => switch (mode) {
  PaymentExecutionMode.unknown => 'Da definire',
  PaymentExecutionMode.requiresUserAction => 'Richiede una mia azione',
  PaymentExecutionMode.automatic => 'Automatico',
  PaymentExecutionMode.scheduled => 'Già programmato',
};

Widget _app(FinanceStore store) => MaterialApp(
  home: ExpectedExpenseCompletionPage(
    financeStore: store,
    relationshipId: 'relationship_1',
    occurrenceId: 'occurrence_1',
  ),
);

class _Harness {
  late final FinanceStore store;
  int writes = 0;

  _Harness({
    DateTime? dueDate,
    ExpectedExpenseDateCertainty? certainty,
    int? preferenceDay,
    ExpectedPaymentWindow? window,
    PaymentExecutionMode relationshipMode = PaymentExecutionMode.unknown,
    PaymentExecutionMode occurrenceMode = PaymentExecutionMode.unknown,
    PlannedEconomicImpact? plannedImpact,
    FinancePaymentMethod paymentMethod = FinancePaymentMethod.manual,
    bool failWrites = false,
    Completer<PersistenceWriteVerification>? writeCompleter,
  }) {
    store = FinanceStore(
      initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
        relationships: [
          ExpenseRelationship(
            relationshipId: 'relationship_1',
            service: 'Servizio sintetico',
            provider: 'Fornitore sintetico',
            subject: FinanceSubject.matteo,
            status: ExpenseRelationshipStatus.active,
            periodicity: ExpenseRelationshipPeriodicity(
              type: FinanceRecurringType.monthly,
            ),
            paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
              method: paymentMethod,
            ),
            paymentExecutionMode: relationshipMode,
            manualPaymentPreference: preferenceDay == null
                ? null
                : ManualPaymentPreference(
                    preferredStartDayOfMonth: preferenceDay,
                  ),
          ),
        ],
        occurrences: [
          ExpectedExpenseOccurrence(
            occurrenceId: 'occurrence_1',
            relationshipId: 'relationship_1',
            status: ExpectedExpenseOccurrenceStatus.pending,
            expectedDueDate: dueDate ?? DateTime(2026, 11, 14),
            expectedDueDateSource: ExpectedExpenseDateSource.explicit,
            expectedDueDateCertainty: certainty,
            expectedPaymentWindow: window,
            plannedEconomicImpact: plannedImpact,
            expectedAmount: 42,
            estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
            evidenceEconomicFactIds: const ['fact_1'],
            confidence: ExpenseEstimateConfidence.low,
            provisional: true,
            expectedPaymentConfiguration:
                ExpenseRelationshipPaymentConfiguration(method: paymentMethod),
            paymentExecutionMode: occurrenceMode,
            expectedSubject: FinanceSubject.matteo,
          ),
        ],
      ),
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async {
          writes++;
          if (writeCompleter != null) return writeCompleter.future;
          if (failWrites) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );
  }
}

ExpectedPaymentWindow _window({
  required int startDay,
  required int endDay,
  required ExpectedPaymentWindowOrigin origin,
}) => ExpectedPaymentWindow(
  start: DateTime(2026, 11, startDay),
  end: DateTime(2026, 11, endDay),
  semantic: ExpectedPaymentWindowSemantic.userPreferred,
  source: ExpectedExpenseDateSource.explicit,
  confidence: ExpectedTemporalConfidence.low,
  origin: origin,
);
