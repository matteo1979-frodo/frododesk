import 'package:flutter/material.dart';

import '../../logic/calendar/view_models/family_adult_now_details_view_model.dart';
import '../../models/real_event.dart';

class FamilyAdultNowDialog extends StatelessWidget {
  final FamilyAdultNowDetailsViewModel model;

  const FamilyAdultNowDialog({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(model.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stato attuale",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              model.nowLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: model.visual.color,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Turno previsto",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(model.turnLabel),
            Text(
              "Stato attuale: ${model.nowLabel}",
              style: TextStyle(
                color: model.visual.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Eventi della giornata",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _EventSection(
              title: "Prima",
              emptyText: "• Nessun evento già concluso",
              events: model.pastEvents,
              prefix: "✓ ",
            ),
            const SizedBox(height: 10),
            _EventSection(
              title: "Adesso",
              emptyText: "• Nessun evento in corso",
              events: model.currentEvents,
              prefix: "👉 ",
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 10),
            _EventSection(
              title: "Dopo",
              emptyText: "• Nessun evento successivo",
              events: model.futureEvents,
              prefix: "• ",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Chiudi"),
        ),
      ],
    );
  }
}

class _EventSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<RealEvent> events;
  final String prefix;
  final Color? color;
  final FontWeight fontWeight;

  const _EventSection({
    required this.title,
    required this.emptyText,
    required this.events,
    required this.prefix,
    this.color,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (events.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...events.map(
            (event) => Text(
              "$prefix${event.title} "
              "${_formatTime(event.startTime)} - "
              "${_formatTime(event.endTime)}",
              style: TextStyle(color: color, fontWeight: fontWeight),
            ),
          ),
      ],
    );
  }

  static String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
