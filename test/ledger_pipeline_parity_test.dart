import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/ledger_snapshot.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  final observedAt = DateTime(2026, 8, 30, 12);
  late LedgerCoordinator coordinator;

  setUp(() => coordinator = _coordinator());

  test('empty, basic income/outflow and global deterministic order', () {
    final empty = _build(coordinator, observedAt: observedAt);
    final snapshot = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction('outflow', date: DateTime(2026, 8, 20)),
        _transaction('income', income: true, date: DateTime(2026, 8, 22)),
        _transaction('same-b', date: DateTime(2026, 8, 21)),
        _transaction('same-a', date: DateTime(2026, 8, 21)),
      ],
    );

    expect(empty.isArchiveEmpty, isTrue);
    expect(snapshot.timeline.map((event) => event.eventId), [
      'finance_transaction:income',
      'finance_transaction:same-a',
      'finance_transaction:same-b',
      'finance_transaction:outflow',
    ]);
    expect(snapshot.timeline.first.nature, EconomicNature.income);
    expect(snapshot.timeline.last.nature, EconomicNature.outflow);
  });

  test(
    'real expense parity: correlated once, legacy distinct, real facts distinct',
    () {
      final correlated = _build(
        coordinator,
        observedAt: observedAt,
        transactions: [_transaction('tx', factId: 'expense-fact')],
        expenses: [_expense('expense', factId: 'expense-fact')],
      );
      final legacy = _build(
        coordinator,
        observedAt: observedAt,
        transactions: [_transaction('legacy-tx')],
        expenses: [_expense('legacy-expense')],
      );
      final distinct = _build(
        coordinator,
        observedAt: observedAt,
        expenses: [
          _expense('same-a', factId: 'fact-a', description: 'Identica'),
          _expense('same-b', factId: 'fact-b', description: 'Identica'),
        ],
      );

      expect(correlated.timeline, hasLength(1));
      final event = correlated.timeline.single;
      expect(event.amount, 20);
      expect(event.nature, EconomicNature.outflow);
      expect(event.category?.id, 'casa');
      expect(event.personId, 'matteo');
      expect(event.personLabel, 'Matteo');
      expect(
        event.counterparties.where(
          (party) => party.role == LedgerCounterpartyRole.origin,
        ),
        hasLength(1),
      );
      expect(event.sourceLinks.map((link) => link.kind).toSet(), {
        EconomicSourceKind.realExpense,
        EconomicSourceKind.financeTransaction,
      });
      expect(legacy.timeline, hasLength(2));
      expect(distinct.timeline, hasLength(2));
    },
  );

  test('extra income and recurring occurrences preserve distinct facts', () {
    final income = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [_transaction('income', income: true, factId: 'income')],
      expenses: [_expense('income-expense', income: true, factId: 'income')],
    );
    final recurring = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction(
          'salary-august',
          income: true,
          factId: 'salary-2026-08',
          recurringItemId: 'salary-rule',
        ),
        _transaction(
          'salary-september',
          income: true,
          factId: 'salary-2026-09',
          recurringItemId: 'salary-rule',
          date: DateTime(2026, 9, 20),
        ),
      ],
    );

    expect(income.timeline.single.nature, EconomicNature.income);
    expect(income.timeline.single.economicSign, LedgerEconomicSign.positive);
    expect(recurring.timeline, hasLength(2));
    expect(recurring.timeline.map((event) => event.eventId).toSet(), {
      'economic_fact:salary-2026-08',
      'economic_fact:salary-2026-09',
    });
  });

  test('account to cash and account to account become single transfers', () {
    final cash = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction('cash-tx', factId: 'cash-fact', balanceId: 'account-a'),
      ],
      expenses: [
        _expense(
          'cash-expense',
          factId: 'cash-fact',
          cashWithdrawal: true,
          balanceId: 'account-a',
        ),
      ],
    );
    final accountTransfer = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction(
          'transfer-out',
          factId: 'account-transfer',
          type: FinanceTransactionType.transfer,
          balanceId: 'account-a',
        ),
        _transaction(
          'transfer-in',
          factId: 'account-transfer',
          type: FinanceTransactionType.transfer,
          balanceId: 'account-b',
          income: true,
        ),
      ],
    );

    _expectTransfer(cash.timeline.single, 'Conto Matteo', 'Contanti Matteo');
    _expectTransfer(
      accountTransfer.timeline.single,
      'Conto Matteo',
      'Conto Chiara',
    );
  });

  test('semantic metadata survives the full prepaid transfer pipeline', () {
    final snapshot = coordinator.build(
      transactions: [
        _transaction(
          'prepaid-out',
          factId: 'prepaid-transfer',
          type: FinanceTransactionType.transfer,
          balanceId: 'account-a',
          notes: 'Verso prepagata',
        ),
        _transaction(
          'prepaid-in',
          factId: 'prepaid-transfer',
          type: FinanceTransactionType.transfer,
          balanceId: 'account-b',
          income: true,
          notes: 'Da conto corrente',
        ),
      ],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
      query: 'verso prepagata',
    );

    final event = snapshot.timeline.single;
    expect(event.nature, EconomicNature.internalTransfer);
    expect(event.notes, ['Da conto corrente', 'Verso prepagata']);
    expect(event.transactionOrigins, [EconomicTransactionOrigin.manual]);
    expect(
      event.counterparties.first.balanceType,
      FinanceBalanceType.bankAccount,
    );
    expect(
      event.counterparties.last.balanceType,
      FinanceBalanceType.prepaidCard,
    );
  });

  test(
    'account/fund, fund/account and fund/fund transfers preserve endpoints',
    () {
      final accountFund = _build(
        coordinator,
        observedAt: observedAt,
        movements: [
          _movement(
            'account-fund',
            'account-fund',
            FinanceAssetMovementKind.fundAllocation,
            const [
              FinanceAssetLeg(
                type: FinanceAssetLegType.balance,
                referenceId: 'account-a',
                delta: -20,
              ),
              FinanceAssetLeg(
                type: FinanceAssetLegType.fund,
                referenceId: 'fund-a',
                delta: 20,
              ),
            ],
          ),
        ],
      );
      final fundAccount = _build(
        coordinator,
        observedAt: observedAt,
        movements: [
          _movement(
            'fund-account',
            'fund-account',
            FinanceAssetMovementKind.fundRelease,
            const [
              FinanceAssetLeg(
                type: FinanceAssetLegType.fund,
                referenceId: 'fund-a',
                delta: -20,
              ),
              FinanceAssetLeg(
                type: FinanceAssetLegType.balance,
                referenceId: 'account-a',
                delta: 20,
              ),
            ],
          ),
        ],
      );
      const fundLegs = [
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: 'fund-a',
          delta: -20,
        ),
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: 'fund-b',
          delta: 20,
        ),
      ];
      final fundFund = _build(
        coordinator,
        observedAt: observedAt,
        movements: [
          _movement(
            'fund-out',
            'fund-transfer',
            FinanceAssetMovementKind.fundTransferOut,
            fundLegs,
          ),
          _movement(
            'fund-in',
            'fund-transfer',
            FinanceAssetMovementKind.fundTransferIn,
            fundLegs,
            fundId: 'fund-b',
          ),
        ],
      );

      _expectTransfer(accountFund.timeline.single, 'Conto Matteo', 'Vacanze');
      _expectTransfer(fundAccount.timeline.single, 'Vacanze', 'Conto Matteo');
      _expectTransfer(fundFund.timeline.single, 'Vacanze', 'Auto');
      expect(fundFund.timeline.single.sourceLinks, hasLength(2));
    },
  );

  test('fund expense merges patrimonial and transaction records once', () {
    final snapshot = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction(
          'fund-expense-tx',
          factId: 'fund-expense',
          balanceId: 'fund-a',
          origin: FinanceTransactionOrigin.fund,
        ),
      ],
      movements: [
        _movement(
          'fund-expense-movement',
          'fund-expense',
          FinanceAssetMovementKind.fundExpense,
          const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'fund-a',
              delta: -20,
            ),
            FinanceAssetLeg(type: FinanceAssetLegType.expense, delta: 20),
          ],
        ),
      ],
    );

    expect(snapshot.timeline, hasLength(1));
    final event = snapshot.timeline.single;
    expect(event.nature, EconomicNature.outflow);
    expect(event.counterparties.first.label, 'Vacanze');
    expect(event.sourceLinks, hasLength(2));
  });

  test('adjustments and cancellations stay independent economic facts', () {
    final snapshot = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction(
          'adjustment',
          factId: 'adjustment-fact',
          origin: FinanceTransactionOrigin.adjustment,
        ),
        _transaction('cancellation', factId: 'cancellation-fact', income: true),
      ],
    );

    expect(snapshot.timeline, hasLength(2));
    expect(snapshot.timeline.map((event) => event.eventId).toSet(), {
      'economic_fact:adjustment-fact',
      'economic_fact:cancellation-fact',
    });
  });

  test('endpoint registry covers concrete and neutral historical cases', () {
    final snapshot = _build(
      coordinator,
      observedAt: observedAt,
      transactions: [
        _transaction('account', balanceId: 'account-a'),
        _transaction('missing-account', balanceId: 'deleted-account'),
      ],
      movements: [
        _movement(
          'opening',
          null,
          FinanceAssetMovementKind.legacyOpening,
          const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.openingBalance,
              delta: -20,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'deleted-fund',
              delta: 20,
            ),
          ],
        ),
        _movement(
          'legacy',
          null,
          FinanceAssetMovementKind.legacyUnclassified,
          const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.legacyCounterpart,
              delta: -20,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'fund-a',
              delta: 20,
            ),
          ],
        ),
      ],
      expenses: [
        _expense(
          'missing-cash',
          cashWithdrawal: true,
          cashWalletId: 'deleted-cash',
        ),
      ],
    );

    final labels = snapshot.timeline
        .expand((event) => event.counterparties)
        .map((party) => party.label)
        .toList();
    expect(labels, contains('Conto Matteo'));
    expect(labels.any((label) => label.startsWith('Conto non')), isTrue);
    expect(labels.any((label) => label.startsWith('Fondo non')), isTrue);
    expect(labels.any((label) => label.startsWith('Portafoglio non')), isTrue);
    expect(labels, contains('Saldo già esistente'));
    expect(labels, contains('Contropartita precedente'));
  });

  test(
    'input order and post-build mutations do not affect immutable result',
    () {
      final transactions = [
        _transaction('a', date: DateTime(2026, 8, 20)),
        _transaction('b', date: DateTime(2026, 8, 21)),
      ];
      final forward = _build(
        coordinator,
        observedAt: observedAt,
        transactions: transactions,
      );
      final reverse = _build(
        coordinator,
        observedAt: observedAt,
        transactions: transactions.reversed.toList(),
      );
      transactions.clear();

      expect(
        reverse.timeline.map((event) => event.eventId),
        forward.timeline.map((event) => event.eventId),
      );
      expect(forward.timeline, hasLength(2));
      expect(() => forward.timeline.clear(), throwsUnsupportedError);
      expect(() => forward.availableFilters.clear(), throwsUnsupportedError);
    },
  );

  test('documents intentional Ledger 2.0 differences without touching UI', () {
    const intentionalDifferences = {
      'global timeline instead of two legacy blocks',
      'one canonical row for a shared economicFactId',
      'deterministic global ordering',
      'neutral historical fallbacks',
      'structural filters',
      'unresolved person labels are not invented',
      'legacy null economicFactId records remain distinct',
    };
    final coordinatorSource = File(
      'lib/logic/ledger/ledger_coordinator.dart',
    ).readAsStringSync();

    expect(intentionalDifferences, hasLength(7));
    expect(coordinatorSource, isNot(contains('FinanceLedgerPage')));
    expect(coordinatorSource, isNot(contains('package:flutter')));
  });
}

