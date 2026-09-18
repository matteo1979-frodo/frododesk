import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/manual_payment_window_materializer.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  const materializer = ManualPaymentWindowMaterializer();

  ManualPaymentWindowMaterializationResult materialize(
    int preferredDay,
    DateTime dueDate, {
    ExpectedExpenseDateSource source = ExpectedExpenseDateSource.explicit,
    ExpectedTemporalConfidence confidence = ExpectedTemporalConfidence.high,
  }) => materializer.materialize(
    preference: ManualPaymentPreference(preferredStartDayOfMonth: preferredDay),
    expectedDueDate: dueDate,
    source: source,
    confidence: confidence,
  );

  test('materializes day 5 through a due date on day 14', () {
    final result = materialize(5, DateTime(2026, 11, 14));

    expect(
      result.outcome,
      ManualPaymentWindowMaterializationOutcome.materialized,
    );
    expect(result.window?.start, DateTime(2026, 11, 5));
    expect(result.window?.end, DateTime(2026, 11, 14));
  });

  test('re-materializes deterministically when the due date changes', () {
    final first = materialize(5, DateTime(2026, 11, 14));
    final updated = materialize(5, DateTime(2026, 11, 20));

    expect(first.window?.start, DateTime(2026, 11, 5));
    expect(first.window?.end, DateTime(2026, 11, 14));
    expect(updated.window?.start, DateTime(2026, 11, 5));
    expect(updated.window?.end, DateTime(2026, 11, 20));
  });

  for (final testCase in <({DateTime dueDate, DateTime expectedStart})>[
    (dueDate: DateTime(2027, 2, 28), expectedStart: DateTime(2027, 2, 28)),
    (dueDate: DateTime(2028, 2, 29), expectedStart: DateTime(2028, 2, 29)),
    (dueDate: DateTime(2026, 4, 30), expectedStart: DateTime(2026, 4, 30)),
    (dueDate: DateTime(2026, 5, 31), expectedStart: DateTime(2026, 5, 31)),
  ]) {
    test('clamps day 31 for due date ${testCase.dueDate}', () {
      final result = materialize(31, testCase.dueDate);

      expect(result.window?.start, testCase.expectedStart);
    });
  }

  test('requires an explicit choice when preferred start follows due date', () {
    final preference = ManualPaymentPreference(preferredStartDayOfMonth: 10);

    final result = materializer.materialize(
      preference: preference,
      expectedDueDate: DateTime(2026, 11, 8),
      source: ExpectedExpenseDateSource.explicit,
      confidence: ExpectedTemporalConfidence.high,
    );

    expect(
      result.outcome,
      ManualPaymentWindowMaterializationOutcome.requiresExplicitChoice,
    );
    expect(result.window, isNull);
    expect(preference.preferredStartDayOfMonth, 10);
  });

  test('produces only relationship-default user-preferred windows', () {
    final result = materialize(5, DateTime(2026, 11, 14));

    expect(
      result.window?.semantic,
      ExpectedPaymentWindowSemantic.userPreferred,
    );
    expect(
      result.window?.origin,
      ExpectedPaymentWindowOrigin.relationshipDefault,
    );
    expect(
      result.window?.origin,
      isNot(ExpectedPaymentWindowOrigin.occurrenceOverride),
    );
  });

  test('preserves explicit source and confidence inputs', () {
    final result = materialize(
      5,
      DateTime.utc(2026, 11, 14),
      source: ExpectedExpenseDateSource.calculatedFromPeriodicity,
      confidence: ExpectedTemporalConfidence.medium,
    );

    expect(result.window?.start, DateTime.utc(2026, 11, 5));
    expect(
      result.window?.source,
      ExpectedExpenseDateSource.calculatedFromPeriodicity,
    );
    expect(result.window?.confidence, ExpectedTemporalConfidence.medium);
  });
}
