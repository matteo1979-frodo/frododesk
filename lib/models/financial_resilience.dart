enum ResilienceStatus { breathes, attention, suffers }

enum ResiliencePhase { realized, current, forecast }

enum FinancialEventDirection { income, outflow }

enum FinancialTemporalPrecision { exactDate, window, month, unlocated }

enum FinancialAmountPrecision { known, estimated, unknown }

enum FinancialFlexibility { fixed, flexible, unknown }

enum FinancialResourceKind { balance, cash, fund }

enum MitigationKind {
  designatedFund,
  sameBalance,
  sameOwnerBalance,
  reallocateFund,
  otherOwnerRequiresApproval,
  deferKnownFlexibleCommitment,
  unresolved,
}

class FinancialResource {
  final String id;
  final String label;
  final String? ownerId;
  final double amount;
  final FinancialResourceKind kind;
  final bool protected;
  final String? purposeKey;

  const FinancialResource({
    required this.id,
    required this.label,
    required this.ownerId,
    required this.amount,
    required this.kind,
    this.protected = false,
    this.purposeKey,
  });
}

class FinancialTimelineEvent {
  final String identity;
  final String label;
  final double amount;
  final FinancialEventDirection direction;
  final FinancialTemporalPrecision temporalPrecision;
  final DateTime? start;
  final DateTime? end;
  final int? year;
  final int? month;
  final FinancialAmountPrecision amountPrecision;
  final String? balanceId;
  final String? ownerId;
  final String? purposeKey;
  final FinancialFlexibility flexibility;
  final bool structural;
  final bool extraordinary;
  final bool transfer;

  const FinancialTimelineEvent({
    required this.identity,
    required this.label,
    required this.amount,
    required this.direction,
    required this.temporalPrecision,
    this.start,
    this.end,
    this.year,
    this.month,
    this.amountPrecision = FinancialAmountPrecision.known,
    this.balanceId,
    this.ownerId,
    this.purposeKey,
    this.flexibility = FinancialFlexibility.unknown,
    this.structural = false,
    this.extraordinary = false,
    this.transfer = false,
  });

  bool fallsInMonth(DateTime value) {
    if (temporalPrecision == FinancialTemporalPrecision.unlocated) return false;
    if (year != null && month != null) {
      return year == value.year && month == value.month;
    }
    final date = start;
    return date != null && date.year == value.year && date.month == value.month;
  }
}

class HistoricalFinancialFact {
  final String identity;
  final DateTime date;
  final double amount;
  final FinancialEventDirection direction;
  final String? balanceId;
  final String? ownerId;
  final bool structural;
  final bool extraordinary;
  final bool transfer;

  const HistoricalFinancialFact({
    required this.identity,
    required this.date,
    required this.amount,
    required this.direction,
    this.balanceId,
    this.ownerId,
    this.structural = false,
    this.extraordinary = false,
    this.transfer = false,
  });
}

class MitigationOption {
  final MitigationKind kind;
  final double amount;
  final String explanation;
  final bool requiresApproval;
  final String? sacrificedPurpose;

  const MitigationOption({
    required this.kind,
    required this.amount,
    required this.explanation,
    this.requiresApproval = false,
    this.sacrificedPurpose,
  });
}

class InformationCoverage {
  final bool futureIncomeKnown;
  final int exactEvents;
  final int impreciseEvents;
  final int unlocatedEvents;
  final int knownAccountEvents;
  final int totalEvents;

  const InformationCoverage({
    required this.futureIncomeKnown,
    required this.exactEvents,
    required this.impreciseEvents,
    required this.unlocatedEvents,
    required this.knownAccountEvents,
    required this.totalEvents,
  });

  bool get partial =>
      !futureIncomeKnown || impreciseEvents > 0 || unlocatedEvents > 0;
}

class StructuralNeedEstimate {
  final double? monthlyOrdinaryNeed;
  final double? seasonalNeed;
  final int observedMonths;
  final int sameMonthYears;

  const StructuralNeedEstimate({
    required this.monthlyOrdinaryNeed,
    required this.seasonalNeed,
    required this.observedMonths,
    required this.sameMonthYears,
  });
}

class ResilienceAssessment {
  final DateTime month;
  final ResiliencePhase phase;
  final ResilienceStatus status;
  final double openingLiquidity;
  final double projectedClosingLiquidity;
  final double minimumProjectedLiquidity;
  final double inflow;
  final double outflow;
  final double fundCoverage;
  final double unresolvedDeficit;
  final InformationCoverage coverage;
  final StructuralNeedEstimate structuralNeed;
  final List<String> explanations;
  final List<MitigationOption> alternatives;

  const ResilienceAssessment({
    required this.month,
    required this.phase,
    required this.status,
    required this.openingLiquidity,
    required this.projectedClosingLiquidity,
    required this.minimumProjectedLiquidity,
    required this.inflow,
    required this.outflow,
    required this.fundCoverage,
    required this.unresolvedDeficit,
    required this.coverage,
    required this.structuralNeed,
    required this.explanations,
    required this.alternatives,
  });

  double get flow => inflow - outflow;
}
