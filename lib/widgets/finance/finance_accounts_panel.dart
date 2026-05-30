import 'package:flutter/material.dart';

import '../../models/finance_balance.dart';
import '../../stores/finance_store.dart';

class FinanceAccountsPanel extends StatefulWidget {
  final FinanceStore financeStore;
  final VoidCallback? onChanged;

  const FinanceAccountsPanel({
    super.key,
    required this.financeStore,
    this.onChanged,
  });

  @override
  State<FinanceAccountsPanel> createState() => _FinanceAccountsPanelState();
}

class _FinanceAccountsPanelState extends State<FinanceAccountsPanel> {
  IconData _iconForType(FinanceBalanceType type) {
    switch (type) {
      case FinanceBalanceType.bankAccount:
        return Icons.account_balance_rounded;
      case FinanceBalanceType.cash:
        return Icons.payments_rounded;
      case FinanceBalanceType.prepaidCard:
        return Icons.credit_card_rounded;
      case FinanceBalanceType.debitCard:
        return Icons.wallet_rounded;
      case FinanceBalanceType.creditCard:
        return Icons.credit_score_rounded;
      case FinanceBalanceType.sharedAccount:
        return Icons.groups_rounded;
    }
  }

  String _typeLabel(FinanceBalanceType type) {
    switch (type) {
      case FinanceBalanceType.bankAccount:
        return 'Conto bancario';
      case FinanceBalanceType.cash:
        return 'Contanti';
      case FinanceBalanceType.prepaidCard:
        return 'Carta prepagata';
      case FinanceBalanceType.debitCard:
        return 'Bancomat';
      case FinanceBalanceType.creditCard:
        return 'Carta credito';
      case FinanceBalanceType.sharedAccount:
        return 'Conto condiviso';
    }
  }

