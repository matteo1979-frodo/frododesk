import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/spese/builders/spese_command_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/spese_command.dart';

void main() {
  const builder = SpeseCommandBuilder();
  final preparedAt = DateTime(2026, 8, 17, 12);

  SpeseCommandDraft expenseDraft({
    String amount = '12,50',
    DateTime? occurredAt,
    String description = ' Pranzo ',
    String category = 'Alimentazione',
    String? personId = 'matteo',
    String accountId = 'account_1',
  }) {
    return SpeseCommandDraft(
      id: 'expense_1',
      kind: SpeseCommandKind.expense,
      preparedAt: preparedAt,
      occurredAt: occurredAt ?? DateTime(2026, 8, 16),
      origin: SpeseCommandEndpointDraft(
        kind: EconomicEndpointKind.account,
        referenceId: accountId,
      ),
      destination: const SpeseCommandEndpointDraft(
        kind: EconomicEndpointKind.external,
        label: 'Spesa',
      ),
      amountInput: amount,
      category: category,
      personId: personId,
      description: description,
    );
  }

  final registry = SpeseCommandRegistry(
    accounts: const {'account_1': 'Conto principale'},
    funds: const {'fund_1': 'Vacanze'},
    categories: const {'Alimentazione'},
    people: const {'matteo'},
  );

  test('costruisce un comando immutabile con dati normalizzati', () {
    final command = builder.build(draft: expenseDraft(), registry: registry);

    expect(command.id, 'expense_1');
    expect(command.amount, 12.5);
    expect(command.description, 'Pranzo');
    expect(command.category, 'Alimentazione');
    expect(command.personId, 'matteo');
    expect(command.origin.referenceId, 'account_1');
    expect(command.origin.label, 'Conto principale');
    expect(command.destination.kind, EconomicEndpointKind.external);
  });

  test('rifiuta importi non numerici, non positivi o non finiti', () {
    for (final amount in ['', '0', '-2', 'NaN', 'Infinity']) {
      expect(
        () => builder.build(
          draft: expenseDraft(amount: amount),
          registry: registry,
        ),
        throwsA(
          isA<SpeseCommandValidationException>().having(
            (error) => error.error,
            'error',
            SpeseCommandValidationError.invalidAmount,
          ),
        ),
      );
    }
  });

  test('valida conto, fondo e portafoglio tramite i registri', () {
    expect(
      () => builder.build(
        draft: expenseDraft(accountId: 'missing'),
        registry: registry,
      ),
      throwsA(
        isA<SpeseCommandValidationException>().having(
          (error) => error.error,
          'error',
          SpeseCommandValidationError.invalidOrigin,
        ),
      ),
    );

    final fundCommand = builder.build(
      draft: SpeseCommandDraft(
        id: 'fund_expense',
        kind: SpeseCommandKind.expense,
        preparedAt: preparedAt,
        occurredAt: preparedAt,
        origin: const SpeseCommandEndpointDraft(
          kind: EconomicEndpointKind.fund,
          referenceId: 'fund_1',
        ),
        destination: const SpeseCommandEndpointDraft(
          kind: EconomicEndpointKind.external,
          label: 'Spesa',
        ),
        amountInput: '100',
        category: 'Alimentazione',
        personId: 'matteo',
        description: 'Spesa dal fondo',
      ),
      registry: registry,
    );
    expect(fundCommand.origin.label, 'Vacanze');

    expect(
      () => builder.build(
        draft: SpeseCommandDraft(
          id: 'cash',
          kind: SpeseCommandKind.cashWithdrawal,
          preparedAt: preparedAt,
          occurredAt: preparedAt,
          origin: const SpeseCommandEndpointDraft(
            kind: EconomicEndpointKind.account,
            referenceId: 'account_1',
          ),
          destination: const SpeseCommandEndpointDraft(
            kind: EconomicEndpointKind.cash,
            referenceId: 'missing_wallet',
          ),
          amountInput: '20',
          category: 'Alimentazione',
          personId: 'matteo',
          description: 'Prelievo',
        ),
        registry: registry,
      ),
      throwsA(
        isA<SpeseCommandValidationException>().having(
          (error) => error.error,
          'error',
          SpeseCommandValidationError.invalidDestination,
        ),
      ),
    );
  });

  test('valida data, categoria, persona e descrizione', () {
    final cases = <SpeseCommandDraft>[
      expenseDraft(occurredAt: DateTime(2019, 12, 31)),
      expenseDraft(category: 'Sconosciuta'),
      expenseDraft(personId: 'unknown'),
      expenseDraft(description: '   '),
    ];
    final expectedErrors = <SpeseCommandValidationError>[
      SpeseCommandValidationError.invalidDate,
      SpeseCommandValidationError.invalidCategory,
      SpeseCommandValidationError.invalidPerson,
      SpeseCommandValidationError.invalidDescription,
    ];

    for (var index = 0; index < cases.length; index++) {
      expect(
        () => builder.build(draft: cases[index], registry: registry),
        throwsA(
          isA<SpeseCommandValidationException>().having(
            (error) => error.error,
            'error',
            expectedErrors[index],
          ),
        ),
      );
    }
  });

  test('il comando non modifica i registri ricevuti', () {
    final accounts = <String, String>{'account_1': 'Conto principale'};
    final mutableRegistry = SpeseCommandRegistry(
      accounts: accounts,
      categories: const {'Alimentazione'},
      people: const {'matteo'},
    );
    accounts['account_2'] = 'Aggiunto dopo';

    expect(mutableRegistry.accounts, hasLength(1));
    expect(
      () => mutableRegistry.accounts['account_3'] = 'Non consentito',
      throwsUnsupportedError,
    );
  });
}
