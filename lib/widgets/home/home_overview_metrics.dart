import 'package:flutter/material.dart';

import '../shared/metric_tile.dart';

class HomeOverviewMetrics extends StatelessWidget {
  final int promemoriaCount;
  final int eventiCount;
  final int prossimiGiorniCount;

  final VoidCallback onPromemoriaTap;
  final VoidCallback onEventiTap;
  final VoidCallback onPeopleTap;
  final VoidCallback onNext7DaysTap;

  const HomeOverviewMetrics({
    super.key,
    required this.promemoriaCount,
    required this.eventiCount,
    required this.prossimiGiorniCount,
    required this.onPromemoriaTap,
    required this.onEventiTap,
    required this.onPeopleTap,
    required this.onNext7DaysTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        MetricTile(
          icon: Icons.notifications_none_rounded,
          label: "Promemoria",
          value: promemoriaCount.toString(),
          color: const Color(0xFF7E57C2),
          onTap: onPromemoriaTap,
        ),
        MetricTile(
          icon: Icons.event_note_rounded,
          label: "Eventi",
          value: eventiCount.toString(),
          color: const Color(0xFF3F51B5),
          onTap: onEventiTap,
        ),
        MetricTile(
          icon: Icons.groups_2_rounded,
          label: "Persone",
          value: "3",
          color: const Color(0xFF26A69A),
          onTap: onPeopleTap,
        ),
        MetricTile(
          icon: Icons.upcoming_rounded,
          label: "Eventi globali",
          value: prossimiGiorniCount.toString(),
          color: const Color(0xFFEC407A),
          onTap: onNext7DaysTap,
        ),
      ],
    );
  }
}
