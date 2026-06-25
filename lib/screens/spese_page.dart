import 'dart:ui';

import 'package:flutter/material.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';
import '../models/real_expense.dart';
import '../models/finance_recurring_item.dart';
import '../stores/expense_category_store.dart';
import '../stores/cash_wallet_store.dart';

class SpesePage extends StatefulWidget {
  final FinanceStore financeStore;

  const SpesePage({super.key, required this.financeStore});

  @override
  State<SpesePage> createState() => _SpesePageState();
}

class _SpesePageState extends State<SpesePage> {
  final ExpenseStore expenseStore = ExpenseStore();
  final ExpenseCategoryStore categoryStore = ExpenseCategoryStore();
  final CashWalletStore cashWalletStore = CashWalletStore();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    await expenseStore.load();
    await categoryStore.load();
    await cashWalletStore.load();

    if (mounted) {
      setState(() {});
    }
  }

  String _monthName(int month) {
    const months = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTitle = "${_monthName(now.month)} ${now.year}";

    final currentMonthExpenses = expenseStore.all.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final last7DaysTotal = expenseStore.all
        .where(
          (expense) =>
              expense.date.isAfter(now.subtract(const Duration(days: 7))),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final currentMonthTotal = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final cashWalletTotal = cashWalletStore.all
        .where((wallet) => wallet.active)
        .fold<double>(0, (sum, wallet) => sum + wallet.currentAmount);

    String monthSummary;

    if (currentMonthExpenses.isEmpty) {
      monthSummary =
          "Nessun movimento registrato. Quando inizierai a inserire spese reali, qui FrodoDesk ti aiuterà a capire dove stanno andando i soldi.";
    } else {
      monthSummary =
          "Hai registrato ${currentMonthExpenses.length} movimenti per un totale di €${currentMonthTotal.toStringAsFixed(0)}.";
    }

    final categoryTotals = <String, double>{};

    for (final expense in currentMonthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    String mainCategory = "-";

    if (categoryTotals.isNotEmpty) {
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topValue = sortedCategories.first.value;

      final topCategories = sortedCategories
          .where((entry) => entry.value == topValue)
          .map((entry) => entry.key)
          .toList();

      mainCategory = topCategories.take(3).join(" / ");
    }

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
                    _SpeseHeroCard(currentMonthTotal: currentMonthTotal),
                    const SizedBox(height: 16),
                    _SpeseMainGrid(
                      movementCount: currentMonthExpenses.length,
                      last7DaysTotal: last7DaysTotal,
                      mainCategory: mainCategory,
                      currentMonthTotal: currentMonthTotal,
                      cashWalletTotal: cashWalletTotal,
                    ),
                    const SizedBox(height: 16),
                    _SpeseMonthStatusCard(summary: monthSummary),
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
                      monthTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...currentMonthExpenses
                        .take(3)
                        .map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SpeseGlassCard(
                              child: Row(
                                children: [
                                  _SpeseIconBox(
                                    icon: expense.isIncome
                                        ? Icons.add_card_rounded
                                        : (expense.isCashWithdrawal
                                              ? Icons
                                                    .account_balance_wallet_rounded
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    expense.displayAmount,
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
                                monthTitle: monthTitle,
                                financeStore: widget.financeStore,
                                expenseStore: expenseStore,
                                categoryStore: categoryStore,
                                cashWalletStore: cashWalletStore,
                              ),
                            ),
                          );

                          if (mounted) setState(() {});
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
                                financeStore: widget.financeStore,
                                expenseStore: expenseStore,
                                categoryStore: categoryStore,
                              ),
                            ),
                          );

                          if (mounted) setState(() {});
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
                                financeStore: widget.financeStore,
                                expenseStore: expenseStore,
                                cashWalletStore: cashWalletStore,
                              ),
                            ),
                          );

                          if (mounted) setState(() {});
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
                                financeStore: widget.financeStore,
                                expenseStore: expenseStore,
                              ),
                            ),
                          );

                          if (mounted) setState(() {});
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final ExpenseCategoryStore categoryStore;

  const _RealExpenseAccountPage({
    required this.financeStore,
    required this.expenseStore,
    required this.categoryStore,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = financeStore.balances
        .where((balance) => balance.active)
        .toList();

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
                            "Saldo: €${balance.availableAmount.toStringAsFixed(2)}",
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _RealExpenseFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                financeStore: financeStore,
                                expenseStore: expenseStore,
                                categoryStore: categoryStore,
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final ExpenseCategoryStore categoryStore;
  final RealExpense? editingExpense;

  const _RealExpenseFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.financeStore,
    required this.expenseStore,
    required this.categoryStore,
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
                  "Saldo attuale: €${widget.balanceAmount.toStringAsFixed(2)}",
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
                        value: selectedCategory,
                        decoration: _inputDecoration(
                          label: "Categoria",
                          hint: "Seleziona categoria...",
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          ...widget.categoryStore.all.map((category) {
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

                            await widget.categoryStore.addCategory(newCategory);

                            if (!mounted) return;

                            setState(() {
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
                        value: selectedSubject,
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
                            final amount =
                                double.tryParse(
                                  amountController.text.replaceAll(",", "."),
                                ) ??
                                0;

                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inserisci un importo valido."),
                                ),
                              );
                              return;
                            }

                            if (descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inserisci una descrizione."),
                                ),
                              );
                              return;
                            }

                            if (selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Seleziona una categoria."),
                                ),
                              );
                              return;
                            }

                            await widget.financeStore.registerRealExpense(
                              balanceId: widget.balanceId,
                              amount: amount,
                              description: descriptionController.text.trim(),
                              notes: selectedCategory,
                            );

                            await widget.expenseStore.addExpense(
                              RealExpense(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                balanceId: widget.balanceId,
                                balanceName: widget.balanceName,
                                amount: amount,
                                description: descriptionController.text.trim(),
                                category: selectedCategory!,
                                date: selectedDate,
                                subject: selectedSubject,
                              ),
                            );

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
            "€${currentMonthTotal.toStringAsFixed(0)}",
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
                value: "€${cashWalletTotal.toStringAsFixed(0)}",
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
                value: "€${last7DaysTotal.toStringAsFixed(0)}",
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
  final String summary;

  const _SpeseMonthStatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _SpeseGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpeseIconBox(
            icon: Icons.psychology_alt_rounded,
            color: Color(0xFFFFD54F),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lettura del mese",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final ExpenseCategoryStore categoryStore;
  final CashWalletStore cashWalletStore;

  const _ExpenseMonthHistoryPage({
    required this.expenses,
    required this.monthTitle,
    required this.financeStore,
    required this.expenseStore,
    required this.categoryStore,
    required this.cashWalletStore,
  });

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
                                  Text("Importo: ${expense.displayAmount}"),
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
                                      await financeStore.restoreRealExpense(
                                        balanceId: expense.balanceId,
                                        amount: expense.amount,
                                        description: expense.description,
                                      );

                                      if (expense.cashWalletId != null) {
                                        await cashWalletStore.removeCash(
                                          walletId: expense.cashWalletId!,
                                          amount: expense.amount,
                                        );
                                      }

                                      await expenseStore.removeExpense(
                                        expense.id,
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
                                                financeStore: financeStore,
                                                expenseStore: expenseStore,
                                                cashWalletStore:
                                                    cashWalletStore,
                                                editingExpense: expense,
                                              ),
                                        ),
                                      );

                                      return;
                                    }

                                    if (expense.isIncome) {
                                      await financeStore.removeExtraIncome(
                                        balanceId: expense.balanceId,
                                        amount: expense.amount,
                                        description: expense.description,
                                      );

                                      await expenseStore.removeExpense(
                                        expense.id,
                                      );

                                      if (!context.mounted) return;

                                      Navigator.of(context).pop();

                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => _ExtraIncomeFormPage(
                                            balanceId: expense.balanceId,
                                            balanceName: expense.balanceName,
                                            balanceAmount: 0,
                                            financeStore: financeStore,
                                            expenseStore: expenseStore,
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

                                                await financeStore
                                                    .restoreRealExpense(
                                                      balanceId:
                                                          expense.balanceId,
                                                      amount: expense.amount,
                                                      description:
                                                          expense.description,
                                                    );

                                                if (expense.isCashWithdrawal &&
                                                    expense.cashWalletId !=
                                                        null) {
                                                  await cashWalletStore
                                                      .removeCash(
                                                        walletId: expense
                                                            .cashWalletId!,
                                                        amount: expense.amount,
                                                      );
                                                }

                                                await expenseStore
                                                    .removeExpense(expense.id);

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
                                                          financeStore:
                                                              financeStore,
                                                          expenseStore:
                                                              expenseStore,
                                                          categoryStore:
                                                              categoryStore,
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

                                    if (expense.isIncome) {
                                      await financeStore.removeExtraIncome(
                                        balanceId: expense.balanceId,
                                        amount: expense.amount,
                                        description: expense.description,
                                      );
                                    } else {
                                      await financeStore.restoreRealExpense(
                                        balanceId: expense.balanceId,
                                        amount: expense.amount,
                                        description: expense.description,
                                      );
                                    }

                                    if (expense.isCashWithdrawal &&
                                        expense.cashWalletId != null) {
                                      await cashWalletStore.removeCash(
                                        walletId: expense.cashWalletId!,
                                        amount: expense.amount,
                                      );
                                    }

                                    await expenseStore.removeExpense(
                                      expense.id,
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
                                  ? "+${expense.displayAmount}"
                                  : expense.displayAmount,
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;

  const _CashWithdrawalAccountPage({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = financeStore.balances
        .where((balance) => balance.active)
        .toList();

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
                            "Saldo: €${balance.availableAmount.toStringAsFixed(2)}",
                        color: const Color(0xFF66BB6A),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _CashWithdrawalFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                balancePersonId: balance.personId,
                                financeStore: financeStore,
                                expenseStore: expenseStore,
                                cashWalletStore: cashWalletStore,
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final RealExpense? editingExpense;

  const _CashWithdrawalFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.balancePersonId,
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
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
                  "Saldo attuale: €${widget.balanceAmount.toStringAsFixed(2)}",
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
                            final amount =
                                double.tryParse(
                                  amountController.text.replaceAll(",", "."),
                                ) ??
                                0;

                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inserisci un importo valido."),
                                ),
                              );
                              return;
                            }

                            final walletId = 'wallet_${widget.balancePersonId}';
                            final wallet = widget.cashWalletStore.findById(
                              walletId,
                            );

                            if (wallet == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Portafoglio contanti non trovato.",
                                  ),
                                ),
                              );
                              return;
                            }

                            await widget.financeStore.registerRealExpense(
                              balanceId: widget.balanceId,
                              amount: amount,
                              description: "Prelievo contanti",
                              notes: wallet.name,
                            );

                            await widget.cashWalletStore.addCash(
                              walletId: wallet.id,
                              amount: amount,
                            );

                            await widget.expenseStore.addExpense(
                              RealExpense(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                balanceId: widget.balanceId,
                                balanceName: widget.balanceName,
                                amount: amount,
                                description: "Prelievo contanti",
                                category: "Portafoglio contanti",
                                date: selectedDate,
                                isCashWithdrawal: true,
                                cashWalletId: wallet.id,
                              ),
                            );

                            if (!context.mounted) return;

                            Navigator.of(context).pop();
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Prelievo registrato in ${wallet.name}.",
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;

  const _ExtraIncomeAccountPage({
    required this.financeStore,
    required this.expenseStore,
  });

  @override
  Widget build(BuildContext context) {
    final activeBalances = financeStore.balances
        .where((balance) => balance.active)
        .toList();

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
                            "Saldo: €${balance.availableAmount.toStringAsFixed(2)}",
                        color: const Color(0xFF42A5F5),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _ExtraIncomeFormPage(
                                balanceId: balance.balanceId,
                                balanceName: balance.name,
                                balanceAmount: balance.availableAmount,
                                financeStore: financeStore,
                                expenseStore: expenseStore,
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
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final RealExpense? editingExpense;

  const _ExtraIncomeFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.financeStore,
    required this.expenseStore,
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
                  "Saldo attuale: €${widget.balanceAmount.toStringAsFixed(2)}",
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
                            final amount =
                                double.tryParse(
                                  amountController.text.replaceAll(",", "."),
                                ) ??
                                0;

                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inserisci un importo valido."),
                                ),
                              );
                              return;
                            }

                            if (descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inserisci una descrizione."),
                                ),
                              );
                              return;
                            }

                            await widget.financeStore.registerExtraIncome(
                              balanceId: widget.balanceId,
                              amount: amount,
                              description: descriptionController.text.trim(),
                            );

                            await widget.expenseStore.addExpense(
                              RealExpense(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                balanceId: widget.balanceId,
                                balanceName: widget.balanceName,
                                amount: amount,
                                description: descriptionController.text.trim(),
                                category: "Entrata extra",
                                date: selectedDate,
                                isIncome: true,
                              ),
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
