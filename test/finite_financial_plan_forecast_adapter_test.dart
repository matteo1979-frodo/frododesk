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

    test('uses an installment override without adapter-specific logic', () {
      final item = adapter.itemsForMonth(
        _plan(installmentAmountOverrides: const {3: 401.25}),
        DateTime(2027, 3),
      ).single;

      expect(item.installmentNumber, 3);
      expect(item.expectedAmount, 401.25);
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

    test('returns only installments in an inclusive nearby range', () {
      final items = adapter.itemsInRange(
        plan: _plan(),
        start: DateTime(2027, 3, 15),
        end: DateTime(2027, 4, 15),
      );

      expect(items.map((item) => item.installmentNumber), [3, 4]);
      expect(items.map((item) => item.date), [
        DateTime(2027, 3, 15),
        DateTime(2027, 4, 15),
      ]);
      expect(() => items.add(items.first), throwsUnsupportedError);
    });

    test('seeks directly into 2056 in a forty-year monthly plan', () {
      final items = adapter.itemsInRange(
        plan: _plan(
          totalInstallments: 480,
          firstInstallmentDate: DateTime(2026, 1, 15),
        ),
        start: DateTime(2056),
        end: DateTime(2056, 12, 31, 23, 59, 59),
      );

      expect(items, hasLength(12));
      expect(items.first.installmentNumber, 361);
      expect(items.first.date, DateTime(2056, 1, 15));
      expect(items.last.installmentNumber, 372);
      expect(items.last.date, DateTime(2056, 12, 15));
    });

    test('start just after an installment skips it', () {
      final items = adapter.itemsInRange(
        plan: _plan(),
        start: DateTime(2027, 3, 15, 0, 0, 0, 1),
        end: DateTime(2027, 4, 15),
      );

      expect(items.map((item) => item.installmentNumber), [4]);
    });

    test('returns empty outside plan bounds and for a completed plan', () {
      final plan = _plan();

      expect(
        adapter.itemsInRange(
          plan: plan,
          start: DateTime(2026),
          end: DateTime(2026, 12, 31),
        ),
        isEmpty,
      );
      expect(
        adapter.itemsInRange(
          plan: plan,
          start: DateTime(2028),
          end: DateTime(2028, 12, 31),
        ),
        isEmpty,
      );
      expect(
        adapter.itemsInRange(
          plan: _plan(completedInstallments: 12),
          start: DateTime(2027),
          end: DateTime(2027, 12, 31),
        ),
        isEmpty,
      );
    });

    test('completed progress wins over the temporal candidate', () {
      final items = adapter.itemsInRange(
        plan: _plan(
          totalInstallments: 480,
          completedInstallments: 300,
          firstInstallmentDate: DateTime(2026, 1, 15),
        ),
        start: DateTime(2026),
        end: DateTime(2051, 2, 15),
      );

      expect(items.map((item) => item.installmentNumber), [301, 302]);
      expect(items.map((item) => item.date), [
        DateTime(2051, 1, 15),
        DateTime(2051, 2, 15),
      ]);
    });

    test('single-day, single-month, and annual ranges are inclusive', () {
      final plan = _plan();

      expect(
        adapter
            .itemsInRange(
              plan: plan,
              start: DateTime(2027, 5, 15),
              end: DateTime(2027, 5, 15),
            )
            .single
            .installmentNumber,
        5,
      );
      expect(
        adapter
            .itemsInRange(
              plan: plan,
              start: DateTime(2027, 6),
              end: DateTime(2027, 6, 30),
            )
            .single
            .installmentNumber,
        6,
      );
      expect(
        adapter.itemsInRange(
          plan: plan,
          start: DateTime(2027),
          end: DateTime(2027, 12, 31),
        ),
        hasLength(12),
      );
    });

    test('range-aware items match filtered remaining items', () {
      final cases = <({
        FiniteFinancialPlan plan,
        DateTime start,
        DateTime end,
      })>[
        (
          plan: _plan(
            totalInstallments: 36,
            firstInstallmentDate: DateTime(2027, 1, 28),
            scheduledDayOfMonth: 28,
          ),
          start: DateTime(2027, 2),
          end: DateTime(2028, 3, 31),
        ),
        (
          plan: _plan(
            totalInstallments: 36,
            firstInstallmentDate: DateTime(2027, 1, 29),
            scheduledDayOfMonth: 29,
          ),
          start: DateTime(2027, 2),
          end: DateTime(2028, 3, 31),
        ),
        (
          plan: _plan(
            totalInstallments: 24,
            firstInstallmentDate: DateTime(2027, 1, 30),
            scheduledDayOfMonth: 30,
          ),
          start: DateTime(2027, 2),
          end: DateTime(2028, 2, 29),
        ),
        (
          plan: _plan(
            totalInstallments: 24,
            firstInstallmentDate: DateTime(2027, 1, 31),
            scheduledDayOfMonth: 31,
          ),
          start: DateTime(2027, 2),
          end: DateTime(2028, 2, 29),
        ),
        (
          plan: _plan(
            totalInstallments: 24,
            firstInstallmentDate: DateTime(2027, 12, 15),
          ),
          start: DateTime(2027, 12, 15),
          end: DateTime(2028, 2, 15),
        ),
      ];

      for (final entry in cases) {
        final actual = adapter.itemsInRange(
          plan: entry.plan,
          start: entry.start,
          end: entry.end,
        );
        final expected = adapter
            .remainingItems(entry.plan)
            .where(
              (item) =>
                  !item.date.isBefore(entry.start) &&
                  !item.date.isAfter(entry.end),
            )
            .toList();

        expect(_itemSignatures(actual), _itemSignatures(expected));
      }
    });

    test('rejects an end before start', () {
      expect(
        () => adapter.itemsInRange(
          plan: _plan(),
          start: DateTime(2027, 2),
          end: DateTime(2027, 1, 31),
        ),
        throwsArgumentError,
      );
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
  int totalInstallments = 12,
  DateTime? firstInstallmentDate,
  int scheduledDayOfMonth = 15,
  String? debitBalanceId = 'balance_banca',
  Map<int, double> installmentAmountOverrides = const {},
}) {
  return FiniteFinancialPlan(
    id: 'plan_inps',
    name: 'Rateizzazione INPS',
    description: 'Piano finito',
    subject: FinanceSubject.matteo,
    creditor: 'INPS',
    debitBalanceId: debitBalanceId,
    totalInstallments: totalInstallments,
    expectedInstallmentAmount: 386,
    installmentAmountOverrides: installmentAmountOverrides,
    firstInstallmentDate: firstInstallmentDate ?? DateTime(2027, 1, 15),
    scheduledDayOfMonth: scheduledDayOfMonth,
    completedInstallments: completedInstallments,
  );
}

List<String> _itemSignatures(
  Iterable<FiniteFinancialPlanForecastItem> items,
) => [
  for (final item in items)
    '${item.identity}|${item.planId}|${item.installmentNumber}|'
        '${item.date.toIso8601String()}|${item.expectedAmount}|${item.name}|'
        '${item.description}|${item.subject.name}|${item.debitBalanceId}|'
        '${item.isOutflow}',
];
