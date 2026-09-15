import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_recurring_item_builder.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_draft.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_demo_data.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('smart template supplies modern recurring defaults', () {
    final defaults = const FinanceRecurringItemBuilder().defaultsFor(
      FinanceSmartTemplateType.utilityBill,
    );

    expect(defaults.paymentMethod, FinancePaymentMethod.rid);
    expect(defaults.behaviorProfile.timeSensitive, isTrue);
    expect(defaults.behaviorProfile.canBeSplit, isTrue);
  });

  test('builder preserves advanced metadata and percentage splits', () {
    const builder = FinanceRecurringItemBuilder();
    final draft = FinanceRecurringDraft(
      name: 'Bolletta',
      description: '',
      expectedAmount: 200,
      nextDueDate: DateTime(2026, 9, 1),
      isIncome: false,
      recurringType: FinanceRecurringType.monthly,
      category: FinanceCategory.house,
      paymentOwner: FinancePaymentOwner.shared,
      subject: FinanceSubject.shared,
      paymentMethod: FinancePaymentMethod.rid,
      templateType: FinanceSmartTemplateType.utilityBill,
      matteoPercentage: 30,
      chiaraPercentage: 70,
      mandatory: true,
      paymentPriority: FinancePaymentPriority.critical,
      variability: FinanceVariability.fixed,
      protectionLevel: FinanceProtectionLevel.protected,
      stability: FinanceStability.unstable,
      suspensionRisk: FinanceSuspensionRisk.high,
      behaviorProfile: const FinanceBehaviorProfile(timeSensitive: true),
    );

    final item = builder.build(draft, DateTime(2026, 8, 11));

    expect(item.splits.map((split) => split.amount), [60, 140]);
    expect(item.mandatory, isTrue);
    expect(item.paymentPriority, FinancePaymentPriority.critical);
    expect(item.variability, FinanceVariability.fixed);
    expect(item.protectionLevel, FinanceProtectionLevel.protected);
    expect(item.stability, FinanceStability.unstable);
    expect(item.suspensionRisk, FinanceSuspensionRisk.high);
    expect(item.behaviorProfile.timeSensitive, isTrue);
    expect(item.toJson()['paymentMethod'], 'rid');
  });

  test('custom percentage split must total one hundred percent', () {
    const builder = FinanceRecurringItemBuilder();
    final draft = FinanceRecurringDraft(
      name: 'Bolletta',
      description: '',
      expectedAmount: 100,
      nextDueDate: DateTime(2026, 9, 1),
      isIncome: false,
      recurringType: FinanceRecurringType.monthly,
      category: FinanceCategory.house,
      paymentOwner: FinancePaymentOwner.shared,
      subject: FinanceSubject.shared,
      paymentMethod: FinancePaymentMethod.rid,
      templateType: FinanceSmartTemplateType.utilityBill,
      matteoPercentage: 30,
      chiaraPercentage: 60,
      mandatory: true,
      paymentPriority: FinancePaymentPriority.high,
      variability: FinanceVariability.variable,
      protectionLevel: FinanceProtectionLevel.none,
      stability: FinanceStability.stable,
      suspensionRisk: FinanceSuspensionRisk.low,
      behaviorProfile: const FinanceBehaviorProfile(),
    );

    expect(builder.validate(draft), 'La ripartizione deve totalizzare 100%');
  });

  test('modern finance UI delegates recovered features to coordinators', () {
    final finance = File('lib/screens/finance_screen.dart').readAsStringSync();
    final funds = File(
      'lib/screens/finance/finance_funds_page.dart',
    ).readAsStringSync();
    final ledger = File(
      'lib/screens/finance/finance_ledger_page.dart',
    ).readAsStringSync();

    expect(finance, contains('FinanceFundsCoordinator('));
    expect(finance, contains('FinanceLedgerPresentationCoordinator('));
    expect(finance, contains('FinanceRecurringCoordinator('));
    expect(funds, isNot(contains('FinanceStore')));
    expect(ledger, isNot(contains('FinanceStore')));
  });

  test(
    'active recurring presentation structurally excludes confirmed items',
    () {
      final finance = File(
        'lib/screens/finance_screen.dart',
      ).readAsStringSync();

      expect(
        finance,
        matches(
          RegExp(r'where\(\(item\) => item\.isIncome && !item\.confirmed\)'),
        ),
      );
      expect(
        finance,
        matches(
          RegExp(r'where\(\(item\) => !item\.isIncome && !item\.confirmed\)'),
        ),
      );
      expect(
        finance,
        contains(
          '.where((item) => item.isIncome == isIncome && !item.confirmed)',
        ),
      );
    },
  );

  testWidgets(
    'FinanceScreen shows the next active occurrence and hides its history',
    (tester) async {
      await initializeDateFormatting('it_IT');
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final template = demoRecurringItems.firstWhere(
        (item) =>
            !item.isIncome &&
            item.recurringType == FinanceRecurringType.monthly,
      );
      final historical = template.copyWith(
        id: 'history-2026-08-19',
        name: 'TEST B3 RICORRENZA',
        nextDueDate: DateTime(2026, 8, 19),
        confirmed: true,
        realAmount: 0.01,
      );
      final active = template.copyWith(
        id: 'active-2026-09-19',
        name: 'TEST B3 RICORRENZA',
        nextDueDate: DateTime(2026, 9, 19),
        confirmed: false,
        realAmount: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FinanceScreen(
            financeStore: FinanceStore(
              initialRecurringItems: [historical, active],
            ),
            expenseStore: ExpenseStore(),
            cashWalletStore: CashWalletStore(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Uscite previste'), findsOneWidget);
      expect(find.text('TEST B3 RICORRENZA'), findsWidgets);
      expect(find.textContaining('19/09/2026'), findsWidgets);
      expect(find.textContaining('19/08/2026'), findsNothing);
    },
  );

  testWidgets('fifth active expense remains reachable through Vedi tutte', (
    tester,
  ) async {
    await initializeDateFormatting('it_IT');
    await tester.binding.setSurfaceSize(const Size(1400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final template = demoRecurringItems.firstWhere(
      (item) =>
          !item.isIncome && item.recurringType == FinanceRecurringType.monthly,
    );
    final activeItems = [
      for (var index = 0; index < 4; index++)
        template.copyWith(
          id: 'earlier-$index',
          name: 'Precedente $index',
          nextDueDate: DateTime(2026, 8, 20 + index),
          confirmed: false,
          realAmount: null,
        ),
      template.copyWith(
        id: 'active-2026-09-19',
        name: 'TEST B3 RICORRENZA',
        nextDueDate: DateTime(2026, 9, 19),
        confirmed: false,
        realAmount: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: FinanceStore(initialRecurringItems: activeItems),
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('TEST B3 RICORRENZA'), findsNothing);
    expect(find.text('Vedi tutte'), findsOneWidget);
    await tester.tap(find.text('Vedi tutte'));
    await tester.pumpAndSettle();

    expect(find.text('TEST B3 RICORRENZA'), findsOneWidget);
    expect(find.textContaining('19/09/2026'), findsOneWidget);
  });

  testWidgets('FinanceScreen uses Italian euro presentation end to end', (
    tester,
  ) async {
    await initializeDateFormatting('it_IT');
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final expenseTemplate = demoRecurringItems.firstWhere(
      (item) => !item.isIncome,
    );
    final incomeTemplate = demoRecurringItems.firstWhere(
      (item) => item.isIncome,
    );
    final items = [
      expenseTemplate.copyWith(
        id: 'octopus-60',
        name: 'Luce Octopus',
        expectedAmount: 60,
        nextDueDate: DateTime(2026, 9, 1),
        confirmed: false,
        realAmount: null,
      ),
      expenseTemplate.copyWith(
        id: 'expense-2461',
        name: 'Altre uscite',
        expectedAmount: 2461,
        nextDueDate: DateTime(2026, 9, 2),
        confirmed: false,
        realAmount: null,
      ),
      incomeTemplate.copyWith(
        id: 'income-1495-01',
        name: 'Entrata precisa',
        expectedAmount: 1495.01,
        nextDueDate: DateTime(2026, 9, 3),
        confirmed: false,
        realAmount: null,
      ),
    ];
    final negativeBalance = FinanceBalance(
      personId: 'matteo',
      balanceId: 'negative-balance',
      name: 'Conto negativo',
      initialAmount: -1234.56,
      currentAmount: -1234.56,
      updatedAt: DateTime(2026, 8, 21),
      balanceType: FinanceBalanceType.bankAccount,
      operational: true,
      active: true,
      reservedAmount: 0,
      warningThreshold: 0,
      persistentStressDays: 0,
      recoveryDays: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: FinanceStore(
            initialBalances: [negativeBalance],
            initialRecurringItems: items,
          ),
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('-€60,00'), findsOneWidget);
    expect(find.text('+€1.495,01'), findsOneWidget);
    expect(find.text('2 voci • €2.521,00'), findsOneWidget);
    expect(find.text('-€1.234,56'), findsWidgets);
    expect(find.textContaining('€0,00'), findsWidgets);

    await tester.tap(find.text('Luce Octopus').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Importo previsto'), findsOneWidget);
    expect(find.text('€60,00'), findsOneWidget);
  });
}
