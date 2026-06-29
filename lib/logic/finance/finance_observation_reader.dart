import '../../core/frododesk_modules.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/frodo_observation.dart';
import '../../stores/finance_store.dart';

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

    final overdue = pendingItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return dueDay.isBefore(today);
    }).toList();

    final next7Days = pendingItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return !dueDay.isBefore(today) && !dueDay.isAfter(endOfWeek);
    }).toList();

    final thisMonth = pendingItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return dueDay.isAfter(endOfWeek) && !dueDay.isAfter(endOfMonth);
    }).toList();

    final future = pendingItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return dueDay.isAfter(endOfMonth);
    }).toList();

    String formatItems(List<FinanceRecurringItem> items) {
      if (items.isEmpty) return '-';

      return items
          .take(5)
          .map(
            (item) =>
                '${item.name}: -€${item.expectedAmount.toStringAsFixed(0)} (${item.nextDueDate.day.toString().padLeft(2, '0')}/${item.nextDueDate.month.toString().padLeft(2, '0')})',
          )
          .join('\n');
    }

    final totalPending = pendingItems.fold<double>(
      0,
      (sum, item) => sum + item.expectedAmount,
    );

    observations.add(
      FrodoObservation(
        id: 'finance_deadlines_${now.year}_${now.month}',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Scadenze',
        message:
            '${pendingItems.length} scadenze ancora da confermare per €${totalPending.toStringAsFixed(0)}.',
        details:
            'In ritardo\n${formatItems(overdue)}\n\nEntro 7 giorni\n${formatItems(next7Days)}\n\nEntro il mese\n${formatItems(thisMonth)}\n\nFuture\n${formatItems(future)}',
        impact:
            'Le scadenze non confermate rappresentano gli impegni economici ancora aperti.',
        priority: overdue.isNotEmpty ? 96 : 88,
        level: overdue.isNotEmpty
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
