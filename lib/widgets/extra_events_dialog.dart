import 'package:flutter/material.dart';

import '../models/real_event.dart';
import '../utils/calendario_formatters.dart';

Future<void> showExtraEventsDialog({
  required BuildContext context,
  required String personName,
  required List<RealEvent> events,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Eventi $personName"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: events.map((e) {
                String time = "";

                if (e.startTime != null && e.endTime != null) {
                  time =
                      "${fmtTimeOfDay(e.startTime!)}–${fmtTimeOfDay(e.endTime!)}";
                } else if (e.startTime != null) {
                  time = fmtTimeOfDay(e.startTime!);
                } else {
                  time = "Tutto il giorno";
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text("${e.title} • $time")),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Chiudi"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}
