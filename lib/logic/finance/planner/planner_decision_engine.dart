import '../../../models/finance_balance.dart';
import '../../../models/finance_recurring_item.dart';
import 'planner_decision.dart';

class PlannerDecisionEngine {
  static List<PlannerDecision> analyze({
    required List<FinanceRecurringItem> items,
    List<FinanceBalance> balances = const [],
    List<FinancePaymentOwner> ownersUnderPressure = const [],
  }) {
    final decisions =
        items
            .map(
              (item) => _analyzeItem(
                item,
                balances: balances,
                ownersUnderPressure: ownersUnderPressure,
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return decisions;
  }

  static PlannerDecision _analyzeItem(
    FinanceRecurringItem item, {
    required List<FinanceBalance> balances,
    required List<FinancePaymentOwner> ownersUnderPressure,
  }) {
    final decisionTrace = _buildDecisionTrace(
      item,
      balances: balances,
      ownersUnderPressure: ownersUnderPressure,
    );

    if (item.isIncome) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.waitIncome,
        reason: 'Entrata prevista: va considerata prima di usare fondi.',
        score: 850,
        decisionTrace: decisionTrace,
      );
    }

    if (_isAutomaticOrRid(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.keepCovered,
        reason: 'RID/addebito automatico: non va spostato o rimandato.',
        score: 1000,
        decisionTrace: decisionTrace,
      );
    }

    if (_isProtected(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.keepCovered,
        reason:
            'Voce protetta: rappresenta una protezione economica e non dovrebbe essere utilizzata se non strettamente necessario.',
        score: 950,
        decisionTrace: decisionTrace,
      );
    }

    if (_isCritical(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.payNow,
        reason: 'Spesa critica o obbligatoria: va messa tra le priorità.',
        score: 900,
        decisionTrace: decisionTrace,
      );
    }

    if (_wouldBreakMinimumBalance(item, balances)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.monitor,
        reason:
            'Questa uscita rischia di portare il conto collegato sotto la soglia minima di sicurezza.',
        score: 875,
        decisionTrace: decisionTrace,
      );
    }

    if (_isAssignedToOwnerUnderPressure(item, ownersUnderPressure)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.monitor,
        reason:
            'Questa uscita pesa su una persona già in sofferenza economica: prima di confermarla valuta se esistono alternative.',
        score: 825,
        decisionTrace: decisionTrace,
      );
    }

    if (_canBeDelayed(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.delay,
        reason: 'Spesa rimandabile: può aiutare a recuperare margine.',
        score: 500,
        decisionTrace: decisionTrace,
      );
    }

    return PlannerDecision(
      item: item,
      type: PlannerDecisionType.monitor,
      reason: 'Spesa da monitorare: non ha una regola forte associata.',
      score: 300,
      decisionTrace: decisionTrace,
    );
  }

  static List<PlannerDecisionTrace> _buildDecisionTrace(
    FinanceRecurringItem item, {
    required List<FinanceBalance> balances,
    required List<FinancePaymentOwner> ownersUnderPressure,
  }) {
    final trace = <PlannerDecisionTrace>[];

    if (item.isIncome) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.incomeForecast,
          level: PlannerDecisionTraceLevel.positive,
          message: 'La voce è un’entrata prevista.',
        ),
      );
    } else {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.generic,
          level: PlannerDecisionTraceLevel.neutral,
          message: 'La voce è un’uscita prevista.',
        ),
      );
    }

    if (_isAutomaticOrRid(item)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.automaticPayment,
          level: PlannerDecisionTraceLevel.critical,
          message:
              'La voce risulta collegata a RID o addebito automatico: non va trattata come spostabile.',
        ),
      );
    }

    if (_isProtected(item)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.protectedExpense,
          level: PlannerDecisionTraceLevel.warning,
          message:
              'La voce è protetta: consumarla o modificarla può ridurre la resilienza economica.',
        ),
      );
    }

    if (_isCritical(item)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.criticalExpense,
          level: PlannerDecisionTraceLevel.critical,
          message:
              'La voce ha priorità critica o obbligatoria e deve essere valutata prima delle spese manovrabili.',
        ),
      );
    }

    if (_wouldBreakMinimumBalance(item, balances)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.minimumBalance,
          level: PlannerDecisionTraceLevel.warning,
          message:
              'Il conto collegato rischia di scendere sotto la soglia minima di sicurezza.',
        ),
      );
    }

    if (_isAssignedToOwnerUnderPressure(item, ownersUnderPressure)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.ownerUnderPressure,
          level: PlannerDecisionTraceLevel.warning,
          message: 'La voce pesa su una persona già in sofferenza economica.',
        ),
      );
    }

    if (_canBeDelayed(item)) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.delayAllowed,
          level: PlannerDecisionTraceLevel.positive,
          message:
              'La voce è manovrabile: può essere valutata come rimandabile.',
        ),
      );
    }

    if (trace.length == 1) {
      trace.add(
        const PlannerDecisionTrace(
          reason: PlannerDecisionReason.generic,
          level: PlannerDecisionTraceLevel.neutral,
          message: 'Non sono emerse regole forti aggiuntive per questa voce.',
        ),
      );
    }

    return trace;
  }

  static bool _isAutomaticOrRid(FinanceRecurringItem item) {
    final method = item.paymentMethod.name.toLowerCase();

    return !item.requiresManualConfirmation ||
        method.contains('rid') ||
        method.contains('automatic') ||
        method.contains('addebito');
  }

  static bool _isProtected(FinanceRecurringItem item) {
    return item.protectionLevel == FinanceProtectionLevel.protected ||
        item.protectionLevel == FinanceProtectionLevel.critical;
  }

  static bool _isCritical(FinanceRecurringItem item) {
    return item.mandatory ||
        item.paymentPriority == FinancePaymentPriority.critical ||
        item.protectionLevel == FinanceProtectionLevel.critical;
  }

  static bool _wouldBreakMinimumBalance(
    FinanceRecurringItem item,
    List<FinanceBalance> balances,
  ) {
    final balanceId = item.balanceId;

    if (balanceId == null) return false;

    final balance = balances.where((b) => b.balanceId == balanceId).firstOrNull;

    if (balance == null) return false;
    if (!balance.active) return false;

    final projectedAmount = balance.availableAmount - item.expectedAmount;

    return projectedAmount <= balance.warningThreshold;
  }

  static bool _isAssignedToOwnerUnderPressure(
    FinanceRecurringItem item,
    List<FinancePaymentOwner> ownersUnderPressure,
  ) {
    if (ownersUnderPressure.isEmpty) return false;

    if (ownersUnderPressure.contains(item.paymentOwner)) {
      return true;
    }

    if (item.paymentOwner == FinancePaymentOwner.shared) {
      return ownersUnderPressure.isNotEmpty;
    }

    if (item.hasCustomSplits) {
      for (final split in item.splits) {
        final splitOwner = FinancePaymentOwner.values.firstWhere(
          (owner) => owner.name == split.personId,
          orElse: () => FinancePaymentOwner.shared,
        );

        if (ownersUnderPressure.contains(splitOwner)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _canBeDelayed(FinanceRecurringItem item) {
    if (_isAutomaticOrRid(item)) return false;
    if (_isProtected(item)) return false;
    if (_isCritical(item)) return false;
    if (!item.behaviorProfile.canBeDelayed) return false;

    return true;
  }
}
