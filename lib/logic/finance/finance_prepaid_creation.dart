import '../../models/finance_account_linked_item.dart';
import '../../models/finance_balance.dart';

typedef FinancePrepaidCreationIdTokenGenerator = String Function();

class FinancePrepaidCreationInput {
  final String parentBalanceId;
  final String personId;
  final String prepaidName;
  final double amount;
  final String linkedItemName;
  final String description;
  final DateTime? expirationDate;
  final bool active;
  final DateTime occurredAt;

  const FinancePrepaidCreationInput({
    required this.parentBalanceId,
    required this.personId,
    required this.prepaidName,
    required this.amount,
    required this.linkedItemName,
    this.description = '',
    this.expirationDate,
    this.active = true,
    required this.occurredAt,
  });
}

class FinancePrepaidCreationRecords {
  final FinanceBalance balance;
  final FinanceAccountLinkedItem linkedItem;

  const FinancePrepaidCreationRecords({
    required this.balance,
    required this.linkedItem,
  });
}

class FinancePrepaidCreationBuilder {
  final FinancePrepaidCreationIdTokenGenerator idTokenGenerator;

  FinancePrepaidCreationBuilder({
    FinancePrepaidCreationIdTokenGenerator? idTokenGenerator,
  }) : idTokenGenerator =
           idTokenGenerator ??
           (() => DateTime.now().microsecondsSinceEpoch.toString());

  FinancePrepaidCreationRecords build(FinancePrepaidCreationInput input) {
    final token = idTokenGenerator();
    final balanceId = 'balance_prepaid_$token';
    final linkedItemId = 'linked_prepaid_$token';
    final balance = FinanceBalance(
      personId: input.personId,
      balanceId: balanceId,
      name: input.prepaidName,
      initialAmount: input.amount,
      currentAmount: input.amount,
      updatedAt: input.occurredAt,
      balanceType: FinanceBalanceType.prepaidCard,
      operational: true,
      active: input.active,
      reservedAmount: 0,
      warningThreshold: 200,
      persistentStressDays: 0,
      recoveryDays: 0,
    );
    final linkedItem = FinanceAccountLinkedItem(
      id: linkedItemId,
      balanceId: input.parentBalanceId,
      autonomousBalanceId: balanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: input.linkedItemName,
      description: input.description,
      expirationDate: input.expirationDate,
      amount: input.amount,
      active: input.active,
    );
    return FinancePrepaidCreationRecords(
      balance: balance,
      linkedItem: linkedItem,
    );
  }
}

enum FinancePrepaidCreationFailure {
  v3Required,
  parentNotFound,
  personMismatch,
  commitFailed,
}

class FinancePrepaidCreationResult {
  final FinancePrepaidCreationRecords? records;
  final FinancePrepaidCreationFailure? failure;
  final List<String> errors;

  FinancePrepaidCreationResult._({
    required this.records,
    required this.failure,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory FinancePrepaidCreationResult.success(
    FinancePrepaidCreationRecords records,
  ) => FinancePrepaidCreationResult._(
    records: records,
    failure: null,
    errors: const [],
  );

  factory FinancePrepaidCreationResult.failed({
    required FinancePrepaidCreationFailure failure,
    required Iterable<String> errors,
  }) => FinancePrepaidCreationResult._(
    records: null,
    failure: failure,
    errors: errors,
  );

  bool get isSuccess => failure == null;
}
