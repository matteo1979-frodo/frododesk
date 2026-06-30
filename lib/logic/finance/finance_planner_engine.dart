import '../../models/frodo_observation.dart';
import '../../models/finance_recurring_item.dart';
import '../../stores/finance_store.dart';
import 'planner/planner_decision.dart';
import 'planner/planner_decision_engine.dart';
import 'planner/planner_recommendation_builder.dart';
import 'planner/planner_scenario_builder.dart';

class FinancePlannerResult {
  final String message;
  final String impact;
  final FrodoObservationLevel level;
  final int priority;
  final List<PlannerDecision> decisions;
  final List<FrodoObservationScenario> scenarios;
  final List<FrodoObservationRecommendation> recommendations;

  const FinancePlannerResult({
    required this.message,
    required this.impact,
    required this.level,
    required this.priority,
    required this.decisions,
    required this.scenarios,
    required this.recommendations,
  });
}

class FinancePlannerEngine {
  static FinancePlannerResult analyze({required FinanceStore financeStore}) {
    final now = DateTime.now();

    final matteoForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.matteo,
    );

    final chiaraForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.chiara,
    );

    final ownersUnderPressure = <FinancePaymentOwner>[
      if (matteoForecast < 0) FinancePaymentOwner.matteo,
      if (chiaraForecast < 0) FinancePaymentOwner.chiara,
    ];

    final familyForecast = matteoForecast + chiaraForecast;

    final totalFunds = financeStore.totalFunds();

    final usableFunds = financeStore.funds
        .where((fund) => !fund.protected)
        .fold<double>(0, (sum, fund) => sum + fund.amount);

    final protectedFunds = totalFunds - usableFunds;

    final pendingExpenses = financeStore.recurringItems
        .where((item) => !item.isIncome && !item.confirmed)
        .toList();

    final upcomingIncome =
        financeStore
            .futureRecurringItems()
            .where((item) => item.isIncome)
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final imminentIncome = upcomingIncome.where((item) {
      final days = item.nextDueDate.difference(now).inDays;
      return days >= 0 && days <= 7;
    }).toList();

    final imminentIncomeTotal = imminentIncome.fold<double>(
      0,
      (sum, item) => sum + item.expectedAmount,
    );

    final projectedAfterIncome = familyForecast + imminentIncomeTotal;
    final projectedWithFunds = familyForecast + usableFunds;

    final decisionItems = <FinanceRecurringItem>[
      ...pendingExpenses,
      ...imminentIncome,
    ];

    final decisions = PlannerDecisionEngine.analyze(
      items: decisionItems,
      balances: financeStore.balances,
      ownersUnderPressure: ownersUnderPressure,
    );

    final hasProblem = familyForecast < 0 || financeStore.isUnderPressure();
    final hasPersonalPressure = matteoForecast < 0 || chiaraForecast < 0;
    final hasImminentIncomeSolution =
        hasProblem && imminentIncome.isNotEmpty && projectedAfterIncome >= 0;

    final hasFundsSolution = hasProblem && usableFunds > 0;
    final hasOnlyProtectedFunds =
        hasProblem && usableFunds <= 0 && protectedFunds > 0;

    final message = _message(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
      hasOnlyProtectedFunds: hasOnlyProtectedFunds,
    );

    final impact = _impact(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
      hasOnlyProtectedFunds: hasOnlyProtectedFunds,
    );

    final level = _level(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
      hasOnlyProtectedFunds: hasOnlyProtectedFunds,
    );

    final priority = _priority(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
      hasOnlyProtectedFunds: hasOnlyProtectedFunds,
    );

    final scenarios = PlannerScenarioBuilder.build(
      decisions: decisions,
      familyForecast: familyForecast,
      projectedAfterIncome: hasImminentIncomeSolution
          ? projectedAfterIncome
          : null,
      projectedWithFunds: !hasImminentIncomeSolution && hasFundsSolution
          ? projectedWithFunds
          : null,
      hasOnlyProtectedFunds: hasOnlyProtectedFunds,
    );

    final recommendations = PlannerRecommendationBuilder.build(
      decisions: decisions,
    );

    return FinancePlannerResult(
      message: message,
      impact: impact,
      level: level,
      priority: priority,
      decisions: decisions,
      scenarios: scenarios,
      recommendations: recommendations,
    );
  }

  static String _message({
    required bool hasProblem,
    required bool hasPersonalPressure,
    required bool hasImminentIncomeSolution,
    required bool hasFundsSolution,
    required bool hasOnlyProtectedFunds,
  }) {
    if (hasImminentIncomeSolution) {
      return 'Conviene aspettare le entrate in arrivo.';
    }

    if (hasFundsSolution) {
      return 'I fondi utilizzabili possono aiutare, senza toccare quelli protetti.';
    }

    if (hasOnlyProtectedFunds) {
      return 'Ci sono fondi disponibili, ma risultano protetti: non vanno considerati come prima soluzione.';
    }

    if (hasProblem) {
      return 'Serve recuperare margine sulle spese manovrabili.';
    }

    if (hasPersonalPressure) {
      return 'La pressione è personale: evita di spostare spese bloccate.';
    }

    return 'La distribuzione attuale sembra sostenibile.';
  }

  static String _impact({
    required bool hasProblem,
    required bool hasPersonalPressure,
    required bool hasImminentIncomeSolution,
    required bool hasFundsSolution,
    required bool hasOnlyProtectedFunds,
  }) {
    if (hasImminentIncomeSolution) {
      return 'Le entrate imminenti possono riportare il mese in sicurezza senza usare fondi.';
    }

    if (hasFundsSolution) {
      return 'Il Planner considera prima i fondi non protetti e lascia intatte le protezioni dedicate.';
    }

    if (hasOnlyProtectedFunds) {
      return 'Usare fondi protetti ridurrebbe la resilienza futura: il Planner preferisce cercare alternative.';
    }

    if (hasProblem) {
      return 'La famiglia è in pressione: il Planner separa le spese bloccate da quelle su cui puoi agire.';
    }

    if (hasPersonalPressure) {
      return 'Il saldo familiare può restare positivo, ma non tutte le uscite possono cambiare conto.';
    }

    return 'Non emergono criticità immediate. Il Planner mantiene comunque attenzione su RID, priorità e spese critiche.';
  }

  static FrodoObservationLevel _level({
    required bool hasProblem,
    required bool hasPersonalPressure,
    required bool hasImminentIncomeSolution,
    required bool hasFundsSolution,
    required bool hasOnlyProtectedFunds,
  }) {
    if (hasImminentIncomeSolution || hasFundsSolution) {
      return FrodoObservationLevel.opportunity;
    }

    if (hasProblem || hasOnlyProtectedFunds) {
      return FrodoObservationLevel.problem;
    }

    if (hasPersonalPressure) {
      return FrodoObservationLevel.attention;
    }

    return FrodoObservationLevel.success;
  }

  static int _priority({
    required bool hasProblem,
    required bool hasPersonalPressure,
    required bool hasImminentIncomeSolution,
    required bool hasFundsSolution,
    required bool hasOnlyProtectedFunds,
  }) {
    if (hasProblem && !hasImminentIncomeSolution && !hasFundsSolution) {
      return 94;
    }

    if (hasImminentIncomeSolution) {
      return 92;
    }

    if (hasFundsSolution) {
      return 91;
    }

    if (hasOnlyProtectedFunds) {
      return 90;
    }

    if (hasPersonalPressure) {
      return 88;
    }

    return 42;
  }
}
