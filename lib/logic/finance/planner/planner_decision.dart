import '../../../models/finance_recurring_item.dart';

enum PlannerDecisionType {
  payNow,
  keepCovered,
  waitIncome,
  delay,
  useFunds,
  blocked,
  monitor,
}

/// Identifica la regola che ha contribuito alla decisione.
/// La UI e gli altri motori devono usare questo enum,
/// mai confrontare direttamente le stringhe.
enum PlannerDecisionReason {
  incomeForecast,
  automaticPayment,
  protectedExpense,
  criticalExpense,
  minimumBalance,
  ownerUnderPressure,
  delayAllowed,
  usableFunds,
  protectedFunds,
  sharedPayment,
  familyPriority,
  personalPriority,
  suggestedAccount,
  thirteenthSalary,
  fourteenthSalary,
  productionBonus,
  extraordinaryIncome,
  opportunity,
  generic,
}

enum PlannerDecisionTraceLevel { positive, neutral, warning, critical }

class PlannerDecisionReasonMetadata {
  final String title;
  final String icon;
  final PlannerDecisionTraceLevel level;

  const PlannerDecisionReasonMetadata({
    required this.title,
    required this.icon,
    required this.level,
  });
}

extension PlannerDecisionReasonExtension on PlannerDecisionReason {
  PlannerDecisionReasonMetadata get metadata {
    switch (this) {
      case PlannerDecisionReason.incomeForecast:
        return const PlannerDecisionReasonMetadata(
          title: 'Entrata imminente',
          icon: '📅',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.automaticPayment:
        return const PlannerDecisionReasonMetadata(
          title: 'Pagamento automatico',
          icon: '🚫',
          level: PlannerDecisionTraceLevel.critical,
        );

      case PlannerDecisionReason.protectedExpense:
        return const PlannerDecisionReasonMetadata(
          title: 'Voce protetta',
          icon: '🛡️',
          level: PlannerDecisionTraceLevel.warning,
        );

      case PlannerDecisionReason.criticalExpense:
        return const PlannerDecisionReasonMetadata(
          title: 'Spesa prioritaria',
          icon: '🎯',
          level: PlannerDecisionTraceLevel.critical,
        );

      case PlannerDecisionReason.minimumBalance:
        return const PlannerDecisionReasonMetadata(
          title: 'Saldo minimo',
          icon: '🏦',
          level: PlannerDecisionTraceLevel.warning,
        );

      case PlannerDecisionReason.ownerUnderPressure:
        return const PlannerDecisionReasonMetadata(
          title: 'Pressione personale',
          icon: '👤',
          level: PlannerDecisionTraceLevel.warning,
        );

      case PlannerDecisionReason.delayAllowed:
        return const PlannerDecisionReasonMetadata(
          title: 'Può essere rimandata',
          icon: '⏳',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.usableFunds:
        return const PlannerDecisionReasonMetadata(
          title: 'Fondi utilizzabili',
          icon: '💰',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.protectedFunds:
        return const PlannerDecisionReasonMetadata(
          title: 'Fondi protetti',
          icon: '🛡️',
          level: PlannerDecisionTraceLevel.warning,
        );

      case PlannerDecisionReason.sharedPayment:
        return const PlannerDecisionReasonMetadata(
          title: 'Pagamento condiviso',
          icon: '👨‍👩‍👧',
          level: PlannerDecisionTraceLevel.neutral,
        );

      case PlannerDecisionReason.familyPriority:
        return const PlannerDecisionReasonMetadata(
          title: 'Priorità familiare',
          icon: '⚖️',
          level: PlannerDecisionTraceLevel.critical,
        );

      case PlannerDecisionReason.personalPriority:
        return const PlannerDecisionReasonMetadata(
          title: 'Priorità personale',
          icon: '👤',
          level: PlannerDecisionTraceLevel.warning,
        );

      case PlannerDecisionReason.suggestedAccount:
        return const PlannerDecisionReasonMetadata(
          title: 'Conto consigliato',
          icon: '💳',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.thirteenthSalary:
        return const PlannerDecisionReasonMetadata(
          title: 'Tredicesima',
          icon: '💶',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.fourteenthSalary:
        return const PlannerDecisionReasonMetadata(
          title: 'Quattordicesima',
          icon: '💶',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.productionBonus:
        return const PlannerDecisionReasonMetadata(
          title: 'Premio produzione',
          icon: '🎁',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.extraordinaryIncome:
        return const PlannerDecisionReasonMetadata(
          title: 'Entrata straordinaria',
          icon: '📈',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.opportunity:
        return const PlannerDecisionReasonMetadata(
          title: 'Opportunità economica',
          icon: '📈',
          level: PlannerDecisionTraceLevel.positive,
        );

      case PlannerDecisionReason.generic:
        return const PlannerDecisionReasonMetadata(
          title: 'Valutazione generale',
          icon: '💡',
          level: PlannerDecisionTraceLevel.neutral,
        );
    }
  }
}

class PlannerDecisionTrace {
  final PlannerDecisionReason reason;
  final PlannerDecisionTraceLevel level;
  final String message;

  /// Se false la motivazione resta disponibile per il motore
  /// ma non viene mostrata nel blocco "Come ha ragionato Frodo".
  final bool visibleToUser;

  const PlannerDecisionTrace({
    required this.reason,
    required this.level,
    required this.message,
    this.visibleToUser = true,
  });
}

class PlannerDecision {
  final FinanceRecurringItem item;
  final PlannerDecisionType type;
  final String reason;
  final int score;

  /// Tutte le valutazioni effettuate dal Planner
  /// che hanno portato alla decisione finale.
  final List<PlannerDecisionTrace> decisionTrace;

  const PlannerDecision({
    required this.item,
    required this.type,
    required this.reason,
    required this.score,
    this.decisionTrace = const [],
  });

  bool get isActionable {
    return type == PlannerDecisionType.payNow ||
        type == PlannerDecisionType.delay ||
        type == PlannerDecisionType.useFunds;
  }

  bool get isBlocked {
    return type == PlannerDecisionType.blocked ||
        type == PlannerDecisionType.keepCovered;
  }

  bool get hasDecisionTrace => decisionTrace.isNotEmpty;
}
