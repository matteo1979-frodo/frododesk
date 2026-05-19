import 'package:flutter/material.dart';

import '../../models/finance_recurring_item.dart';
import '../../stores/finance_store.dart';

class FinanceTimeItemCard extends StatelessWidget {
  final FinanceRecurringItem item;
  final FinanceStore financeStore;

  final VoidCallback? onTap;
  final VoidCallback? onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onConfirm;

  final String Function(int month) getMonthName;

  const FinanceTimeItemCard({
    super.key,
    required this.item,
    required this.financeStore,
    required this.getMonthName,
    this.onTap,
    this.onChanged,
    this.onEdit,
    this.onDelete,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final Color amountColor = item.isIncome
        ? const Color(0xFF43A047)
        : const Color(0xFFE53935);

    final String statusLabel = item.confirmed
        ? "CONFERMATA"
        : financeStore.isRecurringItemOverdue(item)
        ? "SCADUTA"
        : financeStore.isRecurringItemDueToday(item)
        ? "OGGI"
        : financeStore.isRecurringItemUpcoming(item)
        ? "IN ARRIVO"
        : "FUTURA";

    final Color statusColor = item.confirmed
        ? const Color(0xFF8D6E63)
        : financeStore.isRecurringItemOverdue(item)
        ? const Color(0xFFE53935)
        : financeStore.isRecurringItemDueToday(item)
        ? const Color(0xFFFF9800)
        : const Color(0xFF1E88E5);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 132,
              decoration: BoxDecoration(
                color: _priorityColor(item.paymentPriority).withOpacity(0.88),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.confirmed
                      ? const Color(0xFF8D6E63).withOpacity(0.08)
                      : financeStore.isRecurringItemOverdue(item)
                      ? const Color(0xFFE53935).withOpacity(0.10)
                      : financeStore.isRecurringItemDueToday(item)
                      ? const Color(0xFFFF9800).withOpacity(0.10)
                      : financeStore.isRecurringItemUpcoming(item)
                      ? const Color(0xFF1E88E5).withOpacity(0.08)
                      : Colors.white.withOpacity(0.72),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 18,
                          color: amountColor,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          "€${item.expectedAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),

                    if (item.description.trim().length > 3) ...[
                      const SizedBox(height: 4),

                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.52),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.black.withOpacity(0.45),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          "${item.nextDueDate.day} "
                          "${getMonthName(item.nextDueDate.month)} "
                          "${item.nextDueDate.year}",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.50),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),

                        const Spacer(),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildFinanceStatusBadge(
                              label: statusLabel,
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: Colors.black.withOpacity(0.55),
                        ),
                        onSelected: (value) async {
                          if (value == 'confirm') {
                            onConfirm?.call();
                            onChanged?.call();
                          }

                          if (value == 'edit') {
                            onEdit?.call();
                            onChanged?.call();
                          }

                          if (value == 'delete') {
                            onDelete?.call();
                            onChanged?.call();
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            if (!item.confirmed)
                              const PopupMenuItem(
                                value: 'confirm',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF43A047),
                                    ),
                                    SizedBox(width: 10),
                                    Text("Conferma"),
                                  ],
                                ),
                              ),

                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF1E88E5),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Modifica"),
                                ],
                              ),
                            ),

                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: Color(0xFFE53935),
                                  ),
                                  SizedBox(width: 10),
                                  Text("Elimina"),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(FinancePaymentPriority priority) {
    switch (priority) {
      case FinancePaymentPriority.low:
        return 'BASSA';

      case FinancePaymentPriority.normal:
        return 'NORMALE';

      case FinancePaymentPriority.high:
        return 'ALTA';

      case FinancePaymentPriority.critical:
        return 'CRITICA';
    }
  }

  Color _priorityColor(FinancePaymentPriority priority) {
    switch (priority) {
      case FinancePaymentPriority.low:
        return const Color(0xFF43A047);

      case FinancePaymentPriority.normal:
        return const Color(0xFF1E88E5);

      case FinancePaymentPriority.high:
        return const Color(0xFFFF9800);

      case FinancePaymentPriority.critical:
        return const Color(0xFFE53935);
    }
  }

  Widget _buildFinanceStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
