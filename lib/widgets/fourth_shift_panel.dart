import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/fourth_shift_store.dart';
import '../models/fourth_shift_period.dart';

class FourthShiftPanel extends StatefulWidget {
  final FourthShiftStore store;
  final VoidCallback onChanged;

  const FourthShiftPanel({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  State<FourthShiftPanel> createState() => _FourthShiftPanelState();
}

class _FourthShiftPanelState extends State<FourthShiftPanel> {
  String _selectedPersonId = 'chiara';
  FourthShiftCycleWeek _selectedWeek = FourthShiftCycleWeek.week1;

  DateTime? _startDate;
  DateTime? _endDate;

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  String _personLabel(String personId) {
    switch (personId) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      default:
        return personId;
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
    _selectedPersonId = 'chiara';
    _selectedWeek = FourthShiftCycleWeek.week1;
    _startDate = null;
    _endDate = null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Quarta Squadra'),
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
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() {
                          _selectedPersonId = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FourthShiftCycleWeek>(
                      value: _selectedWeek,
                      decoration: const InputDecoration(
                        labelText: 'Settimana iniziale del ciclo',
                      ),
                      items: FourthShiftCycleWeek.values.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w.label));
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() {
                          _selectedWeek = v;
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

                    final period = FourthShiftPeriod(
                      personId: _selectedPersonId,
                      startDate: _startDate!,
                      endDate: _endDate!,
                      initialCycleWeek: _selectedWeek,
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
        const SnackBar(content: Text('Periodo Quarta Squadra salvato.')),
      );
    }
  }

  void _removePeriod(FourthShiftPeriod period) {
    setState(() {
      widget.store.removePeriod(period);
    });

    widget.onChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Periodo Quarta Squadra rimosso.')),
    );
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
              'Quarta Squadra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestisci i periodi attivi di Quarta Squadra. Il form di inserimento si apre solo quando serve.',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAddPeriodDialog,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apri Quarta Squadra'),
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
                'Nessun periodo Quarta Squadra inserito.',
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
                          '${_personLabel(p.personId)} • ${p.initialCycleWeek.label}\n${_fmtDate(p.startDate)} → ${_fmtDate(p.endDate)}',
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
