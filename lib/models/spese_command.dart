import 'economic_event.dart';

enum SpeseCommandKind { expense, extraIncome, cashWithdrawal }

enum SpeseCommandAction { create, removeForEdit, delete }

class SpeseCommandEndpoint {
  final EconomicEndpointKind kind;
  final String? referenceId;
  final String label;

  const SpeseCommandEndpoint({
    required this.kind,
    required this.label,
    this.referenceId,
  });
}

class SpeseCommand {
  final String id;
  final SpeseCommandKind kind;
  final SpeseCommandAction action;
  final String? targetRecordId;
  final DateTime preparedAt;
  final DateTime occurredAt;
  final SpeseCommandEndpoint origin;
  final SpeseCommandEndpoint destination;
  final double amount;
  final String category;
  final String? personId;
  final String description;

  const SpeseCommand({
    required this.id,
    required this.kind,
    required this.action,
    required this.preparedAt,
    required this.occurredAt,
    required this.origin,
    required this.destination,
    required this.amount,
    required this.category,
    required this.description,
    this.targetRecordId,
    this.personId,
  });
}

class SpeseCommandEndpointDraft {
  final EconomicEndpointKind kind;
  final String? referenceId;
  final String? label;

  const SpeseCommandEndpointDraft({
    required this.kind,
    this.referenceId,
    this.label,
  });
}

class SpeseCommandDraft {
  final String id;
  final SpeseCommandKind kind;
  final SpeseCommandAction action;
  final String? targetRecordId;
  final DateTime preparedAt;
  final DateTime occurredAt;
  final SpeseCommandEndpointDraft origin;
  final SpeseCommandEndpointDraft destination;
  final String amountInput;
  final String category;
  final String? personId;
  final String description;

  const SpeseCommandDraft({
    required this.id,
    required this.kind,
    this.action = SpeseCommandAction.create,
    required this.preparedAt,
    required this.occurredAt,
    required this.origin,
    required this.destination,
    required this.amountInput,
    required this.category,
    required this.description,
    this.targetRecordId,
    this.personId,
  });
}

class SpeseCommandRegistry {
  final Map<String, String> accounts;
  final Map<String, String> funds;
  final Map<String, String> cashWallets;
  final Set<String> categories;
  final Set<String> people;

  SpeseCommandRegistry({
    Map<String, String> accounts = const {},
    Map<String, String> funds = const {},
    Map<String, String> cashWallets = const {},
    Set<String> categories = const {},
    Set<String> people = const {},
  }) : accounts = Map.unmodifiable(accounts),
       funds = Map.unmodifiable(funds),
       cashWallets = Map.unmodifiable(cashWallets),
       categories = Set.unmodifiable(categories),
       people = Set.unmodifiable(people);
}
