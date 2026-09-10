import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_module_presentation_builder.dart';
import 'package:frododesk/models/finance_module_presentation.dart';
import 'package:frododesk/models/home_finance_snapshot.dart';

void main() {
  const builder = FinanceModulePresentationBuilder();

  test('builds the stable module presentation with Italian euro formatting', () {
    final presentation = builder.build(
      const HomeFinanceSnapshot(
        totalBalance: 2393.32,
        projectedMonthlyMargin: 488.50,
        underPressure: false,
        economicPressureScore: 420,
      ),
    );

    expect(
      presentation.subtitle,
      'Saldo €2.393,32 • Margine €488,50',
    );
    expect(presentation.badgeText, 'Stabile');
    expect(presentation.state, FinanceModuleState.stable);
  });

  test(
    'builds the pressure module presentation without changing layout text',
    () {
      final presentation = builder.build(
        const HomeFinanceSnapshot(
          totalBalance: 1200.60,
          projectedMonthlyMargin: -125.40,
          underPressure: true,
          economicPressureScore: 1800,
        ),
      );

      expect(
        presentation.subtitle,
        'Saldo €1.200,60 • Margine -€125,40',
      );
      expect(presentation.badgeText, 'Pressione');
      expect(presentation.state, FinanceModuleState.pressure);
    },
  );

  test('preserves a negative balance and neutral visual zero', () {
    final negative = builder.build(
      const HomeFinanceSnapshot(
        totalBalance: -1234.56,
        projectedMonthlyMargin: 60,
        underPressure: false,
        economicPressureScore: 0,
      ),
    );
    final zero = builder.build(
      const HomeFinanceSnapshot(
        totalBalance: -0.0,
        projectedMonthlyMargin: -0.004,
        underPressure: false,
        economicPressureScore: 0,
      ),
    );

    expect(
      negative.subtitle,
      'Saldo -€1.234,56 • Margine €60,00',
    );
    expect(zero.subtitle, 'Saldo €0,00 • Margine €0,00');
  });

  test('uses only Home finance snapshot data and remains pure', () {
    final builderSource = File(
      'lib/logic/finance/builders/finance_module_presentation_builder.dart',
    ).readAsStringSync();
    final presentationSource = File(
      'lib/models/finance_module_presentation.dart',
    ).readAsStringSync();
    final source = '$builderSource\n$presentationSource';

    expect(builderSource, contains('build(HomeFinanceSnapshot snapshot)'));
    expect(source, isNot(contains('FinanceStore')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('save')));
  });
}
