import 'package:flutter/material.dart';

import '../logic/core_store.dart';

enum _StatsPeriod { currentDay, currentWeek, currentMonth, currentYear }

class StatisticheScreen extends StatefulWidget {
  final CoreStore coreStore;

  const StatisticheScreen({super.key, required this.coreStore});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  CoreStore get coreStore => widget.coreStore;

  _StatsPeriod selectedPeriod = _StatsPeriod.currentMonth;

  Future<void> _openSupportoFamiliare() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF12251D).withOpacity(0.96),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Supporto familiare",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SandraHoursCard(
                    coreStore: coreStore,
                    period: selectedPeriod,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (mounted) setState(() {});
  }

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
                const Text(
                  "Panoramica statistiche",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;

                    if (constraints.maxWidth >= 1000) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth >= 720) {
                      crossAxisCount = 3;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: constraints.maxWidth >= 720 ? 1.15 : 1,
                      children: [
                        _SupportFamilyStatCard(
                          coreStore: coreStore,
                          period: selectedPeriod,
                          onTap: _openSupportoFamiliare,
                        ),
                        const _StatsHubCard(
                          icon: Icons.shield_rounded,
                          title: "Copertura",
                          value: "Presto",
                          subtitle: "Buchi e pressione",
                          color: Color(0xFF42A5F5),
                        ),
                        const _StatsHubCard(
                          icon: Icons.event_note_rounded,
                          title: "Eventi",
                          value: "Presto",
                          subtitle: "Storico famiglia",
                          color: Color(0xFFEC407A),
                        ),
                        const _StatsHubCard(
                          icon: Icons.euro_rounded,
                          title: "Costi",
                          value: "Presto",
                          subtitle: "Spese e impatto",
                          color: Color(0xFFFFCA28),
                        ),
                      ],
                    );
                  },
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
          label: "Giorno",
          selected: selected == _StatsPeriod.currentDay,
          onTap: () => onChanged(_StatsPeriod.currentDay),
        ),
        _PeriodChip(
          label: "Settimana",
          selected: selected == _StatsPeriod.currentWeek,
          onTap: () => onChanged(_StatsPeriod.currentWeek),
        ),
        _PeriodChip(
          label: "Mese",
          selected: selected == _StatsPeriod.currentMonth,
          onTap: () => onChanged(_StatsPeriod.currentMonth),
        ),
        _PeriodChip(
          label: "Anno",
          selected: selected == _StatsPeriod.currentYear,
          onTap: () => onChanged(_StatsPeriod.currentYear),
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
      backgroundColor: Colors.white.withOpacity(0.86),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: Colors.white.withOpacity(0.28)),
    );
  }
}

class _SupportFamilyStatCard extends StatelessWidget {
  final CoreStore coreStore;
  final _StatsPeriod period;
  final VoidCallback onTap;

  const _SupportFamilyStatCard({
    required this.coreStore,
    required this.period,
    required this.onTap,
  });

  DateTime _cleanDay(DateTime day) => DateTime(day.year, day.month, day.day);

