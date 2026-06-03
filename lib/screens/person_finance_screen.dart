import 'package:flutter/material.dart';

import '../models/finance_balance.dart';
import '../stores/finance_store.dart';
import 'account_detail_screen.dart';

class PersonFinanceScreen extends StatefulWidget {
  final FinanceStore financeStore;
  final String personId;
  final String personName;

  const PersonFinanceScreen({
    super.key,
    required this.financeStore,
    required this.personId,
    required this.personName,
  });

  @override
  State<PersonFinanceScreen> createState() => _PersonFinanceScreenState();
}

class _PersonFinanceScreenState extends State<PersonFinanceScreen> {
  List<FinanceBalance> get personBalances {
    return widget.financeStore.balances
        .where((b) => b.personId == widget.personId && b.active)
        .toList();
  }

  double get total {
    return personBalances.fold(0, (sum, b) => sum + b.currentAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        title: Text("Conti ${widget.personName}"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nuovo conto"),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.28)),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _summaryCard(),
                const SizedBox(height: 18),
                ...personBalances.map(_accountCard),
                if (personBalances.isEmpty) _emptyCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.personName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Saldo totale",
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "€${total.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(FinanceBalance balance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountDetailScreen(
                financeStore: widget.financeStore,
                balance: balance,
              ),
            ),
          );

