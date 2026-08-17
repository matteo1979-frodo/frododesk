import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  final observedAt = DateTime(2026, 8, 30);
  final coordinator = LedgerCoordinator(
    timelineBuilder: LedgerTimelineBuilder(
      endpointResolver: LedgerEndpointResolver(
        registry: LedgerEndpointRegistry(),
      ),
    ),
  );

  test(
    'coordinator propagates amount, category, person and nature conflicts',
    () {
      final scenarios = <String, void Function()>{
        'amount': () => coordinator.build(
          transactions: [
            _transaction('a', factId: 'amount', amount: 10),
            _transaction('b', factId: 'amount', amount: 20),
          ],
          assetMovements: const [],
          realExpenses: const [],
          observedAt: observedAt,
        ),
        'category': () => coordinator.build(
          transactions: const [],
          assetMovements: const [],
          realExpenses: [
            _expense('a', factId: 'category', category: 'Casa'),
            _expense('b', factId: 'category', category: 'Auto'),
          ],
          observedAt: observedAt,
        ),
        'personId': () => coordinator.build(
          transactions: [
            _transaction('a', factId: 'person', subject: FinanceSubject.matteo),
            _transaction('b', factId: 'person', subject: FinanceSubject.chiara),
          ],
          assetMovements: const [],
          realExpenses: const [],
          observedAt: observedAt,
        ),
        'nature': () => coordinator.build(
          transactions: [
            _transaction('a', factId: 'nature'),
            _transaction('b', factId: 'nature', income: true),
          ],
          assetMovements: const [],
          realExpenses: const [],
          observedAt: observedAt,
        ),
      };

      for (final scenario in scenarios.entries) {
        expect(
          scenario.value,
          throwsA(
            isA<EconomicEventMergeConflict>().having(
              (error) => error.field,
              'field',
              scenario.key,
            ),
          ),
          reason: scenario.key,
        );
      }
    },
  );

  test(
    'canonical merge preserves dates, relations and informative metadata',
    () {
      final earlier = DateTime(2026, 8, 10);
      final laterObservation = DateTime(2026, 8, 30);
      final canonical = const EconomicEventCorrelator().correlate([
        EconomicEvent(
          id: 'transaction',
          economicFactId: 'fact',
          observedAt: DateTime(2026, 8, 20),
          occurredAt: DateTime(2026, 8, 20),
          origins: const [
            EconomicEndpoint(
              kind: EconomicEndpointKind.account,
              referenceId: 'account',
              label: 'Conto',
              amount: 20,
            ),
          ],
          destinations: const [
            EconomicEndpoint(
              kind: EconomicEndpointKind.external,
              label: 'Destinazione esterna',
              amount: 20,
            ),
          ],
          description: 'Breve',
          amount: 20,
          nature: EconomicNature.outflow,
          sourceLinks: const [
            EconomicSourceLink(
              kind: EconomicSourceKind.financeTransaction,
              recordId: 'transaction',
            ),
          ],
          relatedEventIds: const ['recurring_item:rule'],
        ),
        EconomicEvent(
          id: 'expense',
          economicFactId: 'fact',
          observedAt: laterObservation,
          occurredAt: earlier,
          origins: const [
            EconomicEndpoint(
              kind: EconomicEndpointKind.account,
              referenceId: 'account',
              label: 'Conto',
              amount: 20,
            ),
          ],
          destinations: const [
            EconomicEndpoint(
              kind: EconomicEndpointKind.cash,
              referenceId: 'cash',
              label: 'Contanti',
              amount: 20,
            ),
          ],
          category: const EconomicCategoryRef(id: 'casa', label: 'Casa'),
          personId: 'matteo',
          description: 'Descrizione molto più informativa',
          amount: 20,
          nature: EconomicNature.internalTransfer,
          sourceLinks: const [
            EconomicSourceLink(
              kind: EconomicSourceKind.realExpense,
              recordId: 'expense',
            ),
          ],
          relatedEventIds: const ['expense:original'],
        ),
      ]).single;

      expect(canonical.occurredAt, earlier);
      expect(canonical.observedAt, laterObservation);
      expect(canonical.description, 'Descrizione molto più informativa');
      expect(canonical.category?.id, 'casa');
      expect(canonical.personId, 'matteo');
      expect(canonical.nature, EconomicNature.internalTransfer);
      expect(canonical.destinations.single.kind, EconomicEndpointKind.cash);
      expect(canonical.sourceLinks, hasLength(2));
      expect(canonical.relatedEventIds, [
        'expense:original',
        'recurring_item:rule',
      ]);
    },
  );

  test('snapshot query and all structural filter families preserve order', () {
    final snapshot = coordinator.build(
      transactions: [
        _transaction(
          'income',
          factId: 'income',
          income: true,
          description: 'Bonus famiglia',
        ),
        _transaction('expense', factId: 'expense'),
      ],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
      query: 'bonus',
      selectedFilterIds: const {
        'nature:income',
        'period:2026-08',
        'source:financeTransaction',
      },
    );

    expect(snapshot.totalEventCount, 2);
    expect(snapshot.filteredEventCount, 1);
    expect(snapshot.timeline.length, snapshot.filteredEventCount);
    expect(snapshot.timeline.single.title, 'Bonus famiglia');
    expect(snapshot.availableFilters, isNotEmpty);
  });
}

FinanceTransaction _transaction(
  String id, {
  required String factId,
  double amount = 20,
  bool income = false,
  FinanceSubject subject = FinanceSubject.matteo,
  String? description,
}) => FinanceTransaction(
  id: id,
  economicFactId: factId,
  balanceId: 'account',
  amount: amount,
  date: DateTime(2026, 8, 20),
  isIncome: income,
  subject: subject,
  description: description ?? id,
  type: income ? FinanceTransactionType.income : FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
);

RealExpense _expense(
  String id, {
  required String factId,
  required String category,
}) => RealExpense(
  id: id,
  economicFactId: factId,
  balanceId: 'account',
  balanceName: 'Conto',
  amount: 20,
  description: id,
  category: category,
  date: DateTime(2026, 8, 20),
);
