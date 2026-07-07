import 'package:flutter/material.dart';

import '../../logic/alice_events/alice_event_behavior_text.dart';
import '../../models/alice_special_event.dart';
import '../../utils/calendario_formatters.dart';

class AliceEventExpanded extends StatelessWidget {
  final AliceSpecialEvent event;
  final List<String> conflictWith;

  final String Function(AliceSpecialEventCategory category) categoryLabel;
  final String Function(AliceSpecialEvent event) operationalDescription;
  final String Function(AliceSpecialEvent event) realTimeMeaning;

  final bool Function(AliceSpecialEvent event) isAliceOutDuringEvent;
  final bool Function(AliceSpecialEvent event) requiresAdultSupervision;
  final bool Function(AliceSpecialEvent event) canGenerateCoverageProblem;

  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const AliceEventExpanded({
    super.key,
    required this.event,
    required this.conflictWith,
    required this.categoryLabel,
    required this.operationalDescription,
    required this.realTimeMeaning,
    required this.isAliceOutDuringEvent,
    required this.requiresAdultSupervision,
    required this.canGenerateCoverageProblem,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          "Categoria: ${categoryLabel(e.category)}",
          style: TextStyle(
            color: Colors.black.withOpacity(0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Comportamento: ${aliceEventBehaviorLabel(e.behavior)}",
          style: TextStyle(
            color: Colors.black.withOpacity(0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (e.accompanyingAdultKey != null) ...[
          const SizedBox(height: 4),
          Text(
            "Con: ${_adultLabel(e.accompanyingAdultKey)}",
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
        if (e.dropOffAdultKey != null) ...[
          const SizedBox(height: 4),
          Text(
            "Accompagna: ${_adultLabel(e.dropOffAdultKey)}",
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
        if (e.pickUpAdultKey != null) ...[
          const SizedBox(height: 4),
          Text(
            "Ritiro: ${_adultLabel(e.pickUpAdultKey)}",
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          operationalDescription(e),
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          realTimeMeaning(e),
          style: TextStyle(
            color: isAliceOutDuringEvent(e) ? Colors.orange : Colors.green,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          requiresAdultSupervision(e)
              ? "Serve supervisione adulta."
              : "Non richiede supervisione adulta.",
          style: TextStyle(
            color: requiresAdultSupervision(e)
                ? Colors.deepOrange
                : Colors.teal,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          canGenerateCoverageProblem(e)
              ? "Può influenzare la copertura familiare."
              : "Nessun impatto previsto sulla copertura.",
          style: TextStyle(
            color: canGenerateCoverageProblem(e)
                ? Colors.redAccent
                : Colors.green,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Orario: ${fmtTimeOfDay(e.start)}–${fmtTimeOfDay(e.end)}",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (e.note.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            "Nota: ${e.note}",
            style: TextStyle(color: Colors.black.withOpacity(0.72)),
          ),
        ],
        if (conflictWith.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            "In conflitto con: ${conflictWith.join(', ')}",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_calendar),
                label: const Text("Sposta evento"),
              ),
              OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Annulla evento"),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text("Modifica"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Rimuovi"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _adultLabel(String? key) {
    return key == 'matteo'
        ? 'Matteo'
        : key == 'chiara'
        ? 'Chiara'
        : key == 'sandra'
        ? 'Sandra'
        : 'Supporto';
  }
}
