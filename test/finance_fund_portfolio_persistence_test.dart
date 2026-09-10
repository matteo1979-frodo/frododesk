import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('legacy migration preserves funds and their previous history', () async {
    final store = FinanceStore(
      initialFunds: [_fund(500)],
      initialFundTransactions: [
        FundTransaction(
          id: 'old-withdraw',
          fundId: 'vacanze',
          description: 'Acconto viaggio',
          amount: 100,
          date: DateTime(2025, 6, 1),
          type: FundTransactionType.withdraw,
        ),
      ],
    );

    await store.migrateLegacyPortfolio();

    expect(store.funds.single.amount, 500);
    expect(
      store.funds.single.openingKind,
      FinanceFundOpeningKind.legacyImported,
    );
    expect(store.assetMovements, hasLength(2));
    expect(
      store.assetMovements.every(
        (movement) => movement.accountingDelta.abs() < 0.001,
      ),
      isTrue,
    );

    final restored = FinanceStore();
    expect(await restored.loadSavedPortfolio(), isTrue);
    expect(restored.funds.single.amount, 500);
    expect(restored.assetMovements, hasLength(2));
  });

  test('later account saves keep the versioned portfolio coherent', () async {
    final store = FinanceStore(
      initialBalances: [_balance(1000)],
      initialFunds: [_fund(500)],
    );
    await store.migrateLegacyPortfolio();

    await store.replaceBalance(_balance(750));

    final restored = FinanceStore();
    expect(await restored.loadSavedPortfolio(), isTrue);
    expect(restored.balances.single.currentAmount, 750);
    expect(restored.funds.single.amount, 500);
  });
}

FinanceFund _fund(double amount) => FinanceFund(
  id: 'vacanze',
  name: 'Vacanze',
  description: 'Viaggi',
  amount: amount,
  protected: false,
  category: FinanceFundCategory.generic,
);

FinanceBalance _balance(double amount) => FinanceBalance(
  personId: 'matteo',
  balanceId: 'conto',
  name: 'Conto Matteo',
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime(2026, 8, 11),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
