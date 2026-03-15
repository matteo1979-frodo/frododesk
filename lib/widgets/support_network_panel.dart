import 'package:flutter/material.dart';

import '../logic/support_network_store.dart';
import '../logic/day_settings_store.dart';
import '../models/support_person.dart';

class SupportNetworkPanel extends StatefulWidget {
  final DateTime selectedDay;
  final SupportNetworkStore store;
  final DaySettingsStore daySettingsStore;
  final VoidCallback onChanged;

  const SupportNetworkPanel({
    super.key,
    required this.selectedDay,
    required this.store,
    required this.daySettingsStore,
    required this.onChanged,
  });

  @override
  State<SupportNetworkPanel> createState() => _SupportNetworkPanelState();
}

class _SupportNetworkPanelState extends State<SupportNetworkPanel> {
  final Set<String> _expandedIds = <String>{};
  bool _showInactivePeople = false;

  String _generateSupportId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'support_$now';
  }

  String _fmt(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  String _fmtDay(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }

  Future<void> _addPerson() async {
    final nameCtrl = TextEditingController();

    TimeOfDay start = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 18, minute: 0);

    final savedNames = widget.store.savedNames;

    final created = await showDialog<SupportPerson>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Aggiungi persona"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (savedNames.isNotEmpty)
                    DropdownButtonFormField<String>(
                      hint: const Text("Seleziona dalla rubrica"),
                      items: [
                        ...savedNames.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                        const DropdownMenuItem(
                          value: "__new__",
                          child: Text("+ Nuova persona"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        if (value == "__new__") {
                          nameCtrl.clear();
                        } else {
                          nameCtrl.text = value;
                        }

                        setLocalState(() {});
                      },
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nome persona",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (picked == null) return;
                            setLocalState(() {
                              start = picked;
                            });
                          },
                          child: Text("Inizio: ${_fmt(start)}"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (picked == null) return;
                            setLocalState(() {
                              end = picked;
                            });
                          },
                          child: Text("Fine: ${_fmt(end)}"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final startMin = start.hour * 60 + start.minute;
                    final endMin = end.hour * 60 + end.minute;
                    if (endMin <= startMin) return;

                    Navigator.of(context).pop(
                      SupportPerson(
                        id: _generateSupportId(),
                        name: name,
                        enabled: true,
                        start: start,
                        end: end,
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

    nameCtrl.dispose();

    if (created == null) return;

    setState(() {
      widget.store.addPerson(created);
      _expandedIds.add(created.id);
    });
    widget.onChanged();
  }

  Future<void> _editPerson(SupportPerson person) async {
    final nameCtrl = TextEditingController(text: person.name);

    TimeOfDay start = person.start;
    TimeOfDay end = person.end;
    bool enabled = person.enabled;

    final updated = await showDialog<SupportPerson>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Modifica persona"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nome persona",
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Attiva nella rete"),
                    value: enabled,
                    onChanged: (v) {
                      setLocalState(() {
                        enabled = v;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (picked == null) return;
                            setLocalState(() {
                              start = picked;
                            });
                          },
                          child: Text("Inizio: ${_fmt(start)}"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (picked == null) return;
                            setLocalState(() {
                              end = picked;
                            });
                          },
                          child: Text("Fine: ${_fmt(end)}"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final startMin = start.hour * 60 + start.minute;
                    final endMin = end.hour * 60 + end.minute;
                    if (endMin <= startMin) return;

                    Navigator.of(context).pop(
                      person.copyWith(
                        name: name,
                        enabled: enabled,
                        start: start,
                        end: end,
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

    nameCtrl.dispose();

    if (updated == null) return;

    setState(() {
      widget.store.updatePerson(person.id, updated);
    });
    widget.onChanged();
  }

  void _removePerson(SupportPerson person) {
    setState(() {
      widget.store.removePerson(person.id);
      widget.daySettingsStore.clearSupportPersonFromAllDays(person.id);
      _expandedIds.remove(person.id);
    });
    widget.onChanged();
  }

  void _togglePersonForSelectedDay(SupportPerson person, bool enabledToday) {
    setState(() {
      widget.daySettingsStore.setSupportPersonEnabledForDay(
        widget.selectedDay,
        person.id,
        enabledToday,
      );
    });
    widget.onChanged();
  }

  void _toggleExpanded(String personId) {
    setState(() {
      if (_expandedIds.contains(personId)) {
        _expandedIds.remove(personId);
      } else {
        _expandedIds.add(personId);
      }
    });
  }

  Widget _personRow(SupportPerson p) {
    final enabledToday = widget.daySettingsStore.isSupportPersonEnabledForDay(
      widget.selectedDay,
      p.id,
    );
    final isExpanded = _expandedIds.contains(p.id);

    final activeColor = p.enabled ? Colors.green : Colors.grey;
    final backgroundColor = p.enabled
        ? Colors.black.withOpacity(0.03)
        : Colors.grey.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleExpanded(p.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_fmt(p.start)}–${_fmt(p.end)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: p.enabled ? enabledToday : false,
                    onChanged: p.enabled
                        ? (v) => _togglePersonForSelectedDay(p, v)
                        : null,
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.black.withOpacity(0.65),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 12),
                  Text(
                    p.enabled ? "Presente nella rete" : "Non attiva nella rete",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editPerson(p),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Modifica"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _removePerson(p),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text("Rimuovi"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final people = widget.store.people;

    final activeToday = people.where((p) {
      if (!p.enabled) return false;
      return widget.daySettingsStore.isSupportPersonEnabledForDay(
        widget.selectedDay,
        p.id,
      );
    }).toList();

    final inactiveToday = people.where((p) {
      if (!p.enabled) return true;
      return !widget.daySettingsStore.isSupportPersonEnabledForDay(
        widget.selectedDay,
        p.id,
      );
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rete di Supporto",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Persone extra disponibili da contattare in caso di bisogno.",
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 6),
            Text(
              "Giorno selezionato: ${_fmtDay(widget.selectedDay)}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.add),
              label: const Text("Aggiungi persona"),
            ),
            const SizedBox(height: 16),
            if (activeToday.isEmpty)
              Text(
                "Nessuna persona attiva oggi.",
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              ),
            if (activeToday.isNotEmpty) ...activeToday.map(_personRow),
            if (inactiveToday.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    _showInactivePeople = !_showInactivePeople;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        _showInactivePeople
                            ? "Nascondi persone non attive"
                            : "Mostra persone non attive (${inactiveToday.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.72),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showInactivePeople
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showInactivePeople) ...[
                const SizedBox(height: 8),
                ...inactiveToday.map(_personRow),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
