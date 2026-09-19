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
    await tester.tap(find.byKey(const Key('save-completed-expected-expense')));
    await tester.pumpAndSettle();

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
      await tester.tap(
        find.byKey(const Key('save-completed-expected-expense')),
      );
      await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const Key('save-completed-expected-expense')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const Key('save-completed-expected-expense')));
    await tester.pumpAndSettle();

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
      await tester.tap(
        find.byKey(const Key('save-completed-expected-expense')),
      );
      await tester.pumpAndSettle();

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
      await tester.tap(
        find.byKey(const Key('save-completed-expected-expense')),
      );
      await tester.pumpAndSettle();

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

    await tester.tap(find.byKey(const Key('save-completed-expected-expense')));
    await tester.pump();

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

    await tester.tap(find.byKey(const Key('save-completed-expected-expense')));
    await tester.pumpAndSettle();

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
              method: FinancePaymentMethod.manual,
            ),
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
            expectedAmount: 42,
            estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
            evidenceEconomicFactIds: const ['fact_1'],
            confidence: ExpenseEstimateConfidence.low,
            provisional: true,
            expectedPaymentConfiguration:
                ExpenseRelationshipPaymentConfiguration(
                  method: FinancePaymentMethod.manual,
                ),
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
