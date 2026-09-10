import 'dart:ui';

import 'package:flutter/material.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';
import '../models/real_expense.dart';
import '../models/finance_recurring_item.dart';
import '../models/frodo_observation.dart';
import '../stores/expense_category_store.dart';
import '../stores/cash_wallet_store.dart';
import '../logic/spese/spese_coordinator.dart';
import '../logic/spese/builders/spese_command_builder.dart';
import '../logic/spese/spese_mutation_coordinator.dart';
import '../models/economic_event.dart';
import '../models/spese_command.dart';
import '../models/spese_snapshot.dart';
import '../utils/euro_formatter.dart';

const _speseCommandBuilder = SpeseCommandBuilder();

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

class SpesePage extends StatefulWidget {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;

  const SpesePage({
    super.key,
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
  });

  @override
  State<SpesePage> createState() => _SpesePageState();
}

class _SpesePageState extends State<SpesePage> {
  final ExpenseCategoryStore categoryStore = ExpenseCategoryStore();
  late final SpeseCoordinator coordinator;
  late final SpeseMutationCoordinator mutationCoordinator;
  late SpeseSnapshot snapshot;

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
    snapshot = coordinator.build(observedAt: DateTime.now());
    _loadCategoryStore();
  }

  Future<void> _loadCategoryStore() async {
    await categoryStore.load();
    final loadedSnapshot = coordinator.build(observedAt: DateTime.now());
    if (mounted) {
      setState(() => snapshot = loadedSnapshot);
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
                                      expense.description,
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
                                expenses: currentMonthExpenses,
                                monthTitle: snapshot.monthTitle,
                                snapshot: snapshot,
                                coordinator: coordinator,
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MovementChoiceTile(
                        icon: Icons.shopping_bag_rounded,
                        title: "Spesa reale",
                        subtitle: "McDonald's, Sandra, benzina, ferramenta...",
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
                        icon: Icons.payments_rounded,
                        title: "Prelievo contanti",
                        subtitle: "Scala un conto e carica un portafoglio",
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
  final RealExpense? editingExpense;

  const _RealExpenseFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.snapshot,
    required this.coordinator,
    required this.mutationCoordinator,
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
                          onPressed: () async {
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
                                  destination: const SpeseCommandEndpointDraft(
                                    kind: EconomicEndpointKind.external,
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

                            await widget.mutationCoordinator.execute(command);

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
                            widget.editingExpense == null
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
  final List<RealExpense> expenses;
  final String monthTitle;
  final SpeseSnapshot snapshot;
  final SpeseCoordinator coordinator;
  final SpeseMutationCoordinator mutationCoordinator;

  const _ExpenseMonthHistoryPage({
    required this.expenses,
    required this.monthTitle,
    required this.snapshot,
    required this.coordinator,
    required this.mutationCoordinator,
  });

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
                                    expense.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Importo: ${EuroFormatter.format(expense.amount)}",
                                  ),
                                  Text("Categoria: ${expense.category}"),
                                  Text("Conto: ${expense.balanceName}"),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text("Chiudi"),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();

                                    if (expense.isCashWithdrawal) {
                                      await mutationCoordinator.execute(
                                        _existingMovementCommand(
                                          expense,
                                          SpeseCommandAction.removeForEdit,
                                        ),
                                      );

                                      if (!context.mounted) return;

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
                                                    expense.cashWalletId ==
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
                                      await mutationCoordinator.execute(
                                        _existingMovementCommand(
                                          expense,
                                          SpeseCommandAction.removeForEdit,
                                        ),
                                      );

                                      if (!context.mounted) return;

                                      Navigator.of(context).pop();

                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => _ExtraIncomeFormPage(
                                            balanceId: expense.balanceId,
                                            balanceName: expense.balanceName,
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

                                                await mutationCoordinator
                                                    .execute(
                                                      _existingMovementCommand(
                                                        expense,
                                                        SpeseCommandAction
                                                            .removeForEdit,
                                                      ),
                                                    );

                                                if (!context.mounted) return;

                                                Navigator.of(context).pop();

                                                await Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        _RealExpenseFormPage(
                                                          balanceId:
                                                              expense.balanceId,
                                                          balanceName: expense
                                                              .balanceName,
                                                          balanceAmount: 0,
                                                          snapshot: snapshot,
                                                          coordinator:
                                                              coordinator,
                                                          mutationCoordinator:
                                                              mutationCoordinator,
                                                          editingExpense:
                                                              expense,
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

                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    expense.description,
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
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final editingExpense = widget.editingExpense;

    selectedDate = editingExpense?.date ?? DateTime.now();

    if (editingExpense != null) {
      amountController.text = editingExpense.amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final walletId = 'wallet_${widget.balancePersonId}';
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
                                  destination: SpeseCommandEndpointDraft(
                                    kind: EconomicEndpointKind.cash,
                                    referenceId: walletId,
                                  ),
                                  amountInput: amountController.text,
                                  category: 'Portafoglio contanti',
                                  personId: widget.balancePersonId,
                                  description: 'Prelievo contanti',
                                ),
                                registry: widget.snapshot.commandRegistry,
                              ),
                            );
                            if (command == null) return;

                            await widget.mutationCoordinator.execute(command);

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Prelievo registrato in ${command.destination.label}.",
                                ),
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

                            await widget.mutationCoordinator.execute(command);

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
