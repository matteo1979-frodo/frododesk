import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';

void main() {
  late LedgerEndpointResolver resolver;

  setUp(() {
    resolver = LedgerEndpointResolver(
      registry: LedgerEndpointRegistry(
        accounts: const {
          'account': LedgerEndpointRecord(
            id: 'account',
            label: 'Banca di Imola',
            personId: 'matteo',
          ),
        },
        funds: const {
          'fund': LedgerEndpointRecord(id: 'fund', label: 'Fondo Vacanze'),
        },
        cashWallets: const {
          'wallet': LedgerEndpointRecord(
            id: 'wallet',
            label: 'Portafoglio Matteo',
            personId: 'matteo',
          ),
        },
        people: const {
          'matteo': LedgerPersonRecord(id: 'matteo', label: 'Matteo'),
          'chiara': LedgerPersonRecord(id: 'chiara', label: 'Chiara'),
        },
      ),
    );
  });

  test('resolves existing account and its owner', () {
    final resolved = resolver.resolve(
      _endpoint(EconomicEndpointKind.account, referenceId: 'account'),
    );

    expect(resolved.label, 'Banca di Imola');
    expect(resolved.personId, 'matteo');
    expect(resolved.personLabel, 'Matteo');
    expect(resolved.usesHistoricalFallback, isFalse);
  });

  test('resolves fund and cash wallet by id', () {
    expect(
      resolver
          .resolve(_endpoint(EconomicEndpointKind.fund, referenceId: 'fund'))
          .label,
      'Fondo Vacanze',
    );
    final wallet = resolver.resolve(
      _endpoint(EconomicEndpointKind.cash, referenceId: 'wallet'),
    );
    expect(wallet.label, 'Portafoglio Matteo');
    expect(wallet.personLabel, 'Matteo');
  });

  test('preserves external, opening balance and generic labels', () {
    expect(
      resolver
          .resolve(
            _endpoint(EconomicEndpointKind.external, label: 'Supermercato'),
          )
          .label,
      'Supermercato',
    );
    expect(
      resolver
          .resolve(
            _endpoint(
              EconomicEndpointKind.openingBalance,
              label: 'Saldo già esistente',
            ),
          )
          .label,
      'Saldo già esistente',
    );
    expect(
      resolver
          .resolve(
            _endpoint(
              EconomicEndpointKind.other,
              label: 'Contropartita legacy',
            ),
          )
          .label,
      'Contropartita legacy',
    );
  });

  test('uses neutral fallbacks without losing historical references', () {
    final missing = resolver.resolve(
      _endpoint(EconomicEndpointKind.account, referenceId: 'deleted'),
    );

    expect(missing.referenceId, 'deleted');
    expect(missing.label, 'Conto non più disponibile');
    expect(missing.usesHistoricalFallback, isTrue);
    expect(missing.personId, isNull);
  });

  test('preserves endpoint person over registry owner when supplied', () {
    final resolved = resolver.resolve(
      _endpoint(
        EconomicEndpointKind.account,
        referenceId: 'account',
        personId: 'chiara',
      ),
    );

    expect(resolved.personId, 'chiara');
    expect(resolved.personLabel, 'Chiara');
  });

  test('resolves multiple origins and destinations in one event', () {
    final event = EconomicEvent(
      id: 'multi',
      observedAt: DateTime(2026, 8, 19),
      occurredAt: DateTime(2026, 8, 18),
      origins: [
        _endpoint(EconomicEndpointKind.account, referenceId: 'account'),
        _endpoint(EconomicEndpointKind.cash, referenceId: 'wallet'),
      ],
      destinations: [
        _endpoint(EconomicEndpointKind.fund, referenceId: 'fund'),
        _endpoint(EconomicEndpointKind.external, label: 'Spesa'),
      ],
      description: 'Scenario multiplo',
      amount: 20,
      nature: EconomicNature.internalTransfer,
    );

    final resolved = resolver.resolveEvent(event);

    expect(resolved.origins.map((item) => item.label), [
      'Banca di Imola',
      'Portafoglio Matteo',
    ]);
    expect(resolved.destinations.map((item) => item.label), [
      'Fondo Vacanze',
      'Spesa',
    ]);
    expect(() => resolved.origins.clear(), throwsUnsupportedError);
  });

  test('registry owns immutable copies', () {
    final accounts = <String, LedgerEndpointRecord>{
      'account': const LedgerEndpointRecord(id: 'account', label: 'Conto'),
    };
    final registry = LedgerEndpointRegistry(accounts: accounts);
    accounts.clear();

    expect(registry.accounts.entries.single.key, 'account');
    expect(
      () => registry.accounts['other'] = const LedgerEndpointRecord(
        id: 'other',
        label: 'Altro',
      ),
      throwsUnsupportedError,
    );
  });

  test('resolver has no forbidden dependencies', () {
    final resolverSource = File(
      'lib/logic/ledger/ledger_endpoint_resolver.dart',
    ).readAsStringSync();
    final modelSource = File(
      'lib/models/ledger_resolved_endpoint.dart',
    ).readAsStringSync();
    final source = '$resolverSource\n$modelSource';

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceAssetMovement')));
  });
}

EconomicEndpoint _endpoint(
  EconomicEndpointKind kind, {
  String? referenceId,
  String label = 'Etichetta generica',
  String? personId,
}) => EconomicEndpoint(
  kind: kind,
  referenceId: referenceId,
  label: label,
  personId: personId,
  amount: 10,
);
