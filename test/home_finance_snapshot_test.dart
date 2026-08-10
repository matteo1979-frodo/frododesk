import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/home_finance_snapshot.dart';

void main() {
  test('HomeFinanceSnapshot contains only the visible Home finance data', () {
    const snapshot = HomeFinanceSnapshot(
      totalBalance: 2393.32,
      projectedMonthlyMargin: 488.50,
      underPressure: false,
      economicPressureScore: 420,
    );

    expect(snapshot.totalBalance, 2393.32);
    expect(snapshot.projectedMonthlyMargin, 488.50);
    expect(snapshot.underPressure, isFalse);
    expect(snapshot.economicPressureScore, 420);

    final source = File(
      'lib/models/home_finance_snapshot.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('FinanceRecurringItem')));
    expect(source, isNot(contains('FinanceFund')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceMonth')));
    expect(source, isNot(contains('FinanceStore')));
    expect(source, isNot(contains('Widget')));
  });

  test('Home requests finance view data with its single observed time', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final buildStart = home.indexOf('Widget build(BuildContext context)');
    final buildEnd = home.indexOf('Widget _buildHeader', buildStart);
    final build = home.substring(buildStart, buildEnd);

    expect(build, contains('HomeFinanceCoordinator('));
    expect(build, contains('financeStore: financeStore'));
    expect(build, contains('build(observedAt: observedAt)'));
    expect(build, isNot(contains('FinanceSummaryBuilder')));
    expect(build, isNot(contains('FinancePressurePresentationBuilder')));
    expect(build, isNot(contains('FinanceModulePresentationBuilder')));
    expect(build, isNot(contains('financeStore.totalBalance()')));
    expect(build, isNot(contains('financeStore.projectedMonthlyMargin()')));
    expect(build, isNot(contains('financeStore.economicPressureScore(')));
  });

  test(
    'visible finance widgets consume snapshot data instead of store reads',
    () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      final pressureCard = File(
        'lib/widgets/finance/finance_pressure_summary_card.dart',
      ).readAsStringSync();
      final overviewStart = home.indexOf('Widget _buildPanoramicaOggiCard');
      final overviewEnd = home.indexOf(
        'Future<void> _showFinancePresentPopup',
        overviewStart,
      );
      final overview = home.substring(overviewStart, overviewEnd);
      final modulesStart = home.indexOf('Widget _buildModulesSection');
      final modulesEnd = home.indexOf('class _DashboardCard', modulesStart);
      final modules = home.substring(modulesStart, modulesEnd);

      expect(overview, contains('financePressurePresentation'));
      expect(modules, contains('financeModulePresentation.subtitle'));
      expect(modules, contains('financeModulePresentation.badgeText'));
      expect(modules, isNot(contains('financeSnapshot.')));
      expect(overview, isNot(contains('financeStore.')));
      expect(pressureCard, isNot(contains('FinanceStore')));
      expect(pressureCard, isNot(contains('economicPressureScore')));
    },
  );
}
