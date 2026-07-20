import 'package:flutter/material.dart';

import '../../logic/calendar/builders/alice_event_logistics_text_builder.dart';

class AliceEventLogisticsDetails extends StatelessWidget {
  final AliceEventLogisticsTextResult logisticsText;

  const AliceEventLogisticsDetails({super.key, required this.logisticsText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (logisticsText.sameAdultText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.sameAdultText!,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.incompleteText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.incompleteText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.involvedAdultsText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.involvedAdultsText!,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.busyWarningText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.busyWarningText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.conflictText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.conflictText!,
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.supportSuggestionText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.supportSuggestionText!,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.singleAdultText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.singleAdultText!,
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),

        if (logisticsText.splitLogisticsText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              logisticsText.splitLogisticsText!,
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
