import 'dart:convert';

import 'finance_recurring_item.dart';

/// Pure description of one real installment confirmation.
///
/// This contract only supplies stable identities and validated input for a
/// future coordinator. It does not create economic records or mutate a plan.
class FiniteFinancialPlanInstallmentConfirmation {
  final String planId;
  final int installmentNumber;
  final String debitBalanceId;
  final FinanceSubject subject;
  final double mainAmount;
  final DateTime economicDate;
  final String description;
  final String mainCategory;
  final double? bankFee;
  final String? bankFeeCategory;

  FiniteFinancialPlanInstallmentConfirmation({
    required String planId,
    required this.installmentNumber,
    required String debitBalanceId,
    required this.subject,
    required this.mainAmount,
    required this.economicDate,
    required String description,
    required String mainCategory,
    double? bankFee,
    String? bankFeeCategory,
  }) : planId = planId.trim(),
       debitBalanceId = debitBalanceId.trim(),
       description = description.trim(),
       mainCategory = mainCategory.trim(),
       bankFee = bankFee == 0 ? null : bankFee,
       bankFeeCategory = bankFee == null || bankFee == 0
           ? null
           : bankFeeCategory?.trim() {
    if (this.planId.isEmpty) {
      throw ArgumentError.value(planId, 'planId', 'Must not be empty');
    }
    if (installmentNumber <= 0) {
      throw ArgumentError.value(
        installmentNumber,
        'installmentNumber',
        'Must be greater than zero',
      );
    }
    if (this.debitBalanceId.isEmpty) {
      throw ArgumentError.value(
        debitBalanceId,
        'debitBalanceId',
        'Must not be empty',
      );
    }
    if (!mainAmount.isFinite || mainAmount <= 0) {
      throw ArgumentError.value(
        mainAmount,
        'mainAmount',
        'Must be finite and greater than zero',
      );
    }
    if (economicDate.isBefore(DateTime(2020)) ||
        !economicDate.isBefore(DateTime(2101))) {
      throw ArgumentError.value(
        economicDate,
        'economicDate',
        'Must be between 2020-01-01 and 2100-12-31',
      );
    }
    if (this.description.isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'Must not be empty',
      );
    }
    if (this.mainCategory.isEmpty) {
      throw ArgumentError.value(
        mainCategory,
        'mainCategory',
        'Must not be empty',
      );
    }
    if (bankFee != null && (!bankFee.isFinite || bankFee < 0)) {
      throw ArgumentError.value(
        bankFee,
        'bankFee',
        'Must be finite and non-negative',
      );
    }
    if (hasBankFee &&
        (this.bankFeeCategory == null || this.bankFeeCategory!.isEmpty)) {
      throw ArgumentError.value(
        bankFeeCategory,
        'bankFeeCategory',
        'Must not be empty when bankFee is positive',
      );
    }
  }

  bool get hasBankFee => bankFee != null && bankFee! > 0;

  double get totalAccountOutflow => mainAmount + (bankFee ?? 0);

  String get installmentIdentity =>
      'finite_plan_installment:${_encodedPlanId()}:$installmentNumber';

  String get mainEconomicFactId => 'economic_fact:$installmentIdentity:main';

  String? get feeEconomicFactId =>
      hasBankFee ? 'economic_fact:$installmentIdentity:fee' : null;

  String _encodedPlanId() => base64Url.encode(utf8.encode(planId));
}
