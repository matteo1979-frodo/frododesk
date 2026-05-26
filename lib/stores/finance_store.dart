import '../models/finance_balance.dart';
import '../models/finance_fund.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_snapshot.dart';
import 'finance_demo_data.dart';
import '../logic/persistence_store.dart';
import '../models/fund_transaction.dart';
import '../models/finance_month_projection.dart';

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
  final List<FundTransaction> fundTransactions = [];

  double totalBalance() {
    return balances.fold(0.0, (sum, balance) => sum + balance.availableAmount);
  }

  double grossTotalBalance() {
    return balances.fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  double operationalBalance() {
    return balances
        .where((balance) => balance.operational)
        .fold(0.0, (sum, balance) => sum + balance.availableAmount);
  }

  bool hasOperationalWarning() {
    return balances.any(
      (balance) => balance.operational && balance.isUnderWarning,
    );
  }

  double operationalStressRatio() {
    final total = operationalBalance();

    if (total <= 0) {
      return 1;
    }

    final reserved = balances
        .where((b) => b.operational)
        .fold(0.0, (sum, balance) => sum + balance.reservedAmount);

    return reserved / total;
  }

  String operationalStressLevel() {
    final ratio = operationalStressRatio();

    if (ratio >= 1.0) {
      return 'apnea';
    }

    if (ratio >= 0.75) {
      return 'critical';
    }

    if (ratio >= 0.50) {
      return 'warning';
    }

    if (ratio >= 0.25) {
      return 'attention';
    }

    return 'stable';
  }

  bool isOperationalStressCritical() {
    final level = operationalStressLevel();

    return level == 'critical' || level == 'apnea';
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

  bool isRecurringItemDueToday(FinanceRecurringItem item) {
    final now = DateTime.now();

    return item.nextDueDate.year == now.year &&
        item.nextDueDate.month == now.month &&
        item.nextDueDate.day == now.day;
  }

  bool isRecurringItemOverdue(FinanceRecurringItem item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueDay = DateTime(
      item.nextDueDate.year,
      item.nextDueDate.month,
      item.nextDueDate.day,
    );

    return dueDay.isBefore(today) && !item.confirmed;
  }

  bool isRecurringItemUpcoming(
    FinanceRecurringItem item, {
    int withinDays = 7,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueDay = DateTime(
      item.nextDueDate.year,
      item.nextDueDate.month,
      item.nextDueDate.day,
    );

    final limit = today.add(Duration(days: withinDays));

    return !item.confirmed &&
        dueDay.isAfter(today) &&
        (dueDay.isBefore(limit) || dueDay == limit);
  }

  DateTime nextDueDateAfterConfirmation(FinanceRecurringItem item) {
    final base = item.nextDueDate;

    switch (item.recurringType) {
      case FinanceRecurringType.monthly:
        return DateTime(base.year, base.month + 1, base.day);

      case FinanceRecurringType.yearly:
        return DateTime(base.year + 1, base.month, base.day);

      case FinanceRecurringType.oneShot:
        return base;

      case FinanceRecurringType.custom:
        final interval = item.customInterval ?? 1;
        final unit = item.customIntervalUnit ?? 'months';

        if (unit == 'days') {
          return base.add(Duration(days: interval));
        }

        if (unit == 'years') {
          return DateTime(base.year + interval, base.month, base.day);
        }

        return DateTime(base.year, base.month + interval, base.day);
    }
  }

  bool isUnderPressure() {
    return projectedMonthlyMargin() < 0;
  }

  int _priorityWeight(FinancePaymentPriority priority) {
    switch (priority) {
      case FinancePaymentPriority.low:
        return 1;

      case FinancePaymentPriority.normal:
        return 2;

      case FinancePaymentPriority.high:
        return 3;

      case FinancePaymentPriority.critical:
        return 4;
    }
  }

  List<FinanceRecurringItem> pastRecurringItems() {
    final items = recurringItems.where((item) => item.confirmed).toList();

    items.sort((a, b) {
      final dateCompare = b.nextDueDate.compareTo(a.nextDueDate);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));
    });

    return items;
  }

  List<FinanceRecurringItem> presentRecurringItems() {
    final items = recurringItems.where((item) {
      return !item.confirmed &&
          (isRecurringItemDueToday(item) || isRecurringItemOverdue(item));
    }).toList();

    items.sort((a, b) {
      final priorityCompare = _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.nextDueDate.compareTo(b.nextDueDate);
    });

    return items;
  }

  List<FinanceRecurringItem> futureRecurringItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = recurringItems.where((item) {
      final dueDay = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      return !item.confirmed && dueDay.isAfter(today);
    }).toList();

    items.sort((a, b) {
      final priorityCompare = _priorityWeight(
        b.paymentPriority,
      ).compareTo(_priorityWeight(a.paymentPriority));

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.nextDueDate.compareTo(b.nextDueDate);
    });

    return items;
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
      operationalBalance: operationalBalance(),
      operationalStressRatio: operationalStressRatio(),
      operationalStressLevel: operationalStressLevel(),
      vitalityState: balances.isEmpty ? 'stable' : balances.first.vitalityState,
      resilienceRatio: balances.isEmpty ? 1 : balances.first.resilienceRatio,
      recovering: balances.isNotEmpty && balances.first.isRecovering,
      fatigued: balances.isNotEmpty && balances.first.isFatigued,
      degrading: balances.isNotEmpty && balances.first.isDegrading,
      losingControl: balances.isNotEmpty && balances.first.isLosingControl,
      drowning: balances.isNotEmpty && balances.first.isDrowning,
    );
  }

  void saveSnapshot(DateTime date) {
    snapshots.add(createSnapshot(date));
  }

  FinanceSnapshot? latestSnapshot() {
    if (snapshots.isEmpty) {
      return null;
    }

    String economicHealthTrend() {
      if (snapshots.length < 2) {
        return 'unknown';
      }

      final previous = snapshots[snapshots.length - 2];
      final current = snapshots.last;

      if (current.drowning || current.losingControl) {
        return 'critical';
      }

      if (current.degrading && previous.degrading) {
        return 'worsening';
      }

      if (current.fatigued && previous.fatigued) {
        return 'fatigued';
      }

      if (current.recovering && !previous.recovering) {
        return 'recovering';
      }

      if (!current.underPressure && previous.underPressure) {
        return 'improving';
      }

      if (!current.underPressure && !previous.underPressure) {
        return 'stable';
      }

      return 'watch';
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
      balanceId: old.balanceId,
      personId: old.personId,
      initialAmount: old.initialAmount,
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
      balanceType: FinanceBalanceType.bankAccount,
      operational: true,
      reservedAmount: 0,
      warningThreshold: 200,
      persistentStressDays: 0,
      recoveryDays: 0,
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
      await loadSavedFundTransactions();

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
          balanceId: 'balance_matteo',
          personId: 'matteo',
          initialAmount: 993.32,
          currentAmount: 993.32,
          updatedAt: now,
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          reservedAmount: 0,
          warningThreshold: 200,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
        FinanceBalance(
          balanceId: 'balance_chiara',
          personId: 'chiara',
          initialAmount: 1400,
          currentAmount: 1400,
          updatedAt: now,
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          reservedAmount: 0,
          warningThreshold: 200,
          persistentStressDays: 0,
          recoveryDays: 0,
        ),
      ]);

    await saveBalances();

    final fundsLoaded = await loadSavedFunds();
    await loadSavedFundTransactions();

    if (!fundsLoaded) {
      funds
        ..clear()
        ..addAll(demoFunds);

      await saveFunds();
    }

    recurringItems
      ..clear()
      ..addAll(demoRecurringItems);
    await saveRecurringItems();
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

  Future<bool> loadSavedFundTransactions() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_fund_transactions',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    fundTransactions
      ..clear()
      ..addAll(jsonList.map(FundTransaction.fromJson));

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
      category: old.category,
    );

    await saveFunds();
  }

  Future<void> updateFund(FinanceFund updatedFund) async {
    final index = funds.indexWhere((f) => f.id == updatedFund.id);

    if (index == -1) {
      return;
    }

    funds[index] = updatedFund;

    await saveFunds();
  }

  Future<void> addFundTransaction({
    required String fundId,
    required String description,
    required double amount,
    required FundTransactionType type,
  }) async {
    final fundIndex = funds.indexWhere((f) => f.id == fundId);

    if (fundIndex == -1) {
      return;
    }

    final oldFund = funds[fundIndex];

    double newAmount = oldFund.amount;

    if (type == FundTransactionType.deposit) {
      newAmount += amount;
    } else {
      newAmount -= amount;
    }

    if (newAmount < 0) {
      newAmount = 0;
    }

    funds[fundIndex] = FinanceFund(
      id: oldFund.id,
      name: oldFund.name,
      description: oldFund.description,
      amount: newAmount,
      protected: oldFund.protected,
      category: oldFund.category,
    );

    fundTransactions.add(
      FundTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fundId: fundId,
        description: description,
        amount: amount,
        date: DateTime.now(),
        type: type,
      ),
    );

    await saveFunds();
    await saveFundTransactions();
  }

  Future<void> removeFund(String fundId) async {
    funds.removeWhere((f) => f.id == fundId);

    await saveFunds();
    await saveFundTransactions();
  }

  Future<void> confirmRecurringItem(String itemId, {double? realAmount}) async {
    final index = recurringItems.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      return;
    }

    final item = recurringItems[index];

    recurringItems[index] = item.copyWith(
      confirmed: true,
      realAmount: realAmount ?? item.expectedAmount,
    );

    if (item.recurringType != FinanceRecurringType.oneShot) {
      final nextDate = nextDueDateAfterConfirmation(item);

      final now = DateTime.now();

      recurringItems.add(
        item.copyWith(
          id: 'recurring_${now.microsecondsSinceEpoch}',
          nextDueDate: nextDate,
          confirmed: false,
          realAmount: null,
        ),
      );
    }

    await saveRecurringItems();
  }

  Future<void> addRecurringItem(FinanceRecurringItem item) async {
    recurringItems.add(item);

    await saveRecurringItems();
  }

  Future<void> removeRecurringItem(String itemId) async {
    recurringItems.removeWhere((item) => item.id == itemId);

    await saveRecurringItems();
  }

  Future<void> updateRecurringItem(FinanceRecurringItem updatedItem) async {
    final index = recurringItems.indexWhere(
      (item) => item.id == updatedItem.id,
    );

    if (index == -1) {
      return;
    }

    recurringItems[index] = updatedItem;

    await saveRecurringItems();
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

  Future<void> saveFundTransactions() async {
    final jsonList = fundTransactions.map((t) => t.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_fund_transactions', jsonList);
  }

  Future<void> saveRecurringItems() async {
    final jsonList = recurringItems.map((item) => item.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_recurring_items', jsonList);
  }

  double totalRecurringAmount(List<FinanceRecurringItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.expectedAmount);
  }

  double economicPressureScore() {
    double score = 0;

    final now = DateTime.now();

    for (final item in recurringItems) {
      if (item.isIncome) continue;

      double weight = item.expectedAmount;

      final matchingProtectedFundsAmount = funds
          .where((fund) {
            if (!fund.protected) return false;

            if (fund.category == FinanceFundCategory.emergency) {
              weight *= 0.80;
              return true;
            }

            if (fund.category == FinanceFundCategory.auto &&
                item.category == FinanceCategory.auto) {
              return true;
            }

            if (fund.category == FinanceFundCategory.home &&
                item.category == FinanceCategory.house) {
              return true;
            }

            if (fund.category == FinanceFundCategory.health &&
                item.category == FinanceCategory.health) {
              return true;
            }

            if (fund.category == FinanceFundCategory.school &&
                item.category == FinanceCategory.school) {
              return true;
            }

            return false;
          })
          .fold<double>(0, (sum, f) => sum + f.amount);

      if (item.protectionLevel == FinanceProtectionLevel.protected &&
          matchingProtectedFundsAmount >= item.expectedAmount) {
        weight *= 0.55;

        final minimumPressure = item.expectedAmount * 0.28;

        if (weight < minimumPressure) {
          weight = minimumPressure;
        }
      }

      switch (item.paymentPriority) {
        case FinancePaymentPriority.low:
          weight *= 0.5;
          break;

        case FinancePaymentPriority.normal:
          weight *= 1.0;
          break;

        case FinancePaymentPriority.high:
          weight *= 1.5;
          break;

        case FinancePaymentPriority.critical:
          weight *= 2.0;
          break;
      }

      final dueDate = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        item.nextDueDate.day,
      );

      final days = dueDate.difference(now).inDays;

      if (days <= 30) {
        weight *= 1.8;
      } else if (days <= 90) {
        weight *= 1.4;
      } else if (days <= 180) {
        weight *= 1.1;
      } else if (days <= 365) {
        weight *= 0.8;
      } else {
        weight *= 0.5;
      }

      score += weight;
    }

    final margin = projectedMonthlyMargin();

    if (margin < 0) {
      score *= 1.5;
    }

    return score;
  }

  List<FinanceRecurringItem> itemsForProjectionMonth(DateTime month) {
    return recurringItems.where((item) {
      final firstDueMonth = DateTime(
        item.nextDueDate.year,
        item.nextDueDate.month,
        1,
      );

      final currentMonth = DateTime(month.year, month.month, 1);

      if (currentMonth.year < firstDueMonth.year ||
          (currentMonth.year == firstDueMonth.year &&
              currentMonth.month < firstDueMonth.month)) {
        return false;
      }

      switch (item.recurringType) {
        case FinanceRecurringType.monthly:
          return true;

        case FinanceRecurringType.yearly:
          return currentMonth.month == item.nextDueDate.month &&
              currentMonth.year >= item.nextDueDate.year;

        case FinanceRecurringType.oneShot:
          return firstDueMonth.year == currentMonth.year &&
              firstDueMonth.month == currentMonth.month;

        case FinanceRecurringType.custom:
          final interval = item.customInterval ?? 1;
          final unit = item.customIntervalUnit ?? 'months';

          if (unit == 'months') {
            final monthDiff =
                (currentMonth.year - firstDueMonth.year) * 12 +
                (currentMonth.month - firstDueMonth.month);

            return monthDiff >= 0 && monthDiff % interval == 0;
          }

          if (unit == 'years') {
            final yearDiff = currentMonth.year - firstDueMonth.year;

            return currentMonth.month == firstDueMonth.month &&
                yearDiff >= 0 &&
                yearDiff % interval == 0;
          }

          return firstDueMonth.year == currentMonth.year &&
              firstDueMonth.month == currentMonth.month;
      }
    }).toList();
  }

  double projectedAmountForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    double total = 0;

    for (final item in itemsForProjectionMonth(month)) {
      if (item.isIncome) continue;

      if (item.hasCustomSplits) {
        for (final split in item.splits) {
          final splitOwner = FinancePaymentOwner.values.firstWhere(
            (e) => e.name == split.personId,
            orElse: () => FinancePaymentOwner.shared,
          );

          if (splitOwner == owner) {
            total += split.amount;
          }
        }

        continue;
      }

      if (item.paymentOwner == owner) {
        total += item.expectedAmount;
      }

      if (item.paymentOwner == FinancePaymentOwner.shared) {
        total += item.expectedAmount / 2;
      }
    }

    return total;
  }

  double projectedIncomeForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    double total = 0;

    for (final item in itemsForProjectionMonth(month)) {
      if (!item.isIncome) continue;

      if (item.hasCustomSplits) {
        for (final split in item.splits) {
          final splitOwner = FinancePaymentOwner.values.firstWhere(
            (e) => e.name == split.personId,
            orElse: () => FinancePaymentOwner.shared,
          );

          if (splitOwner == owner) {
            total += split.amount;
          }
        }

        continue;
      }

      if (item.paymentOwner == owner) {
        total += item.expectedAmount;
      }

      if (item.paymentOwner == FinancePaymentOwner.shared) {
        total += item.expectedAmount / 2;
      }
    }

    return total;
  }

  double projectedMarginForOwner({
    required DateTime month,
    required FinancePaymentOwner owner,
  }) {
    final income = projectedIncomeForOwner(month: month, owner: owner);

    final expenses = projectedAmountForOwner(month: month, owner: owner);

    return income - expenses;
  }

  List<FinanceMonthProjection> nextMonthProjections({int months = 12}) {
    final now = DateTime.now();
    final result = <FinanceMonthProjection>[];

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);

      double income = 0;
      double expenses = 0;

      for (final item in itemsForProjectionMonth(month)) {
        if (item.isIncome) {
          income += item.expectedAmount;
        } else {
          expenses += item.expectedAmount;
        }
      }

      final margin = income - expenses;

      double pressure = expenses;

      if (margin < 0) {
        pressure *= 1.5;
      }

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
        ),
      );
    }

    return result;
  }

  List<FinanceMonthProjection> yearProjections(int year) {
    final result = <FinanceMonthProjection>[];

    for (int monthIndex = 1; monthIndex <= 12; monthIndex++) {
      final month = DateTime(year, monthIndex, 1);

      double income = 0;
      double expenses = 0;

      for (final item in itemsForProjectionMonth(month)) {
        if (item.isIncome) {
          income += item.expectedAmount;
        } else {
          expenses += item.expectedAmount;
        }
      }

      final margin = income - expenses;

      double pressure = expenses;

      if (margin < 0) {
        pressure *= 1.5;
      }

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
        ),
      );
    }

    return result;
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