  Future<void> _showAddAccountDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    String selectedPersonId = 'matteo';
    FinanceBalanceType selectedType = FinanceBalanceType.bankAccount;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, refreshDialog) {
            return AlertDialog(
              title: const Text('Nuovo conto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome conto',
                        hintText: 'Es. Conto Imola Matteo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo iniziale',
                        hintText: 'Es. 500.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPersonId,
                      decoration: const InputDecoration(
                        labelText: 'Proprietario',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'matteo',
                          child: Text('Matteo'),
                        ),
                        DropdownMenuItem(
                          value: 'chiara',
                          child: Text('Chiara'),
                        ),
                        DropdownMenuItem(value: 'alice', child: Text('Alice')),
                        DropdownMenuItem(
                          value: 'shared',
                          child: Text('Condiviso'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        refreshDialog(() {
                          selectedPersonId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FinanceBalanceType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo conto',
                      ),
                      items: FinanceBalanceType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        refreshDialog(() {
                          selectedType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final rawAmount = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final amount = double.tryParse(rawAmount);

                    if (name.isEmpty || amount == null) {
                      return;
                    }

                    final now = DateTime.now();

                    widget.financeStore.balances.add(
                      FinanceBalance(
                        balanceId: 'balance_${now.microsecondsSinceEpoch}',
                        personId: selectedPersonId,
                        name: name,
                        initialAmount: amount,
                        currentAmount: amount,
                        updatedAt: now,
                        balanceType: selectedType,
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
                    }

                    widget.onChanged?.call();

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Crea conto'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTransferDialog() async {
    final activeBalances = widget.financeStore.balances
        .where((b) => b.active)
        .toList();

    if (activeBalances.length < 2) {
      return;
    }

    String fromBalanceId = activeBalances.first.balanceId;
    String toBalanceId = activeBalances[1].balanceId;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(text: 'Trasferimento');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, refreshDialog) {
            return AlertDialog(
              title: const Text('Trasferimento tra conti'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: fromBalanceId,
                      decoration: const InputDecoration(labelText: 'Da conto'),
                      items: widget.financeStore.balances
                          .where((b) => b.active)
                          .map(
                            (balance) => DropdownMenuItem(
                              value: balance.balanceId,
                              child: Text(balance.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        refreshDialog(() {
                          fromBalanceId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: toBalanceId,
                      decoration: const InputDecoration(labelText: 'A conto'),
                      items: widget.financeStore.balances
                          .where((b) => b.active)
                          .map(
                            (balance) => DropdownMenuItem(
                              value: balance.balanceId,
                              child: Text(balance.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        refreshDialog(() {
                          toBalanceId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Importo',
                        hintText: 'Es. 100.00',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );

                    if (amount == null || amount <= 0) {
                      return;
                    }

                    if (fromBalanceId == toBalanceId) {
                      return;
                    }

                    await widget.financeStore.transferBetweenBalances(
                      fromBalanceId: fromBalanceId,
                      toBalanceId: toBalanceId,
                      amount: amount,
                      description: descriptionController.text.trim(),
                    );

                    if (mounted) {
                      setState(() {});
                    }

                    widget.onChanged?.call();

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Trasferisci'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = widget.financeStore.balances
        .where((b) => b.active)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.black87,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Conti e strumenti economici',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Trasferisci',
                    onPressed: _showTransferDialog,
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                  IconButton(
                    tooltip: 'Nuovo conto',
                    onPressed: _showAddAccountDialog,
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...balances.map((balance) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconForType(balance.balanceType),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _typeLabel(balance.balanceType),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.black54,
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final nameController = TextEditingController(
                              text: balance.name,
                            );

                            final amountController = TextEditingController(
                              text: balance.currentAmount.toStringAsFixed(2),
                            );

                            String selectedPersonId = balance.personId;
                            FinanceBalanceType selectedType =
                                balance.balanceType;

                            await showDialog<void>(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, refreshDialog) {
                                    return AlertDialog(
                                      title: const Text('Modifica conto'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: nameController,
                                              decoration: const InputDecoration(
                                                labelText: 'Nome conto',
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            TextField(
                                              controller: amountController,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: const InputDecoration(
                                                labelText: 'Saldo attuale',
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            DropdownButtonFormField<String>(
                                              value: selectedPersonId,
                                              decoration: const InputDecoration(
                                                labelText: 'Proprietario',
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'matteo',
                                                  child: Text('Matteo'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'chiara',
                                                  child: Text('Chiara'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'alice',
                                                  child: Text('Alice'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'shared',
                                                  child: Text('Condiviso'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                if (value == null) return;

                                                refreshDialog(() {
                                                  selectedPersonId = value;
                                                });
                                              },
                                            ),

                                            const SizedBox(height: 12),

                                            DropdownButtonFormField<
                                              FinanceBalanceType
                                            >(
                                              value: selectedType,
                                              decoration: const InputDecoration(
                                                labelText: 'Tipo conto',
                                              ),
                                              items: FinanceBalanceType.values
                                                  .map((type) {
                                                    return DropdownMenuItem(
                                                      value: type,
                                                      child: Text(
                                                        _typeLabel(type),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value == null) return;

                                                refreshDialog(() {
                                                  selectedType = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Annulla'),
                                        ),

                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final raw = amountController.text
                                                .trim()
                                                .replaceAll(',', '.');

                                            final amount = double.tryParse(raw);

                                            if (amount == null) {
                                              return;
                                            }

                                            final index = widget
                                                .financeStore
                                                .balances
                                                .indexWhere(
                                                  (b) =>
                                                      b.balanceId ==
                                                      balance.balanceId,
                                                );

                                            if (index == -1) return;

                                            final current = widget
                                                .financeStore
                                                .balances[index];

                                            final oldAmount =
                                                current.currentAmount;

                                            final difference =
                                                amount - oldAmount;

                                            widget
                                                    .financeStore
                                                    .balances[index] =
                                                FinanceBalance(
                                                  balanceId: current.balanceId,
                                                  personId: selectedPersonId,
                                                  name: nameController.text
                                                      .trim(),
                                                  initialAmount:
                                                      current.initialAmount,
                                                  currentAmount: oldAmount,
                                                  updatedAt: DateTime.now(),
                                                  balanceType: selectedType,
                                                  operational:
                                                      current.operational,
                                                  active: current.active,
                                                  reservedAmount:
                                                      current.reservedAmount,
                                                  warningThreshold:
                                                      current.warningThreshold,
                                                  persistentStressDays: current
                                                      .persistentStressDays,
                                                  recoveryDays:
                                                      current.recoveryDays,
                                                );

                                            if (difference != 0) {
                                              await widget.financeStore
                                                  .updateBalance(
                                                    balanceId:
                                                        current.balanceId,
                                                    newAmount: amount,
                                                  );
                                            } else {
                                              await widget.financeStore
                                                  .saveBalances();
                                            }

                                            if (mounted) {
                                              setState(() {});
                                            }

                                            widget.onChanged?.call();

                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.save_rounded),
                                          label: const Text('Salva'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          }
                          if (value == 'disable') {
                            final index = widget.financeStore.balances
                                .indexWhere(
                                  (b) => b.balanceId == balance.balanceId,
                                );

                            if (index == -1) return;

                            final current = widget.financeStore.balances[index];

                            widget.financeStore.balances[index] =
                                FinanceBalance(
                                  balanceId: current.balanceId,
                                  personId: current.personId,
                                  name: current.name,
                                  initialAmount: current.initialAmount,
                                  currentAmount: current.currentAmount,
                                  updatedAt: current.updatedAt,
                                  balanceType: current.balanceType,
                                  operational: current.operational,
                                  active: false,
                                  reservedAmount: current.reservedAmount,
                                  warningThreshold: current.warningThreshold,
                                  persistentStressDays:
                                      current.persistentStressDays,
                                  recoveryDays: current.recoveryDays,
                                );

                            await widget.financeStore.saveBalances();

                            if (mounted) {
                              setState(() {});
                            }
                            widget.onChanged?.call();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded),
                                SizedBox(width: 8),
                                Text('Modifica conto'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'disable',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded),
                                SizedBox(width: 8),
                                Text('Disattiva conto'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Text(
                        '€ ${balance.currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        balance.personId.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
