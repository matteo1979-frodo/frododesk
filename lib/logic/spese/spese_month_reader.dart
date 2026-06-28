import '../../models/real_expense.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/frodo_observation.dart';
import '../../core/frododesk_modules.dart';

class SpeseMonthReader {
  static List<FrodoObservation> analyze({
    required List<RealExpense> currentMonthExpenses,
    required List<RealExpense> previousMonthExpenses,
  }) {
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    if (currentMonthExpenses.isEmpty) {
      return [
        FrodoObservation(
          id: 'spese_empty_$monthKey',
          module: FrodoModules.spese,
          category: FrodoObservationCategory.expenses,
          title: 'Nessun movimento',
          message:
              'Nessun movimento registrato. Quando inizierai a inserire spese reali, qui FrodoDesk ti aiuterà a capire dove stanno andando i soldi.',
          priority: 100,
          level: FrodoObservationLevel.info,
          createdAt: now,
        ),
      ];
    }

    final observations = <FrodoObservation>[
      ..._subjectObservations(currentMonthExpenses, now, monthKey),
      ..._categoryObservations(currentMonthExpenses, now, monthKey),
      ..._comparisonObservations(
        currentMonthExpenses,
        previousMonthExpenses,
        now,
        monthKey,
      ),
      ..._concentrationObservations(currentMonthExpenses, now, monthKey),
      _volumeObservation(currentMonthExpenses, now, monthKey),
      _summaryObservation(currentMonthExpenses, now, monthKey),
    ];

    observations.sort((a, b) => b.priority.compareTo(a.priority));

    return observations;
  }

  static List<FrodoObservation> _subjectObservations(
    List<RealExpense> expenses,
    DateTime now,
    String monthKey,
  ) {
    final totals = <FinanceSubject, double>{};

    for (final expense in expenses.where((e) => !e.isIncome)) {
      totals[expense.subject] = (totals[expense.subject] ?? 0) + expense.amount;
    }

    if (totals.isEmpty) return [];

    final total = totals.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return [];

    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final main = ordered.first;
    final percent = (main.value / total * 100).round();

    final result = <FrodoObservation>[
      FrodoObservation(
        id: 'spese_subject_main_$monthKey',
        module: FrodoModules.spese,
        category: FrodoObservationCategory.expenses,
        title: 'Destinazione principale',
        message: _mainSubjectMessage(main.key, percent),
        priority: percent >= 60
            ? 98
            : percent >= 40
            ? 90
            : 70,
        level: percent >= 60
            ? FrodoObservationLevel.attention
            : FrodoObservationLevel.info,
        createdAt: now,
        action: const FrodoObservationAction(
          label: 'Apri Spese',
          targetModule: 'spese',
        ),
      ),
    ];

    if (ordered.length >= 2) {
      final second = ordered[1];
      final secondPercent = (second.value / total * 100).round();

      if (secondPercent >= 20) {
        result.add(
          FrodoObservation(
            id: 'spese_subject_second_$monthKey',
            module: FrodoModules.spese,
            category: FrodoObservationCategory.expenses,
            title: 'Seconda area di spesa',
            message:
                '${_subjectSentenceLabel(second.key)} ha rappresentato il $secondPercent% delle spese reali del mese.',
            priority: 62,
            level: FrodoObservationLevel.info,
            createdAt: now,
          ),
        );
      }
    }

    return result;
  }

  static List<FrodoObservation> _categoryObservations(
    List<RealExpense> expenses,
    DateTime now,
    String monthKey,
  ) {
    final totals = <String, double>{};

    for (final expense in expenses.where((e) => !e.isIncome)) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    if (totals.isEmpty) return [];

    final total = totals.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return [];

    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final main = ordered.first;
    final percent = (main.value / total * 100).round();

    final result = <FrodoObservation>[
      FrodoObservation(
        id: 'spese_category_main_$monthKey',
        module: FrodoModules.spese,
        category: FrodoObservationCategory.expenses,
        title: 'Categoria principale',
        message:
            'La categoria più pesante del mese è ${main.key}, con il $percent% delle spese reali.',
        priority: percent >= 45 ? 86 : 66,
        level: percent >= 45
            ? FrodoObservationLevel.attention
            : FrodoObservationLevel.info,
        createdAt: now,
      ),
    ];

    if (ordered.length >= 2) {
      final second = ordered[1];
      final secondPercent = (second.value / total * 100).round();

      if (secondPercent >= 15) {
        result.add(
          FrodoObservation(
            id: 'spese_category_second_$monthKey',
            module: FrodoModules.spese,
            category: FrodoObservationCategory.expenses,
            title: 'Seconda categoria',
            message:
                'Anche ${second.key} pesa sul mese: circa il $secondPercent% delle spese reali.',
            priority: 50,
            level: FrodoObservationLevel.info,
            createdAt: now,
          ),
        );
      }
    }

    return result;
  }

