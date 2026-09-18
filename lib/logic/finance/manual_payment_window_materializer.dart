import '../../models/expected_expense_occurrence.dart';
import '../../models/manual_payment_preference.dart';

enum ManualPaymentWindowMaterializationOutcome {
  materialized,
  requiresExplicitChoice,
}

class ManualPaymentWindowMaterializationResult {
  final ManualPaymentWindowMaterializationOutcome outcome;
  final ExpectedPaymentWindow? window;

  const ManualPaymentWindowMaterializationResult._({
    required this.outcome,
    required this.window,
  });

  const ManualPaymentWindowMaterializationResult.materialized(
    ExpectedPaymentWindow window,
  ) : this._(
        outcome: ManualPaymentWindowMaterializationOutcome.materialized,
        window: window,
      );

  const ManualPaymentWindowMaterializationResult.requiresExplicitChoice()
    : this._(
        outcome:
            ManualPaymentWindowMaterializationOutcome.requiresExplicitChoice,
        window: null,
      );
}

/// Materializes a relationship-level manual payment preference without side
/// effects. The caller remains responsible for payment-method applicability.
class ManualPaymentWindowMaterializer {
  const ManualPaymentWindowMaterializer();

  ManualPaymentWindowMaterializationResult materialize({
    required ManualPaymentPreference preference,
    required DateTime expectedDueDate,
    required ExpectedExpenseDateSource source,
    required ExpectedTemporalConfidence confidence,
  }) {
    final lastDay = _lastDayOfMonth(expectedDueDate);
    final preferredDay = preference.preferredStartDayOfMonth;
    final startDay = preferredDay <= lastDay ? preferredDay : lastDay;

    if (startDay > expectedDueDate.day) {
      return const ManualPaymentWindowMaterializationResult.requiresExplicitChoice();
    }

    final start = expectedDueDate.isUtc
        ? DateTime.utc(expectedDueDate.year, expectedDueDate.month, startDay)
        : DateTime(expectedDueDate.year, expectedDueDate.month, startDay);
    return ManualPaymentWindowMaterializationResult.materialized(
      ExpectedPaymentWindow(
        start: start,
        end: expectedDueDate,
        semantic: ExpectedPaymentWindowSemantic.userPreferred,
        source: source,
        confidence: confidence,
        origin: ExpectedPaymentWindowOrigin.relationshipDefault,
      ),
    );
  }

  int _lastDayOfMonth(DateTime date) {
    final nextMonth = date.isUtc
        ? DateTime.utc(date.year, date.month + 1)
        : DateTime(date.year, date.month + 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }
}
