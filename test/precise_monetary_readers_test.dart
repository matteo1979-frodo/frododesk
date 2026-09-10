import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_observation_reader.dart';
import 'package:frododesk/logic/finance/planner/planner_decision_engine.dart';
import 'package:frododesk/logic/spese/spese_month_reader.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('Finance reader formats exact balances including cents and thousands', () {
    final now = DateTime.now();
    final observations = FinanceObservationReader.analyze(
      FinanceStore(
        initialBalances: [
          _balance('matteo', 100.25, now),
          _balance('chiara', 1234.56, now),
        ],
      ),
    );
    final economic = observations.singleWhere(
      (item) => item.title == 'Situazione economica',
    );

    expect(
      economic.details,
      'Matteo: €100,25\nChiara: €1.234,56\nFamiglia: €1.334,81',
    );
  });

  test('Finance reader formats exact outgoing and incoming directions once', () {
    final now = DateTime.now();
    final expense = _item(
      id: 'expense',
      name: 'Affitto',
      amount: 100.25,
      dueDate: now,
    );
    final income = _item(
      id: 'income',
      name: 'Rimborso',
      amount: 1234.56,
      dueDate: now.add(const Duration(days: 1)),
      isIncome: true,
    );
    final observations = FinanceObservationReader.analyze(
      FinanceStore(initialRecurringItems: [expense, income]),
    );
    final deadlines = observations.singleWhere(
      (item) => item.title == 'Scadenze',
    );
    final upcomingIncome = observations.singleWhere(
      (item) => item.title == 'Entrate in arrivo',
    );

    expect(deadlines.details, contains('Affitto: -€100,25'));
    expect(upcomingIncome.message, contains('+€1.234,56'));
    expect(upcomingIncome.message, isNot(contains('++')));
  });

  test('Spese reader formats exact total but preserves approximate difference', () {
    final current = [_expense('current', 200.25)];
    final previous = [_expense('previous', 100)];
    final observations = SpeseMonthReader.analyze(
      currentMonthExpenses: current,
      previousMonthExpenses: previous,
    );
    final total = observations.singleWhere((item) => item.title == 'Totale mese');
    final comparison = observations.singleWhere(
      (item) => item.title == 'Spese in aumento',
    );

    expect(
      total.message,
      'Il totale delle spese reali registrate nel mese è €200,25.',
    );
    expect(
      comparison.message,
      'Questo mese hai registrato circa €100 in più rispetto al mese precedente.',
    );
  });

  test('Planner formats exact amounts and keeps declared approximations', () {
    final now = DateTime.now();
    final exact = PlannerDecisionEngine.analyze(
      items: [
        _item(
          id: 'critical',
          name: 'Assicurazione',
          amount: 1234.56,
          dueDate: now,
          mandatory: true,
        ),
      ],
    ).single;
    expect(exact.reason, contains('€1.234,56'));

    final approximate = PlannerDecisionEngine.analyze(
      items: [
        _item(
          id: 'threshold',
          name: 'Acquisto',
          amount: 1100.25,
          dueDate: now,
          balanceId: 'conto',
        ),
      ],
      balances: [_balance('matteo', 1500.25, now, warningThreshold: 500.5)],
    ).single;

    expect(approximate.reason, contains('disponibili circa €1500'));
    expect(approximate.reason, contains('uscita da €1.100,25'));
    expect(approximate.reason, contains('resterebbero circa €400'));
    expect(approximate.reason, contains('soglia minima impostata di €500,50'));
  });

  test('Readers and planner delegate only precise money to EuroFormatter', () {
    final financeReader = File(
      'lib/logic/finance/finance_observation_reader.dart',
    ).readAsStringSync();
    final speseReader = File(
      'lib/logic/spese/spese_month_reader.dart',
    ).readAsStringSync();
    final planner = File(
      'lib/logic/finance/planner/planner_decision_engine.dart',
    ).readAsStringSync();

    expect(financeReader, contains("import '../../utils/euro_formatter.dart';"));
    expect(speseReader, contains("import '../../utils/euro_formatter.dart';"));
    expect(planner, contains("import '../../../utils/euro_formatter.dart';"));
    expect(speseReader, contains('circa €\${difference.toStringAsFixed(0)}'));
    expect(planner, contains('circa €\${_money(before)}'));
  });
}

FinanceBalance _balance(
  String personId,
  double amount,
  DateTime updatedAt, {
  double warningThreshold = 0,
}) => FinanceBalance(
  personId: personId,
  balanceId: personId == 'matteo' ? 'conto' : 'conto_$personId',
  name: 'Conto',
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: updatedAt,
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: warningThreshold,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceRecurringItem _item({
  required String id,
  required String name,
  required double amount,
  required DateTime dueDate,
  bool isIncome = false,
  bool mandatory = false,
  String? balanceId,
}) => FinanceRecurringItem(
  id: id,
  name: name,
  description: name,
  expectedAmount: amount,
  nextDueDate: dueDate,
  isIncome: isIncome,
  recurringType: FinanceRecurringType.oneShot,
  category: FinanceCategory.generic,
  requiresManualConfirmation: true,
  mandatory: mandatory,
  pressureLevel: FinancePressureLevel.low,
  confirmed: false,
  variability: FinanceVariability.fixed,
  paymentPriority: mandatory
      ? FinancePaymentPriority.critical
      : FinancePaymentPriority.normal,
  protectionLevel: FinanceProtectionLevel.none,
  paymentOwner: FinancePaymentOwner.matteo,
  balanceId: balanceId,
  paymentMethod: FinancePaymentMethod.manual,
  stability: FinanceStability.stable,
  suspensionRisk: FinanceSuspensionRisk.low,
  originType: FinanceOriginType.manual,
  splits: const [],
);

RealExpense _expense(String id, double amount) => RealExpense(
  id: id,
  balanceId: 'conto',
  balanceName: 'Conto',
  amount: amount,
  description: id,
  category: 'Casa',
  date: DateTime.now(),
);
