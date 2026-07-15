import 'package:flutter/material.dart';

import '../../logic/calendar/view_models/alice_now_details_view_model.dart';
import '../../logic/calendar/view_models/alice_now_event_view_model.dart';

class AliceNowDialog extends StatelessWidget {
  final AliceNowDetailsViewModel model;

  const AliceNowDialog({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Alice"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stato attuale",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              model.nowLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: model.visual.color,
              ),
            ),
            if (model.dayStateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                "Stato giorno: ${model.dayStateLabel}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              "Eventi della giornata",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _AliceEventSection(
              title: "Prima",
              emptyText: "• Nessun evento già concluso",
              events: model.pastEvents,
              prefix: "✓ ",
            ),
            const SizedBox(height: 10),
            _AliceEventSection(
              title: "Adesso",
              emptyText: "• Nessun evento in corso",
              events: model.currentEvents,
              prefix: "👉 ",
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 10),
            _AliceEventSection(
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

class _AliceEventSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<AliceNowEventViewModel> events;
  final String prefix;
  final Color? color;
  final FontWeight fontWeight;

  const _AliceEventSection({
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
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
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
              "$prefix${event.title}${_timeText(event)}",
              style: TextStyle(
                color: color,
                fontWeight: fontWeight,
              ),
            ),
          ),
      ],
    );
  }

  static String _timeText(AliceNowEventViewModel event) {
    if (event.start == null && event.end == null) {
      return "";
    }

    return " ${_formatTime(event.start)} - ${_formatTime(event.end)}";
  }

  static String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}