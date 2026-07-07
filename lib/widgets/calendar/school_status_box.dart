import 'package:flutter/material.dart';

import '../../utils/calendario_formatters.dart';

class SchoolStatusBox extends StatelessWidget {
  final String schoolPeriodLabel;
  final bool isSchoolDayActive;
  final String schoolWeekdayLabel;
  final TimeOfDay accompagnamento;
  final TimeOfDay ingressoReale;
  final TimeOfDay uscitaReale;
  final TimeOfDay uscitaFine;
  final VoidCallback onOpenSchoolPanel;

  const SchoolStatusBox({
    super.key,
    required this.schoolPeriodLabel,
    required this.isSchoolDayActive,
    required this.schoolWeekdayLabel,
    required this.accompagnamento,
    required this.ingressoReale,
    required this.uscitaReale,
    required this.uscitaFine,
    required this.onOpenSchoolPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Scuola",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Periodo attivo: $schoolPeriodLabel",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isSchoolDayActive
                ? "Oggi: giorno scuola attivo"
                : "Oggi: nessuna scuola prevista",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSchoolDayActive ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Giorno letto dal periodo: $schoolWeekdayLabel",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Accompagnamento automatico: ${fmtTimeOfDay(accompagnamento)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            "Ingresso reale: ${fmtTimeOfDay(ingressoReale)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            "Uscita reale: ${fmtTimeOfDay(uscitaReale)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            "Rientro automatico: ${fmtTimeOfDay(uscitaFine)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenSchoolPanel,
            icon: const Icon(Icons.settings),
            label: const Text("Apri gestione Scuola"),
          ),
        ],
      ),
    );
  }
}
