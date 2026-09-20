import 'finance_category_template.dart';
import 'finance_recurring_item.dart';
import 'manual_payment_preference.dart';

const _preserveManualPaymentPreference = Object();

enum ExpenseRelationshipStatus { active, terminated }

enum PaymentExecutionMode {
  unknown,
  requiresUserAction,
  automatic,
  scheduled,
}

/// The current payment configuration of a continuing expense relationship.
///
/// This is neither a payment nor a bank mandate. It only identifies the
/// method and, when known, the balance expected to fund future payments.
class ExpenseRelationshipPaymentConfiguration {
  final FinancePaymentMethod method;
  final String? expectedBalanceId;

  ExpenseRelationshipPaymentConfiguration({
    required this.method,
    String? expectedBalanceId,
  }) : expectedBalanceId = _optionalText(
         expectedBalanceId,
         'expectedBalanceId',
       );

  Map<String, dynamic> toJson() => {
    'method': method.name,
    'expectedBalanceId': expectedBalanceId,
  };

  factory ExpenseRelationshipPaymentConfiguration.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawMethod = json['method'] ?? FinancePaymentMethod.manual.name;
    if (rawMethod is! String) {
      throw const FormatException('method must be a string');
    }
    final method = FinancePaymentMethod.values
        .where((value) => value.name == rawMethod)
        .firstOrNull;
    if (method == null) {
      throw FormatException('Unknown payment method: $rawMethod');
    }
    final balanceId = json['expectedBalanceId'];
    if (balanceId != null && balanceId is! String) {
      throw const FormatException('expectedBalanceId must be a string or null');
    }
    return ExpenseRelationshipPaymentConfiguration(
      method: method,
      expectedBalanceId: balanceId as String?,
    );
  }
}

/// The cadence configured for a continuing expense relationship.
///
/// It reuses Finance recurring concepts but intentionally does not calculate
/// occurrences or dates. A bimonthly cadence is `custom`, interval 2, months.
class ExpenseRelationshipPeriodicity {
  final FinanceRecurringType type;
  final int? customInterval;
  final String? customIntervalUnit;

  ExpenseRelationshipPeriodicity({
    required this.type,
    int? customInterval,
    String? customIntervalUnit,
  }) : customInterval = type == FinanceRecurringType.custom
           ? customInterval ?? 1
           : null,
       customIntervalUnit = type == FinanceRecurringType.custom
           ? _requiredText(
               customIntervalUnit ?? 'months',
               'customIntervalUnit',
             )
           : null {
    if (type == FinanceRecurringType.oneShot) {
      throw ArgumentError.value(
        type,
        'type',
        'A continuing relationship cannot be one-shot',
      );
    }
    if (this.customInterval != null && this.customInterval! <= 0) {
      throw ArgumentError.value(
        this.customInterval,
        'customInterval',
        'Must be greater than zero',
      );
    }
    if (this.customIntervalUnit != null &&
        !const {'days', 'months', 'years'}.contains(this.customIntervalUnit)) {
      throw ArgumentError.value(
        this.customIntervalUnit,
        'customIntervalUnit',
        'Must be days, months or years',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'customInterval': customInterval,
    'customIntervalUnit': customIntervalUnit,
  };

  factory ExpenseRelationshipPeriodicity.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawType = json['type'];
    if (rawType is! String) {
      throw const FormatException('type must be a string');
    }
    final type = FinanceRecurringType.values
        .where((value) => value.name == rawType)
        .firstOrNull;
    if (type == null) {
      throw FormatException('Unknown recurring type: $rawType');
    }
    final interval = json['customInterval'];
    if (interval != null && interval is! int) {
      throw const FormatException('customInterval must be an integer or null');
    }
    final unit = json['customIntervalUnit'];
    if (unit != null && unit is! String) {
      throw const FormatException(
        'customIntervalUnit must be a string or null',
      );
    }
    return ExpenseRelationshipPeriodicity(
      type: type,
      customInterval: interval as int?,
      customIntervalUnit: unit as String?,
    );
  }
}

/// Stable identity of a continuing relationship that can generate expenses.
///
/// [service] and [provider] are explicit domain data, never identity or
/// name-matching keys. Bills, forecasts and economic facts are deliberately
/// outside this contract.
class ExpenseRelationship {
  final String relationshipId;
  final String service;
  final String provider;
  final FinanceSubject subject;
  final ExpenseRelationshipStatus status;
  final ExpenseRelationshipPeriodicity periodicity;
  final ExpenseRelationshipPaymentConfiguration paymentConfiguration;
  final PaymentExecutionMode paymentExecutionMode;
  final ManualPaymentPreference? manualPaymentPreference;

