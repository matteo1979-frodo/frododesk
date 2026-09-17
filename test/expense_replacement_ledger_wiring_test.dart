import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expense_replacement_metadata.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/ledger_snapshot.dart';

void main() {
  final observedAt = DateTime(2026, 9, 17, 12);
  late LedgerCoordinator coordinator;

  setUp(() {
    coordinator = LedgerCoordinator(
      timelineBuilder: LedgerTimelineBuilder(
        endpointResolver: LedgerEndpointResolver(
          registry: LedgerEndpointRegistry(
            accounts: const {
              'account-current': LedgerEndpointRecord(
                id: 'account-current',
                label: 'Conto corrente',
                personId: 'matteo',
              ),
              'account-history': LedgerEndpointRecord(
                id: 'account-history',
                label: 'Conto storico',
                personId: 'chiara',
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
  });

  test('ordinary event keeps its existing timeline semantics', () {
    final result = _build(coordinator, observedAt, [
      _transaction('ordinary', 'ordinary-fact', 'Spesa ordinaria'),
    ]);

    expect(result.timeline, hasLength(1));
    expect(result.timeline.single.title, 'Spesa ordinaria');
    expect(result.timeline.single.replacementHistory, isEmpty);
  });

  test('complete modern A to B becomes current B with preserved history', () {
    final records = _replacement('A', 'B');

    final result = _build(coordinator, observedAt, records);

    expect(result.timeline, hasLength(1));
    final current = result.timeline.single;
    expect(current.eventId, 'economic_fact:B');
    expect(current.title, 'Current B');
    expect(current.replacementHistory, hasLength(1));
    expect(current.replacementHistory.single.originalEconomicFactId, 'A');
    expect(current.replacementHistory.single.replacementEconomicFactId, 'B');
  });

  test('modern A to B to C becomes C with two ordered edges', () {
    final first = _replacement('A', 'B');
    final second = _replacement('B', 'C', includeOriginal: false);

    final result = _build(coordinator, observedAt, [...first, ...second]);

    expect(result.timeline, hasLength(1));
    expect(result.timeline.single.title, 'Current C');
    expect(
      result.timeline.single.replacementHistory.map(
        (edge) =>
            '${edge.originalEconomicFactId}->${edge.replacementEconomicFactId}',
      ),
      ['A->B', 'B->C'],
    );
  });

  test('incomplete, ambiguous and cyclic components remain separate', () {
    final incomplete = _replacement('I-A', 'I-B')..removeAt(1);
    final ambiguous = _replacement('D-A', 'D-B');
    ambiguous.insert(
      2,
      _marked(
        'duplicate-compensation',
        'duplicate-compensation-fact',
        'D-A',
        'D-B',
        ExpenseReplacementRole.compensation,
      ),
    );
    final cycle = [
      _marked(
        'cycle-A',
        'C-A',
        'C-B',
        'C-A',
        ExpenseReplacementRole.replacement,
      ),
      _marked(
        'cycle-K-AB',
        'C-K-AB',
        'C-A',
        'C-B',
        ExpenseReplacementRole.compensation,
      ),
      _marked(
        'cycle-B',
        'C-B',
        'C-A',
        'C-B',
        ExpenseReplacementRole.replacement,
      ),
      _marked(
        'cycle-K-BA',
        'C-K-BA',
        'C-B',
        'C-A',
        ExpenseReplacementRole.compensation,
      ),
    ];

    final result = _build(coordinator, observedAt, [
      ...incomplete,
      ...ambiguous,
      ...cycle,
    ]);

    expect(
      result.timeline,
      hasLength(incomplete.length + ambiguous.length + cycle.length),
    );
    expect(
      result.timeline.every((entry) => entry.replacementHistory.isEmpty),
      isTrue,
    );
  });

  test('legacy records and an ordinary event remain independent beside B', () {
    final modern = _replacement('A', 'B');
    final legacy = [
      _transaction('legacy-original', null, 'Farmacia'),
      _transaction('legacy-compensation', null, 'Annullamento Farmacia'),
      _transaction('legacy-replacement', null, 'Farmacia test modifica'),
    ];
    final ordinary = _transaction('ordinary', 'ordinary', 'Evento ordinario');

    final result = _build(coordinator, observedAt, [
      ...modern,
      ...legacy,
      ordinary,
    ]);

    expect(result.timeline, hasLength(5));
    expect(
      result.timeline.where((entry) => entry.title == 'Current B'),
      hasLength(1),
    );
    expect(
      result.timeline.where((entry) => entry.title.contains('Farmacia')),
      hasLength(3),
    );
    expect(
      result.timeline.where((entry) => entry.title == 'Evento ordinario'),
      hasLength(1),
    );
  });

  test('search filters and counts use only the current replacement', () {
    final records = _replacement(
      'A',
      'B',
      originalBalanceId: 'account-history',
      replacementBalanceId: 'account-current',
    );

    final currentSearch = _build(
      coordinator,
      observedAt,
      records,
      query: 'current b',
    );
    final historySearch = _build(
      coordinator,
      observedAt,
      records,
      query: 'original a',
    );
    final currentFilter = _build(
      coordinator,
      observedAt,
      records,
      selectedFilterIds: const {'account:account-current'},
    );
    final historyFilter = _build(
      coordinator,
      observedAt,
      records,
      selectedFilterIds: const {'account:account-history'},
    );

    expect(currentSearch.totalEventCount, 1);
    expect(currentSearch.filteredEventCount, 1);
    expect(historySearch.filteredEventCount, 0);
    expect(currentFilter.filteredEventCount, 1);
    expect(historyFilter.selectedFilterIds, isEmpty);
    expect(historyFilter.filteredEventCount, 1);
  });

  test(
    'utility composite facts remain separate and semantically unchanged',
    () {
      final main = _transaction(
        'hera-main',
        'hera-main-fact',
        'Bolletta Hera',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'hera-operation',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
        ),
      );
      final fee = _transaction(
        'hera-fee',
        'hera-fee-fact',
        'Costo accettazione',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'hera-operation',
          role: OperationRole.accessory,
          context: OperationContext.utilityBill,
          accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
        ),
      );

      final result = _build(coordinator, observedAt, [main, fee]);

      expect(result.timeline, hasLength(2));
      expect(
        result.timeline.map((entry) => entry.title),
        containsAll(['Bolletta Hera', 'Costo accettazione postale']),
      );
      expect(
        result.timeline.every((entry) => entry.replacementHistory.isEmpty),
        isTrue,
      );
    },
  );

  test('finite-plan installment event remains unchanged in the Ledger', () {
    final installment = _transaction(
      'finite-installment',
      'finite-installment-fact',
      'Rata INPS 3/12',
      operationMetadata: EconomicOperationMetadata(
        operationId: 'finite-plan-inps-installment-3',
        role: OperationRole.main,
        context: OperationContext.financialPlanInstallment,
      ),
    );

    final result = _build(coordinator, observedAt, [installment]);

    expect(result.timeline, hasLength(1));
    expect(result.timeline.single.title, 'Rata INPS 3/12');
    expect(result.timeline.single.amount, 10);
    expect(result.timeline.single.replacementHistory, isEmpty);
  });
}

LedgerSnapshot _build(
  LedgerCoordinator coordinator,
  DateTime observedAt,
  List<FinanceTransaction> transactions, {
  String query = '',
  Set<String> selectedFilterIds = const {},
}) => coordinator.build(
  transactions: transactions,
  assetMovements: const [],
  realExpenses: const [],
  observedAt: observedAt,
  query: query,
  selectedFilterIds: selectedFilterIds,
);

List<FinanceTransaction> _replacement(
  String originalFactId,
  String replacementFactId, {
  bool includeOriginal = true,
  String originalBalanceId = 'account-current',
  String replacementBalanceId = 'account-current',
}) => [
  if (includeOriginal)
    _transaction(
      'original-$originalFactId',
      originalFactId,
      'Original $originalFactId',
      balanceId: originalBalanceId,
    ),
  _marked(
    'compensation-$originalFactId-$replacementFactId',
    'compensation-$originalFactId-$replacementFactId-fact',
    originalFactId,
    replacementFactId,
    ExpenseReplacementRole.compensation,
    isIncome: true,
  ),
  _marked(
    'replacement-$replacementFactId',
    replacementFactId,
    originalFactId,
    replacementFactId,
    ExpenseReplacementRole.replacement,
    balanceId: replacementBalanceId,
    description: 'Current $replacementFactId',
  ),
];

FinanceTransaction _marked(
  String id,
  String? factId,
  String originalFactId,
  String replacementFactId,
  ExpenseReplacementRole role, {
  bool isIncome = false,
  String balanceId = 'account-current',
  String? description,
}) => _transaction(
  id,
  factId,
  description ?? id,
  balanceId: balanceId,
  isIncome: isIncome,
  replacementMetadata: ExpenseReplacementMetadata(
    originalEconomicFactId: originalFactId,
    replacementEconomicFactId: replacementFactId,
    role: role,
  ),
);

FinanceTransaction _transaction(
  String id,
  String? factId,
  String description, {
  String balanceId = 'account-current',
  bool isIncome = false,
  EconomicOperationMetadata? operationMetadata,
  ExpenseReplacementMetadata? replacementMetadata,
}) => FinanceTransaction(
  id: id,
  balanceId: balanceId,
  amount: 10,
  date: DateTime(2026, 9, 17, 10),
  isIncome: isIncome,
  subject: FinanceSubject.matteo,
  description: description,
  type: isIncome
      ? FinanceTransactionType.income
      : FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: factId,
  operationMetadata: operationMetadata,
  expenseReplacementMetadata: replacementMetadata,
);
