import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/fund_transaction.dart';

void main() {
  group('FinancePortfolioV3Contract', () {
    test('builds a complete deterministic V3 payload', () {
      final portfolio = _portfolio();

      final first = FinancePortfolioV3Contract.build(portfolio);
      final second = FinancePortfolioV3Contract.build(portfolio);

      expect(first, second);
      expect(first['version'], 3);
      expect(first.keys, [
        'version',
        'balances',
        'funds',
        'assetMovements',
        'transactions',
        'fundTransactions',
        'linkedItems',
      ]);
      for (final field in first.keys.skip(1)) {
        expect(first[field], isA<List<dynamic>>());
      }
      final linked = (first['linkedItems'] as List).single as Map;
      expect(linked['balanceId'], 'parent_bank');
      expect(linked['autonomousBalanceId'], 'prepaid_balance');
    });

    test('round-trip reconstructs every collection semantically', () {
      final original = _portfolio(includeRecords: true);

      final result = FinancePortfolioV3Contract.parse(
        FinancePortfolioV3Contract.build(original),
      );

      expect(result.isSuccess, isTrue);
      expect(result.errors, isEmpty);
      expect(
        FinancePortfolioV3Contract.build(result.value!),
        FinancePortfolioV3Contract.build(original),
      );
      expect(
        () => result.value!.balances.add(_balance('other')),
        throwsUnsupportedError,
      );
      expect(() => result.errors.add('error'), throwsUnsupportedError);
    });

    test('accepts a legacy linked item without autonomousBalanceId in V3', () {
      final json = FinancePortfolioV3Contract.build(_portfolio());
      final linked =
          (json['linkedItems'] as List).single as Map<String, dynamic>;
      linked.remove('autonomousBalanceId');

      final result = FinancePortfolioV3Contract.parse(json);

      expect(result.isSuccess, isTrue);
      expect(result.value!.linkedItems.single.autonomousBalanceId, isNull);
    });

    test('rejects missing, V2 and unsupported versions', () {
      final missing = FinancePortfolioV3Contract.build(_portfolio())
        ..remove('version');
      final v2 = FinancePortfolioV3Contract.build(_portfolio())
        ..['version'] = 2;
      final future = FinancePortfolioV3Contract.build(_portfolio())
        ..['version'] = 4;

      expect(FinancePortfolioV3Contract.parse(missing).isSuccess, isFalse);
      expect(FinancePortfolioV3Contract.parse(v2).isSuccess, isFalse);
      expect(FinancePortfolioV3Contract.parse(future).isSuccess, isFalse);
    });

    test('rejects required lists with wrong types and invalid elements', () {
      final wrongList = FinancePortfolioV3Contract.build(_portfolio())
        ..['funds'] = <String, dynamic>{};
      final invalidElement = FinancePortfolioV3Contract.build(_portfolio())
        ..['transactions'] = ['invalid'];

      expect(FinancePortfolioV3Contract.parse(wrongList).isSuccess, isFalse);
      expect(
        FinancePortfolioV3Contract.parse(invalidElement).isSuccess,
        isFalse,
      );
    });

    test('rejects a missing parent balance', () {
      final result = FinancePortfolioV3Validator.validate(
        _portfolio(linkedParentId: 'missing_parent'),
      );

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('missing parent balance'));
    });

    test('rejects a missing autonomous balance', () {
      final result = FinancePortfolioV3Validator.validate(
        _portfolio(linkedAutonomousId: 'missing_prepaid'),
      );

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('missing autonomous balance'));
    });

    test('rejects an autonomous balance with the wrong type', () {
      final result = FinancePortfolioV3Validator.validate(
        _portfolio(autonomousType: FinanceBalanceType.bankAccount),
      );

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('is not prepaidCard'));
    });

    test('rejects a self reference', () {
      final result = FinancePortfolioV3Validator.validate(
        _portfolio(
          autonomousId: 'parent_bank',
          includeAutonomousBalance: false,
        ),
      );

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('parent balance as autonomous')));
    });

    test('rejects duplicate balance ids', () {
      final portfolio = _portfolio();
      final duplicate = FinancePortfolioV3(
        balances: [...portfolio.balances, _balance('parent_bank')],
        funds: portfolio.funds,
        assetMovements: portfolio.assetMovements,
        transactions: portfolio.transactions,
        fundTransactions: portfolio.fundTransactions,
        linkedItems: portfolio.linkedItems,
      );

      final result = FinancePortfolioV3Validator.validate(duplicate);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Duplicate balanceId: parent_bank'));
    });

    test('rejects duplicate linked item ids', () {
      final portfolio = _portfolio();
      final duplicate = FinancePortfolioV3(
        balances: portfolio.balances,
        funds: portfolio.funds,
        assetMovements: portfolio.assetMovements,
        transactions: portfolio.transactions,
        fundTransactions: portfolio.fundTransactions,
        linkedItems: [...portfolio.linkedItems, portfolio.linkedItems.single],
      );

      final result = FinancePortfolioV3Validator.validate(duplicate);

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains('Duplicate linkedItem.id: linked_prepaid'),
      );
    });

    test('validates identities without matching names', () {
      final sameNames = _portfolio(parentName: 'Uguale', prepaidName: 'Uguale');
      final differentNames = _portfolio(
        parentName: 'Conto completamente diverso',
        prepaidName: 'Carta senza corrispondenza',
      );

      expect(FinancePortfolioV3Validator.validate(sameNames).isValid, isTrue);
      expect(
        FinancePortfolioV3Validator.validate(differentNames).isValid,
        isTrue,
      );
    });

    test('has no store, persistence, V2 or Flutter dependencies', () {
      final source = File(
        'lib/logic/finance/finance_portfolio_v3_contract.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('package:flutter/')));
      expect(source, isNot(contains('/stores/')));
      expect(source, isNot(contains('persistence_store')));
      expect(source, isNot(contains('finance_portfolio_v2')));
    });
  });
}

