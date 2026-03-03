import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _day = DateTime.now();

  static const _giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final settimanaTxt = DateFormat("EEEE d MMMM y", "it_IT").format(_day);
    final giornoTxt = DateFormat("y-MM-dd", "it_IT").format(_day);

    return Scaffold(
      appBar: AppBar(
        title: Text("Calendario Alice – ${_giornoLabel(_day)}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settimana / giorno", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text("$settimanaTxt  —  Giorno: $giornoTxt"),
            const SizedBox(height: 12),

            // Pulsanti giorni
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final d = _mondayOfWeek(_day).add(Duration(days: i));
                final selected = _isSameDay(d, _day);

                return ChoiceChip(
                  label: Text(_giorni[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _day = d),
                );
              }),
            ),

            const SizedBox(height: 14),

            // Stato copertura (placeholder)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text("Copertura OK (nessun buco rilevato)")),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Pannelli base (stabili)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _card("Turni lavoro", "Qui metteremo i turni e l’override (ferie/malattia).")),
                  const SizedBox(width: 12),
                  Expanded(child: _card("Alice / Scuola", "Qui metteremo orari scuola e maestre.")),
                  const SizedBox(width: 12),
                  Expanded(child: _card("Info rapide", "Settimana, giorno, copertura, ecc.")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("Modifica"),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _mondayOfWeek(DateTime d) {
    final wd = d.weekday; // 1..7
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _giornoLabel(DateTime d) {
    final i = (d.weekday - 1).clamp(0, 6);
    return _giorni[i];
  }
}