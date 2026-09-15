import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('absent key and valid empty envelope load as empty', () async {
    expect(await FiniteFinancialPlanPersistence().load(), isEmpty);
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_finite_financial_plans': jsonEncode({
        'version': 1,
        'plans': const [],
      }),
    });
    expect(await FiniteFinancialPlanPersistence().load(), isEmpty);
  });

  test(
    'add persists, notifies once, and reload preserves every field',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);
      final plan = _plan();

      expect(await store.addFiniteFinancialPlan(plan), isTrue);
      expect(notifications, 1);
      expect(store.finiteFinancialPlans, hasLength(1));
      expect(() => store.finiteFinancialPlans.clear(), throwsUnsupportedError);
      final prefs = await SharedPreferences.getInstance();
      final envelope =
          jsonDecode(
                prefs.getString('frododesk_finance_finite_financial_plans')!,
              )
              as Map<String, dynamic>;
      expect(envelope['version'], 1);
      expect((envelope['plans'] as List).single, plan.toJson());

      final restored = FinanceStore();
      await restored.loadSavedFiniteFinancialPlans();
      expect(restored.finiteFinancialPlans.single.toJson(), plan.toJson());
      expect(restored.balances, isEmpty);
      expect(restored.transactions, isEmpty);
      expect(restored.recurringItems, isEmpty);
    },
  );

  test(
    'duplicate add and missing update are rejected without notification',
    () async {
      final plan = _plan();
      final store = FinanceStore(initialFiniteFinancialPlans: [plan]);
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.addFiniteFinancialPlan(plan), isFalse);
      expect(
        await store.updateFiniteFinancialPlan(_plan(id: 'missing')),
        isFalse,
      );
      expect(notifications, 0);
    },
  );

  test(
    'update persists, reloads, notifies once, and identical update is no-op',
    () async {
      final original = _plan();
      final persistence = FiniteFinancialPlanPersistence();
      expect((await persistence.write([original])).isSuccess, isTrue);
      final store = FinanceStore(initialFiniteFinancialPlans: [original]);
      var notifications = 0;
      store.addListener(() => notifications++);
      final updated = _plan(completedInstallments: 3);

      expect(await store.updateFiniteFinancialPlan(updated), isTrue);
      expect(await store.updateFiniteFinancialPlan(updated), isFalse);
      expect(notifications, 1);
      final restored = FinanceStore();
      await restored.loadSavedFiniteFinancialPlans();
      expect(restored.finiteFinancialPlans.single.completedInstallments, 3);
    },
  );

  test(
    'malformed, wrong-root, invalid item and duplicate payloads fail wholly',
    () async {
      final cases = <String>[
        '{broken',
        '[]',
        jsonEncode({
          'version': 1,
          'plans': [42],
        }),
        jsonEncode({
          'version': 1,
          'plans': [_plan().toJson(), _plan().toJson()],
        }),
        jsonEncode({'version': 2, 'plans': const []}),
      ];
      for (final raw in cases) {
        SharedPreferences.setMockInitialValues({
          'frododesk_finance_finite_financial_plans': raw,
        });
        final original = _plan(id: 'memory');
        final store = FinanceStore(initialFiniteFinancialPlans: [original]);
        var notifications = 0;
        store.addListener(() => notifications++);

        await expectLater(
          store.loadSavedFiniteFinancialPlans(),
          throwsFormatException,
        );
        expect(store.finiteFinancialPlans.single.id, 'memory');
        expect(notifications, 0);
      }
    },
  );

  test('invalid decoded plan fails without partial publication', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_finite_financial_plans': jsonEncode({
        'version': 1,
        'plans': [
          _plan(id: 'valid').toJson(),
          {'id': ''},
        ],
      }),
    });
    final store = FinanceStore(
      initialFiniteFinancialPlans: [_plan(id: 'memory')],
    );

    await expectLater(
      store.loadSavedFiniteFinancialPlans(),
      throwsFormatException,
    );
    expect(store.finiteFinancialPlans.single.id, 'memory');
  });

  test(
    'writer failures and mismatched read-back leave memory unchanged',
    () async {
      for (final verification in const [
        PersistenceWriteVerification(backendAccepted: false, readBack: null),
        PersistenceWriteVerification(
          backendAccepted: true,
          readBack: 'different',
        ),
      ]) {
        final original = _plan();
        final store = FinanceStore(
          initialFiniteFinancialPlans: [original],
          finiteFinancialPlanPersistence: FiniteFinancialPlanPersistence(
            saveVerified: (key, value) async => verification,
          ),
        );
        var notifications = 0;
        store.addListener(() => notifications++);

        await expectLater(
          store.updateFiniteFinancialPlan(_plan(completedInstallments: 3)),
          throwsStateError,
        );
        expect(store.finiteFinancialPlans.single.completedInstallments, 2);
        expect(notifications, 0);
      }
    },
  );

  test('lifecycle reloads plans before its final refresh', () async {
    expect(
      (await FiniteFinancialPlanPersistence().write([_plan()])).isSuccess,
      isTrue,
    );
    final store = FinanceStore();
    var refreshed = false;

    await FinanceLifecycleLoader(
      financeStore: store,
      refresh: () {
        expect(store.finiteFinancialPlans, hasLength(1));
        refreshed = true;
      },
    ).load();

    expect(refreshed, isTrue);
  });

  test(
    'plan mutations do not touch economic collections or forecast wiring',
    () async {
      final balance = FinanceBalance(
        balanceId: 'balance',
        personId: 'matteo',
        name: 'Conto',
        initialAmount: 100,
        currentAmount: 100,
        updatedAt: DateTime(2026, 9, 15),
        balanceType: FinanceBalanceType.bankAccount,
        operational: true,
        active: true,
        reservedAmount: 0,
        warningThreshold: 0,
        persistentStressDays: 0,
        recoveryDays: 0,
      );
      final store = FinanceStore(initialBalances: [balance]);

      await store.addFiniteFinancialPlan(_plan());

      expect(store.balances.single.toJson(), balance.toJson());
      expect(store.transactions, isEmpty);
      expect(store.recurringItems, isEmpty);
    },
  );
}

FiniteFinancialPlan _plan({
  String id = 'plan_inps',
  int completedInstallments = 2,
}) => FiniteFinancialPlan(
  id: id,
  name: 'Piano INPS',
  description: 'Piano di test',
  subject: FinanceSubject.matteo,
  creditor: 'INPS',
  debitBalanceId: 'balance',
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: completedInstallments,
);
