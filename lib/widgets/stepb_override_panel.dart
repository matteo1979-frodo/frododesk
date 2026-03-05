// lib/widgets/stepb_override_panel.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';

/// Pannello UI Step B: selezione override per Matteo/Chiara.
/// Non contiene logica motore: scrive solo DayOverrides tramite callback.
///
/// ✅ NEW (zero rischio):
/// - può mostrare una piccola etichetta "(periodo)" quando lo stato Ferie
///   NON viene da override manuale ma da ferie lunghe (periodi).
class StepBOverridePanel extends StatelessWidget {
  final DateTime day;
  final DayOverrides current;

  /// Salva un DayOverrides aggiornato (lo store vero lo gestisce chi chiama)
  final ValueChanged<DayOverrides> onSave;

  /// Callback opzionale dopo una modifica (es: refresh IPS)
  final VoidCallback? onAfterChange;

  /// ✅ NEW: true = Ferie arriva da ferie lunghe (periodi), non da override manuale
  final bool matteoFerieFromPeriod;
  final bool chiaraFerieFromPeriod;

  const StepBOverridePanel({
    super.key,
    required this.day,
    required this.current,
    required this.onSave,
    this.onAfterChange,
    this.matteoFerieFromPeriod = false,
    this.chiaraFerieFromPeriod = false,
  });

  PersonDayOverride? _buildPersonOverrideSafe(OverrideStatus status) {
    if (status == OverrideStatus.normal) return null;

    if (status == OverrideStatus.permesso) {
      return PersonDayOverride(
        status: OverrideStatus.permesso,
        permessoRange: TimeRangeMinutes(startMin: 9 * 60, endMin: 10 * 60),
      );
    }

    return PersonDayOverride(status: status);
  }

  String _overrideLabel(OverrideStatus s) {
    switch (s) {
      case OverrideStatus.normal:
        return "Normal";
      case OverrideStatus.ferie:
        return "Ferie (disponibile)";
      case OverrideStatus.permesso:
        return "Permesso (default 09:00–10:00)";
      case OverrideStatus.malattiaLeggera:
        return "Malattia leggera";
      case OverrideStatus.malattiaALetto:
        return "Malattia a letto";
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
      case OverrideStatus.ferie:
        return (
          bg: Colors.green.withOpacity(0.12),
          border: Colors.green.withOpacity(0.45),
          text: Colors.green.shade900,
        );
      case OverrideStatus.permesso:
        return (
          bg: Colors.blue.withOpacity(0.12),
          border: Colors.blue.withOpacity(0.45),
          text: Colors.blue.shade900,
        );
      case OverrideStatus.malattiaLeggera:
        return (
          bg: Colors.orange.withOpacity(0.14),
          border: Colors.orange.withOpacity(0.50),
          text: Colors.orange.shade900,
        );
      case OverrideStatus.malattiaALetto:
        return (
          bg: Colors.red.withOpacity(0.12),
          border: Colors.red.withOpacity(0.45),
          text: Colors.red.shade900,
        );
    }
  }

  Widget _overrideRow({
    required BuildContext context,
    required String label,
    required OverrideStatus value,
    required bool ferieFromPeriod,
    required ValueChanged<OverrideStatus> onChanged,
  }) {
    final s = _styleFor(value);

    final showBadge = value == OverrideStatus.ferie && ferieFromPeriod;

    return Row(
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

              // ✅ NEW: badge "(periodo)" a destra
              suffixIcon: showBadge
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          "(periodo)",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: s.text.withOpacity(0.75),
                          ),
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
            style: TextStyle(color: s.text, fontWeight: FontWeight.w800),
            items: OverrideStatus.values.map((st) {
              return DropdownMenuItem(
                value: st,
                child: Text(_overrideLabel(st)),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);

              if (v == OverrideStatus.permesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Permesso: default 09:00–10:00 (TODO: editor orario).",
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final matteoStatus = current.matteo?.status ?? OverrideStatus.normal;
    final chiaraStatus = current.chiara?.status ?? OverrideStatus.normal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _overrideRow(
          context: context,
          label: "Matteo",
          value: matteoStatus,
          ferieFromPeriod: matteoFerieFromPeriod,
          onChanged: (newStatus) {
            final updated = DayOverrides(
              day: day,
              matteo: _buildPersonOverrideSafe(newStatus),
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
          value: chiaraStatus,
          ferieFromPeriod: chiaraFerieFromPeriod,
          onChanged: (newStatus) {
            final updated = DayOverrides(
              day: day,
              matteo: current.matteo,
              chiara: _buildPersonOverrideSafe(newStatus),
            );
            onSave(updated);
            onAfterChange?.call();
          },
        ),
      ],
    );
  }
}