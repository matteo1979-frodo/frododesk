import 'package:flutter/material.dart';

import '../../logic/calendar/view_models/coverage_criticality_view_model.dart';
import '../../models/coverage_criticality_detail.dart';

class CoverageCriticalitiesPanel extends StatelessWidget {
  final List<CoverageCriticalityViewModel> items;

  const CoverageCriticalitiesPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final decisions = items
        .where(
          (item) => item.kind == CoverageCriticalityKind.recoverySacrificed,
        )
        .toList();
    final protected = items
        .where((item) => item.kind == CoverageCriticalityKind.recoveryProtected)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _countSummary(decisions.length, protected.length),
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (decisions.isNotEmpty)
          _CriticalitySection(
            title: 'Decisioni critiche',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
            items: decisions,
          ),
        if (decisions.isNotEmpty && protected.isNotEmpty)
          const SizedBox(height: 12),
        if (protected.isNotEmpty)
          _CriticalitySection(
            title: 'Recuperi protetti',
            icon: Icons.shield_outlined,
            color: Colors.teal.shade700,
            items: protected,
          ),
      ],
    );
  }

  String _countSummary(int decisions, int protected) {
    final decisionText = decisions == 1
        ? '1 decisione critica'
        : '$decisions decisioni critiche';
    final protectedText = protected == 1
        ? '1 recupero protetto'
        : '$protected recuperi protetti';
    return '$decisionText • $protectedText';
  }
}

class CoverageCriticalityRealityList extends StatelessWidget {
  final List<CoverageCriticalityViewModel> items;

  const CoverageCriticalityRealityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Copertura e recuperi',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item.realityText),
            ),
        ],
      ),
    );
  }
}

class _CriticalitySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<CoverageCriticalityViewModel> items;

  const _CriticalitySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(item.text),
                  Text(
                    item.timeRange,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
