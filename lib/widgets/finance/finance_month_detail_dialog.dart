import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/finance_month_projection.dart';
import '../../models/finance_recurring_item.dart';
import '../../stores/finance_store.dart';

class FinanceMonthDetailDialog extends StatelessWidget {
  final FinanceStore financeStore;
  final FinanceMonthProjection projection;
  final List<FinanceRecurringItem> monthIncomeItems;
  final List<FinanceRecurringItem> monthExpenseItems;

  const FinanceMonthDetailDialog({
    super.key,
    required this.financeStore,
    required this.projection,
    required this.monthIncomeItems,
    required this.monthExpenseItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _compactMonthStat(
              title: "Entrate",
              value: "€${projection.expectedIncome.toStringAsFixed(0)}",
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF43A047),
            ),
            const SizedBox(width: 10),
            _compactMonthStat(
              title: "Uscite",
              value: "€${projection.expectedExpenses.toStringAsFixed(0)}",
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFE53935),
            ),
            const SizedBox(width: 10),
            _compactMonthStat(
              title: "Margine",
              value: "€${projection.expectedMargin.toStringAsFixed(0)}",
              icon: Icons.trending_up_rounded,
              color: projection.expectedMargin < 0
                  ? const Color(0xFFE53935)
                  : const Color(0xFF43A047),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _monthMessage(),

        const SizedBox(height: 18),

        _peopleSituation(),

        const SizedBox(height: 18),

        _itemsSection(
          title: "Entrate del mese",
          emptyText: "Nessuna entrata prevista.",
          items: monthIncomeItems,
        ),

        const SizedBox(height: 16),

        _itemsSection(
          title: "Uscite del mese",
          emptyText: "Nessuna uscita prevista.",
          items: monthExpenseItems,
        ),
      ],
    );
  }

  Widget _compactMonthStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.black.withOpacity(0.58),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthMessage() {
    final isNegative = projection.expectedMargin < 0;
    final isMedium =
        projection.expectedExpenses > projection.expectedIncome * 0.75;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNegative
            ? const Color(0xFFE53935).withOpacity(0.10)
            : const Color(0xFF43A047).withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isNegative
            ? "Questo mese potrebbe essere pesante economicamente."
            : isMedium
            ? "Pressione economica medio-alta."
            : "Situazione sostenibile.",
        style: TextStyle(
          color: Colors.black.withOpacity(0.78),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _peopleSituation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Situazione persone",
            style: TextStyle(
              color: Colors.black.withOpacity(0.78),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _personBox(
                  name: "Matteo",
                  color: const Color(0xFF8D6E63),
                  owner: FinancePaymentOwner.matteo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _personBox(
                  name: "Chiara",
                  color: const Color(0xFF26A69A),
                  owner: FinancePaymentOwner.chiara,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _personBox({
    required String name,
    required Color color,
    required FinancePaymentOwner owner,
  }) {
    final income = financeStore.projectedIncomeForOwner(
      month: projection.month,
      owner: owner,
    );

    final amount = financeStore.projectedAmountForOwner(
      month: projection.month,
      owner: owner,
    );

    final margin = financeStore.projectedMarginForOwner(
      month: projection.month,
      owner: owner,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _personValue("Entrate", income, null),
          const SizedBox(height: 8),
          _personValue("Peso", amount, null),
          const SizedBox(height: 8),
          _personValue(
            "Margine",
            margin,
            margin < 0 ? const Color(0xFFE53935) : const Color(0xFF43A047),
          ),
        ],
      ),
    );
  }

  Widget _personValue(String label, double value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.58),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Text(
          "€${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _itemsSection({
    required String title,
    required String emptyText,
    required List<FinanceRecurringItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black.withOpacity(0.78),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              color: Colors.black.withOpacity(0.58),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...items.map(_compactRecurringRow),
      ],
    );
  }

  Widget _compactRecurringRow(FinanceRecurringItem item) {
    final isIncome = item.isIncome;
    final color = isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);

    final dateText = DateFormat(
      'd MMM',
      'it_IT',
    ).format(_visibleDateForItem(item));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.38)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.52),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "€${item.expectedAmount.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _visibleDateForItem(FinanceRecurringItem item) {
    final lastDayOfMonth = DateTime(
      projection.month.year,
      projection.month.month + 1,
      0,
    ).day;

    final safeDay = item.nextDueDate.day > lastDayOfMonth
        ? lastDayOfMonth
        : item.nextDueDate.day;

    switch (item.recurringType) {
      case FinanceRecurringType.monthly:
        return DateTime(projection.month.year, projection.month.month, safeDay);

      case FinanceRecurringType.yearly:
        return DateTime(projection.month.year, item.nextDueDate.month, safeDay);

      case FinanceRecurringType.oneShot:
      case FinanceRecurringType.custom:
        return item.nextDueDate;
    }
  }
}
