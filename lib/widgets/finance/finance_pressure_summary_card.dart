import 'package:flutter/material.dart';

import '../../models/finance_pressure_presentation.dart';

class FinancePressureSummaryCard extends StatelessWidget {
  final FinancePressurePresentation presentation;

  const FinancePressureSummaryCard({super.key, required this.presentation});

  @override
  Widget build(BuildContext context) {
    final color = Color(presentation.color);

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
                  presentation.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  presentation.description,
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
