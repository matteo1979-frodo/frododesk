import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_recurring_item_builder.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_draft.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/income.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('Finance card separates income management from direct creation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final modern = IncomeRelationship(
      relationshipId: 'income:modern',
      label: 'Entrata moderna',
      category: IncomeCategoryKind.other,
      subject: FinanceSubject.shared,
      expectedOrdinaryAmount: 123,
      periodicity: IncomePeriodicity.monthly,
      firstExpectedDate: DateTime(2026, 10, 10),
    );
    final legacy = const FinanceRecurringItemBuilder().build(
      FinanceRecurringDraft(
        name: 'Entrata legacy da ignorare',
        description: '',
        expectedAmount: 999,
        nextDueDate: DateTime(2026, 10, 10),
        isIncome: true,
        recurringType: FinanceRecurringType.monthly,
        category: FinanceCategory.salary,
        paymentOwner: FinancePaymentOwner.shared,
        subject: FinanceSubject.shared,
        paymentMethod: FinancePaymentMethod.manual,
        templateType: FinanceSmartTemplateType.salary,
        mandatory: false,
        paymentPriority: FinancePaymentPriority.normal,
        variability: FinanceVariability.fixed,
        protectionLevel: FinanceProtectionLevel.none,
        stability: FinanceStability.stable,
        suspensionRisk: FinanceSuspensionRisk.low,
        behaviorProfile: const FinanceBehaviorProfile(),
      ),
      DateTime(2026, 9, 1),
    );
    final store = FinanceStore(
      initialRecurringItems: [legacy],
      initialIncomeAggregate: IncomeAggregate(relationships: [modern]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: store,
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
          forecastReferenceTime: DateTime(2026, 10, 2),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 voci • €123,00'), findsOneWidget);
    expect(find.text('Entrata moderna'), findsOneWidget);
    expect(find.text('Entrata legacy da ignorare'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Entrate'), findsNothing);
    expect(find.text('Uscite previste'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Aggiungi uscita'),
      findsOneWidget,
    );

    await tester.tap(find.text('Entrate previste'));
    await tester.pumpAndSettle();
    expect(find.text('Passato reale, futuro previsto'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Aggiungi entrata'));
    await tester.pumpAndSettle();
    expect(find.text('Passato reale, futuro previsto'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Nuova entrata'), findsNWidgets(2));
  });
}
