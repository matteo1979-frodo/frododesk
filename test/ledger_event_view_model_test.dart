import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';

void main() {
  test('owns immutable copies of counterparties and badges', () {
    final counterparties = <LedgerEventCounterparty>[
      const LedgerEventCounterparty(
        role: LedgerCounterpartyRole.origin,
        kind: EconomicEndpointKind.account,
        referenceId: 'account',
        label: 'Conto Matteo',
        personId: 'matteo',
        amount: 50,
      ),
    ];
    final badges = <LedgerEventBadge>[
      const LedgerEventBadge(
        label: 'Trasferimento',
        tone: LedgerBadgeTone.transfer,
      ),
    ];
    final viewModel = LedgerEventViewModel(
      eventId: 'event-1',
      title: 'Prelievo contanti',
      subtitle: 'Conto Matteo → Portafoglio Matteo',
      amount: 50,
      currencyCode: 'EUR',
      economicSign: LedgerEconomicSign.neutral,
      nature: EconomicNature.internalTransfer,
      observedAt: DateTime(2026, 8, 19, 12),
      occurredAt: DateTime(2026, 8, 18, 9, 30),
      logicalIcon: LedgerLogicalIcon.cash,
      logicalColor: LedgerLogicalColor.transfer,
      counterparties: counterparties,
      badges: badges,
    );

    counterparties.clear();
    badges.clear();

    expect(viewModel.counterparties.single.label, 'Conto Matteo');
    expect(viewModel.badges.single.label, 'Trasferimento');
    expect(viewModel.isInternalTransfer, isTrue);
    expect(viewModel.timelineDate, viewModel.occurredAt);
    expect(() => viewModel.counterparties.clear(), throwsUnsupportedError);
    expect(() => viewModel.badges.clear(), throwsUnsupportedError);
  });

  test('expresses income, expense and transfer without UI types', () {
    final income = _viewModel(
      nature: EconomicNature.income,
      sign: LedgerEconomicSign.positive,
      icon: LedgerLogicalIcon.income,
      color: LedgerLogicalColor.positive,
    );
    final expense = _viewModel(
      nature: EconomicNature.outflow,
      sign: LedgerEconomicSign.negative,
      icon: LedgerLogicalIcon.expense,
      color: LedgerLogicalColor.negative,
    );
    final transfer = _viewModel(
      nature: EconomicNature.internalTransfer,
      sign: LedgerEconomicSign.neutral,
      icon: LedgerLogicalIcon.transfer,
      color: LedgerLogicalColor.transfer,
    );

    expect(income.isInternalTransfer, isFalse);
    expect(income.economicSign, LedgerEconomicSign.positive);
    expect(expense.economicSign, LedgerEconomicSign.negative);
    expect(transfer.isInternalTransfer, isTrue);
    expect(transfer.logicalColor, LedgerLogicalColor.transfer);
  });

  test('preserves immutable structural metadata for future filters', () {
    final sourceLinks = <EconomicSourceLink>[
      const EconomicSourceLink(
        kind: EconomicSourceKind.realExpense,
        recordId: 'expense-1',
      ),
    ];
    final viewModel = LedgerEventViewModel(
      eventId: 'event-1',
      title: 'Titolo non strutturale',
      subtitle: 'Sottotitolo non strutturale',
      amount: 50,
      currencyCode: 'EUR',
      economicSign: LedgerEconomicSign.negative,
      nature: EconomicNature.outflow,
      personId: 'matteo',
      category: const EconomicCategoryRef(id: 'casa', label: 'Casa'),
      observedAt: DateTime(2026, 8, 20),
      occurredAt: DateTime(2026, 8, 18),
      logicalIcon: LedgerLogicalIcon.expense,
      logicalColor: LedgerLogicalColor.negative,
      counterparties: const [
        LedgerEventCounterparty(
          role: LedgerCounterpartyRole.origin,
          kind: EconomicEndpointKind.account,
          referenceId: 'account-1',
          label: 'Conto',
          personId: 'matteo',
          amount: 50,
        ),
        LedgerEventCounterparty(
          role: LedgerCounterpartyRole.destination,
          kind: EconomicEndpointKind.fund,
          referenceId: 'fund-1',
          label: 'Fondo',
          amount: 50,
        ),
      ],
      badges: const [],
      sourceLinks: sourceLinks,
    );
    sourceLinks.clear();

    expect(viewModel.nature, EconomicNature.outflow);
    expect(viewModel.timelineDate, DateTime(2026, 8, 18));
    expect(viewModel.personId, 'matteo');
    expect(viewModel.category?.id, 'casa');
    expect(
      viewModel.counterparties
          .where((item) => item.kind == EconomicEndpointKind.account)
          .single
          .referenceId,
      'account-1',
    );
    expect(
      viewModel.counterparties
          .where((item) => item.kind == EconomicEndpointKind.fund)
          .single
          .referenceId,
      'fund-1',
    );
    expect(viewModel.sourceLinks.single.recordId, 'expense-1');
    expect(() => viewModel.sourceLinks.clear(), throwsUnsupportedError);
  });

  test('contract has only shared-domain dependencies', () {
    final source = File(
      'lib/models/ledger_event_view_model.dart',
    ).readAsStringSync();

    expect(source, contains("import 'economic_event.dart';"));
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Color(')));
    expect(source, isNot(contains('IconData')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceAssetMovement')));
  });
}

LedgerEventViewModel _viewModel({
  required EconomicNature nature,
  required LedgerEconomicSign sign,
  required LedgerLogicalIcon icon,
  required LedgerLogicalColor color,
}) => LedgerEventViewModel(
  eventId: nature.name,
  title: nature.name,
  subtitle: '',
  amount: 10,
  currencyCode: 'EUR',
  economicSign: sign,
  nature: nature,
  observedAt: DateTime(2026, 8, 19),
  occurredAt: DateTime(2026, 8, 18),
  logicalIcon: icon,
  logicalColor: color,
  counterparties: const [],
  badges: const [],
);
