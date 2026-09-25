import 'package:flutter/material.dart';

import '../logic/composite_creation_intent_store.dart';
import '../logic/telefonia/add_sim_creation_coordinator.dart';
import '../models/composite_creation_intent.dart';
import '../models/continuing_service_relationship.dart';
import '../models/expense_relationship.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/finance_balance.dart';
import '../models/finance_category_template.dart';
import '../models/finance_person.dart';
import '../models/finance_recurring_item.dart';
import '../models/sim_service_details.dart';
import '../stores/continuing_service_relationship_store.dart';
import '../stores/finance_store.dart';
import '../stores/sim_service_details_store.dart';

class TelefoniaScreen extends StatefulWidget {
  final ContinuingServiceRelationshipStore relationshipStore;
  final SimServiceDetailsStore simDetailsStore;
  final CompositeCreationIntentStore intentStore;
  final FinanceStore financeStore;
  final Future<void>? financeReady;

  const TelefoniaScreen({
    super.key,
    required this.relationshipStore,
    required this.simDetailsStore,
    required this.intentStore,
    required this.financeStore,
    this.financeReady,
  });

  @override
  State<TelefoniaScreen> createState() => _TelefoniaScreenState();
}

class _TelefoniaScreenState extends State<TelefoniaScreen> {
  bool _loading = true;
  String? _loadError;

  AddSimCreationCoordinator get _coordinator => AddSimCreationCoordinator(
    intentStore: widget.intentStore,
    relationshipStore: widget.relationshipStore,
    simDetailsStore: widget.simDetailsStore,
    financeStore: widget.financeStore,
  );

  @override
  void initState() {
    super.initState();
    widget.relationshipStore.addListener(_refresh);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final financeReady = widget.financeReady;
      if (financeReady != null) await financeReady;
      await widget.relationshipStore.load();
      await widget.simDetailsStore.load();
      await widget.intentStore.load();
      final outcomes = await _coordinator.recoverPending();
      if (!mounted) return;
      final conflicts = outcomes
          .where((outcome) => outcome == AddSimCreationOutcome.conflict)
          .length;
      setState(() => _loading = false);
      if (conflicts > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflicts == 1
                  ? 'Una creazione SIM richiede verifica: dati in conflitto.'
                  : '$conflicts creazioni SIM richiedono verifica: dati in conflitto.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Impossibile completare il recupero: $error';
        });
      }
    }
  }

  @override
  void dispose() {
    widget.relationshipStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSimPage(
          coordinator: _coordinator,
          financeStore: widget.financeStore,
        ),
      ),
    );
    if (created == true) {
      await widget.relationshipStore.load();
      await widget.simDetailsStore.load();
    }
  }

  Future<void> _edit(ContinuingServiceRelationship item) async {
    final result = await Navigator.of(context)
        .push<ContinuingServiceRelationship>(
          MaterialPageRoute(
            builder: (_) => TelefoniaEditorPage(initial: item),
          ),
        );
    if (result != null) await widget.relationshipStore.update(result);
  }

  String _personName(String? personId) {
    if (personId == null) return 'Persona non associata';
    for (final person in widget.financeStore.people) {
      if (person.id == personId) return person.name;
    }
    return 'Persona non disponibile';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.relationshipStore.items;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        title: const Text('Telefonia'),
        backgroundColor: Colors.black.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: !_loading && items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi SIM'),
            )
          : null,
      body: _FrodoBackground(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _loadError != null
            ? _ErrorState(message: _loadError!, retry: _initialize)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: items.isEmpty
                      ? _EmptyState(onAdd: _add)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                          children: [
                            const _PageIntroduction(
                              icon: Icons.phone_android_rounded,
                              title: 'Le tue SIM',
                              subtitle:
                                  'Rapporti telefonici, offerte e credito in un unico posto.',
                            ),
                            const SizedBox(height: 18),
                            ...items.map((item) {
                              final details = widget.simDetailsStore
                                  .findByRelationshipId(item.relationshipId);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SimCard(
                                  item: item,
                                  details: details,
                                  personName: _personName(item.personId),
                                  onEdit: () => _edit(item),
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ),
      ),
    );
  }
}

class _SimCard extends StatelessWidget {
  final ContinuingServiceRelationship item;
  final SimServiceDetails? details;
  final String personName;
  final VoidCallback onEdit;

