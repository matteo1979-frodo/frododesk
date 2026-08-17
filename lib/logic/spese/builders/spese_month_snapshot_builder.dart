import '../../../models/cash_wallet.dart';
import '../../../models/frodo_observation.dart';
import '../../../models/finance_balance.dart';
import '../../../models/finance_recurring_item.dart';
import '../../../models/real_expense.dart';
import '../../../models/spese_command.dart';
import '../../../models/spese_snapshot.dart';

class SpeseMonthSnapshotBuilder {
  const SpeseMonthSnapshotBuilder();

  SpeseSnapshot build({
    required List<RealExpense> expenses,
    required List<CashWallet> cashWallets,
    required List<FinanceBalance> balances,
    required List<String> categories,
    required List<FrodoObservation> observations,
    required DateTime observedAt,
  }) {
    final currentMonthExpenses = expenses.where((expense) {
      return expense.date.year == observedAt.year &&
          expense.date.month == observedAt.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final previousMonth = DateTime(observedAt.year, observedAt.month - 1, 1);
    final previousMonthExpenses = expenses.where((expense) {
      return expense.date.year == previousMonth.year &&
          expense.date.month == previousMonth.month;
    }).toList();

    final last7DaysTotal = expenses
        .where(
          (expense) => expense.date.isAfter(
            observedAt.subtract(const Duration(days: 7)),
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final currentMonthTotal = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final cashWalletTotal = cashWallets
        .where((wallet) => wallet.active)
        .fold<double>(0, (sum, wallet) => sum + wallet.currentAmount);
    final categoryTotals = <String, double>{};
    for (final expense in currentMonthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final activeBalances = balances.where((balance) => balance.active).toList();
    final commandRegistry = SpeseCommandRegistry(
      accounts: {
        for (final balance in balances) balance.balanceId: balance.name,
      },
      cashWallets: {for (final wallet in cashWallets) wallet.id: wallet.name},
      categories: {...categories, 'Entrata extra', 'Portafoglio contanti'},
      people: FinanceSubject.values.map((subject) => subject.name).toSet(),
    );

    return SpeseSnapshot(
      observedAt: observedAt,
      monthTitle: '${_monthName(observedAt.month)} ${observedAt.year}',
      currentMonthExpenses: currentMonthExpenses,
      recentExpenses: currentMonthExpenses.take(3).toList(),
      previousMonthExpenses: previousMonthExpenses,
      monthObservations: observations,
      visibleMonthObservations: observations.take(4).toList(),
      categoryTotals: categoryTotals,
      activeBalances: activeBalances,
      categories: categories,
      commandRegistry: commandRegistry,
      currentMonthTotal: currentMonthTotal,
      last7DaysTotal: last7DaysTotal,
      cashWalletTotal: cashWalletTotal,
      movementCount: currentMonthExpenses.length,
      mainCategory: _mainCategory(categoryTotals),
    );
  }

  String _mainCategory(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return '-';
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topValue = sortedCategories.first.value;
    return sortedCategories
        .where((entry) => entry.value == topValue)
        .map((entry) => entry.key)
        .take(3)
        .join(' / ');
  }

  String _monthName(int month) => const [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ][month - 1];
}
