import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_forecast_reader.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';

void main() {
  const reader = FiniteFinancialPlanForecastReader();

  group('FiniteFinancialPlanForecastReader', () {
    test('empty plans produce zero outflow', () {
      expect(reader.projectedOutflowForMonth([], DateTime(2027, 3)), 0);
    });

    test('installment three contributes after two completed installments', () {
      final plan = _plan(completedInstallments: 2);

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 3)), 386);
    });

    test('a completed installment does not contribute again', () {
      final plan = _plan(completedInstallments: 1);

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 1)), 0);
      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 2)), 386);
    });

    test('last installment contributes but the following month does not', () {
      final plan = _plan(completedInstallments: 11);

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 12)), 386);
      expect(reader.projectedOutflowForMonth([plan], DateTime(2028, 1)), 0);
    });

    test('completed plan produces zero outflow', () {
      final plan = _plan(completedInstallments: 12);

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 12)), 0);
    });

    test('month without an installment produces zero outflow', () {
      final plan = _plan(
        totalInstallments: 1,
        firstInstallmentDate: DateTime(2027, 3, 15),
      );

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 2)), 0);
    });

    test('multiple plans in the same month are summed without deduplication', () {
      final first = _plan(id: 'plan_a', expectedAmount: 386);
      final second = _plan(id: 'plan_b', expectedAmount: 100);

      expect(
        reader.projectedOutflowForMonth([first, second], DateTime(2027, 1)),
        486,
      );
    });

    test('plans in different months contribute only to their own month', () {
      final january = _plan(
        id: 'plan_january',
        totalInstallments: 1,
        expectedAmount: 386,
      );
      final february = _plan(
        id: 'plan_february',
        totalInstallments: 1,
        expectedAmount: 100,
        firstInstallmentDate: DateTime(2027, 2, 15),
      );

      expect(
        reader.projectedOutflowForMonth([january, february], DateTime(2027, 1)),
        386,
      );
      expect(
        reader.projectedOutflowForMonth([january, february], DateTime(2027, 2)),
        100,
      );
    });

    test('day 31 February contribution follows the adapter calendar', () {
      final plan = _plan(
        totalInstallments: 3,
        firstInstallmentDate: DateTime(2027, 1, 31),
        scheduledDayOfMonth: 31,
      );

      expect(reader.projectedOutflowForMonth([plan], DateTime(2027, 2)), 386);
      expect(plan.installment(2)!.dueDate, DateTime(2027, 2, 28));
    });

    test('reading does not modify plan progression', () {
      final plan = _plan(completedInstallments: 2);
      final completedBefore = plan.completedInstallments;
      final scheduleBefore = plan.remainingSchedule
          .map((item) => (item.number, item.dueDate, item.expectedAmount))
          .toList();

      reader.projectedOutflowForMonth([plan], DateTime(2027, 3));

      expect(plan.completedInstallments, completedBefore);
      expect(
        plan.remainingSchedule
            .map((item) => (item.number, item.dueDate, item.expectedAmount)),
        orderedEquals(scheduleBefore),
      );
    });

    test('is pure and has no economic, store, or persistence dependencies', () {
      final source = File(
        'lib/logic/finance/finite_financial_plan_forecast_reader.dart',
      ).readAsStringSync();

      expect(source, contains('FiniteFinancialPlanForecastAdapter'));
      expect(source, isNot(contains('FinanceRecurringItem')));
      expect(source, isNot(contains('FinanceTransaction')));
      expect(source, isNot(contains('RealExpense')));
      expect(source, isNot(contains('EconomicEvent')));
      expect(source, isNot(contains('FinanceStore')));
      expect(source, isNot(contains('PersistenceStore')));
      expect(source, isNot(contains('save')));
    });
  });
}

FiniteFinancialPlan _plan({
  String id = 'plan_inps',
  int totalInstallments = 12,
  int completedInstallments = 0,
  double expectedAmount = 386,
  DateTime? firstInstallmentDate,
  int scheduledDayOfMonth = 15,
}) {
  return FiniteFinancialPlan(
    id: id,
    name: 'Rateizzazione INPS',
    description: 'Piano finito',
    subject: FinanceSubject.matteo,
    creditor: 'INPS',
    debitBalanceId: 'balance_banca',
    totalInstallments: totalInstallments,
    expectedInstallmentAmount: expectedAmount,
    firstInstallmentDate: firstInstallmentDate ?? DateTime(2027, 1, 15),
    scheduledDayOfMonth: scheduledDayOfMonth,
    completedInstallments: completedInstallments,
  );
}
