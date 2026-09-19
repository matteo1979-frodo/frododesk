import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';
import '../models/real_expense.dart';
import '../models/expense_replacement_intent.dart';
import '../models/finance_recurring_item.dart';
import '../models/frodo_observation.dart';
import '../stores/expense_category_store.dart';
import '../stores/cash_wallet_store.dart';
import '../logic/spese/spese_coordinator.dart';
import '../logic/spese/builders/spese_command_builder.dart';
import '../logic/spese/spese_mutation_coordinator.dart';
import '../logic/spese/expense_replacement_coordinator.dart';
import '../logic/spese/expense_replacement_persistence.dart';
import '../logic/finance/composite_economic_operation_coordinator.dart';
import '../logic/finance/expected_expense_update_coordinator.dart';
import '../models/expected_expense_occurrence.dart';
import '../models/expense_relationship.dart';
import '../models/composite_economic_operation.dart';
import '../models/economic_operation_metadata.dart';
import '../models/economic_event.dart';
import '../models/spese_command.dart';
import '../models/spese_snapshot.dart';
import '../utils/euro_formatter.dart';
import 'expected_expense_from_real_expense_page.dart';
import 'expected_expense_completion_page.dart';

const _speseCommandBuilder = SpeseCommandBuilder();

String _expensePresentationTitle(RealExpense expense) {
  final metadata = expense.operationMetadata;
  if (metadata == null || metadata.role == OperationRole.main) {
    return expense.description;
  }
  return switch (metadata.accessoryCostType) {
    AccessoryCostType.bankCommission => 'Commissione bancaria',
    AccessoryCostType.postalAcceptanceCharge => 'Costo accettazione postale',
    null => expense.description,
  };
}

SpeseCommand? _prepareSpeseCommand(
  BuildContext context,
  SpeseCommand Function() build,
) {
  try {
    return build();
  } on SpeseCommandValidationException catch (error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  }
}

String _generateExpenseReplacementId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return 'expense-replacement-${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
}

bool _sameReplacementPayload(
  ExpenseReplacementPayload left,
  ExpenseReplacementPayload right,
) =>
    left.balanceId == right.balanceId &&
    left.balanceName == right.balanceName &&
    left.amount == right.amount &&
    left.description == right.description &&
    left.category == right.category &&
    left.occurredAt == right.occurredAt &&
    left.personId == right.personId;

Future<ExpenseReplacementResult?> _executeSpeseCreationOrEdit({
  required SpeseMutationCoordinator mutationCoordinator,
  required SpeseCommand command,
  required SpeseCommandRegistry registry,
  RealExpense? editingExpense,
  ExpenseReplacementPersistence? replacementPersistence,
  ExpenseReplacementCoordinator? replacementCoordinator,
}) async {
  if (editingExpense == null) {
    await mutationCoordinator.execute(command);
    return null;
  }

  if (command.kind != SpeseCommandKind.expense ||
      replacementPersistence == null ||
      replacementCoordinator == null) {
    final removalCommand = _speseCommandBuilder.buildExistingMovement(
      expense: editingExpense,
      action: SpeseCommandAction.removeForEdit,
      preparedAt: command.preparedAt,
      registry: registry,
    );
    await mutationCoordinator.execute(removalCommand);
    await mutationCoordinator.execute(command);
    return null;
  }

  final payload = ExpenseReplacementPayload(
    balanceId: command.origin.referenceId!,
    balanceName: command.origin.label,
    amount: command.amount,
    description: command.description,
    category: command.category,
    preparedAt: command.preparedAt,
    occurredAt: command.occurredAt,
    personId: command.personId,
  );
  final pending = await replacementPersistence.findByOriginalExpenseId(
    editingExpense.id,
  );
  late final ExpenseReplacementIntent intent;
  if (pending != null) {
    if (!_sameReplacementPayload(pending.replacementPayload, payload)) {
      return ExpenseReplacementResult.conflict(
        ExpenseReplacementReason.intentConflict,
        const ['La spesa ha già una modifica pendente con dati differenti.'],
      );
    }
    intent = pending;
  } else {
    intent = ExpenseReplacementIntent(
      replacementId: _generateExpenseReplacementId(),
      originalExpense: editingExpense,
      replacementPayload: payload,
    );
    await replacementPersistence.add(intent);
  }

  return replacementCoordinator.complete(intent);
}

class SpesePage extends StatefulWidget {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final CompositeEconomicOperationCoordinator? compositeCoordinator;
  final ExpenseReplacementPersistence? expenseReplacementPersistence;
  final ExpenseReplacementCoordinator? expenseReplacementCoordinator;

  const SpesePage({
    super.key,
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    this.compositeCoordinator,
    this.expenseReplacementPersistence,
    this.expenseReplacementCoordinator,
  });

  @override
  State<SpesePage> createState() => _SpesePageState();
}

class _SpesePageState extends State<SpesePage> {
  final ExpenseCategoryStore categoryStore = ExpenseCategoryStore();
  late final SpeseCoordinator coordinator;
  late final SpeseMutationCoordinator mutationCoordinator;
  late final CompositeEconomicOperationCoordinator compositeCoordinator;
  late final ExpenseReplacementPersistence expenseReplacementPersistence;
  late final ExpenseReplacementCoordinator expenseReplacementCoordinator;
  late SpeseSnapshot snapshot;
  bool _replacementRecoveryStarted = false;

  @override
  void initState() {
    super.initState();
    coordinator = SpeseCoordinator(
      financeStore: widget.financeStore,
      expenseStore: widget.expenseStore,
      categoryStore: categoryStore,
      cashWalletStore: widget.cashWalletStore,
    );
    mutationCoordinator = SpeseMutationCoordinator(
      financeStore: widget.financeStore,
      expenseStore: widget.expenseStore,
      cashWalletStore: widget.cashWalletStore,
    );
    compositeCoordinator =
        widget.compositeCoordinator ??
        CompositeEconomicOperationCoordinator(
          financeStore: widget.financeStore,
          expenseStore: widget.expenseStore,
        );
    expenseReplacementPersistence =
        widget.expenseReplacementPersistence ?? ExpenseReplacementPersistence();
    expenseReplacementCoordinator =
        widget.expenseReplacementCoordinator ??
        ExpenseReplacementCoordinator(
          financeStore: widget.financeStore,
          expenseStore: widget.expenseStore,
          persistence: expenseReplacementPersistence,
        );
    snapshot = coordinator.build(observedAt: DateTime.now());
    _initializePage();
  }

