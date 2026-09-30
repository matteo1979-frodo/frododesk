import 'package:flutter/material.dart';

import '../logic/finance/documentary_obligation_coordinator.dart';
import '../models/documentary_obligation.dart';
import '../models/expense_relationship.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/finance_category_template.dart';
import '../models/finance_recurring_item.dart';
import '../stores/finance_store.dart';
import '../utils/euro_formatter.dart';

typedef DocumentaryPaymentLauncher = Future<void> Function(
  BuildContext context,
  DocumentaryObligation obligation,
  DocumentaryInstallment installment,
);

class DocumentaryObligationsPage extends StatefulWidget {
  final FinanceStore financeStore;
  final DocumentaryPaymentLauncher? onRegisterPayment;

  const DocumentaryObligationsPage({
    super.key,
    required this.financeStore,
    this.onRegisterPayment,
  });

  @override
  State<DocumentaryObligationsPage> createState() =>
      _DocumentaryObligationsPageState();
}

class _DocumentaryObligationsPageState
    extends State<DocumentaryObligationsPage> {
  late final DocumentaryObligationCoordinator coordinator =
      DocumentaryObligationCoordinator(financeStore: widget.financeStore);

  Future<void> _add() async {
    final draft = await Navigator.of(context).push<_DocumentaryDraft>(
      MaterialPageRoute(
        builder: (_) => _DocumentaryObligationEditor(
          financeStore: widget.financeStore,
        ),
      ),
    );
    if (draft == null) return;
    final result = draft.relationship == null
        ? await coordinator.register(draft.obligation)
        : await coordinator.registerRecurringDocument(
            obligation: draft.obligation,
            relationship: draft.relationship!,
            nextExpectedDocument: draft.nextExpectedDocument!,
          );
    if (!mounted) return;
    if (result == DocumentaryObligationOutcome.conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identità già presente con dati diversi.')),
      );
    }
    setState(() {});
  }

  Future<void> _materialize(
    DocumentaryObligation obligation,
    DocumentaryContingency contingency,
  ) async {
    final relationshipId = obligation.relationshipId;
    if (relationshipId == null) return;
    final relationship = widget.financeStore.expectedExpenseAggregate.relationships
        .where((item) => item.relationshipId == relationshipId)
        .firstOrNull;
    if (relationship == null) return;
    final input = await showDialog<({double amount, DateTime dueDate})>(
      context: context,
      builder: (_) => _MaterializeDialog(
        initialDate: contingency.anticipatedDueDate ?? DateTime.now(),
      ),
    );
    if (input == null) return;
    final occurrence = ExpectedExpenseOccurrence(
      occurrenceId:
          'documentary_contingency:${obligation.obligationId}:${contingency.contingencyId}',
      relationshipId: relationshipId,
      status: ExpectedExpenseOccurrenceStatus.pending,
      knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
      knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
      expectedDueDate: input.dueDate,
      expectedDueDateSource: ExpectedExpenseDateSource.explicit,
      expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
      expectedAmount: input.amount,
      estimationMethod: ExpenseEstimationMethod.manualEstimate,
      confidence: ExpenseEstimateConfidence.high,
      provisional: false,
      expectedPaymentConfiguration: relationship.paymentConfiguration,
      paymentExecutionMode: relationship.paymentExecutionMode,
      expectedSubject: relationship.subject,
      participatesInCycleProjection: false,
    );
    await coordinator.materializeContingency(
      obligationId: obligation.obligationId,
      contingencyId: contingency.contingencyId,
      occurrence: occurrence,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final obligations = widget.financeStore.documentaryObligationAggregate.obligations;
    final expectedDocuments = widget.financeStore
        .documentaryObligationAggregate.expectedDocuments
        .where((item) => item.status == ExpectedDocumentCycleStatus.expected)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('Bollette e pagamenti'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black.withValues(alpha: 0.08),
        elevation: 0,
      ),
      body: _DocumentaryBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Theme(
              data: _documentaryTheme(context),
              child: obligations.isEmpty && expectedDocuments.isEmpty
                  ? _DocumentaryEmptyState(onAdd: _add)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                      children: [
                        _DocumentaryPageIntroduction(onAdd: _add),
                        const SizedBox(height: 16),
                        if (expectedDocuments.isNotEmpty) ...[
                          _DocumentaryGlassCard(
                            child: ExpansionTile(
                              leading: const Icon(Icons.event_note_outlined),
                              title: const Text(
                                'Documenti che dovrebbero arrivare',
                              ),
                              subtitle: const Text(
                                'Promemoria dei prossimi cicli attesi',
                              ),
                              children: [
                                for (final item in expectedDocuments)
                                  ListTile(
                                    title: Text(
                                      _relationshipName(item.relationshipId),
                                    ),
                                    subtitle: Text(
                                      '${_monthName(item.expectedPeriod.month)} '
                                      '${item.expectedPeriod.year}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        for (final obligation in obligations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentaryGlassCard(
                              child: ExpansionTile(
                                title: Text(obligation.title),
                                subtitle: Text(
                                  '${EuroFormatter.format(obligation.totalAmount)} · '
                                  '${obligation.documentHolder?.name ?? 'intestatario non indicato'}',
                                ),
                                children: [
                                  if (obligation.documentReference
                                      case final value?)
                                    ListTile(
                                      title: const Text('Riferimento'),
                                      subtitle: Text(value),
                                    ),
                                  for (final option in obligation.options)
                                    RadioListTile<String>(
                                      value: option.optionId,
                                      groupValue:
                                          obligation.effectiveSelectedOptionId,
                                      title: Text(option.label),
                                      subtitle: Text(
                                        option.installments
                                            .map(
                                              (item) =>
                                                  '${EuroFormatter.format(item.amount)} · ${_date(item.dueDate)}',
                                            )
                                            .join('\n'),
                                      ),
                                      onChanged:
                                          obligation.selectedOptionId != null
                                              ? null
                                              : (value) async {
                                                  if (value == null) return;
                                                  await coordinator
                                                      .selectOption(
                                                    obligationId: obligation
                                                        .obligationId,
                                                    optionId: value,
                                                  );
                                                  if (mounted) setState(() {});
                                                },
                                    ),
                                  for (final installment
                                      in obligation.operationalInstallments)
                                    ListTile(
                                      leading: const Icon(
                                        Icons.payments_outlined,
                                      ),
                                      title: Text(
                                        EuroFormatter.format(
                                          installment.amount,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Scadenza ${_date(installment.dueDate)}',
                                      ),
                                      trailing:
                                          widget.onRegisterPayment == null
                                              ? null
                                              : FilledButton(
                                                  onPressed: () async {
                                                    await widget
                                                        .onRegisterPayment!(
                                                      context,
                                                      obligation,
                                                      installment,
                                                    );
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Registra pagamento',
                                                  ),
                                                ),
                                    ),
                                  for (final contingency
                                      in obligation.contingencies)
                                    ListTile(
                                      title: Text(contingency.description),
                                      subtitle: Text(
                                        '${contingency.anticipatedDueDate == null ? 'Data non indicata' : _date(contingency.anticipatedDueDate!)} · '
                                        '${_contingencyStatus(contingency.status)}',
                                      ),
                                      trailing: contingency.status ==
                                              DocumentaryContingencyStatus
                                                  .pending
                                          ? Wrap(
                                              children: [
                                                if (obligation.relationshipId !=
                                                    null)
                                                  TextButton(
                                                    onPressed: () =>
                                                        _materialize(
                                                      obligation,
                                                      contingency,
                                                    ),
                                                    child: const Text(
                                                      'È arrivata',
                                                    ),
                                                  ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await coordinator
                                                        .closeContingencyNotDue(
                                                      obligationId: obligation
                                                          .obligationId,
                                                      contingencyId: contingency
                                                          .contingencyId,
                                                    );
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Non dovuta',
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _relationshipName(String id) => widget
      .financeStore.expectedExpenseAggregate.relationships
      .where((item) => item.relationshipId == id)
      .map((item) => item.service)
      .firstOrNull ?? 'Pagamento ricorrente';
}

class _DocumentaryDraft {
  final DocumentaryObligation obligation;
  final ExpenseRelationship? relationship;
  final ExpectedDocumentCycle? nextExpectedDocument;
  const _DocumentaryDraft({
    required this.obligation,
    this.relationship,
    this.nextExpectedDocument,
  });
}

class _DocumentaryObligationEditor extends StatefulWidget {
  final FinanceStore financeStore;
  const _DocumentaryObligationEditor({required this.financeStore});
  @override
  State<_DocumentaryObligationEditor> createState() =>
      _DocumentaryObligationEditorState();
}

class _DocumentaryObligationEditorState
    extends State<_DocumentaryObligationEditor> {
  static const int _customRecurrenceChoice = -1;

  final title = TextEditingController();
  final amount = TextEditingController();
  final reference = TextEditingController();
  final stableRelationshipName = TextEditingController();
  final provider = TextEditingController();
  final expectedYear = TextEditingController();
  FinanceSubject? holder;
  FinanceSubject? recurringSubject;
  String? relationshipId;
  String? expectedDocumentIdentity;
  bool repeats = false;
  int? recurringMonthsChoice;
  final customRecurringMonths = TextEditingController();
  String? recurringSubjectError;
  String? recurringPeriodicityError;
  String? stableRelationshipNameError;
  ExpenseRelationshipCycleLabelPolicy cycleLabelPolicy =
      ExpenseRelationshipCycleLabelPolicy.stableNameOnly;
  int? expectedMonth;
  final options = <DocumentaryFulfillmentOption>[];
  final contingencies = <DocumentaryContingency>[];

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    reference.dispose();
    stableRelationshipName.dispose();
    provider.dispose();
    expectedYear.dispose();
    customRecurringMonths.dispose();
    super.dispose();
  }

  ExpenseRelationshipPeriodicity? _selectedPeriodicity() {
    final choice = recurringMonthsChoice;
    if (choice == null) return null;
    if (choice == 1) {
      return ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      );
    }
    if (choice == 12) {
      return ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.yearly,
      );
    }
    final months = choice == _customRecurrenceChoice
        ? int.tryParse(customRecurringMonths.text.trim())
        : choice;
    if (months == null || months <= 0) return null;
    return ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.custom,
      customInterval: months,
      customIntervalUnit: 'months',
    );
  }

  String _periodicityLabel(ExpenseRelationshipPeriodicity periodicity) {
    return switch (periodicity.type) {
      FinanceRecurringType.monthly => 'Ogni mese',
      FinanceRecurringType.yearly => 'Ogni anno',
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'months' =>
        'Ogni ${periodicity.customInterval} mesi',
      FinanceRecurringType.custom => 'Periodicità personalizzata',
      FinanceRecurringType.oneShot => 'Una sola volta',
    };
  }

  Future<void> _addOption() async {
    final option = await showDialog<DocumentaryFulfillmentOption>(
      context: context,
      builder: (_) => _OptionDialog(index: options.length + 1),
    );
    if (option != null) setState(() => options.add(option));
  }

  Future<void> _addContingency() async {
    final value = await showDialog<DocumentaryContingency>(
      context: context,
      builder: (_) => _ContingencyDialog(index: contingencies.length + 1),
    );
    if (value != null) setState(() => contingencies.add(value));
  }

  void _save() {
    final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
    if (title.text.trim().isEmpty || parsed == null || parsed <= 0) return;
    try {
      final token = DateTime.now().microsecondsSinceEpoch;
      ExpenseRelationship? relationship;
      ExpectedDocumentCycle? nextExpectedDocument;
      String? linkedRelationshipId = relationshipId;
      int? cycleSequence;
      if (repeats) {
        final year = int.tryParse(expectedYear.text.trim());
        final periodicity = relationshipId == null
            ? _selectedPeriodicity()
            : null;
        if (relationshipId == null &&
            (recurringSubject == null ||
                periodicity == null ||
                stableRelationshipName.text.trim().isEmpty)) {
          setState(() {
            recurringSubjectError = recurringSubject == null
                ? 'Scegli la persona'
                : null;
            recurringPeriodicityError = periodicity == null
                ? recurringMonthsChoice == _customRecurrenceChoice
                      ? 'Inserisci un numero di mesi maggiore di zero'
                      : 'Scegli la frequenza'
                : null;
            stableRelationshipNameError =
                stableRelationshipName.text.trim().isEmpty
                ? 'Inserisci il nome stabile della spesa'
                : null;
          });
          return;
        }
        if (year == null ||
            expectedMonth == null ||
            (relationshipId == null &&
                provider.text.trim().isEmpty)) {
          return;
        }
        relationship = relationshipId == null
            ? ExpenseRelationship(
                relationshipId: 'document_relationship_$token',
                service: stableRelationshipName.text,
                provider: provider.text,
                subject: recurringSubject!,
                status: ExpenseRelationshipStatus.active,
                periodicity: periodicity!,
                cycleLabelPolicy: cycleLabelPolicy,
                paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
                  method: FinancePaymentMethod.manual,
                ),
              )
            : widget.financeStore.expectedExpenseAggregate.relationships
                .firstWhere((item) => item.relationshipId == relationshipId);
        linkedRelationshipId = relationship.relationshipId;
        final sequences = <int>[
          for (final item in widget.financeStore.documentaryObligationAggregate.obligations)
            if (item.relationshipId == linkedRelationshipId && item.cycleSequence != null)
              item.cycleSequence!,
          for (final item in widget.financeStore.documentaryObligationAggregate.expectedDocuments)
            if (item.relationshipId == linkedRelationshipId) item.cycleSequence,
          for (final item in widget.financeStore.expectedExpenseAggregate.occurrences)
            if (item.relationshipId == linkedRelationshipId && item.cycleSequence != null)
              item.cycleSequence!,
        ];
        final pendingExpected = widget.financeStore.documentaryObligationAggregate.expectedDocuments
            .where((item) => item.relationshipId == linkedRelationshipId && item.status == ExpectedDocumentCycleStatus.expected)
            .toList();
        if (pendingExpected.isNotEmpty && expectedDocumentIdentity == null) return;
        cycleSequence = pendingExpected.isNotEmpty
            ? pendingExpected.firstWhere((item) => item.identity == expectedDocumentIdentity).cycleSequence
            : sequences.isEmpty
                ? 1
                : sequences.reduce((left, right) => left > right ? left : right) + 1;
        nextExpectedDocument = ExpectedDocumentCycle(
          relationshipId: linkedRelationshipId,
          cycleSequence: cycleSequence + 1,
          expectedPeriod: ExpectedDocumentPeriod(
            year: year,
            month: expectedMonth!,
          ),
        );
      }
      Navigator.pop(
        context,
        _DocumentaryDraft(
          obligation: DocumentaryObligation(
            obligationId: 'documentary_obligation_$token',
            title: title.text,
            totalAmount: parsed,
            documentHolder: holder,
            documentReference: reference.text.trim().isEmpty ? null : reference.text,
            relationshipId: linkedRelationshipId,
            cycleSequence: cycleSequence,
            options: options,
            contingencies: contingencies,
          ),
          relationship: relationship,
          nextExpectedDocument: nextExpectedDocument,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF101820),
    appBar: AppBar(
      title: const Text('Nuova bolletta o pagamento'),
      foregroundColor: Colors.white,
      backgroundColor: Colors.black.withValues(alpha: 0.08),
      elevation: 0,
    ),
    body: _DocumentaryBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Theme(
            data: _documentaryTheme(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                const _DocumentaryEditorIntroduction(),
                const SizedBox(height: 16),
                _DocumentaryFormSection(
                  icon: Icons.receipt_long_outlined,
                  title: 'Il pagamento',
                  subtitle: 'Inserisci i dati che conosci oggi.',
                  children: [
                    TextField(
                      key: const ValueKey('documentary-title'),
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Nome della bolletta o pagamento',
                      ),
                    ),
                    TextField(
                      key: const ValueKey('documentary-amount'),
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quanto devi pagare?',
                      ),
                    ),
                    DropdownButtonFormField<FinanceSubject?>(
                      initialValue: holder,
                      decoration: const InputDecoration(
                        labelText: 'A chi è intestato? (opzionale)',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Non indicato'),
                        ),
                        DropdownMenuItem(
                          value: FinanceSubject.matteo,
                          child: Text('Matteo'),
                        ),
                        DropdownMenuItem(
                          value: FinanceSubject.chiara,
                          child: Text('Chiara'),
                        ),
                        DropdownMenuItem(
                          value: FinanceSubject.alice,
                          child: Text('Alice'),
                        ),
                      ],
                      onChanged: (value) => setState(() => holder = value),
                    ),
                    TextField(
                      controller: reference,
                      decoration: const InputDecoration(
                        labelText: 'Riferimento o note (opzionale)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DocumentaryFormSection(
                  icon: Icons.repeat_rounded,
                  title: 'Quando torna',
                  subtitle:
                      'Tieni distinto il mese in cui la aspetti dalle scadenze reali dei pagamenti.',
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: relationshipId,
                      decoration: const InputDecoration(
                        labelText:
                            'È collegata a una spesa già ricorrente? (opzionale)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Nessuna'),
                        ),
                        for (final relationship in widget.financeStore
                            .expectedExpenseAggregate.relationships)
                          DropdownMenuItem(
                            value: relationship.relationshipId,
                            child: Text(
                              '${relationship.service} · ${relationship.provider}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        relationshipId = value;
                        expectedDocumentIdentity = null;
                        repeats = value != null;
                        if (value == null) {
                          recurringSubject = null;
                        } else {
                          recurringSubject = widget.financeStore
                              .expectedExpenseAggregate.relationships
                              .firstWhere(
                                (item) => item.relationshipId == value,
                              )
                              .subject;
                        }
                        recurringSubjectError = null;
                      }),
                    ),
                    SwitchListTile(
                      key: const ValueKey('documentary-repeats'),
                      contentPadding: EdgeInsets.zero,
                      value: repeats,
                      title: const Text('Questa spesa si ripete'),
                      subtitle: const Text(
                        'Ricordami quando dovrebbe arrivare il prossimo documento.',
                      ),
                      onChanged: (value) => setState(() {
                        repeats = value;
                        if (!value) relationshipId = null;
                      }),
                    ),
                    if (repeats) ...[
                      if (relationshipId != null &&
                          widget.financeStore.documentaryObligationAggregate
                              .expectedDocuments
                              .any(
                                (item) =>
                                    item.relationshipId == relationshipId &&
                                    item.status ==
                                        ExpectedDocumentCycleStatus.expected,
                              ))
                        DropdownButtonFormField<String>(
                          initialValue: expectedDocumentIdentity,
                          decoration: const InputDecoration(
                            labelText: 'Quale documento è arrivato?',
                          ),
                          items: [
                            for (final item in widget.financeStore
                                .documentaryObligationAggregate
                                .expectedDocuments
                                .where(
                                  (item) =>
                                      item.relationshipId == relationshipId &&
                                      item.status ==
                                          ExpectedDocumentCycleStatus.expected,
                                ))
                              DropdownMenuItem(
                                value: item.identity,
                                child: Text(
                                  '${_monthName(item.expectedPeriod.month)} '
                                  '${item.expectedPeriod.year}',
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => expectedDocumentIdentity = value,
                          ),
                        ),
                      if (relationshipId == null)
                        TextField(
                          key: const ValueKey(
                            'documentary-stable-relationship-name',
                          ),
                          controller: stableRelationshipName,
                          decoration: InputDecoration(
                            labelText: 'Nome stabile della spesa',
                            hintText: 'Per esempio TARI',
                            helperText:
                                'Resta uguale anche quando cambia l’anno del documento.',
                            errorText: stableRelationshipNameError,
                          ),
                          onChanged: (_) => setState(
                            () => stableRelationshipNameError = null,
                          ),
                        ),
                      if (relationshipId == null)
                        TextField(
                          key: const ValueKey('documentary-provider'),
                          controller: provider,
                          decoration: const InputDecoration(
                            labelText: 'Ente o fornitore',
                          ),
                        ),
                      DropdownButtonFormField<FinanceSubject>(
                        key: ValueKey(
                          'recurring-subject-${relationshipId ?? 'new'}-'
                          '${recurringSubject?.name ?? 'none'}',
                        ),
                        initialValue: recurringSubject,
                        decoration: InputDecoration(
                          labelText: 'Di chi è normalmente la spesa',
                          hintText: 'Scegli la persona',
                          errorText: recurringSubjectError,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FinanceSubject.matteo,
                            child: Text('Matteo'),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.chiara,
                            child: Text('Chiara'),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.alice,
                            child: Text('Alice'),
                          ),
                        ],
                        onChanged: relationshipId != null
                            ? null
                            : (value) => setState(() {
                                recurringSubject = value;
                                recurringSubjectError = null;
                              }),
                      ),
                      if (relationshipId == null)
                        DropdownButtonFormField<int>(
                          key: const ValueKey('documentary-recurrence'),
                          initialValue: recurringMonthsChoice,
                          decoration: InputDecoration(
                            labelText: 'Quanto spesso torna',
                            hintText: 'Scegli la frequenza',
                            errorText:
                                recurringMonthsChoice ==
                                    _customRecurrenceChoice
                                ? null
                                : recurringPeriodicityError,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text('Ogni mese'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Ogni 2 mesi'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Ogni 3 mesi'),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text('Ogni 4 mesi'),
                            ),
                            DropdownMenuItem(
                              value: 6,
                              child: Text('Ogni 6 mesi'),
                            ),
                            DropdownMenuItem(
                              value: 12,
                              child: Text('Ogni anno'),
                            ),
                            DropdownMenuItem(
                              value: _customRecurrenceChoice,
                              child: Text('Personalizzata…'),
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            recurringMonthsChoice = value;
                            recurringPeriodicityError = null;
                            if (value != _customRecurrenceChoice) {
                              customRecurringMonths.clear();
                            }
                            if (!(_selectedPeriodicity()?.isAnnualCycle ??
                                false)) {
                              cycleLabelPolicy =
                                  ExpenseRelationshipCycleLabelPolicy
                                      .stableNameOnly;
                            }
                          }),
                        ),
                      if (relationshipId == null &&
                          recurringMonthsChoice == _customRecurrenceChoice)
                        TextField(
                          key: const ValueKey('documentary-custom-months'),
                          controller: customRecurringMonths,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Ogni quanti mesi?',
                            hintText: 'Inserisci un numero maggiore di zero',
                            errorText: recurringPeriodicityError,
                          ),
                          onChanged: (_) => setState(
                            () {
                              recurringPeriodicityError = null;
                              if (!(_selectedPeriodicity()?.isAnnualCycle ??
                                  false)) {
                                cycleLabelPolicy =
                                    ExpenseRelationshipCycleLabelPolicy
                                        .stableNameOnly;
                              }
                            },
                          ),
                        ),
                      if (relationshipId == null &&
                          (_selectedPeriodicity()?.isAnnualCycle ?? false))
                        SwitchListTile(
                          key: const ValueKey(
                            'documentary-cycle-label-year',
                          ),
                          contentPadding: EdgeInsets.zero,
                          value:
                              cycleLabelPolicy ==
                              ExpenseRelationshipCycleLabelPolicy
                                  .stableNameWithTargetYear,
                          title: const Text(
                            'Mostra l’anno nel titolo delle previsioni',
                          ),
                          subtitle: const Text(
                            'Per esempio: TARI 2027.',
                          ),
                          onChanged: (value) => setState(() {
                            cycleLabelPolicy = value
                                ? ExpenseRelationshipCycleLabelPolicy
                                      .stableNameWithTargetYear
                                : ExpenseRelationshipCycleLabelPolicy
                                      .stableNameOnly;
                          }),
                        ),
                      if (relationshipId != null)
                        Builder(
                          builder: (context) {
                            final relationship = widget.financeStore
                                .expectedExpenseAggregate.relationships
                                .firstWhere(
                                  (item) =>
                                      item.relationshipId == relationshipId,
                                );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Quanto spesso torna'),
                              subtitle: Text(
                                _periodicityLabel(relationship.periodicity),
                              ),
                            );
                          },
                        ),
                      DropdownButtonFormField<int>(
                        key: const ValueKey('documentary-expected-month'),
                        initialValue: expectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Mese in cui dovrebbe arrivare',
                          hintText: 'Scegli il mese',
                        ),
                        items: [
                          for (var month = 1; month <= 12; month++)
                            DropdownMenuItem(
                              value: month,
                              child: Text(_monthName(month)),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => expectedMonth = value),
                      ),
                      TextField(
                        key: const ValueKey('documentary-expected-year'),
                        controller: expectedYear,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Anno previsto',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _DocumentaryFormSection(
                  icon: Icons.payments_outlined,
                  title: 'Come puoi pagarla?',
                  subtitle:
                      'Aggiungi una o più alternative indicate sul documento.',
                  children: [
                    for (final option in options)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(option.label),
                        subtitle: Text(
                          '${option.installments.length} '
                          '${option.installments.length == 1 ? 'pagamento' : 'pagamenti'}',
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Aggiungi un’alternativa'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DocumentaryFormSection(
                  icon: Icons.help_outline_rounded,
                  title: 'Potrebbero arrivare altri pagamenti?',
                  subtitle:
                      'Annotali senza indicare un importo finché non diventano reali.',
                  children: [
                    for (final item in contingencies)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text(item.description),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addContingency,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Aggiungi un possibile pagamento'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('documentary-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salva'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

ThemeData _documentaryTheme(BuildContext context) {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFFA8D5BA),
      secondary: const Color(0xFFD6B36A),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFA8D5BA), width: 1.5),
      ),
    ),
  );
}

class _DocumentaryBackground extends StatelessWidget {
  final Widget child;
  const _DocumentaryBackground({required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ColoredBox(color: Colors.black.withValues(alpha: 0.30)),
          SafeArea(top: false, child: child),
        ],
      );
}

class _DocumentaryGlassCard extends StatelessWidget {
  final Widget child;
  const _DocumentaryGlassCard({required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: child,
      );
}

class _DocumentaryPageIntroduction extends StatelessWidget {
  final VoidCallback onAdd;
  const _DocumentaryPageIntroduction({required this.onAdd});

  @override
  Widget build(BuildContext context) => _DocumentaryGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 34),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bollette e pagamenti',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Conserva importi, scadenze e alternative di pagamento in un unico posto.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Aggiungi'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DocumentaryEditorIntroduction extends StatelessWidget {
  const _DocumentaryEditorIntroduction();

  @override
  Widget build(BuildContext context) => const _DocumentaryGlassCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note_rounded, size: 34),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aggiungi ciò che sai',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Puoi indicare più modi di pagare e annotare costi futuri ancora incerti.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _DocumentaryFormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _DocumentaryFormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => _DocumentaryGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: const Color(0xFFA8D5BA)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                children[index],
              ],
            ],
          ),
        ),
      );
}

class _DocumentaryEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _DocumentaryEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _DocumentaryGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 52),
                  const SizedBox(height: 16),
                  const Text(
                    'Nessuna bolletta o pagamento',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aggiungi il primo documento per ricordare importi, scadenze e alternative di pagamento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MaterializeDialog extends StatefulWidget {
  final DateTime initialDate;
  const _MaterializeDialog({required this.initialDate});
  @override State<_MaterializeDialog> createState() => _MaterializeDialogState();
}

class _MaterializeDialogState extends State<_MaterializeDialog> {
  final amount = TextEditingController();
  late DateTime dueDate = widget.initialDate;
  @override void dispose() { amount.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Documento arrivato'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo conosciuto')),
      ListTile(title: const Text('Scadenza reale'), subtitle: Text(_date(dueDate)), onTap: () async { final value = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (value != null) setState(() => dueDate = value); }),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
      FilledButton(onPressed: () { final parsed = double.tryParse(amount.text.replaceAll(',', '.')); if (parsed != null && parsed > 0) Navigator.pop(context, (amount: parsed, dueDate: dueDate)); }, child: const Text('Conferma arrivo')),
    ],
  );
}

class _OptionDialog extends StatefulWidget {
  final int index;
  const _OptionDialog({required this.index});
  @override State<_OptionDialog> createState() => _OptionDialogState();
}

class _OptionDialogState extends State<_OptionDialog> {
  final label = TextEditingController();
  final amount = TextEditingController();
  DateTime? dueDate;
  final installments = <DocumentaryInstallment>[];
  @override void dispose() { label.dispose(); amount.dispose(); super.dispose(); }
  void _addInstallment() {
    final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0 || dueDate == null) return;
    setState(() {
      installments.add(
        DocumentaryInstallment(
          installmentId:
              'installment_${widget.index}_${installments.length + 1}',
          amount: parsed,
          dueDate: dueDate!,
        ),
      );
      amount.clear();
      dueDate = null;
    });
  }
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Come puoi pagarla?'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: label, decoration: const InputDecoration(labelText: 'Nome dell’alternativa')),
      TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo di questo pagamento')),
      ListTile(title: const Text('Quando scade?'), subtitle: Text(dueDate == null ? 'Scegli una data' : _date(dueDate!)), onTap: () async { final value = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (value != null) setState(() => dueDate = value); }),
      OutlinedButton(onPressed: dueDate == null ? null : _addInstallment, child: const Text('Aggiungi questo pagamento')),
      for (final item in installments) Text('${EuroFormatter.format(item.amount)} · ${_date(item.dueDate)}'),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')), FilledButton(onPressed: installments.isEmpty ? null : () => Navigator.pop(context, DocumentaryFulfillmentOption(optionId: 'option_${widget.index}', label: label.text, installments: installments)), child: const Text('Conferma'))],
  );
}

class _ContingencyDialog extends StatefulWidget {
  final int index; const _ContingencyDialog({required this.index});
  @override State<_ContingencyDialog> createState() => _ContingencyDialogState();
}
class _ContingencyDialogState extends State<_ContingencyDialog> {
  final description = TextEditingController(); DateTime? date;
  @override void dispose() { description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Possibile pagamento futuro'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: description, decoration: const InputDecoration(labelText: 'Che cosa potrebbe arrivare?')), ListTile(title: const Text('Quando potrebbe arrivare? (opzionale)'), subtitle: Text(date == null ? 'Data non indicata' : _date(date!)), onTap: () async { final value = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (value != null) setState(() => date = value); })]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(context, DocumentaryContingency(contingencyId: 'contingency_${widget.index}', description: description.text, anticipatedDueDate: date)), child: const Text('Aggiungi'))],
  );
}

String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _monthName(int month) => const [
  'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
  'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
][month - 1];
String _contingencyStatus(DocumentaryContingencyStatus status) => switch (status) {
  DocumentaryContingencyStatus.pending => 'Da verificare',
  DocumentaryContingencyStatus.materialized => 'Arrivato',
  DocumentaryContingencyStatus.notDue => 'Non dovuto',
};