  const _SimCard({
    required this.item,
    required this.details,
    required this.personName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => _GlassSurface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF81C784).withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.sim_card_rounded,
            color: Color(0xFF81C784),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _StatusPill(active: item.active),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.provider,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _MetaItem(icon: Icons.person_rounded, label: personName),
                  if (details != null)
                    _MetaItem(
                      icon: Icons.phone_rounded,
                      label: details!.maskedPhoneNumber,
                    ),
                  if (details != null)
                    _MetaItem(
                      icon: Icons.local_offer_rounded,
                      label: details!.offerName,
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Modifica',
          color: Colors.white,
          icon: const Icon(Icons.edit_rounded),
          onPressed: onEdit,
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: (active ? const Color(0xFF81C784) : Colors.white).withOpacity(0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: (active ? const Color(0xFF81C784) : Colors.white).withOpacity(
          0.34,
        ),
      ),
    ),
    child: Text(
      active ? 'Attiva' : 'Disattivata',
      style: TextStyle(
        color: active ? const Color(0xFFA5D6A7) : Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.white60),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _PageIntroduction(
        icon: Icons.phone_android_rounded,
        title: 'Le tue SIM',
        subtitle: 'Rapporti telefonici, offerte e credito in un unico posto.',
      ),
      const SizedBox(height: 18),
      _GlassSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sim_card_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Nessuna SIM configurata',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aggiungi la prima SIM e il relativo ciclo economico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Aggiungi SIM'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorState({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _GlassSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white70),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: retry, child: const Text('Riprova')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FrodoBackground extends StatelessWidget {
  final Widget child;
  const _FrodoBackground({required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
      Container(color: Colors.black.withOpacity(0.28)),
      SafeArea(child: child),
    ],
  );
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withOpacity(0.20)),
    ),
    child: child,
  );
}

class _PageIntroduction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageIntroduction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => _GlassSurface(
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF81C784), size: 34),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    ),
  );
}

class AddSimPage extends StatefulWidget {
  final AddSimCreationCoordinator coordinator;
  final FinanceStore financeStore;

  const AddSimPage({super.key, required this.coordinator, required this.financeStore});

  @override
  State<AddSimPage> createState() => _AddSimPageState();
}

class _AddSimPageState extends State<AddSimPage> {
  final _formKey = GlobalKey<FormState>();
  final provider = TextEditingController();
  final label = TextEditingController();
  final phone = TextEditingController();
  final offer = TextEditingController();
  final renewalAmount = TextEditingController();
  final currentCredit = TextEditingController();
  DateTime? activationDate;
  DateTime? simExpirationDate;
  DateTime? nextRenewalDate;
  String? personId;
  FinanceRecurringType periodicity = FinanceRecurringType.monthly;
  bool active = true;
  bool renewalFromSimCredit = true;
  bool _submitting = false;
  CompositeCreationIntent? _intent;

  List<FinancePerson> get _supportedPeople => widget.financeStore.people
      .where((person) => widget.financeStore.subjectForPersonIdIfSupported(person.id) != null)
      .toList(growable: false);

