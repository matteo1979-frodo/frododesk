import 'package:flutter/material.dart';

import '../models/finance_account_linked_item.dart';
import '../models/finance_balance.dart';
import '../models/finance_transaction.dart';
import '../stores/finance_store.dart';

class AccountDetailScreen extends StatefulWidget {
  final FinanceStore financeStore;
  final FinanceBalance balance;

  const AccountDetailScreen({
    super.key,
    required this.financeStore,
    required this.balance,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  FinanceStore get financeStore => widget.financeStore;
  FinanceBalance get balance => widget.balance;

  List<FinanceTransaction> get accountTransactions {
    return financeStore.transactions
        .where((t) => t.balanceId == balance.balanceId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<FinanceAccountLinkedItem> get linkedItems {
    return financeStore.linkedItems
        .where((item) => item.balanceId == balance.balanceId && item.active)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = accountTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        title: Text(balance.name),
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
                const SizedBox(height: 16),
                _frodoCard(),
                const SizedBox(height: 16),

                _sectionHeader(
                  title: "Ultimi movimenti",
                  actionLabel: transactions.length > 5 ? "Vedi tutti" : null,
                  onActionTap: transactions.length > 5
                      ? _showAllTransactionsDialog
                      : null,
                ),
                const SizedBox(height: 10),
                if (transactions.isEmpty)
                  _emptyCard("Nessun movimento registrato per questo conto.")
                else
                  ...transactions.take(5).map(_transactionTile),

                const SizedBox(height: 18),

                _sectionTitle("Prossime uscite collegate"),
                const SizedBox(height: 10),
                _futureItems(),

                const SizedBox(height: 18),

                balance.balanceType == FinanceBalanceType.prepaidCard
                    ? _sectionTitle("Informazioni carta")
                    : _sectionHeader(
                        title: "Carte e rapporti collegati",
                        actionLabel: "Aggiungi",
                        onActionTap: _showAddLinkedItemDialog,
                      ),
                const SizedBox(height: 10),
                balance.balanceType == FinanceBalanceType.prepaidCard
                    ? _prepaidCardInfoSection()
                    : _linkedItemsSection(),
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
            balance.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Saldo attuale",
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "€${balance.currentAmount.toStringAsFixed(2)}",
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

  Widget _frodoCard() {
    final futureItems =
        financeStore.recurringItems
            .where(
              (item) => !item.confirmed && item.balanceId == balance.balanceId,
            )
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    String message = "Nessuna uscita futura collegata a questo conto.";

    if (futureItems.isNotEmpty) {
      final first = futureItems.first;
      message =
          "Prossima scadenza: ${_formatDate(first.nextDueDate)} • ${first.name} • €${first.expectedAmount.toStringAsFixed(0)}";
    }

    return _glassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.84),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _futureItems() {
    final items =
        financeStore.recurringItems
            .where(
              (item) =>
                  !item.confirmed &&
                  !item.isIncome &&
                  item.balanceId == balance.balanceId,
            )
            .toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    if (items.isEmpty) {
      return _emptyCard("Nessuna uscita prevista collegata a questo conto.");
    }

    return Column(
      children: items.take(8).map((item) {
        return _glassCard(
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: Colors.white70),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: Text(
                  _formatDate(item.nextDueDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "€${item.expectedAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _prepaidCardInfoSection() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Questa prepagata è un contenitore con saldo reale.",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Può ricevere e inviare trasferimenti come un conto.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Le informazioni specifiche della carta, come scadenza, note e avvisi, saranno collegate qui.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedItemsSection() {
    final items = linkedItems;

    if (items.isEmpty) {
      return _emptyCard(
        "Nessuna carta o rapporto collegato. Aggiungi bancomat, carta di credito, prepagata, mutuo, finanziamento o contatti banca.",
      );
    }

    return Column(children: items.map(_linkedItemTile).toList());
  }

  Widget _linkedItemTile(FinanceAccountLinkedItem item) {
    return _glassCard(
      child: Row(
        children: [
          Icon(_iconForLinkedItem(item.type), color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _linkedItemSubtitle(item),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) {
              if (value == "transfer") {
                _showTransferFromLinkedItemDialog(item);
              } else if (value == "edit") {
                _showEditLinkedItemDialog(item);
              } else if (value == "delete") {
                _deleteLinkedItem(item);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "transfer",
                child: Text("Trasferisci denaro"),
              ),
              const PopupMenuItem(value: "edit", child: Text("Modifica")),
              const PopupMenuItem(value: "delete", child: Text("Elimina")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(FinanceTransaction transaction) {
    final sign = transaction.isIncome ? "+" : "-";

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _glassCard(
        child: Row(
          children: [
            Icon(
              transaction.isIncome
                  ? Icons.add_circle_rounded
                  : Icons.remove_circle_rounded,
              color: transaction.isIncome
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 78,
              child: Text(
                _formatDate(transaction.date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              "$sign€${transaction.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLinkedItemDialog() async {
    await _showLinkedItemDialog();
  }

  Future<void> _showEditLinkedItemDialog(
    FinanceAccountLinkedItem existing,
  ) async {
    await _showLinkedItemDialog(existing: existing);
  }

  Future<void> _showLinkedItemDialog({
    FinanceAccountLinkedItem? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? "");
    final descriptionController = TextEditingController(
      text: existing?.description ?? "",
    );
    final amountController = TextEditingController(
      text: existing?.amount?.toStringAsFixed(2) ?? "",
    );

    FinanceAccountLinkedItemType selectedType =
        existing?.type ?? FinanceAccountLinkedItemType.debitCard;

    DateTime? selectedExpiration = existing?.expirationDate;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, refresh) {
          return AlertDialog(
            title: Text(existing == null ? "Aggiungi rapporto" : "Modifica"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<FinanceAccountLinkedItemType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Tipo"),
                    items: FinanceAccountLinkedItemType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      refresh(() {
                        selectedType = value;
                      });
                    },
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                      hintText: "Es. Bancomat Matteo",
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Descrizione / note",
                    ),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Importo / rata / plafond",
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiration ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );

                      if (picked == null) return;

                      refresh(() {
                        selectedExpiration = picked;
                      });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Scadenza",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedExpiration == null
                            ? "Nessuna scadenza"
                            : _formatDate(selectedExpiration!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annulla"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();

                  if (name.isEmpty) return;

                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', '.'),
                  );

                  if (existing == null) {
                    final now = DateTime.now();
                    final linkedId = 'linked_${now.microsecondsSinceEpoch}';

                    financeStore.linkedItems.add(
                      FinanceAccountLinkedItem(
                        id: linkedId,
                        balanceId: balance.balanceId,
                        type: selectedType,
                        name: name,
                        description: descriptionController.text.trim(),
                        expirationDate: selectedExpiration,
                        amount: amount,
                        active: true,
                      ),
                    );

                    if (selectedType ==
                        FinanceAccountLinkedItemType.prepaidCard) {
                      final initialAmount = amount ?? 0;

                      financeStore.balances.add(
                        FinanceBalance(
                          balanceId: 'balance_$linkedId',
                          personId: balance.personId,
                          name: name,
                          initialAmount: initialAmount,
                          currentAmount: initialAmount,
                          updatedAt: now,
                          balanceType: FinanceBalanceType.prepaidCard,
                          operational: true,
                          active: true,
                          reservedAmount: 0,
                          warningThreshold: 0,
                          persistentStressDays: 0,
                          recoveryDays: 0,
                        ),
                      );

                      await financeStore.saveBalances();
                    }
                  } else {
                    final index = financeStore.linkedItems.indexWhere(
                      (item) => item.id == existing.id,
                    );

                    if (index != -1) {
                      financeStore.linkedItems[index] =
                          FinanceAccountLinkedItem(
                            id: existing.id,
                            balanceId: existing.balanceId,
                            type: selectedType,
                            name: name,
                            description: descriptionController.text.trim(),
                            expirationDate: selectedExpiration,
                            amount: amount,
                            active: existing.active,
                          );
                    }
                  }

                  await financeStore.saveLinkedItems();

                  if (mounted) {
                    setState(() {});
                    Navigator.pop(context);
                  }
                },
                child: const Text("Salva"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTransferFromLinkedItemDialog(
    FinanceAccountLinkedItem item,
  ) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController(text: item.name);

    final targets = financeStore.balances
        .where((b) => b.active && b.balanceId != balance.balanceId)
        .toList();

    String? toBalanceId = targets.isEmpty ? null : targets.first.balanceId;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, refresh) {
          return AlertDialog(
            title: const Text("Trasferisci denaro"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Da: ${balance.name}"),
                const SizedBox(height: 8),
                Text(
                  "Rapporto: ${item.name}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toBalanceId,
                  decoration: const InputDecoration(labelText: "A conto"),
                  items: targets.map((target) {
                    return DropdownMenuItem(
                      value: target.balanceId,
                      child: Text(target.name),
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

                  await financeStore.transferBetweenBalances(
                    fromBalanceId: balance.balanceId,
                    toBalanceId: toId,
                    amount: amount,
                    description: reasonController.text.trim().isEmpty
                        ? item.name
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

  Future<void> _deleteLinkedItem(FinanceAccountLinkedItem item) async {
    final index = financeStore.linkedItems.indexWhere((i) => i.id == item.id);

    if (index == -1) return;

    financeStore.linkedItems[index] = FinanceAccountLinkedItem(
      id: item.id,
      balanceId: item.balanceId,
      type: item.type,
      name: item.name,
      description: item.description,
      expirationDate: item.expirationDate,
      amount: item.amount,
      active: false,
    );

    await financeStore.saveLinkedItems();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showAllTransactionsDialog() async {
    final transactions = accountTransactions;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tutti i movimenti"),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: transactions.map(_transactionTile).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Chiudi"),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      children: [
        Expanded(child: _sectionTitle(title)),
        if (actionLabel != null && onActionTap != null)
          TextButton.icon(
            onPressed: onActionTap,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return _glassCard(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.76),
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: child,
    );
  }

  IconData _iconForLinkedItem(FinanceAccountLinkedItemType type) {
    switch (type) {
      case FinanceAccountLinkedItemType.debitCard:
        return Icons.credit_card_rounded;
      case FinanceAccountLinkedItemType.creditCard:
        return Icons.credit_score_rounded;
      case FinanceAccountLinkedItemType.prepaidCard:
        return Icons.payments_rounded;
      case FinanceAccountLinkedItemType.loan:
        return Icons.request_quote_rounded;
      case FinanceAccountLinkedItemType.mortgage:
        return Icons.home_work_rounded;
      case FinanceAccountLinkedItemType.bankContact:
        return Icons.contact_phone_rounded;
      case FinanceAccountLinkedItemType.other:
        return Icons.link_rounded;
    }
  }

  String _linkedItemSubtitle(FinanceAccountLinkedItem item) {
    final parts = <String>[];

    parts.add(_typeLabel(item.type));

    if (item.expirationDate != null) {
      parts.add("Scadenza ${_formatDate(item.expirationDate!)}");
    }

    if (item.amount != null) {
      parts.add("€${item.amount!.toStringAsFixed(2)}");
    }

    if (item.description.trim().isNotEmpty) {
      parts.add(item.description.trim());
    }

    return parts.join(" • ");
  }

  static String _typeLabel(FinanceAccountLinkedItemType type) {
    switch (type) {
      case FinanceAccountLinkedItemType.debitCard:
        return "Bancomat";
      case FinanceAccountLinkedItemType.creditCard:
        return "Carta di credito";
      case FinanceAccountLinkedItemType.prepaidCard:
        return "Prepagata";
      case FinanceAccountLinkedItemType.loan:
        return "Finanziamento";
      case FinanceAccountLinkedItemType.mortgage:
        return "Mutuo";
      case FinanceAccountLinkedItemType.bankContact:
        return "Contatto banca";
      case FinanceAccountLinkedItemType.other:
        return "Altro";
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$day/$month/$year";
  }
}
