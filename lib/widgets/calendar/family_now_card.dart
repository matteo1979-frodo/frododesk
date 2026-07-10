import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../logic/calendar/view_models/family_member_now_view_model.dart';
import '../../logic/calendar/view_models/family_now_view_model.dart';

class FamilyNowCard extends StatelessWidget {
  final FamilyNowViewModel model;
  final DateTime realNow;
  final VoidCallback onTapMatteo;
  final VoidCallback onTapChiara;
  final VoidCallback onTapAlice;

  const FamilyNowCard({
    super.key,
    required this.model,
    required this.realNow,
    required this.onTapMatteo,
    required this.onTapChiara,
    required this.onTapAlice,
  });

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
                Icons.family_restroom,
                size: 18,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "STATO ATTUALE FAMIGLIA",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.indigo.withOpacity(0.14)),
                ),
                child: Text(
                  DateFormat('HH:mm', 'it_IT').format(realNow),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Fotografia reale riferita al giorno selezionato, all'ora attuale.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          _FamilyNowRow(model: model.matteo, onTap: onTapMatteo),
          const SizedBox(height: 8),
          _FamilyNowRow(model: model.chiara, onTap: onTapChiara),
          const SizedBox(height: 8),
          _FamilyNowRow(model: model.alice, onTap: onTapAlice),
        ],
      ),
    );
  }
}

class _FamilyNowRow extends StatelessWidget {
  final FamilyMemberNowViewModel model;
  final VoidCallback onTap;

  const _FamilyNowRow({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = model.isAlice
        ? model.busy
              ? Colors.orange
              : Colors.blue
        : model.busy
        ? Colors.red
        : Colors.green;

    final icon = model.isAlice
        ? model.busy
              ? Icons.directions_walk
              : Icons.home
        : model.busy
        ? Icons.block
        : Icons.check_circle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: Text(
                model.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Transform.translate(
                          offset: const Offset(0, -5),
                          child: Text(
                            model.visual.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: model.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: model.visual.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
