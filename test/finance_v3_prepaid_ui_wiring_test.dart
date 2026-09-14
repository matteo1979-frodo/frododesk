import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_commit.dart';
import 'package:frododesk/logic/finance/finance_prepaid_creation.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/screens/account_detail_screen.dart';
import 'package:frododesk/screens/person_finance_screen.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'new prepaid uses one atomic creation with zero and preserves mapping',
    (tester) async {
      final parent = _balance();
      final store = await _authoritativeStore(parent);
      await _pump(tester, store, parent);

      await _openAddDialog(tester);
      await _selectPrepaid(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Carta test');
      await tester.enterText(find.byType(TextField).at(1), 'Nota test');
      await tester.tap(find.text('Nessuna scadenza'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(store.createCalls, 1);
      expect(store.addCalls, 0);
      expect(store.balances, hasLength(2));
      final prepaid = store.balances.singleWhere(
        (item) => item.balanceType == FinanceBalanceType.prepaidCard,
      );
      final linked = store.linkedItems.single;
      expect(prepaid.personId, parent.personId);
      expect(prepaid.initialAmount, 0);
      expect(prepaid.currentAmount, 0);
      expect(linked.balanceId, parent.balanceId);
      expect(linked.autonomousBalanceId, prepaid.balanceId);
      expect(linked.name, 'Carta test');
      expect(linked.description, 'Nota test');
      expect(linked.expirationDate, isNotNull);
    },
  );

  testWidgets('literal zero remains zero', (tester) async {
    final parent = _balance();
    final store = await _authoritativeStore(parent);
    await _pump(tester, store, parent);

    await _openAddDialog(tester);
    await _selectPrepaid(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Carta zero');
    await tester.enterText(find.byType(TextField).at(2), '0');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(store.createCalls, 1);
    expect(store.addCalls, 0);
    expect(
      store.balances
          .singleWhere(
            (item) => item.balanceType == FinanceBalanceType.prepaidCard,
          )
          .currentAmount,
      0,
    );
  });

  testWidgets('invalid prepaid amount is rejected before domain creation', (
    tester,
  ) async {
    final parent = _balance();
    final store = await _authoritativeStore(parent);
    await _pump(tester, store, parent);

    await _openAddDialog(tester);
    await _selectPrepaid(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Carta invalida');
    await tester.enterText(find.byType(TextField).at(2), 'abc');
    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(store.createCalls, 0);
    expect(store.addCalls, 0);
    expect(store.balances, hasLength(1));
    expect(store.linkedItems, isEmpty);
    expect(find.text('Importo non valido'), findsOneWidget);
  });

  testWidgets('other linked types keep addLinkedItem path', (tester) async {
    final parent = _balance();
    final store = await _authoritativeStore(parent);
    await _pump(tester, store, parent);

    await _openAddDialog(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Bancomat test');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(store.createCalls, 0);
    expect(store.addCalls, 1);
    expect(
      store.linkedItems.single.type,
      FinanceAccountLinkedItemType.debitCard,
    );
    expect(store.balances, hasLength(1));
  });

  testWidgets('editing keeps replaceLinkedItem path', (tester) async {
    final parent = _balance();
    final existing = FinanceAccountLinkedItem(
      id: 'linked',
      balanceId: parent.balanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: 'Carta esistente',
      description: '',
    );
    final store = await _authoritativeStore(parent, linkedItems: [existing]);
    await _pump(tester, store, parent);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Carta modificata');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(store.createCalls, 0);
    expect(store.addCalls, 0);
    expect(store.replaceCalls, 1);
    expect(store.linkedItems.single.name, 'Carta modificata');
  });

  testWidgets('editing an associated prepaid updates both records atomically', (
    tester,
  ) async {
    final parent = _balance();
    final prepaid = _prepaidBalance();
    final existing = FinanceAccountLinkedItem(
      id: 'linked_prepaid',
      balanceId: parent.balanceId,
      autonomousBalanceId: prepaid.balanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: 'Carta test',
      description: 'Prima',
      amount: 0,
    );
    final store = await _authoritativeStore(
      parent,
      linkedItems: [existing],
      extraBalances: [prepaid],
    );
    await _pump(tester, store, parent);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Carta reale');
    await tester.enterText(find.byType(TextField).at(1), 'Nuova descrizione');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(store.updatePairCalls, 1);
    expect(store.replaceCalls, 0);
    expect(store.linkedItems.single.name, 'Carta reale');
    expect(store.linkedItems.single.description, 'Nuova descrizione');
    expect(store.linkedItems.single.autonomousBalanceId, prepaid.balanceId);
    expect(
      store.balances
          .singleWhere((item) => item.balanceId == prepaid.balanceId)
          .name,
      'Carta reale',
    );
  });

  testWidgets('editing another linked type keeps the existing path', (
    tester,
  ) async {
    final parent = _balance();
    final existing = FinanceAccountLinkedItem(
      id: 'linked_debit',
      balanceId: parent.balanceId,
      type: FinanceAccountLinkedItemType.debitCard,
      name: 'Bancomat',
      description: '',
    );
    final store = await _authoritativeStore(parent, linkedItems: [existing]);
    await _pump(tester, store, parent);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Bancomat aggiornato');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(store.updatePairCalls, 0);
    expect(store.replaceCalls, 1);
    expect(store.linkedItems.single.name, 'Bancomat aggiornato');
  });

  testWidgets(
    'person finance cannot rename an associated prepaid in isolation',
    (tester) async {
      final parent = _balance();
      final prepaid = _prepaidBalance();
      final linked = FinanceAccountLinkedItem(
        id: 'linked_prepaid',
        balanceId: parent.balanceId,
        autonomousBalanceId: prepaid.balanceId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: prepaid.name,
        description: '',
      );
      final store = await _authoritativeStore(
        parent,
        linkedItems: [linked],
        extraBalances: [prepaid],
      );
      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PersonFinanceScreen(
            financeStore: store,
            personId: 'matteo',
            personName: 'Matteo',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica conto'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      expect(nameField.readOnly, isTrue);
      expect(
        find.text('Modifica il nome dal rapporto collegato'),
        findsOneWidget,
      );
      expect(store.balances.last.name, prepaid.name);
      expect(store.linkedItems.single.name, prepaid.name);
    },
  );

  testWidgets('V3 required failure has no fallback or partial creation', (
    tester,
  ) async {
    final parent = _balance();
    final store = _SpyFinanceStore(initialBalances: [parent]);
    await _pump(tester, store, parent);

    await _openAddDialog(tester);
    await _selectPrepaid(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Carta rifiutata');
    await tester.tap(find.text('Salva'));
    await tester.pump();

    expect(store.createCalls, 1);
    expect(store.addCalls, 0);
    expect(store.balances, hasLength(1));
    expect(store.linkedItems, isEmpty);
    expect(
      find.textContaining('Finance Portfolio V3 must be authoritative'),
      findsOneWidget,
    );
  });
}

class _SpyFinanceStore extends FinanceStore {
  _SpyFinanceStore({super.initialBalances});

  int createCalls = 0;
  int addCalls = 0;
  int replaceCalls = 0;
  int updatePairCalls = 0;

  @override
  Future<FinancePrepaidCreationResult> createLinkedPrepaid(
    FinancePrepaidCreationInput input,
  ) {
    createCalls++;
    return super.createLinkedPrepaid(input);
  }

  @override
  Future<bool> addLinkedItem(FinanceAccountLinkedItem item) {
    addCalls++;
    return super.addLinkedItem(item);
  }

  @override
  Future<bool> replaceLinkedItem(FinanceAccountLinkedItem item) {
    replaceCalls++;
    return super.replaceLinkedItem(item);
  }

  @override
  Future<FinancePortfolioV3CommitResult> updateLinkedPrepaidPair({
    required String linkedItemId,
    required String name,
    required String description,
    required DateTime? expirationDate,
    required double? amount,
  }) {
    updatePairCalls++;
    return super.updateLinkedPrepaidPair(
      linkedItemId: linkedItemId,
      name: name,
      description: description,
      expirationDate: expirationDate,
      amount: amount,
    );
  }
}

Future<_SpyFinanceStore> _authoritativeStore(
  FinanceBalance parent, {
  List<FinanceAccountLinkedItem> linkedItems = const [],
  List<FinanceBalance> extraBalances = const [],
}) async {
  final portfolio = FinancePortfolioV3(
    balances: [parent, ...extraBalances],
    funds: const [],
    assetMovements: const [],
    transactions: const [],
    fundTransactions: const [],
    linkedItems: linkedItems,
  );
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final store = _SpyFinanceStore();
  expect(await store.loadSavedPortfolioV3(), isTrue);
  return store;
}

Future<void> _pump(
  WidgetTester tester,
  FinanceStore store,
  FinanceBalance parent,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: AccountDetailScreen(financeStore: store, balance: parent),
    ),
  );
  await tester.pump();
}

Future<void> _openAddDialog(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Aggiungi'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Aggiungi'));
  await tester.pumpAndSettle();
}

Future<void> _selectPrepaid(WidgetTester tester) async {
  await tester.tap(find.text('Bancomat').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Prepagata').last);
  await tester.pumpAndSettle();
}

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'parent',
  name: 'Banca di Imola',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime.utc(2026, 9, 11),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceBalance _prepaidBalance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'prepaid',
  name: 'Carta test',
  initialAmount: 0,
  currentAmount: 0,
  updatedAt: DateTime.utc(2026, 9, 11),
  balanceType: FinanceBalanceType.prepaidCard,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
