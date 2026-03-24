// lib/widgets/stepb_override_panel.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';

class StepBOverridePanel extends StatelessWidget {
  final DateTime day;
  final DayOverrides current;
  final ValueChanged<DayOverrides> onSave;
  final VoidCallback? onAfterChange;

  const StepBOverridePanel({
    super.key,
    required this.day,
    required this.current,
    required this.onSave,
    this.onAfterChange,
  });

  // ----------------------------
  // Helpers
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
            final valid = _toMinutes(end) > _toMinutes(start);

            return AlertDialog(
              title: const Text(
                "Permesso – scegli orario",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickTime(
                        context,
                        initial: start,
                      );
                      if (picked != null) {
                        setState(() => start = picked);
                      }
                    },
                    child: Text("Inizio: ${_fmt(start)}"),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickTime(
                        context,
                        initial: end,
                      );
                      if (picked != null) {
                        setState(() => end = picked);
                      }
                    },
                    child: Text("Fine: ${_fmt(end)}"),
                  ),
                  const SizedBox(height: 12),
                  if (!valid)
                    const Text(
                      "⚠️ Fine deve essere dopo inizio",
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: valid
                      ? () {
                          Navigator.pop(
                            ctx,
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
  // UI PERSONA
  // ----------------------------

  Widget _personRow({
    required BuildContext context,
    required String label,
    required PersonDayOverride? currentOverride,
    required ValueChanged<PersonDayOverride?> onChanged,
  }) {
    final isPermesso =
        currentOverride?.status == OverrideStatus.permesso;

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

            if (!isPermesso)
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await _showPermessoDialog(context);
                    if (picked == null) return;

                    onChanged(
                      PersonDayOverride(
                        status: OverrideStatus.permesso,
                        permessoRange: picked,
                      ),
                    );
                  },
                  child: const Text("Permesso"),
                ),
              ),

            if (isPermesso)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    onChanged(null);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Rimuovi permesso"),
                ),
              ),
          ],
        ),

        if (isPermesso && currentOverride?.permessoRange != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 82),
            child: Text(
              "Orario: ${currentOverride!.permessoRange!.toDisplayString()}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------
  // BUILD (CARD PERMESSO)
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Permesso",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          _personRow(
            context: context,
            label: "Matteo",
            currentOverride: current.matteo,
            onChanged: (newOverride) {
              onSave(
                DayOverrides(
                  day: day,
                  matteo: newOverride,
                  chiara: current.chiara,
                ),
              );
              onAfterChange?.call();
            },
          ),

          const SizedBox(height: 12),

          _personRow(
            context: context,
            label: "Chiara",
            currentOverride: current.chiara,
            onChanged: (newOverride) {
              onSave(
                DayOverrides(
                  day: day,
                  matteo: current.matteo,
                  chiara: newOverride,
                ),
              );
              onAfterChange?.call();
            },
          ),
        ],
      ),
    );
  }
}