import '../../core/frododesk_bootstrap.dart';
import '../../core/frododesk_modules.dart';
import '../../engines/observation/observation_engine.dart';
import '../../models/spese_snapshot.dart';
import '../../stores/cash_wallet_store.dart';
import '../../stores/expense_category_store.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'builders/spese_month_snapshot_builder.dart';

class SpeseCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final ExpenseCategoryStore categoryStore;
  final CashWalletStore cashWalletStore;
  final SpeseMonthSnapshotBuilder snapshotBuilder;

  const SpeseCoordinator({
    required this.financeStore,
    required this.expenseStore,
    required this.categoryStore,
    required this.cashWalletStore,
    this.snapshotBuilder = const SpeseMonthSnapshotBuilder(),
  });

  Future<SpeseSnapshot> initialize({required DateTime observedAt}) async {
    await expenseStore.load();
    await categoryStore.load();
    await cashWalletStore.load();
    return build(observedAt: observedAt);
  }

  SpeseSnapshot build({required DateTime observedAt}) {
    FrodoDeskBootstrap.initialize(
      expenses: expenseStore.all,
      financeStore: financeStore,
    );
    final observations = ObservationEngine.collect()
        .where((observation) => observation.module == FrodoModules.spese)
        .toList();
    return snapshotBuilder.build(
      expenses: expenseStore.all,
      cashWallets: cashWalletStore.all,
      balances: financeStore.balances,
      categories: categoryStore.all,
      observations: observations,
      observedAt: observedAt,
    );
  }

  Future<SpeseSnapshot> addCategory({
    required String category,
    required DateTime observedAt,
  }) async {
    await categoryStore.addCategory(category);
    return build(observedAt: observedAt);
  }
}
