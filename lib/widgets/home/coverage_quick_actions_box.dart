import 'package:flutter/material.dart';

import '../../logic/coverage_engine.dart';

class CoverageQuickActionsBox extends StatelessWidget {
  final List<CoverageGapDetail> todayDetails;

  final VoidCallback onResolveTap;
  final VoidCallback onFutureTap;

  final String? futureProblemText;

  const CoverageQuickActionsBox({
    super.key,
    required this.todayDetails,
    required this.onResolveTap,
    required this.onFutureTap,
    this.futureProblemText,
  });

  @override
  Widget build(BuildContext context) {
    if (todayDetails.isEmpty && futureProblemText == null) {
      return const SizedBox.shrink();
    }

    if (todayDetails.isEmpty && futureProblemText != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                futureProblemText!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(onPressed: onFutureTap, child: const Text("VAI")),
          ],
        ),
      );
    }

    final first = todayDetails.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE57373).withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Problema copertura",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            todayDetails.length == 1
                ? "1 buco oggi: ${_formatTime(first.start)}–${_formatTime(first.end)}"
                : "${todayDetails.length} buchi oggi. Primo: ${_formatTime(first.start)}–${_formatTime(first.end)}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onResolveTap,
            icon: const Icon(Icons.bolt_rounded),
            label: const Text("RISOLVI"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }
}
