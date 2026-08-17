import 'package:flutter/foundation.dart';

import '../../stores/finance_store.dart';

class FinanceLifecycleLoader {
  final FinanceStore financeStore;
  final VoidCallback refresh;

  const FinanceLifecycleLoader({
    required this.financeStore,
    required this.refresh,
  });

  Future<void> load() async {
    await financeStore.loadInitialRealData();

    await financeStore.saveBalances();
    await financeStore.saveFunds();
    await financeStore.saveRecurringItems();

    financeStore.saveSnapshot(DateTime.now());

    refresh();
  }
}
