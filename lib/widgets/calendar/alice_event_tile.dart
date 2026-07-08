import 'package:flutter/material.dart';

import '../../logic/calendar/view_models/alice_event_tile_view_model.dart';

class AliceEventTile extends StatelessWidget {
  final AliceEventTileViewModel model;
  final VoidCallback onTap;
  final Widget? expandedChild;

  const AliceEventTile({
    super.key,
    required this.model,
    required this.onTap,
    this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: model.isConflict ? Colors.red.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: model.isConflict
                ? Colors.red.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(model.categoryIcon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.categoryLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: model.badgeBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          model.requiresLogistics
                              ? "Accomp. + Ritiro"
                              : "Evento passivo",
                          style: TextStyle(
                            fontSize: 10,
                            color: model.badgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (model.hasNote) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.notes, size: 16, color: Colors.black54),
                ],
                if (model.isConflict) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  model.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.black54,
                ),
              ],
            ),
            if (expandedChild != null) expandedChild!,
          ],
        ),
      ),
    );
  }
}
