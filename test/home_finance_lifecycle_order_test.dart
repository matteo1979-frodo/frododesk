import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String loader;

  setUpAll(() {
    loader = File(
      'lib/logic/finance/finance_lifecycle_loader.dart',
    ).readAsStringSync();
  });

  test('finance initialization preserves the current operation order', () {
    final operations = <RegExp>[
      RegExp(r'await\s+financeStore\.loadInitialRealData\s*\(\s*\)\s*;'),
      RegExp(r'await\s+financeStore\.saveBalances\s*\(\s*\)\s*;'),
      RegExp(r'await\s+financeStore\.saveFunds\s*\(\s*\)\s*;'),
      RegExp(r'await\s+financeStore\.saveRecurringItems\s*\(\s*\)\s*;'),
      RegExp(r'financeStore\.saveSnapshot\s*\([^;]+\)\s*;'),
      RegExp(r'refresh\s*\(\s*\)\s*;'),
    ];

    final positions = operations.map((operation) {
      final matches = operation.allMatches(loader).toList();
      expect(
        matches,
        hasLength(1),
        reason: 'Each lifecycle operation must occur exactly once.',
      );
      return matches.single.start;
    }).toList();

    expect(positions, orderedEquals([...positions]..sort()));
  });

  test('Home refresh occurs only after the persisted finance sequence', () {
    final snapshot = loader.indexOf('financeStore.saveSnapshot(');
    final refresh = loader.indexOf('refresh();');

    expect(snapshot, isNonNegative);
    expect(refresh, greaterThan(snapshot));
  });
}
