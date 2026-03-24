// lib/widgets/alice_event_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/alice_event_store.dart';

class AliceEventPanel extends StatefulWidget {
  final DateTime selectedDay;
  final AliceEventStore store;
  final VoidCallback onChanged;

  const AliceEventPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.onChanged,
  });

  @override
  State<AliceEventPanel> createState() => _AliceEventPanelState();
}

class _AliceEventPanelState extends State<AliceEventPanel> {
  late AliceEventType _draftType;
  late DateTime _draftStart;
  late DateTime _draftEnd;

  int? _editingIndex;

  bool _isSavedPeriodsOpen = false;

  @override
  void initState() {
    super.initState();
    _loadDraftFromSelectedDay();
  }

  @override
  void didUpdateWidget(covariant AliceEventPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldDay = _onlyDate(oldWidget.selectedDay);
    final newDay = _onlyDate(widget.selectedDay);

    if (oldDay != newDay) {
      _loadDraftFromSelectedDay();
    }
  }

  void _loadDraftFromSelectedDay() {
    final current = _eventForSelectedDay();

    _editingIndex = null;

    if (current == null) {
      _draftType = AliceEventType.schoolNormal;
      _draftStart = _onlyDate(widget.selectedDay);
      _draftEnd = _onlyDate(widget.selectedDay);
      return;
    }

    _draftType = current.type;
    _draftStart = _onlyDate(current.start);
    _draftEnd = _onlyDate(current.end);
  }

  AliceEventPeriod? _eventForSelectedDay() {
    return widget.store.getEventForDay(widget.selectedDay);
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) {
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _fmtDateHuman(DateTime d) {
    return DateFormat('EEEE d MMMM yyyy', 'it_IT').format(d);
  }

  String _label(AliceEventType type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return "Scuola normale";
      case AliceEventType.vacation:
        return "Vacanza";
      case AliceEventType.schoolClosure:
        return "Chiusura scuola";
      case AliceEventType.sickness:
        return "Malattia";
      case AliceEventType.summerCamp:
        return "Centro estivo";
    }
  }

