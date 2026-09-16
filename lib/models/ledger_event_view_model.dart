import 'dart:collection';

import 'economic_event.dart';
import 'finance_balance.dart';

enum LedgerEconomicSign { positive, negative, neutral }

enum LedgerLogicalIcon {
  income,
  expense,
  transfer,
  cash,
  fund,
  adjustment,
  openingBalance,
  other,
}

enum LedgerLogicalColor { positive, negative, transfer, warning, neutral }

enum LedgerCounterpartyRole { origin, destination }

enum LedgerBadgeTone { positive, negative, transfer, warning, neutral }

class LedgerEventCounterparty {
  final LedgerCounterpartyRole role;
  final EconomicEndpointKind kind;
  final String? referenceId;
  final String label;
  final String? personId;
  final String? personLabel;
  final FinanceBalanceType? balanceType;
  final double amount;

  const LedgerEventCounterparty({
    required this.role,
    required this.kind,
    required this.label,
    required this.amount,
    this.referenceId,
    this.personId,
    this.personLabel,
    this.balanceType,
  }) : assert(label != ''),
       assert(amount >= 0);
}

class LedgerEventBadge {
  final String label;
  final LedgerBadgeTone tone;

  const LedgerEventBadge({required this.label, required this.tone})
    : assert(label != '');
}

class LedgerEventViewModel {
  final String eventId;
  final String title;
  final String subtitle;
  final double amount;
  final String currencyCode;
  final LedgerEconomicSign economicSign;
  final EconomicNature nature;
  final String? personId;
  final String? personLabel;
  final EconomicCategoryRef? category;
  final DateTime observedAt;
  final DateTime occurredAt;
  final LedgerLogicalIcon logicalIcon;
  final LedgerLogicalColor logicalColor;
  final UnmodifiableListView<LedgerEventCounterparty> counterparties;
  final UnmodifiableListView<LedgerEventBadge> badges;
  final UnmodifiableListView<EconomicSourceLink> sourceLinks;
  final UnmodifiableListView<String> notes;
  final UnmodifiableListView<EconomicTransactionOrigin> transactionOrigins;
  final UnmodifiableListView<String> recurringItemIds;
  final String? operationDescription;

  LedgerEventViewModel({
    required this.eventId,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currencyCode,
    required this.economicSign,
    required this.nature,
    required this.observedAt,
    required this.occurredAt,
    required this.logicalIcon,
    required this.logicalColor,
    required List<LedgerEventCounterparty> counterparties,
    required List<LedgerEventBadge> badges,
    List<EconomicSourceLink> sourceLinks = const [],
    List<String> notes = const [],
    List<EconomicTransactionOrigin> transactionOrigins = const [],
    List<String> recurringItemIds = const [],
    this.operationDescription,
    this.personId,
    this.personLabel,
    this.category,
  }) : assert(eventId != ''),
       assert(title != ''),
       assert(amount >= 0),
       assert(currencyCode != ''),
       counterparties = UnmodifiableListView(
         List<LedgerEventCounterparty>.of(counterparties),
       ),
       badges = UnmodifiableListView(List<LedgerEventBadge>.of(badges)),
       sourceLinks = UnmodifiableListView(
         List<EconomicSourceLink>.of(sourceLinks),
       ),
       notes = UnmodifiableListView(List<String>.of(notes)),
       transactionOrigins = UnmodifiableListView(
         List<EconomicTransactionOrigin>.of(transactionOrigins),
       ),
       recurringItemIds = UnmodifiableListView(
         List<String>.of(recurringItemIds),
       );

  bool get isInternalTransfer => nature == EconomicNature.internalTransfer;

  DateTime get timelineDate => occurredAt;
}