LedgerCoordinator _coordinator() => LedgerCoordinator(
  timelineBuilder: LedgerTimelineBuilder(
    endpointResolver: LedgerEndpointResolver(
      registry: LedgerEndpointRegistry(
        accounts: const {
          'account': LedgerEndpointRecord(
            id: 'account',
            label: 'Conto Famiglia',
            personId: 'matteo',
            balanceType: FinanceBalanceType.bankAccount,
          ),
          'account-a': LedgerEndpointRecord(
            id: 'account-a',
            label: 'Conto Matteo',
            personId: 'matteo',
            balanceType: FinanceBalanceType.bankAccount,
          ),
          'account-b': LedgerEndpointRecord(
            id: 'account-b',
            label: 'Conto Chiara',
            personId: 'chiara',
            balanceType: FinanceBalanceType.prepaidCard,
          ),
        },
        funds: const {
          'fund-a': LedgerEndpointRecord(id: 'fund-a', label: 'Vacanze'),
          'fund-b': LedgerEndpointRecord(id: 'fund-b', label: 'Auto'),
        },
        cashWallets: const {
          'cash': LedgerEndpointRecord(
            id: 'cash',
            label: 'Contanti Matteo',
            personId: 'matteo',
          ),
        },
        people: const {
          'matteo': LedgerPersonRecord(id: 'matteo', label: 'Matteo'),
          'chiara': LedgerPersonRecord(id: 'chiara', label: 'Chiara'),
        },
      ),
    ),
  ),
);

