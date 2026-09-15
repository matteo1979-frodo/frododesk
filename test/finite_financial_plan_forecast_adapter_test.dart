import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_forecast_adapter.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';

void main() {
  const adapter = FiniteFinancialPlanForecastAdapter();

  group('FiniteFinancialPlanForecastAdapter', () {
    test('adapts only installments three through twelve', () {
      final items = adapter.remainingItems(_plan(completedInstallments: 2));

      expect(items, hasLength(10));
      expect(items.first.installmentNumber, 3);
      expect(items.last.installmentNumber, 12);
      expect(
        items.where((item) => item.installmentNumber == 13),
        isEmpty,
      );
    });

    test('preserves certain plan and installment data', () {
      final item = adapter.remainingItems(
        _plan(completedInstallments: 2),
      ).first;

      expect(item.planId, 'plan_inps');
      expect(item.installmentNumber, 3);
      expect(item.expectedAmount, 386);
      expect(item.name, 'Rateizzazione INPS');
      expect(item.description, 'Piano finito');
      expect(item.subject, FinanceSubject.matteo);
      expect(item.debitBalanceId, 'balance_banca');
      expect(item.isOutflow, isTrue);
    });

    test('preserves a null debit balance id', () {
      final item = adapter.remainingItems(
        _plan(debitBalanceId: null),
      ).first;

      expect(item.debitBalanceId, isNull);
    });

    test('completed plan produces no forecast items', () {
      final items = adapter.remainingItems(
        _plan(completedInstallments: 12),
      );

      expect(items, isEmpty);
    });

    test('returns only the installment belonging to the requested month', () {
      final plan = _plan(completedInstallments: 2);

      final matching = adapter.itemsForMonth(plan, DateTime(2027, 3, 20));
      final afterLast = adapter.itemsForMonth(plan, DateTime(2028, 1, 1));

      expect(matching, hasLength(1));
      expect(matching.single.installmentNumber, 3);
      expect(afterLast, isEmpty);
    });

    test('uses the exact day-31 dates produced by the plan', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 1, 31),
        scheduledDayOfMonth: 31,
      );
      final planFebruary = plan.installment(2)!;
      final forecastFebruary = adapter.itemsForMonth(
        plan,
        DateTime(2027, 2),
      ).single;

      expect(forecastFebruary.date, planFebruary.dueDate);
      expect(forecastFebruary.date, DateTime(2027, 2, 28));
      expect(
        adapter.itemsForMonth(plan, DateTime(2027, 3)).single.date,
        plan.installment(3)!.dueDate,
      );
    });

    test('identity is deterministic and distinct per installment', () {
      final plan = _plan();
      final firstRun = adapter.remainingItems(plan);
      final secondRun = adapter.remainingItems(plan);

      expect(firstRun.first.identity, secondRun.first.identity);
      expect(firstRun[0].identity, isNot(firstRun[1].identity));
    });

    test('is projection-only and has no economic or store dependencies', () {
      final source = File(
        'lib/logic/finance/finite_financial_plan_forecast_adapter.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('economicFactId')));
      expect(source, isNot(contains('FinanceStore')));
      expect(source, isNot(contains('FinanceTransaction')));
      expect(source, isNot(contains('FinanceRecurringItem')));
      expect(source, isNot(contains('RealExpense')));
      expect(source, isNot(contains('Ledger')));
      expect(source, isNot(contains('PersistenceStore')));
      expect(source, isNot(contains('save')));
    });
  });
}

FiniteFinancialPlan _plan({
  int completedInstallments = 0,
  DateTime? firstInstallmentDate,
  int scheduledDayOfMonth = 15,
  String? debitBalanceId = 'balance_banca',
}) {
  return FiniteFinancialPlan(
    id: 'plan_inps',
    name: 'Rateizzazione INPS',
    description: 'Piano finito',
    subject: FinanceSubject.matteo,
    creditor: 'INPS',
    debitBalanceId: debitBalanceId,
    totalInstallments: 12,
    expectedInstallmentAmount: 386,
    firstInstallmentDate: firstInstallmentDate ?? DateTime(2027, 1, 15),
    scheduledDayOfMonth: scheduledDayOfMonth,
    completedInstallments: completedInstallments,
  );
}
