import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('absent key returns a protected empty aggregate', () async {
    final aggregate = await ExpectedExpensePersistence().load();

    expect(aggregate.relationships, isEmpty);
    expect(aggregate.occurrences, isEmpty);
    expect(() => aggregate.relationships.clear(), throwsUnsupportedError);
    expect(() => aggregate.occurrences.clear(), throwsUnsupportedError);
  });

  test('empty aggregate round-trips in one versioned envelope', () async {
    final persistence = ExpectedExpensePersistence();

    expect(
      (await persistence.write(ExpectedExpenseAggregate.empty())).isSuccess,
      isTrue,
    );
    final restored = await persistence.load();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('frododesk_finance_expected_expenses_v1');
    final envelope = jsonDecode(raw!) as Map<String, dynamic>;

    expect(envelope['version'], 1);
    expect(envelope['relationships'], isEmpty);
    expect(envelope['occurrences'], isEmpty);
    expect(restored.relationships, isEmpty);
    expect(restored.occurrences, isEmpty);
  });

  test(
    'relationships and occurrences round-trip every existing field',
    () async {
      final relationships = [_relationship('relationship_1')];
      final occurrences = [
        _occurrence('occurrence_1', relationshipId: 'relationship_1'),
      ];
      final persistence = ExpectedExpensePersistence();

      expect(
        (await persistence.write(
          ExpectedExpenseAggregate(
            relationships: relationships,
            occurrences: occurrences,
          ),
        )).isSuccess,
        isTrue,
      );
      final restored = await persistence.load();

      expect(
        restored.relationships.single.toJson(),
        relationships.single.toJson(),
      );
      expect(restored.occurrences.single.toJson(), occurrences.single.toJson());
    },
  );

  test('supports multiple relationships and occurrences', () async {
    final aggregate = ExpectedExpenseAggregate(
      relationships: [
        _relationship('relationship_1'),
        _relationship('relationship_2'),
      ],
      occurrences: [
        _occurrence('occurrence_1', relationshipId: 'relationship_1'),
        _occurrence('occurrence_2', relationshipId: 'relationship_2'),
      ],
    );
    final persistence = ExpectedExpensePersistence();

    expect((await persistence.write(aggregate)).isSuccess, isTrue);
    final restored = await persistence.load();

    expect(restored.relationships, hasLength(2));
    expect(restored.occurrences, hasLength(2));
  });

  test('allows multiple pending occurrences for one relationship', () async {
    final aggregate = ExpectedExpenseAggregate(
      relationships: [_relationship('relationship_1')],
      occurrences: [
        _occurrence('occurrence_1', relationshipId: 'relationship_1'),
        _occurrence('occurrence_2', relationshipId: 'relationship_1'),
      ],
    );

    expect(
      (await ExpectedExpensePersistence().write(aggregate)).isSuccess,
      isTrue,
    );
  });

  test('rejects duplicate relationship and occurrence identities', () async {
    final duplicateRelationships = ExpectedExpenseAggregate(
      relationships: [
        _relationship('relationship_1'),
        _relationship('relationship_1'),
      ],
    );
    final duplicateOccurrences = ExpectedExpenseAggregate(
      relationships: [_relationship('relationship_1')],
      occurrences: [
        _occurrence('occurrence_1', relationshipId: 'relationship_1'),
        _occurrence('occurrence_1', relationshipId: 'relationship_1'),
      ],
    );
    final persistence = ExpectedExpensePersistence();

    expect(
      (await persistence.write(duplicateRelationships)).failure,
      ExpectedExpenseWriteFailure.invalidPayload,
    );
    expect(
      (await persistence.write(duplicateOccurrences)).failure,
      ExpectedExpenseWriteFailure.invalidPayload,
    );
  });

  test('rejects an occurrence whose relationship is absent', () async {
    final result = await ExpectedExpensePersistence().write(
      ExpectedExpenseAggregate(
        occurrences: [_occurrence('occurrence_1', relationshipId: 'missing')],
      ),
    );

    expect(result.failure, ExpectedExpenseWriteFailure.invalidPayload);
    expect(result.errors.single, contains('missing relationship'));
  });

  test('resolved occurrence preserves its resolved economic fact', () async {
    final persistence = ExpectedExpensePersistence();
    final aggregate = ExpectedExpenseAggregate(
      relationships: [_relationship('relationship_1')],
      occurrences: [
        _occurrence(
          'occurrence_1',
          relationshipId: 'relationship_1',
          status: ExpectedExpenseOccurrenceStatus.resolved,
          resolvedEconomicFactId: 'economic_fact_real_1',
        ),
      ],
    );

    expect((await persistence.write(aggregate)).isSuccess, isTrue);
    final restored = await persistence.load();

    expect(
      restored.occurrences.single.resolvedEconomicFactId,
      'economic_fact_real_1',
    );
  });

  test(
    'qualified payment-window metadata survives aggregate persistence',
    () async {
      final persistence = ExpectedExpensePersistence();
      final aggregate = ExpectedExpenseAggregate(
        relationships: [_relationship('relationship_1')],
        occurrences: [
          _occurrence(
            'occurrence_1',
            relationshipId: 'relationship_1',
            paymentWindow: ExpectedPaymentWindow(
              start: DateTime(2026, 11, 5),
              end: DateTime(2026, 11, 14),
              semantic: ExpectedPaymentWindowSemantic.userPreferred,
              source: ExpectedExpenseDateSource.explicit,
              confidence: ExpectedTemporalConfidence.high,
            ),
          ),
        ],
      );

      expect((await persistence.write(aggregate)).isSuccess, isTrue);
      final restored = await persistence.load();
      final window = restored.occurrences.single.expectedPaymentWindow!;

      expect(window.semantic, ExpectedPaymentWindowSemantic.userPreferred);
      expect(window.source, ExpectedExpenseDateSource.explicit);
      expect(window.confidence, ExpectedTemporalConfidence.high);
    },
  );

  test(
    'malformed JSON, wrong root and unknown version fail explicitly',
    () async {
      for (final raw in [
        '{broken',
        '[]',
        jsonEncode({'version': 2}),
      ]) {
        final persistence = ExpectedExpensePersistence(load: (_) async => raw);

        await expectLater(persistence.load(), throwsFormatException);
      }
    },
  );

  test(
    'invalid relationship and occurrence elements fail explicitly',
    () async {
      final invalidRelationship = _envelope(
        relationships: [
          {..._relationship('relationship_1').toJson(), 'relationshipId': ''},
        ],
      );
      final invalidOccurrence = _envelope(
        relationships: [_relationship('relationship_1').toJson()],
        occurrences: [
          {
            ..._occurrence(
              'occurrence_1',
              relationshipId: 'relationship_1',
            ).toJson(),
            'expectedAmount': 0,
          },
        ],
      );

      for (final raw in [invalidRelationship, invalidOccurrence]) {
        final persistence = ExpectedExpensePersistence(load: (_) async => raw);

        await expectLater(persistence.load(), throwsFormatException);
      }
    },
  );

  test('verified write succeeds and uses the logical key once', () async {
    String? observedKey;
    String? observedValue;
    final persistence = ExpectedExpensePersistence(
      saveVerified: (key, value) async {
        observedKey = key;
        observedValue = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    final result = await persistence.write(_aggregate());

    expect(result.isSuccess, isTrue);
    expect(observedKey, 'finance_expected_expenses_v1');
    expect(observedValue, isNotEmpty);
  });

  test('backend rejection, missing and mismatched read-back fail', () async {
    final cases =
        <MapEntry<PersistenceWriteVerification, ExpectedExpenseWriteFailure>>[
          const MapEntry(
            PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            ),
            ExpectedExpenseWriteFailure.backendRejected,
          ),
          const MapEntry(
            PersistenceWriteVerification(backendAccepted: true, readBack: null),
            ExpectedExpenseWriteFailure.missingReadBack,
          ),
          const MapEntry(
            PersistenceWriteVerification(
              backendAccepted: true,
              readBack: 'different',
            ),
            ExpectedExpenseWriteFailure.mismatchedReadBack,
          ),
        ];

    for (final entry in cases) {
      final result = await ExpectedExpensePersistence(
        saveVerified: (_, _) async => entry.key,
      ).write(_aggregate());

      expect(result.failure, entry.value);
      expect(result.isSuccess, isFalse);
    }
  });

  test('persistence exception is an explicit failed result', () async {
    final result = await ExpectedExpensePersistence(
      saveVerified: (_, _) => throw StateError('offline'),
    ).write(_aggregate());

    expect(result.failure, ExpectedExpenseWriteFailure.persistenceError);
    expect(result.errors.single, contains('offline'));
  });

  test(
    'failed candidate does not replace the previously persisted aggregate',
    () async {
      final original = _aggregate();
      var raw = _envelope(
        relationships: original.relationships
            .map((item) => item.toJson())
            .toList(),
        occurrences: original.occurrences.map((item) => item.toJson()).toList(),
      );
      final persistence = ExpectedExpensePersistence(
        load: (_) async => raw,
        saveVerified: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      );
      final replacement = ExpectedExpenseAggregate(
        relationships: [_relationship('relationship_2')],
      );

      expect((await persistence.write(replacement)).isSuccess, isFalse);
      final restored = await persistence.load();

      expect(restored.relationships.single.relationshipId, 'relationship_1');
    },
  );

  test('retrying the same candidate is idempotently successful', () async {
    String? raw;
    final persistence = ExpectedExpensePersistence(
      load: (_) async => raw,
      saveVerified: (_, value) async {
        raw = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: raw,
        );
      },
    );
    final candidate = _aggregate();

    expect((await persistence.write(candidate)).isSuccess, isTrue);
    expect((await persistence.write(candidate)).isSuccess, isTrue);
    final restored = await persistence.load();

    expect(restored.relationships, hasLength(1));
    expect(restored.occurrences, hasLength(1));
  });

  test(
    'identity does not depend on provider, service, amount or date',
    () async {
      final first = _relationship('relationship_1');
      final second = _relationship('relationship_2');
      final aggregate = ExpectedExpenseAggregate(
        relationships: [first, second],
        occurrences: [
          _occurrence('occurrence_1', relationshipId: first.relationshipId),
          _occurrence('occurrence_2', relationshipId: second.relationshipId),
        ],
      );

      expect(
        (await ExpectedExpensePersistence().write(aggregate)).isSuccess,
        isTrue,
      );
    },
  );
}

