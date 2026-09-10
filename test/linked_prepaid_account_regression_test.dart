import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/screens/account_detail_screen.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/widgets/finance/finance_accounts_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'linked prepaid with null amount does not create an autonomous balance',
    (tester) async {
      final account = _balance(
        id: 'findomestic',
        name: 'Findomestic',
        amount: 120.40,
      );
      final store = FinanceStore(initialBalances: [account]);
      await store.migrateLegacyPortfolio();

      await _pumpAccountDetail(tester, store: store, account: account);
      await _addLinkedPrepaid(tester, name: 'Prepagata Findomestic');

      expect(store.linkedItems, hasLength(1));
      expect(
        store.linkedItems.single.type,
        FinanceAccountLinkedItemType.prepaidCard,
      );
      expect(store.linkedItems.single.amount, isNull);
      expect(store.balances, hasLength(1));
      expect(store.balances.single.balanceId, account.balanceId);
      expect(store.totalBalance(), 120.40);
      expect(store.familyNetWorth(), 120.40);
    },
  );

  testWidgets(
    'linked prepaid amount remains informational and does not duplicate wealth',
    (tester) async {
      final account = _balance(
        id: 'findomestic',
        name: 'Findomestic',
        amount: 120.40,
      );
      final store = FinanceStore(initialBalances: [account]);
      await store.migrateLegacyPortfolio();

      await _pumpAccountDetail(tester, store: store, account: account);
      await _addLinkedPrepaid(
        tester,
        name: 'Prepagata Findomestic',
        amount: '120,40',
      );

      expect(store.linkedItems.single.amount, 120.40);
      expect(store.balances, hasLength(1));
      expect(store.totalBalance(), 120.40);
      expect(store.familyNetWorth(), 120.40);
    },
  );

  testWidgets(
    'linked prepaid persists and reloads without generating a balance',
    (tester) async {
      final account = _balance(
        id: 'findomestic',
        name: 'Findomestic',
        amount: 120.40,
      );
      final store = FinanceStore(initialBalances: [account]);
      await store.migrateLegacyPortfolio();

      await _pumpAccountDetail(tester, store: store, account: account);
      await _addLinkedPrepaid(
        tester,
        name: 'Prepagata Findomestic',
        amount: '120.40',
      );

      final restored = FinanceStore();
      await restored.loadInitialRealData();

      expect(restored.linkedItems, hasLength(1));
      expect(restored.linkedItems.single.name, 'Prepagata Findomestic');
      expect(restored.linkedItems.single.amount, 120.40);
      expect(restored.balances, hasLength(1));
      expect(restored.balances.single.balanceId, account.balanceId);
      expect(restored.balances.single.currentAmount, 120.40);
      expect(restored.totalBalance(), 120.40);
      expect(restored.familyNetWorth(), 120.40);
    },
  );

  testWidgets(
    'deactivating a linked prepaid leaves balances and wealth unchanged',
    (tester) async {
      final account = _balance(
        id: 'findomestic',
        name: 'Findomestic',
        amount: 120.40,
      );
      final store = FinanceStore(initialBalances: [account]);
      await store.migrateLegacyPortfolio();

      await _pumpAccountDetail(tester, store: store, account: account);
      await _addLinkedPrepaid(tester, name: 'Prepagata Findomestic');
      final balancesBefore = store.balances.toList();
      final wealthBefore = store.familyNetWorth();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(store.linkedItems.single.active, isFalse);
      expect(store.balances, orderedEquals(balancesBefore));
      expect(store.familyNetWorth(), wealthBefore);
    },
  );

  testWidgets(
    'explicit prepaid balance keeps its autonomous balance after reload',
    (tester) async {
      final store = FinanceStore();
      await store.migrateLegacyPortfolio();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FinanceAccountsPanel(financeStore: store)),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Nuovo conto'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Carta viaggio');
      await tester.enterText(find.byType(TextField).at(1), '75,50');
      await tester.tap(find.text('Conto bancario').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carta prepagata').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crea conto'));
      await tester.pumpAndSettle();

      expect(store.balances, hasLength(1));
      expect(store.balances.single.balanceType, FinanceBalanceType.prepaidCard);
      expect(store.balances.single.currentAmount, 75.50);

      final restored = FinanceStore();
      await restored.loadInitialRealData();

      expect(restored.balances, hasLength(1));
      expect(restored.balances.single.name, 'Carta viaggio');
      expect(
        restored.balances.single.balanceType,
        FinanceBalanceType.prepaidCard,
      );
      expect(restored.balances.single.currentAmount, 75.50);
      expect(restored.totalBalance(), 75.50);
    },
  );
}

Future<void> _pumpAccountDetail(
  WidgetTester tester, {
  required FinanceStore store,
  required FinanceBalance account,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: AccountDetailScreen(financeStore: store, balance: account),
    ),
  );
  await tester.pump();
}

Future<void> _addLinkedPrepaid(
  WidgetTester tester, {
  required String name,
  String? amount,
}) async {
  await tester.scrollUntilVisible(
    find.text('Aggiungi'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Aggiungi'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Bancomat').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Prepagata').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).at(0), name);
  if (amount != null) {
    await tester.enterText(find.byType(TextField).at(2), amount);
  }
  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();
}

FinanceBalance _balance({
  required String id,
  required String name,
  required double amount,
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: name,
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime(2026, 9, 9),
  balanceType: type,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
