import 'package:flutter/material.dart';

import '../logic/finance/due_date_certainty_confidence_mapper.dart';
import '../logic/finance/expected_expense_update_coordinator.dart';
import '../logic/finance/manual_payment_window_materializer.dart';
import '../models/expense_relationship.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/manual_payment_preference.dart';
import '../stores/finance_store.dart';

class ExpectedExpenseCompletionResult {
  final ExpectedExpenseUpdateOutcome outcome;
  final bool requiresExplicitChoice;

  const ExpectedExpenseCompletionResult({
    required this.outcome,
    required this.requiresExplicitChoice,
  });
}

class ExpectedExpenseCompletionPage extends StatefulWidget {
  final FinanceStore financeStore;
  final String relationshipId;
  final String occurrenceId;

  const ExpectedExpenseCompletionPage({
    super.key,
    required this.financeStore,
    required this.relationshipId,
    required this.occurrenceId,
  });

  @override
  State<ExpectedExpenseCompletionPage> createState() =>
      _ExpectedExpenseCompletionPageState();
}

class _ExpectedExpenseCompletionPageState
    extends State<ExpectedExpenseCompletionPage> {
  final _preferredDayController = TextEditingController();
  DateTime? _dueDate;
  ExpectedExpenseDateCertainty? _certainty;
  ExpectedPaymentWindow? _existingWindow;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final relationship = _relationship();
    final occurrence = _occurrence();
    if (relationship == null) {
      _loadError = 'Rapporto della previsione non trovato.';
      return;
    }
    if (occurrence == null) {
      _loadError = 'Occorrenza della previsione non trovata.';
      return;
    }
    if (occurrence.relationshipId != relationship.relationshipId) {
      _loadError = 'Identità della previsione non coerente.';
      return;
    }
    _dueDate = occurrence.expectedDueDate;
    _certainty = switch (occurrence.expectedDueDateCertainty) {
      ExpectedExpenseDateCertainty.estimated =>
        ExpectedExpenseDateCertainty.estimated,
      ExpectedExpenseDateCertainty.known => ExpectedExpenseDateCertainty.known,
      _ => null,
    };
    _existingWindow = occurrence.expectedPaymentWindow;
    final preferredDay =
        relationship.manualPaymentPreference?.preferredStartDayOfMonth;
    if (preferredDay != null) {
      _preferredDayController.text = '$preferredDay';
    }
  }

  @override
  void dispose() {
    _preferredDayController.dispose();
    super.dispose();
  }

  ExpenseRelationship? _relationship() => widget
      .financeStore
      .expectedExpenseAggregate
      .relationships
      .where((item) => item.relationshipId == widget.relationshipId)
      .firstOrNull;

  ExpectedExpenseOccurrence? _occurrence() => widget
      .financeStore
      .expectedExpenseAggregate
      .occurrences
      .where((item) => item.occurrenceId == widget.occurrenceId)
      .firstOrNull;

  Future<void> _pickDueDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _dueDate = value);
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final relationship = _relationship();
    final occurrence = _occurrence();
    if (relationship == null) {
      _error('Rapporto della previsione non trovato.');
      return;
    }
    if (occurrence == null) {
      _error('Occorrenza della previsione non trovata.');
      return;
    }
    if (occurrence.relationshipId != relationship.relationshipId) {
      _error('Identità della previsione non coerente.');
      return;
    }
    final dueDate = _dueDate;
    if (dueDate == null) {
      _error('Seleziona una scadenza.');
      return;
    }
    final certainty = _certainty;
    if (certainty == null) {
      _error('Indica se la scadenza è stimata o conosciuta.');
      return;
    }
    final preferredDay = int.tryParse(_preferredDayController.text.trim());
    if (preferredDay == null || preferredDay < 1 || preferredDay > 31) {
      _error('Il giorno abituale deve essere compreso tra 1 e 31.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final preference = ManualPaymentPreference(
        preferredStartDayOfMonth: preferredDay,
      );
      var requiresExplicitChoice = false;
      ExpectedPaymentWindow? paymentWindow;
      if (occurrence.expectedPaymentWindow?.origin ==
          ExpectedPaymentWindowOrigin.occurrenceOverride) {
        paymentWindow = occurrence.expectedPaymentWindow;
      } else {
        final confidence = confidenceForDueDateCertainty(certainty);
        if (confidence == null) {
          _error('Qualifica la scadenza prima di creare la finestra.');
          return;
        }
        final materialization = const ManualPaymentWindowMaterializer()
            .materialize(
              preference: preference,
              expectedDueDate: dueDate,
              source: ExpectedExpenseDateSource.explicit,
              confidence: confidence,
            );
        requiresExplicitChoice =
            materialization.outcome ==
            ManualPaymentWindowMaterializationOutcome.requiresExplicitChoice;
        paymentWindow = materialization.window;
      }

      final outcome =
          await ExpectedExpenseUpdateCoordinator(
            financeStore: widget.financeStore,
          ).updateRelationshipAndOccurrence(
            relationshipId: relationship.relationshipId,
            relationshipCandidate: relationship.copyWith(
              manualPaymentPreference: preference,
            ),
            occurrenceId: occurrence.occurrenceId,
            occurrenceCandidate: occurrence.copyWith(
              expectedDueDate: dueDate,
              expectedDueDateSource: ExpectedExpenseDateSource.explicit,
              expectedDueDateCertainty: certainty,
              expectedPaymentWindow: paymentWindow,
            ),
          );
      if (!mounted) return;
      if (outcome != ExpectedExpenseUpdateOutcome.applied &&
          outcome != ExpectedExpenseUpdateOutcome.unchanged) {
        _error(_outcomeMessage(outcome));
        return;
      }
      Navigator.of(context).pop(
        ExpectedExpenseCompletionResult(
          outcome: outcome,
          requiresExplicitChoice: requiresExplicitChoice,
        ),
      );
    } catch (error) {
      if (mounted) _error('Previsione non aggiornata: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completa previsione')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadError != null)
            Text(_loadError!, key: const Key('completion-load-error'))
          else ...[
            ListTile(
              key: const Key('completion-due-date'),
              title: const Text('Scadenza'),
              subtitle: Text(
                _dueDate == null ? 'Non indicata' : _date(_dueDate!),
              ),
              onTap: _pickDueDate,
            ),
            DropdownButtonFormField<ExpectedExpenseDateCertainty>(
              key: const Key('completion-certainty'),
              initialValue: _certainty,
              decoration: const InputDecoration(labelText: 'La scadenza è'),
              items: const [
                DropdownMenuItem(
                  value: ExpectedExpenseDateCertainty.estimated,
                  child: Text('Stimata'),
                ),
                DropdownMenuItem(
                  value: ExpectedExpenseDateCertainty.known,
                  child: Text('Conosciuta'),
                ),
              ],
              onChanged: (value) => setState(() => _certainty = value),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('completion-preferred-day'),
              controller: _preferredDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giorno abituale di inizio (1–31)',
                helperText:
                    'Vale solo per questa spesa: indica da quale giorno del mese della scadenza iniziare a occuparsi del pagamento.',
              ),
            ),
            if (_existingWindow case final window?) ...[
              const SizedBox(height: 12),
              Text(
                'Finestra attuale: ${_date(window.start)} – ${_date(window.end)}',
                key: const Key('completion-existing-window'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('save-completed-expected-expense'),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Salvataggio...' : 'Salva'),
            ),
          ],
        ],
      ),
    );
  }
}

String _outcomeMessage(ExpectedExpenseUpdateOutcome outcome) =>
    switch (outcome) {
      ExpectedExpenseUpdateOutcome.missingRelationship =>
        'Rapporto della previsione non trovato.',
      ExpectedExpenseUpdateOutcome.missingOccurrence =>
        'Occorrenza della previsione non trovata.',
      ExpectedExpenseUpdateOutcome.identityMismatch =>
        'Identità della previsione non coerente.',
      ExpectedExpenseUpdateOutcome.applied ||
      ExpectedExpenseUpdateOutcome.unchanged => 'Previsione aggiornata.',
    };

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
