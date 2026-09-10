import 'package:intl/intl.dart';

/// Formats euro amounts for presentation using the fixed Italian convention.
abstract final class EuroFormatter {
  static final NumberFormat _numberFormat = NumberFormat(
    '#,##0.00',
    'it_IT',
  );

  static String format(num value) => _format(value, showPositiveSign: false);

  static String formatSigned(num value) =>
      _format(value, showPositiveSign: true);

  static String _format(num value, {required bool showPositiveSign}) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite');
    }

    final digits = _numberFormat.format(value.abs());
    if (digits == '0,00') return '€$digits';

    final sign = value.isNegative ? '-' : (showPositiveSign ? '+' : '');
    return '$sign€$digits';
  }
}
