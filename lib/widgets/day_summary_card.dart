import 'package:flutter/material.dart';

class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔴 Stato giorno (placeholder)
            const Text(
              "⚠ Oggi c’è un problema",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // 👤 Matteo
            _buildRow("Matteo: Mattina"),

            // 👤 Chiara
            _buildRow("Chiara: Notte"),

            // 👧 Alice
            _buildRow("Alice: Centro estivo 08:30–16:30"),

            const SizedBox(height: 12),

            // 🕳 Buchi
            const Text("Alice a casa 13:00–14:30"),

            // 🟠 Copertura
            _buildRow("Copertura debole"),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}
