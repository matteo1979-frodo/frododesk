import 'package:flutter/material.dart';

import '../../utils/calendario_formatters.dart';

class SchoolOutSummary extends StatelessWidget {
  final bool visible;
  final TimeOfDay outStart;
  final TimeOfDay outEnd;
  final bool hasCustomOut;

  const SchoolOutSummary({
    super.key,
    required this.visible,
    required this.outStart,
    required this.outEnd,
    required this.hasCustomOut,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                "Uscita: ${fmtTimeOfDay(outStart)}–${fmtTimeOfDay(outEnd)}${hasCustomOut ? " (personalizzata)" : ""}",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock),
          label: const Text("Uscita (gestita da Scuola)"),
        ),
      ],
    );
  }
}
