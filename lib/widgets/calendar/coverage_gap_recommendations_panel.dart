import 'package:flutter/material.dart';

import '../../logic/calendar/view_models/coverage_gap_recommendation_view_model.dart';

class CoverageGapRecommendationsPanel extends StatelessWidget {
  final CoverageGapRecommendationsViewModel model;

  const CoverageGapRecommendationsPanel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Azioni consigliate',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            model.countText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            model.guidanceText,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...model.recommendations.asMap().entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Problema ${entry.key + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.title,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.description,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
          if (model.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Problemi rilevati (${model.recommendations.length}):',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
