import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/finance/income_forecast_reader.dart';
import '../logic/finance/income_lifecycle_coordinator.dart';
import '../models/balance_posting_mode.dart';
import '../models/finance_recurring_item.dart';
import '../models/income.dart';
import '../models/projected_expense_cycle.dart';
import '../stores/finance_store.dart';
import '../utils/euro_formatter.dart';

class IncomePage extends StatefulWidget {
  final FinanceStore financeStore;
  final DateTime? referenceTime;

  const IncomePage({super.key, required this.financeStore, this.referenceTime});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  IncomeLifecycleCoordinator get coordinator =>
      IncomeLifecycleCoordinator(financeStore: widget.financeStore);

  @override
  Widget build(BuildContext context) {
    final aggregate = widget.financeStore.incomeAggregate;
    final now = widget.referenceTime ?? DateTime.now();
    final forecast = const IncomeForecastReader().read(
      aggregate: aggregate,
      horizon: ExpenseProjectionHorizon(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year + 1, 12, 31),
      ),
    );
    final reconciliations = aggregate.reconciliations.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return Scaffold(
      backgroundColor: const Color(0xFF102016),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102016),
        title: const Text('Entrate'),
        actions: [
          IconButton(
            tooltip: 'Aggiungi categoria',
            onPressed: _addCustomCategory,
            icon: const Icon(Icons.category_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRelationship,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuova entrata'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: [
          _introCard(),
          const SizedBox(height: 18),
          _sectionTitle('Futuro', 'Previsioni: non diventano reali da sole.'),
          if (forecast.items.isEmpty)
            _empty('Nessuna entrata prevista.')
          else
            ...forecast.items.map((item) => _forecastTile(item)),
          const SizedBox(height: 22),
          _sectionTitle('Rapporti', 'Fonti ricorrenti e una tantum.'),
          if (aggregate.relationships.isEmpty)
            _empty('Nessun rapporto inserito.')
          else
            ...aggregate.relationships.map(_relationshipCard),
          const SizedBox(height: 22),
          _sectionTitle('Storico', 'Entrate realmente ricevute.'),
          if (reconciliations.isEmpty)
            _empty('Nessuna entrata reale registrata.')
          else
            ...reconciliations.map(_historyTile),
        ],
      ),
    );
  }

  Widget _introCard() => Card(
    color: const Color(0xFF1B3424),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Passato reale, futuro previsto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Registra un accredito normale oppure uno storico già compreso nel saldo attuale.',
            style: TextStyle(color: Colors.white.withOpacity(.72)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _recordCredit(),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Registra entrata ricevuta'),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.62))),
      ],
    ),
  );

  Widget _empty(String value) => Card(
    color: Colors.white.withOpacity(.07),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(value, style: TextStyle(color: Colors.white.withOpacity(.7))),
    ),
  );

  Widget _forecastTile(dynamic item) => Card(
    color: Colors.white.withOpacity(.09),
    child: ListTile(
      leading: const Icon(Icons.schedule_rounded, color: Color(0xFF81C784)),
      title: Text(item.label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        '${DateFormat('dd MMM yyyy', 'it_IT').format(item.economicDate)} • ${_knowledgeLabel(item.knowledge)}',
        style: TextStyle(color: Colors.white.withOpacity(.65)),
      ),
      trailing: Text(
        EuroFormatter.format(item.amount),
        style: const TextStyle(
          color: Color(0xFF81C784),
          fontWeight: FontWeight.w900,
        ),
      ),
      onTap: () => _recordCredit(
        relationshipId: item.relationshipId,
        occurrenceId: item.occurrenceId,
        suggestedAmount: item.amount,
      ),
    ),
  );

  Widget _relationshipCard(IncomeRelationship relationship) => Card(
    color: relationship.isSalary
        ? const Color(0xFF193B2A)
        : Colors.white.withOpacity(.09),
    child: ListTile(
      leading: Icon(
        relationship.isSalary
            ? Icons.badge_outlined
            : Icons.arrow_downward_rounded,
        color: const Color(0xFF81C784),
      ),
      title: Text(
        relationship.isSalary
            ? 'Stipendio • ${relationship.label}'
            : relationship.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${_categoryLabel(relationship.category)} • ${_periodicityLabel(relationship.periodicity)}\n'
        '${_subjectLabel(relationship.subject)} • ${relationship.payer ?? 'Payer non indicato'} • ${_balanceName(relationship.destinationBalanceId)}',
        style: TextStyle(color: Colors.white.withOpacity(.65)),
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            EuroFormatter.format(relationship.expectedOrdinaryAmount),
            style: const TextStyle(
              color: Color(0xFF81C784),
              fontWeight: FontWeight.w900,
            ),
          ),
          InkWell(
            onTap: () => _editRelationship(relationship),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
      onTap: () => _recordCredit(
        relationshipId: relationship.relationshipId,
        suggestedAmount: relationship.expectedOrdinaryAmount,
      ),
    ),
  );

  Widget _historyTile(IncomeReconciliation item) => Card(
    color: Colors.white.withOpacity(.09),
    child: ExpansionTile(
      iconColor: Colors.white,
      collapsedIconColor: Colors.white70,
      leading: Icon(
        item.postingMode == BalancePostingMode.alreadyIncludedInCurrentBalance
            ? Icons.history_rounded
            : Icons.check_circle_outline_rounded,
        color: const Color(0xFF81C784),
      ),
      title: Text(
        '${EuroFormatter.format(item.totalAmount)} • ${_subjectLabel(item.subject)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${DateFormat('dd MMM yyyy', 'it_IT').format(item.occurredAt)} • ${_balanceName(item.destinationBalanceId)}'
        '${item.postingMode == BalancePostingMode.alreadyIncludedInCurrentBalance ? ' • già nel saldo' : ''}',
        style: TextStyle(color: Colors.white.withOpacity(.65)),
      ),
      children: [
        ...item.allocations.map(
          (part) => ListTile(
            dense: true,
            title: Text(
              part.label,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _componentLabel(part.kind),
              style: TextStyle(color: Colors.white.withOpacity(.6)),
            ),
            trailing: Text(
              EuroFormatter.format(part.amount),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _correctCredit(item),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Correggi'),
          ),
        ),
      ],
    ),
  );

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;
    final id = 'income-category:${DateTime.now().microsecondsSinceEpoch}';
    await coordinator.addCustomCategory(
      IncomeCustomCategory(id: id, label: label),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addRelationship() async {
    final result = await showDialog<_RelationshipDraft>(
      context: context,
      builder: (_) => _RelationshipDialog(financeStore: widget.financeStore),
    );
    if (result == null) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final relationshipId = 'income-relationship:$stamp';
    await coordinator.addRelationship(
      IncomeRelationship(
        relationshipId: relationshipId,
        label: result.label,
        category: result.category,
        customCategoryId: result.customCategoryId,
        subject: result.subject,
        payer: result.payer,
        destinationBalanceId: result.balanceId,
        expectedOrdinaryAmount: result.amount,
        periodicity: result.periodicity,
        customIntervalMonths: result.customIntervalMonths,
        firstExpectedDate: result.date,
        historyBasedForecastEnabled: result.useHistory,
      ),
    );
    await coordinator.addOccurrence(
      ExpectedIncomeOccurrence(
        occurrenceId: 'income-occurrence:$stamp:1',
        relationshipId: relationshipId,
        cycleSequence: result.periodicity == IncomePeriodicity.oneTime
            ? null
            : 1,
        expectedDate: result.date,
        expectedAmount: result.amount,
        provenance: IncomeProvenance.userEntered,
        knowledge: result.balanceId == null
            ? IncomeKnowledge.incomplete
            : IncomeKnowledge.known,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editRelationship(IncomeRelationship original) async {
    final result = await showDialog<_RelationshipDraft>(
      context: context,
      builder: (_) => _RelationshipDialog(
        financeStore: widget.financeStore,
        initial: original,
      ),
    );
    if (result == null) return;
    await coordinator.updateRelationship(
      IncomeRelationship(
        relationshipId: original.relationshipId,
        label: result.label,
        category: result.category,
        customCategoryId: result.customCategoryId,
        subject: result.subject,
        payer: result.payer,
        destinationBalanceId: result.balanceId,
        expectedOrdinaryAmount: result.amount,
        periodicity: result.periodicity,
        customIntervalMonths: result.customIntervalMonths,
        firstExpectedDate: result.date,
        historyBasedForecastEnabled: result.useHistory,
        active: original.active,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _recordCredit({
    String? relationshipId,
    String? occurrenceId,
    double? suggestedAmount,
  }) async {
    final result = await showDialog<_CreditDraft>(
      context: context,
      builder: (_) => _CreditDialog(
        financeStore: widget.financeStore,
        initialRelationshipId: relationshipId,
        initialOccurrenceId: occurrenceId,
        initialAmount: suggestedAmount,
      ),
    );
    if (result == null) return;
    final operationId = DateTime.now().microsecondsSinceEpoch.toString();
    await coordinator.recordCredit(
      IncomeCreditRequest(
        operationId: operationId,
        relationshipId: result.relationshipId,
        occurredAt: result.date,
        totalAmount: result.total,
        subject: result.subject,
        payer: result.payer,
        destinationBalanceId: result.balanceId,
        postingMode: result.historical
            ? BalancePostingMode.alreadyIncludedInCurrentBalance
            : BalancePostingMode.affectsCurrentBalance,
        allocations: result.parts.indexed
            .map(
              (entry) => IncomeReconciliationAllocation(
                componentId: 'income-component:$operationId:${entry.$1}',
                kind: entry.$2.kind,
                label: _componentLabel(entry.$2.kind),
                amount: entry.$2.amount,
                occurrenceId: result.occurrenceId,
              ),
            )
            .toList(),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _correctCredit(IncomeReconciliation original) async {
    final result = await showDialog<_CreditDraft>(
      context: context,
      builder: (_) => _CreditDialog(
        financeStore: widget.financeStore,
        initialRelationshipId: original.relationshipId,
        initialOccurrenceId: original.allocations
            .map((item) => item.occurrenceId)
            .whereType<String>()
            .toSet()
            .singleOrNull,
        initialAmount: original.totalAmount,
        initialDate: original.occurredAt,
        initialSubject: original.subject,
        initialBalanceId: original.destinationBalanceId,
        initialPayer: original.payer,
        fixedHistorical:
            original.postingMode ==
            BalancePostingMode.alreadyIncludedInCurrentBalance,
        initialParts: original.allocations
            .map((item) => _CreditPart(item.kind, item.amount))
            .toList(),
      ),
    );
    if (result == null) return;
    await coordinator.correctCredit(
      reconciliationId: original.reconciliationId,
      occurredAt: result.date,
      totalAmount: result.total,
      subject: result.subject,
      payer: result.payer,
      destinationBalanceId: result.balanceId,
      relationshipId: result.relationshipId,
      replaceRelationship: true,
      allocations: result.parts.indexed
          .map(
            (entry) => IncomeReconciliationAllocation(
              componentId:
                  'income-component:${original.reconciliationId}:${entry.$1}',
              kind: entry.$2.kind,
              label: _componentLabel(entry.$2.kind),
              amount: entry.$2.amount,
              occurrenceId: result.occurrenceId,
            ),
          )
          .toList(),
    );
    if (mounted) setState(() {});
  }

  String _balanceName(String? id) => id == null
      ? 'Conto non ancora noto'
      : widget.financeStore.balances
                .where((item) => item.balanceId == id)
                .map((item) => item.name)
                .firstOrNull ??
            'Conto non disponibile';
}

class _RelationshipDraft {
  final String label;
  final IncomeCategoryKind category;
  final String? customCategoryId;
  final FinanceSubject subject;
  final String? payer;
  final String? balanceId;
  final double amount;
  final IncomePeriodicity periodicity;
  final int? customIntervalMonths;
  final DateTime date;
  final bool useHistory;
  const _RelationshipDraft(
    this.label,
    this.category,
    this.customCategoryId,
    this.subject,
    this.payer,
    this.balanceId,
    this.amount,
    this.periodicity,
    this.customIntervalMonths,
    this.date,
    this.useHistory,
  );
}

class _RelationshipDialog extends StatefulWidget {
  final FinanceStore financeStore;
  final IncomeRelationship? initial;
  const _RelationshipDialog({required this.financeStore, this.initial});
  @override
  State<_RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends State<_RelationshipDialog> {
  late final TextEditingController label;
  late final TextEditingController payer;
  late final TextEditingController amount;
  late IncomeCategoryKind category;
  String? customCategoryId;
  late FinanceSubject subject;
  String? balanceId;
  late IncomePeriodicity periodicity;
  int customMonths = 2;
  late DateTime date;
  late bool useHistory;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    label = TextEditingController(text: initial?.label);
    payer = TextEditingController(text: initial?.payer);
    amount = TextEditingController(
      text: initial == null
          ? null
          : initial.expectedOrdinaryAmount.toStringAsFixed(2),
    );
    category = initial?.category ?? IncomeCategoryKind.salary;
    customCategoryId = initial?.customCategoryId;
    subject = initial?.subject ?? FinanceSubject.shared;
    balanceId = initial?.destinationBalanceId;
    periodicity = initial?.periodicity ?? IncomePeriodicity.monthly;
    customMonths = initial?.customIntervalMonths ?? 2;
    date = initial?.firstExpectedDate ?? DateTime.now();
    useHistory = initial?.historyBasedForecastEnabled ?? true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Nuova entrata' : 'Correggi entrata'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            DropdownButtonFormField<IncomeCategoryKind>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: IncomeCategoryKind.values
                  .where(
                    (item) =>
                        item != IncomeCategoryKind.custom ||
                        widget
                            .financeStore
                            .incomeAggregate
                            .customCategories
                            .isNotEmpty,
                  )
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_categoryLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => category = value!),
            ),
            if (category == IncomeCategoryKind.custom)
              DropdownButtonFormField<String>(
                initialValue: customCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoria personalizzata',
                ),
                items: widget.financeStore.incomeAggregate.customCategories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => customCategoryId = value),
              ),
            DropdownButtonFormField<FinanceSubject>(
              initialValue: subject,
              decoration: const InputDecoration(labelText: 'Persona'),
              items: FinanceSubject.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_subjectLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => subject = value!),
            ),
            TextField(
              controller: payer,
              decoration: const InputDecoration(
                labelText: 'Da chi (facoltativo)',
              ),
            ),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Importo previsto'),
            ),
            DropdownButtonFormField<String?>(
              initialValue: balanceId,
              decoration: const InputDecoration(
                labelText: 'Conto di accredito',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Non ancora noto'),
                ),
                ...widget.financeStore.balances
                    .where((item) => item.active)
                    .map(
                      (item) => DropdownMenuItem<String?>(
                        value: item.balanceId,
                        child: Text(item.name),
                      ),
                    ),
              ],
              onChanged: (value) => setState(() => balanceId = value),
            ),
            DropdownButtonFormField<IncomePeriodicity>(
              initialValue: periodicity,
              decoration: const InputDecoration(labelText: 'Periodicità'),
              items: IncomePeriodicity.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_periodicityLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => periodicity = value!),
            ),
            if (periodicity == IncomePeriodicity.customMonths)
              DropdownButtonFormField<int>(
                initialValue: customMonths,
                decoration: const InputDecoration(
                  labelText: 'Ogni quanti mesi',
                ),
                items: List.generate(11, (index) => index + 2)
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value mesi'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => customMonths = value!),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prima data prevista'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usa lo storico dello stesso periodo'),
              subtitle: const Text(
                'Solo le componenti ordinarie alimentano la stima.',
              ),
              value: useHistory,
              onChanged: (value) => setState(() => useHistory = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () {
          final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
          if (label.text.trim().isEmpty ||
              parsed == null ||
              parsed <= 0 ||
              (category == IncomeCategoryKind.custom &&
                  customCategoryId == null)) {
            return;
          }
          Navigator.pop(
            context,
            _RelationshipDraft(
              label.text.trim(),
              category,
              customCategoryId,
              subject,
              payer.text.trim().isEmpty ? null : payer.text.trim(),
              balanceId,
              parsed,
              periodicity,
              periodicity == IncomePeriodicity.customMonths
                  ? customMonths
                  : null,
              date,
              useHistory,
            ),
          );
        },
        child: const Text('Salva'),
      ),
    ],
  );
}

class _CreditPart {
  IncomeComponentKind kind;
  double amount;
  _CreditPart(this.kind, this.amount);
}

class _CreditDraft {
  final String? relationshipId;
  final String? occurrenceId;
  final DateTime date;
  final FinanceSubject subject;
  final String? payer;
  final String balanceId;
  final bool historical;
  final List<_CreditPart> parts;
  double get total => parts.fold(0, (sum, item) => sum + item.amount);
  const _CreditDraft(
    this.relationshipId,
    this.occurrenceId,
    this.date,
    this.subject,
    this.payer,
    this.balanceId,
    this.historical,
    this.parts,
  );
}

class _CreditDialog extends StatefulWidget {
  final FinanceStore financeStore;
  final String? initialRelationshipId;
  final String? initialOccurrenceId;
  final double? initialAmount;
  final DateTime? initialDate;
  final FinanceSubject? initialSubject;
  final String? initialBalanceId;
  final String? initialPayer;
  final bool? fixedHistorical;
  final List<_CreditPart>? initialParts;
  const _CreditDialog({
    required this.financeStore,
    this.initialRelationshipId,
    this.initialOccurrenceId,
    this.initialAmount,
    this.initialDate,
    this.initialSubject,
    this.initialBalanceId,
    this.initialPayer,
    this.fixedHistorical,
    this.initialParts,
  });
  @override
  State<_CreditDialog> createState() => _CreditDialogState();
}

class _CreditDialogState extends State<_CreditDialog> {
  late String? relationshipId = widget.initialRelationshipId;
  late String? occurrenceId = widget.initialOccurrenceId;
  late DateTime date = widget.initialDate ?? DateTime.now();
  late FinanceSubject subject = widget.initialSubject ?? FinanceSubject.shared;
  late String? balanceId = widget.initialBalanceId;
  late bool historical = widget.fixedHistorical ?? false;
  late final TextEditingController payer = TextEditingController(
    text: widget.initialPayer,
  );
  late List<_CreditPart> parts =
      widget.initialParts
          ?.map((item) => _CreditPart(item.kind, item.amount))
          .toList() ??
      [_CreditPart(IncomeComponentKind.ordinary, widget.initialAmount ?? 0)];

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Entrata ricevuta'),
    content: SizedBox(
      width: 540,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: relationshipId,
              decoration: const InputDecoration(
                labelText: 'Rapporto (facoltativo)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Entrata autonoma'),
                ),
                ...widget.financeStore.incomeAggregate.relationships.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.relationshipId,
                    child: Text(item.label),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                relationshipId = value;
                occurrenceId = null;
              }),
            ),
            if (relationshipId != null)
              DropdownButtonFormField<String?>(
                initialValue: occurrenceId,
                decoration: const InputDecoration(
                  labelText: 'Periodo previsto (facoltativo)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nessun periodo'),
                  ),
                  ...widget.financeStore.incomeAggregate.occurrences
                      .where((item) => item.relationshipId == relationshipId)
                      .map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.occurrenceId,
                          child: Text(
                            DateFormat(
                              'MMMM yyyy',
                              'it_IT',
                            ).format(item.expectedDate),
                          ),
                        ),
                      ),
                ],
                onChanged: (value) => setState(() => occurrenceId = value),
              ),
            DropdownButtonFormField<FinanceSubject>(
              initialValue: subject,
              decoration: const InputDecoration(labelText: 'Persona'),
              items: FinanceSubject.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_subjectLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => subject = value!),
            ),
            TextField(
              controller: payer,
              decoration: const InputDecoration(
                labelText: 'Da chi (facoltativo)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: balanceId,
              decoration: const InputDecoration(labelText: 'Sul conto'),
              items: widget.financeStore.balances
                  .where((item) => item.active)
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.balanceId,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => balanceId = value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data accredito'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Già compreso nel saldo attuale'),
              subtitle: const Text(
                'Registra lo storico senza aumentare il saldo.',
              ),
              value: historical,
              onChanged: widget.fixedHistorical != null
                  ? null
                  : (value) => setState(() => historical = value),
            ),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Componenti dell’accredito',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ...parts.indexed.map(
              (entry) => Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<IncomeComponentKind>(
                      initialValue: entry.$2.kind,
                      items: IncomeComponentKind.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_componentLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => entry.$2.kind = value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      initialValue: entry.$2.amount == 0
                          ? ''
                          : entry.$2.amount.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Importo'),
                      onChanged: (value) => entry.$2.amount =
                          double.tryParse(value.replaceAll(',', '.')) ?? 0,
                    ),
                  ),
                  IconButton(
                    onPressed: parts.length == 1
                        ? null
                        : () => setState(() => parts.removeAt(entry.$1)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => parts.add(_CreditPart(IncomeComponentKind.other, 0)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi componente'),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () {
          if (balanceId == null || parts.any((item) => item.amount <= 0)) {
            return;
          }
          Navigator.pop(
            context,
            _CreditDraft(
              relationshipId,
              occurrenceId,
              date,
              subject,
              payer.text.trim().isEmpty ? null : payer.text.trim(),
              balanceId!,
              historical,
              parts,
            ),
          );
        },
        child: const Text('Registra'),
      ),
    ],
  );
}

