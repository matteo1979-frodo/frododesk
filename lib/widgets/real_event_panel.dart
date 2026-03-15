import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/real_event_store.dart';
import '../models/real_event.dart';

class RealEventPanel extends StatefulWidget {
  final DateTime selectedDay;
  final RealEventStore store;
  final VoidCallback onChanged;

  const RealEventPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.onChanged,
  });

  @override
  State<RealEventPanel> createState() => _RealEventPanelState();
}

class _RealEventPanelState extends State<RealEventPanel> {
  bool _isExpanded = false;

  DateTime get selectedDay => widget.selectedDay;
  RealEventStore get store => widget.store;
  VoidCallback get onChanged => widget.onChanged;

  String _fmt(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _fmtDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

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
      case 'family':
        return 'Famiglia / Generale';
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
        DateTime startDate = _onlyDate(selectedDay);
        DateTime endDate = _onlyDate(selectedDay);
        bool allDay = true;

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
                        DropdownMenuItem<String?>(
                          value: 'family',
                          child: Text("Famiglia / Generale"),
                        ),
                      ],
                      onChanged: (value) {
                        setLocalState(() => personKey = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Tutto il giorno",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      value: allDay,
                      onChanged: (value) {
                        setLocalState(() {
                          allDay = value;
                          if (allDay) {
                            start = null;
                            end = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2024, 1, 1),
                                lastDate: DateTime(2035, 12, 31),
                                helpText: "Data INIZIO",
                                cancelText: "Annulla",
                                confirmText: "OK",
                                locale: const Locale('it', 'IT'),
                              );
                              if (picked == null) return;
                              setLocalState(() {
                                startDate = _onlyDate(picked);
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            },
                            child: Text("Inizio ${_fmtDate(startDate)}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2035, 12, 31),
                                helpText: "Data FINE",
                                cancelText: "Annulla",
                                confirmText: "OK",
                                locale: const Locale('it', 'IT'),
                              );
                              if (picked == null) return;
                              setLocalState(() {
                                endDate = _onlyDate(picked);
                              });
                            },
                            child: Text("Fine ${_fmtDate(endDate)}"),
                          ),
                        ),
                      ],
                    ),
                    if (!allDay) ...[
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
                                      end ??
                                      const TimeOfDay(hour: 10, minute: 0),
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
                    ],
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

                    if (!allDay && start != null && end != null) {
                      final startMin = start!.hour * 60 + start!.minute;
                      final endMin = end!.hour * 60 + end!.minute;
                      if (endMin <= startMin) return;
                    }

                    Navigator.of(context).pop(
                      _EventDraft(
                        title: title,
                        personKey: personKey,
                        startDate: startDate,
                        endDate: endDate,
                        startTime: allDay ? null : start,
                        endTime: allDay ? null : end,
                        notes: notesCtrl.text.trim(),
                        allDay: allDay,
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

    final event = RealEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startDate: _onlyDate(result.startDate),
      endDate: _onlyDate(result.endDate),
      title: result.title,
      startTime: result.startTime,
      endTime: result.endTime,
      personKey: result.personKey,
      notes: result.notes.isEmpty ? null : result.notes,
    );

    store.addEvent(event);
    onChanged();

    if (mounted) {
      setState(() {
        _isExpanded = true;
      });
    }
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
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: _isExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isExpanded = value;
                });
              },
              title: Text(
                "Eventi del giorno (${events.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                "Visite, viaggi, appuntamenti e impegni reali.",
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),
              children: [
                const SizedBox(height: 8),
                if (hasAnyConflict) ...[
                  if (matteoConflicts.isNotEmpty)
                    _ConflictBox(
                      personLabel: "Matteo",
                      conflicts: matteoConflicts,
                    ),
                  if (chiaraConflicts.isNotEmpty)
                    _ConflictBox(
                      personLabel: "Chiara",
                      conflicts: chiaraConflicts,
                    ),
                  if (aliceConflicts.isNotEmpty)
                    _ConflictBox(
                      personLabel: "Alice",
                      conflicts: aliceConflicts,
                    ),
                  if (sandraConflicts.isNotEmpty)
                    _ConflictBox(
                      personLabel: "Sandra",
                      conflicts: sandraConflicts,
                    ),
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
                        if (mounted) {
                          setState(() {});
                        }
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
    final start = event.startTime != null
        ? _fmt(event.startTime!)
        : "Tutto il giorno";
    final end = event.endTime != null ? _fmt(event.endTime!) : "";
    return end.isEmpty
        ? "${event.title} ($start)"
        : "${event.title} ($start–$end)";
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

  String _fmtDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
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
      case 'family':
        return 'Famiglia / Generale';
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

    final isMultiDay = event.startDate != event.endDate;

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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isMultiDay
                        ? "Periodo: ${_fmtDate(event.startDate)} – ${_fmtDate(event.endDate)}"
                        : "Data: ${_fmtDate(event.startDate)}",
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hasTimes
                        ? "${event.startTime != null ? _fmt(event.startTime!) : "--:--"}"
                              " – "
                              "${event.endTime != null ? _fmt(event.endTime!) : "--:--"}"
                        : "Tutto il giorno",
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
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String notes;
  final bool allDay;

  const _EventDraft({
    required this.title,
    required this.personKey,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.notes,
    required this.allDay,
  });
}