  static List<FrodoObservation> _comparisonObservations(
    List<RealExpense> current,
    List<RealExpense> previous,
    DateTime now,
    String monthKey,
  ) {
    final currentTotal = _expenseTotal(current);
    final previousTotal = _expenseTotal(previous);

    if (previousTotal <= 0) return [];

    final difference = currentTotal - previousTotal;
    final percent = (difference.abs() / previousTotal * 100).round();

    if (percent < 10) {
      return [
        FrodoObservation(
          id: 'spese_comparison_stable_$monthKey',
          module: FrodoModules.spese,
          category: FrodoObservationCategory.expenses,
          title: 'Mese stabile',
          message:
              'Le spese reali sono simili al mese precedente: variazione circa $percent%.',
          priority: 48,
          level: FrodoObservationLevel.info,
          createdAt: now,
        ),
      ];
    }

    if (difference > 0) {
      return [
        FrodoObservation(
          id: 'spese_comparison_up_$monthKey',
          module: FrodoModules.spese,
          category: FrodoObservationCategory.expenses,
          title: 'Spese in aumento',
          message:
              'Questo mese hai registrato circa €${difference.toStringAsFixed(0)} in più rispetto al mese precedente.',
          priority: percent >= 30 ? 92 : 78,
          level: percent >= 30
              ? FrodoObservationLevel.attention
              : FrodoObservationLevel.info,
          createdAt: now,
        ),
      ];
    }

    return [
      FrodoObservation(
        id: 'spese_comparison_down_$monthKey',
        module: FrodoModules.spese,
        category: FrodoObservationCategory.expenses,
        title: 'Spese in calo',
        message:
            'Questo mese hai registrato circa €${difference.abs().toStringAsFixed(0)} in meno rispetto al mese precedente.',
        priority: percent >= 30 ? 88 : 74,
        level: FrodoObservationLevel.success,
        createdAt: now,
      ),
    ];
  }

  static List<FrodoObservation> _concentrationObservations(
    List<RealExpense> expenses,
    DateTime now,
    String monthKey,
  ) {
    final expenseOnly = expenses.where((e) => !e.isIncome).toList();

    if (expenseOnly.length < 4) return [];

    expenseOnly.sort((a, b) => a.date.compareTo(b.date));

    final lastDate = expenseOnly.last.date;
    final lastFiveDaysTotal = expenseOnly
        .where(
          (e) => e.date.isAfter(lastDate.subtract(const Duration(days: 5))),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final total = _expenseTotal(expenseOnly);
    if (total <= 0) return [];

    final percent = (lastFiveDaysTotal / total * 100).round();

    if (percent < 50) return [];

    return [
      FrodoObservation(
        id: 'spese_concentration_$monthKey',
        module: FrodoModules.spese,
        category: FrodoObservationCategory.expenses,
        title: 'Spese concentrate',
        message:
            'Attenzione: il $percent% delle spese del mese è concentrato negli ultimi giorni registrati.',
        priority: percent >= 70 ? 91 : 82,
        level: FrodoObservationLevel.attention,
        createdAt: now,
      ),
    ];
  }

  static FrodoObservation _volumeObservation(
    List<RealExpense> expenses,
    DateTime now,
    String monthKey,
  ) {
    final movements = expenses.length;

    return FrodoObservation(
      id: 'spese_volume_$monthKey',
      module: FrodoModules.spese,
      category: FrodoObservationCategory.expenses,
      title: 'Movimenti registrati',
      message:
          'Hai registrato $movements movimenti reali nel mese: sono la base della memoria economica di FrodoDesk.',
      priority: 35,
      level: FrodoObservationLevel.info,
      createdAt: now,
    );
  }

  static FrodoObservation _summaryObservation(
    List<RealExpense> expenses,
    DateTime now,
    String monthKey,
  ) {
    final total = _expenseTotal(expenses);

    return FrodoObservation(
      id: 'spese_summary_$monthKey',
      module: FrodoModules.spese,
      category: FrodoObservationCategory.expenses,
      title: 'Totale mese',
      message:
          'Il totale delle spese reali registrate nel mese è €${total.toStringAsFixed(0)}.',
      priority: 20,
      level: FrodoObservationLevel.info,
      createdAt: now,
    );
  }

  static double _expenseTotal(List<RealExpense> expenses) {
    return expenses
        .where((expense) => !expense.isIncome)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  static String _mainSubjectMessage(FinanceSubject subject, int percent) {
    switch (subject) {
      case FinanceSubject.matteo:
        return 'Questo mese la maggior parte delle spese è stata destinata a Matteo ($percent%).';
      case FinanceSubject.chiara:
        return 'Questo mese la maggior parte delle spese è stata destinata a Chiara ($percent%).';
      case FinanceSubject.alice:
        return 'Questo mese la maggior parte delle spese è stata destinata ad Alice ($percent%).';
      case FinanceSubject.shared:
        return 'Questo mese la maggior parte delle spese è stata destinata alla famiglia ($percent%).';
    }
  }

  static String _subjectSentenceLabel(FinanceSubject subject) {
    switch (subject) {
      case FinanceSubject.matteo:
        return 'Matteo';
      case FinanceSubject.chiara:
        return 'Chiara';
      case FinanceSubject.alice:
        return 'Alice';
      case FinanceSubject.shared:
        return 'La famiglia';
    }
  }
}