String _subjectLabel(FinanceSubject value) => switch (value) {
  FinanceSubject.matteo => 'Matteo',
  FinanceSubject.chiara => 'Chiara',
  FinanceSubject.alice => 'Alice',
  FinanceSubject.shared => 'Famiglia',
};
String _periodicityLabel(IncomePeriodicity value) => switch (value) {
  IncomePeriodicity.oneTime => 'Una tantum',
  IncomePeriodicity.monthly => 'Mensile',
  IncomePeriodicity.yearly => 'Annuale',
  IncomePeriodicity.customMonths => 'Periodicità personalizzata',
};
String _knowledgeLabel(IncomeKnowledge value) => switch (value) {
  IncomeKnowledge.known => 'Noto',
  IncomeKnowledge.predicted => 'Previsto',
  IncomeKnowledge.estimated => 'Stimato dallo storico',
  IncomeKnowledge.incomplete => 'Informazione incompleta',
};
String _componentLabel(IncomeComponentKind value) => switch (value) {
  IncomeComponentKind.ordinary => 'Importo ordinario',
  IncomeComponentKind.taxRefund730 => 'Rimborso 730',
  IncomeComponentKind.productionBonus => 'Premio di produzione',
  IncomeComponentKind.thirteenth => 'Tredicesima',
  IncomeComponentKind.fourteenth => 'Quattordicesima',
  IncomeComponentKind.other => 'Altra componente',
};
String _categoryLabel(IncomeCategoryKind value) => switch (value) {
  IncomeCategoryKind.salary => 'Stipendio',
  IncomeCategoryKind.professionalWork => 'Lavoro autonomo / professionale',
  IncomeCategoryKind.occasionalWork =>
    'Secondo lavoro / prestazione occasionale',
  IncomeCategoryKind.pension => 'Pensione',
  IncomeCategoryKind.singleAllowance => 'Assegno unico',
  IncomeCategoryKind.otherBenefit => 'Altra prestazione / indennità',
  IncomeCategoryKind.rent => 'Affitto / locazione',
  IncomeCategoryKind.taxRefund730 => 'Rimborso 730',
  IncomeCategoryKind.otherTaxRefund => 'Altro rimborso fiscale',
  IncomeCategoryKind.genericRefund => 'Rimborso generico',
  IncomeCategoryKind.financialIncome => 'Interessi / dividendi / proventi',
  IncomeCategoryKind.saleGain => 'Vendita / plusvalenza',
  IncomeCategoryKind.gift => 'Regalo / donazione',
  IncomeCategoryKind.moneyReturn => 'Restituzione di denaro',
  IncomeCategoryKind.other => 'Altra entrata',
  IncomeCategoryKind.custom => 'Categoria personalizzata',
};
