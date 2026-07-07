import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/status_visual.dart';

import '../../logic/calendar/view_models/family_now_view_model.dart';

class FamilyNowCard extends StatelessWidget {
  final FamilyNowViewModel model;
  final DateTime realNow;

  const FamilyNowCard({super.key, required this.model, required this.realNow});

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
          _FamilyNowRow(
            name: "Matteo",
            label: model.matteoLabel,
            visual: model.matteoVisual,
            busy: model.matteoLabel.startsWith("occupato"),
          ),
          const SizedBox(height: 8),
          _FamilyNowRow(
            name: "Chiara",
            label: model.chiaraLabel,
            visual: model.chiaraVisual,
            busy: model.chiaraLabel.startsWith("occupato"),
          ),
          const SizedBox(height: 8),
          _FamilyNowRow(
            name: "Alice",
            label: model.aliceLabel,
            visual: model.aliceVisual,
            busy: model.aliceLabel.startsWith("fuori"),
            isAlice: true,
          ),
        ],
      ),
    );
  }
}

class _FamilyNowRow extends StatelessWidget {
  final String name;
  final String label;
  final StatusVisual visual;
  final bool busy;
  final bool isAlice;

  const _FamilyNowRow({
    required this.name,
    required this.label,
    required this.visual,
    required this.busy,
    this.isAlice = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlice
        ? busy
              ? Colors.orange
              : Colors.blue
        : busy
        ? Colors.red
        : Colors.green;

    final icon = isAlice
        ? busy
              ? Icons.directions_walk
              : Icons.home
        : busy
        ? Icons.block
        : Icons.check_circle;

    return Container(
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
              name,
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
                          visual.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: visual.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