  ExpenseRelationship({
    required String relationshipId,
    required String service,
    required String provider,
    required this.subject,
    required this.status,
    required this.periodicity,
    required this.paymentConfiguration,
    this.paymentExecutionMode = PaymentExecutionMode.unknown,
    this.manualPaymentPreference,
  }) : relationshipId = _requiredText(relationshipId, 'relationshipId'),
       service = _requiredText(service, 'service'),
       provider = _requiredText(provider, 'provider');

  ExpenseRelationship copyWith({
    String? provider,
    FinanceSubject? subject,
    ExpenseRelationshipStatus? status,
    ExpenseRelationshipPeriodicity? periodicity,
    ExpenseRelationshipPaymentConfiguration? paymentConfiguration,
    PaymentExecutionMode? paymentExecutionMode,
    Object? manualPaymentPreference = _preserveManualPaymentPreference,
  }) => ExpenseRelationship(
    relationshipId: relationshipId,
    service: service,
    provider: provider ?? this.provider,
    subject: subject ?? this.subject,
    status: status ?? this.status,
    periodicity: periodicity ?? this.periodicity,
    paymentConfiguration: paymentConfiguration ?? this.paymentConfiguration,
    paymentExecutionMode: paymentExecutionMode ?? this.paymentExecutionMode,
    manualPaymentPreference:
        identical(manualPaymentPreference, _preserveManualPaymentPreference)
        ? this.manualPaymentPreference
        : manualPaymentPreference as ManualPaymentPreference?,
  );

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'service': service,
    'provider': provider,
    'subject': subject.name,
    'status': status.name,
    'periodicity': periodicity.toJson(),
    'paymentConfiguration': paymentConfiguration.toJson(),
    'paymentExecutionMode': paymentExecutionMode.name,
    'manualPaymentPreference': manualPaymentPreference?.toJson(),
  };

  factory ExpenseRelationship.fromJson(Map<String, dynamic> json) {
    final subject = _enumValue(
      json,
      'subject',
      FinanceSubject.values,
      (value) => value.name,
    );
    final statusRaw = json['status'] ?? ExpenseRelationshipStatus.active.name;
    if (statusRaw is! String) {
      throw const FormatException('status must be a string');
    }
    final status = ExpenseRelationshipStatus.values
        .where((value) => value.name == statusRaw)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Unknown relationship status: $statusRaw');
    }
    final periodicity = json['periodicity'];
    final payment = json['paymentConfiguration'];
    final manualPaymentPreference = json['manualPaymentPreference'];
    if (periodicity is! Map) {
      throw const FormatException('periodicity must be an object');
    }
    if (payment is! Map) {
      throw const FormatException('paymentConfiguration must be an object');
    }
    if (manualPaymentPreference != null && manualPaymentPreference is! Map) {
      throw const FormatException(
        'manualPaymentPreference must be an object or null',
      );
    }
    return ExpenseRelationship(
      relationshipId: _jsonString(json, 'relationshipId'),
      service: _jsonString(json, 'service'),
      provider: _jsonString(json, 'provider'),
      subject: subject,
      status: status,
      periodicity: ExpenseRelationshipPeriodicity.fromJson(
        Map<String, dynamic>.from(periodicity),
      ),
      paymentConfiguration:
          ExpenseRelationshipPaymentConfiguration.fromJson(
            Map<String, dynamic>.from(payment),
          ),
      paymentExecutionMode: _optionalEnumValue(
        json,
        'paymentExecutionMode',
        PaymentExecutionMode.values,
        (value) => value.name,
        PaymentExecutionMode.unknown,
      ),
      manualPaymentPreference: manualPaymentPreference == null
          ? null
          : ManualPaymentPreference.fromJson(
              Map<String, dynamic>.from(manualPaymentPreference),
            ),
    );
  }
}

T _optionalEnumValue<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) nameOf,
  T legacyValue,
) {
  final raw = json[key];
  if (raw == null) return legacyValue;
  if (raw is! String) throw FormatException('$key must be a string');
  for (final value in values) {
    if (nameOf(value) == raw) return value;
  }
  throw FormatException('Unknown $key: $raw');
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty');
  }
  return normalized;
}

String? _optionalText(String? value, String field) {
  if (value == null) return null;
  return _requiredText(value, field);
}

String _jsonString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

T _enumValue<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) nameOf,
) {
  final raw = json[key];
  if (raw is! String) throw FormatException('$key must be a string');
  for (final value in values) {
    if (nameOf(value) == raw) return value;
  }
  throw FormatException('Unknown $key: $raw');
}