  Future<void> _initializePage() async {
    await categoryStore.load();
    await _recoverPendingExpenseReplacements();
    final loadedSnapshot = coordinator.build(observedAt: DateTime.now());
    if (mounted) {
      setState(() => snapshot = loadedSnapshot);
    }
  }

  Future<void> _recoverPendingExpenseReplacements() async {
    if (_replacementRecoveryStarted) return;
    _replacementRecoveryStarted = true;

    late final List<ExpenseReplacementIntent> intents;
    try {
      intents = await expenseReplacementPersistence.load();
    } catch (error, stackTrace) {
      debugPrint('Expense replacement recovery load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    for (final intent in intents) {
      try {
        final result = await expenseReplacementCoordinator.complete(intent);
        if (result.status == ExpenseReplacementStatus.conflict ||
            result.status == ExpenseReplacementStatus.failed) {
          debugPrint(
            'Expense replacement recovery ${intent.replacementId} '
            '${result.status.name}: ${result.errors.join('; ')}',
          );
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Expense replacement recovery ${intent.replacementId} failed: '
          '$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _refreshSnapshot() async {
    final refreshedSnapshot = coordinator.build(observedAt: DateTime.now());
    if (mounted) {
      setState(() => snapshot = refreshedSnapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthExpenses = snapshot.currentMonthExpenses;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Spese"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.30)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  children: [
                    _SpeseHeroCard(
                      currentMonthTotal: snapshot.currentMonthTotal,
                    ),
                    const SizedBox(height: 16),
                    _SpeseMainGrid(
                      movementCount: snapshot.movementCount,
                      last7DaysTotal: snapshot.last7DaysTotal,
                      mainCategory: snapshot.mainCategory,
                      currentMonthTotal: snapshot.currentMonthTotal,
                      cashWalletTotal: snapshot.cashWalletTotal,
                    ),
                    const SizedBox(height: 16),
                    _SpeseMonthStatusCard(
                      observations: snapshot.monthObservations,
                      visibleObservations: snapshot.visibleMonthObservations,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Movimenti del mese corrente",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.monthTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (currentMonthExpenses.isEmpty)
                      const _EmptyMovementsCard(),
                    ...snapshot.recentExpenses.map(
                      (expense) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SpeseGlassCard(
                          child: Row(
                            children: [
                              _SpeseIconBox(
                                icon: expense.isIncome
                                    ? Icons.add_card_rounded
                                    : (expense.isCashWithdrawal
                                          ? Icons.account_balance_wallet_rounded
                                          : Icons.receipt_long_rounded),
                                color: expense.isIncome
                                    ? const Color(0xFF42A5F5)
                                    : (expense.isCashWithdrawal
                                          ? const Color(0xFF66BB6A)
                                          : const Color(0xFFFF7043)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _expensePresentationTitle(expense),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${expense.category} • ${expense.balanceName}",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              switch (expense.subject) {
                                                FinanceSubject.matteo =>
                                                  "👨 Matteo",
                                                FinanceSubject.chiara =>
                                                  "👩 Chiara",
                                                FinanceSubject.alice =>
                                                  "👧 Alice",
                                                FinanceSubject.shared =>
                                                  "👨‍👩‍👧 Condiviso",
                                              },
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatMovementDate(expense.date),
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                EuroFormatter.format(expense.amount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (currentMonthExpenses.isNotEmpty)
                      _MovementChoiceTile(
                        icon: Icons.history_rounded,
                        title: "Vedi storico mese",
                        subtitle:
                            "${currentMonthExpenses.length} movimenti registrati",
                        color: const Color(0xFFFFB74D),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _ExpenseMonthHistoryPage(
                                financeStore: widget.financeStore,
                                expenses: currentMonthExpenses,
                                monthTitle: snapshot.monthTitle,
                                snapshot: snapshot,
                                coordinator: coordinator,
                                mutationCoordinator: mutationCoordinator,
                                replacementPersistence:
                                    expenseReplacementPersistence,
                                replacementCoordinator:
                                    expenseReplacementCoordinator,
                              ),
                            ),
                          );

                          await _refreshSnapshot();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            backgroundColor: const Color(0xFF101820),
            builder: (context) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MovementChoiceTile(
                          icon: Icons.shopping_bag_rounded,
                          title: "Spesa reale",
                          subtitle:
                              "McDonald's, Sandra, benzina, ferramenta...",
                          color: const Color(0xFFFF7043),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _RealExpenseAccountPage(
                                  snapshot: snapshot,
                                  coordinator: coordinator,
                                  mutationCoordinator: mutationCoordinator,
                                ),
                              ),
                            );

                            await _refreshSnapshot();
                          },
                        ),
                        const SizedBox(height: 10),
                        _MovementChoiceTile(
                          icon: Icons.receipt_long_rounded,
                          title: "Bolletta con costi accessori",
                          subtitle:
                              "Importo principale, commissione e costo postale",
                          color: const Color(0xFFAB47BC),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _UtilityBillAccountPage(
                                  snapshot: snapshot,
                                  coordinator: coordinator,
                                  compositeCoordinator: compositeCoordinator,
                                ),
                              ),
                            );

                            await _refreshSnapshot();
                          },
                        ),
                        const SizedBox(height: 10),
                        _MovementChoiceTile(
                          icon: Icons.payments_rounded,
                          title: "Prelievo contanti",
                          subtitle: "Scala un conto e registra il prelievo",
                          color: const Color(0xFF66BB6A),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _CashWithdrawalAccountPage(
                                  snapshot: snapshot,
                                  mutationCoordinator: mutationCoordinator,
                                ),
                              ),
                            );

                            await _refreshSnapshot();
                          },
                        ),
                        const SizedBox(height: 10),
                        _MovementChoiceTile(
                          icon: Icons.add_card_rounded,
                          title: "Entrata extra",
                          subtitle:
                              "Rimborso, regalo, vendita, entrata occasionale",
                          color: const Color(0xFF42A5F5),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _ExtraIncomeAccountPage(
                                  snapshot: snapshot,
                                  mutationCoordinator: mutationCoordinator,
                                ),
                              ),
                            );

                            await _refreshSnapshot();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: const Color(0xFFFFB74D),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nuovo movimento"),
      ),
    );
  }
}

