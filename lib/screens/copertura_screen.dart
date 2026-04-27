// lib/screens/copertura_screen.dart
import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import 'calendario_screen_stepa.dart';

class CoperturaScreen extends StatelessWidget {
  final CoreStore coreStore;

  const CoperturaScreen({super.key, required this.coreStore});

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _openCalendarToday(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarioScreenStepAStabile(
          coreStore: coreStore,
          initialSelectedDay: today,
        ),
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required String message,
    VoidCallback? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            action?.call();

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));

            if (action != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CoperturaScreen(coreStore: coreStore),
                ),
              );
            }
          },
          child: Text(label),
        ),
      ),
    );
  }

  Widget _gapDetailBox({
    required String title,
    required dynamic gap,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Alice non coperta dalle ${_formatTime(gap.start)} alle ${_formatTime(gap.end)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...gap.lines.map<Widget>(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $line'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nowMinutes = now.hour * 60 + now.minute;

    final details = coreStore.coverageEngine.aliceHomeRiskDetailsForDay(
      day: today,
      uscita13:
          coreStore.daySettingsStore.uscita13ForDay(today) ??
          coreStore.settingsStore.isUscita13,
      sandraMattinaOn:
          coreStore.daySettingsStore.sandraMattinaForDay(today) ??
          coreStore.settingsStore.isSandraDisponibile,
      sandraPranzoOn:
          coreStore.daySettingsStore.sandraPranzoForDay(today) ??
          coreStore.settingsStore.isSandraDisponibile,
      sandraSeraOn:
          coreStore.daySettingsStore.sandraSeraForDay(today) ??
          coreStore.settingsStore.isSandraDisponibile,
      schoolStart: const TimeOfDay(hour: 8, minute: 25),
      overrides: coreStore.overrideStore.getEffectiveForDay(
        day: today,
        ferieStore: coreStore.feriePeriodStore,
      ),
      ferieStore: coreStore.feriePeriodStore,
    );

    final activeOrFutureGaps = details.where((gap) {
      return _minutes(gap.end) > nowMinutes;
    }).toList();

    final resolvedGaps = details.where((gap) {
      return _minutes(gap.end) <= nowMinutes;
    }).toList();

    final firstGap = activeOrFutureGaps.isEmpty
        ? null
        : activeOrFutureGaps.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Copertura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: firstGap == null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Copertura sotto controllo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Da ora in poi non risultano buchi di copertura per Alice.',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (resolvedGaps.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text(
                        'Problemi già passati oggi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Questi buchi non sono più attivi, ma restano visibili come memoria della giornata.',
                      ),
                      const SizedBox(height: 12),
                      ...resolvedGaps.asMap().entries.map(
                        (entry) => _gapDetailBox(
                          title: 'Risolto / passato ${entry.key + 1}',
                          gap: entry.value,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _openCalendarToday(context),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Apri calendario'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _minutes(firstGap.start) <= nowMinutes
                          ? 'Problema copertura in corso'
                          : 'Problema copertura',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Alice non coperta dalle ${_formatTime(firstGap.start)} alle ${_formatTime(firstGap.end)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dettaglio:',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...firstGap.lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $line'),
                      ),
                    ),
                    if (activeOrFutureGaps.length > 1) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Altri problemi da gestire oggi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...activeOrFutureGaps
                          .skip(1)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => _gapDetailBox(
                              title: 'Problema ${entry.key + 2}',
                              gap: entry.value,
                              color: Colors.red,
                            ),
                          ),
                    ],
                    if (resolvedGaps.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Già passati oggi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...resolvedGaps.asMap().entries.map(
                        (entry) => _gapDetailBox(
                          title: 'Passato ${entry.key + 1}',
                          gap: entry.value,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'Soluzioni possibili',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      context: context,
                      label: 'Attiva Sandra',
                      message: 'Sandra attivata per oggi',
                      action: () {
                        coreStore.daySettingsStore.setSandraForDay(today, true);
                      },
                    ),
                    _actionButton(
                      context: context,
                      label: 'Usa rete supporto',
                      message: 'Rete supporto: da collegare nello step futuro',
                    ),
                    _actionButton(
                      context: context,
                      label: 'Porta Alice con te',
                      message:
                          'Alice al seguito: da collegare nello step futuro',
                    ),
                    _actionButton(
                      context: context,
                      label: 'Cambia turno',
                      message: 'Cambio turno: da collegare nello step futuro',
                    ),
                    _actionButton(
                      context: context,
                      label: 'Prendi permesso',
                      message: 'Permesso: da collegare nello step futuro',
                    ),
                    _actionButton(
                      context: context,
                      label: 'Chiedi ferie',
                      message: 'Ferie: da collegare nello step futuro',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openCalendarToday(context),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Apri calendario'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
