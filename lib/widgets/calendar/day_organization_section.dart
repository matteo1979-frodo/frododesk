import 'package:flutter/material.dart';

import '../../utils/calendario_formatters.dart';

class DayOrganizationSection extends StatelessWidget {
  final bool uscita13Eff;
  final TimeOfDay? uscitaAt;
  final ValueChanged<bool> onToggleUscitaAnticipata;

  const DayOrganizationSection({
    super.key,
    required this.uscita13Eff,
    required this.uscitaAt,
    required this.onToggleUscitaAnticipata,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          "Stato / organizzazione della giornata",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            uscita13Eff && uscitaAt != null
                ? "Uscita anticipata: ${fmtTimeOfDay(uscitaAt!)}"
                : "Uscita anticipata (tocca per impostare orario)",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          value: uscita13Eff,
          onChanged: onToggleUscitaAnticipata,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
