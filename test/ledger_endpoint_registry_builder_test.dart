import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/adapters/finance_asset_movement_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/finance_transaction_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/real_expense_event_adapter.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_registry_builder.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/models/cash_wallet.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_person.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  const builder = LedgerEndpointRegistryBuilder();

  test('builds a valid empty registry without synthetic entities', () {
    final registry = builder.build(
      accounts: const [],
      funds: const [],
      wallets: const [],
      people: const [],
    );

    expect(registry.accounts, isEmpty);
    expect(registry.funds, isEmpty);
    expect(registry.cashWallets, isEmpty);
    expect(registry.people, isEmpty);
  });

  test('maps real identities, labels and structurally associated owners', () {
    final registry = _registry();

    expect(registry.accounts['account-a']?.label, 'Conto A');
    expect(registry.accounts['account-a']?.personId, 'matteo');
    expect(
      registry.accounts['account-a']?.balanceType,
      FinanceBalanceType.bankAccount,
    );
    expect(registry.funds['fund-a']?.label, 'Vacanze');
    expect(registry.funds['fund-a']?.personId, isNull);
    expect(registry.cashWallets['wallet-a']?.label, 'Portafoglio Matteo');
    expect(registry.cashWallets['wallet-a']?.personId, 'matteo');
    expect(registry.people['matteo']?.label, 'Matteo');
  });

  test('preserves structural bank account and prepaid balance types', () {
    final registry = builder.build(
      accounts: [
        _balance(id: 'bank'),
        _balance(id: 'prepaid', type: FinanceBalanceType.prepaidCard),
      ],
      funds: const [],
      wallets: const [],
      people: const [],
    );
    final resolver = LedgerEndpointResolver(registry: registry);

    expect(
      resolver
          .resolve(_endpoint(EconomicEndpointKind.account, 'bank'))
          .balanceType,
      FinanceBalanceType.bankAccount,
    );
    expect(
      resolver
          .resolve(_endpoint(EconomicEndpointKind.account, 'prepaid'))
          .balanceType,
      FinanceBalanceType.prepaidCard,
    );
  });

  test('unknown owner is preserved without inventing a person label', () {
    final registry = builder.build(
      accounts: [_balance(id: 'account-a', personId: 'deleted-person')],
      funds: const [],
      wallets: const [],
      people: const [],
    );
    final resolved = LedgerEndpointResolver(
      registry: registry,
    ).resolve(_endpoint(EconomicEndpointKind.account, 'account-a'));

    expect(resolved.personId, 'deleted-person');
    expect(resolved.personLabel, isNull);
  });

  test('supports multiple entities and sorts records by structural id', () {
    final registry = builder.build(
      accounts: [
        _balance(id: 'z'),
        _balance(id: 'a'),
      ],
      funds: [_fund('z'), _fund('a')],
      wallets: [_wallet('z'), _wallet('a')],
      people: const [
        FinancePerson(id: 'z', name: 'Zeta'),
        FinancePerson(id: 'a', name: 'Alfa'),
      ],
    );

    expect(registry.accounts.keys, ['a', 'z']);
    expect(registry.funds.keys, ['a', 'z']);
    expect(registry.cashWallets.keys, ['a', 'z']);
    expect(registry.people.keys, ['a', 'z']);
  });

  test('collapses identical duplicates for every registry', () {
    final registry = builder.build(
      accounts: [_balance(), _balance()],
      funds: [_fund('fund-a'), _fund('fund-a')],
      wallets: [_wallet('wallet-a'), _wallet('wallet-a')],
      people: const [
        FinancePerson(id: 'matteo', name: 'Matteo'),
        FinancePerson(id: 'matteo', name: 'Matteo'),
      ],
    );

    expect(registry.accounts, hasLength(1));
    expect(registry.funds, hasLength(1));
    expect(registry.cashWallets, hasLength(1));
    expect(registry.people, hasLength(1));
  });

  test('rejects conflicting duplicates without depending on input order', () {
    for (final accounts in [
      [_balance(name: 'A'), _balance(name: 'B')],
      [_balance(name: 'B'), _balance(name: 'A')],
    ]) {
      expect(
        () => builder.build(
          accounts: accounts,
          funds: const [],
          wallets: const [],
          people: const [],
        ),
        throwsA(isA<StateError>()),
      );
    }
    expect(
      () => builder.build(
        accounts: const [],
        funds: [
          _fund('fund-a'),
          _fund('fund-a', name: 'Emergenze'),
        ],
        wallets: const [],
        people: const [],
      ),
      throwsStateError,
    );
    expect(
      () => builder.build(
        accounts: const [],
        funds: const [],
        wallets: [
          _wallet('wallet-a'),
          _wallet('wallet-a', name: 'Altro'),
        ],
        people: const [],
      ),
      throwsStateError,
    );
    expect(
      () => builder.build(
        accounts: const [],
        funds: const [],
        wallets: const [],
        people: const [
          FinancePerson(id: 'matteo', name: 'Matteo'),
          FinancePerson(id: 'matteo', name: 'Nome incompatibile'),
        ],
      ),
      throwsStateError,
    );
  });

  test('owns immutable defensive copies and never mutates inputs', () {
    final accounts = [_balance()];
    final registry = builder.build(
      accounts: accounts,
      funds: const [],
      wallets: const [],
      people: const [],
    );
    accounts.clear();

    expect(registry.accounts, hasLength(1));
    expect(() => registry.accounts.clear(), throwsUnsupportedError);
  });

  test('integrates with resolver for current and historical endpoints', () {
    final resolver = LedgerEndpointResolver(registry: _registry());
    final event = EconomicEvent(
      id: 'event',
      observedAt: DateTime(2026, 8, 20),
      occurredAt: DateTime(2026, 8, 19),
      origins: [
        _endpoint(EconomicEndpointKind.account, 'account-a'),
        _endpoint(EconomicEndpointKind.cash, 'wallet-a'),
      ],
      destinations: [
        _endpoint(EconomicEndpointKind.fund, 'fund-a'),
        _endpoint(EconomicEndpointKind.account, 'deleted-account'),
      ],
      description: 'Scenario',
      amount: 10,
      nature: EconomicNature.internalTransfer,
    );
    final resolved = resolver.resolveEvent(event);

    expect(resolved.origins.map((item) => item.label), [
      'Conto A',
      'Portafoglio Matteo',
    ]);
    expect(resolved.origins.first.personLabel, 'Matteo');
    expect(resolved.destinations.first.label, 'Vacanze');
    expect(resolved.destinations.last.usesHistoricalFallback, isTrue);
  });

  test('leaves external, opening balance and legacy fallback to resolver', () {
    final resolver = LedgerEndpointResolver(
      registry: builder.build(
        accounts: const [],
        funds: const [],
        wallets: const [],
        people: const [],
      ),
    );

    expect(
      resolver.resolve(_endpoint(EconomicEndpointKind.external, null)).label,
      'Soggetto esterno',
    );
    expect(
      resolver
          .resolve(_endpoint(EconomicEndpointKind.openingBalance, null))
          .label,
      'Saldo iniziale',
    );
    expect(
      resolver.resolve(_endpoint(EconomicEndpointKind.other, null)).label,
      'Riferimento precedente',
    );
  });

  test('adapter reference ids resolve against real model ids', () {
    final resolver = LedgerEndpointResolver(registry: _registry());
    final observedAt = DateTime(2026, 8, 20);
    final transaction = const FinanceTransactionEventAdapter().adapt(
      FinanceTransaction(
        id: 'transaction',
        balanceId: 'account-a',
        amount: 10,
        date: observedAt,
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: 'Spesa',
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
      ),
      observedAt: observedAt,
    );
    final movement = const FinanceAssetMovementEventAdapter().adapt(
      FinanceAssetMovement(
        id: 'movement',
        fundId: 'fund-a',
        kind: FinanceAssetMovementKind.fundAllocation,
        description: 'Conto a fondo',
        occurredAt: observedAt,
        legs: const [
          FinanceAssetLeg(
            type: FinanceAssetLegType.balance,
            referenceId: 'account-a',
            delta: -10,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: 'fund-a',
            delta: 10,
          ),
        ],
      ),
      observedAt: observedAt,
    );
    final withdrawal = const RealExpenseEventAdapter().adapt(
      RealExpense(
        id: 'withdrawal',
        balanceId: 'account-a',
        balanceName: 'Conto A',
        amount: 10,
        description: 'Prelievo',
        category: 'Contanti',
        date: observedAt,
        isCashWithdrawal: true,
        cashWalletId: 'wallet-a',
        subject: FinanceSubject.matteo,
      ),
      observedAt: observedAt,
    );

    expect(resolver.resolveEvent(transaction).origins.single.label, 'Conto A');
    expect(resolver.resolveEvent(movement).origins.single.label, 'Conto A');
    expect(
      resolver.resolveEvent(movement).destinations.single.label,
      'Vacanze',
    );
    expect(
      resolver.resolveEvent(withdrawal).destinations.single.label,
      'Portafoglio Matteo',
    );
  });

  test('builder has no Flutter, store or persistence dependencies', () {
    final source = File(
      'lib/logic/ledger/ledger_endpoint_registry_builder.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('SharedPreferences')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('EconomicEvent')));
  });
}

LedgerEndpointRegistry _registry() =>
    const LedgerEndpointRegistryBuilder().build(
      accounts: [_balance()],
      funds: [_fund('fund-a')],
      wallets: [_wallet('wallet-a')],
      people: const [FinancePerson(id: 'matteo', name: 'Matteo')],
    );

FinanceBalance _balance({
  String id = 'account-a',
  String name = 'Conto A',
  String personId = 'matteo',
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) => FinanceBalance(
  personId: personId,
  balanceId: id,
  name: name,
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 8, 20),
  balanceType: type,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceFund _fund(String id, {String name = 'Vacanze'}) => FinanceFund(
  id: id,
  name: name,
  description: '',
  amount: 100,
  protected: false,
  category: FinanceFundCategory.generic,
);

CashWallet _wallet(String id, {String name = 'Portafoglio Matteo'}) =>
    CashWallet(id: id, personId: 'matteo', name: name, currentAmount: 20);

EconomicEndpoint _endpoint(EconomicEndpointKind kind, String? referenceId) =>
    EconomicEndpoint(
      kind: kind,
      referenceId: referenceId,
      label: '',
      amount: 10,
    );
