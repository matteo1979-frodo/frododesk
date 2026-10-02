import '../../models/documentary_obligation.dart';
import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/finance_forecast_presentation.dart';
import '../../models/finite_financial_plan.dart';
import '../../models/future_outflow_presentation.dart';
import '../../models/projected_expense_cycle.dart';
import 'documentary_obligation_projection_adapter.dart';
import 'documentary_obligation_persistence.dart';
import 'expected_expense_persistence.dart';
import 'expected_expense_reader.dart';
import 'expense_relationship_projection_adapter.dart';
import 'future_expense_reader.dart';
import 'future_outflow_presentation_composer.dart';

/// Pure convergence boundary for future financial outflows.
class FinanceForecastReader {
  const FinanceForecastReader();

  FinanceForecastOverview read({
    required ExpectedExpenseAggregate expectedExpenses,
    required DocumentaryObligationAggregate documentaryObligations,
    required Iterable<FiniteFinancialPlan> finitePlans,
    required DateTime referenceTime,
    required ExpenseProjectionHorizon projectionHorizon,
  }) {
    final expected = const FutureExpenseReader().read(
      projections: const ExpectedExpenseReader().read(expectedExpenses),
      referenceTime: referenceTime,
    );
    final projected = const ExpenseRelationshipProjectionAdapter().project(
      aggregate: expectedExpenses,
      horizon: projectionHorizon,
    );
    final documentary = const DocumentaryObligationProjectionAdapter()
        .projectWithAuthority(documentaryObligations);
    final composed = const FutureOutflowPresentationComposer().compose(
      expectedExpenses: expected,
      projectedCycles: projected,
      finitePlans: finitePlans,
      referenceTime: referenceTime,
      documentaryInstallments: documentary.items,
      materializedDocumentaryCycleIds: documentary.materializedCycleIdentities,
    );
    final planById = {for (final plan in finitePlans) plan.id: plan};
    final obligationById = {
      for (final obligation in documentaryObligations.obligations)
        obligation.obligationId: obligation,
    };
    final source = [
      ...composed.pastMonths,
      ...composed.currentMonth,
      for (final group in composed.futureMonths) ...group.items,
      ...composed.unplaced,
    ];
    return FinanceForecastOverview(
      source.map(
        (item) =>
            _map(item, planById: planById, obligationById: obligationById),
      ),
    );
  }

  FinanceForecastPresentation _map(
    FutureOutflowPresentation item, {
    required Map<String, FiniteFinancialPlan> planById,
    required Map<String, DocumentaryObligation> obligationById,
  }) {
    final temporal = _temporalKnowledge(item);
    final expected = item.expectedExpense?.source;
    final projected = item.projectedExpenseCycle;
    final plan = item.planId == null ? null : planById[item.planId];
    final obligation = item.obligationId == null
        ? null
        : obligationById[item.obligationId];
    final relationshipId =
        expected?.relationshipId ??
        projected?.identity.relationshipId ??
        item.relationshipId;
    final cycleSequence =
        expected?.cycleSequence ??
        projected?.identity.cycleSequence ??
        item.cycleSequence;

    return FinanceForecastPresentation(
      identity: _identity(item, relationshipId, cycleSequence),
      label: item.title,
      amount: item.amount,
      subject:
          expected?.expectedSubject ??
          projected?.expectedSubject ??
          plan?.subject ??
          obligation?.documentHolder,
      balanceId:
          expected?.expectedPaymentConfiguration.expectedBalanceId ??
          projected?.expectedPaymentConfiguration.expectedBalanceId ??
          plan?.debitBalanceId,
      temporalKnowledge: temporal,
      economicStart: _isEconomic(temporal) ? item.placementStart : null,
      economicEnd: _isEconomic(temporal) ? item.placementEnd : null,
      economicPeriod:
          temporal == FinanceForecastTemporalKnowledge.economicPeriodKnown
          ? item.placementPeriod
          : null,
      documentaryPeriod:
          temporal == FinanceForecastTemporalKnowledge.documentPeriodOnly
          ? item.placementPeriod
          : null,
      certainty: _certainty(item),
      provisional: item.provisional,
      authority: item.authority,
      provenance: item.datePresentation,
      relationshipId: relationshipId,
      cycleSequence: cycleSequence,
      occurrenceId: expected?.occurrenceId,
      obligationId: item.obligationId,
      documentaryInstallmentId: item.documentaryInstallmentId,
      planId: item.planId,
      installmentNumber: item.installmentNumber,
      economicFactId: expected?.resolvedEconomicFactId,
      requiresUserAction: item.requiresUserAction,
      requiresPlanning: item.requiresPlanning,
    );
  }

