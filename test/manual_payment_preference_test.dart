import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  group('ManualPaymentPreference', () {
    for (final day in [1, 5, 31]) {
      test('accepts preferred day $day', () {
        final preference = ManualPaymentPreference(
          preferredStartDayOfMonth: day,
        );

        expect(preference.preferredStartDayOfMonth, day);
      });
    }

    for (final day in [0, 32]) {
      test('rejects preferred day $day', () {
        expect(
          () => ManualPaymentPreference(preferredStartDayOfMonth: day),
          throwsArgumentError,
        );
      });
    }

    test('uses explicit due-date anchors', () {
      final preference = ManualPaymentPreference(preferredStartDayOfMonth: 5);

      expect(
        preference.startAnchor,
        ManualPaymentPreferenceStartAnchor.expectedDueDateMonth,
      );
      expect(
        preference.endAnchor,
        ManualPaymentPreferenceEndAnchor.expectedDueDate,
      );
    });

    test('round-trips every field through JSON', () {
      final source = ManualPaymentPreference(preferredStartDayOfMonth: 31);

      final restored = ManualPaymentPreference.fromJson(source.toJson());

      expect(restored.toJson(), source.toJson());
    });

    test('rejects malformed and unknown JSON values', () {
      for (final json in <Map<String, dynamic>>[
        {
          'preferredStartDayOfMonth': '5',
          'startAnchor': 'expectedDueDateMonth',
          'endAnchor': 'expectedDueDate',
        },
        {
          'preferredStartDayOfMonth': 5,
          'startAnchor': 'issueDateMonth',
          'endAnchor': 'expectedDueDate',
        },
        {
          'preferredStartDayOfMonth': 5,
          'startAnchor': 'expectedDueDateMonth',
          'endAnchor': 'fixedDate',
        },
      ]) {
        expect(
          () => ManualPaymentPreference.fromJson(json),
          throwsFormatException,
        );
      }
    });
  });
}
