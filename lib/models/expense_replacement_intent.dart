import 'dart:convert';

import 'economic_event.dart';
import 'finance_recurring_item.dart';
import 'real_expense.dart';
import 'spese_command.dart';

class ExpenseReplacementIdentities {
  final String compensationTransactionId;
  final String compensationEconomicFactId;
  final String replacementCommandId;
  final String replacementEconomicFactId;

  const ExpenseReplacementIdentities._({
    required this.compensationTransactionId,
    required this.compensationEconomicFactId,
    required this.replacementCommandId,
    required this.replacementEconomicFactId,
  });

  factory ExpenseReplacementIdentities.fromReplacementId(String replacementId) {
    final normalized = replacementId.trim();
    if (normalized.isEmpty || normalized != replacementId) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Must be non-empty and have no surrounding whitespace',
      );
    }
    final encoded = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    final namespace = 'expense_replacement_$encoded';
    final commandId = '${namespace}_replacement';
    return ExpenseReplacementIdentities._(
      compensationTransactionId: '${namespace}_compensation_transaction',
      compensationEconomicFactId: '${namespace}_compensation_fact',
      replacementCommandId: commandId,
      replacementEconomicFactId: 'economic_fact_spese_$commandId',
    );
  }
}

class ExpenseReplacementPayload {
  final String balanceId;
  final String balanceName;
  final double amount;
  final String description;
  final String category;
  final DateTime preparedAt;
  final DateTime occurredAt;
  final String? personId;

  ExpenseReplacementPayload({
    required this.balanceId,
    required this.balanceName,
    required this.amount,
    required this.description,
    required this.category,
    required this.preparedAt,
    required this.occurredAt,
    this.personId,
  }) {
    _validate();
  }

  void _validate() {
    if (balanceId.trim().isEmpty) {
      throw ArgumentError.value(balanceId, 'balanceId', 'Must not be empty');
    }
    if (balanceName.trim().isEmpty) {
      throw ArgumentError.value(
        balanceName,
        'balanceName',
        'Must not be empty',
      );
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be finite and positive',
      );
    }
    if (description.trim().isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'Must not be empty',
      );
    }
    if (category.trim().isEmpty) {
      throw ArgumentError.value(category, 'category', 'Must not be empty');
    }
    if (personId != null && personId!.trim().isEmpty) {
      throw ArgumentError.value(personId, 'personId', 'Must not be empty');
    }
    if (personId != null &&
        !FinanceSubject.values.any((subject) => subject.name == personId)) {
      throw ArgumentError.value(
        personId,
        'personId',
        'Must be a known subject',
      );
    }
  }

  SpeseCommand toCommand(ExpenseReplacementIdentities identities) =>
      SpeseCommand(
        id: identities.replacementCommandId,
        kind: SpeseCommandKind.expense,
        action: SpeseCommandAction.create,
        preparedAt: preparedAt,
        occurredAt: occurredAt,
        origin: SpeseCommandEndpoint(
          kind: EconomicEndpointKind.account,
          referenceId: balanceId,
          label: balanceName,
        ),
        destination: const SpeseCommandEndpoint(
          kind: EconomicEndpointKind.external,
          label: 'Esterno',
        ),
        amount: amount,
        category: category,
        personId: personId,
        description: description,
      );

  Map<String, dynamic> toJson() => {
    'balanceId': balanceId,
    'balanceName': balanceName,
    'amount': amount,
    'description': description,
    'category': category,
    'preparedAt': preparedAt.toIso8601String(),
    'occurredAt': occurredAt.toIso8601String(),
    'personId': personId,
  };

  factory ExpenseReplacementPayload.fromJson(Map<String, dynamic> json) =>
      ExpenseReplacementPayload(
        balanceId: _requiredString(json, 'balanceId'),
        balanceName: _requiredString(json, 'balanceName'),
        amount: _requiredNumber(json, 'amount').toDouble(),
        description: _requiredString(json, 'description'),
        category: _requiredString(json, 'category'),
        preparedAt: _requiredDate(json, 'preparedAt'),
        occurredAt: _requiredDate(json, 'occurredAt'),
        personId: _optionalString(json, 'personId'),
      );
}

