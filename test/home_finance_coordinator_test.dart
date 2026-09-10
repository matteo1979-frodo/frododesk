import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/home_finance_coordinator.dart';
import 'package:frododesk/models/finance_module_presentation.dart';
import 'package:frododesk/models/finance_pressure_presentation.dart';
import 'package:frododesk/models/home_observed_at.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('orchestrates the three builders into Home finance view data', () {
    final financeStore = FinanceStore()..loadDemoData();
    final observedAt = HomeObservedAt(observedAt: DateTime(2026, 8, 10, 12));

    final viewData = HomeFinanceCoordinator(
      financeStore: financeStore,
    ).build(observedAt: observedAt);

    expect(
      viewData.modulePresentation.subtitle,
      'Saldo €3.750,00 • Margine €3.882,00',
    );
    expect(viewData.modulePresentation.badgeText, 'Stabile');
    expect(viewData.modulePresentation.state, FinanceModuleState.stable);
    expect(viewData.pressurePresentation.state, isA<FinancePressureState>());
    expect(viewData.pressurePresentation.title, isNotEmpty);
    expect(viewData.pressurePresentation.description, isNotEmpty);
  });

  test('is deterministic and does not mutate FinanceStore', () {
    final financeStore = FinanceStore()..loadDemoData();
    final observedAt = HomeObservedAt(observedAt: DateTime(2026, 8, 10, 12));
    final balances = List.of(financeStore.balances);
    final funds = List.of(financeStore.funds);
    final recurringItems = List.of(financeStore.recurringItems);
    final coordinator = HomeFinanceCoordinator(financeStore: financeStore);

    final first = coordinator.build(observedAt: observedAt);
    final second = coordinator.build(observedAt: observedAt);

    expect(
      second.modulePresentation.subtitle,
      first.modulePresentation.subtitle,
    );
    expect(second.pressurePresentation.state, first.pressurePresentation.state);
    expect(financeStore.balances, orderedEquals(balances));
    expect(financeStore.funds, orderedEquals(funds));
    expect(financeStore.recurringItems, orderedEquals(recurringItems));
  });

  test('contains orchestration only and no business or UI decisions', () {
    final coordinator = File(
      'lib/logic/finance/home_finance_coordinator.dart',
    ).readAsStringSync();
    final viewData = File(
      'lib/models/home_finance_view_data.dart',
    ).readAsStringSync();
    final source = '$coordinator\n$viewData';

    expect(coordinator, contains('summaryBuilder.build('));
    expect(coordinator, contains('pressurePresentationBuilder.build('));
    expect(coordinator, contains('modulePresentationBuilder.build('));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('toStringAsFixed')));
    expect(source, isNot(contains('economicPressureScore <')));
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('save')));
  });
}