  _StatsRange _rangeFor(DateTime reference) {
    final day = _cleanDay(reference);

    switch (period) {
      case _StatsPeriod.currentDay:
        return _StatsRange(start: day, end: day);

      case _StatsPeriod.currentWeek:
        final start = day.subtract(Duration(days: day.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentMonth:
        final start = DateTime(day.year, day.month, 1);
        final end = DateTime(day.year, day.month + 1, 0);
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentYear:
        final start = DateTime(day.year, 1, 1);
        final end = DateTime(day.year, 12, 31);
        return _StatsRange(start: start, end: end);
    }
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

      if (duration > 0) total += duration;
    }

    return total;
  }

  int _totalMinutesForRange(DateTime startDay, int daysCount) {
    int total = 0;

    for (int i = 0; i < daysCount; i++) {
      final day = startDay.add(Duration(days: i));
      total += _sandraFixedMinutesForDay(day);
      total += _supportMinutesForSandraDay(day);
    }

    return total;
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

  @override
  Widget build(BuildContext context) {
    final range = _rangeFor(DateTime.now());
    final daysCount = range.daysCount;

    final totalMinutes = _totalMinutesForRange(range.start, daysCount);
    final totalCost = (totalMinutes / 60) * coreStore.settingsStore.sandraRate;

    return _StatsHubCard(
      icon: Icons.support_agent_rounded,
      title: "Supporto familiare",
      value: _formatMinutes(totalMinutes),
      subtitle: "Sandra • €${totalCost.toStringAsFixed(2)}",
      color: const Color(0xFFFFCA28),
      onTap: onTap,
    );
  }
}

class _StatsHubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _StatsHubCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: card,
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

  _StatsRange _rangeFor(DateTime reference) {
    final day = _cleanDay(reference);

    switch (period) {
      case _StatsPeriod.currentDay:
        return _StatsRange(start: day, end: day);

      case _StatsPeriod.currentWeek:
        final start = day.subtract(Duration(days: day.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentMonth:
        final start = DateTime(day.year, day.month, 1);
        final end = DateTime(day.year, day.month + 1, 0);
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentYear:
        final start = DateTime(day.year, 1, 1);
        final end = DateTime(day.year, 12, 31);
        return _StatsRange(start: start, end: end);
    }
  }

  _StatsRange _previousRangeFor(_StatsRange range) {
    switch (period) {
      case _StatsPeriod.currentDay:
        final day = range.start.subtract(const Duration(days: 1));
        return _StatsRange(start: day, end: day);

      case _StatsPeriod.currentWeek:
        final start = range.start.subtract(const Duration(days: 7));
        final end = start.add(const Duration(days: 6));
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentMonth:
        final start = DateTime(range.start.year, range.start.month - 1, 1);
        final end = DateTime(range.start.year, range.start.month, 0);
        return _StatsRange(start: start, end: end);

      case _StatsPeriod.currentYear:
        final start = DateTime(range.start.year - 1, 1, 1);
        final end = DateTime(range.start.year - 1, 12, 31);
        return _StatsRange(start: start, end: end);
    }
  }

  String _periodLabel(_StatsRange range) {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "giorno (${range.start.day}/${range.start.month})";

      case _StatsPeriod.currentWeek:
        return "settimana (${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month})";

      case _StatsPeriod.currentMonth:
        return "mese (${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month})";

      case _StatsPeriod.currentYear:
        return "anno ${range.start.year}";
    }
  }

  String _periodTitle(DateTime reference) {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "${reference.day}/${reference.month}/${reference.year}";

      case _StatsPeriod.currentWeek:
        final range = _rangeFor(reference);
        return "${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}";

      case _StatsPeriod.currentMonth:
        return "${_monthName(reference.month)} ${reference.year}";

      case _StatsPeriod.currentYear:
        return "${reference.year}";
    }
  }

  DateTime _moveReference(DateTime reference, int direction) {
    switch (period) {
      case _StatsPeriod.currentDay:
        return reference.add(Duration(days: direction));

      case _StatsPeriod.currentWeek:
        return reference.add(Duration(days: 7 * direction));

      case _StatsPeriod.currentMonth:
        return DateTime(reference.year, reference.month + direction, 1);

      case _StatsPeriod.currentYear:
        return DateTime(reference.year + direction, reference.month, 1);
    }
  }

  String _currentLabel() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Giorno attuale";
      case _StatsPeriod.currentWeek:
        return "Settimana attuale";
      case _StatsPeriod.currentMonth:
        return "Mese attuale";
      case _StatsPeriod.currentYear:
        return "Anno attuale";
    }
  }

  String _previousLabel() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Giorno precedente";
      case _StatsPeriod.currentWeek:
        return "Settimana precedente";
      case _StatsPeriod.currentMonth:
        return "Mese precedente";
      case _StatsPeriod.currentYear:
        return "Anno precedente";
    }
  }

  String _trendText(int currentMinutes, int previousMinutes) {
    final diff = currentMinutes - previousMinutes;

    if (diff == 0) {
      return "Stabile rispetto al periodo precedente";
    }

    final diffLabel = _formatMinutes(diff.abs());

    if (diff > 0) {
      return "In aumento di $diffLabel rispetto al periodo precedente";
    }

    return "In calo di $diffLabel rispetto al periodo precedente";
  }

  String _primaryMiniTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Totale giorno";
      case _StatsPeriod.currentWeek:
        return "Media giorno";
      case _StatsPeriod.currentMonth:
        return "Media giorno";
      case _StatsPeriod.currentYear:
        return "Media mese";
    }
  }

  String _maxMiniTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Giorno";
      case _StatsPeriod.currentWeek:
      case _StatsPeriod.currentMonth:
        return "Giorno più intenso";
      case _StatsPeriod.currentYear:
        return "Mese più intenso";
    }
  }

  String _peakMiniTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Ore giorno";
      case _StatsPeriod.currentWeek:
      case _StatsPeriod.currentMonth:
        return "Picco ore";
      case _StatsPeriod.currentYear:
        return "Picco mese";
    }
  }

  String _summaryTotalTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Totale giorno";
      case _StatsPeriod.currentWeek:
        return "Totale settimana";
      case _StatsPeriod.currentMonth:
        return "Totale mese";
      case _StatsPeriod.currentYear:
        return "Totale anno";
    }
  }

  String _summaryCostTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Costo giorno";
      case _StatsPeriod.currentWeek:
        return "Costo settimana";
      case _StatsPeriod.currentMonth:
        return "Costo mese";
      case _StatsPeriod.currentYear:
        return "Costo anno";
    }
  }

  String _summaryActiveTitle() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Presenza Sandra";
      case _StatsPeriod.currentWeek:
      case _StatsPeriod.currentMonth:
      case _StatsPeriod.currentYear:
        return "Giorni con Sandra";
    }
  }

  String _chartCaption() {
    switch (period) {
      case _StatsPeriod.currentDay:
        return "Il punto rappresenta le ore Sandra totali del giorno.";
      case _StatsPeriod.currentWeek:
      case _StatsPeriod.currentMonth:
        return "Ogni punto rappresenta le ore Sandra totali del giorno.";
      case _StatsPeriod.currentYear:
        return "Ogni punto rappresenta le ore Sandra totali del mese.";
    }
  }

  String _pointLabel(_SandraDailyPoint point) {
    switch (period) {
      case _StatsPeriod.currentDay:
      case _StatsPeriod.currentWeek:
      case _StatsPeriod.currentMonth:
        return "${point.day.day}/${point.day.month}";
      case _StatsPeriod.currentYear:
        return _monthName(point.day.month).substring(0, 3);
    }
  }

  String _monthName(int month) {
    const months = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    return months[month - 1];
  }

  Color _trendColor(int currentMinutes, int previousMinutes) {
    if (currentMinutes > previousMinutes) {
      return const Color(0xFFFFCA28);
    }

    if (currentMinutes < previousMinutes) {
      return const Color(0xFF8BC34A);
    }

    return Colors.white70;
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

      if (duration > 0) total += duration;
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

  int _totalSandraMinutesForDay(DateTime day) {
    return _sandraFixedMinutesForDay(day) + _supportMinutesForSandraDay(day);
  }

  List<_SandraDailyPoint> _dailyPoints(DateTime startDay, int daysCount) {
    final points = <_SandraDailyPoint>[];

    for (int i = 0; i < daysCount; i++) {
      final day = startDay.add(Duration(days: i));
      points.add(
        _SandraDailyPoint(day: day, minutes: _totalSandraMinutesForDay(day)),
      );
    }

    return points;
  }

  List<_SandraDailyPoint> _monthlyPoints(int year) {
    final points = <_SandraDailyPoint>[];

    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(year, month);
      final monthEnd = DateTime(year, month + 1, 0);
      final daysCount = monthEnd.day;

      final minutes = _totalMinutesForRange(monthStart, daysCount);

      points.add(_SandraDailyPoint(day: monthStart, minutes: minutes));
    }

    return points;
  }

  List<_SandraDailyPoint> _pointsForRange(_StatsRange range) {
    if (period == _StatsPeriod.currentYear) {
      return _monthlyPoints(range.start.year);
    }

    return _dailyPoints(range.start, range.daysCount);
  }

  int _totalMinutesForRange(DateTime startDay, int daysCount) {
    int total = 0;

    for (int i = 0; i < daysCount; i++) {
      final day = startDay.add(Duration(days: i));
      total += _totalSandraMinutesForDay(day);
    }

    return total;
  }

  int _activeDaysForRange(DateTime startDay, int daysCount) {
    int total = 0;

    for (int i = 0; i < daysCount; i++) {
      final day = startDay.add(Duration(days: i));
      if (_totalSandraMinutesForDay(day) > 0) {
        total++;
      }
    }

    return total;
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

  String _summaryText(int totalMinutes) {
    if (totalMinutes == 0) {
      return "Sandra non è stata utilizzata in questo periodo";
    }

    final hours = totalMinutes ~/ 60;

    if (hours <= 3) {
      return "Utilizzo leggero di Sandra";
    } else if (hours <= 8) {
      return "Sandra usata in modo regolare";
    } else {
      return "Sandra molto presente in questo periodo";
    }
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

  Future<void> _showTrendPopup({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    DateTime visibleDate = _cleanDay(initialDate);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final currentRange = _rangeFor(visibleDate);
            final previousRange = _previousRangeFor(currentRange);

            final currentMinutes = _totalMinutesForRange(
              currentRange.start,
              currentRange.daysCount,
            );

            final previousMinutes = _totalMinutesForRange(
              previousRange.start,
              previousRange.daysCount,
            );

            final currentCost =
                (currentMinutes / 60) * coreStore.settingsStore.sandraRate;
            final previousCost =
                (previousMinutes / 60) * coreStore.settingsStore.sandraRate;

            final points = _pointsForRange(currentRange);
            final previousPoints = _pointsForRange(previousRange);

            final activeDays = _activeDaysForRange(
              currentRange.start,
              currentRange.daysCount,
            );

            final trendText = _trendText(currentMinutes, previousMinutes);
            final trendColor = _trendColor(currentMinutes, previousMinutes);

            final averageMinutes = period == _StatsPeriod.currentYear
                ? (currentMinutes / 12).round()
                : period == _StatsPeriod.currentDay
                ? currentMinutes
                : currentRange.daysCount == 0
                ? 0
                : (currentMinutes / currentRange.daysCount).round();

            final maxPoint = points.isEmpty
                ? null
                : points.reduce((a, b) => a.minutes >= b.minutes ? a : b);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3328).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCA28).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.show_chart_rounded,
                              color: Color(0xFFFFCA28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Andamento Sandra",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Periodo precedente",
                            onPressed: () {
                              dialogSetState(() {
                                visibleDate = _moveReference(visibleDate, -1);
                              });
                            },
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _periodTitle(visibleDate),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: "Periodo successivo",
                            onPressed: () {
                              dialogSetState(() {
                                visibleDate = _moveReference(visibleDate, 1);
                              });
                            },
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trendText,
                              style: TextStyle(
                                color: trendColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _TrendValueBox(
                                    title: _currentLabel(),
                                    value: _formatMinutes(currentMinutes),
                                    subtitle:
                                        "€${currentCost.toStringAsFixed(2)} stimati",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TrendValueBox(
                                    title: _previousLabel(),
                                    value: _formatMinutes(previousMinutes),
                                    subtitle:
                                        "€${previousCost.toStringAsFixed(2)} stimati",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _TrendMiniStat(
                            title: _primaryMiniTitle(),
                            value: _formatMinutes(averageMinutes),
                          ),
                          _TrendMiniStat(
                            title: _maxMiniTitle(),
                            value: maxPoint == null
                                ? "-"
                                : _pointLabel(maxPoint),
                          ),
                          _TrendMiniStat(
                            title: _peakMiniTitle(),
                            value: maxPoint == null
                                ? "-"
                                : _formatMinutes(maxPoint.minutes),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 220,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: CustomPaint(
                          painter: _SandraLineChartPainter(
                            points: points,
                            previousPoints: previousPoints,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = constraints.maxWidth >= 520
                              ? (constraints.maxWidth - 20) / 3
                              : constraints.maxWidth;

                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: _MonthSummaryBox(
                                  title: _summaryTotalTitle(),
                                  value: _formatMinutes(currentMinutes),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MonthSummaryBox(
                                  title: _summaryCostTitle(),
                                  value: "€${currentCost.toStringAsFixed(2)}",
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _MonthSummaryBox(
                                  title: _summaryActiveTitle(),
                                  value: period == _StatsPeriod.currentDay
                                      ? (activeDays > 0
                                            ? "Presente"
                                            : "Assente")
                                      : activeDays == 1
                                      ? "1 giorno"
                                      : "$activeDays giorni",
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ChartLegendItem(
                            color: const Color(0xFFFFCA28),
                            label: _currentLabel(),
                          ),
                          _ChartLegendItem(
                            color: Colors.white54,
                            label: _previousLabel(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _chartCaption(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _rangeFor(DateTime.now());
    final daysCount = range.daysCount;

    int fixedMinutes = 0;
    int activeDays = 0;
    int activeSlots = 0;

    int supportMinutes = 0;
    int supportDays = 0;
    int supportSlots = 0;

    for (int i = 0; i < daysCount; i++) {
      final day = range.start.add(Duration(days: i));

      final dayMinutes = _sandraFixedMinutesForDay(day);
      final daySlots = _sandraFixedSlotsForDay(day);

      fixedMinutes += dayMinutes;
      activeSlots += daySlots;

      if (daySlots > 0) activeDays++;

      final daySupportMinutes = _supportMinutesForSandraDay(day);
      final daySupportSlots = _supportSlotsForSandraDay(day);

      supportMinutes += daySupportMinutes;
      supportSlots += daySupportSlots;

      if (daySupportSlots > 0) supportDays++;
    }

    final totalMinutes = fixedMinutes + supportMinutes;

    final hourlyRate = coreStore.settingsStore.sandraRate;
    final totalCost = (totalMinutes / 60) * hourlyRate;

    final fixedLabel =
        "${_formatMinutes(fixedMinutes)} • ${_dayLabel(activeDays)} • ${_slotLabel(activeSlots)}";

    final supportLabel =
        "${_formatMinutes(supportMinutes)} • ${_dayLabel(supportDays)} • ${_supportLabel(supportSlots)}";

    final totalLabel = _formatMinutes(totalMinutes);
    final summary = _summaryText(totalMinutes);
    final costMainLabel = "€${totalCost.toStringAsFixed(2)}";
    final hourlyRateLabel = "${hourlyRate.toStringAsFixed(2)} €/h";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3328).withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8BC34A).withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCA28).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFFFCA28).withOpacity(0.28),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFFFFCA28),
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  "Sandra",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
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
          const SizedBox(height: 8),
          Text(
            "Periodo: ${_periodLabel(range)}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            totalLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                "$costMainLabel stimati",
                style: const TextStyle(
                  color: Color(0xFFFFCA28),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "($hourlyRateLabel)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.16)),
          const SizedBox(height: 10),
          _SandraDetailBox(label: "Fasce standard", value: fixedLabel),
          const SizedBox(height: 8),
          _SandraDetailBox(label: "Supporto extra", value: supportLabel),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                _showTrendPopup(context: context, initialDate: DateTime.now()),
            icon: const Icon(Icons.show_chart_rounded),
            label: const Text("Vedi andamento"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.28)),
              backgroundColor: Colors.white.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRange {
  final DateTime start;
  final DateTime end;

  const _StatsRange({required this.start, required this.end});

  int get daysCount => end.difference(start).inDays + 1;
}

class _SandraDetailBox extends StatelessWidget {
  final String label;
  final String value;

  const _SandraDetailBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
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

class _TrendValueBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _TrendValueBox({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFFFCA28),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendMiniStat extends StatelessWidget {
  final String title;
  final String value;

  const _TrendMiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.74),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MonthSummaryBox extends StatelessWidget {
  final String title;
  final String value;

  const _MonthSummaryBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SandraDailyPoint {
  final DateTime day;
  final int minutes;

  const _SandraDailyPoint({required this.day, required this.minutes});
}

class _SandraLineChartPainter extends CustomPainter {
  final List<_SandraDailyPoint> points;
  final List<_SandraDailyPoint> previousPoints;

  const _SandraLineChartPainter({
    required this.points,
    required this.previousPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 1;

    final axisTextStyle = TextStyle(
      color: Colors.white.withOpacity(0.62),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    final chartLeft = 34.0;
    final chartRight = size.width - 10.0;
    final chartTop = 10.0;
    final chartBottom = size.height - 28.0;

    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final allPoints = [...points, ...previousPoints];

    final maxMinutes = allPoints.isEmpty
        ? 60
        : allPoints.map((p) => p.minutes).fold<int>(0, (a, b) => a > b ? a : b);

    final safeMax = maxMinutes <= 0 ? 60 : maxMinutes;
    final maxHours = (safeMax / 60).ceil().clamp(1, 999).toInt();

    for (int i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight * (i / 4);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final labelHours = ((maxHours * (4 - i) / 4) * 10).round() / 10;
      final painter = TextPainter(
        text: TextSpan(text: "${labelHours}h", style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(canvas, Offset(4, y - 7));
    }

    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFFFFCA28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final previousLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = const Color(0xFFFFCA28);

    if (previousPoints.length > 1) {
      final previousPath = Path();

      for (int i = 0; i < previousPoints.length; i++) {
        final x = chartLeft + chartWidth * (i / (previousPoints.length - 1));
        final hours = previousPoints[i].minutes / 60;
        final y = chartBottom - (hours / maxHours) * chartHeight;

        if (i == 0) {
          previousPath.moveTo(x, y);
        } else {
          previousPath.lineTo(x, y);
        }
      }

      canvas.drawPath(previousPath, previousLinePaint);
    }

    if (points.length == 1) {
      final x = chartLeft + chartWidth / 2;
      final y =
          chartBottom - ((points.first.minutes / 60) / maxHours) * chartHeight;

      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      _paintBottomLabel(
        canvas,
        "${points.first.day.day}/${points.first.day.month}",
        x - 12,
        chartBottom + 8,
      );

      return;
    }

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft + chartWidth * (i / (points.length - 1));
      final hours = points[i].minutes / 60;
      final y = chartBottom - (hours / maxHours) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft + chartWidth * (i / (points.length - 1));
      final hours = points[i].minutes / 60;
      final y = chartBottom - (hours / maxHours) * chartHeight;

      canvas.drawCircle(Offset(x, y), 3.2, dotPaint);
    }

    final isYearMode =
        points.length == 12 && points.every((p) => p.day.day == 1);

    if (isYearMode) {
      for (int i = 0; i < points.length; i++) {
        final x = chartLeft + chartWidth * (i / (points.length - 1));

        _paintBottomLabel(
          canvas,
          _monthShort(points[i].day.month),
          x - 10,
          chartBottom + 8,
        );
      }

      return;
    }

    final first = points.first.day;
    final last = points.last.day;

    _paintBottomLabel(
      canvas,
      "${first.day}/${first.month}",
      chartLeft,
      chartBottom + 8,
    );

    _paintBottomLabel(
      canvas,
      "${last.day}/${last.month}",
      chartRight - 28,
      chartBottom + 8,
    );
  }

  void _paintBottomLabel(Canvas canvas, String text, double x, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.60),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(x, y));
  }

  String _monthShort(int month) {
    const names = [
      "Gen",
      "Feb",
      "Mar",
      "Apr",
      "Mag",
      "Giu",
      "Lug",
      "Ago",
      "Set",
      "Ott",
      "Nov",
      "Dic",
    ];

    return names[month - 1];
  }

  @override
  bool shouldRepaint(covariant _SandraLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.previousPoints != previousPoints;
  }
}
