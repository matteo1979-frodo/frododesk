import '../../models/finance_forecast_presentation.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/finance_transaction.dart';
import '../../models/financial_resilience.dart';
import '../../models/income.dart';
import '../../models/income_forecast_presentation.dart';
import '../../stores/cash_wallet_store.dart';
import '../../stores/finance_store.dart';
import 'financial_resilience_engine.dart';

class HouseholdResilienceReader {
  const HouseholdResilienceReader();

  List<ResilienceAssessment> readYear({
    required int year,
    required DateTime referenceTime,
    required FinanceStore financeStore,
    required CashWalletStore cashWalletStore,
    required IncomeForecastOverview incomes,
    required FinanceForecastOverview expenses,
  }) {
    final resources = <FinancialResource>[
      ...financeStore.balances
          .where((item) => item.active)
          .map(
            (item) => FinancialResource(
              id: item.balanceId,
              label: item.name,
              ownerId: item.personId,
              amount: item.currentAmount,
              kind: FinancialResourceKind.balance,
            ),
          ),
      ...cashWalletStore.all
          .where((item) => item.active)
          .map(
            (item) => FinancialResource(
              id: item.id,
              label: item.name,
              ownerId: item.personId,
              amount: item.currentAmount,
              kind: FinancialResourceKind.cash,
            ),
          ),
      ...financeStore.funds
          .where((item) => item.status.name == 'active')
          .map(
            (item) => FinancialResource(
              id: item.id,
              label: item.name,
              ownerId: null,
              amount: item.amount,
              kind: FinancialResourceKind.fund,
              protected: item.protected,
              purposeKey: item.category.name,
            ),
          ),
    ];
    final events = <FinancialTimelineEvent>[
      ...incomes.items.map(
        (item) => FinancialTimelineEvent(
          identity: item.identity,
          label: item.label,
          amount: item.amount,
          direction: FinancialEventDirection.income,
          temporalPrecision: FinancialTemporalPrecision.exactDate,
          start: item.economicDate,
          end: item.economicDate,
          amountPrecision: item.knowledge == IncomeKnowledge.estimated
              ? FinancialAmountPrecision.estimated
              : FinancialAmountPrecision.known,
          balanceId: item.destinationBalanceId,
          ownerId: _owner(item.subject),
          structural: _incomeStructural(financeStore, item.relationshipId),
          extraordinary: false,
        ),
      ),
      ...expenses.items.map(_expenseEvent),
    ];
    final facts = financeStore.transactions.map(
      (item) => HistoricalFinancialFact(
        identity: item.economicFactId ?? item.id,
        date: item.date,
        amount: item.amount,
        direction: item.isIncome
            ? FinancialEventDirection.income
            : FinancialEventDirection.outflow,
        balanceId: item.balanceId,
        ownerId: _owner(item.subject),
        structural: item.recurringItemId != null,
        extraordinary: item.origin == FinanceTransactionOrigin.adjustment,
        transfer: item.type == FinanceTransactionType.transfer,
      ),
    );
    return const FinancialResilienceEngine().assessYear(
      year: year,
      referenceTime: referenceTime,
      resources: resources,
      futureEvents: events,
      historicalFacts: facts,
      futureIncomeKnown: financeStore.incomeAggregate.relationships.isNotEmpty,
    );
  }

  FinancialTimelineEvent _expenseEvent(FinanceForecastPresentation item) {
    final precision = switch (item.temporalKnowledge) {
      FinanceForecastTemporalKnowledge.economicDateKnown =>
        FinancialTemporalPrecision.exactDate,
      FinanceForecastTemporalKnowledge.economicWindowKnown =>
        FinancialTemporalPrecision.window,
      FinanceForecastTemporalKnowledge.economicPeriodKnown =>
        FinancialTemporalPrecision.month,
      FinanceForecastTemporalKnowledge.documentPeriodOnly ||
      FinanceForecastTemporalKnowledge.unlocated =>
        FinancialTemporalPrecision.unlocated,
    };
    return FinancialTimelineEvent(
      identity: item.identity,
      label: item.label,
      amount: item.amount,
      direction: FinancialEventDirection.outflow,
      temporalPrecision: precision,
      start: item.economicStart,
      end: item.economicEnd,
      year: item.economicPeriod?.year,
      month: item.economicPeriod?.month,
      amountPrecision: switch (item.certainty) {
        FinanceForecastCertainty.known => FinancialAmountPrecision.known,
        FinanceForecastCertainty.estimated ||
        FinanceForecastCertainty.projected =>
          FinancialAmountPrecision.estimated,
        FinanceForecastCertainty.unspecified =>
          FinancialAmountPrecision.unknown,
      },
      balanceId: item.balanceId,
      ownerId: item.subject == null ? null : _owner(item.subject!),
      flexibility: FinancialFlexibility.unknown,
      structural: item.relationshipId != null || item.planId != null,
    );
  }

  bool _incomeStructural(FinanceStore store, String id) => store
      .incomeAggregate
      .relationships
      .where((item) => item.relationshipId == id)
      .any((item) => item.periodicity != IncomePeriodicity.oneTime);

  String? _owner(FinanceSubject subject) => switch (subject) {
    FinanceSubject.matteo => 'matteo',
    FinanceSubject.chiara => 'chiara',
    FinanceSubject.alice => 'alice',
    FinanceSubject.shared => null,
  };
}
