import '../models/finance_balance.dart';
import '../models/finance_fund.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_snapshot.dart';
import 'finance_demo_data.dart';
import '../logic/persistence_store.dart';

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

  Future<void> updateBalance({
    required String personId,
    required double newAmount,
  }) async {
    final index = balances.indexWhere((b) => b.personId == personId);

    if (index == -1) {
      return;
    }

    final old = balances[index];

    balances[index] = FinanceBalance(
      personId: old.personId,
      initialAmount: old.initialAmount,
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
    );

    await saveBalances();
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

  Future<void> loadInitialRealData() async {
    final now = DateTime.now();

    final loaded = await loadSavedBalances();

    if (loaded) {
      final fundsLoaded = await loadSavedFunds();

      if (!fundsLoaded) {
        funds
          ..clear()
          ..addAll(demoFunds);

        await saveFunds();
      }

      final recurringItemsLoaded = await loadSavedRecurringItems();

      if (!recurringItemsLoaded) {
        recurringItems
          ..clear()
          ..addAll(demoRecurringItems);

        await saveRecurringItems();
      }

      return;
    }

    balances
      ..clear()
      ..addAll([
        FinanceBalance(
          personId: 'matteo',
          initialAmount: 993.32,
          currentAmount: 993.32,
          updatedAt: now,
        ),
        FinanceBalance(
          personId: 'chiara',
          initialAmount: 1400,
          currentAmount: 1400,
          updatedAt: now,
        ),
      ]);

    await saveBalances();

    final fundsLoaded = await loadSavedFunds();

    if (!fundsLoaded) {
      funds
        ..clear()
        ..addAll(demoFunds);

      await saveFunds();
    }

    recurringItems
      ..clear()
      ..addAll(demoRecurringItems);
  }

  Future<void> saveBalances() async {
    final jsonList = balances.map((b) => b.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_balances', jsonList);
  }

  Future<bool> loadSavedBalances() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_balances');

    if (jsonList.isEmpty) {
      return false;
    }

    balances
      ..clear()
      ..addAll(jsonList.map(FinanceBalance.fromJson));

    return true;
  }

  Future<bool> loadSavedFunds() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_funds');

    if (jsonList.isEmpty) {
      return false;
    }

    funds
      ..clear()
      ..addAll(jsonList.map(FinanceFund.fromJson));

    return true;
  }

  Future<void> updateFundAmount({
    required String fundId,
    required double newAmount,
  }) async {
    final index = funds.indexWhere((f) => f.id == fundId);

    if (index == -1) {
      return;
    }

    final old = funds[index];

    funds[index] = FinanceFund(
      id: old.id,
      name: old.name,
      description: old.description,
      amount: newAmount,
      protected: old.protected,
    );

    await saveFunds();
  }

  Future<bool> loadSavedRecurringItems() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_recurring_items',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    recurringItems
      ..clear()
      ..addAll(jsonList.map(FinanceRecurringItem.fromJson));

    return true;
  }

  Future<void> saveFunds() async {
    final jsonList = funds.map((f) => f.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_funds', jsonList);
  }

  Future<void> saveRecurringItems() async {
    final jsonList = recurringItems.map((item) => item.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_recurring_items', jsonList);
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