  @override
  void dispose() {
    provider.dispose();
    label.dispose();
    phone.dispose();
    offer.dispose();
    renewalAmount.dispose();
    currentCredit.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  double? _number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));
  String? _requiredText(String? value) => value == null || value.trim().isEmpty ? 'Campo obbligatorio' : null;
  String? _positiveAmount(String? value) {
    final parsed = _number(value ?? '');
    return parsed == null || parsed <= 0 ? 'Inserisci un importo valido' : null;
  }

  String? _nonNegativeAmount(String? value) {
    final parsed = _number(value ?? '');
    return parsed == null || parsed < 0 ? 'Inserisci un importo valido' : null;
  }

  CompositeCreationIntent _buildIntent() {
    final selectedPersonId = personId!;
    final subject = widget.financeStore.subjectForPersonIdIfSupported(selectedPersonId)!;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final operationId = 'add_sim_$stamp';
    final serviceId = 'service_sim_$stamp';
    final balanceId = 'balance_sim_$stamp';
    final expenseId = 'expense_sim_$stamp';
    final payment = ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.card,
      expectedBalanceId: balanceId,
    );
    final service = ContinuingServiceRelationship(
      relationshipId: serviceId,
      provider: provider.text,
      label: label.text,
      personId: selectedPersonId,
      active: active,
    );
    final credit = _number(currentCredit.text)!;
    final renewal = _number(renewalAmount.text)!;
    final balance = FinanceBalance(
      personId: selectedPersonId,
      balanceId: balanceId,
      name: '${label.text.trim()} · credito SIM',
      initialAmount: credit,
      currentAmount: credit,
      updatedAt: DateTime.now(),
      balanceType: FinanceBalanceType.prepaidCard,
      operational: true,
      active: active,
      reservedAmount: 0,
      warningThreshold: renewal,
      persistentStressDays: 0,
      recoveryDays: 0,
    );
    final expense = ExpenseRelationship(
      relationshipId: expenseId,
      service: offer.text,
      provider: provider.text,
      subject: subject,
      status: active ? ExpenseRelationshipStatus.active : ExpenseRelationshipStatus.terminated,
      periodicity: ExpenseRelationshipPeriodicity(type: periodicity),
      paymentConfiguration: payment,
      paymentExecutionMode: PaymentExecutionMode.automatic,
    );
    final occurrence = ExpectedExpenseOccurrence(
      occurrenceId: 'occurrence_sim_$stamp',
      relationshipId: expenseId,
      cycleSequence: 1,
      cycleAnchor: nextRenewalDate!,
      status: ExpectedExpenseOccurrenceStatus.pending,
      expectedDueDate: nextRenewalDate,
      expectedDueDateSource: ExpectedExpenseDateSource.explicit,
      expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
      expectedAmount: renewal,
      estimationMethod: ExpenseEstimationMethod.manualEstimate,
      confidence: ExpenseEstimateConfidence.high,
      provisional: false,
      expectedPaymentConfiguration: payment,
      paymentExecutionMode: PaymentExecutionMode.automatic,
      expectedSubject: subject,
    );
    final details = SimServiceDetails(
      relationshipId: serviceId,
      phoneNumber: phone.text,
      offerName: offer.text,
      activationDate: activationDate!,
      simExpirationDate: simExpirationDate!,
      creditBalanceId: balanceId,
      expenseRelationshipId: expenseId,
    );
    return widget.coordinator.buildIntent(
      operationId: operationId,
      serviceRelationship: service,
      simDetails: details,
      expenseRelationship: expense,
      firstOccurrence: occurrence,
      creditBalance: balance,
    );
  }

  Future<void> _save() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Il flusso integrato può creare soltanto una SIM inizialmente attiva.',
          ),
        ),
      );
      return;
    }
    final complete = personId != null &&
        activationDate != null &&
        simExpirationDate != null &&
        nextRenewalDate != null &&
        renewalFromSimCredit;
    if (!valid || !complete) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa tutti i dati obbligatori.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      _intent ??= _buildIntent();
      final outcome = await widget.coordinator.start(_intent!);
      if (!mounted) return;
      if (outcome == AddSimCreationOutcome.conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creazione non completata: dati in conflitto. Nessun dato esistente è stato sovrascritto.')),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Creazione interrotta. Puoi riprovare senza duplicare i dati: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _dateLabel(DateTime? value) => value == null
      ? 'Seleziona'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F1D12),
    appBar: AppBar(
      title: const Text('Aggiungi SIM'),
      backgroundColor: Colors.black.withOpacity(0.08),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: _FrodoBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Theme(
            data: _telefoniaFormTheme(context),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  const _PageIntroduction(
                    icon: Icons.add_card_rounded,
                    title: 'Nuova SIM',
                    subtitle:
                        'Inserisci i dati della linea, del rinnovo e del credito.',
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    icon: Icons.sim_card_rounded,
                    title: 'La SIM',
                    children: [
                      TextFormField(
                        controller: provider,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Provider'),
                        validator: _requiredText,
                      ),
                      TextFormField(
                        controller: label,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Etichetta SIM',
                        ),
                        validator: _requiredText,
                      ),
                      DropdownButtonFormField<String>(
                        value: personId,
                        dropdownColor: const Color(0xFF1F3524),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Persona'),
                        items: _supportedPeople
                            .map(
                              (person) => DropdownMenuItem(
                                value: person.id,
                                child: Text(person.name),
                              ),
                            )
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => personId = value),
                        validator: (value) =>
                            value == null ? 'Seleziona una persona' : null,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'SIM attiva',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: active,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => active = value),
                      ),
                      TextFormField(
                        controller: phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Numero'),
                        keyboardType: TextInputType.phone,
                        validator: _requiredText,
                      ),
                      TextFormField(
                        controller: offer,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Offerta'),
                        validator: _requiredText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    icon: Icons.calendar_month_rounded,
                    title: 'Date',
                    children: [
                      _DateTile(
                        label: 'Data di attivazione',
                        value: _dateLabel(activationDate),
                        error: activationDate == null,
                        onTap: () => _pickDate(
                          activationDate,
                          (value) => activationDate = value,
                        ),
                      ),
                      _DateTile(
                        label: 'Scadenza SIM',
                        value: _dateLabel(simExpirationDate),
                        error: simExpirationDate == null,
                        onTap: () => _pickDate(
                          simExpirationDate,
                          (value) => simExpirationDate = value,
                        ),
                      ),
                      _DateTile(
                        label: 'Prossimo rinnovo',
                        value: _dateLabel(nextRenewalDate),
                        error: nextRenewalDate == null,
                        onTap: () => _pickDate(
                          nextRenewalDate,
                          (value) => nextRenewalDate = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormSection(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Rinnovo e credito',
                    children: [
                      TextFormField(
                        controller: renewalAmount,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Importo rinnovo',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _positiveAmount,
                      ),
                      DropdownButtonFormField<FinanceRecurringType>(
                        value: periodicity,
                        dropdownColor: const Color(0xFF1F3524),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Periodicità',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FinanceRecurringType.monthly,
                            child: Text('Mensile'),
                          ),
                          DropdownMenuItem(
                            value: FinanceRecurringType.yearly,
                            child: Text('Annuale'),
                          ),
                        ],
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                  setState(() => periodicity = value!),
                      ),
                      TextFormField(
                        controller: currentCredit,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Credito SIM attuale',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _nonNegativeAmount,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Il rinnovo viene scalato dal credito SIM',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Il credito SIM finanzia il rinnovo previsto.',
                          style: TextStyle(color: Colors.white60),
                        ),
                        value: renewalFromSimCredit,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(
                                  () => renewalFromSimCredit = value ?? false,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _save,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Crea SIM'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

ThemeData _telefoniaFormTheme(BuildContext context) {
  final base = Theme.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
  );
  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: Color(0xFFA5D6A7)),
      enabledBorder: border,
      border: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF81C784), width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
      ),
    ),
  );
}

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => _GlassSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF81C784), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children.expand(
          (child) => [child, const SizedBox(height: 12)],
        ),
      ],
    ),
  );
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final bool error;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.value, required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.22)),
    ),
    child: ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(
        value,
        style: TextStyle(
          color: error ? const Color(0xFFEF9A9A) : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
      onTap: onTap,
    ),
  );
}

