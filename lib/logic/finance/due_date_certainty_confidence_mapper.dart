import '../../models/expected_expense_occurrence.dart';

/// Maps the certainty of an expected due date to the confidence of a newly
/// materialized payment window.
///
/// A legacy-unqualified date cannot authorize automatic materialization.
ExpectedTemporalConfidence? confidenceForDueDateCertainty(
  ExpectedExpenseDateCertainty certainty,
) => switch (certainty) {
  ExpectedExpenseDateCertainty.estimated => ExpectedTemporalConfidence.low,
  ExpectedExpenseDateCertainty.known => ExpectedTemporalConfidence.high,
  ExpectedExpenseDateCertainty.legacyUnspecified => null,
};
