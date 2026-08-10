import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_summary_builder.dart';
import 'package:frododesk/models/home_observed_at.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('builds the minimal Home finance snapshot from current store data', () {
    final financeStore = FinanceStore()..loadDemoData();
    final observedAt = HomeObservedAt(observedAt: DateTime(2026, 8, 10, 12));

    final snapshot = const FinanceSummaryBuilder().build(
      financeStore: financeStore,
      observedAt: observedAt,
    );

    expect(snapshot.totalBalance, financeStore.totalBalance());
    expect(
      snapshot.projectedMonthlyMargin,
      financeStore.projectedMonthlyMargin(),
    );
    expect(snapshot.underPressure, financeStore.isUnderPressure());
    expect(
      snapshot.economicPressureScore,
      financeStore.economicPressureScore(observedAt: observedAt.observedAt),
    );
  });

  test('is stateless, deterministic and does not mutate FinanceStore', () {
    final financeStore = FinanceStore()..loadDemoData();
    final observedAt = HomeObservedAt(observedAt: DateTime(2026, 8, 10, 12));
    final balances = List.of(financeStore.balances);
    final funds = List.of(financeStore.funds);
    final recurringItems = List.of(financeStore.recurringItems);

    final first = const FinanceSummaryBuilder().build(
      financeStore: financeStore,
      observedAt: observedAt,
    );
    final second = const FinanceSummaryBuilder().build(
      financeStore: financeStore,
      observedAt: observedAt,
    );

    expect(second.totalBalance, first.totalBalance);
    expect(second.projectedMonthlyMargin, first.projectedMonthlyMargin);
    expect(second.underPressure, first.underPressure);
    expect(second.economicPressureScore, first.economicPressureScore);
    expect(financeStore.balances, orderedEquals(balances));
    expect(financeStore.funds, orderedEquals(funds));
    expect(financeStore.recurringItems, orderedEquals(recurringItems));
  });

  test('builder has no UI, persistence or implicit clock dependency', () {
    final source = File(
      'lib/logic/finance/builders/finance_summary_builder.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('save')));
  });
}
