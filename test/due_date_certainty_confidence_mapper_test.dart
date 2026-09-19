import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/due_date_certainty_confidence_mapper.dart';
import 'package:frododesk/logic/finance/manual_payment_window_materializer.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  group('due-date certainty confidence mapping', () {
    test('estimated maps only to low', () {
      final confidence = confidenceForDueDateCertainty(
        ExpectedExpenseDateCertainty.estimated,
      );

      expect(confidence, ExpectedTemporalConfidence.low);
      expect(confidence, isNot(ExpectedTemporalConfidence.medium));
      expect(confidence, isNot(ExpectedTemporalConfidence.high));
    });

    test('known maps only to high', () {
      final confidence = confidenceForDueDateCertainty(
        ExpectedExpenseDateCertainty.known,
      );

      expect(confidence, ExpectedTemporalConfidence.high);
      expect(confidence, isNot(ExpectedTemporalConfidence.medium));
      expect(confidence, isNot(ExpectedTemporalConfidence.low));
    });

    test('legacy unspecified maps to no confidence', () {
      final confidence = confidenceForDueDateCertainty(
        ExpectedExpenseDateCertainty.legacyUnspecified,
      );

      expect(confidence, isNull);
      expect(confidence, isNot(ExpectedTemporalConfidence.low));
      expect(confidence, isNot(ExpectedTemporalConfidence.medium));
      expect(confidence, isNot(ExpectedTemporalConfidence.high));
    });

    test(
      'explicit estimated due date materializes a low-confidence window',
      () {
        final preference = ManualPaymentPreference(preferredStartDayOfMonth: 5);
        final confidence = confidenceForDueDateCertainty(
          ExpectedExpenseDateCertainty.estimated,
        );

        final result = const ManualPaymentWindowMaterializer().materialize(
          preference: preference,
          expectedDueDate: DateTime(2026, 11, 14),
          source: ExpectedExpenseDateSource.explicit,
          confidence: confidence!,
        );

        expect(
          result.outcome,
          ManualPaymentWindowMaterializationOutcome.materialized,
        );
        expect(result.window?.start, DateTime(2026, 11, 5));
        expect(result.window?.end, DateTime(2026, 11, 14));
        expect(result.window?.source, ExpectedExpenseDateSource.explicit);
        expect(result.window?.confidence, ExpectedTemporalConfidence.low);
        expect(preference.preferredStartDayOfMonth, 5);
      },
    );

    test('explicit known due date materializes a high-confidence window', () {
      final preference = ManualPaymentPreference(preferredStartDayOfMonth: 5);
      final confidence = confidenceForDueDateCertainty(
        ExpectedExpenseDateCertainty.known,
      );

      final result = const ManualPaymentWindowMaterializer().materialize(
        preference: preference,
        expectedDueDate: DateTime(2026, 11, 20),
        source: ExpectedExpenseDateSource.explicit,
        confidence: confidence!,
      );

      expect(
        result.outcome,
        ManualPaymentWindowMaterializationOutcome.materialized,
      );
      expect(result.window?.start, DateTime(2026, 11, 5));
      expect(result.window?.end, DateTime(2026, 11, 20));
      expect(result.window?.source, ExpectedExpenseDateSource.explicit);
      expect(result.window?.confidence, ExpectedTemporalConfidence.high);
      expect(preference.preferredStartDayOfMonth, 5);
    });
  });
}
