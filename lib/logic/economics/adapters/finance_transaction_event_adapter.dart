import '../../../models/economic_event.dart';
import '../../../models/finance_recurring_item.dart';
import '../../../models/finance_transaction.dart';
import '../economic_event_adapter.dart';

class FinanceTransactionEventAdapter
    implements EconomicEventAdapter<FinanceTransaction> {
  const FinanceTransactionEventAdapter();

  @override
  EconomicEvent adapt(
    FinanceTransaction source, {
    required DateTime observedAt,
    String? eventId,
  }) {
    final amount = source.amount.abs();
    final account = EconomicEndpoint(
      kind: source.origin == FinanceTransactionOrigin.fund
          ? EconomicEndpointKind.fund
          : EconomicEndpointKind.account,
      referenceId: source.balanceId,
      label: 'Conto',
      personId: _personId(source.subject),
      amount: amount,
    );
    final counterpart = EconomicEndpoint(
      kind: source.type == FinanceTransactionType.transfer
          ? EconomicEndpointKind.other
          : EconomicEndpointKind.external,
      label: source.type == FinanceTransactionType.transfer
          ? 'Contropartita del trasferimento'
          : source.isIncome
          ? 'Provenienza esterna'
          : 'Destinazione esterna',
      amount: amount,
    );
    final nature = switch (source.type) {
      FinanceTransactionType.income => EconomicNature.income,
      FinanceTransactionType.expense => EconomicNature.outflow,
      FinanceTransactionType.transfer => EconomicNature.internalTransfer,
    };

    return EconomicEvent(
      id: eventId ?? 'finance_transaction:${source.id}',
      economicFactId: source.economicFactId,
      observedAt: observedAt,
      occurredAt: source.date,
      origins: source.isIncome ? [counterpart] : [account],
      destinations: source.isIncome ? [account] : [counterpart],
      personId: _personId(source.subject),
      description: source.description,
      amount: amount,
      nature: nature,
      sourceLinks: [
        EconomicSourceLink(
          kind: EconomicSourceKind.financeTransaction,
          recordId: source.id,
        ),
      ],
      relatedEventIds: source.recurringItemId == null
          ? const []
          : ['recurring_item:${source.recurringItemId}'],
    );
  }

  String? _personId(FinanceSubject subject) => switch (subject) {
    FinanceSubject.matteo => 'matteo',
    FinanceSubject.chiara => 'chiara',
    FinanceSubject.alice => 'alice',
    FinanceSubject.shared => null,
  };
}