class ExpenseReplacementIntent {
  static const int currentVersion = 1;

  final int version;
  final String replacementId;
  final RealExpense originalExpense;
  final ExpenseReplacementPayload replacementPayload;

  ExpenseReplacementIntent({
    this.version = currentVersion,
    required this.replacementId,
    required this.originalExpense,
    required this.replacementPayload,
  }) {
    _validate();
  }

  ExpenseReplacementIdentities get identities =>
      ExpenseReplacementIdentities.fromReplacementId(replacementId);

  void _validate() {
    if (version != currentVersion) {
      throw ArgumentError.value(version, 'version', 'Unsupported version');
    }
    if (replacementId.trim().isEmpty || replacementId.trim() != replacementId) {
      throw ArgumentError.value(
        replacementId,
        'replacementId',
        'Must be non-empty and have no surrounding whitespace',
      );
    }
    if (originalExpense.id.trim().isEmpty ||
        originalExpense.balanceId.trim().isEmpty ||
        originalExpense.balanceName.trim().isEmpty ||
        originalExpense.description.trim().isEmpty ||
        originalExpense.category.trim().isEmpty ||
        !originalExpense.amount.isFinite ||
        originalExpense.amount <= 0) {
      throw ArgumentError.value(
        originalExpense,
        'originalExpense',
        'Must be a structurally complete expense',
      );
    }
    if (originalExpense.economicFactId != null &&
        originalExpense.economicFactId!.trim().isEmpty) {
      throw ArgumentError.value(
        originalExpense.economicFactId,
        'originalExpense.economicFactId',
        'Must be null or non-empty',
      );
    }
    if (originalExpense.isIncome ||
        originalExpense.isCashWithdrawal ||
        originalExpense.nonTrackedCash ||
        originalExpense.cashWalletId != null) {
      throw ArgumentError.value(
        originalExpense,
        'originalExpense',
        'Must be an ordinary expense',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'replacementId': replacementId,
    'originalExpense': originalExpense.toJson(),
    'replacementPayload': replacementPayload.toJson(),
  };

  factory ExpenseReplacementIntent.fromJson(Map<String, dynamic> json) {
    final version = _requiredInt(json, 'version');
    if (version != currentVersion) {
      throw FormatException(
        'Unsupported expense replacement version: $version',
      );
    }
    final originalJson = _requiredMap(json, 'originalExpense');
    _validateOriginalExpenseJson(originalJson);
    final payloadJson = _requiredMap(json, 'replacementPayload');
    try {
      return ExpenseReplacementIntent(
        version: version,
        replacementId: _requiredString(json, 'replacementId'),
        originalExpense: RealExpense.fromJson(originalJson),
        replacementPayload: ExpenseReplacementPayload.fromJson(payloadJson),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid expense replacement intent: $error');
    }
  }

  static void _validateOriginalExpenseJson(Map<String, dynamic> json) {
    for (final key in const [
      'id',
      'balanceId',
      'balanceName',
      'description',
      'category',
      'date',
      'subject',
    ]) {
      _requiredString(json, key);
    }
    _requiredNumber(json, 'amount');
    for (final key in const [
      'nonTrackedCash',
      'isCashWithdrawal',
      'isIncome',
    ]) {
      if (json[key] is! bool) throw FormatException('$key must be a bool');
    }
    _requiredDate(json, 'date');
    final subject = json['subject'];
    if (!FinanceSubject.values.any((value) => value.name == subject)) {
      throw FormatException('Unknown subject: $subject');
    }
    if (json['cashWalletId'] != null && json['cashWalletId'] is! String) {
      throw const FormatException('cashWalletId must be a string or null');
    }
    if (json['economicFactId'] != null && json['economicFactId'] is! String) {
      throw const FormatException('economicFactId must be a string or null');
    }
    if (json['operationMetadata'] != null &&
        json['operationMetadata'] is! Map) {
      throw const FormatException(
        'operationMetadata must be an object or null',
      );
    }
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key must be an object');
  return Map<String, dynamic>.from(value);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string or null');
  return value;
}

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('$key must be a number');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an int');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be an ISO-8601 date');
  return parsed;
}
