import '../../core/frododesk_modules.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/frodo_observation.dart';
import '../../stores/finance_store.dart';
import 'finance_planner_engine.dart';

class FinanceObservationReader {
  static List<FrodoObservation> analyze(FinanceStore financeStore) {
    final now = DateTime.now();
    final observations = <FrodoObservation>[];

    _buildUpcomingDeadlinesObservation(
      financeStore: financeStore,
      now: now,
      observations: observations,
    );

    _buildEconomicSituationObservation(
      financeStore: financeStore,
      now: now,
      observations: observations,
    );

    _buildFundsObservation(
      financeStore: financeStore,
      now: now,
      observations: observations,
    );

    _buildPlannerObservation(
      financeStore: financeStore,
      now: now,
      observations: observations,
    );

    _buildUpcomingIncomeObservation(
      financeStore: financeStore,
      now: now,
      observations: observations,
    );

    return observations;
  }

  static void _buildUpcomingDeadlinesObservation({
    required FinanceStore financeStore,
    required DateTime now,
    required List<FrodoObservation> observations,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final pendingItems =
        financeStore.recurringItems
            .where((item) => !item.isIncome && !item.confirmed)
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    if (pendingItems.isEmpty) return;

    DateTime dayOf(FinanceRecurringItem item) {
      return DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );
    }

    double totalOf(List<FinanceRecurringItem> items) {
      return items.fold<double>(0, (sum, item) => sum + item.expectedAmount);
    }

    String dateOf(FinanceRecurringItem item) {
      final day = item.nextDueDate.day.toString().padLeft(2, '0');
      final month = item.nextDueDate.month.toString().padLeft(2, '0');
      return '$day/$month';
    }

    String itemLine(FinanceRecurringItem item) {
      return '• ${item.name}: -€${item.expectedAmount.toStringAsFixed(0)} (${dateOf(item)})';
    }

    String section({
      required String icon,
      required String title,
      required List<FinanceRecurringItem> items,
      String emptyLabel = '✅ Nessuna',
    }) {
      if (items.isEmpty) {
        return '$icon $title\n$emptyLabel';
      }

      final count = items.length;
      final total = totalOf(items);
      final allItems = items.map(itemLine).join('\n');

      return '$icon $title\n$count scadenze • €${total.toStringAsFixed(0)}\n$allItems';
    }

    final overdue = pendingItems.where((item) {
      return dayOf(item).isBefore(today);
    }).toList();

    final next7Days = pendingItems.where((item) {
      final dueDay = dayOf(item);
      return !dueDay.isBefore(today) && !dueDay.isAfter(endOfWeek);
    }).toList();

    final thisMonth = pendingItems.where((item) {
      final dueDay = dayOf(item);
      return dueDay.isAfter(endOfWeek) && !dueDay.isAfter(endOfMonth);
    }).toList();

    final future = pendingItems.where((item) {
      return dayOf(item).isAfter(endOfMonth);
    }).toList();

    final totalPending = totalOf(pendingItems);
    final overdueTotal = totalOf(overdue);
    final next7Total = totalOf(next7Days);
    final futureTotal = totalOf(future);

    final hasOverdue = overdue.isNotEmpty;
    final hasHeavyWeek = next7Total >= 500;

    final message = hasOverdue
        ? 'Priorità oggi: ${overdue.length} scadenze già in ritardo per €${overdueTotal.toStringAsFixed(0)}.'
        : next7Days.isNotEmpty
        ? 'Nei prossimi 7 giorni hai ${next7Days.length} scadenze per €${next7Total.toStringAsFixed(0)}.'
        : 'Nessuna scadenza urgente. Totale aperto: €${totalPending.toStringAsFixed(0)}.';

    final impact = hasOverdue
        ? 'Per rimettere in ordine le scadenze devi gestire prima i pagamenti già scaduti.'
        : hasHeavyWeek
        ? 'La settimana concentra molte uscite: conviene controllare la disponibilità prima di confermare nuovi pagamenti.'
        : future.isNotEmpty
        ? 'Non ci sono ritardi immediati, ma restano €${futureTotal.toStringAsFixed(0)} di scadenze future da pianificare.'
        : 'Le scadenze aperte non mostrano pressione immediata.';

    observations.add(
      FrodoObservation(
        id: 'finance_deadlines_${now.year}_${now.month}',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Scadenze',
        message: message,
        details:
            'Priorità oggi\n${section(icon: '🔴', title: 'In ritardo', items: overdue)}\n\n'
            'Da controllare a breve\n${section(icon: '🟡', title: 'Tra oggi e 7 giorni', items: next7Days)}\n\n'
            'Resto del mese\n${section(icon: '🟢', title: 'Entro il mese', items: thisMonth)}\n\n'
            'Da pianificare\n${section(icon: '🔵', title: 'Dopo questo mese', items: future)}',
        impact: impact,
        priority: hasOverdue
            ? 96
            : hasHeavyWeek
            ? 90
            : 88,
        level: hasOverdue
            ? FrodoObservationLevel.problem
            : FrodoObservationLevel.attention,
        createdAt: now,
      ),
    );
  }

