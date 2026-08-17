import '../../../models/economic_event.dart';
import '../../../models/finance_recurring_item.dart';
import '../../../models/real_expense.dart';
import '../economic_event_adapter.dart';

class RealExpenseEventAdapter implements EconomicEventAdapter<RealExpense> {
  const RealExpenseEventAdapter();

  @override
  EconomicEvent adapt(
    RealExpense source, {
    required DateTime observedAt,
    String? eventId,
  }) {
    final amount = source.amount.abs();
    final account = EconomicEndpoint(
      kind: source.nonTrackedCash
          ? EconomicEndpointKind.cash
          : EconomicEndpointKind.account,
      referenceId: source.balanceId,
      label: source.balanceName,
      amount: amount,
    );
    final cashWallet = EconomicEndpoint(
      kind: EconomicEndpointKind.cash,
      referenceId: source.cashWalletId,
      label: 'Portafoglio contanti',
      amount: amount,
    );
    final external = EconomicEndpoint(
      kind: EconomicEndpointKind.external,
      label: source.isIncome ? 'Provenienza esterna' : 'Spesa sostenuta',
      amount: amount,
    );

    return EconomicEvent(
      id: eventId ?? 'real_expense:${source.id}',
      economicFactId: source.economicFactId,
      observedAt: observedAt,
      occurredAt: source.date,
      origins: source.isIncome ? [external] : [account],
      destinations: source.isIncome
          ? [account]
          : source.isCashWithdrawal
          ? [cashWallet]
          : [external],
      category: EconomicCategoryRef.fromLabel(source.category),
      personId: _personId(source.subject),
      description: source.description,
      amount: amount,
      nature: source.isIncome
          ? EconomicNature.income
          : source.isCashWithdrawal
          ? EconomicNature.internalTransfer
          : EconomicNature.outflow,
      sourceLinks: [
        EconomicSourceLink(
          kind: EconomicSourceKind.realExpense,
          recordId: source.id,
        ),
      ],
    );
  }

  String? _personId(FinanceSubject subject) => switch (subject) {
    FinanceSubject.matteo => 'matteo',
    FinanceSubject.chiara => 'chiara',
    FinanceSubject.alice => 'alice',
    FinanceSubject.shared => null,
  };
}
