import '../models/finance_balance.dart';
import '../models/finance_fund.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_snapshot.dart';
import 'finance_demo_data.dart';
import '../logic/persistence_store.dart';
import '../models/fund_transaction.dart';
import '../models/finance_month_projection.dart';
import '../models/finance_transaction.dart';

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
  final List<FinanceTransaction> transactions = [];

  double totalBalance() {
    return balances
        .where((balance) => balance.active)
        .fold(0.0, (sum, balance) => sum + balance.availableAmount);
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
      economicTrend: economicHealthTrend(),
      resilienceRatio: balances.isEmpty ? 1 : balances.first.resilienceRatio,
      recovering: balances.isNotEmpty && balances.first.isRecovering,
      fatigued: balances.isNotEmpty && balances.first.isFatigued,
      degrading: balances.isNotEmpty && balances.first.isDegrading,
      losingControl: balances.isNotEmpty && balances.first.isLosingControl,
      drowning: balances.isNotEmpty && balances.first.isDrowning,
    );
  }

  Future<void> saveSnapshot(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);

    final snapshot = createSnapshot(day);

    final existingIndex = snapshots.indexWhere((s) {
      final existingDay = DateTime(s.date.year, s.date.month, s.date.day);

      return existingDay == day;
    });

    if (existingIndex == -1) {
      snapshots.add(snapshot);
    } else {
      snapshots[existingIndex] = snapshot;
    }

    await saveSnapshots();
  }

  FinanceSnapshot? latestSnapshot() {
    if (snapshots.isEmpty) {
      return null;
    }

    return snapshots.last;
  }

  String economicHealthTrend() {
    if (snapshots.length < 3) {
      return 'unknown';
    }

    final recent = snapshots.sublist(snapshots.length - 3);

    final criticalCount = recent
        .where((snapshot) => snapshot.drowning || snapshot.losingControl)
        .length;

    if (criticalCount >= 1) {
      return 'critical';
    }

    final degradingCount = recent
        .where((snapshot) => snapshot.degrading)
        .length;

    if (degradingCount >= 2) {
      return 'worsening';
    }

    final fatiguedCount = recent.where((snapshot) => snapshot.fatigued).length;

    if (fatiguedCount >= 2) {
      return 'fatigued';
    }

    final recoveringCount = recent
        .where((snapshot) => snapshot.recovering)
        .length;

    if (recoveringCount >= 2) {
      return 'recovering';
    }

    final pressureCount = recent
        .where((snapshot) => snapshot.underPressure)
        .length;

    if (pressureCount == 0) {
      return 'stable';
    }

    return 'watch';
  }

  double balanceForPerson(String personId) {
    return balances
        .where((balance) => balance.personId == personId)
        .fold(0.0, (sum, balance) => sum + balance.currentAmount);
  }

  Future<void> updateBalance({
    required String balanceId,
    required double newAmount,
  }) async {
    final index = balances.indexWhere((b) => b.balanceId == balanceId);

    if (index == -1) {
      return;
    }

    final old = balances[index];
    final difference = newAmount - old.currentAmount;

    balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      active: old.active,
      initialAmount: old.initialAmount,
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    if (difference != 0) {
      transactions.add(
        FinanceTransaction(
          id: 'adjustment_${DateTime.now().microsecondsSinceEpoch}',
          balanceId: old.balanceId,
          amount: difference.abs(),
          date: DateTime.now(),
          isIncome: difference > 0,
          description: 'Correzione saldo ${old.name}',
          type: difference > 0
              ? FinanceTransactionType.income
              : FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.adjustment,
          notes: 'Saldo modificato manualmente',
        ),
      );
    }

    await saveBalances();
    await saveTransactions();
  }

  Future<void> transferBetweenBalances({
    required String fromBalanceId,
    required String toBalanceId,
    required double amount,
    String description = 'Trasferimento',
  }) async {
    final fromIndex = balances.indexWhere((b) => b.balanceId == fromBalanceId);

    final toIndex = balances.indexWhere((b) => b.balanceId == toBalanceId);

    if (fromIndex == -1 || toIndex == -1) {
      return;
    }

    final fromBalance = balances[fromIndex];
    final toBalance = balances[toIndex];

    balances[fromIndex] = FinanceBalance(
      balanceId: fromBalance.balanceId,
      personId: fromBalance.personId,
      name: fromBalance.name,
      active: fromBalance.active,
      initialAmount: fromBalance.initialAmount,
      currentAmount: fromBalance.currentAmount - amount,
      updatedAt: DateTime.now(),
      balanceType: fromBalance.balanceType,
      operational: fromBalance.operational,
      reservedAmount: fromBalance.reservedAmount,
      warningThreshold: fromBalance.warningThreshold,
      persistentStressDays: fromBalance.persistentStressDays,
      recoveryDays: fromBalance.recoveryDays,
    );

    balances[toIndex] = FinanceBalance(
      balanceId: toBalance.balanceId,
      personId: toBalance.personId,
      name: toBalance.name,
      active: toBalance.active,
      initialAmount: toBalance.initialAmount,
      currentAmount: toBalance.currentAmount + amount,
      updatedAt: DateTime.now(),
      balanceType: toBalance.balanceType,
      operational: toBalance.operational,
      reservedAmount: toBalance.reservedAmount,
      warningThreshold: toBalance.warningThreshold,
      persistentStressDays: toBalance.persistentStressDays,
      recoveryDays: toBalance.recoveryDays,
    );

    final transferId = DateTime.now().microsecondsSinceEpoch.toString();

    transactions.add(
      FinanceTransaction(
        id: 'transfer_out_$transferId',
        balanceId: fromBalance.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: false,
        description: description,
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Trasferimento verso ${toBalance.name}',
      ),
    );

    transactions.add(
      FinanceTransaction(
        id: 'transfer_in_$transferId',
        balanceId: toBalance.balanceId,
        amount: amount,
        date: DateTime.now(),
        isIncome: true,
        description: description,
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Trasferimento da ${fromBalance.name}',
      ),
    );

    await saveBalances();
    await saveTransactions();
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
      final allBalancesZero = balances.every((b) => b.currentAmount == 0);

      if (!allBalancesZero) {
        final fundsLoaded = await loadSavedFunds();
        await loadSavedFundTransactions();
        await loadSavedTransactions();
        await loadSavedSnapshots();

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
      for (int i = 0; i < balances.length; i++) {
        final old = balances[i];

        if (old.name == old.balanceId) {
          balances[i] = FinanceBalance(
            balanceId: old.balanceId,
            personId: old.personId,
            name: old.personId == 'matteo'
                ? 'Conto principale Matteo'
                : old.personId == 'chiara'
                ? 'Conto principale Chiara'
                : old.name,
            initialAmount: old.initialAmount,
            currentAmount: old.currentAmount,
            updatedAt: old.updatedAt,
            balanceType: old.balanceType,
            operational: old.operational,
            active: old.active,
            reservedAmount: old.reservedAmount,
            warningThreshold: old.warningThreshold,
            persistentStressDays: old.persistentStressDays,
            recoveryDays: old.recoveryDays,
          );
        }
      }

      await saveBalances();
    }

    balances
      ..clear()
      ..addAll([
        FinanceBalance(
          balanceId: 'balance_matteo',
          personId: 'matteo',
          name: 'Conto principale Matteo',
          active: true,
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
          name: 'Conto principale Chiara',
          active: true,
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
    await loadSavedTransactions();
    await loadSavedSnapshots();

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

  Future<void> saveTransactions() async {
    final jsonList = transactions.map((t) => t.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_transactions', jsonList);
  }

  Future<void> saveSnapshots() async {
    final jsonList = snapshots.map((s) => s.toJson()).toList();

    await PersistenceStore.saveJsonList('finance_snapshots', jsonList);
  }

  Future<bool> loadSavedTransactions() async {
    final jsonList = await PersistenceStore.loadJsonList(
      'finance_transactions',
    );

    if (jsonList.isEmpty) {
      return false;
    }

    transactions
      ..clear()
      ..addAll(jsonList.map(FinanceTransaction.fromJson));

    return true;
  }

  Future<bool> loadSavedSnapshots() async {
    final jsonList = await PersistenceStore.loadJsonList('finance_snapshots');

    if (jsonList.isEmpty) {
      return false;
    }

    snapshots
      ..clear()
      ..addAll(jsonList.map(FinanceSnapshot.fromJson));

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

    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    fundTransactions.add(
      FundTransaction(
        id: transactionId,
        fundId: fundId,
        description: description,
        amount: amount,
        date: DateTime.now(),
        type: type,
      ),
    );

    transactions.add(
      FinanceTransaction(
        id: 'fund_$transactionId',
        balanceId: fundId,
        amount: amount,
        date: DateTime.now(),
        isIncome: type == FundTransactionType.deposit,
        description: description.isEmpty ? oldFund.name : description,
        type: type == FundTransactionType.deposit
            ? FinanceTransactionType.income
            : FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
        notes: 'Movimento fondo: ${oldFund.name}',
      ),
    );

    await saveFunds();
    await saveFundTransactions();
    await saveTransactions();
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
    final amount = realAmount ?? item.expectedAmount;

    if (item.balanceId != null) {
      final balanceIndex = balances.indexWhere(
        (balance) => balance.balanceId == item.balanceId,
      );

      if (balanceIndex != -1) {
        final oldBalance = balances[balanceIndex];

        final newAmount = item.isIncome
            ? oldBalance.currentAmount + amount
            : oldBalance.currentAmount - amount;

        balances[balanceIndex] = FinanceBalance(
          balanceId: oldBalance.balanceId,
          personId: oldBalance.personId,
          name: oldBalance.name,
          initialAmount: oldBalance.initialAmount,
          currentAmount: newAmount,
          updatedAt: DateTime.now(),
          balanceType: oldBalance.balanceType,
          operational: oldBalance.operational,
          active: oldBalance.active,
          reservedAmount: oldBalance.reservedAmount,
          warningThreshold: oldBalance.warningThreshold,
          persistentStressDays: oldBalance.persistentStressDays,
          recoveryDays: oldBalance.recoveryDays,
        );

        transactions.add(
          FinanceTransaction(
            id: 'transaction_${DateTime.now().microsecondsSinceEpoch}',
            balanceId: oldBalance.balanceId,
            amount: amount,
            date: DateTime.now(),
            isIncome: item.isIncome,
            description: item.name,
            type: item.isIncome
                ? FinanceTransactionType.income
                : FinanceTransactionType.expense,
            origin: FinanceTransactionOrigin.recurringItem,
            recurringItemId: item.id,
            notes: item.description,
          ),
        );

        await saveBalances();
        await saveTransactions();
      }
    }

    recurringItems[index] = item.copyWith(confirmed: true, realAmount: amount);

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
    final itemIndex = recurringItems.indexWhere((item) => item.id == itemId);

    if (itemIndex == -1) {
      return;
    }

    final item = recurringItems[itemIndex];

    final linkedTransactions = transactions
        .where((transaction) => transaction.recurringItemId == item.id)
        .toList();

    for (final transaction in linkedTransactions) {
      final balanceIndex = balances.indexWhere(
        (balance) => balance.balanceId == transaction.balanceId,
      );

      if (balanceIndex == -1) continue;

      final oldBalance = balances[balanceIndex];

      final restoredAmount = transaction.isIncome
          ? oldBalance.currentAmount - transaction.amount
          : oldBalance.currentAmount + transaction.amount;

      balances[balanceIndex] = FinanceBalance(
        balanceId: oldBalance.balanceId,
        personId: oldBalance.personId,
        name: oldBalance.name,
        initialAmount: oldBalance.initialAmount,
        currentAmount: restoredAmount,
        updatedAt: DateTime.now(),
        balanceType: oldBalance.balanceType,
        operational: oldBalance.operational,
        active: oldBalance.active,
        reservedAmount: oldBalance.reservedAmount,
        warningThreshold: oldBalance.warningThreshold,
        persistentStressDays: oldBalance.persistentStressDays,
        recoveryDays: oldBalance.recoveryDays,
      );
    }

    transactions.removeWhere(
      (transaction) => transaction.recurringItemId == item.id,
    );

    recurringItems.removeAt(itemIndex);

    await saveBalances();
    await saveTransactions();
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

      final behavior = item.behaviorProfile;

      weight *= 1 + behavior.rigidityScore;
      weight *= 1 + (1 - behavior.maneuverabilityScore);

      if (behavior.lifeGenerated) {
        weight *= 1.15;
      }

      if (behavior.timeSensitive) {
        weight *= 1.20;
      }

      if (!behavior.affectsResilience) {
        weight *= 0.85;
      }

      if (!behavior.affectsOperationalOxygen) {
        weight *= 0.90;
      }

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

  FinanceMonthSaturation _monthSaturation({
    required double margin,
    required double pressureDensity,
    required int pressureItemCount,
  }) {
    if (margin < 0 && pressureDensity > 800) {
      return FinanceMonthSaturation.critical;
    }

    if (margin < 200 && pressureItemCount >= 8) {
      return FinanceMonthSaturation.high;
    }

    if (pressureDensity > 400 || pressureItemCount >= 5) {
      return FinanceMonthSaturation.medium;
    }

    return FinanceMonthSaturation.low;
  }

  List<FinanceMonthProjection> nextMonthProjections({int months = 12}) {
    final now = DateTime.now();
    final result = <FinanceMonthProjection>[];

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month + i, 1);

      double income = 0;
      double expenses = 0;

      final monthItems = itemsForProjectionMonth(month);

      for (final item in monthItems) {
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

      final pressureItems = monthItems.where((item) => !item.isIncome).toList();
      final pressureItemCount = pressureItems.length;
      final pressureDensity = pressureItemCount == 0
          ? 0.0
          : pressure / pressureItemCount;

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
          pressureItemCount: pressureItemCount,
          pressureDensity: pressureDensity,
          saturation: _monthSaturation(
            margin: margin,
            pressureDensity: pressureDensity,
            pressureItemCount: pressureItemCount,
          ),
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

      final monthItems = itemsForProjectionMonth(month);

      for (final item in monthItems) {
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

      final pressureItems = monthItems.where((item) => !item.isIncome).toList();
      final pressureItemCount = pressureItems.length;
      final pressureDensity = pressureItemCount == 0
          ? 0.0
          : pressure / pressureItemCount;

      result.add(
        FinanceMonthProjection(
          month: month,
          expectedIncome: income,
          expectedExpenses: expenses,
          expectedMargin: margin,
          pressureScore: pressure,
          pressureItemCount: pressureItemCount,
          pressureDensity: pressureDensity,
          saturation: _monthSaturation(
            margin: margin,
            pressureDensity: pressureDensity,
            pressureItemCount: pressureItemCount,
          ),
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
