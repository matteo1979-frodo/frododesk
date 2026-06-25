import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/finance_month_projection.dart';
import '../../stores/finance_store.dart';

typedef FinanceMonthTap =
    Future<void> Function(FinanceMonthProjection projection, Color color);

class FinanceYearDashboard extends StatefulWidget {
  final FinanceStore financeStore;
  final FinanceMonthTap onMonthTap;

  const FinanceYearDashboard({
    super.key,
    required this.financeStore,
    required this.onMonthTap,
  });

  @override
  State<FinanceYearDashboard> createState() => _FinanceYearDashboardState();
}

class _FinanceYearDashboardState extends State<FinanceYearDashboard> {
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final yearlyProjections = widget.financeStore.yearProjections(selectedYear);

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
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF8D6E63)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Pressione temporale",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.78),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              _yearButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  setState(() {
                    selectedYear--;
                  });
                },
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "$selectedYear",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _yearButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  setState(() {
                    selectedYear++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: yearlyProjections.map((projection) {
              final monthName = DateFormat(
                'MMM',
                'it_IT',
              ).format(projection.month);

              late final Color color;
              late final String label;

              if (projection.expectedMargin < 0) {
                color = const Color(0xFFE53935);
                label = "Soffre";
              } else if (projection.expectedMargin <= 200) {
                color = const Color(0xFFFFB300);
                label = "Attenzione";
              } else {
                color = const Color(0xFF43A047);
                label = "Respira";
              }

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await widget.onMonthTap(projection, color);
                },
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        monthName,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.78),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "€${projection.expectedMargin.toStringAsFixed(0)}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _yearButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
