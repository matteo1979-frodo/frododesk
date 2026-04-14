// lib/widgets/alice_event_panel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/alice_event_store.dart';
import '../logic/summer_camp_special_event_store.dart';

class AliceEventPanel extends StatefulWidget {
  final DateTime selectedDay;
  final AliceEventStore store;
  final SummerCampSpecialEventStore summerCampSpecialEventStore;
  final VoidCallback onChanged;

  const AliceEventPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.summerCampSpecialEventStore,
    required this.onChanged,
  });

  @override
  State<AliceEventPanel> createState() => _AliceEventPanelState();
}

class _AliceEventPanelState extends State<AliceEventPanel> {
  late AliceEventType _draftType;
  late DateTime _draftStart;
  late DateTime _draftEnd;

  TimeOfDay _draftSummerCampStart = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _draftSummerCampEnd = const TimeOfDay(hour: 16, minute: 30);

  int? _editingIndex;

  bool _isSavedPeriodsOpen = false;
  bool _isEditorOpen = false;
  final Set<int> _expandedSavedPeriodIndexes = <int>{};

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
    _isEditorOpen = false;

    if (current == null) {
      _draftType = AliceEventType.schoolNormal;
      _draftStart = _onlyDate(widget.selectedDay);
      _draftEnd = _onlyDate(widget.selectedDay);
      _draftSummerCampStart = const TimeOfDay(hour: 8, minute: 30);
      _draftSummerCampEnd = const TimeOfDay(hour: 16, minute: 30);
      return;
    }

