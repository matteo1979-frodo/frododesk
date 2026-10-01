import 'dart:convert';

import 'balance_posting_mode.dart';
import 'economic_operation_metadata.dart';
import 'finance_recurring_item.dart';
import 'finance_transaction.dart';
import 'real_expense.dart';

enum CompositeCorrectionIntentPhase {
  pending,
  financeApplied,
  expensesApplied,
  documentaryApplied,
  completed,
  conflict,
}

class CompositeCorrectionPayload {
  final String balanceId;
  final String balanceName;
  final double mainAmount;
  final DateTime economicDate;
  final String description;
  final String category;
  final FinanceSubject subject;
  final Map<AccessoryCostType, double> accessories;
  final BalancePostingMode balancePostingMode;

  CompositeCorrectionPayload({
    required this.balanceId,
    required this.balanceName,
    required this.mainAmount,
    required this.economicDate,
    required this.description,
    required this.category,
    required this.subject,
    required Map<AccessoryCostType, double> accessories,
    required this.balancePostingMode,
  }) : accessories = Map.unmodifiable(accessories) {
    if (balanceId.trim().isEmpty ||
        balanceName.trim().isEmpty ||
        description.trim().isEmpty ||
        category.trim().isEmpty) {
      throw ArgumentError('Composite correction text fields must be non-empty');
    }
    if (!mainAmount.isFinite ||
        mainAmount <= 0 ||
        this.accessories.values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Composite correction amounts must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'balanceId': balanceId,
    'balanceName': balanceName,
    'mainAmount': mainAmount,
    'economicDate': economicDate.toIso8601String(),
    'description': description,
    'category': category,
    'subject': subject.name,
    'accessories': {
      for (final entry in accessories.entries) entry.key.name: entry.value,
    },
    'balancePostingMode': balancePostingMode.name,
  };

  factory CompositeCorrectionPayload.fromJson(Map<String, dynamic> json) {
    final rawAccessories = Map<String, dynamic>.from(
      json['accessories'] as Map,
    );
    return CompositeCorrectionPayload(
      balanceId: json['balanceId'] as String,
      balanceName: json['balanceName'] as String,
      mainAmount: (json['mainAmount'] as num).toDouble(),
      economicDate: DateTime.parse(json['economicDate'] as String),
      description: json['description'] as String,
      category: json['category'] as String,
      subject: FinanceSubject.values.firstWhere(
        (value) => value.name == json['subject'],
      ),
      accessories: {
        for (final entry in rawAccessories.entries)
          AccessoryCostType.values.firstWhere(
            (value) => value.name == entry.key,
          ): (entry.value as num)
              .toDouble(),
      },
      balancePostingMode: BalancePostingMode.values.firstWhere(
        (value) => value.name == json['balancePostingMode'],
      ),
    );
  }
}

class CompositeCorrectionIntent {
  static const version = 1;
  final int contractVersion;
  final String correctionId;
  final String operationId;
  final int revision;
  final CompositeCorrectionIntentPhase phase;
  final List<FinanceTransaction> originalTransactions;
  final List<RealExpense> originalExpenses;
  final Map<String, dynamic> originalPortfolio;
  final String? documentaryObligationId;
  final String? documentaryInstallmentId;
  final String? originalFulfilledEconomicFactId;
  final CompositeCorrectionPayload payload;

  CompositeCorrectionIntent({
    this.contractVersion = version,
    required this.correctionId,
    required this.operationId,
    required this.revision,
    this.phase = CompositeCorrectionIntentPhase.pending,
    required Iterable<FinanceTransaction> originalTransactions,
    required Iterable<RealExpense> originalExpenses,
    required Map<String, dynamic> originalPortfolio,
    this.documentaryObligationId,
    this.documentaryInstallmentId,
    this.originalFulfilledEconomicFactId,
    required this.payload,
  }) : originalTransactions = List.unmodifiable(originalTransactions),
       originalExpenses = List.unmodifiable(originalExpenses),
       originalPortfolio = Map.unmodifiable(
         Map<String, dynamic>.from(originalPortfolio),
       ) {
    if (contractVersion != version ||
        correctionId.trim().isEmpty ||
        operationId.trim().isEmpty ||
        revision < 1) {
      throw ArgumentError('Invalid composite correction intent identity');
    }
    if (this.originalTransactions.isEmpty || this.originalExpenses.isEmpty) {
      throw ArgumentError('Original composite snapshots must not be empty');
    }
    final documentary =
        documentaryObligationId != null ||
        documentaryInstallmentId != null ||
        originalFulfilledEconomicFactId != null;
    if (documentary &&
        (documentaryObligationId == null ||
            documentaryInstallmentId == null ||
            originalFulfilledEconomicFactId == null)) {
      throw ArgumentError('Documentary snapshot must be complete');
    }
  }

  String factId(String component) =>
      'economic_fact:composite_correction:${_encoded(correctionId)}:$component';
  String transactionId(String component) =>
      'finance_transaction:composite_correction:${_encoded(correctionId)}:$component';
  String expenseId(String component) =>
      'real_expense:composite_correction:${_encoded(correctionId)}:$component';

  CompositeCorrectionIntent withPhase(CompositeCorrectionIntentPhase value) =>
      CompositeCorrectionIntent(
        contractVersion: contractVersion,
        correctionId: correctionId,
        operationId: operationId,
        revision: revision,
        phase: value,
        originalTransactions: originalTransactions,
        originalExpenses: originalExpenses,
        originalPortfolio: originalPortfolio,
        documentaryObligationId: documentaryObligationId,
        documentaryInstallmentId: documentaryInstallmentId,
        originalFulfilledEconomicFactId: originalFulfilledEconomicFactId,
        payload: payload,
      );

  Map<String, dynamic> toJson() => {
    'version': contractVersion,
    'correctionId': correctionId,
    'operationId': operationId,
    'revision': revision,
    'phase': phase.name,
    'originalTransactions': originalTransactions
        .map((item) => item.toJson())
        .toList(),
    'originalExpenses': originalExpenses.map((item) => item.toJson()).toList(),
    'originalPortfolio': originalPortfolio,
    'documentaryObligationId': documentaryObligationId,
    'documentaryInstallmentId': documentaryInstallmentId,
    'originalFulfilledEconomicFactId': originalFulfilledEconomicFactId,
    'payload': payload.toJson(),
  };

  factory CompositeCorrectionIntent.fromJson(Map<String, dynamic> json) =>
      CompositeCorrectionIntent(
        contractVersion: json['version'] as int,
        correctionId: json['correctionId'] as String,
        operationId: json['operationId'] as String,
        revision: json['revision'] as int,
        phase: CompositeCorrectionIntentPhase.values.firstWhere(
          (value) => value.name == json['phase'],
        ),
        originalTransactions: (json['originalTransactions'] as List).map(
          (item) => FinanceTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
        originalExpenses: (json['originalExpenses'] as List).map(
          (item) =>
              RealExpense.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
        originalPortfolio: Map<String, dynamic>.from(
          json['originalPortfolio'] as Map,
        ),
        documentaryObligationId: json['documentaryObligationId'] as String?,
        documentaryInstallmentId: json['documentaryInstallmentId'] as String?,
        originalFulfilledEconomicFactId:
            json['originalFulfilledEconomicFactId'] as String?,
        payload: CompositeCorrectionPayload.fromJson(
          Map<String, dynamic>.from(json['payload'] as Map),
        ),
      );

  static String _encoded(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