  Color _typeColor(AliceEventType type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return Colors.grey;
      case AliceEventType.vacation:
        return Colors.teal;
      case AliceEventType.schoolClosure:
        return Colors.deepOrange;
      case AliceEventType.sickness:
        return Colors.red;
      case AliceEventType.summerCamp:
        return Colors.green;
    }
  }

  IconData _typeIcon(AliceEventType type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return Icons.school_outlined;
      case AliceEventType.vacation:
        return Icons.beach_access_outlined;
      case AliceEventType.schoolClosure:
        return Icons.event_busy_outlined;
      case AliceEventType.sickness:
        return Icons.sick_outlined;
      case AliceEventType.summerCamp:
        return Icons.park_outlined;
    }
  }

  Future<void> _pickDraftStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftStart,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Seleziona data inizio',
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    final normalized = _onlyDate(picked);

    setState(() {
      _draftStart = normalized;
      if (_draftEnd.isBefore(_draftStart)) {
        _draftEnd = _draftStart;
      }
    });
  }

  Future<void> _pickDraftEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftEnd,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Seleziona data fine',
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    final normalized = _onlyDate(picked);

    setState(() {
      _draftEnd = normalized;
      if (_draftEnd.isBefore(_draftStart)) {
        _draftStart = _draftEnd;
      }
    });
  }

  void _startEditingSavedPeriod(int index) {
    final e = widget.store.events[index];

    setState(() {
      _editingIndex = index;
      _draftType = e.type;
      _draftStart = _onlyDate(e.start);
      _draftEnd = _onlyDate(e.end);
    });
  }

  void _cancelEditing() {
    setState(() {
      _loadDraftFromSelectedDay();
    });
  }

  void _saveDraftPeriod() {
    if (_editingIndex != null) {
      final index = _editingIndex!;
      if (_draftType == AliceEventType.schoolNormal) {
        widget.store.removeEventAt(index);
      } else {
        widget.store.updateEvent(
          index,
          AliceEventPeriod(
            start: _draftStart,
            end: _draftEnd,
            type: _draftType,
          ),
        );
      }
    } else {
      if (_draftType != AliceEventType.schoolNormal) {
        widget.store.addEvent(
          AliceEventPeriod(
            start: _draftStart,
            end: _draftEnd,
            type: _draftType,
          ),
        );
      }
    }

    widget.onChanged();

    setState(() {
      _loadDraftFromSelectedDay();
    });
  }

  void _clearEvent() {
    final events = widget.store.events;

    for (int i = events.length - 1; i >= 0; i--) {
      if (events[i].includesDay(widget.selectedDay)) {
        widget.store.removeEventAt(i);
      }
    }

    widget.onChanged();

    setState(() {
      _loadDraftFromSelectedDay();
    });
  }

  void _removeSavedPeriodAt(int index) {
    widget.store.removeEventAt(index);
    widget.onChanged();

    setState(() {
      _loadDraftFromSelectedDay();
    });
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.black.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _eventForSelectedDay();
    final events = widget.store.events;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eventi Alice",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Gestisci i periodi speciali di Alice e lo stato reale del giorno selezionato.",
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 14),

            _buildInfoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    "Giorno selezionato",
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fmtDateHuman(widget.selectedDay),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_editingIndex != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Modalità modifica periodo salvato",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelEditing,
                      child: const Text("Annulla"),
                    ),
                  ],
                ),
              ),

            _buildSectionTitle(
              "Editor periodo",
              icon: Icons.edit_calendar_outlined,
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<AliceEventType>(
              value: _draftType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Tipo evento Alice",
                border: OutlineInputBorder(),
              ),
              items: AliceEventType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(_typeIcon(t), size: 18, color: _typeColor(t)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_label(t))),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _draftType = v;
                });
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDraftStart,
                    icon: const Icon(Icons.event),
                    label: Text("Inizio: ${_fmtDate(_draftStart)}"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDraftEnd,
                    icon: const Icon(Icons.event_available),
                    label: Text("Fine: ${_fmtDate(_draftEnd)}"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildInfoBox(
              backgroundColor: _draftType == AliceEventType.schoolNormal
                  ? Colors.grey.withOpacity(0.08)
                  : _typeColor(_draftType).withOpacity(0.08),
              borderColor: _draftType == AliceEventType.schoolNormal
                  ? Colors.grey.withOpacity(0.25)
                  : _typeColor(_draftType).withOpacity(0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _typeIcon(_draftType),
                        size: 18,
                        color: _typeColor(_draftType),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tipo selezionato: ${_label(_draftType)}",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_draftType == AliceEventType.schoolNormal)
                    Text(
                      _editingIndex != null
                          ? "Se salvi con 'Scuola normale', il periodo in modifica verrà rimosso."
                          : "Se salvi con 'Scuola normale', l’evento attivo sul giorno selezionato verrà rimosso.",
                      style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    ),
                  if (_draftType != AliceEventType.schoolNormal)
                    Text(
                      "Periodo da salvare: ${_fmtDate(_draftStart)} → ${_fmtDate(_draftEnd)}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveDraftPeriod,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _editingIndex != null
                          ? "Salva modifica"
                          : "Salva periodo",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildSectionTitle(
              "Stato del giorno selezionato",
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: 10),

            if (current == null)
              _buildInfoBox(
                child: Text(
                  "Stato attuale: Scuola normale.",
                  style: TextStyle(color: Colors.black.withOpacity(0.75)),
                ),
              ),

            if (current != null)
              _buildInfoBox(
                backgroundColor: _typeColor(current.type).withOpacity(0.08),
                borderColor: _typeColor(current.type).withOpacity(0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _typeIcon(current.type),
                          size: 18,
                          color: _typeColor(current.type),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Evento attivo: ${_label(current.type)}",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Periodo attivo: ${_fmtDate(current.start)} → ${_fmtDate(current.end)}",
                      style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _clearEvent,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Rimuovi evento attivo"),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _isSavedPeriodsOpen = !_isSavedPeriodsOpen;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSectionTitle(
                        "Periodi salvati Alice",
                        icon: Icons.list_alt_outlined,
                      ),
                    ),
                    Icon(
                      _isSavedPeriodsOpen
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (_isSavedPeriodsOpen && events.isEmpty)
              _buildInfoBox(
                child: Text(
                  "Nessun periodo salvato.",
                  style: TextStyle(color: Colors.black.withOpacity(0.65)),
                ),
              ),

            if (_isSavedPeriodsOpen && events.isNotEmpty)
              ...List.generate(events.length, (index) {
                final e = events[index];
                final activeOnSelectedDay = e.includesDay(widget.selectedDay);
                final isEditingThis = _editingIndex == index;

                final cardColor = isEditingThis
                    ? Colors.orange
                    : activeOnSelectedDay
                    ? Colors.blue
                    : _typeColor(e.type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardColor.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _typeIcon(e.type),
                            size: 18,
                            color: _typeColor(e.type),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _label(e.type),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_fmtDate(e.start)} → ${_fmtDate(e.end)}",
                        style: TextStyle(color: Colors.black.withOpacity(0.7)),
                      ),
                      if (activeOnSelectedDay) ...[
                        const SizedBox(height: 6),
                        const Text(
                          "Attivo sul giorno selezionato",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (isEditingThis) ...[
                        const SizedBox(height: 6),
                        const Text(
                          "Periodo in modifica",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _startEditingSavedPeriod(index),
                              icon: const Icon(Icons.edit),
                              label: const Text("Modifica"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _removeSavedPeriodAt(index),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text("Rimuovi"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
