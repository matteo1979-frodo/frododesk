// lib/widgets/ferie_period_panel.dart
import 'package:flutter/material.dart';

import '../logic/ferie_period_store.dart';
import '../models/day_override.dart';

class FeriePeriodPanel extends StatefulWidget {
  final FeriePeriodStore store;
  final DateTime? selectedDay;
  final VoidCallback? onChanged;

  const FeriePeriodPanel({
    super.key,
    required this.store,
    this.selectedDay,
    this.onChanged,
  });

  @override
  State<FeriePeriodPanel> createState() => _FeriePeriodPanelState();
}

class _FeriePeriodPanelState extends State<FeriePeriodPanel> {
  FeriePerson _person = FeriePerson.matteo;
  bool _isOpen = false;
  final Set<int> _expandedIndexes = <int>{};

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmt(DateTime d) {
    final x = _onlyDate(d);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return "$dd-$mm-${x.year}";
  }

  String _personLabel(FeriePerson p) {
    switch (p) {
      case FeriePerson.matteo:
        return "Matteo";
      case FeriePerson.chiara:
        return "Chiara";
    }
  }

  bool _isActiveOnSelectedDay(FeriePeriod p) {
    final selected = widget.selectedDay;
    if (selected == null) return false;
    final d0 = _onlyDate(selected);
    return !d0.isBefore(_onlyDate(p.startDay)) &&
        !d0.isAfter(_onlyDate(p.endDay));
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
      _isOpen = true;
    });

    widget.onChanged?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Aggiunto: ${_personLabel(_person)} ${_fmt(start)} → ${_fmt(end)}",
        ),
      ),
    );
  }

  Future<void> _editPeriod(FeriePeriod p) async {
    DateTime tempStart = _onlyDate(p.startDay);
    DateTime tempEnd = _onlyDate(p.endDay);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifica ferie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: _personLabel(p.person),
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Persona'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(
                                initial: tempStart,
                                helpText: "Seleziona INIZIO ferie",
                              );
                              if (picked == null) return;

                              setDialogState(() {
                                tempStart = picked;
                                if (tempEnd.isBefore(tempStart)) {
                                  tempEnd = tempStart;
                                }
                              });
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text('Dal ${_fmt(tempStart)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(
                                initial: tempEnd,
                                helpText: "Seleziona FINE ferie",
                              );
                              if (picked == null) return;

                              setDialogState(() {
                                tempEnd = picked;
                              });
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text('Al ${_fmt(tempEnd)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annulla'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (tempEnd.isBefore(tempStart)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La data fine non può essere prima della data inizio.',
                          ),
                        ),
                      );
                      return;
                    }

                    widget.store.remove(p);
                    widget.store.add(
                      FeriePeriod(
                        person: p.person,
                        startDay: tempStart,
                        endDay: tempEnd,
                      ),
                    );

                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salva modifica'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      setState(() {});
      widget.onChanged?.call();
    }
  }

  void _removePeriod(FeriePeriod p) {
    setState(() {
      widget.store.remove(p);
    });

    widget.onChanged?.call();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Periodo ferie rimosso.')));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store.all();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _isOpen = !_isOpen;
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ferie lunghe (periodi)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Inserisci periodi 1–3 settimane (modificabili/eliminabili).",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(_isOpen ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_isOpen) ...[
              const SizedBox(height: 12),

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
                      setState(() {
                        _person = v;
                        _expandedIndexes.clear();
                      });
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
                ...List.generate(items.length, (index) {
                  final p = items[index];
                  final isActive = _isActiveOnSelectedDay(p);
                  final isExpanded = _expandedIndexes.contains(index);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedIndexes.remove(index);
                        } else {
                          _expandedIndexes
                            ..clear()
                            ..add(index);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.blue : Colors.teal)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isActive ? Colors.blue : Colors.teal)
                              .withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.beach_access_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _personLabel(p.person),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${_fmt(p.startDay)} → ${_fmt(p.endDay)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Stato suggerito: ${OverrideStatus.ferie.name}",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.72),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isActive) ...[
                              const Text(
                                "Attivo sul giorno selezionato",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _editPeriod(p),
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Modifica"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _removePeriod(p),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text("Rimuovi"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