ExpectedExpenseAggregate _aggregate() => ExpectedExpenseAggregate(
  relationships: [_relationship('relationship_1')],
  occurrences: [_occurrence('occurrence_1', relationshipId: 'relationship_1')],
);

ExpenseRelationship _relationship(String id) => ExpenseRelationship(
  relationshipId: id,
  service: 'Acqua',
  provider: 'Hera',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.custom,
    customInterval: 2,
    customIntervalUnit: 'months',
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
);

ExpectedExpenseOccurrence _occurrence(
  String id, {
  required String relationshipId,
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  String? resolvedEconomicFactId,
  ExpectedPaymentWindow? paymentWindow,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: relationshipId,
  status: status,
  expectedIssueDate: DateTime(2026, 10, 23),
  expectedIssueDateSource: ExpectedExpenseDateSource.explicit,
  expectedPaymentWindow: paymentWindow,
  expectedAmount: 59.63,
  estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
  evidenceEconomicFactIds: const ['economic_fact_1'],
  confidence: ExpenseEstimateConfidence.low,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
  expectedSubject: FinanceSubject.matteo,
  resolvedEconomicFactId: resolvedEconomicFactId,
);

String _envelope({
  List<Map<String, dynamic>> relationships = const [],
  List<Map<String, dynamic>> occurrences = const [],
}) => jsonEncode({
  'version': 1,
  'relationships': relationships,
  'occurrences': occurrences,
});