FinancePortfolioV3 _portfolio({
  String parentId = 'parent_bank',
  String autonomousId = 'prepaid_balance',
  String? linkedParentId,
  String? linkedAutonomousId,
  FinanceBalanceType autonomousType = FinanceBalanceType.prepaidCard,
  bool includeAutonomousBalance = true,
  bool includeRecords = false,
  String parentName = 'Conto padre',
  String prepaidName = 'Prepagata autonoma',
}) {
  final parent = _balance(parentId, name: parentName);
  final prepaid = _balance(
    autonomousId,
    name: prepaidName,
    type: autonomousType,
  );
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fondo',
    description: 'Test',
    amount: 10,
    protected: false,
    category: FinanceFundCategory.generic,
  );

  return FinancePortfolioV3(
    balances: [parent, if (includeAutonomousBalance) prepaid],
    funds: includeRecords ? [fund] : const [],
    assetMovements: includeRecords
        ? [
            FinanceAssetMovement(
              id: 'movement',
              fundId: fund.id,
              kind: FinanceAssetMovementKind.fundAllocation,
              description: 'Allocazione',
              occurredAt: DateTime.utc(2026, 1, 2),
              legs: const [
                FinanceAssetLeg(
                  type: FinanceAssetLegType.balance,
                  referenceId: 'parent_bank',
                  delta: -10,
                ),
                FinanceAssetLeg(
                  type: FinanceAssetLegType.fund,
                  referenceId: 'fund',
                  delta: 10,
                ),
              ],
              economicFactId: 'fact',
            ),
          ]
        : const [],
    transactions: includeRecords
        ? [
            FinanceTransaction(
              id: 'transaction',
              balanceId: parentId,
              amount: 5,
              date: DateTime.utc(2026, 1, 3),
              isIncome: false,
              subject: FinanceSubject.shared,
              description: 'Spesa',
              type: FinanceTransactionType.expense,
              origin: FinanceTransactionOrigin.manual,
              economicFactId: 'transaction_fact',
            ),
          ]
        : const [],
    fundTransactions: includeRecords
        ? [
            FundTransaction(
              id: 'fund_transaction',
              fundId: fund.id,
              description: 'Versamento',
              amount: 10,
              date: DateTime.utc(2026, 1, 2),
              type: FundTransactionType.deposit,
            ),
          ]
        : const [],
    linkedItems: [
      FinanceAccountLinkedItem(
        id: 'linked_prepaid',
        balanceId: linkedParentId ?? parentId,
        autonomousBalanceId: linkedAutonomousId ?? autonomousId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: 'Carta collegata',
        description: 'Test',
      ),
    ],
  );
}

FinanceBalance _balance(
  String id, {
  String? name,
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) {
  return FinanceBalance(
    personId: 'person',
    balanceId: id,
    name: name ?? id,
    initialAmount: 100,
    currentAmount: 100,
    updatedAt: DateTime.utc(2026, 1, 1),
    balanceType: type,
    operational: true,
    active: true,
    reservedAmount: 0,
    warningThreshold: 0,
    persistentStressDays: 0,
    recoveryDays: 0,
  );
}