  static void _buildEconomicSituationObservation({
    required FinanceStore financeStore,
    required DateTime now,
    required List<FrodoObservation> observations,
  }) {
    final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    final matteoForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.matteo,
    );

    final chiaraForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.chiara,
    );

    final familyForecast = matteoForecast + chiaraForecast;

    final hasPersonalPressure = matteoForecast < 0 || chiaraForecast < 0;
    final hasFamilyPressure =
        familyForecast < 0 || financeStore.isUnderPressure();

    final level = hasFamilyPressure
        ? FrodoObservationLevel.problem
        : hasPersonalPressure
        ? FrodoObservationLevel.attention
        : FrodoObservationLevel.success;

    final priority = hasFamilyPressure
        ? 94
        : hasPersonalPressure
        ? 90
        : 45;

    final message = hasFamilyPressure
        ? 'La famiglia è in pressione economica prevista.'
        : hasPersonalPressure
        ? 'Uno dei conti personali entra in sofferenza.'
        : 'La situazione economica prevista resta positiva.';

    final impact = hasFamilyPressure
        ? 'Serve attenzione: la distribuzione attuale delle entrate e uscite non copre completamente il mese.'
        : hasPersonalPressure
        ? 'Il saldo familiare può restare positivo, ma la distribuzione tra i conti crea sofferenza personale.'
        : 'La distribuzione attuale non genera sofferenza economica immediata.';

    observations.add(
      FrodoObservation(
        id: 'finance_economic_situation_$monthKey',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Situazione economica',
        message: message,
        details:
            'Matteo: €${matteoForecast.toStringAsFixed(0)}\nChiara: €${chiaraForecast.toStringAsFixed(0)}\nFamiglia: €${familyForecast.toStringAsFixed(0)}',
        impact: impact,
        priority: priority,
        level: level,
        createdAt: now,
      ),
    );
  }

  static void _buildFundsObservation({
    required FinanceStore financeStore,
    required DateTime now,
    required List<FrodoObservation> observations,
  }) {
    if (financeStore.funds.isEmpty) return;

    final totalFunds = financeStore.totalFunds();

    final protectedAmount = financeStore.funds
        .where((f) => f.protected)
        .fold<double>(0, (sum, f) => sum + f.amount);

    final availableAmount = financeStore.funds
        .where((f) => !f.protected)
        .fold<double>(0, (sum, f) => sum + f.amount);

    final activeFunds = financeStore.funds.where((f) => f.amount > 0).length;
    final emptyFunds = financeStore.funds.where((f) => f.amount <= 0).length;
    final protectedFunds = financeStore.funds.where((f) => f.protected).length;
    final unprotectedFunds = financeStore.funds
        .where((f) => !f.protected)
        .length;

    String icon(double amount) {
      if (amount <= 0) return '🔴';
      if (amount < 500) return '🟡';
      return '🟢';
    }

    String status(double amount) {
      if (amount <= 0) return 'Nessuna copertura';
      if (amount < 500) return 'Copertura bassa';
      if (amount < 1500) return 'Copertura discreta';
      return 'Copertura buona';
    }

    final sortedFunds = [...financeStore.funds]
      ..sort((a, b) {
        final protectedCompare = b.protected.toString().compareTo(
          a.protected.toString(),
        );

        if (protectedCompare != 0) return protectedCompare;

        return b.amount.compareTo(a.amount);
      });

    final details = sortedFunds
        .map(
          (fund) =>
              '${icon(fund.amount)} ${fund.name}: '
              '€${fund.amount.toStringAsFixed(0)} '
              '(${status(fund.amount)})',
        )
        .join('\n');

    observations.add(
      FrodoObservation(
        id: 'finance_funds_${now.year}_${now.month}',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Stato fondi',
        message:
            'Totale fondi €${totalFunds.toStringAsFixed(0)} '
            '(Protetti €${protectedAmount.toStringAsFixed(0)} • '
            'Disponibili €${availableAmount.toStringAsFixed(0)}).',
        details: details,
        impact:
            '$activeFunds fondi attivi • '
            '$emptyFunds da completare • '
            '$protectedFunds protetti • '
            '$unprotectedFunds utilizzabili.',
        priority: totalFunds > 0 ? 50 : 85,
        level: totalFunds > 0
            ? FrodoObservationLevel.info
            : FrodoObservationLevel.attention,
        createdAt: now,
      ),
    );
  }

  static void _buildPlannerObservation({
    required FinanceStore financeStore,
    required DateTime now,
    required List<FrodoObservation> observations,
  }) {
    final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    final matteoForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.matteo,
    );

    final chiaraForecast = financeStore.availableThisMonthForOwner(
      FinancePaymentOwner.chiara,
    );

    final familyForecast = matteoForecast + chiaraForecast;
    final totalFunds = financeStore.totalFunds();

    final planner = FinancePlannerEngine.analyze(financeStore: financeStore);

    observations.add(
      FrodoObservation(
        id: 'finance_planner_$monthKey',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Piano consigliato',
        message: planner.message,
        details:
            'Matteo: €${matteoForecast.toStringAsFixed(0)}\nChiara: €${chiaraForecast.toStringAsFixed(0)}\nFamiglia: €${familyForecast.toStringAsFixed(0)}\nFondi: €${totalFunds.toStringAsFixed(0)}',
        impact: planner.impact,
        scenarios: planner.scenarios,
        recommendations: planner.recommendations,
        priority: planner.priority,
        level: planner.level,
        createdAt: now,
      ),
    );
  }

  static void _buildUpcomingIncomeObservation({
    required FinanceStore financeStore,
    required DateTime now,
    required List<FrodoObservation> observations,
  }) {
    final upcomingIncomeItems =
        financeStore
            .futureRecurringItems()
            .where((item) => item.isIncome)
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    if (upcomingIncomeItems.isEmpty) return;

    final firstDate = upcomingIncomeItems.first.nextDueDate;

    final sameDayIncomeItems = upcomingIncomeItems.where((item) {
      return item.nextDueDate.year == firstDate.year &&
          item.nextDueDate.month == firstDate.month &&
          item.nextDueDate.day == firstDate.day;
    }).toList();

    final totalIncome = sameDayIncomeItems.fold<double>(
      0,
      (sum, item) => sum + item.expectedAmount,
    );

    final details = sameDayIncomeItems
        .map(
          (item) =>
              '${_ownerLabel(item.paymentOwner)}: +€${item.expectedAmount.toStringAsFixed(0)}',
        )
        .join('\n');

    observations.add(
      FrodoObservation(
        id: 'finance_upcoming_income_${firstDate.year}_${firstDate.month}_${firstDate.day}',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Entrate in arrivo',
        message:
            'Il ${firstDate.day.toString().padLeft(2, '0')}/${firstDate.month.toString().padLeft(2, '0')} sono previste entrate per +€${totalIncome.toStringAsFixed(0)}.',
        details: details,
        impact:
            'Queste entrate aumenteranno la disponibilità economica del mese.',
        priority: 55,
        level: FrodoObservationLevel.info,
        createdAt: now,
        targetDate: firstDate,
      ),
    );
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
}
