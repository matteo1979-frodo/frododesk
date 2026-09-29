import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/finance/due_date_certainty_confidence_mapper.dart';
import '../logic/finance/expected_expense_lifecycle_coordinator.dart';
import '../logic/finance/expected_expense_update_coordinator.dart';
import '../logic/finance/manual_payment_window_materializer.dart';
import '../models/expense_relationship.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/economic_operation_metadata.dart';
import '../models/manual_payment_preference.dart';
import '../models/planned_economic_impact.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';

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
  final ExpenseStore? expenseStore;
  final String relationshipId;
  final String occurrenceId;
  final bool initiallyEditing;

  const ExpectedExpenseCompletionPage({
    super.key,
    required this.financeStore,
    this.expenseStore,
    required this.relationshipId,
    required this.occurrenceId,
    this.initiallyEditing = false,
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
  bool _editing = false;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _editing = widget.initiallyEditing;
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

  Future<void> _recordKnownData() async {
    final occurrence = _occurrence();
    if (occurrence == null || _submitting) return;
    final amount = TextEditingController(
      text: occurrence.expectedAmount.toStringAsFixed(2),
    );
    var issueDate = occurrence.expectedIssueDate;
    var dueDate = occurrence.expectedDueDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('La bolletta è arrivata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('known-expense-amount'),
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Importo reale'),
              ),
              ListTile(
                key: const Key('known-expense-issue-date'),
                title: const Text('Data emissione'),
                subtitle: Text(
                  issueDate == null ? 'Non indicata' : _date(issueDate!),
                ),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: issueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (value != null) setDialogState(() => issueDate = value);
                },
              ),
              ListTile(
                key: const Key('known-expense-due-date'),
                title: const Text('Scadenza reale'),
                subtitle: Text(
                  dueDate == null ? 'Non indicata' : _date(dueDate!),
                ),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (value != null) setDialogState(() => dueDate = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              key: const Key('confirm-known-expense-data'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salva dati reali'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final parsed = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      _error('Inserisci un importo reale valido.');
      return;
    }
    final expenseStore = widget.expenseStore;
    if (expenseStore == null) {
      _error('Archivio spese non disponibile. Riapri la pagina da Spese.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result =
          await ExpectedExpenseLifecycleCoordinator(
            financeStore: widget.financeStore,
            expenseStore: expenseStore,
          ).recordKnownExpenseData(
            relationshipId: widget.relationshipId,
            occurrenceId: widget.occurrenceId,
            data: KnownExpectedExpenseData(
              amount: parsed,
              issueDate: issueDate,
              dueDate: dueDate,
            ),
          );
      if (!mounted) return;
      if (!result.isSuccess) {
        _error(
          result.errors.isEmpty
              ? 'Aggiornamento non riuscito.'
              : result.errors.join('; '),
        );
      } else {
        setState(() {
          _dueDate = dueDate;
          _certainty = dueDate == null
              ? null
              : ExpectedExpenseDateCertainty.known;
        });
      }
    } catch (error) {
      if (mounted) _error('$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _recordPayment() async {
    final occurrence = _occurrence();
    final expenseStore = widget.expenseStore;
    if (occurrence == null || expenseStore == null || _submitting) return;
    final balances = widget.financeStore.balances
        .where(
          (item) =>
              item.active && item.personId == occurrence.expectedSubject.name,
        )
        .toList();
    if (balances.isEmpty) {
      _error('Nessun conto attivo disponibile per il pagamento.');
      return;
    }
    var balanceId = occurrence.expectedPaymentConfiguration.expectedBalanceId;
    if (!balances.any((item) => item.balanceId == balanceId)) {
      balanceId = balances.first.balanceId;
    }
    final amount = TextEditingController(
      text: occurrence.expectedAmount.toStringAsFixed(2),
    );
    final description = TextEditingController(
      text: _relationship()?.provider ?? 'Spesa',
    );
    final category = TextEditingController(
      text: _relationship()?.service ?? 'Spese',
    );
    final bankFee = TextEditingController();
    final postalFee = TextEditingController();
    var paidAt = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registra pagamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('expected-payment-balance'),
                  initialValue: balanceId,
                  decoration: const InputDecoration(labelText: 'Conto reale'),
                  items: [
                    for (final balance in balances)
                      DropdownMenuItem(
                        value: balance.balanceId,
                        child: Text(balance.name),
                      ),
                  ],
                  onChanged: (value) => balanceId = value,
                ),
                TextField(
                  key: const Key('expected-payment-amount'),
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Importo pagato',
                  ),
                ),
                TextField(
                  key: const Key('expected-payment-description'),
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Descrizione'),
                ),
                TextField(
                  key: const Key('expected-payment-category'),
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                ListTile(
                  key: const Key('expected-payment-date'),
                  title: const Text('Data reale pagamento'),
                  subtitle: Text(_date(paidAt)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: paidAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) setDialogState(() => paidAt = value);
                  },
                ),
                TextField(
                  key: const Key('expected-payment-bank-fee'),
                  controller: bankFee,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Commissione bancaria (opzionale)',
                  ),
                ),
                TextField(
                  key: const Key('expected-payment-postal-fee'),
                  controller: postalFee,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Costo accettazione (opzionale)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              key: const Key('confirm-expected-payment'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Conferma pagamento'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    double? parseRequired(TextEditingController controller) =>
        double.tryParse(controller.text.trim().replaceAll(',', '.'));
    double? parseOptional(TextEditingController controller) =>
        controller.text.trim().isEmpty ? null : parseRequired(controller);
    final parsedAmount = parseRequired(amount);
    final parsedBankFee = parseOptional(bankFee);
    final parsedPostalFee = parseOptional(postalFee);
    if (parsedAmount == null ||
        parsedAmount <= 0 ||
        (parsedBankFee != null && parsedBankFee <= 0) ||
        (parsedPostalFee != null && parsedPostalFee <= 0)) {
      _error('Controlla gli importi inseriti.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result =
          await ExpectedExpenseLifecycleCoordinator(
            financeStore: widget.financeStore,
            expenseStore: expenseStore,
          ).recordExpectedExpensePayment(
            relationshipId: widget.relationshipId,
            occurrenceId: widget.occurrenceId,
            payment: ExpectedExpensePayment(
              paidAt: paidAt,
              balanceId: balanceId!,
              subject: occurrence.expectedSubject,
              category: category.text,
              description: description.text,
              amount: parsedAmount,
              accessories: [
                if (parsedBankFee != null)
                  (
                    amount: parsedBankFee,
                    type: AccessoryCostType.bankCommission,
                  ),
                if (parsedPostalFee != null)
                  (
                    amount: parsedPostalFee,
                    type: AccessoryCostType.postalAcceptanceCharge,
                  ),
              ],
            ),
          );
      if (!mounted) return;
      if (!result.isSuccess) {
        _error(
          result.errors.isEmpty
              ? 'Pagamento non registrato.'
              : result.errors.join('; '),
        );
        return;
      }
      Navigator.of(context).pop(
        const ExpectedExpenseCompletionResult(
          outcome: ExpectedExpenseUpdateOutcome.applied,
          requiresExplicitChoice: false,
        ),
      );
    } catch (error) {
      if (mounted) _error('$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  Future<void> _removeForecast() async {
    final action = await showModalBottomSheet<_RemovalAction>(
      context: context,
      backgroundColor: const Color(0xFF23302B),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Rimuovi previsione',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('remove-current-forecast'),
                title: const Text(
                  'Annulla solo questa previsione',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Non comparirà più tra le spese future.',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _RemovalAction.cancelOccurrence,
                ),
              ),
              ListTile(
                key: const Key('stop-future-forecasts'),
                title: const Text(
                  'Non prevedere più questa spesa',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'FrodoDesk non creerà nuove previsioni per questa spesa.',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.pop(
                  sheetContext,
                  _RemovalAction.terminateRelationship,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _RemovalAction.cancelOccurrence) {
      final confirmed = await _confirm(
        title: 'Annullare questa previsione?',
        message:
            'Non comparirà più tra le spese future. I dati resteranno conservati.',
        confirmLabel: 'Annulla previsione',
      );
      if (confirmed == true) await _cancelOccurrence();
      return;
    }
    final currentAction = await showDialog<_CurrentForecastAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cosa vuoi fare con la previsione già aperta?'),
        content: const Text(
          'La spesa non verrà più prevista in futuro. Scegli se conservare questa previsione oppure annullarla.',
        ),
        actions: [
          TextButton(
            key: const Key('keep-current-forecast'),
            onPressed: () =>
                Navigator.pop(dialogContext, _CurrentForecastAction.keep),
            child: const Text('Mantieni questa previsione'),
          ),
          TextButton(
            key: const Key('cancel-current-with-relationship'),
            onPressed: () =>
                Navigator.pop(dialogContext, _CurrentForecastAction.cancel),
            child: const Text('Annulla anche questa'),
          ),
        ],
      ),
    );
    if (!mounted || currentAction == null) return;
    await _terminateRelationship(
      cancelCurrent: currentAction == _CurrentForecastAction.cancel,
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Indietro'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  Future<void> _cancelOccurrence() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final outcome = await ExpectedExpenseUpdateCoordinator(
        financeStore: widget.financeStore,
      ).cancelPendingOccurrence(occurrenceId: widget.occurrenceId);
      if (!mounted) return;
      if (outcome == ExpectedExpenseLifecycleOutcome.applied ||
          outcome == ExpectedExpenseLifecycleOutcome.alreadyCancelled) {
        Navigator.of(context).pop(
          const ExpectedExpenseCompletionResult(
            outcome: ExpectedExpenseUpdateOutcome.applied,
            requiresExplicitChoice: false,
          ),
        );
      } else {
        _error(_lifecycleOutcomeMessage(outcome));
      }
    } catch (error) {
      if (mounted) _error('Previsione non annullata: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _terminateRelationship({required bool cancelCurrent}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final outcome =
          await ExpectedExpenseUpdateCoordinator(
            financeStore: widget.financeStore,
          ).terminateActiveRelationship(
            relationshipId: widget.relationshipId,
            occurrenceId: widget.occurrenceId,
            cancelCurrentOccurrence: cancelCurrent,
          );
      if (!mounted) return;
      if (outcome == ExpectedExpenseLifecycleOutcome.applied ||
          outcome == ExpectedExpenseLifecycleOutcome.alreadyTerminated) {
        Navigator.of(context).pop(
          const ExpectedExpenseCompletionResult(
            outcome: ExpectedExpenseUpdateOutcome.applied,
            requiresExplicitChoice: false,
          ),
        );
      } else {
        _error(_lifecycleOutcomeMessage(outcome));
      }
    } catch (error) {
      if (mounted) _error('Impostazione non aggiornata: $error');
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
        title: const Text('Spesa futura'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black.withValues(alpha: 0.08),
        elevation: 0,
        actions: [
          if (_loadError == null && !_editing)
            IconButton(
              key: const Key('edit-future-expense'),
              tooltip: 'Modifica pianificazione',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
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
                            ? 'Importo stimato'
                            : 'Importo previsto',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CompletionBadge(
                            label: _paymentModeLabel(
                              occurrence.paymentExecutionMode,
                            ),
                          ),
                          _CompletionBadge(
                            label:
                                occurrence.knowledgeState ==
                                    ExpectedExpenseKnowledgeState.knownUnpaid
                                ? 'Importo noto, non pagato'
                                : 'Previsione',
                          ),
                        ],
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
                      if (_editing) ...[
                        ListTile(
                          key: const Key('completion-due-date'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Data prevista',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            _dueDate == null
                                ? 'Non indicata'
                                : _date(_dueDate!),
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
                      ] else ...[
                        _CompletionValue(
                          label: 'Scadenza prevista',
                          value: _dueDate == null
                              ? 'Non indicata'
                              : _date(_dueDate!),
                        ),
                        _CompletionValue(
                          label: 'Stato',
                          value: _certaintyLabel(_certainty),
                        ),
                      ],
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
                      if (_editing) ...[
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
                      ] else ...[
                        _CompletionValue(
                          label: 'Giorno abituale',
                          value: _preferredDayController.text.trim().isEmpty
                              ? 'Non indicato'
                              : '${_preferredDayController.text.trim()} del mese',
                        ),
                        _CompletionValue(
                          label: 'Finestra abituale',
                          value: _existingWindow == null
                              ? 'Non indicata'
                              : '${_date(_existingWindow!.start)} – ${_date(_existingWindow!.end)}',
                        ),
                        _CompletionValue(
                          label: 'Impatto pianificato',
                          value: _plannedImpactLabel(_plannedEconomicImpact),
                        ),
                        _CompletionValue(
                          label: 'Modalità',
                          value: _paymentModeLabel(_paymentExecutionMode),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_editing) ...[
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
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _editing = false),
                    child: const Text('Annulla modifica'),
                  ),
                ] else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (occurrence.status ==
                              ExpectedExpenseOccurrenceStatus.pending &&
                          occurrence.knowledgeState ==
                              ExpectedExpenseKnowledgeState.forecast)
                        FilledButton.icon(
                          key: const Key('record-known-expense-data'),
                          onPressed: _submitting ? null : _recordKnownData,
                          icon: const Icon(Icons.mark_email_read_rounded),
                          label: const Text('La bolletta è arrivata'),
                        ),
                      if (occurrence.status ==
                              ExpectedExpenseOccurrenceStatus.pending &&
                          widget.expenseStore != null) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          key: const Key('record-expected-expense-payment'),
                          onPressed: _submitting ? null : _recordPayment,
                          icon: const Icon(Icons.payments_rounded),
                          label: const Text('Registra pagamento'),
                        ),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('remove-future-expense'),
                        onPressed: _submitting ? null : _removeForecast,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8A80),
                          side: const BorderSide(color: Color(0xFFFF8A80)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        label: const Text('Rimuovi previsione'),
                      ),
                    ],
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

class _CompletionValue extends StatelessWidget {
  final String label;
  final String value;

  const _CompletionValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CompletionBadge extends StatelessWidget {
  final String label;

  const _CompletionBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFB74D)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFFFFD180),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

enum _RemovalAction { cancelOccurrence, terminateRelationship }

enum _CurrentForecastAction { keep, cancel }

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

String _lifecycleOutcomeMessage(ExpectedExpenseLifecycleOutcome outcome) =>
    switch (outcome) {
      ExpectedExpenseLifecycleOutcome.applied => 'Impostazione aggiornata.',
      ExpectedExpenseLifecycleOutcome.alreadyCancelled =>
        'Questa previsione è già stata annullata.',
      ExpectedExpenseLifecycleOutcome.alreadyTerminated =>
        'Le previsioni future erano già state interrotte.',
      ExpectedExpenseLifecycleOutcome.missingRelationship =>
        'Rapporto della previsione non trovato.',
      ExpectedExpenseLifecycleOutcome.missingOccurrence =>
        'Previsione non trovata.',
      ExpectedExpenseLifecycleOutcome.identityMismatch =>
        'Identità della previsione non coerente.',
      ExpectedExpenseLifecycleOutcome.occurrenceNotPending =>
        'Questa previsione non può essere annullata nel suo stato attuale.',
      ExpectedExpenseLifecycleOutcome.relationshipNotActive =>
        'Questa spesa non può essere interrotta nel suo stato attuale.',
    };

String _certaintyLabel(ExpectedExpenseDateCertainty? certainty) =>
    switch (certainty) {
      ExpectedExpenseDateCertainty.estimated => 'Stimata',
      ExpectedExpenseDateCertainty.known => 'Conosciuta',
      ExpectedExpenseDateCertainty.legacyUnspecified || null => 'Non indicato',
    };

String _paymentModeLabel(PaymentExecutionMode mode) => switch (mode) {
  PaymentExecutionMode.unknown => 'Da definire',
  PaymentExecutionMode.requiresUserAction => 'Richiede una mia azione',
  PaymentExecutionMode.automatic => 'Automatico',
  PaymentExecutionMode.scheduled => 'Già programmato',
};

String _plannedImpactLabel(PlannedEconomicImpact? impact) {
  if (impact == null) return 'Non indicato';
  return impact.start == impact.end
      ? _date(impact.start)
      : '${_date(impact.start)} – ${_date(impact.end)}';
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
