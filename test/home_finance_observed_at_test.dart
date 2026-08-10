import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Home passes its observed time to the visible finance pressure path',
    () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      final pressureCard = File(
        'lib/widgets/finance/finance_pressure_summary_card.dart',
      ).readAsStringSync();

      expect(home, contains('HomeFinanceCoordinator('));
      expect(home, contains('build(observedAt: observedAt)'));
      expect(pressureCard, isNot(contains('DateTime.now')));
    },
  );

  test('finance pressure score reads only the supplied observed time', () {
    final store = File('lib/stores/finance_store.dart').readAsStringSync();
    final methodStart = store.indexOf('double economicPressureScore');
    final methodEnd = store.indexOf(
      'List<FinanceRecurringItem> itemsForProjectionMonth',
      methodStart,
    );
    final method = store.substring(methodStart, methodEnd);

    expect(
      method,
      contains('economicPressureScore({required DateTime observedAt})'),
    );
    expect(method, contains('dueDate.difference(observedAt).inDays'));
    expect(method, isNot(contains('DateTime.now')));
  });
}
