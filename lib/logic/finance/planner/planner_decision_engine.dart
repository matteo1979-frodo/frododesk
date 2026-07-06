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
        reason: _incomeReason(item),
        score: 850,
        decisionTrace: decisionTrace,
      );
    }

    if (_isAutomaticOrRid(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.keepCovered,
        reason: _automaticPaymentReason(item),
        score: 1000,
        decisionTrace: decisionTrace,
      );
    }

    if (_isProtected(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.keepCovered,
        reason: _protectedReason(item),
        score: 950,
        decisionTrace: decisionTrace,
      );
    }

    if (_isCritical(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.payNow,
        reason: _criticalReason(item),
        score: 900,
        decisionTrace: decisionTrace,
      );
    }

    if (_wouldBreakMinimumBalance(item, balances)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.monitor,
        reason: _minimumBalanceReason(item, balances),
        score: 875,
        decisionTrace: decisionTrace,
      );
    }

    if (_isAssignedToOwnerUnderPressure(item, ownersUnderPressure)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.monitor,
        reason: _ownerUnderPressureReason(item, ownersUnderPressure),
        score: 825,
        decisionTrace: decisionTrace,
      );
    }

    if (_canBeDelayed(item)) {
      return PlannerDecision(
        item: item,
        type: PlannerDecisionType.delay,
        reason: _delayReason(item),
        score: 500,
        decisionTrace: decisionTrace,
      );
    }

    return PlannerDecision(
      item: item,
      type: PlannerDecisionType.monitor,
      reason: _genericMonitorReason(item),
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
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.incomeForecast,
          level: PlannerDecisionTraceLevel.positive,
          message: _incomeReason(item),
        ),
      );
    } else {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.generic,
          level: PlannerDecisionTraceLevel.neutral,
          message:
              'Ho considerato ${item.name} come uscita prevista da €${_money(item.expectedAmount)}.',
        ),
      );
    }

    if (_isAutomaticOrRid(item)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.automaticPayment,
          level: PlannerDecisionTraceLevel.critical,
          message: _automaticPaymentReason(item),
        ),
      );
    }

    if (_isProtected(item)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.protectedExpense,
          level: PlannerDecisionTraceLevel.warning,
          message: _protectedReason(item),
        ),
      );
    }

    if (_isCritical(item)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.criticalExpense,
          level: PlannerDecisionTraceLevel.critical,
          message: _criticalReason(item),
        ),
      );
    }

    if (_wouldBreakMinimumBalance(item, balances)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.minimumBalance,
          level: PlannerDecisionTraceLevel.warning,
          message: _minimumBalanceReason(item, balances),
        ),
      );
    }

    if (_isAssignedToOwnerUnderPressure(item, ownersUnderPressure)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.ownerUnderPressure,
          level: PlannerDecisionTraceLevel.warning,
          message: _ownerUnderPressureReason(item, ownersUnderPressure),
        ),
      );
    }

    if (_canBeDelayed(item)) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.delayAllowed,
          level: PlannerDecisionTraceLevel.positive,
          message: _delayReason(item),
        ),
      );
    }

    if (trace.length == 1) {
      trace.add(
        PlannerDecisionTrace(
          reason: PlannerDecisionReason.generic,
          level: PlannerDecisionTraceLevel.neutral,
          message: _genericMonitorReason(item),
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
    final balance = _linkedBalance(item, balances);

    if (balance == null) return false;

    final projectedAmount = balance.availableAmount - item.expectedAmount;

    return projectedAmount <= balance.warningThreshold;
  }

  static FinanceBalance? _linkedBalance(
    FinanceRecurringItem item,
    List<FinanceBalance> balances,
  ) {
    final balanceId = item.balanceId;

    if (balanceId == null) return null;

    final matches = balances.where((b) => b.balanceId == balanceId).toList();

    if (matches.isEmpty) return null;

    final balance = matches.first;

    if (!balance.active) return null;

    return balance;
  }

  static String _incomeReason(FinanceRecurringItem item) {
    return 'Ho visto che ${item.name} è un’entrata prevista da €${_money(item.expectedAmount)} per ${_ownerLabel(item.paymentOwner)}. Prima di usare fondi o forzare pagamenti, conviene considerare questa entrata nel piano.';
  }

  static String _automaticPaymentReason(FinanceRecurringItem item) {
    return 'Ho visto che ${item.name} è collegata a un pagamento automatico o RID. Per questo non la considero una voce spostabile o rimandabile.';
  }

  static String _protectedReason(FinanceRecurringItem item) {
    return 'Ho visto che ${item.name} è una voce protetta. Preferisco non modificarla o consumarla se non strettamente necessario, perché serve a mantenere protezione economica.';
  }

  static String _criticalReason(FinanceRecurringItem item) {
    return 'Ho dato priorità a ${item.name}, perché è una spesa critica o obbligatoria da €${_money(item.expectedAmount)}. Prima vengono le voci che non possono essere lasciate indietro.';
  }

  static String _minimumBalanceReason(
    FinanceRecurringItem item,
    List<FinanceBalance> balances,
  ) {
    final balance = _linkedBalance(item, balances);

    if (balance == null) {
      return 'Ho visto che ${item.name} rischia di portare il conto collegato sotto la soglia minima di sicurezza.';
    }

    final before = balance.availableAmount;
    final after = before - item.expectedAmount;
    final owner = _personLabel(balance.personId);

    return 'Ho controllato ${balance.name} di $owner. Prima di ${item.name} risultano disponibili circa €${_money(before)}. Dopo questa uscita da €${_money(item.expectedAmount)} resterebbero circa €${_money(after)}, sotto la soglia minima impostata di €${_money(balance.warningThreshold)}.';
  }

  static String _ownerUnderPressureReason(
    FinanceRecurringItem item,
    List<FinancePaymentOwner> ownersUnderPressure,
  ) {
    final owners = ownersUnderPressure.map(_ownerLabel).join(', ');

    if (item.paymentOwner == FinancePaymentOwner.shared) {
      return 'Ho visto che ${item.name} è una spesa condivisa, ma almeno una persona è già in sofferenza economica ($owners). Prima di confermarla conviene valutare se il peso è distribuito bene.';
    }

    return 'Ho visto che ${item.name} pesa su ${_ownerLabel(item.paymentOwner)}, che risulta già in sofferenza economica. Prima di confermare questa uscita conviene valutare alternative.';
  }

  static String _delayReason(FinanceRecurringItem item) {
    return 'Ho visto che ${item.name} non è automatica, non è critica e può essere rimandata. Spostarla può aiutare a recuperare margine senza toccare le spese bloccate.';
  }

  static String _genericMonitorReason(FinanceRecurringItem item) {
    return 'Ho controllato ${item.name}, ma non ho trovato una regola forte che imponga di pagarla subito, rimandarla o bloccarla. Per ora la considero una voce da monitorare.';
  }

  static String _money(double value) {
    return value.toStringAsFixed(0);
  }

  static String _personLabel(String personId) {
    switch (personId) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'alice':
        return 'Alice';
      default:
        return personId;
    }
  }

  static String _ownerLabel(FinancePaymentOwner owner) {
    switch (owner) {
      case FinancePaymentOwner.matteo:
        return 'Matteo';
      case FinancePaymentOwner.chiara:
        return 'Chiara';
      case FinancePaymentOwner.shared:
        return 'Condiviso';
    }
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
