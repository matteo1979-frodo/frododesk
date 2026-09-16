import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';

void main() {
  late LedgerTimelineBuilder builder;

  setUp(() {
    builder = LedgerTimelineBuilder(
      endpointResolver: LedgerEndpointResolver(
        registry: LedgerEndpointRegistry(
          accounts: const {
            'account-a': LedgerEndpointRecord(
              id: 'account-a',
              label: 'Banca Matteo',
              personId: 'matteo',
              balanceType: FinanceBalanceType.bankAccount,
            ),
            'account-b': LedgerEndpointRecord(
              id: 'account-b',
              label: 'Banca Chiara',
              personId: 'chiara',
              balanceType: FinanceBalanceType.prepaidCard,
            ),
          },
          funds: const {
            'fund': LedgerEndpointRecord(id: 'fund', label: 'Fondo Vacanze'),
          },
          cashWallets: const {
            'cash': LedgerEndpointRecord(
              id: 'cash',
              label: 'Portafoglio Matteo',
              personId: 'matteo',
            ),
          },
          people: const {
            'matteo': LedgerPersonRecord(id: 'matteo', label: 'Matteo'),
            'chiara': LedgerPersonRecord(id: 'chiara', label: 'Chiara'),
          },
        ),
      ),
    );
  });

  test('builds an empty immutable timeline', () {
    final timeline = builder.build(const []);

    expect(timeline, isEmpty);
    expect(() => timeline.add(_placeholderViewModel()), throwsUnsupportedError);
  });

  test('maps income and outflow semantic presentation', () {
    final timeline = builder.build([
      _event(
        id: 'income',
        nature: EconomicNature.income,
        description: 'Stipendio',
        origins: [_external('Datore di lavoro')],
        destinations: [_account('account-a')],
      ),
      _event(
        id: 'outflow',
        nature: EconomicNature.outflow,
        description: 'Spesa alimentare',
        origins: [_account('account-a')],
        destinations: [_external('Supermercato')],
      ),
    ]);
    final income = timeline.singleWhere((event) => event.eventId == 'income');
    final outflow = timeline.singleWhere((event) => event.eventId == 'outflow');

    expect(income.title, 'Stipendio');
    expect(income.economicSign, LedgerEconomicSign.positive);
    expect(income.logicalIcon, LedgerLogicalIcon.income);
    expect(income.logicalColor, LedgerLogicalColor.positive);
    expect(income.badges.single.label, 'Entrata');
    expect(outflow.economicSign, LedgerEconomicSign.negative);
    expect(outflow.logicalIcon, LedgerLogicalIcon.expense);
    expect(outflow.badges.single.label, 'Uscita');
  });

  test('presents composite accessory costs without merging their facts', () {
    final timeline = builder.build([
      _event(
        id: 'main',
        factId: 'fact-main',
        description: 'Bolletta acqua Hera',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation-hera',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
        ),
      ),
      _event(
        id: 'bank',
        factId: 'fact-bank',
        description: 'Bolletta acqua Hera',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation-hera',
          role: OperationRole.accessory,
          context: OperationContext.utilityBill,
          accessoryCostType: AccessoryCostType.bankCommission,
        ),
      ),
      _event(
        id: 'postal',
        factId: 'fact-postal',
        description: 'Bolletta acqua Hera',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation-hera',
          role: OperationRole.accessory,
          context: OperationContext.utilityBill,
          accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
        ),
      ),
    ]);

    expect(timeline, hasLength(3));
    expect(timeline.map((event) => event.title).toSet(), {
      'Bolletta acqua Hera',
      'Commissione bancaria',
      'Costo accettazione postale',
    });
    expect(
      timeline
          .singleWhere((event) => event.eventId == 'main')
          .operationDescription,
      isNull,
    );
    expect(
      timeline
          .singleWhere((event) => event.eventId == 'bank')
          .operationDescription,
      'Bolletta acqua Hera',
    );
  });

  test('legacy and main titles keep their original descriptions', () {
    final timeline = builder.build([
      _event(id: 'legacy', description: 'Spesa legacy'),
      _event(
        id: 'main',
        description: 'Bolletta originale',
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
        ),
      ),
    ]);

    expect(
      timeline.singleWhere((event) => event.eventId == 'legacy').title,
      'Spesa legacy',
    );
    expect(
      timeline.singleWhere((event) => event.eventId == 'main').title,
      'Bolletta originale',
    );
  });

  test('maps one internal transfer preserving origin and destination', () {
    final timeline = builder.build([
      _event(
        id: 'transfer',
        nature: EconomicNature.internalTransfer,
        description: 'Giroconto',
        origins: [_account('account-a')],
        destinations: [_account('account-b')],
      ),
    ]);
    final transfer = timeline.single;

    expect(transfer.economicSign, LedgerEconomicSign.neutral);
    expect(transfer.logicalIcon, LedgerLogicalIcon.transfer);
    expect(transfer.logicalColor, LedgerLogicalColor.transfer);
    expect(transfer.isInternalTransfer, isTrue);
    expect(transfer.subtitle, 'Banca Matteo → Banca Chiara');
    expect(transfer.counterparties.map((item) => item.role), [
      LedgerCounterpartyRole.origin,
      LedgerCounterpartyRole.destination,
    ]);
  });

  test('preserves notes, provenance and structural prepaid endpoint type', () {
    final event = _event(
      id: 'prepaid-transfer',
      nature: EconomicNature.internalTransfer,
      origins: [_account('account-a')],
      destinations: [_account('account-b')],
      notes: const ['Nota trasferimento'],
      transactionOrigins: const [EconomicTransactionOrigin.recurringItem],
      recurringItemIds: const ['rule'],
    );

    final viewModel = builder.build([event]).single;

    expect(viewModel.notes, ['Nota trasferimento']);
    expect(viewModel.transactionOrigins, [
      EconomicTransactionOrigin.recurringItem,
    ]);
    expect(viewModel.recurringItemIds, ['rule']);
    expect(
      viewModel.counterparties.first.balanceType,
      FinanceBalanceType.bankAccount,
    );
    expect(
      viewModel.counterparties.last.balanceType,
      FinanceBalanceType.prepaidCard,
    );
    expect(viewModel.isInternalTransfer, isTrue);
  });

  test('uses cash and fund structural icons for internal transfers', () {
    final cash = builder.build([
      _event(
        id: 'cash-transfer',
        nature: EconomicNature.internalTransfer,
        origins: [_account('account-a')],
        destinations: [_cash('cash')],
      ),
    ]).single;
    final fund = builder.build([
      _event(
        id: 'fund-transfer',
        nature: EconomicNature.internalTransfer,
        origins: [_account('account-a')],
        destinations: [_fund('fund')],
      ),
    ]).single;

    expect(cash.logicalIcon, LedgerLogicalIcon.cash);
    expect(fund.logicalIcon, LedgerLogicalIcon.fund);
  });

  test('builds one global timeline from different original source kinds', () {
    final timeline = builder.build([
      _event(
        id: 'transaction-event',
        sourceKind: EconomicSourceKind.financeTransaction,
      ),
      _event(
        id: 'movement-event',
        sourceKind: EconomicSourceKind.financeAssetMovement,
      ),
      _event(id: 'expense-event', sourceKind: EconomicSourceKind.realExpense),
    ]);

    expect(timeline, hasLength(3));
    expect(timeline.map((event) => event.eventId).toSet(), {
      'transaction-event',
      'movement-event',
      'expense-event',
    });
  });

  test('orders by occurredAt, observedAt and finally stable eventId', () {
    final timeline = builder.build([
      _event(
        id: 'same-b',
        occurredAt: DateTime(2026, 8, 19),
        observedAt: DateTime(2026, 8, 20, 10),
      ),
      _event(
        id: 'older',
        occurredAt: DateTime(2026, 8, 18),
        observedAt: DateTime(2026, 8, 22),
      ),
      _event(
        id: 'same-a',
        occurredAt: DateTime(2026, 8, 19),
        observedAt: DateTime(2026, 8, 20, 10),
      ),
      _event(
        id: 'observed-later',
        occurredAt: DateTime(2026, 8, 19),
        observedAt: DateTime(2026, 8, 20, 11),
      ),
      _event(id: 'newest', occurredAt: DateTime(2026, 8, 21)),
    ]);

    expect(timeline.map((event) => event.eventId), [
      'newest',
      'observed-later',
      'same-a',
      'same-b',
      'older',
    ]);
  });

  test('is independent from input order and mapping is repeatable', () {
    final first = _event(id: 'a', occurredAt: DateTime(2026, 8, 19));
    final second = _event(id: 'b', occurredAt: DateTime(2026, 8, 20));

    final forward = builder.build([first, second]);
    final reverse = builder.build([second, first]);
    final repeated = builder.build([first]).single;

    expect(
      forward.map((event) => event.eventId),
      reverse.map((event) => event.eventId),
    );
    expect(repeated.eventId, first.id);
    expect(repeated.title, first.description);
    expect(repeated.subtitle, forward.last.subtitle);
    expect(repeated.economicSign, forward.last.economicSign);
  });

  test(
    'keeps visually identical distinct and legacy events as separate rows',
    () {
      final timeline = builder.build([
        _event(id: 'fact-a', factId: 'fact-a'),
        _event(id: 'fact-b', factId: 'fact-b'),
        _event(id: 'legacy-a'),
        _event(id: 'legacy-b'),
      ]);

      expect(timeline, hasLength(4));
      expect(timeline.map((event) => event.eventId).toSet(), hasLength(4));
    },
  );

  test('uses resolver labels, owners and neutral historical fallbacks', () {
    final resolved = builder.build([
      _event(
        id: 'resolved',
        origins: [_account('account-a')],
        destinations: [_fund('fund')],
        nature: EconomicNature.internalTransfer,
      ),
    ]).single;
    final historical = builder.build([
      _event(
        id: 'historical',
        origins: [_account('deleted')],
        destinations: [_external('Spesa')],
      ),
    ]).single;

    expect(resolved.counterparties.first.label, 'Banca Matteo');
    expect(resolved.counterparties.first.personId, 'matteo');
    expect(resolved.counterparties.first.personLabel, 'Matteo');
    expect(resolved.counterparties.last.label, 'Fondo Vacanze');
    expect(historical.subtitle, contains('Conto non'));
    expect(historical.subtitle, endsWith('→ Spesa'));
    expect(
      historical.badges.map((badge) => badge.label),
      contains('Riferimento storico'),
    );
  });

  test('propagates category, person and structural source links', () {
    final event = _event(
      id: 'metadata',
      personId: 'matteo',
      category: const EconomicCategoryRef(id: 'casa', label: 'Casa'),
      sourceKind: EconomicSourceKind.realExpense,
    );

    final viewModel = builder.build([event]).single;

    expect(viewModel.personId, 'matteo');
    expect(viewModel.personLabel, 'Matteo');
    expect(viewModel.category?.id, 'casa');
    expect(viewModel.sourceLinks.single.kind, EconomicSourceKind.realExpense);
    expect(viewModel.sourceLinks.single.recordId, 'metadata');
  });

  test('does not mutate input and owns immutable nested collections', () {
    final input = [_event(id: 'event')];
    final original = input.single;

    final timeline = builder.build(input);

    expect(input.single, same(original));
    expect(() => timeline.clear(), throwsUnsupportedError);
    expect(
      () => timeline.single.counterparties.clear(),
      throwsUnsupportedError,
    );
    expect(() => timeline.single.badges.clear(), throwsUnsupportedError);
  });

  test('has no collector, correlator, UI, store or persistence dependency', () {
    final source = File(
      'lib/logic/ledger/ledger_timeline_builder.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('EconomicEventCollector')));
    expect(source, isNot(contains('EconomicEventCorrelator')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceAssetMovement')));
    expect(source, isNot(contains('RealExpense')));
  });
}

EconomicEvent _event({
  required String id,
  String? factId,
  EconomicNature nature = EconomicNature.outflow,
  String description = 'Descrizione',
  DateTime? observedAt,
  DateTime? occurredAt,
  List<EconomicEndpoint>? origins,
  List<EconomicEndpoint>? destinations,
  EconomicSourceKind sourceKind = EconomicSourceKind.other,
  String? personId,
  EconomicCategoryRef? category,
  List<String> notes = const [],
  List<EconomicTransactionOrigin> transactionOrigins = const [],
  List<String> recurringItemIds = const [],
  EconomicOperationMetadata? operationMetadata,
}) => EconomicEvent(
  id: id,
  economicFactId: factId,
  observedAt: observedAt ?? DateTime(2026, 8, 20),
  occurredAt: occurredAt ?? DateTime(2026, 8, 19),
  origins: origins ?? [_account('account-a')],
  destinations: destinations ?? [_external('Spesa')],
  description: description,
  amount: 20,
  nature: nature,
  personId: personId,
  category: category,
  sourceLinks: [EconomicSourceLink(kind: sourceKind, recordId: id)],
  notes: notes,
  transactionOrigins: transactionOrigins,
  recurringItemIds: recurringItemIds,
  operationMetadata: operationMetadata,
);

EconomicEndpoint _account(String id) => EconomicEndpoint(
  kind: EconomicEndpointKind.account,
  referenceId: id,
  label: 'Conto',
  amount: 20,
);

EconomicEndpoint _fund(String id) => EconomicEndpoint(
  kind: EconomicEndpointKind.fund,
  referenceId: id,
  label: 'Fondo',
  amount: 20,
);

EconomicEndpoint _cash(String id) => EconomicEndpoint(
  kind: EconomicEndpointKind.cash,
  referenceId: id,
  label: 'Contanti',
  amount: 20,
);

EconomicEndpoint _external(String label) => EconomicEndpoint(
  kind: EconomicEndpointKind.external,
  label: label,
  amount: 20,
);

LedgerEventViewModel _placeholderViewModel() => LedgerEventViewModel(
  eventId: 'placeholder',
  title: 'Placeholder',
  subtitle: '',
  amount: 0,
  currencyCode: 'EUR',
  economicSign: LedgerEconomicSign.neutral,
  nature: EconomicNature.internalTransfer,
  observedAt: DateTime(2026),
  occurredAt: DateTime(2026),
  logicalIcon: LedgerLogicalIcon.other,
  logicalColor: LedgerLogicalColor.neutral,
  counterparties: const [],
  badges: const [],
);
