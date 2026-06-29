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
  final List<FrodoObservationScenario> scenarios;
  final List<FrodoObservationRecommendation> recommendations;

  const FinancePlannerResult({
    required this.message,
    required this.impact,
    required this.level,
    required this.priority,
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

    final familyForecast = matteoForecast + chiaraForecast;
    final totalFunds = financeStore.totalFunds();

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
    final projectedWithFunds = familyForecast + totalFunds;

    final decisionItems = <FinanceRecurringItem>[
      ...pendingExpenses,
      ...imminentIncome,
    ];

    final decisions = PlannerDecisionEngine.analyze(items: decisionItems);

    final hasProblem = familyForecast < 0 || financeStore.isUnderPressure();
    final hasPersonalPressure = matteoForecast < 0 || chiaraForecast < 0;
    final hasImminentIncomeSolution =
        hasProblem && imminentIncome.isNotEmpty && projectedAfterIncome >= 0;

    final hasFundsSolution = hasProblem && totalFunds > 0;

    final message = _message(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
    );

    final impact = _impact(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
    );

    final level = _level(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
    );

    final priority = _priority(
      hasProblem: hasProblem,
      hasPersonalPressure: hasPersonalPressure,
      hasImminentIncomeSolution: hasImminentIncomeSolution,
      hasFundsSolution: hasFundsSolution,
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
    );

    final recommendations = PlannerRecommendationBuilder.build(
      decisions: decisions,
    );

    return FinancePlannerResult(
      message: message,
      impact: impact,
      level: level,
      priority: priority,
      scenarios: scenarios,
      recommendations: recommendations,
    );
  }

  static String _message({
    required bool hasProblem,
    required bool hasPersonalPressure,
    required bool hasImminentIncomeSolution,
    required bool hasFundsSolution,
  }) {
    if (hasImminentIncomeSolution) {
      return 'Conviene aspettare le entrate in arrivo.';
    }

    if (hasFundsSolution) {
      return 'I fondi possono aiutare, ma solo sulle spese non rimandabili.';
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
  }) {
    if (hasImminentIncomeSolution) {
      return 'Le entrate imminenti possono riportare il mese in sicurezza senza usare fondi.';
    }

    if (hasFundsSolution) {
      return 'Prima di usare fondi, FrodoDesk distingue RID, spese critiche e spese rimandabili.';
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
  }) {
    if (hasImminentIncomeSolution || hasFundsSolution) {
      return FrodoObservationLevel.opportunity;
    }

    if (hasProblem) {
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

    if (hasPersonalPressure) {
      return 88;
    }

    return 42;
  }
}
