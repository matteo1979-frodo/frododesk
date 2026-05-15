import '../models/finance_balance.dart';
import '../models/finance_fund.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_snapshot.dart';
import 'finance_demo_data.dart';

class FinanceStore {
  final List<FinancePerson> people = const [
    FinancePerson(id: 'matteo', name: 'Matteo'),
    FinancePerson(id: 'chiara', name: 'Chiara'),
    FinancePerson(id: 'alice', name: 'Alice'),
  ];

  final List<FinanceBalance> balances = [];
  final List<FinanceFund> funds = [];
  final List<FinanceRecurringItem> recurringItems = [];
  final List<FinanceSnapshot> snapshots = [];

  double totalBalance() {
    return balances.fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  double totalFunds() {
    return funds.fold(0.0, (sum, fund) => sum + fund.amount);
  }

  double projectedMonthlyExpenses() {
    return recurringItems
        .where((item) => !item.isIncome)
        .fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double projectedMonthlyIncome() {
    return recurringItems
        .where((item) => item.isIncome)
        .fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double projectedMonthlyMargin() {
    return projectedMonthlyIncome() - projectedMonthlyExpenses();
  }

  bool isUnderPressure() {
    return projectedMonthlyMargin() < 0;
  }

  FinanceSnapshot createSnapshot(DateTime date) {
    return FinanceSnapshot(
      date: date,
      totalBalance: totalBalance(),
      totalFunds: totalFunds(),
      projectedMonthlyIncome: projectedMonthlyIncome(),
      projectedMonthlyExpenses: projectedMonthlyExpenses(),
      projectedMonthlyMargin: projectedMonthlyMargin(),
      underPressure: isUnderPressure(),
    );
  }

  void saveSnapshot(DateTime date) {
    snapshots.add(createSnapshot(date));
  }

  FinanceSnapshot? latestSnapshot() {
    if (snapshots.isEmpty) {
      return null;
    }

    return snapshots.last;
  }

  double balanceForPerson(String personId) {
    return balances
        .where((balance) => balance.personId == personId)
        .fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  void loadDemoData() {
    balances
      ..clear()
      ..addAll(demoBalances);

    funds
      ..clear()
      ..addAll(demoFunds);

    recurringItems
      ..clear()
      ..addAll(demoRecurringItems);
  }

  String financeSummaryText() {
    return '''
Saldo totale: ${totalBalance().toStringAsFixed(2)}
Fondi: ${totalFunds().toStringAsFixed(2)}
Entrate previste: ${projectedMonthlyIncome().toStringAsFixed(2)}
Uscite previste: ${projectedMonthlyExpenses().toStringAsFixed(2)}
Margine previsto: ${projectedMonthlyMargin().toStringAsFixed(2)}
Pressione: ${isUnderPressure() ? 'SI' : 'NO'}
''';
  }

  String demoSummaryText() {
    loadDemoData();
    saveSnapshot(DateTime.now());
    return financeSummaryText();
  }
}
