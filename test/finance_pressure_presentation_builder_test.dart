import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_pressure_presentation_builder.dart';
import 'package:frododesk/models/finance_pressure_presentation.dart';

void main() {
  const builder = FinancePressurePresentationBuilder();

  test('maps low pressure including the lower boundary', () {
    for (final presentation in [builder.build(0), builder.build(499.99)]) {
      expect(presentation.title, 'Pressione economica bassa');
      expect(presentation.description, 'Situazione stabile e sostenibile.');
      expect(presentation.state, FinancePressureState.low);
      expect(presentation.color, 0xFF66BB6A);
    }
  });

  test('maps medium pressure at 500 and below 1500', () {
    for (final presentation in [builder.build(500), builder.build(1499.99)]) {
      expect(presentation.title, 'Pressione economica media');
      expect(presentation.description, 'Le uscite iniziano a pesare.');
      expect(presentation.state, FinancePressureState.medium);
      expect(presentation.color, 0xFFFFB300);
    }
  });

  test('maps high pressure at 1500 and below 3000', () {
    for (final presentation in [builder.build(1500), builder.build(2999.99)]) {
      expect(presentation.title, 'Pressione economica alta');
      expect(
        presentation.description,
        'Serve attenzione sulle prossime spese.',
      );
      expect(presentation.state, FinancePressureState.high);
      expect(presentation.color, 0xFFE57373);
    }
  });

  test('maps critical pressure from 3000', () {
    final presentation = builder.build(3000);

    expect(presentation.title, 'Pressione economica critica');
    expect(
      presentation.description,
      'La situazione economica è sotto forte pressione.',
    );
    expect(presentation.state, FinancePressureState.critical);
    expect(presentation.color, 0xFFD32F2F);
  });

  test('builder and presentation are pure and UI-independent', () {
    final builderSource = File(
      'lib/logic/finance/builders/finance_pressure_presentation_builder.dart',
    ).readAsStringSync();
    final presentationSource = File(
      'lib/models/finance_pressure_presentation.dart',
    ).readAsStringSync();
    final source = '$builderSource\n$presentationSource';

    expect(source, isNot(contains('FinanceStore')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
  });
}
