import 'package:flutter/material.dart';

import '../logic/core_store.dart';

enum _StatsPeriod { last7, last30, currentMonth }

class StatisticheScreen extends StatefulWidget {
  final CoreStore coreStore;

  const StatisticheScreen({super.key, required this.coreStore});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  CoreStore get coreStore => widget.coreStore;

  _StatsPeriod selectedPeriod = _StatsPeriod.last30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Statistiche"),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.28),
                    Colors.black.withOpacity(0.42),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _StatisticheHeader(),
                const SizedBox(height: 18),
                _PeriodSelector(
                  selected: selectedPeriod,
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _SandraHoursCard(
                  coreStore: coreStore,
                  period: selectedPeriod,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticheHeader extends StatelessWidget {
  const _StatisticheHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistiche",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Lettura dei dati reali del sistema",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _StatsPeriod selected;
  final ValueChanged<_StatsPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PeriodChip(
          label: "7 giorni",
          selected: selected == _StatsPeriod.last7,
          onTap: () => onChanged(_StatsPeriod.last7),
        ),
        _PeriodChip(
          label: "30 giorni",
          selected: selected == _StatsPeriod.last30,
          onTap: () => onChanged(_StatsPeriod.last30),
        ),
        _PeriodChip(
          label: "Mese corrente",
          selected: selected == _StatsPeriod.currentMonth,
          onTap: () => onChanged(_StatsPeriod.currentMonth),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFCA28),
      backgroundColor: Colors.white.withOpacity(0.16),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: Colors.white.withOpacity(0.28)),
    );
  }
}

class _SandraHoursCard extends StatelessWidget {
  final CoreStore coreStore;
  final _StatsPeriod period;
  final VoidCallback onChanged;

  const _SandraHoursCard({
    required this.coreStore,
    required this.period,
    required this.onChanged,
  });

  DateTime _cleanDay(DateTime day) => DateTime(day.year, day.month, day.day);

  DateTime _startDayForPeriod(DateTime today) {
    switch (period) {
      case _StatsPeriod.last7:
        return today.subtract(const Duration(days: 6));
      case _StatsPeriod.last30:
        return today.subtract(const Duration(days: 29));
      case _StatsPeriod.currentMonth:
        return DateTime(today.year, today.month, 1);
    }
  }

  String _periodLabel(DateTime startDay, DateTime today) {
    switch (period) {
      case _StatsPeriod.last7:
        return "ultimi 7 giorni";
      case _StatsPeriod.last30:
        return "ultimi 30 giorni";
      case _StatsPeriod.currentMonth:
        return "mese corrente";
    }
  }

  int _daysCount(DateTime startDay, DateTime today) {
    return today.difference(startDay).inDays + 1;
  }

  int _sandraFixedMinutesForDay(DateTime day) {
    final mattina =
        coreStore.daySettingsStore.sandraMattinaForDay(day) ?? false;
    final pranzo = coreStore.daySettingsStore.sandraPranzoForDay(day) ?? false;
    final sera = coreStore.daySettingsStore.sandraSeraForDay(day) ?? false;

    int total = 0;

    if (mattina) total += 95;
    if (pranzo) total += 90;
    if (sera) total += 95;

    return total;
  }

  int _sandraFixedSlotsForDay(DateTime day) {
    final mattina =
        coreStore.daySettingsStore.sandraMattinaForDay(day) ?? false;
    final pranzo = coreStore.daySettingsStore.sandraPranzoForDay(day) ?? false;
    final sera = coreStore.daySettingsStore.sandraSeraForDay(day) ?? false;

    int total = 0;

    if (mattina) total++;
    if (pranzo) total++;
    if (sera) total++;

    return total;
  }

  int _supportMinutesForSandraDay(DateTime day) {
    int total = 0;

    final enabledIds = coreStore.daySettingsStore.supportPeopleEnabledIdsForDay(
      day,
    );

    if (enabledIds.isEmpty) return 0;

    for (final person in coreStore.supportNetworkStore.people) {
      final isSandra = person.name.trim().toLowerCase() == "sandra";
      final enabledThatDay = enabledIds.contains(person.id);

      if (!isSandra || !person.enabled || !enabledThatDay) continue;

      final startMinutes = person.start.hour * 60 + person.start.minute;
      final endMinutes = person.end.hour * 60 + person.end.minute;

      final duration = endMinutes - startMinutes;

      if (duration > 0) {
        total += duration;
      }
    }

    return total;
  }

