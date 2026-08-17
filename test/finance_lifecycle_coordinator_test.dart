import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coordinator only constructs and orchestrates the lifecycle loader', () {
    final coordinator = File(
      'lib/logic/finance/finance_lifecycle_coordinator.dart',
    ).readAsStringSync();

    expect(coordinator, contains('FinanceLifecycleLoader('));
    expect(coordinator, contains('Future<void> initialize()'));
    expect(
      RegExp(r'_loader\.load\s*\(\s*\)').allMatches(coordinator),
      hasLength(1),
    );
    expect(coordinator, isNot(contains('loadInitialRealData')));
    expect(coordinator, isNot(contains('saveBalances')));
    expect(coordinator, isNot(contains('saveFunds')));
    expect(coordinator, isNot(contains('saveRecurringItems')));
    expect(coordinator, isNot(contains('saveSnapshot')));
    expect(coordinator, isNot(contains('DateTime.now')));
    expect(coordinator, isNot(contains('debugPrint')));
    expect(coordinator, isNot(contains('setState')));
  });

  test('Home creates the coordinator and requests one initialization', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final methodStart = home.indexOf('Future<void> _loadFinanceData()');
    final methodEnd = home.indexOf(
      'Future<void> _showDataTransferDialog()',
      methodStart,
    );

    expect(methodStart, isNonNegative);
    expect(methodEnd, greaterThan(methodStart));
    final method = home.substring(methodStart, methodEnd);

    expect(
      RegExp(r'FinanceLifecycleCoordinator\s*\(').allMatches(method),
      hasLength(1),
    );
    expect(method, contains('financeStore: financeStore'));
    expect(method, contains('if (mounted)'));
    expect(method, contains('setState(() {})'));
    expect(RegExp(r'\.initialize\s*\(\s*\)').allMatches(method), hasLength(1));
    expect(method, isNot(contains('FinanceLifecycleLoader')));
    expect(method, isNot(contains('loadInitialRealData')));
    expect(method, isNot(contains('saveBalances')));
    expect(method, isNot(contains('saveFunds')));
    expect(method, isNot(contains('saveRecurringItems')));
    expect(method, isNot(contains('saveSnapshot')));
  });
}
