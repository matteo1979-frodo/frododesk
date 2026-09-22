import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/first_cycle_expense_evidence.dart';
import '../../models/finance_recurring_item.dart';

/// Purely derives the first future occurrence from one available real fact.
class FirstCycleExpectedExpenseGenerator {
  const FirstCycleExpectedExpenseGenerator();

  ExpectedExpenseOccurrence generate({
    required ExpenseRelationship relationship,
    required FirstCycleExpenseEvidence evidence,
    required String occurrenceId,
    DateTime? explicitNextDate,
  }) {
    if (relationship.status != ExpenseRelationshipStatus.active) {
      throw StateError(
        'A terminated expense relationship cannot generate occurrences',
      );
    }
    if (explicitNextDate != null &&
        !explicitNextDate.isAfter(evidence.referenceDate)) {
      throw ArgumentError.value(
        explicitNextDate,
        'explicitNextDate',
        'Must be after the evidence reference date',
      );
    }

    final nextDate =
        explicitNextDate ??
        _nextDate(evidence.referenceDate, relationship.periodicity);
    final dateSource = explicitNextDate == null
        ? ExpectedExpenseDateSource.calculatedFromPeriodicity
        : ExpectedExpenseDateSource.explicit;
    final isIssue =
        evidence.referenceDateSemantic == ExpenseEvidenceDateSemantic.issue;
    final payment = relationship.paymentConfiguration;

    return ExpectedExpenseOccurrence(
      occurrenceId: occurrenceId,
      relationshipId: relationship.relationshipId,
      cycleSequence: 1,
      cycleAnchor: nextDate,
      status: ExpectedExpenseOccurrenceStatus.pending,
      expectedIssueDate: isIssue ? nextDate : null,
      expectedIssueDateSource: isIssue ? dateSource : null,
      expectedDueDate: isIssue ? null : nextDate,
      expectedDueDateSource: isIssue ? null : dateSource,
      expectedAmount: evidence.amount,
      estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
      evidenceEconomicFactIds: [evidence.economicFactId],
      confidence: ExpenseEstimateConfidence.low,
      provisional: true,
      expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: payment.method,
        expectedBalanceId: payment.expectedBalanceId,
      ),
      paymentExecutionMode: relationship.paymentExecutionMode,
      expectedSubject: relationship.subject,
    );
  }

  DateTime _nextDate(
    DateTime referenceDate,
    ExpenseRelationshipPeriodicity periodicity,
  ) {
    final months = switch (periodicity.type) {
      FinanceRecurringType.monthly => 1,
      FinanceRecurringType.yearly => 12,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'months' =>
        periodicity.customInterval!,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'years' =>
        periodicity.customInterval! * 12,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'days' =>
        null,
      FinanceRecurringType.custom => throw UnsupportedError(
        'Custom periodicity unit is not supported: '
        '${periodicity.customIntervalUnit}',
      ),
      FinanceRecurringType.oneShot => throw UnsupportedError(
        'One-shot periodicity cannot generate a future occurrence',
      ),
    };
    if (months == null) {
      return referenceDate.add(Duration(days: periodicity.customInterval!));
    }
    return _addMonthsClamped(referenceDate, months);
  }

  DateTime _addMonthsClamped(DateTime source, int months) {
    final monthStart = source.isUtc
        ? DateTime.utc(source.year, source.month + months)
        : DateTime(source.year, source.month + months);
    final nextMonthStart = source.isUtc
        ? DateTime.utc(monthStart.year, monthStart.month + 1)
        : DateTime(monthStart.year, monthStart.month + 1);
    final lastDay = nextMonthStart.subtract(const Duration(days: 1)).day;
    final day = source.day <= lastDay ? source.day : lastDay;

    return source.isUtc
        ? DateTime.utc(
            monthStart.year,
            monthStart.month,
            day,
            source.hour,
            source.minute,
            source.second,
            source.millisecond,
            source.microsecond,
          )
        : DateTime(
            monthStart.year,
            monthStart.month,
            day,
            source.hour,
            source.minute,
            source.second,
            source.millisecond,
            source.microsecond,
          );
  }
}
