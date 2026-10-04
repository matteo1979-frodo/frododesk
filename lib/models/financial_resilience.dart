enum ResilienceStatus { breathes, attention, suffers }

enum ResiliencePhase { realized, current, forecast }

enum FinancialEventDirection { income, outflow }

enum FinancialTemporalPrecision { exactDate, window, month, unlocated }

enum FinancialAmountPrecision { known, estimated, unknown }

enum FinancialFlexibility { fixed, flexible, unknown }

enum FinancialResourceKind { balance, cash, fund }

enum MitigationActionKnowledge { capacityOnly, executableActionKnown }

class FundingGap {
  final String commitmentId;
  final String commitmentLabel;
  final String targetBalanceId;
  final String targetBalanceLabel;
  final String? ownerId;
  final double requiredAmount;
  final double availableAmount;
  final double amount;
  final DateTime? date;

  const FundingGap({
    required this.commitmentId,
    required this.commitmentLabel,
    required this.targetBalanceId,
    required this.targetBalanceLabel,
    required this.ownerId,
    required this.requiredAmount,
    required this.availableAmount,
    required this.amount,
    this.date,
  });
}

class ResilienceLineItem {
  final String identity;
  final String label;
  final double amount;
  final FinancialEventDirection direction;
  final DateTime? date;
  final String? ownerId;
  final String? balanceId;
  final String? balanceLabel;

  const ResilienceLineItem({
    required this.identity,
    required this.label,
    required this.amount,
    required this.direction,
    this.date,
    this.ownerId,
    this.balanceId,
    this.balanceLabel,
  });
}

class PersonResilienceDetail {
  final String ownerId;
  final List<FinancialResource> resources;
  final List<ResilienceLineItem> items;

  const PersonResilienceDetail({
    required this.ownerId,
    required this.resources,
    required this.items,
  });

  double get liquidity => resources.fold(0, (sum, item) => sum + item.amount);
  double get inflow => items
      .where((item) => item.direction == FinancialEventDirection.income)
      .fold(0, (sum, item) => sum + item.amount);
  double get outflow => items
      .where((item) => item.direction == FinancialEventDirection.outflow)
      .fold(0, (sum, item) => sum + item.amount);
}

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
  final String label;
  final String? balanceLabel;

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
    this.label = 'Movimento',
    this.balanceLabel,
  });
}

class MitigationOption {
  final MitigationKind kind;
  final double amount;
  final String explanation;
  final bool requiresApproval;
  final String? sacrificedPurpose;
  final String? sourceResourceId;
  final String? sourceResourceLabel;
  final String? ownerId;
  final String? fundingGapCommitmentId;
  final String? targetBalanceId;
  final MitigationActionKnowledge actionKnowledge;

  const MitigationOption({
    required this.kind,
    required this.amount,
    required this.explanation,
    this.requiresApproval = false,
    this.sacrificedPurpose,
    this.sourceResourceId,
    this.sourceResourceLabel,
    this.ownerId,
    this.fundingGapCommitmentId,
    this.targetBalanceId,
    this.actionKnowledge = MitigationActionKnowledge.capacityOnly,
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
  final List<ResilienceLineItem> items;
  final List<PersonResilienceDetail> people;
  final List<FundingGap> fundingGaps;

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
    this.items = const [],
    this.people = const [],
    this.fundingGaps = const [],
  });

  double get flow => inflow - outflow;

  String get coverageTitle => phase == ResiliencePhase.realized
      ? 'Storico parziale'
      : 'Previsione parziale';

  String get coverageExplanation => phase == ResiliencePhase.realized
      ? 'Sono mostrati i fatti storici conosciuti; potrebbero mancare movimenti non registrati.'
      : 'Lo stato economico è separato dalla completezza delle informazioni.';
}
