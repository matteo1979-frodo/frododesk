// lib/widgets/ferie_period_panel.dart
import 'package:flutter/material.dart';

import '../logic/ferie_period_store.dart';
import '../models/day_override.dart';

/// Pannello CNC per gestire "ferie lunghe" (periodi) per Matteo/Chiara.
/// - Aggiungi periodo (start/end)
/// - Vedi lista
/// - Elimina singolo periodo
///
/// NOTE:
/// - In-memory (come store). Persistenza dopo.
/// - Non tocca Override Step B: qui stiamo solo costruendo il sottoprogramma UI.
class FeriePeriodPanel extends StatefulWidget {
  final FeriePeriodStore store;

  const FeriePeriodPanel({super.key, required this.store});

  @override
  State<FeriePeriodPanel> createState() => _FeriePeriodPanelState();
}

class _FeriePeriodPanelState extends State<FeriePeriodPanel> {
  FeriePerson _person = FeriePerson.matteo;

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmt(DateTime d) {
    final x = _onlyDate(d);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return "${x.year}-$mm-$dd";
  }

  String _personLabel(FeriePerson p) {
    switch (p) {
      case FeriePerson.matteo:
        return "Matteo";
      case FeriePerson.chiara:
        return "Chiara";
    }
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required String helpText,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: helpText,
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );
    if (picked == null) return null;
    return _onlyDate(picked);
  }

  Future<void> _addPeriod() async {
    final now = _onlyDate(DateTime.now());

    final start = await _pickDate(
      initial: now,
      helpText: "Seleziona INIZIO ferie",
    );
    if (start == null) return;

    final end = await _pickDate(
      initial: start,
      helpText: "Seleziona FINE ferie",
    );
    if (end == null) return;

    if (end.isBefore(start)) return;

    setState(() {
      widget.store.add(
        FeriePeriod(person: _person, startDay: start, endDay: end),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Aggiunto: ${_personLabel(_person)} ${_fmt(start)} → ${_fmt(end)}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store.periodsFor(_person);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ferie lunghe (periodi)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Inserisci periodi 1–3 settimane (modificabili/eliminabili).",
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),

            // Selettore persona
            Row(
              children: [
                const Text(
                  "Persona:",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                DropdownButton<FeriePerson>(
                  value: _person,
                  items: FeriePerson.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(_personLabel(p)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _person = v);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addPeriod,
                  icon: const Icon(Icons.add),
                  label: const Text("Aggiungi"),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            if (items.isEmpty)
              Text(
                "Nessun periodo inserito per ${_personLabel(_person)}.",
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              )
            else
              Column(
                children: items.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${_fmt(p.startDay)} → ${_fmt(p.endDay)}",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      "Stato suggerito: ${OverrideStatus.ferie.name}",
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    trailing: IconButton(
                      tooltip: "Elimina periodo",
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => widget.store.remove(p));
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
