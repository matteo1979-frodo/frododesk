import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/logic/finance/future_expense_reader.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/expected_expense_projection.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/future_expense_projection.dart';
import 'package:frododesk/models/planned_economic_impact.dart';

void main() {
  const reader = FutureExpenseReader();
  final referenceTime = DateTime(2026, 11, 20);

  group('open occurrence policy', () {
    test('includes pending forecast and known-unpaid in input order', () {
      final source = _source([
        _occurrence('forecast'),
        _occurrence(
          'known',
          knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
          knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
        ),
      ]);

      final result = reader.read(
        projections: source,
        referenceTime: referenceTime,
      );

      expect(result.map((item) => item.occurrenceId), ['forecast', 'known']);
      expect(
        result[0].source.knowledgeState,
        ExpectedExpenseKnowledgeState.forecast,
      );
      expect(
        result[1].source.knowledgeState,
        ExpectedExpenseKnowledgeState.knownUnpaid,
      );
    });

    test('excludes resolved and cancelled occurrences', () {
      final result = reader.read(
        projections: _source([
          _occurrence('pending'),
          _occurrence(
            'resolved',
            status: ExpectedExpenseOccurrenceStatus.resolved,
            resolvedEconomicFactId: 'fact_resolved',
          ),
          _occurrence(
            'cancelled',
            status: ExpectedExpenseOccurrenceStatus.cancelled,
          ),
        ]),
        referenceTime: referenceTime,
      );

      expect(result.map((item) => item.occurrenceId), ['pending']);
    });

    test('keeps pending occurrence from a terminated relationship', () {
      final result = reader.read(
        projections: _source([
          _occurrence('pending'),
        ], relationshipStatus: ExpenseRelationshipStatus.terminated),
        referenceTime: referenceTime,
      );

      expect(
        result.single.source.relationshipStatus,
        ExpenseRelationshipStatus.terminated,
      );
    });
  });

  group('economic impact placement', () {
    test(
      'planned impact has priority and preserves a range after due date',
      () {
        final planned = PlannedEconomicImpact(
          start: DateTime(2026, 12, 5),
          end: DateTime(2026, 12, 7),
          origin: PlannedEconomicImpactOrigin.userDecision,
        );
        final result = reader
            .read(
              projections: _source([
                _occurrence(
                  'planned',
                  plannedImpact: planned,
                  paymentWindow: _window(
                    ExpectedPaymentWindowSemantic.expectedDebit,
                  ),
                ),
              ]),
              referenceTime: referenceTime,
            )
            .single;

        expect(
          result.economicImpactPlacement,
          FutureExpenseEconomicImpactPlacement.plannedEconomicImpact,
        );
        expect(result.economicImpactStart, planned.start);
        expect(result.economicImpactEnd, planned.end);
        expect(result.source.expectedDueDate, DateTime(2026, 11, 14));
        expect(
          result.source.plannedEconomicImpact!.origin,
          PlannedEconomicImpactOrigin.userDecision,
        );
      },
    );

    test('uses and preserves expected-debit interval without a plan', () {
      final window = _window(ExpectedPaymentWindowSemantic.expectedDebit);
      final result = reader
          .read(
            projections: _source([_occurrence('debit', paymentWindow: window)]),
            referenceTime: referenceTime,
          )
          .single;

      expect(
        result.economicImpactPlacement,
        FutureExpenseEconomicImpactPlacement.expectedDebitWindow,
      );
      expect(result.economicImpactStart, window.start);
      expect(result.economicImpactEnd, window.end);
      expect(result.economicImpactStart, isNot(result.economicImpactEnd));
    });

    test('user preference is insufficient and occurrence remains visible', () {
      final result = reader
          .read(
            projections: _source([
              _occurrence(
                'preferred',
                paymentWindow: _window(
                  ExpectedPaymentWindowSemantic.userPreferred,
                ),
              ),
            ]),
            referenceTime: referenceTime,
          )
          .single;

      expect(
        result.economicImpactPlacement,
        FutureExpenseEconomicImpactPlacement.insufficient,
      );
      expect(result.economicImpactStart, isNull);
      expect(result.economicImpactEnd, isNull);
      expect(result.source.expectedPaymentWindow, isNotNull);
    });

    for (final mode in PaymentExecutionMode.values) {
      test('${mode.name} does not invent an impact date', () {
        final result = reader
            .read(
              projections: _source([
                _occurrence('mode_${mode.name}', executionMode: mode),
              ]),
              referenceTime: referenceTime,
            )
            .single;

        expect(result.source.occurrencePaymentExecutionMode, mode);
        expect(
          result.economicImpactPlacement,
          FutureExpenseEconomicImpactPlacement.insufficient,
        );
        expect(result.economicImpactStart, isNull);
      });
    }

    test('issue and due dates are never economic-impact fallbacks', () {
      final result = reader
          .read(
            projections: _source([_occurrence('dates')]),
            referenceTime: referenceTime,
          )
          .single;

      expect(result.source.expectedIssueDate, isNotNull);
      expect(result.source.expectedDueDate, isNotNull);
      expect(
        result.economicImpactPlacement,
        FutureExpenseEconomicImpactPlacement.insufficient,
      );
      expect(result.economicImpactStart, isNull);
    });
  });

  group('overdue qualification', () {
    test('reference time equal to or before due date is not overdue', () {
      final source = _source([_occurrence('due')]);

      expect(
        reader
            .read(projections: source, referenceTime: DateTime(2026, 11, 14))
            .single
            .overdueQualification,
        FutureExpenseOverdueQualification.notOverdue,
      );
      expect(
        reader
            .read(projections: source, referenceTime: DateTime(2026, 11, 13))
            .single
            .overdueQualification,
        FutureExpenseOverdueQualification.notOverdue,
      );
    });

    for (final entry in const {
      ExpectedExpenseDateCertainty.known:
          FutureExpenseOverdueQualification.overdueKnown,
      ExpectedExpenseDateCertainty.estimated:
          FutureExpenseOverdueQualification.overdueEstimated,
      ExpectedExpenseDateCertainty.legacyUnspecified:
          FutureExpenseOverdueQualification.overdueUnspecifiedCertainty,
    }.entries) {
      test('preserves overdue certainty ${entry.key.name}', () {
        final result = reader
            .read(
              projections: _source([
                _occurrence('overdue', dueCertainty: entry.key),
              ]),
              referenceTime: referenceTime,
            )
            .single;

        expect(result.overdueQualification, entry.value);
      });
    }

    test('no due date is not overdue regardless of knowledge state', () {
      final result = reader
          .read(
            projections: _source([
              _occurrence(
                'no_due',
                withDueDate: false,
                knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
                knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
              ),
            ]),
            referenceTime: referenceTime,
          )
          .single;

      expect(
        result.overdueQualification,
        FutureExpenseOverdueQualification.notOverdue,
      );
    });
  });

  group('snapshot preservation', () {
    test(
      'uses occurrence balance including null without relationship fallback',
      () {
        final projections = _source([
          _occurrence('specific', expectedBalanceId: 'balance_occurrence'),
          _occurrence('null', expectedBalanceId: null),
        ], relationshipBalanceId: 'balance_relationship');
        final result = reader.read(
          projections: projections,
          referenceTime: referenceTime,
        );

        expect(
          result[0].source.expectedPaymentConfiguration.expectedBalanceId,
          'balance_occurrence',
        );
        expect(
          result[1].source.expectedPaymentConfiguration.expectedBalanceId,
          isNull,
        );
        expect(
          result[1].source.relationshipPaymentConfiguration.expectedBalanceId,
          'balance_relationship',
        );
      },
    );

    test('preserves amount quality, identity and descriptive data', () {
      final source = _source([_occurrence('quality')]).single;
      final result = reader
          .read(projections: [source], referenceTime: referenceTime)
          .single;

      expect(result.source, same(source));
      expect(result.occurrenceId, 'quality');
      expect(result.relationshipId, 'relationship_1');
      expect(result.source.provider, 'Hera');
      expect(result.source.service, 'Energia');
      expect(result.source.expectedAmount, 123.45);
      expect(result.source.provisional, isTrue);
      expect(
        result.source.estimationMethod,
        ExpenseEstimationMethod.manualEstimate,
      );
      expect(result.source.confidence, ExpenseEstimateConfidence.low);
      expect(result.source.evidenceEconomicFactIds, isEmpty);
    });

    test('does not mutate input and returns an immutable result', () {
      final source = _source([_occurrence('first'), _occurrence('second')]);
      final before = source.toList();
      final result = reader.read(
        projections: source,
        referenceTime: referenceTime,
      );

      expect(source, orderedEquals(before));
      expect(() => result.clear(), throwsUnsupportedError);
    });
  });
}

