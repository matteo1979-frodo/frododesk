import 'finance_category_template.dart';
import 'finance_recurring_item.dart';
import 'manual_payment_preference.dart';

const _preserveManualPaymentPreference = Object();

class ExpenseRelationshipIdentifier {
  final String namespace;
  final String value;
  final String? provenance;

  ExpenseRelationshipIdentifier({
    required String namespace,
    required String value,
    String? provenance,
  }) : namespace = _requiredText(namespace, 'namespace'),
       value = _requiredText(value, 'value'),
       provenance = _optionalText(provenance, 'provenance');

  String get identity => '$namespace:$value';

  Map<String, dynamic> toJson() => {
    'namespace': namespace,
    'value': value,
    'provenance': provenance,
  };

  factory ExpenseRelationshipIdentifier.fromJson(Map<String, dynamic> json) =>
      ExpenseRelationshipIdentifier(
        namespace: _jsonString(json, 'namespace'),
        value: _jsonString(json, 'value'),
        provenance: json['provenance'] as String?,
      );
}

class ExpenseRelationshipCommercialTerm {
  final DateTime? effectiveFrom;
  final DateTime? commercialEnd;

  const ExpenseRelationshipCommercialTerm({
    this.effectiveFrom,
    this.commercialEnd,
  });

  Map<String, dynamic> toJson() => {
    'effectiveFrom': effectiveFrom?.toIso8601String(),
    'commercialEnd': commercialEnd?.toIso8601String(),
  };

  factory ExpenseRelationshipCommercialTerm.fromJson(
    Map<String, dynamic> json,
  ) => ExpenseRelationshipCommercialTerm(
    effectiveFrom: _optionalDate(json, 'effectiveFrom'),
    commercialEnd: _optionalDate(json, 'commercialEnd'),
  );
}

enum ExpenseRelationshipStatus { active, terminated }

enum ExpenseRelationshipCycleLabelPolicy {
  stableNameOnly,
  stableNameWithTargetYear,
}

enum PaymentExecutionMode { unknown, requiresUserAction, automatic, scheduled }

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
           ? _requiredText(customIntervalUnit ?? 'months', 'customIntervalUnit')
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

  factory ExpenseRelationshipPeriodicity.fromJson(Map<String, dynamic> json) {
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

  bool get isAnnualCycle =>
      type == FinanceRecurringType.yearly ||
      (type == FinanceRecurringType.custom &&
          ((customInterval == 12 && customIntervalUnit == 'months') ||
              (customInterval == 1 && customIntervalUnit == 'years')));
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
  final ExpenseRelationshipCycleLabelPolicy cycleLabelPolicy;
  final ExpenseRelationshipPaymentConfiguration paymentConfiguration;
  final PaymentExecutionMode paymentExecutionMode;
  final ManualPaymentPreference? manualPaymentPreference;
  final List<ExpenseRelationshipIdentifier> identifiers;
  final ExpenseRelationshipCommercialTerm? commercialTerm;

  ExpenseRelationship({
    required String relationshipId,
    required String service,
    required String provider,
    required this.subject,
    required this.status,
    required this.periodicity,
    this.cycleLabelPolicy = ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
    required this.paymentConfiguration,
    this.paymentExecutionMode = PaymentExecutionMode.unknown,
    this.manualPaymentPreference,
    this.identifiers = const [],
    this.commercialTerm,
  }) : relationshipId = _requiredText(relationshipId, 'relationshipId'),
       service = _requiredText(service, 'service'),
       provider = _requiredText(provider, 'provider') {
    final identities = identifiers.map((item) => item.identity).toList();
    if (identities.toSet().length != identities.length) {
      throw ArgumentError.value(identifiers, 'identifiers', 'Must be unique');
    }
    if (commercialTerm?.effectiveFrom != null &&
        commercialTerm?.commercialEnd != null &&
        commercialTerm!.commercialEnd!.isBefore(
          commercialTerm!.effectiveFrom!,
        )) {
      throw ArgumentError.value(commercialTerm, 'commercialTerm');
    }
    if (cycleLabelPolicy ==
            ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear &&
        !periodicity.isAnnualCycle) {
      throw ArgumentError.value(
        cycleLabelPolicy,
        'cycleLabelPolicy',
        'The target year label requires an annual cycle',
      );
    }
  }

  ExpenseRelationship copyWith({
    String? service,
    String? provider,
    FinanceSubject? subject,
    ExpenseRelationshipStatus? status,
    ExpenseRelationshipPeriodicity? periodicity,
    ExpenseRelationshipCycleLabelPolicy? cycleLabelPolicy,
    ExpenseRelationshipPaymentConfiguration? paymentConfiguration,
    PaymentExecutionMode? paymentExecutionMode,
    Object? manualPaymentPreference = _preserveManualPaymentPreference,
    List<ExpenseRelationshipIdentifier>? identifiers,
    Object? commercialTerm = _preserveManualPaymentPreference,
  }) => ExpenseRelationship(
    relationshipId: relationshipId,
    service: service ?? this.service,
    provider: provider ?? this.provider,
    subject: subject ?? this.subject,
    status: status ?? this.status,
    periodicity: periodicity ?? this.periodicity,
    cycleLabelPolicy: cycleLabelPolicy ?? this.cycleLabelPolicy,
    paymentConfiguration: paymentConfiguration ?? this.paymentConfiguration,
    paymentExecutionMode: paymentExecutionMode ?? this.paymentExecutionMode,
    manualPaymentPreference:
        identical(manualPaymentPreference, _preserveManualPaymentPreference)
        ? this.manualPaymentPreference
        : manualPaymentPreference as ManualPaymentPreference?,
    identifiers: identifiers ?? this.identifiers,
    commercialTerm: identical(commercialTerm, _preserveManualPaymentPreference)
        ? this.commercialTerm
        : commercialTerm as ExpenseRelationshipCommercialTerm?,
  );

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'service': service,
    'provider': provider,
    'subject': subject.name,
    'status': status.name,
    'periodicity': periodicity.toJson(),
    'cycleLabelPolicy': cycleLabelPolicy.name,
    'paymentConfiguration': paymentConfiguration.toJson(),
    'paymentExecutionMode': paymentExecutionMode.name,
    'manualPaymentPreference': manualPaymentPreference?.toJson(),
    'identifiers': identifiers.map((item) => item.toJson()).toList(),
    'commercialTerm': commercialTerm?.toJson(),
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
    final identifiers = json['identifiers'] ?? const [];
    final commercialTerm = json['commercialTerm'];
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
    if (identifiers is! List) {
      throw const FormatException('identifiers must be a list');
    }
    if (commercialTerm != null && commercialTerm is! Map) {
      throw const FormatException('commercialTerm must be an object or null');
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
      cycleLabelPolicy: _optionalEnumValue(
        json,
        'cycleLabelPolicy',
        ExpenseRelationshipCycleLabelPolicy.values,
        (value) => value.name,
        ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
      ),
      paymentConfiguration: ExpenseRelationshipPaymentConfiguration.fromJson(
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
      identifiers: identifiers
          .map(
            (item) => ExpenseRelationshipIdentifier.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      commercialTerm: commercialTerm == null
          ? null
          : ExpenseRelationshipCommercialTerm.fromJson(
              Map<String, dynamic>.from(commercialTerm),
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

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string or null');
  return DateTime.parse(value);
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
