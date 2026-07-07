import 'package:flutter/material.dart';

class AliceEventsHeader extends StatelessWidget {
  final bool hasExtraEvents;
  final int extraEventsCount;
  final bool showAlicePeriodPanel;
  final VoidCallback onNewAliceEvent;
  final VoidCallback onToggleAlicePeriodPanel;

  const AliceEventsHeader({
    super.key,
    required this.hasExtraEvents,
    required this.extraEventsCount,
    required this.showAlicePeriodPanel,
    required this.onNewAliceEvent,
    required this.onToggleAlicePeriodPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Eventi Alice del giorno",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          hasExtraEvents
              ? "Eventi salvati: $extraEventsCount"
              : "Nessun evento Alice salvato per questo giorno.",
          style: TextStyle(color: Colors.black.withOpacity(0.68)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onNewAliceEvent,
                icon: const Icon(Icons.add),
                label: const Text("Nuovo evento Alice"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleAlicePeriodPanel,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  showAlicePeriodPanel
                      ? "Chiudi stato / periodo"
                      : "Modifica stato / periodo",
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
