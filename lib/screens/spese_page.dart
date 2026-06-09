import 'dart:ui';

import 'package:flutter/material.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';
import '../models/real_expense.dart';
import '../stores/expense_category_store.dart';

class SpesePage extends StatefulWidget {
  final FinanceStore financeStore;

  const SpesePage({super.key, required this.financeStore});

  @override
  State<SpesePage> createState() => _SpesePageState();
}

class _SpesePageState extends State<SpesePage> {
  final ExpenseStore expenseStore = ExpenseStore();
  final ExpenseCategoryStore categoryStore = ExpenseCategoryStore();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    await expenseStore.load();
    await categoryStore.load();

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
                                  const _SpeseIconBox(
                                    icon: Icons.receipt_long_rounded,
                                    color: Color(0xFFFF7043),
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
                                        Text(
                                          "${expense.category} • ${expense.balanceName}",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _ExpenseMonthHistoryPage(
                                expenses: currentMonthExpenses,
                                monthTitle: monthTitle,
                              ),
                            ),
                          );
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
                        title: "Prelievo / non tracciato",
                        subtitle: "Soldi usciti dal conto e non dettagliati",
                        color: const Color(0xFF66BB6A),
                      ),
                      const SizedBox(height: 10),
                      _MovementChoiceTile(
                        icon: Icons.add_card_rounded,
                        title: "Entrata extra",
                        subtitle:
                            "Rimborso, regalo, vendita, entrata occasionale",
                        color: const Color(0xFF42A5F5),
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

  const _RealExpenseFormPage({
    required this.balanceId,
    required this.balanceName,
    required this.balanceAmount,
    required this.financeStore,
    required this.expenseStore,
    required this.categoryStore,
  });

  @override
  State<_RealExpenseFormPage> createState() => _RealExpenseFormPageState();
}

class _RealExpenseFormPageState extends State<_RealExpenseFormPage> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedCategory;

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
                                date: DateTime.now(),
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
                          label: const Text("Conferma spesa"),
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

  const _SpeseMainGrid({
    required this.movementCount,
    required this.last7DaysTotal,
    required this.mainCategory,
    required this.currentMonthTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniSpeseCard(
                title: "Contanti / non tracciato",
                value: "€0",
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

class _ExpenseMonthHistoryPage extends StatelessWidget {
  final List<RealExpense> expenses;
  final String monthTitle;

  const _ExpenseMonthHistoryPage({
    required this.expenses,
    required this.monthTitle,
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
                    child: _SpeseGlassCard(
                      child: Row(
                        children: [
                          const _SpeseIconBox(
                            icon: Icons.receipt_long_rounded,
                            color: Color(0xFFFF7043),
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
                                Text(
                                  "${expense.category} • ${expense.balanceName}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
