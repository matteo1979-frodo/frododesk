import 'package:flutter/material.dart';

import 'sandra_compact_row.dart';
import '../../logic/calendar/view_models/sandra_coverage_view_model.dart';

class SandraCoverageCard extends StatelessWidget {
  final SandraCoverageViewModel model;

  final VoidCallback onEditMattina;
  final VoidCallback onEditPranzo;
  final VoidCallback onEditSera;

  final ValueChanged<bool> onChangedMattina;
  final ValueChanged<bool> onChangedPranzo;
  final ValueChanged<bool> onChangedSera;

  const SandraCoverageCard({
    super.key,
    required this.model,
    required this.onEditMattina,
    required this.onEditPranzo,
    required this.onEditSera,
    required this.onChangedMattina,
    required this.onChangedPranzo,
    required this.onChangedSera,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: "Copertura Sandra / Babysitter",
      subtitle: "Fasce rapide con modifica orario e attivazione manuale.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SandraCompactRow(
            title: "Mattina",
            start: model.mattinaStart,
            end: model.mattinaEnd,
            serve: model.decision.serveSandraMattina,
            manual: model.manualMattina,
            onEdit: onEditMattina,
            onChanged: onChangedMattina,
          ),
          const SizedBox(height: 8),
          SandraCompactRow(
            title: "Pranzo",
            start: model.pranzoStart,
            end: model.pranzoEnd,
            serve: model.decision.serveSandraPranzo,
            manual: model.manualPranzo,
            onEdit: onEditPranzo,
            onChanged: onChangedPranzo,
          ),
          const SizedBox(height: 8),
          SandraCompactRow(
            title: "Sera",
            start: model.seraStart,
            end: model.seraEnd,
            serve: model.decision.serveSandraSera,
            manual: model.manualSera,
            onEdit: onEditSera,
            onChanged: onChangedSera,
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
