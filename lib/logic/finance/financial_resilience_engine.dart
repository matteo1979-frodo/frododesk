import '../../models/financial_resilience.dart';

class FinancialResilienceEngine {
  const FinancialResilienceEngine();

  List<ResilienceAssessment> assessYear({
    required int year,
    required DateTime referenceTime,
    required Iterable<FinancialResource> resources,
    required Iterable<FinancialTimelineEvent> futureEvents,
    required Iterable<HistoricalFinancialFact> historicalFacts,
    required bool futureIncomeKnown,
  }) {
    final resourceList = resources.where((item) => item.amount >= 0).toList();
    final events = <String, FinancialTimelineEvent>{
      for (final item in futureEvents.where((item) => !item.transfer))
        item.identity: item,
    }.values.toList();
    final facts = <String, HistoricalFinancialFact>{
      for (final item in historicalFacts.where((item) => !item.transfer))
        item.identity: item,
    }.values.toList();
    var liquidity = resourceList.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final result = <ResilienceAssessment>[];
    for (var monthIndex = 1; monthIndex <= 12; monthIndex++) {
      final month = DateTime(year, monthIndex);
      final phase =
          month.isBefore(DateTime(referenceTime.year, referenceTime.month))
          ? ResiliencePhase.realized
          : month.year == referenceTime.year &&
                month.month == referenceTime.month
          ? ResiliencePhase.current
          : ResiliencePhase.forecast;
      if (phase == ResiliencePhase.realized) {
        result.add(_realized(month, liquidity, facts, resourceList));
        continue;
      }
      final monthEvents = events
          .where((item) => item.fallsInMonth(month))
          .toList();
      final assessment = _forecast(
        month: month,
        phase: phase,
        opening: liquidity,
        resources: resourceList,
        monthEvents: monthEvents,
        allEvents: events,
        facts: facts,
        futureIncomeKnown: futureIncomeKnown,
      );
      result.add(assessment);
      liquidity = assessment.projectedClosingLiquidity;
    }
    return List.unmodifiable(result);
  }