/// Safe, shallow editor. Economic links and SIM details are deliberately not
/// editable here because changing them independently would split the domains.
class TelefoniaEditorPage extends StatefulWidget {
  final ContinuingServiceRelationship initial;
  const TelefoniaEditorPage({super.key, required this.initial});

  @override
  State<TelefoniaEditorPage> createState() => _TelefoniaEditorPageState();
}

class _TelefoniaEditorPageState extends State<TelefoniaEditorPage> {
  late final TextEditingController label;
  late bool active;

  @override
  void initState() {
    super.initState();
    label = TextEditingController(text: widget.initial.label);
    active = widget.initial.active;
  }

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  void _save() {
    if (label.text.trim().isEmpty) return;
    Navigator.pop(context, widget.initial.copyWith(label: label.text, active: active));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F1D12),
    appBar: AppBar(
      title: const Text('Modifica SIM'),
      backgroundColor: Colors.black.withOpacity(0.08),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: _FrodoBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Theme(
            data: _telefoniaFormTheme(context),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dati del rapporto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ReadOnlyValue(
                        label: 'Provider',
                        value: widget.initial.provider,
                      ),
                      const SizedBox(height: 12),
                      _ReadOnlyValue(
                        label: 'Persona associata',
                        value: widget.initial.personId ?? 'Non associata',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: label,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Etichetta SIM',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'SIM attiva',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: active,
                        onChanged: (value) => setState(() => active = value),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text('Salva'),
                        ),
                      ),
                    ],
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

class _ReadOnlyValue extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
