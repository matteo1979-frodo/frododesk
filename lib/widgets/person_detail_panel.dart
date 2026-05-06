import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import '../logic/ferie_period_store.dart';
import '../logic/turn_engine.dart';
import '../models/disease_period.dart';

class PersonDetailPanel extends StatefulWidget {
  final String personName;
  final CoreStore coreStore;

  const PersonDetailPanel({
    super.key,
    required this.personName,
    required this.coreStore,
  });

  @override
  State<PersonDetailPanel> createState() => _PersonDetailPanelState();
}

class _PersonDetailPanelState extends State<PersonDetailPanel> {
  late DateTime visibleMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    visibleMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.personName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Vista personale della giornata e del mese",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              _todayBox(),

              const SizedBox(height: 18),

              _monthHeader(),

              const SizedBox(height: 12),

              _weekDaysHeader(),

              const SizedBox(height: 8),

              _miniCalendar(),

              const SizedBox(height: 16),

              _legend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayBox() {
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    if (widget.personName == "Alice") {
      return _infoBox("Stato di oggi: scuola/eventi/copertura da collegare");
    }

    final feriePerson = _feriePersonForCurrentPerson();
    if (feriePerson != null &&
        widget.coreStore.feriePeriodStore.isOnHoliday(
          feriePerson,
          cleanToday,
        )) {
      return _infoBox("Stato di oggi: Ferie");
    }

    final person = widget.personName == "Matteo"
        ? TurnPerson.matteo
        : TurnPerson.chiara;

    final plan = widget.coreStore.turnEngine.turnPlanForPersonDay(
      person: person,
      day: cleanToday,
    );

    return _infoBox("Turno di oggi: ${_turnLabel(plan.type)}");
  }

  Widget _monthHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _monthTitle(visibleMonth),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: "Mese precedente",
          onPressed: () {
            setState(() {
              visibleMonth = DateTime(
                visibleMonth.year,
                visibleMonth.month - 1,
                1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: "Mese successivo",
          onPressed: () {
            setState(() {
              visibleMonth = DateTime(
                visibleMonth.year,
                visibleMonth.month + 1,
                1,
              );
            });
          },
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _weekDaysHeader() {
    const days = ["L", "M", "M", "G", "V", "S", "D"];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            days[index],
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        );
      },
    );
  }

  Widget _miniCalendar() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmptyCells = firstDay.weekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - leadingEmptyCells + 1;
        final date = DateTime(visibleMonth.year, visibleMonth.month, dayNumber);

        final dotColor = _dotColorForDay(date);

        final today = DateTime.now();
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        return Container(
          decoration: BoxDecoration(
            color: isToday
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? Colors.black.withOpacity(0.45)
                  : Colors.black.withOpacity(0.08),
              width: isToday ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isToday
                        ? Colors.black
                        : Colors.black.withOpacity(0.78),
                  ),
                ),
              ),
              if (dotColor != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color? _dotColorForDay(DateTime date) {
    if (widget.personName == "Alice") {
      return null;
    }
    final personId = widget.personName.toLowerCase();

    final isSick = widget.coreStore.diseasePeriodStore.all.any((p) {
      final day = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        p.startDate.year,
        p.startDate.month,
        p.startDate.day,
      );
      final end = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);

      return p.personId == personId &&
          !day.isBefore(start) &&
          !day.isAfter(end);
    });

    if (isSick) {
      return Colors.red;
    }
    final feriePerson = _feriePersonForCurrentPerson();

    if (feriePerson != null &&
        widget.coreStore.feriePeriodStore.isOnHoliday(feriePerson, date)) {
      return Colors.green;
    }

    final person = widget.personName == "Matteo"
        ? TurnPerson.matteo
        : TurnPerson.chiara;

    final plan = widget.coreStore.turnEngine.turnPlanForPersonDay(
      person: person,
      day: date,
    );

    switch (plan.type) {
      case TurnType.mattina:
        return Colors.yellow;
      case TurnType.pomeriggio:
        return Colors.orange;
      case TurnType.notte:
        return Colors.blue;
      case TurnType.off:
        return Colors.grey;
    }
  }

  FeriePerson? _feriePersonForCurrentPerson() {
    if (widget.personName == "Matteo") {
      return FeriePerson.matteo;
    }

    if (widget.personName == "Chiara") {
      return FeriePerson.chiara;
    }

    return null;
  }

  String _turnLabel(TurnType type) {
    switch (type) {
      case TurnType.mattina:
        return "Mattina";
      case TurnType.pomeriggio:
        return "Pomeriggio";
      case TurnType.notte:
        return "Notte";
      case TurnType.off:
        return "Riposo";
    }
  }

  String _monthTitle(DateTime date) {
    final months = [
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

    return "${months[date.month - 1]} ${date.year}";
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _LegendItem(color: Colors.yellow, label: "Mattina"),
        _LegendItem(color: Colors.orange, label: "Pomeriggio"),
        _LegendItem(color: Colors.blue, label: "Notte"),
        _LegendItem(color: Colors.grey, label: "Riposo"),
        _LegendItem(color: Colors.green, label: "Ferie"),
        _LegendItem(color: Colors.red, label: "Malattia"),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
