import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/finance/due_date_certainty_confidence_mapper.dart';
import '../logic/finance/expected_expense_update_coordinator.dart';
import '../logic/finance/manual_payment_window_materializer.dart';
import '../models/expense_relationship.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/manual_payment_preference.dart';
import '../models/planned_economic_impact.dart';
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
  PaymentExecutionMode _paymentExecutionMode = PaymentExecutionMode.unknown;
  PlannedEconomicImpact? _plannedEconomicImpact;
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
    _paymentExecutionMode = occurrence.paymentExecutionMode;
    _plannedEconomicImpact = occurrence.plannedEconomicImpact;
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

  Future<void> _pickPlannedEconomicImpact() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _plannedEconomicImpact?.start ?? _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(() {
        _plannedEconomicImpact = PlannedEconomicImpact(
          start: value,
          end: value,
          origin: PlannedEconomicImpactOrigin.userDecision,
        );
      });
    }
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
              paymentExecutionMode: _paymentExecutionMode,
              plannedEconomicImpact: _plannedEconomicImpact,
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
    final relationship = _relationship();
    final occurrence = _occurrence();
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('Completa previsione'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black.withValues(alpha: 0.08),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.38)),
          ),
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (_loadError != null)
                _CompletionGlassCard(
                  child: Text(
                    _loadError!,
                    key: const Key('completion-load-error'),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else ...[
                _CompletionGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${relationship!.service} · ${relationship.provider}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '€${occurrence!.expectedAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: Color(0xFFFFD180),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        occurrence.provisional
                            ? 'Importo stimato/provvisorio'
                            : 'Importo previsto',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _CompletionGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CompletionSectionTitle(
                        icon: Icons.event_rounded,
                        title: 'Scadenza',
                      ),
                      ListTile(
                        key: const Key('completion-due-date'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Data prevista',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          _dueDate == null ? 'Non indicata' : _date(_dueDate!),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.edit_calendar_rounded,
                          color: Colors.white70,
                        ),
                        onTap: _pickDueDate,
                      ),
                      DropdownButtonFormField<ExpectedExpenseDateCertainty>(
                        key: const Key('completion-certainty'),
                        initialValue: _certainty,
                        dropdownColor: const Color(0xFF23302B),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'La scadenza è',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
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
                        onChanged: (value) =>
                            setState(() => _certainty = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _CompletionGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CompletionSectionTitle(
                        icon: Icons.payments_rounded,
                        title: 'Pagamento e pianificazione',
                      ),
                      TextField(
                        key: const Key('completion-preferred-day'),
                        controller: _preferredDayController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Giorno abituale di inizio (1–31)',
                          labelStyle: TextStyle(color: Colors.white70),
                          helperStyle: TextStyle(color: Colors.white60),
                          helperText:
                              'Da quale giorno iniziare a occuparsi del pagamento.',
                        ),
                      ),
                      if (_existingWindow case final window?) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Finestra attuale: ${_date(window.start)} – ${_date(window.end)}',
                          key: const Key('completion-existing-window'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentExecutionMode>(
                        key: const Key('completion-payment-execution-mode'),
                        initialValue: _paymentExecutionMode,
                        dropdownColor: const Color(0xFF23302B),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Come verrà pagata?',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PaymentExecutionMode.unknown,
                            child: Text('Da definire'),
                          ),
                          DropdownMenuItem(
                            value: PaymentExecutionMode.requiresUserAction,
                            child: Text('Richiede una mia azione'),
                          ),
                          DropdownMenuItem(
                            value: PaymentExecutionMode.automatic,
                            child: Text('Automatico'),
                          ),
                          DropdownMenuItem(
                            value: PaymentExecutionMode.scheduled,
                            child: Text('Già programmato'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentExecutionMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        key: const Key('completion-planned-impact-date'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Quando prevedi che usciranno i soldi?',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          _plannedEconomicImpact == null
                              ? 'Nessuna pianificazione esplicita'
                              : _plannedEconomicImpact!.start ==
                                    _plannedEconomicImpact!.end
                              ? _date(_plannedEconomicImpact!.start)
                              : '${_date(_plannedEconomicImpact!.start)} – '
                                    '${_date(_plannedEconomicImpact!.end)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: _plannedEconomicImpact == null
                            ? const Icon(
                                Icons.edit_calendar_rounded,
                                color: Colors.white70,
                              )
                            : IconButton(
                                key: const Key(
                                  'completion-clear-planned-impact',
                                ),
                                tooltip: 'Rimuovi pianificazione',
                                onPressed: () => setState(
                                  () => _plannedEconomicImpact = null,
                                ),
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                ),
                              ),
                        onTap: _pickPlannedEconomicImpact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('save-completed-expected-expense'),
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_submitting ? 'Salvataggio...' : 'Salva'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionGlassCard extends StatelessWidget {
  final Widget child;

  const _CompletionGlassCard({required this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: child,
      ),
    ),
  );
}

class _CompletionSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CompletionSectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFFFB74D)),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
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
