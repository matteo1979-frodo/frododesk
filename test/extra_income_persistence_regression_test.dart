import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_ledger_coordinator.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/spese_command.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('extra income survives a complete store restart exactly once', () async {
    final financeStore = FinanceStore();
    final expenseStore = ExpenseStore();
    final cashWalletStore = CashWalletStore();
    await financeStore.loadInitialRealData();
    await expenseStore.load();
    await cashWalletStore.load();
    final balance = financeStore.balances.first;
    final previousAmount = balance.currentAmount;
    const commandId = 'test_b3_entrata';
    final economicFactId = 'economic_fact_spese_$commandId';

    await SpeseMutationCoordinator(
      financeStore: financeStore,
      expenseStore: expenseStore,
      cashWalletStore: cashWalletStore,
    ).execute(
      SpeseCommand(
        id: commandId,
        kind: SpeseCommandKind.extraIncome,
        action: SpeseCommandAction.create,
        preparedAt: DateTime(2026, 8, 19, 12),
        occurredAt: DateTime(2026, 8, 19),
        origin: const SpeseCommandEndpoint(
          kind: EconomicEndpointKind.external,
          label: 'Esterno',
        ),
        destination: SpeseCommandEndpoint(
          kind: EconomicEndpointKind.account,
          referenceId: balance.balanceId,
          label: balance.name,
        ),
        amount: 0.01,
        category: 'Entrata extra',
        personId: 'matteo',
        description: 'TEST B3 ENTRATA',
      ),
    );

    expect(
      expenseStore.all.where((item) => item.id == commandId),
      hasLength(1),
    );
    expect(
      financeStore.transactions.where(
        (item) => item.economicFactId == economicFactId,
      ),
      hasLength(1),
    );
    expect(
      financeStore.balances
          .singleWhere((item) => item.balanceId == balance.balanceId)
          .currentAmount,
      closeTo(previousAmount + 0.01, 0.000001),
    );

    financeStore.dispose();
    expenseStore.dispose();
    cashWalletStore.dispose();

    final restoredFinanceStore = FinanceStore();
    final restoredExpenseStore = ExpenseStore();
    final restoredCashWalletStore = CashWalletStore();
    await restoredFinanceStore.loadInitialRealData();
    await restoredExpenseStore.load();
    await restoredCashWalletStore.load();

    final restoredExpenses = restoredExpenseStore.all
        .where((item) => item.id == commandId)
        .toList();
    final restoredTransactions = restoredFinanceStore.transactions
        .where((item) => item.economicFactId == economicFactId)
        .toList();
    expect(restoredExpenses, hasLength(1));
    expect(restoredTransactions, hasLength(1));
    expect(restoredExpenses.single.economicFactId, economicFactId);
    expect(restoredTransactions.single.economicFactId, economicFactId);
    expect(
      restoredFinanceStore.balances
          .singleWhere((item) => item.balanceId == balance.balanceId)
          .currentAmount,
      closeTo(previousAmount + 0.01, 0.000001),
    );
    expect(
      FinanceLedgerCoordinator(financeStore: restoredFinanceStore)
          .build()
          .entries
          .where((entry) => entry.transaction.economicFactId == economicFactId),
      hasLength(1),
    );
  });
}