  String _identity(
    FutureOutflowPresentation item,
    String? relationshipId,
    int? cycleSequence,
  ) {
    if (item.authority == FutureOutflowAuthority.finiteFinancialPlan) {
      return 'finite-plan:${item.planId}#${item.installmentNumber}';
    }
    if (item.authority == FutureOutflowAuthority.documentaryObligation &&
        item.documentaryInstallmentId != null) {
      return 'documentary-installment:${item.obligationId}#${item.documentaryInstallmentId}';
    }
    if (relationshipId != null && cycleSequence != null) {
      return 'expense-cycle:$relationshipId#$cycleSequence';
    }
    return 'expected-occurrence:${item.expectedExpense!.source.occurrenceId}';
  }

  FinanceForecastTemporalKnowledge _temporalKnowledge(
    FutureOutflowPresentation item,
  ) {
    switch (item.datePresentation) {
      case FutureOutflowDatePresentation.plannedEconomicImpact:
      case FutureOutflowDatePresentation.expectedDebitWindow:
        final start = item.placementStart!;
        final end = item.placementEnd!;
        if (start.year != end.year || start.month != end.month) {
          return FinanceForecastTemporalKnowledge.unlocated;
        }
        return start == end
            ? FinanceForecastTemporalKnowledge.economicDateKnown
            : FinanceForecastTemporalKnowledge.economicWindowKnown;
      case FutureOutflowDatePresentation.dueDateFallback:
        final source = item.expectedExpense!.source;
        return source.expectedDueDateCertainty ==
                    ExpectedExpenseDateCertainty.known &&
                source.occurrencePaymentExecutionMode ==
                    PaymentExecutionMode.automatic
            ? FinanceForecastTemporalKnowledge.economicDateKnown
            : FinanceForecastTemporalKnowledge.unlocated;
      case FutureOutflowDatePresentation.projectedCycle:
        return item.projectedExpenseCycle!.paymentExecutionMode ==
                PaymentExecutionMode.automatic
            ? FinanceForecastTemporalKnowledge.economicDateKnown
            : FinanceForecastTemporalKnowledge.unlocated;
      case FutureOutflowDatePresentation.finitePlanForecast:
      case FutureOutflowDatePresentation.documentaryDeadline:
        return FinanceForecastTemporalKnowledge.economicDateKnown;
      case FutureOutflowDatePresentation.expectedDocumentPeriod:
      case FutureOutflowDatePresentation.documentaryChoiceRequired:
        return item.placementPeriod == null
            ? FinanceForecastTemporalKnowledge.unlocated
            : FinanceForecastTemporalKnowledge.documentPeriodOnly;
      case FutureOutflowDatePresentation.unplaced:
        return FinanceForecastTemporalKnowledge.unlocated;
    }
  }

  FinanceForecastCertainty _certainty(FutureOutflowPresentation item) {
    final source = item.expectedExpense?.source;
    if (source != null) {
      return switch (source.confidence) {
        ExpenseEstimateConfidence.high => FinanceForecastCertainty.known,
        ExpenseEstimateConfidence.medium => FinanceForecastCertainty.estimated,
        ExpenseEstimateConfidence.low => FinanceForecastCertainty.unspecified,
      };
    }
    return item.authority == FutureOutflowAuthority.projectedExpenseRelationship
        ? FinanceForecastCertainty.projected
        : FinanceForecastCertainty.known;
  }

  bool _isEconomic(FinanceForecastTemporalKnowledge knowledge) =>
      knowledge == FinanceForecastTemporalKnowledge.economicDateKnown ||
      knowledge == FinanceForecastTemporalKnowledge.economicWindowKnown;
}
