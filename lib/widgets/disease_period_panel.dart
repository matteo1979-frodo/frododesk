import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/disease_period_store.dart';
import '../models/disease_period.dart';

class DiseasePeriodPanel extends StatefulWidget {
  final DateTime selectedDay;
  final DiseasePeriodStore store;
  final VoidCallback onChanged;

  const DiseasePeriodPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.onChanged,
  });

  @override
  State<DiseasePeriodPanel> createState() => _DiseasePeriodPanelState();
}

class _DiseasePeriodPanelState extends State<DiseasePeriodPanel> {
  String _selectedPersonId = 'matteo';
  DiseaseType _selectedType = DiseaseType.mild;

  DateTime? _startDate;
  DateTime? _endDate;

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  String _personLabel(String personId) {
    switch (personId) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'sandra':
        return 'Sandra';
      case 'alice':
        return 'Alice';
      default:
        return personId;
    }
  }

  String _typeLabel(DiseaseType type) {
    switch (type) {
      case DiseaseType.mild:
        return 'Malattia leggera';
      case DiseaseType.bed:
        return 'Malattia a letto';
    }
  }

  Future<void> _pickStartDateInDialog(StateSetter setLocalState) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Seleziona data inizio',
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    setLocalState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDateInDialog(StateSetter setLocalState) async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Seleziona data fine',
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    setLocalState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _openAddPeriodDialog() async {
    _selectedPersonId = 'matteo';
    _selectedType = DiseaseType.mild;
    _startDate = null;
    _endDate = null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Malattia'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedPersonId,
                      decoration: const InputDecoration(labelText: 'Persona'),
                      items: const [
                        DropdownMenuItem(
                          value: 'matteo',
                          child: Text('Matteo'),
                        ),
                        DropdownMenuItem(
                          value: 'chiara',
                          child: Text('Chiara'),
                        ),
                        DropdownMenuItem(
                          value: 'sandra',
                          child: Text('Sandra'),
                        ),
                        DropdownMenuItem(value: 'alice', child: Text('Alice')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() {
                          _selectedPersonId = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DiseaseType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo malattia',
                      ),
                      items: DiseaseType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() {
                          _selectedType = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _pickStartDateInDialog(setLocalState),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _startDate == null
                                  ? 'Data inizio'
                                  : 'Dal ${_fmtDate(_startDate!)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _pickEndDateInDialog(setLocalState),
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _endDate == null
                                  ? 'Data fine'
                                  : 'Al ${_fmtDate(_endDate!)}',
                            ),
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
                    if (_startDate == null || _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleziona data inizio e data fine.'),
                        ),
                      );
                      return;
                    }

                    if (_endDate!.isBefore(_startDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La data fine non può essere prima della data inizio.',
                          ),
                        ),
                      );
                      return;
                    }

                    final period = DiseasePeriod(
                      personId: _selectedPersonId,
                      type: _selectedType,
                      startDate: _startDate!,
                      endDate: _endDate!,
                    );

                    try {
                      widget.store.addPeriod(period);
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Salva periodo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      setState(() {});
      widget.onChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periodo malattia salvato.')),
      );
    }
  }

  void _removePeriod(DiseasePeriod period) {
    setState(() {
      widget.store.removePeriod(period);
    });

    widget.onChanged();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Periodo malattia rimosso.')));
  }

  @override
  Widget build(BuildContext context) {
    final periods = widget.store.all;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Malattia a periodo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestisci i periodi di malattia. Il form di inserimento si apre solo quando serve.',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAddPeriodDialog,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apri Malattia'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Periodi salvati',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (periods.isEmpty)
              Text(
                'Nessun periodo malattia inserito.',
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              )
            else
              ...periods.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_personLabel(p.personId)} • ${_typeLabel(p.type)}\n${_fmtDate(p.startDate)} → ${_fmtDate(p.endDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePeriod(p),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Rimuovi periodo',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}