          if (mounted) {
            setState(() {});
          }
        },
        child: _glassCard(
          child: Row(
            children: [
              Icon(
                balance.balanceType == FinanceBalanceType.bankAccount
                    ? Icons.account_balance_rounded
                    : balance.balanceType == FinanceBalanceType.prepaidCard
                    ? Icons.account_balance_wallet_rounded
                    : balance.balanceType == FinanceBalanceType.debitCard
                    ? Icons.credit_card_rounded
                    : balance.balanceType == FinanceBalanceType.creditCard
                    ? Icons.credit_score_rounded
                    : balance.balanceType == FinanceBalanceType.cash
                    ? Icons.payments_rounded
                    : Icons.people_alt_rounded,
                color: balance.balanceType == FinanceBalanceType.bankAccount
                    ? const Color(0xFFFFD54F) // oro caldo
                    : balance.balanceType == FinanceBalanceType.prepaidCard
                    ? const Color(0xFF81C784) // verde bosco
                    : balance.balanceType == FinanceBalanceType.debitCard
                    ? const Color(0xFF64B5F6) // blu
                    : balance.balanceType == FinanceBalanceType.creditCard
                    ? const Color(0xFFE57373) // rosso tenue
                    : balance.balanceType == FinanceBalanceType.cash
                    ? const Color(0xFFA1887F) // rame
                    : const Color(0xFFBA68C8), // condiviso
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "€${balance.currentAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      balance.balanceType == FinanceBalanceType.bankAccount
                          ? "Conto bancario"
                          : balance.balanceType ==
                                FinanceBalanceType.prepaidCard
                          ? "Prepagata"
                          : balance.balanceType == FinanceBalanceType.debitCard
                          ? "Bancomat"
                          : balance.balanceType == FinanceBalanceType.creditCard
                          ? "Carta di credito"
                          : balance.balanceType == FinanceBalanceType.cash
                          ? "Contanti"
                          : "Conto condiviso",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (value) {
                  if (value == 'transfer') {
                    _showTransferDialog(balance);
                  } else if (value == 'edit') {
                    _showEditAccountDialog(balance);
                  } else if (value == 'delete') {
                    _deleteAccount(balance);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'transfer',
                    child: Text("Trasferisci denaro"),
                  ),
                  PopupMenuItem(value: 'edit', child: Text("Modifica conto")),
                  PopupMenuItem(value: 'delete', child: Text("Elimina conto")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return _glassCard(
      child: Text(
        "Nessun conto attivo per ${widget.personName}.",
        style: TextStyle(
          color: Colors.white.withOpacity(0.78),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: child,
    );
  }

  Future<void> _showAddAccountDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: "0");

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuovo conto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome conto"),
            ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: "Saldo iniziale"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(
                    amountController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;

              final now = DateTime.now();

              widget.financeStore.balances.add(
                FinanceBalance(
                  balanceId: 'balance_${now.microsecondsSinceEpoch}',
                  personId: widget.personId,
                  name: nameController.text.trim(),
                  initialAmount: amount,
                  currentAmount: amount,
                  updatedAt: now,
                  balanceType: FinanceBalanceType.bankAccount,
                  operational: true,
                  active: true,
                  reservedAmount: 0,
                  warningThreshold: 200,
                  persistentStressDays: 0,
                  recoveryDays: 0,
                ),
              );

              await widget.financeStore.saveBalances();

              if (mounted) {
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAccountDialog(FinanceBalance balance) async {
    final nameController = TextEditingController(text: balance.name);
    final amountController = TextEditingController(
      text: balance.currentAmount.toStringAsFixed(2),
    );

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifica conto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome conto"),
            ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: "Saldo attuale"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(
                amountController.text.trim().replaceAll(',', '.'),
              );

              if (amount == null) return;

              final index = widget.financeStore.balances.indexWhere(
                (b) => b.balanceId == balance.balanceId,
              );

              if (index == -1) return;

              final old = widget.financeStore.balances[index];

              widget.financeStore.balances[index] = FinanceBalance(
                balanceId: old.balanceId,
                personId: old.personId,
                name: nameController.text.trim(),
                initialAmount: old.initialAmount,
                currentAmount: amount,
                updatedAt: DateTime.now(),
                balanceType: old.balanceType,
                operational: old.operational,
                active: old.active,
                reservedAmount: old.reservedAmount,
                warningThreshold: old.warningThreshold,
                persistentStressDays: old.persistentStressDays,
                recoveryDays: old.recoveryDays,
              );

              await widget.financeStore.saveBalances();

              if (mounted) {
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransferDialog(FinanceBalance fromBalance) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    String? toBalanceId = widget.financeStore.balances
        .where((b) => b.active && b.balanceId != fromBalance.balanceId)
        .map((b) => b.balanceId)
        .firstOrNull;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, refresh) {
          final possibleTargets = widget.financeStore.balances
              .where((b) => b.active && b.balanceId != fromBalance.balanceId)
              .toList();

          return AlertDialog(
            title: const Text("Trasferisci denaro"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Da: ${fromBalance.name}"),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toBalanceId,
                  decoration: const InputDecoration(labelText: "A conto"),
                  items: possibleTargets.map((b) {
                    return DropdownMenuItem(
                      value: b.balanceId,
                      child: Text(b.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    refresh(() {
                      toBalanceId = value;
                    });
                  },
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: "Importo"),
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: "Motivo"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annulla"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final toId = toBalanceId;
                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', '.'),
                  );

                  if (toId == null || amount == null || amount <= 0) return;

                  await widget.financeStore.transferBetweenBalances(
                    fromBalanceId: fromBalance.balanceId,
                    toBalanceId: toId,
                    amount: amount,
                    description: reasonController.text.trim().isEmpty
                        ? "Trasferimento"
                        : reasonController.text.trim(),
                  );

                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: const Text("Trasferisci"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount(FinanceBalance balance) async {
    final index = widget.financeStore.balances.indexWhere(
      (b) => b.balanceId == balance.balanceId,
    );

    if (index == -1) return;

    final old = widget.financeStore.balances[index];

    widget.financeStore.balances[index] = FinanceBalance(
      balanceId: old.balanceId,
      personId: old.personId,
      name: old.name,
      initialAmount: old.initialAmount,
      currentAmount: old.currentAmount,
      updatedAt: DateTime.now(),
      balanceType: old.balanceType,
      operational: old.operational,
      active: false,
      reservedAmount: old.reservedAmount,
      warningThreshold: old.warningThreshold,
      persistentStressDays: old.persistentStressDays,
      recoveryDays: old.recoveryDays,
    );

    await widget.financeStore.saveBalances();

    if (mounted) {
      setState(() {});
    }
  }
}
