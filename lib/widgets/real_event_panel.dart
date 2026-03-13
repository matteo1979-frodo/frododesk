import 'package:flutter/material.dart';

import '../logic/real_event_store.dart';
import '../models/real_event.dart';

class RealEventPanel extends StatelessWidget {
  final DateTime selectedDay;
  final RealEventStore store;
  final VoidCallback onChanged;

  const RealEventPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.onChanged,
  });

  String _fmt(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _personLabel(String? personKey) {
    switch (personKey) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'alice':
        return 'Alice';
      case 'sandra':
        return 'Sandra';
      default:
        return 'Nessuna persona';
    }
  }

  Future<void> _addSimpleEvent(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final result = await showDialog<_EventDraft>(
      context: context,
      builder: (context) {
        TimeOfDay? start;
        TimeOfDay? end;
        String? personKey;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Nuovo evento reale"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Titolo evento",
                        hintText: "Es. Visita Bologna / Cambio gomme",
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: personKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Persona coinvolta",
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text("Nessuna persona"),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'matteo',
                          child: Text("Matteo"),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'chiara',
                          child: Text("Chiara"),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'alice',
                          child: Text("Alice"),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'sandra',
                          child: Text("Sandra"),
                        ),
                      ],
                      onChanged: (value) {
                        setLocalState(() => personKey = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    start ??
                                    const TimeOfDay(hour: 9, minute: 0),
                                helpText: "Ora INIZIO",
                                cancelText: "Annulla",
                                confirmText: "OK",
                              );
                              if (picked == null) return;
                              setLocalState(() => start = picked);
                            },
                            child: Text(
                              start == null
                                  ? "Ora inizio"
                                  : "Inizio ${_fmt(start!)}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    end ?? const TimeOfDay(hour: 10, minute: 0),
                                helpText: "Ora FINE",
                                cancelText: "Annulla",
                                confirmText: "OK",
                              );
                              if (picked == null) return;
                              setLocalState(() => end = picked);
                            },
                            child: Text(
                              end == null ? "Ora fine" : "Fine ${_fmt(end!)}",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        hintText: "Dettagli opzionali",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    Navigator.of(context).pop(
                      _EventDraft(
                        title: title,
                        personKey: personKey,
                        startTime: start,
                        endTime: end,
                        notes: notesCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    notesCtrl.dispose();

    if (result == null) return;

    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    final event = RealEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startDate: normalizedDay,
      endDate: normalizedDay,
      title: result.title,
      startTime: result.startTime,
      endTime: result.endTime,
      personKey: result.personKey,
      notes: result.notes.isEmpty ? null : result.notes,
    );

    store.addEvent(event);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final events = store.eventsForDay(selectedDay);

    final matteoConflicts = store.overlappingPairsForPersonOnDay(
      day: selectedDay,
      personKey: 'matteo',
    );
    final chiaraConflicts = store.overlappingPairsForPersonOnDay(
      day: selectedDay,
      personKey: 'chiara',
    );
    final aliceConflicts = store.overlappingPairsForPersonOnDay(
      day: selectedDay,
      personKey: 'alice',
    );
    final sandraConflicts = store.overlappingPairsForPersonOnDay(
      day: selectedDay,
      personKey: 'sandra',
    );

    final hasAnyConflict =
        matteoConflicts.isNotEmpty ||
        chiaraConflicts.isNotEmpty ||
        aliceConflicts.isNotEmpty ||
        sandraConflicts.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eventi del giorno",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Visite, viaggi, appuntamenti e impegni reali.",
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),

            if (hasAnyConflict) ...[
              if (matteoConflicts.isNotEmpty)
                _ConflictBox(personLabel: "Matteo", conflicts: matteoConflicts),
              if (chiaraConflicts.isNotEmpty)
                _ConflictBox(personLabel: "Chiara", conflicts: chiaraConflicts),
              if (aliceConflicts.isNotEmpty)
                _ConflictBox(personLabel: "Alice", conflicts: aliceConflicts),
              if (sandraConflicts.isNotEmpty)
                _ConflictBox(personLabel: "Sandra", conflicts: sandraConflicts),
              const SizedBox(height: 12),
            ],

            if (events.isEmpty)
              Text(
                "Nessun evento reale inserito per questo giorno.",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),

            if (events.isNotEmpty) ...[
              for (int i = 0; i < events.length; i++) ...[
                _RealEventTile(
                  event: events[i],
                  onDelete: () {
                    store.removeEvent(events[i].id);
                    onChanged();
                  },
                ),
                if (i != events.length - 1) const Divider(),
              ],
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _addSimpleEvent(context),
              icon: const Icon(Icons.add),
              label: const Text("Aggiungi evento"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBox extends StatelessWidget {
  final String personLabel;
  final List<RealEventConflict> conflicts;

  const _ConflictBox({required this.personLabel, required this.conflicts});

  String _fmt(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _eventLabel(RealEvent event) {
    final start = event.startTime != null ? _fmt(event.startTime!) : "--:--";
    final end = event.endTime != null ? _fmt(event.endTime!) : "--:--";
    return "${event.title} ($start–$end)";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Conflitto eventi rilevato",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Persona coinvolta: $personLabel",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < conflicts.length; i++) ...[
            Text("• ${_eventLabel(conflicts[i].first)}"),
            Text("• ${_eventLabel(conflicts[i].second)}"),
            if (i != conflicts.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RealEventTile extends StatelessWidget {
  final RealEvent event;
  final VoidCallback onDelete;

  const _RealEventTile({required this.event, required this.onDelete});

  String _fmt(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _personLabel(String? personKey) {
    switch (personKey) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'alice':
        return 'Alice';
      case 'sandra':
        return 'Sandra';
      default:
        return 'Nessuna persona';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTimes = event.startTime != null || event.endTime != null;
    final hasNotes = (event.notes ?? '').trim().isNotEmpty;
    final hasPerson =
        event.personKey != null && event.personKey!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.event_note, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (hasPerson)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Persona: ${_personLabel(event.personKey)}",
                      style: TextStyle(color: Colors.black.withOpacity(0.68)),
                    ),
                  ),
                if (hasTimes)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "${event.startTime != null ? _fmt(event.startTime!) : "--:--"}"
                      " – "
                      "${event.endTime != null ? _fmt(event.endTime!) : "--:--"}",
                      style: TextStyle(color: Colors.black.withOpacity(0.65)),
                    ),
                  ),
                if (hasNotes)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.notes!.trim(),
                      style: TextStyle(color: Colors.black.withOpacity(0.72)),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Elimina evento",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EventDraft {
  final String title;
  final String? personKey;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String notes;

  const _EventDraft({
    required this.title,
    required this.personKey,
    required this.startTime,
    required this.endTime,
    required this.notes,
  });
}