  int _supportSlotsForSandraDay(DateTime day) {
    final enabledIds = coreStore.daySettingsStore.supportPeopleEnabledIdsForDay(
      day,
    );

    if (enabledIds.isEmpty) return 0;

    return coreStore.supportNetworkStore.people.where((person) {
      final isSandra = person.name.trim().toLowerCase() == "sandra";
      final enabledThatDay = enabledIds.contains(person.id);

      return isSandra && person.enabled && enabledThatDay;
    }).length;
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;

    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  String _dayLabel(int count) {
    return count == 1 ? "1 giorno" : "$count giorni";
  }

  String _slotLabel(int count) {
    return count == 1 ? "1 fascia" : "$count fasce";
  }

  String _supportLabel(int count) {
    return count == 1 ? "1 intervento" : "$count interventi";
  }

  Future<void> _editSandraHourlyRate(BuildContext context) async {
    final controller = TextEditingController(
      text: coreStore.settingsStore.sandraRate.toStringAsFixed(2),
    );

    final saved = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Paga oraria Sandra"),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Euro / ora",
              hintText: "Es. 10.00",
              suffixText: "€/h",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = controller.text.trim().replaceAll(",", ".");
                final value = double.tryParse(raw);

                if (value == null || value < 0) return;

                Navigator.of(context).pop(value);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (saved == null) return;

    coreStore.settingsStore.setSandraHourlyRate(saved);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final today = _cleanDay(DateTime.now());
    final startDay = _startDayForPeriod(today);
    final daysCount = _daysCount(startDay, today);

    int fixedMinutes = 0;
    int activeDays = 0;
    int activeSlots = 0;

    int supportMinutes = 0;
    int supportDays = 0;
    int supportSlots = 0;

    for (int i = 0; i < daysCount; i++) {
      final day = startDay.add(Duration(days: i));

      final dayMinutes = _sandraFixedMinutesForDay(day);
      final daySlots = _sandraFixedSlotsForDay(day);

      fixedMinutes += dayMinutes;
      activeSlots += daySlots;

      if (daySlots > 0) {
        activeDays++;
      }

      final daySupportMinutes = _supportMinutesForSandraDay(day);
      final daySupportSlots = _supportSlotsForSandraDay(day);

      supportMinutes += daySupportMinutes;
      supportSlots += daySupportSlots;

      if (daySupportSlots > 0) {
        supportDays++;
      }
    }

    final totalMinutes = fixedMinutes + supportMinutes;

    final hourlyRate = coreStore.settingsStore.sandraRate;
    final totalCost = (totalMinutes / 60) * hourlyRate;

    final fixedLabel =
        "${_formatMinutes(fixedMinutes)} • ${_dayLabel(activeDays)} • ${_slotLabel(activeSlots)}";

    final supportLabel =
        "${_formatMinutes(supportMinutes)} • ${_dayLabel(supportDays)} • ${_supportLabel(supportSlots)}";

    final totalLabel = _formatMinutes(totalMinutes);
    final costMainLabel = "€${totalCost.toStringAsFixed(2)}";
    final hourlyRateLabel = "${hourlyRate.toStringAsFixed(2)} €/h";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3328).withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BC34A).withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCA28).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFCA28).withOpacity(0.28),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFFFFCA28),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Sandra",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Modifica paga oraria",
                onPressed: () => _editSandraHourlyRate(context),
                icon: const Icon(Icons.settings_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Periodo: ${_periodLabel(startDay, today)} (${startDay.day}/${startDay.month} - ${today.day}/${today.month})",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            totalLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                "$costMainLabel stimati",
                style: const TextStyle(
                  color: Color(0xFFFFCA28),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "($hourlyRateLabel)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withOpacity(0.16)),
          const SizedBox(height: 12),
          _SandraDetailBox(label: "Fasce standard", value: fixedLabel),
          const SizedBox(height: 10),
          _SandraDetailBox(label: "Supporto extra", value: supportLabel),
        ],
      ),
    );
  }
}

class _SandraDetailBox extends StatelessWidget {
  final String label;
  final String value;

  const _SandraDetailBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