List<ExpectedExpenseProjection> _source(
  List<ExpectedExpenseOccurrence> occurrences, {
  ExpenseRelationshipStatus relationshipStatus =
      ExpenseRelationshipStatus.active,
  String? relationshipBalanceId,
}) {
  final relationship = ExpenseRelationship(
    relationshipId: 'relationship_1',
    service: 'Energia',
    provider: 'Hera',
    subject: FinanceSubject.matteo,
    status: relationshipStatus,
    periodicity: ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.monthly,
    ),
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.rid,
      expectedBalanceId: relationshipBalanceId,
    ),
    paymentExecutionMode: PaymentExecutionMode.automatic,
  );
  return const ExpectedExpenseReader().read(
    ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: occurrences,
    ),
  );
}

ExpectedExpenseOccurrence _occurrence(
  String id, {
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  ExpectedExpenseKnowledgeState knowledgeState =
      ExpectedExpenseKnowledgeState.forecast,
  ExpectedExpenseKnowledgeSource knowledgeSource =
      ExpectedExpenseKnowledgeSource.legacyUnspecified,
  ExpectedExpenseDateCertainty dueCertainty =
      ExpectedExpenseDateCertainty.known,
  ExpectedPaymentWindow? paymentWindow,
  PlannedEconomicImpact? plannedImpact,
  PaymentExecutionMode executionMode = PaymentExecutionMode.unknown,
  bool withDueDate = true,
  String? expectedBalanceId,
  String? resolvedEconomicFactId,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: 'relationship_1',
  status: status,
  knowledgeState: knowledgeState,
  knowledgeSource: knowledgeSource,
  expectedIssueDate: DateTime(2026, 11, 1),
  expectedIssueDateSource: ExpectedExpenseDateSource.explicit,
  expectedDueDate: withDueDate ? DateTime(2026, 11, 14) : null,
  expectedDueDateSource: withDueDate
      ? ExpectedExpenseDateSource.explicit
      : null,
  expectedDueDateCertainty: withDueDate ? dueCertainty : null,
  expectedPaymentWindow: paymentWindow,
  plannedEconomicImpact: plannedImpact,
  expectedAmount: 123.45,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.low,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.card,
    expectedBalanceId: expectedBalanceId,
  ),
  paymentExecutionMode: executionMode,
  expectedSubject: FinanceSubject.matteo,
  resolvedEconomicFactId: resolvedEconomicFactId,
);

ExpectedPaymentWindow _window(ExpectedPaymentWindowSemantic semantic) =>
    ExpectedPaymentWindow(
      start: DateTime(2026, 11, 10),
      end: DateTime(2026, 11, 12),
      semantic: semantic,
      source: ExpectedExpenseDateSource.explicit,
      confidence: ExpectedTemporalConfidence.high,
      origin: ExpectedPaymentWindowOrigin.occurrenceOverride,
    );
