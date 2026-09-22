import '../../../models/economic_event.dart';
import '../../../models/real_expense.dart';
import '../../../models/spese_command.dart';

enum SpeseCommandValidationError {
  invalidId,
  invalidAmount,
  invalidDate,
  invalidOrigin,
  invalidDestination,
  invalidCategory,
  invalidPerson,
  invalidDescription,
}

class SpeseCommandValidationException implements Exception {
  final SpeseCommandValidationError error;
  final String message;

  const SpeseCommandValidationException(this.error, this.message);

  @override
  String toString() => message;
}

class SpeseCommandBuilder {
  const SpeseCommandBuilder();

  SpeseCommand build({
    required SpeseCommandDraft draft,
    required SpeseCommandRegistry registry,
  }) {
    final id = draft.id.trim();
    if (id.isEmpty) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidId,
        'Identificativo movimento non valido.',
      );
    }

    final amount = _parseAmount(draft.amountInput);
    _validateDate(draft.occurredAt);

    final description = draft.description.trim();
    if (description.isEmpty) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidDescription,
        'Inserisci una descrizione.',
      );
    }

    final category = draft.category.trim();
    if (category.isEmpty || !registry.categories.contains(category)) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidCategory,
        'Seleziona una categoria.',
      );
    }

    final personId = draft.personId?.trim();
    if (personId != null &&
        (personId.isEmpty || !registry.people.contains(personId))) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidPerson,
        'Seleziona una persona valida.',
      );
    }

    return SpeseCommand(
      id: id,
      kind: draft.kind,
      action: draft.action,
      targetRecordId: _validateTarget(draft),
      preparedAt: draft.preparedAt,
      occurredAt: draft.occurredAt,
      origin: _buildEndpoint(
        draft.origin,
        registry,
        SpeseCommandValidationError.invalidOrigin,
      ),
      destination: _buildEndpoint(
        draft.destination,
        registry,
        SpeseCommandValidationError.invalidDestination,
      ),
      amount: amount,
      category: category,
      personId: personId,
      description: description,
      balancePostingMode: draft.balancePostingMode,
    );
  }

  SpeseCommand buildExistingMovement({
    required RealExpense expense,
    required SpeseCommandAction action,
    required DateTime preparedAt,
    required SpeseCommandRegistry registry,
  }) {
    if (action == SpeseCommandAction.create) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidId,
        'Operazione sul movimento non valida.',
      );
    }

    final kind = expense.isCashWithdrawal
        ? SpeseCommandKind.cashWithdrawal
        : expense.isIncome
        ? SpeseCommandKind.extraIncome
        : SpeseCommandKind.expense;
    final account = SpeseCommandEndpointDraft(
      kind: EconomicEndpointKind.account,
      referenceId: expense.balanceId,
    );
    final external = const SpeseCommandEndpointDraft(
      kind: EconomicEndpointKind.external,
      label: 'Movimento esterno',
    );
    final destination = expense.isCashWithdrawal
        ? expense.nonTrackedCash
              ? const SpeseCommandEndpointDraft(
                  kind: EconomicEndpointKind.external,
                  label: 'Contanti non tracciati',
                )
              : SpeseCommandEndpointDraft(
                  kind: EconomicEndpointKind.cash,
                  referenceId: expense.cashWalletId,
                )
        : expense.isIncome
        ? account
        : external;
    final origin = expense.isIncome ? external : account;

    return build(
      draft: SpeseCommandDraft(
        id: 'mutation_${preparedAt.microsecondsSinceEpoch}',
        kind: kind,
        action: action,
        targetRecordId: expense.id,
        preparedAt: preparedAt,
        occurredAt: expense.date,
        origin: origin,
        destination: destination,
        amountInput: expense.amount.toString(),
        category: expense.category,
        personId: expense.subject.name,
        description: expense.description,
        balancePostingMode: expense.balancePostingMode,
      ),
      registry: registry,
    );
  }

  String? _validateTarget(SpeseCommandDraft draft) {
    final targetRecordId = draft.targetRecordId?.trim();
    if (draft.action == SpeseCommandAction.create) {
      if (targetRecordId != null && targetRecordId.isNotEmpty) {
        throw const SpeseCommandValidationException(
          SpeseCommandValidationError.invalidId,
          'Il nuovo movimento non può avere un record da sostituire.',
        );
      }
      return null;
    }
    if (targetRecordId == null || targetRecordId.isEmpty) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidId,
        'Movimento da modificare o eliminare non valido.',
      );
    }
    return targetRecordId;
  }

  double _parseAmount(String input) {
    final amount = double.tryParse(input.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidAmount,
        'Inserisci un importo valido.',
      );
    }
    return amount;
  }

  void _validateDate(DateTime date) {
    final firstDate = DateTime(2020);
    final lastDateExclusive = DateTime(2101);
    if (date.isBefore(firstDate) || !date.isBefore(lastDateExclusive)) {
      throw const SpeseCommandValidationException(
        SpeseCommandValidationError.invalidDate,
        'Seleziona una data valida.',
      );
    }
  }

  SpeseCommandEndpoint _buildEndpoint(
    SpeseCommandEndpointDraft draft,
    SpeseCommandRegistry registry,
    SpeseCommandValidationError error,
  ) {
    final referenceId = draft.referenceId?.trim();
    final registryForKind = switch (draft.kind) {
      EconomicEndpointKind.account => registry.accounts,
      EconomicEndpointKind.fund => registry.funds,
      EconomicEndpointKind.cash => registry.cashWallets,
      _ => null,
    };

    if (registryForKind != null) {
      final label = referenceId == null ? null : registryForKind[referenceId];
      if (referenceId == null || referenceId.isEmpty || label == null) {
        final message = draft.kind == EconomicEndpointKind.cash
            ? 'Portafoglio contanti non trovato.'
            : 'Origine o destinazione non valida.';
        throw SpeseCommandValidationException(error, message);
      }
      return SpeseCommandEndpoint(
        kind: draft.kind,
        referenceId: referenceId,
        label: label,
      );
    }

    final label = draft.label?.trim() ?? '';
    if (label.isEmpty) {
      throw SpeseCommandValidationException(
        error,
        'Origine o destinazione non valida.',
      );
    }
    return SpeseCommandEndpoint(
      kind: draft.kind,
      referenceId: referenceId,
      label: label,
    );
  }
}
