import 'package:flutter/material.dart';

import '../../stores/finance_store.dart';

class FinancePressureSummaryCard extends StatelessWidget {
  final FinanceStore financeStore;

  const FinancePressureSummaryCard({super.key, required this.financeStore});

  @override
  Widget build(BuildContext context) {
    final pressure = financeStore.economicPressureScore();

    String label;
    Color color;
    String description;

    if (pressure < 500) {
      label = "Pressione economica bassa";
      description = "Situazione stabile e sostenibile.";
      color = const Color(0xFF66BB6A);
    } else if (pressure < 1500) {
      label = "Pressione economica media";
      description = "Le uscite iniziano a pesare.";
      color = const Color(0xFFFFB300);
    } else if (pressure < 3000) {
      label = "Pressione economica alta";
      description = "Serve attenzione sulle prossime spese.";
      color = const Color(0xFFE57373);
    } else {
      label = "Pressione economica critica";
      description = "La situazione economica è sotto forte pressione.";
      color = const Color(0xFFD32F2F);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.ssid_chart_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
