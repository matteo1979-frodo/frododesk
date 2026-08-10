import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String home;
  late String overviewCard;
  late String modulesSection;
  late String financeModuleCard;
  late String expensesModuleCard;

  setUpAll(() {
    home = File('lib/screens/home_screen.dart').readAsStringSync();

    overviewCard = _between(
      home,
      'Widget _buildPanoramicaOggiCard',
      'Future<void> _showFinancePresentPopup',
    );
    modulesSection = _between(
      home,
      'Widget _buildModulesSection',
      'class _DashboardCard',
    );
    financeModuleCard = _between(
      modulesSection,
      'icon: Icons.euro_rounded',
      'icon: Icons.receipt_long_rounded',
    );
    expensesModuleCard = _between(
      modulesSection,
      'icon: Icons.receipt_long_rounded',
      'icon: Icons.shield_rounded',
    );
  });

  test('Home renders the finance pressure summary in today overview', () {
    expect('FinancePressureSummaryCard('.allMatches(home), hasLength(1));
    expect(overviewCard, contains('FinancePressureSummaryCard('));
    expect(overviewCard, contains('presentation: financePressurePresentation'));
  });

  test('finance module card preserves balance, margin and status contract', () {
    expect(financeModuleCard, contains('title: "Finanze"'));
    expect(
      financeModuleCard,
      contains('subtitle: financeModulePresentation.subtitle'),
    );
    expect(
      financeModuleCard,
      contains('badge: financeModulePresentation.badgeText'),
    );
  });

  test('finance and expenses cards navigate with the Home finance store', () {
    expect(
      financeModuleCard,
      contains('FinanceScreen(financeStore: financeStore)'),
    );
    expect(
      expensesModuleCard,
      contains('SpesePage(financeStore: financeStore)'),
    );
  });

  test('finance card opens FinanceScreen and not the legacy finance popup', () {
    expect(
      financeModuleCard,
      contains('FinanceScreen(financeStore: financeStore)'),
    );
    expect(financeModuleCard, isNot(contains('_showFinancePopup')));
    expect(financeModuleCard, isNot(contains('showDialog')));
    expect(
      RegExp(r'\b_showFinancePopup\s*\(').allMatches(home),
      hasLength(1),
      reason: 'The only occurrence must remain the unreachable declaration.',
    );
  });
}

String _between(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);

  expect(start, isNonNegative, reason: 'Missing start marker: $startMarker');
  expect(end, greaterThan(start), reason: 'Missing end marker: $endMarker');

  return source.substring(start, end);
}
