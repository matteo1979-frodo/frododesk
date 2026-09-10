import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/utils/euro_formatter.dart';

void main() {
  group('EuroFormatter.format', () {
    test('uses fixed Italian euro presentation', () {
      expect(EuroFormatter.format(0), '€0,00');
      expect(EuroFormatter.format(0.0), '€0,00');
      expect(EuroFormatter.format(0.01), '€0,01');
      expect(EuroFormatter.format(8), '€8,00');
      expect(EuroFormatter.format(60.5), '€60,50');
      expect(EuroFormatter.format(60.56), '€60,56');
      expect(EuroFormatter.format(1234.56), '€1.234,56');
      expect(EuroFormatter.format(1000000), '€1.000.000,00');
      expect(EuroFormatter.format(-60), '-€60,00');
    });

    test('rounds only the final visual representation', () {
      expect(EuroFormatter.format(1.234), '€1,23');
      expect(EuroFormatter.format(1.235), '€1,24');
      expect(EuroFormatter.format(-1.234), '-€1,23');
      expect(EuroFormatter.format(-1.235), '-€1,24');
    });

    test('normalizes values rendered as visual zero', () {
      expect(EuroFormatter.format(-0.0), '€0,00');
      expect(EuroFormatter.format(-0.004), '€0,00');
      expect(EuroFormatter.format(0.004), '€0,00');
    });
  });

  group('EuroFormatter.formatSigned', () {
    test('adds a sign only to visually non-zero values', () {
      expect(EuroFormatter.formatSigned(0), '€0,00');
      expect(EuroFormatter.formatSigned(-0.0), '€0,00');
      expect(EuroFormatter.formatSigned(-0.004), '€0,00');
      expect(EuroFormatter.formatSigned(0.004), '€0,00');
      expect(EuroFormatter.formatSigned(60), '+€60,00');
      expect(EuroFormatter.formatSigned(-60), '-€60,00');
      expect(EuroFormatter.formatSigned(1495), '+€1.495,00');
    });

    test('never introduces spaces or duplicate signs', () {
      for (final value in <num>[-60, 0, 60]) {
        final formatted = EuroFormatter.formatSigned(value);
        expect(formatted, isNot(contains(' ')));
        expect(formatted, isNot(startsWith('++')));
        expect(formatted, isNot(startsWith('--')));
      }
    });
  });

  test('rejects non-finite values explicitly', () {
    for (final value in <double>[
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        () => EuroFormatter.format(value),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EuroFormatter.formatSigned(value),
        throwsA(isA<ArgumentError>()),
      );
    }
  });

  test('is deterministic across repeated calls', () {
    final results = List<String>.generate(
      100,
      (_) => EuroFormatter.formatSigned(1234.56),
    );

    expect(results.toSet(), {'+€1.234,56'});
  });

  test('has no forbidden architectural dependencies', () {
    final source = File('lib/utils/euro_formatter.dart').readAsStringSync();

    for (final forbidden in <String>[
      'package:flutter/',
      '/stores/',
      '/persistence/',
      '/models/',
      '/coordinators/',
      '/widgets/',
      'finance_',
      'spese_',
      'ledger_',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}