  ResilienceAssessment _realized(
    DateTime month,
    double currentLiquidity,
    List<HistoricalFinancialFact> facts,
    List<FinancialResource> resources,
  ) {
    final monthFacts = facts
        .where(
          (item) =>
              item.date.year == month.year && item.date.month == month.month,
        )
        .toList();
    final income = monthFacts
        .where((item) => item.direction == FinancialEventDirection.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final outflow = monthFacts
        .where((item) => item.direction == FinancialEventDirection.outflow)
        .fold<double>(0, (sum, item) => sum + item.amount);
    return ResilienceAssessment(
      month: month,
      phase: ResiliencePhase.realized,
      status: ResilienceStatus.breathes,
      openingLiquidity: currentLiquidity,
      projectedClosingLiquidity: currentLiquidity,
      minimumProjectedLiquidity: currentLiquidity,
      inflow: income,
      outflow: outflow,
      fundCoverage: 0,
      unresolvedDeficit: 0,
      coverage: const InformationCoverage(
        futureIncomeKnown: false,
        exactEvents: 0,
        impreciseEvents: 0,
        unlocatedEvents: 0,
        knownAccountEvents: 0,
        totalEvents: 0,
      ),
      structuralNeed: _structuralNeed(facts, month),
      explanations: [
        'Mese realizzato: entrate €${income.toStringAsFixed(2)}, uscite €${outflow.toStringAsFixed(2)}.',
      ],
      alternatives: const [],
      items: monthFacts
          .map(
            (item) => ResilienceLineItem(
              identity: item.identity,
              label: item.label,
              amount: item.amount,
              direction: item.direction,
              date: item.date,
              ownerId: item.ownerId,
              balanceId: item.balanceId,
              balanceLabel: item.balanceLabel,
            ),
          )
          .toList(growable: false),
      people: _people(
        resources,
        monthFacts
            .map(
              (item) => ResilienceLineItem(
                identity: item.identity,
                label: item.label,
                amount: item.amount,
                direction: item.direction,
                date: item.date,
                ownerId: item.ownerId,
                balanceId: item.balanceId,
                balanceLabel: item.balanceLabel,
              ),
            )
            .toList(),
      ),
    );
  }

  ResilienceAssessment _forecast({
    required DateTime month,
    required ResiliencePhase phase,
    required double opening,
    required List<FinancialResource> resources,
    required List<FinancialTimelineEvent> monthEvents,
    required List<FinancialTimelineEvent> allEvents,
    required List<HistoricalFinancialFact> facts,
    required bool futureIncomeKnown,
  }) {
    final exact =
        monthEvents
            .where(
              (item) =>
                  item.temporalPrecision ==
                  FinancialTemporalPrecision.exactDate,
            )
            .toList()
          ..sort((a, b) => a.start!.compareTo(b.start!));
    final imprecise = monthEvents
        .where(
          (item) =>
              item.temporalPrecision == FinancialTemporalPrecision.window ||
              item.temporalPrecision == FinancialTemporalPrecision.month,
        )
        .toList();
    final unlocated = allEvents
        .where(
          (item) =>
              item.temporalPrecision == FinancialTemporalPrecision.unlocated,
        )
        .length;
    final income = monthEvents
        .where((item) => item.direction == FinancialEventDirection.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final outflow = monthEvents
        .where((item) => item.direction == FinancialEventDirection.outflow)
        .fold<double>(0, (sum, item) => sum + item.amount);
    var running = opening;
    var minimum = opening;
    final accountBalances = {
      for (final item in resources.where(
        (item) => item.kind != FinancialResourceKind.fund,
      ))
        item.id: item.amount,
    };
    final fundingGaps = <FundingGap>[];
    // Conservative bound: imprecise outflows precede imprecise incomes. This
    // does not claim a date; it exposes the worst ordering allowed by facts.
    for (final event in imprecise.where(
      (item) => item.direction == FinancialEventDirection.outflow,
    )) {
      running -= event.amount;
      if (running < minimum) minimum = running;
    }
    for (final event in exact) {
      running += event.direction == FinancialEventDirection.income
          ? event.amount
          : -event.amount;
      if (running < minimum) minimum = running;
      final balanceId = event.balanceId;
      if (balanceId != null && accountBalances.containsKey(balanceId)) {
        final previous = accountBalances[balanceId]!;
        final next =
            previous +
            (event.direction == FinancialEventDirection.income
                ? event.amount
                : -event.amount);
        accountBalances[balanceId] = next;
        if (event.direction == FinancialEventDirection.outflow && next < 0) {
          final available = previous.clamp(0, event.amount).toDouble();
          final resource = resources
              .where((item) => item.id == balanceId)
              .firstOrNull;
          fundingGaps.add(
            FundingGap(
              commitmentId: event.identity,
              commitmentLabel: event.label,
              targetBalanceId: balanceId,
              targetBalanceLabel: resource?.label ?? balanceId,
              ownerId: resource?.ownerId ?? event.ownerId,
              requiredAmount: event.amount,
              availableAmount: available,
              amount: event.amount - available,
              date: event.start,
            ),
          );
        }
      }
    }
    for (final event in imprecise.where(
      (item) => item.direction == FinancialEventDirection.income,
    )) {
      running += event.amount;
    }
    final closing = opening + income - outflow;
    final alternatives = <MitigationOption>[];
    var fundCoverage = 0.0;
    final totalGap = minimum < 0 ? -minimum : 0.0;
    var unresolved = totalGap;
    for (final event in monthEvents.where(
      (item) =>
          item.direction == FinancialEventDirection.outflow &&
          item.purposeKey != null,
    )) {
      final matching = resources.where(
        (item) =>
            item.kind == FinancialResourceKind.fund &&
            item.purposeKey == event.purposeKey,
      );
      final covered = matching
          .fold<double>(0, (sum, item) => sum + item.amount)
          .clamp(0, event.amount)
          .toDouble();
      fundCoverage += covered;
      if (covered > 0) {
        alternatives.add(
          MitigationOption(
            kind: MitigationKind.designatedFund,
            amount: covered,
            explanation:
                'Il Fondo destinato copre €${covered.toStringAsFixed(2)} di ${event.label}.',
          ),
        );
      }
    }
    if (totalGap <= .005 && fundingGaps.isNotEmpty) {
      final remainingCapacity = _alternativeCapacity(monthEvents, resources);
      for (final gap in fundingGaps) {
        unresolved += _alternatives(
          gap,
          monthEvents,
          resources,
          alternatives,
          remainingCapacity,
        );
      }
    }
    if (unresolved > .005 &&
        totalGap > .005 &&
        monthEvents.any(
          (item) => item.flexibility == FinancialFlexibility.flexible,
        )) {
      alternatives.add(
        MitigationOption(
          kind: MitigationKind.deferKnownFlexibleCommitment,
          amount: unresolved,
          explanation:
              'Un impegno esplicitamente flessibile può essere valutato per il rinvio.',
        ),
      );
      unresolved = 0;
    }
    final need = _structuralNeed(facts, month);
    final futureLoss = _futureStructuralLoss(month, allEvents);
    final explanations = <String>[];
    if (income - outflow < 0 && unresolved <= .005) {
      explanations.add(
        'Il flusso del mese è negativo di €${(outflow - income).toStringAsFixed(2)}, ma gli impegni conosciuti restano coperti.',
      );
    }
    if (!futureIncomeKnown) {
      explanations.add(
        'Non risultano entrate future registrate: la previsione è parziale, non pari a zero reddito reale.',
      );
    }
    if (imprecise.isNotEmpty) {
      explanations.add(
        '${imprecise.length} eventi hanno timing impreciso; il minimo usa un limite conservativo senza inventare un giorno.',
      );
    }
    if (unresolved > .005) {
      explanations.add(
        'Con risorse e alternative conosciute non risultano coperti €${unresolved.toStringAsFixed(2)}.',
      );
    }
    for (final gap in fundingGaps) {
      explanations.add(
        '${gap.commitmentLabel} richiede €${gap.requiredAmount.toStringAsFixed(2)} '
        'su ${gap.targetBalanceLabel}, dove risultano '
        '€${gap.availableAmount.toStringAsFixed(2)}: mancano '
        '€${gap.amount.toStringAsFixed(2)}.',
      );
    }
    if (futureLoss > opening && unresolved <= .005) {
      explanations.add(
        'La traiettoria strutturale conosciuta consumerebbe la liquidità disponibile nell’orizzonte.',
      );
    }
    final status = unresolved > .005
        ? ResilienceStatus.suffers
        : minimum < 0 || alternatives.isNotEmpty || futureLoss > opening
        ? ResilienceStatus.attention
        : ResilienceStatus.breathes;
    if (explanations.isEmpty) {
      explanations.add(
        'Gli impegni economicamente collocati risultano coperti dalle risorse conosciute.',
      );
    }
    return ResilienceAssessment(
      month: month,
      phase: phase,
      status: status,
      openingLiquidity: opening,
      projectedClosingLiquidity: closing,
      minimumProjectedLiquidity: minimum,
      inflow: income,
      outflow: outflow,
      fundCoverage: fundCoverage,
      unresolvedDeficit: unresolved,
      coverage: InformationCoverage(
        futureIncomeKnown: futureIncomeKnown,
        exactEvents: exact.length,
        impreciseEvents: imprecise.length,
        unlocatedEvents: unlocated,
        knownAccountEvents: monthEvents
            .where((item) => item.balanceId != null)
            .length,
        totalEvents: monthEvents.length,
      ),
      structuralNeed: need,
      explanations: List.unmodifiable(explanations),
      alternatives: List.unmodifiable(alternatives),
      items: monthEvents
          .map(
            (item) => ResilienceLineItem(
              identity: item.identity,
              label: item.label,
              amount: item.amount,
              direction: item.direction,
              date: item.start,
              ownerId: item.ownerId,
              balanceId: item.balanceId,
              balanceLabel: resources
                  .where((resource) => resource.id == item.balanceId)
                  .firstOrNull
                  ?.label,
            ),
          )
          .toList(growable: false),
      people: _people(
        resources,
        monthEvents
            .map(
              (item) => ResilienceLineItem(
                identity: item.identity,
                label: item.label,
                amount: item.amount,
                direction: item.direction,
                date: item.start,
                ownerId: item.ownerId,
                balanceId: item.balanceId,
                balanceLabel: resources
                    .where((resource) => resource.id == item.balanceId)
                    .firstOrNull
                    ?.label,
              ),
            )
            .toList(),
      ),
      fundingGaps: List.unmodifiable(fundingGaps),
    );
  }

  double _alternatives(
    FundingGap fundingGap,
    List<FinancialTimelineEvent> events,
    List<FinancialResource> resources,
    List<MitigationOption> options,
    Map<String, double> remainingCapacity,
  ) {
    var gap = fundingGap.amount;
    double use(
      Iterable<FinancialResource> candidates,
      MitigationKind kind,
      String text, {
      bool approval = false,
    }) {
      for (final candidate in candidates) {
        final available = remainingCapacity[candidate.id] ?? 0;
        final amount = available.clamp(0, gap).toDouble();
        if (amount <= 0) continue;
        options.add(
          MitigationOption(
            kind: kind,
            amount: amount,
            explanation: kind == MitigationKind.sameOwnerBalance
                ? _sameOwnerCapacityExplanation(candidate, fundingGap, amount)
                : '$text ${candidate.label}: €${amount.toStringAsFixed(2)}.',
            requiresApproval: approval,
            sourceResourceId: candidate.id,
            sourceResourceLabel: candidate.label,
            ownerId: candidate.ownerId,
            fundingGapCommitmentId: fundingGap.commitmentId,
            targetBalanceId: fundingGap.targetBalanceId,
            actionKnowledge: MitigationActionKnowledge.capacityOnly,
          ),
        );
        remainingCapacity[candidate.id] = available - amount;
        gap -= amount;
        if (gap <= .005) break;
      }
      return gap;
    }

    use(
      resources.where(
        (item) =>
            item.kind != FinancialResourceKind.fund &&
            item.id != fundingGap.targetBalanceId &&
            item.ownerId == fundingGap.ownerId,
      ),
      MitigationKind.sameOwnerBalance,
      'Funding gap sul conto richiesto. Capacità disponibile su',
    );
    if (gap > .005) {
      use(
        resources.where(
          (item) =>
              item.kind == FinancialResourceKind.fund &&
              !item.protected &&
              item.id != fundingGap.targetBalanceId,
        ),
        MitigationKind.reallocateFund,
        'Un Fondo non protetto può essere riallocato, sacrificandone la destinazione.',
      );
    }
    if (gap > .005) {
      use(
        resources.where(
          (item) =>
              item.kind != FinancialResourceKind.fund &&
              item.ownerId != null &&
              item.ownerId != fundingGap.ownerId,
        ),
        MitigationKind.otherOwnerRequiresApproval,
        'Risorse di un altro membro sono potenzialmente disponibili, ma richiedono consenso.',
        approval: true,
      );
    }
    if (gap > .005 &&
        events.any(
          (item) => item.flexibility == FinancialFlexibility.flexible,
        )) {
      options.add(
        MitigationOption(
          kind: MitigationKind.deferKnownFlexibleCommitment,
          amount: gap,
          explanation:
              'Un impegno esplicitamente flessibile può essere valutato per il rinvio.',
        ),
      );
      gap = 0;
    }
    if (gap > .005) {
      options.add(
        MitigationOption(
          kind: MitigationKind.unresolved,
          amount: gap,
          explanation: 'Nessuna alternativa conosciuta copre il deficit.',
        ),
      );
    }
    return gap;
  }

  String _sameOwnerCapacityExplanation(
    FinancialResource source,
    FundingGap fundingGap,
    double amount,
  ) {
    final owner = _displayOwner(source.ownerId);
    final capacity = owner == null
        ? 'È disponibile una capacità di €${amount.toStringAsFixed(2)} su ${source.label}'
        : '$owner dispone di €${amount.toStringAsFixed(2)} su ${source.label}';
    return '$capacity. Non è però certificato che questa disponibilità possa '
        'essere trasferita direttamente a ${fundingGap.targetBalanceLabel}.';
  }

  String? _displayOwner(String? ownerId) {
    final value = ownerId?.trim();
    if (value == null || value.isEmpty) return null;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Map<String, double> _alternativeCapacity(
    List<FinancialTimelineEvent> events,
    List<FinancialResource> resources,
  ) => {
    for (final resource in resources)
      resource.id:
          (resource.amount -
                  events
                      .where(
                        (event) =>
                            event.direction ==
                                FinancialEventDirection.outflow &&
                            event.balanceId == resource.id,
                      )
                      .fold<double>(0, (sum, event) => sum + event.amount))
              .clamp(0, resource.amount)
              .toDouble(),
  };

  static List<PersonResilienceDetail> _people(
    List<FinancialResource> resources,
    List<ResilienceLineItem> items,
  ) {
    final owners = <String>{
      ...resources.map((item) => item.ownerId).whereType<String>(),
      ...items.map((item) => item.ownerId).whereType<String>(),
    }.toList()..sort();
    return owners
        .map(
          (owner) => PersonResilienceDetail(
            ownerId: owner,
            resources: resources
                .where((item) => item.ownerId == owner)
                .toList(growable: false),
            items: items
                .where((item) => item.ownerId == owner)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  static StructuralNeedEstimate _structuralNeed(
    List<HistoricalFinancialFact> facts,
    DateTime target,
  ) {
    final ordinary = facts.where(
      (item) =>
          item.direction == FinancialEventDirection.outflow &&
          item.structural &&
          !item.extraordinary,
    );
    final byMonth = <String, double>{};
    for (final fact in ordinary) {
      final key = '${fact.date.year}-${fact.date.month}';
      byMonth[key] = (byMonth[key] ?? 0) + fact.amount;
    }
    final sameMonth = ordinary
        .where((item) => item.date.month == target.month)
        .fold<Map<int, double>>({}, (map, item) {
          map[item.date.year] = (map[item.date.year] ?? 0) + item.amount;
          return map;
        });
    double? average(Iterable<double> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    return StructuralNeedEstimate(
      monthlyOrdinaryNeed: average(byMonth.values),
      seasonalNeed: sameMonth.length >= 2 ? average(sameMonth.values) : null,
      observedMonths: byMonth.length,
      sameMonthYears: sameMonth.length,
    );
  }

  double _futureStructuralLoss(
    DateTime month,
    List<FinancialTimelineEvent> events,
  ) =>
      events
          .where(
            (item) =>
                item.structural &&
                item.direction == FinancialEventDirection.outflow &&
                (item.start == null || !item.start!.isBefore(month)),
          )
          .fold<double>(0, (sum, item) => sum + item.amount) -
      events
          .where(
            (item) =>
                item.structural &&
                item.direction == FinancialEventDirection.income &&
                (item.start == null || !item.start!.isBefore(month)),
          )
          .fold<double>(0, (sum, item) => sum + item.amount);
}
