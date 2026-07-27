import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../logic/calendar/view_models/alice_day_overview_view_model.dart';
import '../../logic/calendar/view_models/family_day_overview_view_model.dart';
import '../../logic/calendar/view_models/family_member_day_overview_view_model.dart';

class FamilyDayOverviewCard extends StatelessWidget {
  final FamilyDayOverviewViewModel model;

  const FamilyDayOverviewCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PANORAMICA FAMIGLIA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy', 'it_IT').format(model.day),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Situazione prevista per la giornata selezionata.',
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          _FamilyDayOverviewRow(model: model.matteo),
          const SizedBox(height: 8),
          _FamilyDayOverviewRow(model: model.chiara),
          const SizedBox(height: 8),
          _AliceDayOverviewRow(model: model.alice),
        ],
      ),
    );
  }
}

class _FamilyDayOverviewRow extends StatelessWidget {
  final FamilyMemberDayOverviewViewModel model;

  const _FamilyDayOverviewRow({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              model.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.statusLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  model.turnLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AliceDayOverviewRow extends StatelessWidget {
  final AliceDayOverviewViewModel model;

  const _AliceDayOverviewRow({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              model.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              model.statusLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
