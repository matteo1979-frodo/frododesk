import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/adapters/finance_asset_movement_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/finance_transaction_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/real_expense_event_adapter.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  final observedAt = DateTime(2026, 8, 18, 12);

  test('economic event owns immutable endpoints and source links', () {
    final origins = [
      const EconomicEndpoint(
        kind: EconomicEndpointKind.account,
        referenceId: 'account',
        label: 'Conto',
        amount: 50,
      ),
    ];
    final links = [
      const EconomicSourceLink(
        kind: EconomicSourceKind.other,
        recordId: 'legacy',
      ),
    ];
    final event = EconomicEvent(
      id: 'event',
      observedAt: observedAt,
      occurredAt: DateTime(2026, 8, 17),
      origins: origins,
      destinations: const [
        EconomicEndpoint(
          kind: EconomicEndpointKind.external,
          label: 'Negozio',
          amount: 50,
        ),
      ],
      description: 'Acquisto',
      amount: 50,
      nature: EconomicNature.outflow,
      sourceLinks: links,
    );

    origins.clear();
    links.clear();

    expect(event.origins, hasLength(1));
    expect(event.sourceLinks, hasLength(1));
    expect(() => event.origins.clear(), throwsUnsupportedError);
    expect(() => event.relatedEventIds.add('other'), throwsUnsupportedError);
  });

  test(
    'real expense adapter maps expense, income and cash transfer semantics',
    () {
      const adapter = RealExpenseEventAdapter();
      final expense = adapter.adapt(
        _expense(id: 'expense', amount: 30),
        observedAt: observedAt,
      );
      final income = adapter.adapt(
        _expense(id: 'income', amount: 70, isIncome: true),
        observedAt: observedAt,
      );
      final withdrawal = adapter.adapt(
        _expense(
          id: 'withdrawal',
          amount: 100,
          isCashWithdrawal: true,
          cashWalletId: 'wallet_matteo',
        ),
        observedAt: observedAt,
        eventId: 'economic:withdrawal',
      );

      expect(expense.id, 'real_expense:expense');
      expect(expense.nature, EconomicNature.outflow);
      expect(expense.origins.single.kind, EconomicEndpointKind.account);
      expect(expense.destinations.single.kind, EconomicEndpointKind.external);
      expect(expense.category?.id, 'alimentazione');
      expect(expense.personId, 'matteo');
      expect(income.nature, EconomicNature.income);
      expect(income.origins.single.kind, EconomicEndpointKind.external);
      expect(income.destinations.single.kind, EconomicEndpointKind.account);
      expect(withdrawal.id, 'economic:withdrawal');
      expect(withdrawal.nature, EconomicNature.internalTransfer);
      expect(withdrawal.destinations.single.referenceId, 'wallet_matteo');
    },
  );

  test(
    'finance transaction adapter keeps effective and observed dates distinct',
    () {
      final occurredAt = DateTime(2026, 8, 10);
      final event = const FinanceTransactionEventAdapter().adapt(
        FinanceTransaction(
          id: 'transaction',
          balanceId: 'account',
          amount: 45,
          date: occurredAt,
          isIncome: false,
          subject: FinanceSubject.chiara,
          description: 'Farmacia',
          type: FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.manual,
          recurringItemId: 'recurring',
        ),
        observedAt: observedAt,
      );

      expect(event.id, 'finance_transaction:transaction');
      expect(event.observedAt, observedAt);
      expect(event.occurredAt, occurredAt);
      expect(event.nature, EconomicNature.outflow);
      expect(event.personId, 'chiara');
      expect(event.relatedEventIds, ['recurring_item:recurring']);
      expect(event.sourceLinks.single.recordId, 'transaction');
    },
  );

  test(
    'asset movement adapter supports multiple origins and fund destinations',
    () {
      final movement = FinanceAssetMovement(
        id: 'allocation',
        fundId: 'vacanze',
        kind: FinanceAssetMovementKind.fundAllocation,
        description: 'Versamento',
        occurredAt: DateTime(2026, 8, 15),
        legs: const [
          FinanceAssetLeg(
            type: FinanceAssetLegType.balance,
            referenceId: 'matteo',
            delta: -100,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.balance,
            referenceId: 'chiara',
            delta: -50,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: 'vacanze',
            delta: 150,
          ),
        ],
      );
      final event = FinanceAssetMovementEventAdapter(
        category: EconomicCategoryRef.fromLabel('Vacanze'),
      ).adapt(movement, observedAt: observedAt, eventId: 'economic:allocation');

      expect(event.id, 'economic:allocation');
      expect(event.nature, EconomicNature.internalTransfer);
      expect(event.amount, 150);
      expect(event.origins, hasLength(2));
      expect(
        event.origins.map((item) => item.kind),
        everyElement(EconomicEndpointKind.account),
      );
      expect(event.destinations.single.kind, EconomicEndpointKind.fund);
      expect(event.destinations.single.referenceId, 'vacanze');
      expect(
        event.sourceLinks.single.kind,
        EconomicSourceKind.financeAssetMovement,
      );
    },
  );

  test('fund expense is represented as an economic outflow', () {
    final event = const FinanceAssetMovementEventAdapter().adapt(
      FinanceAssetMovement(
        id: 'expense',
        fundId: 'vacanze',
        kind: FinanceAssetMovementKind.fundExpense,
        description: 'Hotel',
        occurredAt: DateTime(2026, 8, 16),
        legs: const [
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: 'vacanze',
            delta: -200,
          ),
          FinanceAssetLeg(type: FinanceAssetLegType.expense, delta: 200),
        ],
      ),
      observedAt: observedAt,
    );

    expect(event.nature, EconomicNature.outflow);
    expect(event.origins.single.kind, EconomicEndpointKind.fund);
    expect(event.destinations.single.kind, EconomicEndpointKind.external);
  });

  test('shared contract has no dependencies on legacy models or UI', () {
    final source = File('lib/models/economic_event.dart').readAsStringSync();

    expect(source, isNot(contains('real_expense.dart')));
    expect(source, isNot(contains('finance_transaction.dart')));
    expect(source, isNot(contains('finance_asset_movement.dart')));
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('PersistenceStore')));
  });
}

RealExpense _expense({
  required String id,
  required double amount,
  bool isIncome = false,
  bool isCashWithdrawal = false,
  String? cashWalletId,
}) => RealExpense(
  id: id,
  balanceId: 'account',
  balanceName: 'Conto Matteo',
  amount: amount,
  description: id,
  category: 'Alimentazione',
  date: DateTime(2026, 8, 17),
  isIncome: isIncome,
  isCashWithdrawal: isCashWithdrawal,
  cashWalletId: cashWalletId,
  subject: FinanceSubject.matteo,
);
