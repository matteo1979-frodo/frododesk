import '../../models/expected_expense_occurrence.dart';
import '../../models/expected_expense_projection.dart';
import '../../models/future_expense_projection.dart';

/// Pure policy layer over complete expected-expense projections.
///
/// It preserves input order, includes only pending occurrences, and never
/// invents an economic-impact date from unrelated temporal information.
class FutureExpenseReader {
  const FutureExpenseReader();

  List<FutureExpenseProjection> read({
    required Iterable<ExpectedExpenseProjection> projections,
    required DateTime referenceTime,
  }) => List<FutureExpenseProjection>.unmodifiable(
    projections
        .where(
          (projection) =>
              projection.status == ExpectedExpenseOccurrenceStatus.pending,
        )
        .map((projection) {
          final displayPlacement = _displayPlacement(projection);
          return FutureExpenseProjection(
            source: projection,
            economicImpactPlacement: _placement(projection),
            economicImpactStart: _impactStart(projection),
            economicImpactEnd: _impactEnd(projection),
            displayPlacement: displayPlacement,
            displayStart: _displayStart(projection, displayPlacement),
            displayEnd: _displayEnd(projection, displayPlacement),
            overdueQualification: _overdue(projection, referenceTime),
          );
        }),
  );

  FutureExpenseDisplayPlacement _displayPlacement(
    ExpectedExpenseProjection projection,
  ) {
    if (projection.plannedEconomicImpact != null) {
      return FutureExpenseDisplayPlacement.plannedEconomicImpact;
    }
    if (projection.expectedPaymentWindow?.semantic ==
        ExpectedPaymentWindowSemantic.expectedDebit) {
      return FutureExpenseDisplayPlacement.expectedDebitWindow;
    }
    if (projection.expectedDueDate != null) {
      return FutureExpenseDisplayPlacement.dueDateFallback;
    }
    return FutureExpenseDisplayPlacement.unplaced;
  }

  DateTime? _displayStart(
    ExpectedExpenseProjection projection,
    FutureExpenseDisplayPlacement placement,
  ) => switch (placement) {
    FutureExpenseDisplayPlacement.plannedEconomicImpact =>
      projection.plannedEconomicImpact!.start,
    FutureExpenseDisplayPlacement.expectedDebitWindow =>
      projection.expectedPaymentWindow!.start,
    FutureExpenseDisplayPlacement.dueDateFallback => projection.expectedDueDate,
    FutureExpenseDisplayPlacement.unplaced => null,
  };

  DateTime? _displayEnd(
    ExpectedExpenseProjection projection,
    FutureExpenseDisplayPlacement placement,
  ) => switch (placement) {
    FutureExpenseDisplayPlacement.plannedEconomicImpact =>
      projection.plannedEconomicImpact!.end,
    FutureExpenseDisplayPlacement.expectedDebitWindow =>
      projection.expectedPaymentWindow!.end,
    FutureExpenseDisplayPlacement.dueDateFallback => projection.expectedDueDate,
    FutureExpenseDisplayPlacement.unplaced => null,
  };

  FutureExpenseEconomicImpactPlacement _placement(
    ExpectedExpenseProjection projection,
  ) {
    if (projection.plannedEconomicImpact != null) {
      return FutureExpenseEconomicImpactPlacement.plannedEconomicImpact;
    }
    if (projection.expectedPaymentWindow?.semantic ==
        ExpectedPaymentWindowSemantic.expectedDebit) {
      return FutureExpenseEconomicImpactPlacement.expectedDebitWindow;
    }
    return FutureExpenseEconomicImpactPlacement.insufficient;
  }

  DateTime? _impactStart(ExpectedExpenseProjection projection) {
    final planned = projection.plannedEconomicImpact;
    if (planned != null) return planned.start;
    final window = projection.expectedPaymentWindow;
    return window?.semantic == ExpectedPaymentWindowSemantic.expectedDebit
        ? window?.start
        : null;
  }

  DateTime? _impactEnd(ExpectedExpenseProjection projection) {
    final planned = projection.plannedEconomicImpact;
    if (planned != null) return planned.end;
    final window = projection.expectedPaymentWindow;
    return window?.semantic == ExpectedPaymentWindowSemantic.expectedDebit
        ? window?.end
        : null;
  }

  FutureExpenseOverdueQualification _overdue(
    ExpectedExpenseProjection projection,
    DateTime referenceTime,
  ) {
    final dueDate = projection.expectedDueDate;
    if (dueDate == null || !referenceTime.isAfter(dueDate)) {
      return FutureExpenseOverdueQualification.notOverdue;
    }
    return switch (projection.expectedDueDateCertainty) {
      ExpectedExpenseDateCertainty.known =>
        FutureExpenseOverdueQualification.overdueKnown,
      ExpectedExpenseDateCertainty.estimated =>
        FutureExpenseOverdueQualification.overdueEstimated,
      ExpectedExpenseDateCertainty.legacyUnspecified ||
      null => FutureExpenseOverdueQualification.overdueUnspecifiedCertainty,
    };
  }
}
