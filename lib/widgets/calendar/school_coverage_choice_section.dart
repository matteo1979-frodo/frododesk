import 'package:flutter/material.dart';

import '../../logic/day_settings_store.dart';
import '../../utils/calendario_formatters.dart';

class SchoolCoverageChoiceSection extends StatelessWidget {
  final TimeOfDay ingressoInizio;
  final TimeOfDay ingressoFine;
  final TimeOfDay uscitaReale;
  final TimeOfDay? uscitaAt;
  final bool uscita13Eff;

  final SchoolCoverChoice schoolInCover;
  final SchoolCoverChoice schoolOutCover;
  final SchoolCoverChoice lunchCover;

  final String Function(SchoolCoverChoice choice) labelForChoice;

  final ValueChanged<SchoolCoverChoice> onSchoolInChanged;
  final ValueChanged<SchoolCoverChoice> onSchoolOutChanged;
  final ValueChanged<SchoolCoverChoice> onLunchChanged;

  const SchoolCoverageChoiceSection({
    super.key,
    required this.ingressoInizio,
    required this.ingressoFine,
    required this.uscitaReale,
    required this.uscitaAt,
    required this.uscita13Eff,
    required this.schoolInCover,
    required this.schoolOutCover,
    required this.lunchCover,
    required this.labelForChoice,
    required this.onSchoolInChanged,
    required this.onSchoolOutChanged,
    required this.onLunchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          "Decisione scuola (copertura)",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<SchoolCoverChoice>(
          value: schoolInCover,
          isExpanded: true,
          decoration: InputDecoration(
            labelText:
                "Ingresso ${fmtTimeOfDay(ingressoInizio)}–${fmtTimeOfDay(ingressoFine)}",
          ),
          items: SchoolCoverChoice.values.map((c) {
            return DropdownMenuItem(value: c, child: Text(labelForChoice(c)));
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            onSchoolInChanged(v);
          },
        ),
        if (!uscita13Eff) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<SchoolCoverChoice>(
            value: schoolOutCover,
            isExpanded: true,
            decoration: InputDecoration(
              labelText:
                  "Uscita ${fmtTimeOfDay(uscitaReale)}–${fmtTimeOfDay(TimeOfDay(hour: (uscitaReale.hour + ((uscitaReale.minute + 20) ~/ 60)), minute: (uscitaReale.minute + 20) % 60))}",
            ),
            items: SchoolCoverChoice.values.map((c) {
              return DropdownMenuItem(value: c, child: Text(labelForChoice(c)));
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              onSchoolOutChanged(v);
            },
          ),
        ],
        if (uscita13Eff && uscitaAt != null) ...[
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "Decisione pranzo (uscita anticipata)",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<SchoolCoverChoice>(
            value: lunchCover,
            isExpanded: true,
            decoration: InputDecoration(
              labelText:
                  "Pranzo ${fmtTimeOfDay(uscitaAt!)}–${fmtTimeOfDay(TimeOfDay(hour: ((uscitaAt!.hour * 60 + uscitaAt!.minute + 20) ~/ 60) % 24, minute: (uscitaAt!.hour * 60 + uscitaAt!.minute + 20) % 60))}",
            ),
            items: SchoolCoverChoice.values.map((c) {
              return DropdownMenuItem(value: c, child: Text(labelForChoice(c)));
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              onLunchChanged(v);
            },
          ),
        ],
      ],
    );
  }
}