LedgerSnapshot _build(
  LedgerCoordinator coordinator, {
  required DateTime observedAt,
  List<FinanceTransaction> transactions = const [],
  List<FinanceAssetMovement> movements = const [],
  List<RealExpense> expenses = const [],
}) => coordinator.build(
  transactions: transactions,
  assetMovements: movements,
  realExpenses: expenses,
  observedAt: observedAt,
);

FinanceTransaction _transaction(
  String id, {
  String? factId,
  bool income = false,
  FinanceTransactionType? type,
  FinanceTransactionOrigin origin = FinanceTransactionOrigin.manual,
  String balanceId = 'account',
  String? description,
  String? recurringItemId,
  DateTime? date,
  String? notes,
}) => FinanceTransaction(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  amount: 20,
  date: date ?? DateTime(2026, 8, 20),
  isIncome: income,
  subject: FinanceSubject.matteo,
  description: description ?? id,
  type:
      type ??
      (income ? FinanceTransactionType.income : FinanceTransactionType.expense),
  origin: origin,
  recurringItemId: recurringItemId,
  notes: notes,
);

RealExpense _expense(
  String id, {
  String? factId,
  String? description,
  bool income = false,
  bool cashWithdrawal = false,
  String balanceId = 'account',
  String cashWalletId = 'cash',
}) => RealExpense(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  balanceName: 'Conto Famiglia',
  amount: 20,
  description: description ?? id,
  category: 'Casa',
  date: DateTime(2026, 8, 20),
  isIncome: income,
  isCashWithdrawal: cashWithdrawal,
  cashWalletId: cashWithdrawal ? cashWalletId : null,
  subject: FinanceSubject.matteo,
);

FinanceAssetMovement _movement(
  String id,
  String? factId,
  FinanceAssetMovementKind kind,
  List<FinanceAssetLeg> legs, {
  String fundId = 'fund-a',
}) => FinanceAssetMovement(
  id: id,
  economicFactId: factId,
  fundId: fundId,
  kind: kind,
  description: id,
  occurredAt: DateTime(2026, 8, 20),
  legs: legs,
);

void _expectTransfer(
  LedgerEventViewModel event,
  String origin,
  String destination,
) {
  expect(event.nature, EconomicNature.internalTransfer);
  expect(event.economicSign, LedgerEconomicSign.neutral);
  final origins = event.counterparties
      .where((party) => party.role == LedgerCounterpartyRole.origin)
      .toList();
  final destinations = event.counterparties
      .where((party) => party.role == LedgerCounterpartyRole.destination)
      .toList();
  expect(origins, hasLength(1));
  expect(destinations, hasLength(1));
  expect(origins.single.label, origin);
  expect(destinations.single.label, destination);
}