    _draftType = current.type;
    _draftStart = _onlyDate(current.start);
    _draftEnd = _onlyDate(current.end);
    _draftSummerCampStart =
        current.summerCampStart ?? const TimeOfDay(hour: 8, minute: 30);
    _draftSummerCampEnd =
        current.summerCampEnd ?? const TimeOfDay(hour: 16, minute: 30);
  }

  AliceEventPeriod? _eventForSelectedDay() {
    return widget.store.getEventForDay(widget.selectedDay);
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) {
    return DateFormat('dd-MM-yyyy').format(d);
  }

  String _fmtTime(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
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

  Future<void> _pickDraftSchoolStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 25),
      helpText: 'Scuola normale • ORARIO INGRESSO',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );

    if (picked == null) return;

    setState(() {
      _draftSummerCampStart = picked;
    });
  }

  Future<void> _pickDraftSummerCampStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _draftSummerCampStart,
      helpText: 'Centro estivo • ORARIO INGRESSO',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );

    if (picked == null) return;

    final newStartMinutes = picked.hour * 60 + picked.minute;
    final currentEndMinutes =
        _draftSummerCampEnd.hour * 60 + _draftSummerCampEnd.minute;

    setState(() {
      _draftSummerCampStart = picked;
      if (newStartMinutes >= currentEndMinutes) {
        _draftSummerCampEnd = TimeOfDay(
          hour: picked.hour + 1 <= 23 ? picked.hour + 1 : picked.hour,
          minute: picked.minute,
        );
      }
    });
  }

  Future<void> _pickDraftSchoolEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 25),
      helpText: 'Scuola normale • ORARIO USCITA',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );

    if (picked == null) return;

    setState(() {
      _draftSummerCampEnd = picked;
    });
  }

  Future<void> _pickDraftSummerCampEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _draftSummerCampEnd,
      helpText: 'Centro estivo • ORARIO USCITA',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );

    if (picked == null) return;

    final currentStartMinutes =
        _draftSummerCampStart.hour * 60 + _draftSummerCampStart.minute;
    final newEndMinutes = picked.hour * 60 + picked.minute;

    if (newEndMinutes <= currentStartMinutes) return;

    setState(() {
      _draftSummerCampEnd = picked;
    });
  }

  void _startEditingSavedPeriod(int index) {
    final e = widget.store.events[index];

    setState(() {
      _editingIndex = index;
      _draftType = e.type;
      _draftStart = _onlyDate(e.start);
      _draftEnd = _onlyDate(e.end);
      _draftSummerCampStart =
          e.summerCampStart ?? const TimeOfDay(hour: 8, minute: 30);
      _draftSummerCampEnd =
          e.summerCampEnd ?? const TimeOfDay(hour: 16, minute: 30);
      _isEditorOpen = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _loadDraftFromSelectedDay();
    });
  }

  void _saveDraftPeriod() {
    final needsCustomTimes =
        _draftType == AliceEventType.summerCamp ||
        _draftType == AliceEventType.schoolNormal;

    final newEvent = AliceEventPeriod(
      start: _draftStart,
      end: _draftEnd,
      type: _draftType,
      summerCampStart: needsCustomTimes ? _draftSummerCampStart : null,
      summerCampEnd: needsCustomTimes ? _draftSummerCampEnd : null,
    );

    if (_editingIndex != null) {
      widget.store.updateEvent(_editingIndex!, newEvent);
    } else {
      widget.store.addEvent(newEvent);
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
      _expandedSavedPeriodIndexes.remove(index);
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

  Widget _buildCurrentStateCard(AliceEventPeriod? current) {
    if (current == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.45)),
        ),
        child: Row(
          children: [
            Icon(
              _typeIcon(AliceEventType.schoolNormal),
              size: 18,
              color: _typeColor(AliceEventType.schoolNormal),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Evento attivo Alice: Nessun evento speciale",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _typeColor(AliceEventType.schoolNormal),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _typeColor(current.type).withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _typeColor(current.type).withOpacity(0.45)),
      ),
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
                  "Evento attivo Alice: ${_label(current.type)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: _typeColor(current.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Periodo attivo: ${_fmtDate(current.start)} → ${_fmtDate(current.end)}",
            style: TextStyle(
              color: Colors.black.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (current.type == AliceEventType.summerCamp) ...[
            const SizedBox(height: 6),
            Text(
              "Orario centro estivo: ${_fmtTime(current.summerCampStart ?? const TimeOfDay(hour: 8, minute: 30))} → ${_fmtTime(current.summerCampEnd ?? const TimeOfDay(hour: 16, minute: 30))}",
              style: TextStyle(
                color: Colors.black.withOpacity(0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _clearEvent,
            icon: const Icon(Icons.delete_outline),
            label: const Text("Rimuovi evento attivo"),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPeriodTile(int index, AliceEventPeriod e) {
    final activeOnSelectedDay = e.includesDay(widget.selectedDay);
    final isEditingThis = _editingIndex == index;
    final isExpanded = _expandedSavedPeriodIndexes.contains(index);

    final cardColor = isEditingThis
        ? Colors.orange
        : activeOnSelectedDay
        ? Colors.blue
        : _typeColor(e.type);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedSavedPeriodIndexes.remove(index);
          } else {
            _expandedSavedPeriodIndexes
              ..clear()
              ..add(index);
          }
        });
      },
      child: Container(
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
                Icon(_typeIcon(e.type), size: 18, color: _typeColor(e.type)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(e.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_fmtDate(e.start)} → ${_fmtDate(e.end)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeOnSelectedDay) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.visibility, size: 18, color: Colors.blue),
                ],
                if (isEditingThis) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 18, color: Colors.orange),
                ],
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.black54,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              if (e.type == AliceEventType.summerCamp) ...[
                Text(
                  "Orario: ${_fmtTime(e.summerCampStart ?? const TimeOfDay(hour: 8, minute: 30))} → ${_fmtTime(e.summerCampEnd ?? const TimeOfDay(hour: 16, minute: 30))}",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (activeOnSelectedDay) ...[
                const Text(
                  "Attivo sul giorno selezionato",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
              ],
              if (isEditingThis) ...[
                const Text(
                  "Periodo in modifica",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
              ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildEditorPreviewBox() {
    return _buildInfoBox(
      backgroundColor: _draftType == AliceEventType.schoolNormal
          ? Colors.grey.withOpacity(0.08)
          : _typeColor(_draftType).withOpacity(0.08),
      borderColor: _draftType == AliceEventType.schoolNormal
          ? Colors.grey.withOpacity(0.25)
          : _typeColor(_draftType).withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Periodo da salvare: ${_fmtDate(_draftStart)} → ${_fmtDate(_draftEnd)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_draftType == AliceEventType.summerCamp) ...[
            const SizedBox(height: 8),
            Text(
              "Orario base: ${_fmtTime(_draftSummerCampStart)} → ${_fmtTime(_draftSummerCampEnd)}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _eventForSelectedDay();
    final today = _onlyDate(DateTime.now());

    bool isPastPeriod(AliceEventPeriod event) {
      final end = _onlyDate(event.end);
      return end.isBefore(today);
    }

    final events = widget.store.events
        .where((event) => !isPastPeriod(event))
        .toList();
    final specialSummerCampEvents = widget.summerCampSpecialEventStore.getAll();

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

            _buildCurrentStateCard(current),

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
              value: _draftType == AliceEventType.schoolNormal
                  ? null
                  : _draftType,
              selectedItemBuilder: (context) {
                return AliceEventType.values.map((t) {
                  final text = t == AliceEventType.schoolNormal
                      ? "Seleziona evento"
                      : _label(t);

                  return Row(
                    children: [
                      Icon(_typeIcon(t), size: 18, color: _typeColor(t)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text)),
                    ],
                  );
                }).toList();
              },
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Imposta nuovo stato",
                border: OutlineInputBorder(),
              ),
              items: AliceEventType.values
                  .where((t) => t != AliceEventType.schoolNormal)
                  .map((t) {
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
                  })
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _draftType = v;
                  _isEditorOpen = true;
                });
              },
            ),

            if (_isEditorOpen) ...[
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

              if (_draftType == AliceEventType.summerCamp ||
                  _draftType == AliceEventType.schoolNormal) ...[
                const SizedBox(height: 12),
                _buildInfoBox(
                  backgroundColor: Colors.green.withOpacity(0.08),
                  borderColor: Colors.green.withOpacity(0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        _draftType == AliceEventType.schoolNormal
                            ? "Orari scuola"
                            : "Orari centro estivo",
                        icon: Icons.access_time,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _draftType == AliceEventType.schoolNormal
                                  ? _pickDraftSchoolStart
                                  : _pickDraftSummerCampStart,
                              icon: const Icon(Icons.login),
                              label: Text(
                                _draftType == AliceEventType.schoolNormal
                                    ? "Ingresso scuola: ${_fmtTime(_draftSummerCampStart)}"
                                    : "Ingresso: ${_fmtTime(_draftSummerCampStart)}",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDraftSummerCampEnd,
                              icon: const Icon(Icons.logout),
                              label: Text(
                                _draftType == AliceEventType.schoolNormal
                                    ? "Uscita scuola: ${_fmtTime(_draftSummerCampEnd)}"
                                    : "Uscita: ${_fmtTime(_draftSummerCampEnd)}",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              _buildEditorPreviewBox(),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelEditing,
                      icon: const Icon(Icons.close),
                      label: const Text("Annulla"),
                    ),
                  ),
                ],
              ),
            ],

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

            if (_isSavedPeriodsOpen && specialSummerCampEvents.isNotEmpty)
              _buildInfoBox(
                backgroundColor: Colors.green.withOpacity(0.06),
                borderColor: Colors.green.withOpacity(0.20),
                child: Text(
                  "Eventi speciali centro estivo salvati: ${specialSummerCampEvents.length}",
                  style: TextStyle(color: Colors.black.withOpacity(0.75)),
                ),
              ),

            if (_isSavedPeriodsOpen && events.isEmpty)
              _buildInfoBox(
                child: Text(
                  "Nessun periodo salvato.",
                  style: TextStyle(color: Colors.black.withOpacity(0.65)),
                ),
              ),

            if (_isSavedPeriodsOpen && events.isNotEmpty)
              ...List.generate(
                events.length,
                (index) => _buildSavedPeriodTile(index, events[index]),
              ),
          ],
        ),
      ),
    );
  }
}
