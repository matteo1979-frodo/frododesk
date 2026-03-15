// lib/widgets/stepb_override_panel.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';

/// Pannello UI Step B: selezione override per Matteo/Chiara.
/// Non contiene logica motore: scrive solo DayOverrides tramite callback.
///
/// STEP B pulito:
/// - gestisce solo:
///   - Normal
///   - Permesso
///
/// Malattia e Ferie NON stanno più qui:
/// - Malattia -> DiseasePeriodStore
/// - Ferie -> FeriePeriodStore
///
/// ✅ Se selezioni Permesso -> dialog per scegliere INIZIO + FINE (TimeOfDay)
/// - Salva in PersonDayOverride.permessoRange (TimeRangeMinutes)
class StepBOverridePanel extends StatelessWidget {
  final DateTime day;
  final DayOverrides current;

  /// Salva un DayOverrides aggiornato (lo store vero lo gestisce chi chiama)
  final ValueChanged<DayOverrides> onSave;

  /// Callback opzionale dopo una modifica (es: refresh IPS)
  final VoidCallback? onAfterChange;

  const StepBOverridePanel({
    super.key,
    required this.day,
    required this.current,
    required this.onSave,
    this.onAfterChange,
  });

  // ----------------------------
  // Helpers time
  // ----------------------------

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int m) {
    final hh = (m ~/ 60).clamp(0, 23);
    final mm = (m % 60).clamp(0, 59);
    return TimeOfDay(hour: hh, minute: mm);
  }

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<TimeOfDay?> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
  }) {
    return showTimePicker(context: context, initialTime: initial);
  }

  // ----------------------------
  // Dialog Permesso
  // ----------------------------

  Future<TimeRangeMinutes?> _showPermessoDialog(
    BuildContext context, {
    TimeRangeMinutes? initial,
  }) async {
    final initStart = initial?.startMin ?? (12 * 60 + 45);
    final initEnd = initial?.endMin ?? (14 * 60 + 30);

    TimeOfDay start = _fromMinutes(initStart);
    TimeOfDay end = _fromMinutes(initEnd);

    return showDialog<TimeRangeMinutes>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final startMin = _toMinutes(start);
            final endMin = _toMinutes(end);
            final valid = endMin > startMin;

            return AlertDialog(
              title: const Text(
                "Permesso – scegli orario",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text("Inizio: ${_fmt(start)}"),
                          onPressed: () async {
                            final picked = await _pickTime(
                              context,
                              initial: start,
                            );
                            if (picked == null) return;
                            setState(() => start = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_filled),
                          label: Text("Fine: ${_fmt(end)}"),
                          onPressed: () async {
                            final picked = await _pickTime(
                              context,
                              initial: end,
                            );
                            if (picked == null) return;
                            setState(() => end = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!valid)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "⚠️ La fine deve essere dopo l’inizio.",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (valid)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Selezionato: ${_fmt(start)}–${_fmt(end)}",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: valid
                      ? () {
                          Navigator.of(ctx).pop(
                            TimeRangeMinutes(
                              startMin: _toMinutes(start),
                              endMin: _toMinutes(end),
                            ),
                          );
                        }
                      : null,
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------
  // Override builders
  // ----------------------------

  PersonDayOverride? _buildPersonOverrideSafe(
    OverrideStatus status, {
    TimeRangeMinutes? permessoRange,
  }) {
    if (status == OverrideStatus.normal) return null;

    if (status == OverrideStatus.permesso) {
      return PersonDayOverride(
        status: OverrideStatus.permesso,
        permessoRange:
            permessoRange ??
            TimeRangeMinutes(startMin: 12 * 60 + 45, endMin: 14 * 60 + 30),
      );
    }

    return null;
  }

  String _overrideLabel(OverrideStatus s) {
    switch (s) {
      case OverrideStatus.normal:
        return "Normal";
      case OverrideStatus.permesso:
        return "Permesso (con orario)";
      case OverrideStatus.ferie:
      case OverrideStatus.malattiaLeggera:
      case OverrideStatus.malattiaALetto:
        return "";
    }
  }

  ({Color bg, Color border, Color text}) _styleFor(OverrideStatus value) {
    switch (value) {
      case OverrideStatus.normal:
        return (
          bg: Colors.grey.withOpacity(0.08),
          border: Colors.grey.withOpacity(0.35),
          text: Colors.black87,
        );
      case OverrideStatus.permesso:
        return (
          bg: Colors.blue.withOpacity(0.12),
          border: Colors.blue.withOpacity(0.45),
          text: Colors.blue.shade900,
        );
      case OverrideStatus.ferie:
      case OverrideStatus.malattiaLeggera:
      case OverrideStatus.malattiaALetto:
        return (
          bg: Colors.grey.withOpacity(0.08),
          border: Colors.grey.withOpacity(0.35),
          text: Colors.black87,
        );
    }
  }

  List<OverrideStatus> get _stepBAllowedStatuses => const [
    OverrideStatus.normal,
    OverrideStatus.permesso,
  ];

  Widget _overrideRow({
    required BuildContext context,
    required String label,
    required PersonDayOverride? currentOverride,
    required ValueChanged<PersonDayOverride?> onOverrideChanged,
  }) {
    final rawValue = currentOverride?.status ?? OverrideStatus.normal;
    final value = _stepBAllowedStatuses.contains(rawValue)
        ? rawValue
        : OverrideStatus.normal;

    final s = _styleFor(value);

    final showPermessoRange =
        value == OverrideStatus.permesso &&
        currentOverride?.permessoRange != null;

    final permessoText = showPermessoRange
        ? "Orario permesso: ${currentOverride!.permessoRange!.toDisplayString()}"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<OverrideStatus>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: s.bg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: s.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: s.border, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: s.text, fontWeight: FontWeight.w800),
                items: _stepBAllowedStatuses.map((st) {
                  return DropdownMenuItem(
                    value: st,
                    child: Text(_overrideLabel(st)),
                  );
                }).toList(),
                onChanged: (v) async {
                  if (v == null) return;

                  if (v == OverrideStatus.permesso) {
                    final picked = await _showPermessoDialog(
                      context,
                      initial: currentOverride?.permessoRange,
                    );

                    if (picked == null) return;

                    onOverrideChanged(
                      _buildPersonOverrideSafe(
                        OverrideStatus.permesso,
                        permessoRange: picked,
                      ),
                    );
                    return;
                  }

                  onOverrideChanged(_buildPersonOverrideSafe(v));
                },
              ),
            ),
          ],
        ),
        if (permessoText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 82),
            child: Text(
              permessoText,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overrideRow(
          context: context,
          label: "Matteo",
          currentOverride: current.matteo,
          onOverrideChanged: (newOverride) {
            final updated = DayOverrides(
              day: day,
              matteo: newOverride,
              chiara: current.chiara,
            );
            onSave(updated);
            onAfterChange?.call();
          },
        ),
        const SizedBox(height: 12),
        _overrideRow(
          context: context,
          label: "Chiara",
          currentOverride: current.chiara,
          onOverrideChanged: (newOverride) {
            final updated = DayOverrides(
              day: day,
              matteo: current.matteo,
              chiara: newOverride,
            );
            onSave(updated);
            onAfterChange?.call();
          },
        ),
      ],
    );
  }
}
