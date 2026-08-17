import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_recurring_item_builder.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_draft.dart';
import 'package:frododesk/models/finance_recurring_item.dart';

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
    expect(finance, contains('FinanceLedgerCoordinator('));
    expect(finance, contains('FinanceRecurringCoordinator('));
    expect(funds, isNot(contains('FinanceStore')));
    expect(ledger, isNot(contains('FinanceStore')));
  });
}
