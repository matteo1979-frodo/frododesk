import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  group('ExpenseRelationship', () {
    test('builds a valid active monthly relationship', () {
      final relationship = _relationship();

      expect(relationship.relationshipId, 'utility_water_1');
      expect(relationship.service, 'Acqua');
      expect(relationship.provider, 'Fornitore acqua');
      expect(relationship.subject, FinanceSubject.matteo);
      expect(relationship.status, ExpenseRelationshipStatus.active);
      expect(
        relationship.periodicity.type,
        FinanceRecurringType.monthly,
      );
    });

    test('preserves service and provider through JSON round-trip', () {
      final source = _relationship(
        service: '  Acqua  ',
        provider: '  Fornitore acqua  ',
      );

      final restored = ExpenseRelationship.fromJson(source.toJson());

      expect(restored.service, 'Acqua');
      expect(restored.provider, 'Fornitore acqua');
      expect(restored.toJson(), source.toJson());
    });

    test('legacy JSON defaults to the stable name only policy', () {
      final json = _relationship().toJson()..remove('cycleLabelPolicy');

      final restored = ExpenseRelationship.fromJson(json);

      expect(
        restored.cycleLabelPolicy,
        ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
      );
    });

    test('round-trips and copies the annual target-year label policy', () {
      final source = _relationship(
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.yearly,
        ),
        cycleLabelPolicy:
            ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
      );

      final restored = ExpenseRelationship.fromJson(source.toJson());
      final renamed = restored.copyWith(service: 'Tributo comunale');

      expect(restored.toJson(), source.toJson());
      expect(renamed.service, 'Tributo comunale');
      expect(
        renamed.cycleLabelPolicy,
        ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
      );
    });

    test('target-year labels require an annual-compatible cadence', () {
      expect(
        () => _relationship(
          cycleLabelPolicy:
              ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
        ),
        throwsArgumentError,
      );
      expect(
        ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 12,
          customIntervalUnit: 'months',
        ).isAnnualCycle,
        isTrue,
      );
    });

    test('supports manual payment without an expected balance', () {
      final relationship = _relationship(
        payment: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.manual,
        ),
      );

      expect(
        relationship.paymentConfiguration.method,
        FinancePaymentMethod.manual,
      );
      expect(relationship.paymentConfiguration.expectedBalanceId, isNull);
    });

    test('supports RID with an expected balance', () {
      final relationship = _relationship(
        payment: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: 'balance_matteo',
        ),
      );

      expect(relationship.paymentConfiguration.method, FinancePaymentMethod.rid);
      expect(
        relationship.paymentConfiguration.expectedBalanceId,
        'balance_matteo',
      );
    });

    test('preserves the pertinent subject', () {
      final restored = ExpenseRelationship.fromJson(
        _relationship(subject: FinanceSubject.chiara).toJson(),
      );

      expect(restored.subject, FinanceSubject.chiara);
    });

    test('supports active and terminated states', () {
      expect(_relationship().status, ExpenseRelationshipStatus.active);
      expect(
        _relationship(status: ExpenseRelationshipStatus.terminated).status,
        ExpenseRelationshipStatus.terminated,
      );
    });

    test('supports monthly and custom two-month periodicity', () {
      final monthly = _relationship();
      final bimonthly = _relationship(
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 2,
          customIntervalUnit: 'months',
        ),
      );

      expect(monthly.periodicity.type, FinanceRecurringType.monthly);
      expect(bimonthly.periodicity.type, FinanceRecurringType.custom);
      expect(bimonthly.periodicity.customInterval, 2);
      expect(bimonthly.periodicity.customIntervalUnit, 'months');
    });

    test('round-trips the complete contract with stable JSON names', () {
      final source = _relationship(
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 2,
        ),
        payment: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: 'balance_matteo',
        ),
      );

      final json = source.toJson();
      final restored = ExpenseRelationship.fromJson(json);

      expect(restored.toJson(), json);
      expect(json['relationshipId'], 'utility_water_1');
      expect(json['subject'], 'matteo');
      expect(json['status'], 'active');
      expect(json['periodicity'], {
        'type': 'custom',
        'customInterval': 2,
        'customIntervalUnit': 'months',
      });
      expect(json['paymentConfiguration'], {
        'method': 'rid',
        'expectedBalanceId': 'balance_matteo',
      });
    });

    test('round-trips an optional manual payment preference', () {
      final source = _relationship(
        manualPaymentPreference: ManualPaymentPreference(
          preferredStartDayOfMonth: 5,
        ),
      );

      final restored = ExpenseRelationship.fromJson(source.toJson());

      expect(restored.toJson(), source.toJson());
      expect(restored.manualPaymentPreference?.preferredStartDayOfMonth, 5);
    });

    test('round-trips without a manual payment preference', () {
      final source = _relationship();

      final restored = ExpenseRelationship.fromJson(source.toJson());

      expect(restored.manualPaymentPreference, isNull);
      expect(restored.toJson(), source.toJson());
    });

    test('loads legacy JSON without the preference field', () {
      final json = _relationship().toJson()..remove('manualPaymentPreference');

      final restored = ExpenseRelationship.fromJson(json);

      expect(restored.manualPaymentPreference, isNull);
    });

    test('rejects malformed manual payment preference JSON', () {
      final json = {
        ..._relationship().toJson(),
        'manualPaymentPreference': 'day 5',
      };

      expect(() => ExpenseRelationship.fromJson(json), throwsFormatException);
    });

    test('JSON equivalence includes the manual payment preference', () {
      final first = _relationship(
        manualPaymentPreference: ManualPaymentPreference(
          preferredStartDayOfMonth: 5,
        ),
      );
      final same = ExpenseRelationship.fromJson(first.toJson());
      final different = first.copyWith(
        manualPaymentPreference: ManualPaymentPreference(
          preferredStartDayOfMonth: 10,
        ),
      );

      expect(jsonEncode(same.toJson()), jsonEncode(first.toJson()));
      expect(jsonEncode(different.toJson()), isNot(jsonEncode(first.toJson())));
    });

    test('keeps backward-compatible defaults for additive fields', () {
      final json = _relationship().toJson()
        ..remove('status');
      final payment = Map<String, dynamic>.from(
        json['paymentConfiguration'] as Map,
      )..remove('method');
      json['paymentConfiguration'] = payment;

      final restored = ExpenseRelationship.fromJson(json);

      expect(restored.status, ExpenseRelationshipStatus.active);
      expect(
        restored.paymentConfiguration.method,
        FinancePaymentMethod.manual,
      );
    });

    test('rejects invalid identity, service, provider and balance references', () {
      expect(() => _relationship(relationshipId: '  '), throwsArgumentError);
      expect(() => _relationship(service: ''), throwsArgumentError);
      expect(() => _relationship(provider: ' '), throwsArgumentError);
      expect(
        () => ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid continuing periodicities', () {
      expect(
        () => ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.oneShot,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 2,
          customIntervalUnit: 'weeks',
        ),
        throwsArgumentError,
      );
    });

    test('rejects malformed and unknown JSON values', () {
      final valid = _relationship().toJson();
      for (final invalid in <Map<String, dynamic>>[
        {...valid}..remove('relationshipId'),
        {...valid, 'subject': 'unknown'},
        {...valid, 'status': 'paused'},
        {...valid, 'periodicity': 'monthly'},
        {...valid, 'paymentConfiguration': []},
      ]) {
        expect(
          () => ExpenseRelationship.fromJson(invalid),
          throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        );
      }
    });

    test('identity does not depend on provider, account or payment method', () {
      final original = _relationship();
      final changed = original.copyWith(
        provider: 'Nuovo fornitore',
        paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: 'new_balance',
        ),
      );

      expect(changed.relationshipId, original.relationshipId);
      expect(changed.service, original.service);
      expect(changed.provider, 'Nuovo fornitore');
      expect(changed.paymentConfiguration.method, FinancePaymentMethod.rid);
      expect(
        changed.paymentConfiguration.expectedBalanceId,
        'new_balance',
      );
    });
  });
}

ExpenseRelationship _relationship({
  String relationshipId = 'utility_water_1',
  String service = 'Acqua',
  String provider = 'Fornitore acqua',
  FinanceSubject subject = FinanceSubject.matteo,
  ExpenseRelationshipStatus status = ExpenseRelationshipStatus.active,
  ExpenseRelationshipPeriodicity? periodicity,
  ExpenseRelationshipCycleLabelPolicy cycleLabelPolicy =
      ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
  ExpenseRelationshipPaymentConfiguration? payment,
  ManualPaymentPreference? manualPaymentPreference,
}) => ExpenseRelationship(
  relationshipId: relationshipId,
  service: service,
  provider: provider,
  subject: subject,
  status: status,
  periodicity:
      periodicity ??
      ExpenseRelationshipPeriodicity(type: FinanceRecurringType.monthly),
  cycleLabelPolicy: cycleLabelPolicy,
  paymentConfiguration:
      payment ??
      ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
  manualPaymentPreference: manualPaymentPreference,
);