class _UtilityBillAccountPage extends StatelessWidget {
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final CompositeEconomicOperationCoordinator compositeCoordinator;

  const _UtilityBillAccountPage({
    required this.snapshot,
    required this.coordinator,
    required this.compositeCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('Nuova bolletta'),
        backgroundColor: Colors.black.withValues(alpha: 0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Da quale conto viene addebitata?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (snapshot.activeBalances.isEmpty)
                  const _SpeseGlassCard(
                    child: Text(
                      'Nessun conto attivo trovato.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...snapshot.activeBalances.map(
                    (balance) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MovementChoiceTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: balance.name,
                        subtitle:
                            'Saldo: ${EuroFormatter.format(balance.availableAmount)}',
                        color: const Color(0xFFAB47BC),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _UtilityBillFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                balancePersonId: balance.personId,
                                snapshot: snapshot,
                                coordinator: coordinator,
                                compositeCoordinator: compositeCoordinator,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityBillFormPage extends StatefulWidget {
  final String balanceId;
  final String balanceName;
  final double balanceAmount;
  final String balancePersonId;
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final CompositeEconomicOperationCoordinator compositeCoordinator;

  const _UtilityBillFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.balancePersonId,
    required this.snapshot,
    required this.coordinator,
    required this.compositeCoordinator,
  });

  @override
  State<_UtilityBillFormPage> createState() => _UtilityBillFormPageState();
}

class _UtilityBillFormPageState extends State<_UtilityBillFormPage> {
  final mainAmountController = TextEditingController();
  final bankCommissionController = TextEditingController();
  final postalAcceptanceController = TextEditingController();
  final descriptionController = TextEditingController();
  late final String operationIdentity;
  late List<String> categories;
  late FinanceSubject selectedSubject;
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    operationIdentity = 'utility_bill_${DateTime.now().microsecondsSinceEpoch}';
    categories = widget.snapshot.categories.toList();
    selectedSubject = FinanceSubject.values.firstWhere(
      (subject) => subject.name == widget.balancePersonId,
      orElse: () => FinanceSubject.shared,
    );
  }

  @override
  void dispose() {
    mainAmountController.dispose();
    bankCommissionController.dispose();
    postalAcceptanceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  double? _parseRequiredAmount(String value) {
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    return amount != null && amount.isFinite && amount > 0 ? amount : null;
  }

  double? _parseOptionalAmount(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 0;
    final amount = double.tryParse(normalized.replaceAll(',', '.'));
    return amount != null && amount.isFinite && amount >= 0 ? amount : null;
  }

  CompositeEconomicOperation? _buildOperation() {
    final mainAmount = _parseRequiredAmount(mainAmountController.text);
    final bankCommission = _parseOptionalAmount(bankCommissionController.text);
    final postalAcceptance = _parseOptionalAmount(
      postalAcceptanceController.text,
    );
    if (mainAmount == null ||
        bankCommission == null ||
        postalAcceptance == null) {
      return null;
    }
    final accessories = <CompositeEconomicAccessoryInput>[];
    if (bankCommission > 0) {
      accessories.add((
        economicFactId: 'economic_fact:$operationIdentity:bank_commission',
        amount: bankCommission,
        accessoryCostType: AccessoryCostType.bankCommission,
      ));
    }
    if (postalAcceptance > 0) {
      accessories.add((
        economicFactId: 'economic_fact:$operationIdentity:postal_acceptance',
        amount: postalAcceptance,
        accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
      ));
    }
    return CompositeEconomicOperation(
      operationId: operationIdentity,
      context: OperationContext.utilityBill,
      mainEconomicFactId: 'economic_fact:$operationIdentity:main',
      mainAmount: mainAmount,
      accessories: accessories,
    );
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    final operation = _buildOperation();
    if (operation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci importi validi.')),
      );
      return;
    }
    final description = descriptionController.text.trim();
    if (description.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci descrizione e categoria.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    late final CompositeEconomicOperationResult result;
    try {
      result = await widget.compositeCoordinator.record(
        CompositeEconomicOperationPosting(
          operation: operation,
          debitBalanceId: widget.balanceId,
          subject: selectedSubject,
          economicDate: selectedDate,
          description: description,
          category: selectedCategory!,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (!mounted) return;

    if (result.status == CompositeEconomicOperationStatus.completed ||
        result.status == CompositeEconomicOperationStatus.alreadyComplete) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == CompositeEconomicOperationStatus.completed
                ? 'Bolletta registrata.'
                : 'Bolletta già registrata.',
          ),
        ),
      );
      return;
    }

    final details = result.errors.isEmpty
        ? result.reason?.name ?? 'Errore sconosciuto'
        : result.errors.join('; ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bolletta non registrata: $details')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildOperation();
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('Importo bolletta'),
        backgroundColor: Colors.black.withValues(alpha: 0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  'Conto scelto: ${widget.balanceName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saldo attuale: ${EuroFormatter.format(widget.balanceAmount)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _SpeseGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: mainAmountController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Importo principale',
                          'Es. 59,63',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bankCommissionController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Commissione bancaria (facoltativa)',
                          'Es. 2,00',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: postalAcceptanceController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Costo accettazione postale (facoltativo)',
                          'Es. 1,00',
                        ),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Totale addebitato al conto: ${EuroFormatter.format(preview.totalAmount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: _decoration(
                          'Descrizione',
                          'Es. Bolletta energia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MovementDateSelector(
                        selectedDate: selectedDate,
                        onChanged: (value) =>
                            setState(() => selectedDate = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: _decoration(
                          'Categoria principale',
                          'Seleziona categoria...',
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          ...categories.map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: '__new_category__',
                            child: Text('➕ Nuova categoria'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value != '__new_category__') {
                            setState(() => selectedCategory = value);
                            return;
                          }
                          final controller = TextEditingController();
                          final newCategory = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Nuova categoria'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Nome categoria',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annulla'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    controller.text.trim(),
                                  ),
                                  child: const Text('Crea'),
                                ),
                              ],
                            ),
                          );
                          controller.dispose();
                          if (newCategory == null || newCategory.isEmpty) {
                            return;
                          }
                          final updated = await widget.coordinator.addCategory(
                            category: newCategory,
                            observedAt: DateTime.now(),
                          );
                          if (!mounted) return;
                          setState(() {
                            categories = updated.categories.toList();
                            selectedCategory = newCategory;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FinanceSubject>(
                        initialValue: selectedSubject,
                        decoration: _decoration('Di chi è', ''),
                        items: const [
                          DropdownMenuItem(
                            value: FinanceSubject.matteo,
                            child: Text('👨 Matteo'),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.chiara,
                            child: Text('👩 Chiara'),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.alice,
                            child: Text('👧 Alice'),
                          ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => selectedSubject = value);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : _submit,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            isSubmitting
                                ? 'Registrazione in corso...'
                                : 'Conferma bolletta',
                          ),
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
    );
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.86),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
  );
}

class _RealExpenseAccountPage extends StatelessWidget {
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final SpeseMutationCoordinator mutationCoordinator;

  const _RealExpenseAccountPage({
    required this.snapshot,
    required this.coordinator,
    required this.mutationCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = snapshot.activeBalances;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Nuova spesa reale"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  "Da quale conto esce?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (activeBalances.isEmpty)
                  const _SpeseGlassCard(
                    child: Text(
                      "Nessun conto attivo trovato.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ...activeBalances.map(
                    (balance) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MovementChoiceTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: balance.name,
                        subtitle:
                            "Saldo: ${EuroFormatter.format(balance.availableAmount)}",
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _RealExpenseFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                snapshot: snapshot,
                                coordinator: coordinator,
                                mutationCoordinator: mutationCoordinator,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RealExpenseFormPage extends StatefulWidget {
  final String balanceId;
  final String balanceName;
  final double balanceAmount;
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final SpeseMutationCoordinator mutationCoordinator;
  final ExpenseReplacementPersistence? replacementPersistence;
  final ExpenseReplacementCoordinator? replacementCoordinator;
  final RealExpense? editingExpense;

  const _RealExpenseFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.snapshot,
    required this.coordinator,
    required this.mutationCoordinator,
    this.replacementPersistence,
    this.replacementCoordinator,
    this.editingExpense,
  });

  @override
  State<_RealExpenseFormPage> createState() => _RealExpenseFormPageState();
}

class _RealExpenseFormPageState extends State<_RealExpenseFormPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedCategory;
  FinanceSubject selectedSubject = FinanceSubject.shared;
  late List<String> categories;
  late SpeseCommandRegistry commandRegistry;
  bool isSubmitting = false;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final editingExpense = widget.editingExpense;
    categories = widget.snapshot.categories.toList();
    commandRegistry = widget.snapshot.commandRegistry;
    selectedDate = editingExpense?.date ?? DateTime.now();

    if (editingExpense != null) {
      amountController.text = editingExpense.amount.toStringAsFixed(2);
      descriptionController.text = editingExpense.description;
      selectedCategory = editingExpense.category;
      selectedSubject = editingExpense.subject;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Importo spesa"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  "Conto scelto: ${widget.balanceName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Saldo attuale: ${EuroFormatter.format(widget.balanceAmount)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _SpeseGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quanto hai speso?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          label: "Importo",
                          hint: "Es. 30.00",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: _inputDecoration(
                          label: "Descrizione",
                          hint: "Es. McDonald's, Sandra, benzina...",
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MovementDateSelector(
                        selectedDate: selectedDate,
                        onChanged: (newDate) {
                          setState(() {
                            selectedDate = newDate;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: _inputDecoration(
                          label: "Categoria",
                          hint: "Seleziona categoria...",
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          ...categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }),
                          const DropdownMenuItem(
                            value: "__new_category__",
                            child: Text("➕ Nuova categoria"),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == "__new_category__") {
                            final controller = TextEditingController();

                            final newCategory = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Nuova categoria"),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      labelText: "Nome categoria",
                                      hintText: "Es. Giardinaggio",
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Annulla"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(controller.text.trim());
                                      },
                                      child: const Text("Crea"),
                                    ),
                                  ],
                                );
                              },
                            );

                            controller.dispose();

                            if (newCategory == null || newCategory.isEmpty) {
                              return;
                            }

                            final updatedSnapshot = await widget.coordinator
                                .addCategory(
                                  category: newCategory,
                                  observedAt: DateTime.now(),
                                );

                            if (!mounted) return;

                            setState(() {
                              categories = updatedSnapshot.categories.toList();
                              commandRegistry = updatedSnapshot.commandRegistry;
                              selectedCategory = newCategory;
                            });

                            return;
                          }

                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<FinanceSubject>(
                        initialValue: selectedSubject,
                        decoration: _inputDecoration(
                          label: "Di chi è",
                          hint: "",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FinanceSubject.matteo,
                            child: Text("👨 Matteo"),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.chiara,
                            child: Text("👩 Chiara"),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.alice,
                            child: Text("👧 Alice"),
                          ),
                          DropdownMenuItem(
                            value: FinanceSubject.shared,
                            child: Text("👨‍👩‍👧 Condiviso"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedSubject = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (isSubmitting) return;
                                  final preparedAt = DateTime.now();
                                  final command = _prepareSpeseCommand(
                                    context,
                                    () => _speseCommandBuilder.build(
                                      draft: SpeseCommandDraft(
                                        id: preparedAt.millisecondsSinceEpoch
                                            .toString(),
                                        kind: SpeseCommandKind.expense,
                                        preparedAt: preparedAt,
                                        occurredAt: selectedDate,
                                        origin: SpeseCommandEndpointDraft(
                                          kind: EconomicEndpointKind.account,
                                          referenceId: widget.balanceId,
                                        ),
                                        destination:
                                            const SpeseCommandEndpointDraft(
                                              kind:
                                                  EconomicEndpointKind.external,
                                              label: 'Spesa',
                                            ),
                                        amountInput: amountController.text,
                                        category: selectedCategory ?? '',
                                        personId: selectedSubject.name,
                                        description: descriptionController.text,
                                      ),
                                      registry: commandRegistry,
                                    ),
                                  );
                                  if (command == null) return;

                                  setState(() => isSubmitting = true);
                                  try {
                                    final result =
                                        await _executeSpeseCreationOrEdit(
                                          mutationCoordinator:
                                              widget.mutationCoordinator,
                                          command: command,
                                          registry: commandRegistry,
                                          editingExpense: widget.editingExpense,
                                          replacementPersistence:
                                              widget.replacementPersistence,
                                          replacementCoordinator:
                                              widget.replacementCoordinator,
                                        );

                                    if (result != null &&
                                        result.status !=
                                            ExpenseReplacementStatus
                                                .completed &&
                                        result.status !=
                                            ExpenseReplacementStatus
                                                .alreadyComplete) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result.errors.isEmpty
                                                ? 'Modifica non completata.'
                                                : result.errors.join('\n'),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Modifica non completata: $error',
                                        ),
                                      ),
                                    );
                                    return;
                                  } finally {
                                    if (mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                  }

                                  if (!context.mounted) return;

                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Spesa registrata."),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            isSubmitting
                                ? 'Salvataggio in corso...'
                                : widget.editingExpense == null
                                ? "Conferma spesa"
                                : "Salva modifiche",
                          ),
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
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.86),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _SpeseBackground extends StatelessWidget {
  final Widget child;

  const _SpeseBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.30)),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _SpeseHeroCard extends StatelessWidget {
  final double currentMonthTotal;

  const _SpeseHeroCard({required this.currentMonthTotal});

  @override
  Widget build(BuildContext context) {
    return _SpeseGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _SpeseIconBox(
                icon: Icons.account_balance_wallet_rounded,
                color: Color(0xFFFFB74D),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Controllo Spese Reali",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            EuroFormatter.format(currentMonthTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Spese reali registrate nel mese corrente",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const _SpeseHintBox(
            text:
                "Qui FrodoDesk legge ciò che è successo davvero: spese veloci, prelievi, contanti non tracciati e uscite quotidiane.",
          ),
        ],
      ),
    );
  }
}

class _SpeseMainGrid extends StatelessWidget {
  final int movementCount;
  final double last7DaysTotal;
  final String mainCategory;
  final double currentMonthTotal;
  final double cashWalletTotal;

  const _SpeseMainGrid({
    required this.movementCount,
    required this.last7DaysTotal,
    required this.mainCategory,
    required this.currentMonthTotal,
    required this.cashWalletTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniSpeseCard(
                title: "Portafogli contanti",
                value: EuroFormatter.format(cashWalletTotal),
                icon: Icons.payments_rounded,
                color: Color(0xFF66BB6A),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MiniSpeseCard(
                title: "Categoria principale",
                value: mainCategory,
                icon: Icons.emoji_events_rounded,
                color: Color(0xFF42A5F5),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniSpeseCard(
                title: "Ultimi 7 giorni",
                value: EuroFormatter.format(last7DaysTotal),
                icon: Icons.calendar_month_rounded,
                color: Color(0xFFAB47BC),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MiniSpeseCard(
                title: "Movimenti",
                value: movementCount.toString(),
                icon: Icons.receipt_long_rounded,
                color: Color(0xFFFF7043),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeseMonthStatusCard extends StatelessWidget {
  final List<FrodoObservation> observations;
  final List<FrodoObservation> visibleObservations;

  const _SpeseMonthStatusCard({
    required this.observations,
    required this.visibleObservations,
  });

  @override
  Widget build(BuildContext context) {
    return _SpeseGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SpeseIconBox(
            icon: Icons.psychology_alt_rounded,
            color: Color(0xFFFFD54F),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lettura del mese",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ...visibleObservations.map(
                  (observation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "• ${observation.message}",
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (observations.length > visibleObservations.length) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text("Tutte le analisi"),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: observations.map((observation) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            observation.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(observation.message),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text("Chiudi"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text("Mostra tutte le analisi"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMovementsCard extends StatelessWidget {
  const _EmptyMovementsCard();

  @override
  Widget build(BuildContext context) {
    return _SpeseGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SpeseIconBox(icon: Icons.inbox_rounded, color: Color(0xFF90A4AE)),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "Nessun movimento inserito.\nIl prossimo passo sarà registrare una spesa reale veloce.",
              style: TextStyle(
                color: Colors.white70,
                height: 1.35,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSpeseCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniSpeseCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SpeseGlassCard(
      child: Row(
        children: [
          _SpeseIconBox(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeseHintBox extends StatelessWidget {
  final String text;

  const _SpeseHintBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.28,
        ),
      ),
    );
  }
}

class _SpeseGlassCard extends StatelessWidget {
  final Widget child;

  const _SpeseGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SpeseIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SpeseIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _MovementChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MovementChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _SpeseGlassCard(
        child: Row(
          children: [
            _SpeseIconBox(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

String _formatMovementDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return "$day/$month/$year $hour:$minute";
}

class _ExpenseMonthHistoryPage extends StatelessWidget {
  final FinanceStore financeStore;
  final List<RealExpense> expenses;
  final String monthTitle;
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final SpeseMutationCoordinator mutationCoordinator;
  final ExpenseReplacementPersistence replacementPersistence;
  final ExpenseReplacementCoordinator replacementCoordinator;

  const _ExpenseMonthHistoryPage({
    required this.financeStore,
    required this.expenses,
    required this.monthTitle,
    required this.snapshot,
    required this.coordinator,
    required this.mutationCoordinator,
    required this.replacementPersistence,
    required this.replacementCoordinator,
  });

  bool _canCreatePrediction(RealExpense expense) =>
      canCreateExpectedExpensePrediction(expense);

  ({
    ExpenseRelationship relationship,
    ExpectedExpenseOccurrence occurrence,
  })? _prediction(RealExpense expense) {
    final factId = expense.economicFactId;
    if (factId == null) return null;
    final occurrence = financeStore.expectedExpenseAggregate.occurrences
        .where((item) => item.evidenceEconomicFactIds.contains(factId))
        .firstOrNull;
    if (occurrence == null) return null;
    final relationship = financeStore
        .expectedExpenseAggregate
        .relationships
        .where((item) => item.relationshipId == occurrence.relationshipId)
        .firstOrNull;
    if (relationship == null) return null;
    return (relationship: relationship, occurrence: occurrence);
  }

  String _formatExpectedDate(ExpectedExpenseOccurrence occurrence) {
    final date = occurrence.expectedIssueDate ??
        occurrence.expectedDueDate ??
        occurrence.expectedPaymentWindow?.start;
    return date == null ? 'non disponibile' : _formatMovementDate(date);
  }

  String _certaintyLabel(ExpectedExpenseDateCertainty? certainty) =>
      switch (certainty) {
        ExpectedExpenseDateCertainty.estimated => 'stimata',
        ExpectedExpenseDateCertainty.known => 'conosciuta',
        _ => 'non qualificata',
      };

  SpeseCommand _existingMovementCommand(
    RealExpense expense,
    SpeseCommandAction action,
  ) {
    return _speseCommandBuilder.buildExistingMovement(
      expense: expense,
      action: action,
      preparedAt: DateTime.now(),
      registry: snapshot.commandRegistry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Storico mese"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  "Movimenti del mese",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  monthTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...expenses.map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text("Dettaglio movimento"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _expensePresentationTitle(expense),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (expense.operationMetadata?.role ==
                                      OperationRole.accessory) ...[
                                    const SizedBox(height: 4),
                                    Text('Operazione: ${expense.description}'),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    "Importo: ${EuroFormatter.format(expense.amount)}",
                                  ),
                                  Text("Categoria: ${expense.category}"),
                                  Text("Conto: ${expense.balanceName}"),
                                  if (_prediction(expense) case final value?) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Previsione salvata: ${value.relationship.service} · '
                                      '${value.relationship.provider}',
                                    ),
                                    Text(
                                      'Prossima data: ${_formatExpectedDate(value.occurrence)}',
                                    ),
                                    Text(
                                      'Importo previsto: ${EuroFormatter.format(value.occurrence.expectedAmount)} '
                                      '· stima provvisoria',
                                    ),
                                    if (value.occurrence.expectedDueDate
                                        case final dueDate?)
                                      Text(
                                        'Scadenza ${_certaintyLabel(value.occurrence.expectedDueDateCertainty)}: '
                                        '${_formatMovementDate(dueDate)}',
                                      ),
                                    if (value
                                            .relationship
                                            .manualPaymentPreference
                                        case final preference?)
                                      Text(
                                        'Preferenza abituale: dal giorno '
                                        '${preference.preferredStartDayOfMonth}',
                                      ),
                                    if (value.occurrence.expectedPaymentWindow
                                        case final window?)
                                      Text(
                                        'Finestra prevista: '
                                        '${_formatMovementDate(window.start)} – '
                                        '${_formatMovementDate(window.end)}',
                                      ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text("Chiudi"),
                                ),
                                if (_canCreatePrediction(expense) &&
                                    _prediction(expense) == null)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();
                                      final now = DateTime.now();
                                      final token = now.microsecondsSinceEpoch;
                                      final saved = await Navigator.of(context)
                                          .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ExpectedExpenseFromRealExpensePage(
                                                    expense: expense,
                                                    financeStore: financeStore,
                                                    relationshipId:
                                                        'expense_relationship_$token',
                                                    occurrenceId:
                                                        'expected_occurrence_$token',
                                                  ),
                                            ),
                                          );
                                      if (!context.mounted || saved != true) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Previsione salvata.'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.event_repeat),
                                    label: const Text('Prevedi le prossime'),
                                  ),
                                if (_prediction(expense) case final value?)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();
                                      final result = await Navigator.of(context)
                                          .push<
                                            ExpectedExpenseCompletionResult
                                          >(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ExpectedExpenseCompletionPage(
                                                    financeStore: financeStore,
                                                    relationshipId: value
                                                        .relationship
                                                        .relationshipId,
                                                    occurrenceId: value
                                                        .occurrence
                                                        .occurrenceId,
                                                  ),
                                            ),
                                          );
                                      if (!context.mounted || result == null) {
                                        return;
                                      }
                                      final message =
                                          result.requiresExplicitChoice
                                          ? 'Previsione salvata. La preferenza abituale cade dopo questa scadenza: per questa volta serve una scelta specifica.'
                                          : result.outcome ==
                                                ExpectedExpenseUpdateOutcome
                                                    .unchanged
                                          ? 'Previsione già aggiornata.'
                                          : 'Previsione aggiornata.';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_calendar),
                                    label: const Text('Completa previsione'),
                                  ),
                                if (expense.operationMetadata != null)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      "Operazione composta: modifica ed eliminazione non disponibili.",
                                    ),
                                  ),
                                if (expense.operationMetadata == null)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();

                                      if (expense.isCashWithdrawal) {
                                        Navigator.of(context).pop();

                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                _CashWithdrawalFormPage(
                                                  balanceId: expense.balanceId,
                                                  balanceName:
                                                      expense.balanceName,
                                                  balanceAmount: 0,
                                                  balancePersonId:
                                                      expense.nonTrackedCash
                                                      ? expense.subject.name
                                                      : expense.cashWalletId ==
                                                            'wallet_chiara'
                                                      ? 'chiara'
                                                      : 'matteo',
                                                  snapshot: snapshot,
                                                  mutationCoordinator:
                                                      mutationCoordinator,
                                                  editingExpense: expense,
                                                ),
                                          ),
                                        );

                                        return;
                                      }

                                      if (expense.isIncome) {
                                        Navigator.of(context).pop();

                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                _ExtraIncomeFormPage(
                                                  balanceId: expense.balanceId,
                                                  balanceName:
                                                      expense.balanceName,
                                                  balanceAmount: 0,
                                                  snapshot: snapshot,
                                                  mutationCoordinator:
                                                      mutationCoordinator,
                                                  editingExpense: expense,
                                                ),
                                          ),
                                        );

                                        return;
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (modifyContext) {
                                          return AlertDialog(
                                            title: const Text(
                                              "Modifica movimento",
                                            ),
                                            content: const Text(
                                              "FrodoDesk preparerà la modifica di questa spesa mantenendo importo, descrizione, categoria e data già compilati.",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(
                                                    modifyContext,
                                                  ).pop();
                                                },
                                                child: const Text("Annulla"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.of(
                                                    modifyContext,
                                                  ).pop();

                                                  var matchingBalanceIndex = -1;
                                                  for (
                                                    var index = 0;
                                                    index <
                                                        snapshot
                                                            .activeBalances
                                                            .length;
                                                    index++
                                                  ) {
                                                    if (snapshot
                                                            .activeBalances[index]
                                                            .balanceId !=
                                                        expense.balanceId) {
                                                      continue;
                                                    }
                                                    if (matchingBalanceIndex !=
                                                        -1) {
                                                      matchingBalanceIndex = -2;
                                                      break;
                                                    }
                                                    matchingBalanceIndex =
                                                        index;
                                                  }
                                                  if (matchingBalanceIndex <
                                                      0) {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Conto originale non disponibile.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  Navigator.of(context).pop();

                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => _RealExpenseFormPage(
                                                        balanceId:
                                                            expense.balanceId,
                                                        balanceName:
                                                            expense.balanceName,
                                                        balanceAmount: snapshot
                                                            .activeBalances[matchingBalanceIndex]
                                                            .currentAmount,
                                                        snapshot: snapshot,
                                                        coordinator:
                                                            coordinator,
                                                        mutationCoordinator:
                                                            mutationCoordinator,
                                                        replacementPersistence:
                                                            replacementPersistence,
                                                        replacementCoordinator:
                                                            replacementCoordinator,
                                                        editingExpense: expense,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text("Continua"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text("Modifica"),
                                  ),
                                if (expense.operationMetadata == null)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();

                                      await mutationCoordinator.execute(
                                        _existingMovementCommand(
                                          expense,
                                          SpeseCommandAction.delete,
                                        ),
                                      );

                                      if (!context.mounted) return;

                                      Navigator.of(context).pop();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Movimento eliminato."),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text("Elimina"),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                      child: _SpeseGlassCard(
                        child: Row(
                          children: [
                            _SpeseIconBox(
                              icon: expense.isIncome
                                  ? Icons.add_card_rounded
                                  : (expense.isCashWithdrawal
                                        ? Icons.account_balance_wallet_rounded
                                        : Icons.receipt_long_rounded),
                              color: expense.isIncome
                                  ? const Color(0xFF42A5F5)
                                  : (expense.isCashWithdrawal
                                        ? const Color(0xFF66BB6A)
                                        : const Color(0xFFFF7043)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _expensePresentationTitle(expense),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${expense.category} • ${expense.balanceName}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            switch (expense.subject) {
                                              FinanceSubject.matteo =>
                                                "👨 Matteo",
                                              FinanceSubject.chiara =>
                                                "👩 Chiara",
                                              FinanceSubject.alice =>
                                                "👧 Alice",
                                              FinanceSubject.shared =>
                                                "👨‍👩‍👧 Condiviso",
                                            },
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatMovementDate(expense.date),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              expense.isIncome
                                  ? EuroFormatter.formatSigned(expense.amount)
                                  : EuroFormatter.format(expense.amount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashWithdrawalAccountPage extends StatelessWidget {
  final SpeseSnapshot snapshot;
  final SpeseMutationCoordinator mutationCoordinator;

  const _CashWithdrawalAccountPage({
    required this.snapshot,
    required this.mutationCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = snapshot.activeBalances;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Prelievo contanti"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  "Da quale conto prelevi?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (activeBalances.isEmpty)
                  const _SpeseGlassCard(
                    child: Text(
                      "Nessun conto attivo trovato.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ...activeBalances.map(
                    (balance) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MovementChoiceTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: balance.name,
                        subtitle:
                            "Saldo: ${EuroFormatter.format(balance.availableAmount)}",
                        color: const Color(0xFF66BB6A),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _CashWithdrawalFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                balancePersonId: balance.personId,
                                snapshot: snapshot,
                                mutationCoordinator: mutationCoordinator,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashWithdrawalFormPage extends StatefulWidget {
  final String balanceId;
  final String balanceName;
  final double balanceAmount;
  final String balancePersonId;
  final SpeseSnapshot snapshot;
  final SpeseMutationCoordinator mutationCoordinator;
  final RealExpense? editingExpense;

  const _CashWithdrawalFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.balancePersonId,
    required this.snapshot,
    required this.mutationCoordinator,
    this.editingExpense,
  });

  @override
  State<_CashWithdrawalFormPage> createState() =>
      _CashWithdrawalFormPageState();
}

class _CashWithdrawalFormPageState extends State<_CashWithdrawalFormPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final editingExpense = widget.editingExpense;

    selectedDate = editingExpense?.date ?? DateTime.now();

    if (editingExpense != null) {
      amountController.text = editingExpense.amount.toStringAsFixed(2);
      descriptionController.text = editingExpense.description;
      selectedCategory = editingExpense.category;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalCategories = widget.snapshot.categories.toSet();
    final currentCategory = selectedCategory;
    if (currentCategory != null) {
      withdrawalCategories.add(currentCategory);
    }
    final editingTrackedCash =
        widget.editingExpense != null && !widget.editingExpense!.nonTrackedCash;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Importo prelievo"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  "Conto scelto: ${widget.balanceName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Saldo attuale: ${EuroFormatter.format(widget.balanceAmount)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _SpeseGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quanto hai prelevato?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: "Importo",
                          hintText: "Es. 40.00",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MovementDateSelector(
                        selectedDate: selectedDate,
                        onChanged: (newDate) {
                          setState(() {
                            selectedDate = newDate;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Categoria (facoltativa)',
                          hintText: 'Contanti / non tracciato',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: withdrawalCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedCategory = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Nota / descrizione (facoltativa)',
                          hintText: 'Prelievo contanti',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final preparedAt = DateTime.now();
                            final command = _prepareSpeseCommand(
                              context,
                              () => _speseCommandBuilder.build(
                                draft: SpeseCommandDraft(
                                  id: preparedAt.millisecondsSinceEpoch
                                      .toString(),
                                  kind: SpeseCommandKind.cashWithdrawal,
                                  preparedAt: preparedAt,
                                  occurredAt: selectedDate,
                                  origin: SpeseCommandEndpointDraft(
                                    kind: EconomicEndpointKind.account,
                                    referenceId: widget.balanceId,
                                  ),
                                  destination: editingTrackedCash
                                      ? SpeseCommandEndpointDraft(
                                          kind: EconomicEndpointKind.cash,
                                          referenceId: widget
                                              .editingExpense!
                                              .cashWalletId,
                                        )
                                      : const SpeseCommandEndpointDraft(
                                          kind: EconomicEndpointKind.external,
                                          label: 'Contanti non tracciati',
                                        ),
                                  amountInput: amountController.text,
                                  category:
                                      selectedCategory ??
                                      'Contanti / non tracciato',
                                  personId: widget.balancePersonId,
                                  description:
                                      descriptionController.text.trim().isEmpty
                                      ? 'Prelievo contanti'
                                      : descriptionController.text,
                                ),
                                registry: widget.snapshot.commandRegistry,
                              ),
                            );
                            if (command == null) return;

                            await _executeSpeseCreationOrEdit(
                              mutationCoordinator: widget.mutationCoordinator,
                              command: command,
                              registry: widget.snapshot.commandRegistry,
                              editingExpense: widget.editingExpense,
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prelievo contanti registrato.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            widget.editingExpense == null
                                ? "Conferma prelievo"
                                : "Salva modifiche",
                          ),
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
    );
  }
}

class _MovementDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _MovementDateSelector({
    required this.selectedDate,
    required this.onChanged,
  });

  String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$day/$month/$year $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (pickedDate == null) return;
        if (!context.mounted) return;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(selectedDate),
        );

        if (pickedTime == null) return;

        onChanged(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Data operazione",
          filled: true,
          fillColor: Colors.white.withOpacity(0.86),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          _format(selectedDate),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ExtraIncomeAccountPage extends StatelessWidget {
  final SpeseSnapshot snapshot;
  final SpeseMutationCoordinator mutationCoordinator;

  const _ExtraIncomeAccountPage({
    required this.snapshot,
    required this.mutationCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = snapshot.activeBalances;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Entrata extra"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  "Su quale conto entra?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (activeBalances.isEmpty)
                  const _SpeseGlassCard(
                    child: Text(
                      "Nessun conto attivo trovato.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ...activeBalances.map(
                    (balance) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MovementChoiceTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: balance.name,
                        subtitle:
                            "Saldo: ${EuroFormatter.format(balance.availableAmount)}",
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _ExtraIncomeFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                snapshot: snapshot,
                                mutationCoordinator: mutationCoordinator,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraIncomeFormPage extends StatefulWidget {
  final String balanceId;
  final String balanceName;
  final double balanceAmount;
  final SpeseSnapshot snapshot;
  final SpeseMutationCoordinator mutationCoordinator;
  final RealExpense? editingExpense;

  const _ExtraIncomeFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.snapshot,
    required this.mutationCoordinator,
    this.editingExpense,
  });

  @override
  State<_ExtraIncomeFormPage> createState() => _ExtraIncomeFormPageState();
}

class _ExtraIncomeFormPageState extends State<_ExtraIncomeFormPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final editingExpense = widget.editingExpense;
    selectedDate = editingExpense?.date ?? DateTime.now();

    if (editingExpense != null) {
      amountController.text = editingExpense.amount.toStringAsFixed(2);
      descriptionController.text = editingExpense.description;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text("Importo entrata"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _SpeseBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  "Conto scelto: ${widget.balanceName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Saldo attuale: ${EuroFormatter.format(widget.balanceAmount)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _SpeseGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quanto è entrato?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: "Importo",
                          hintText: "Es. 50.00",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: "Descrizione",
                          hintText: "Es. Rimborso, regalo, vendita...",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MovementDateSelector(
                        selectedDate: selectedDate,
                        onChanged: (newDate) {
                          setState(() {
                            selectedDate = newDate;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final preparedAt = DateTime.now();
                            final command = _prepareSpeseCommand(
                              context,
                              () => _speseCommandBuilder.build(
                                draft: SpeseCommandDraft(
                                  id: preparedAt.millisecondsSinceEpoch
                                      .toString(),
                                  kind: SpeseCommandKind.extraIncome,
                                  preparedAt: preparedAt,
                                  occurredAt: selectedDate,
                                  origin: const SpeseCommandEndpointDraft(
                                    kind: EconomicEndpointKind.external,
                                    label: 'Entrata esterna',
                                  ),
                                  destination: SpeseCommandEndpointDraft(
                                    kind: EconomicEndpointKind.account,
                                    referenceId: widget.balanceId,
                                  ),
                                  amountInput: amountController.text,
                                  category: 'Entrata extra',
                                  description: descriptionController.text,
                                ),
                                registry: widget.snapshot.commandRegistry,
                              ),
                            );
                            if (command == null) return;

                            await _executeSpeseCreationOrEdit(
                              mutationCoordinator: widget.mutationCoordinator,
                              command: command,
                              registry: widget.snapshot.commandRegistry,
                              editingExpense: widget.editingExpense,
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Entrata extra registrata."),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            widget.editingExpense == null
                                ? "Conferma entrata"
                                : "Salva modifiche",
                          ),
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
    );
  }
}
