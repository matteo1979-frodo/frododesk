import 'package:flutter/material.dart';

import '../logic/finance/expected_expense_registration_coordinator.dart';
import '../models/economic_operation_metadata.dart';
import '../models/expense_relationship.dart';
import '../models/first_cycle_expense_evidence.dart';
import '../models/finance_category_template.dart';
import '../models/finance_recurring_item.dart';
import '../models/real_expense.dart';
import '../stores/finance_store.dart';

enum _SupportedPeriodicity { monthly, yearly, customMonths }

bool canCreateExpectedExpensePrediction(RealExpense expense) =>
    !expense.isIncome &&
    !expense.isCashWithdrawal &&
    expense.economicFactId != null &&
    expense.operationMetadata?.role != OperationRole.accessory;

class ExpectedExpenseFromRealExpensePage extends StatefulWidget {
  final RealExpense expense;
  final FinanceStore financeStore;
  final String relationshipId;
  final String occurrenceId;

  const ExpectedExpenseFromRealExpensePage({
    super.key,
    required this.expense,
    required this.financeStore,
    required this.relationshipId,
    required this.occurrenceId,
  });

  @override
  State<ExpectedExpenseFromRealExpensePage> createState() =>
      _ExpectedExpenseFromRealExpensePageState();
}

class _ExpectedExpenseFromRealExpensePageState
    extends State<ExpectedExpenseFromRealExpensePage> {
  final serviceController = TextEditingController();
  final providerController = TextEditingController();
  _SupportedPeriodicity periodicity = _SupportedPeriodicity.monthly;
  int customMonths = 2;
  ExpenseEvidenceDateSemantic dateSemantic =
      ExpenseEvidenceDateSemantic.issue;
  FinancePaymentMethod paymentMethod = FinancePaymentMethod.manual;
  late DateTime evidenceDate;
  DateTime? explicitNextDate;
  bool useExpectedBalance = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    evidenceDate = widget.expense.date;
  }

  @override
  void dispose() {
    serviceController.dispose();
    providerController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidenceDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: evidenceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => evidenceDate = value);
  }

  Future<void> _pickNextDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: explicitNextDate ?? evidenceDate.add(const Duration(days: 1)),
      firstDate: evidenceDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => explicitNextDate = value);
  }

  ExpenseRelationshipPeriodicity _periodicity() => switch (periodicity) {
    _SupportedPeriodicity.monthly => ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.monthly,
    ),
    _SupportedPeriodicity.yearly => ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.yearly,
    ),
    _SupportedPeriodicity.customMonths => ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.custom,
      customInterval: customMonths,
      customIntervalUnit: 'months',
    ),
  };

  Future<void> _submit() async {
    if (submitting) return;
    final service = serviceController.text.trim();
    final provider = providerController.text.trim();
    final factId = widget.expense.economicFactId;
    if (service.isEmpty || provider.isEmpty || factId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila servizio e fornitore.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await ExpectedExpenseRegistrationCoordinator(
        financeStore: widget.financeStore,
      ).register(
        relationship: ExpenseRelationship(
          relationshipId: widget.relationshipId,
          service: service,
          provider: provider,
          subject: widget.expense.subject,
          status: ExpenseRelationshipStatus.active,
          periodicity: _periodicity(),
          paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
            method: paymentMethod,
            expectedBalanceId: useExpectedBalance
                ? widget.expense.balanceId
                : null,
          ),
        ),
        evidence: FirstCycleExpenseEvidence(
          economicFactId: factId,
          amount: widget.expense.amount,
          referenceDate: evidenceDate,
          referenceDateSemantic: dateSemantic,
          operationMetadata: widget.expense.operationMetadata,
        ),
        occurrenceId: widget.occurrenceId,
        explicitNextDate: explicitNextDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Previsione non salvata: $error')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prevedi le prossime')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Importo di riferimento: €${widget.expense.amount.toStringAsFixed(2)}'),
          Text('Soggetto: ${widget.expense.subject.name}'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('expected-service'),
            controller: serviceController,
            decoration: const InputDecoration(labelText: 'Servizio'),
          ),
          TextField(
            key: const Key('expected-provider'),
            controller: providerController,
            decoration: const InputDecoration(labelText: 'Fornitore'),
          ),
          DropdownButtonFormField<_SupportedPeriodicity>(
            key: const Key('expected-periodicity'),
            initialValue: periodicity,
            decoration: const InputDecoration(labelText: 'Periodicità'),
            items: const [
              DropdownMenuItem(
                value: _SupportedPeriodicity.monthly,
                child: Text('Mensile'),
              ),
              DropdownMenuItem(
                value: _SupportedPeriodicity.yearly,
                child: Text('Annuale'),
              ),
              DropdownMenuItem(
                value: _SupportedPeriodicity.customMonths,
                child: Text('Personalizzata in mesi'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => periodicity = value);
            },
          ),
          if (periodicity == _SupportedPeriodicity.customMonths)
            DropdownButtonFormField<int>(
              key: const Key('expected-custom-months'),
              initialValue: customMonths,
              decoration: const InputDecoration(labelText: 'Ogni quanti mesi'),
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} mesi'),
                ),
              ),
              onChanged: (value) {
                if (value != null) setState(() => customMonths = value);
              },
            ),
          DropdownButtonFormField<ExpenseEvidenceDateSemantic>(
            key: const Key('expected-date-semantic'),
            initialValue: dateSemantic,
            decoration: const InputDecoration(labelText: 'Tipo data evidenza'),
            items: const [
              DropdownMenuItem(
                value: ExpenseEvidenceDateSemantic.issue,
                child: Text('Emissione'),
              ),
              DropdownMenuItem(
                value: ExpenseEvidenceDateSemantic.due,
                child: Text('Scadenza'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => dateSemantic = value);
            },
          ),
          ListTile(
            key: const Key('expected-evidence-date'),
            title: const Text('Data evidenza'),
            subtitle: Text(_date(evidenceDate)),
            onTap: _pickEvidenceDate,
          ),
          ListTile(
            key: const Key('expected-next-date'),
            title: const Text('Prossima data conosciuta (opzionale)'),
            subtitle: Text(explicitNextDate == null ? 'Non indicata' : _date(explicitNextDate!)),
            trailing: explicitNextDate == null
                ? null
                : IconButton(
                    onPressed: () => setState(() => explicitNextDate = null),
                    icon: const Icon(Icons.clear),
                  ),
            onTap: _pickNextDate,
          ),
          DropdownButtonFormField<FinancePaymentMethod>(
            key: const Key('expected-payment-method'),
            initialValue: paymentMethod,
            decoration: const InputDecoration(labelText: 'Metodo previsto'),
            items: FinancePaymentMethod.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => paymentMethod = value);
            },
          ),
          SwitchListTile(
            key: const Key('expected-balance-switch'),
            value: useExpectedBalance,
            title: Text('Conto previsto: ${widget.expense.balanceName}'),
            onChanged: (value) => setState(() => useExpectedBalance = value),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('save-expected-expense'),
            onPressed: submitting ? null : _submit,
            child: Text(submitting ? 'Salvataggio...' : 'Salva previsione'),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
