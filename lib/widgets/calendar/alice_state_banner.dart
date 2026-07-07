import 'package:flutter/material.dart';

class AliceStateBanner extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  final String? periodLabel;
  final Color periodColor;
  final IconData periodIcon;

  const AliceStateBanner({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.periodLabel,
    required this.periodColor,
    required this.periodIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Stato Alice: $label",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color.withOpacity(1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (periodLabel != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: periodColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: periodColor.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Icon(periodIcon, size: 18, color: periodColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Stato periodo attivo: $periodLabel",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: periodColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
