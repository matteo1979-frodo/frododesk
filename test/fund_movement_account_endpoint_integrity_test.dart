import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_fund_movement_builder.dart';
import 'package:frododesk/logic/finance/finance_fund_lifecycle_coordinator.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/logic/finance/finance_ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_registry_builder.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'account endpoint survives account-fund-account and both ledgers',
    () async {
      const accountId = 'balance_banca_di_imola';
      const fundId = 'test_b4_fondo';
      final account = _account(accountId);
      const fund = FinanceFund(
        id: fundId,
        name: 'TEST B4 FONDO',
        description: '',
        amount: 1.01,
        protected: false,
        category: FinanceFundCategory.generic,
      );
      final openedAt = DateTime(2026, 8, 23, 10);
      final releasedAt = DateTime(2026, 8, 23, 11);

      final openingPlan = const FinanceFundMovementBuilder().open(
        balances: [account],
        funds: const [],
        movements: const [],
        transactions: const [],
        fund: fund,
        sources: const [
          FinanceMoneyPortion(balanceId: accountId, amount: 1.01),
        ],
        preExisting: false,
        occurredAt: openedAt,
        economicFactId: 'fact-opening',
      );
      expect(openingPlan.movements.single.legs.first.referenceId, accountId);

      final store = FinanceStore(initialBalances: [account]);
      final lifecycle = FinanceFundLifecycleCoordinator(
        financeStore: store,
        clock: () => openedAt,
      );
      await lifecycle.openFund(
        fund: fund,
        sources: const [
          FinanceMoneyPortion(balanceId: accountId, amount: 1.01),
        ],
        preExisting: false,
      );

      expect(store.assetMovements.single.legs.first.referenceId, accountId);
      expect(store.fundTransactions, isEmpty);
      expect(store.transactions, isEmpty);

      final releasePlan = const FinanceFundMovementBuilder().release(
        balances: store.balances,
        funds: store.funds,
        movements: store.assetMovements,
        transactions: store.transactions,
        fundId: fundId,
        destinations: const [
          FinanceMoneyPortion(balanceId: accountId, amount: 0.01),
        ],
        description: 'Prelievo di collaudo',
        occurredAt: releasedAt,
        economicFactId: 'fact-release',
      );
      expect(releasePlan.movements.last.legs.last.referenceId, accountId);

      final releaseLifecycle = FinanceFundLifecycleCoordinator(
        financeStore: store,
        clock: () => releasedAt,
      );
      await releaseLifecycle.returnToAccounts(fundId, const [
        FinanceMoneyPortion(balanceId: accountId, amount: 0.01),
      ], 'Prelievo di collaudo');

      expect(store.assetMovements, hasLength(2));
      expect(store.assetMovements.last.legs.last.referenceId, accountId);
      expect(store.balances.single.balanceId, accountId);
      expect(store.balances.single.name, 'Banca di Imola');

      await FinanceLifecycleLoader(financeStore: store, refresh: () {}).load();
      expect(store.balances.single.balanceId, accountId);

      final portfolio = await PersistenceStore.loadJsonMap(
        'finance_portfolio_v2',
      );
      final movementsJson = portfolio!['assetMovements'] as List;
      final openingLegs = (movementsJson.first as Map)['legs'] as List;
      final releaseLegs = (movementsJson.last as Map)['legs'] as List;
      expect((openingLegs.first as Map)['referenceId'], accountId);
      expect((releaseLegs.last as Map)['referenceId'], accountId);

      final restored = FinanceStore();
      expect(await restored.loadSavedPortfolio(), isTrue);
      expect(restored.balances.single.balanceId, accountId);
      expect(restored.assetMovements.first.legs.first.referenceId, accountId);
      expect(restored.assetMovements.last.legs.last.referenceId, accountId);

      final legacy = FinanceLedgerCoordinator(financeStore: restored).build();
      expect(legacy.fundOperations, hasLength(2));
      final legacyOpening = legacy.fundOperations.singleWhere(
        (item) => item.movement.kind == FinanceAssetMovementKind.fundAllocation,
      );
      final legacyRelease = legacy.fundOperations.singleWhere(
        (item) => item.movement.kind == FinanceAssetMovementKind.fundRelease,
      );
      expect(legacyOpening.origins.single.name, 'Banca di Imola');
      expect(legacyRelease.destinations.single.name, 'Banca di Imola');

      final registry = const LedgerEndpointRegistryBuilder().build(
        accounts: restored.balances,
        funds: restored.funds,
        wallets: const [],
        people: restored.people,
      );
      expect(registry.accounts[accountId]?.label, 'Banca di Imola');
      final ledger2 =
          LedgerCoordinator(
            timelineBuilder: LedgerTimelineBuilder(
              endpointResolver: LedgerEndpointResolver(registry: registry),
            ),
          ).build(
            transactions: restored.transactions,
            assetMovements: restored.assetMovements,
            realExpenses: const [],
            observedAt: DateTime(2026, 8, 23, 12),
          );
      expect(ledger2.timeline, hasLength(2));
      expect(
        ledger2.timeline
            .expand((event) => event.counterparties)
            .where((party) => party.referenceId == accountId)
            .map((party) => party.label),
        everyElement('Banca di Imola'),
      );
    },
  );
}

FinanceBalance _account(String id) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: 'Banca di Imola',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 8, 23),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
