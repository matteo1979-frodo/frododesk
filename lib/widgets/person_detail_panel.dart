import 'package:flutter/material.dart';

import '../logic/alice_event_store.dart';
import '../logic/core_store.dart';
import '../logic/ferie_period_store.dart';
import '../logic/turn_engine.dart';
import '../screens/calendario_screen_stepa.dart';

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

  Future<void> _openCalendarToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final navigator = Navigator.of(context);
    navigator.pop();

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => CalendarioScreenStepAStabile(
          coreStore: widget.coreStore,
          initialSelectedDay: today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 790),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EC),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.personName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Vista personale della giornata e del mese",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: "Apri calendario",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openCalendarToday,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _todayBox(),
              const SizedBox(height: 18),
              _monthHeader(),
              const SizedBox(height: 14),
              _weekDaysHeader(),
              const SizedBox(height: 8),
              _miniCalendar(),
              const SizedBox(height: 18),
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
      return _infoBox("Stato di oggi: ${_aliceDayLabel(cleanToday)}");
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

  String _aliceDayLabel(DateTime date) {
    if (_isAliceSick(date)) return "Malattia";

    final alicePeriod = widget.coreStore.aliceEventStore.getEventForDay(date);

    if (alicePeriod != null) {
      switch (alicePeriod.type) {
        case AliceEventType.sickness:
          return "Malattia";
        case AliceEventType.summerCamp:
          return "Centro estivo";
        case AliceEventType.vacation:
          return "Vacanza";
        case AliceEventType.schoolClosure:
          return "Scuola chiusa";
        case AliceEventType.schoolNormal:
          return "Scuola normale";
      }
    }

    final hasAliceEvent = widget.coreStore.aliceSpecialEventStore
        .eventsForDay(date)
        .where((event) => event.enabled)
        .isNotEmpty;

    if (hasAliceEvent) return "Evento / attività";

    final uscitaAnticipata = widget.coreStore.daySettingsStore
        .uscitaAnticipataTimeForDay(date);

    if (uscitaAnticipata != null) return "Uscita anticipata";

    final schoolConfig = widget.coreStore.schoolStore.schoolDayConfigFor(date);
    if (schoolConfig != null && schoolConfig.enabled) {
      return "Scuola normale";
    }

    return "Scuola chiusa";
  }

  Widget _monthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3A1B), Color(0xFF6C8A3E)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F3A1B).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _monthTitle(visibleMonth),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          _monthArrow(
            icon: Icons.chevron_left_rounded,
            tooltip: "Mese precedente",
            onTap: () {
              setState(() {
                visibleMonth = DateTime(
                  visibleMonth.year,
                  visibleMonth.month - 1,
                  1,
                );
              });
            },
          ),
          const SizedBox(width: 8),
          _monthArrow(
            icon: Icons.chevron_right_rounded,
            tooltip: "Mese successivo",
            onTap: () {
              setState(() {
                visibleMonth = DateTime(
                  visibleMonth.year,
                  visibleMonth.month + 1,
                  1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _monthArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
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
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final isSunday = index == 6;

        return Center(
          child: Text(
            days[index],
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isSunday
                  ? const Color(0xFFC62828)
                  : Colors.black.withOpacity(0.62),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index < leadingEmptyCells) return const SizedBox.shrink();

        final dayNumber = index - leadingEmptyCells + 1;
        final date = DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
        final dotColor = _dotColorForDay(date);

        final today = DateTime.now();
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        final isSunday = date.weekday == DateTime.sunday;
        final isSaturday = date.weekday == DateTime.saturday;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isToday
                  ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]
                  : [Colors.white.withOpacity(0.96), const Color(0xFFEFE9DA)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? const Color(0xFFB08D57)
                  : isSunday
                  ? const Color(0xFFC62828).withOpacity(0.22)
                  : Colors.black.withOpacity(0.07),
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isToday ? 0.16 : 0.08),
                blurRadius: isToday ? 16 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 7,
                child: Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isSunday
                        ? const Color(0xFFC62828)
                        : isSaturday
                        ? Colors.black.withOpacity(0.68)
                        : Colors.black.withOpacity(0.86),
                  ),
                ),
              ),
              if (dotColor != null)
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.92),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withOpacity(0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              if (isToday)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F3A1B),
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
      if (_isAliceSick(date)) return Colors.red;

      final alicePeriod = widget.coreStore.aliceEventStore.getEventForDay(date);

      if (alicePeriod != null) {
        switch (alicePeriod.type) {
          case AliceEventType.sickness:
            return Colors.red;
          case AliceEventType.summerCamp:
            return Colors.green;
          case AliceEventType.vacation:
            return Colors.purple;
          case AliceEventType.schoolClosure:
            return Colors.grey;
          case AliceEventType.schoolNormal:
            return Colors.blue;
        }
      }

      final hasAliceEvent = widget.coreStore.aliceSpecialEventStore
          .eventsForDay(date)
          .where((event) => event.enabled)
          .isNotEmpty;

      if (hasAliceEvent) return Colors.green;

      final uscitaAnticipata = widget.coreStore.daySettingsStore
          .uscitaAnticipataTimeForDay(date);

      if (uscitaAnticipata != null) return Colors.orange;

      final schoolConfig = widget.coreStore.schoolStore.schoolDayConfigFor(
        date,
      );
      if (schoolConfig != null && schoolConfig.enabled) {
        return Colors.blue;
      }

      return Colors.grey;
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

    if (isSick) return Colors.red;

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

  bool _isAliceSick(DateTime date) {
    if (widget.coreStore.aliceEventStore.isSicknessDay(date)) {
      return true;
    }

    return widget.coreStore.diseasePeriodStore.all.any((p) {
      final day = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        p.startDate.year,
        p.startDate.month,
        p.startDate.day,
      );
      final end = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);

      return p.personId == "alice" && !day.isBefore(start) && !day.isAfter(end);
    });
  }

  FeriePerson? _feriePersonForCurrentPerson() {
    if (widget.personName == "Matteo") return FeriePerson.matteo;
    if (widget.personName == "Chiara") return FeriePerson.chiara;
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
        color: const Color(0xFFEFE9DA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB08D57).withOpacity(0.24)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _legend() {
    final isAlice = widget.personName == "Alice";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: isAlice
            ? const [
                _LegendItem(color: Colors.blue, label: "Scuola"),
                _LegendItem(
                  color: Colors.green,
                  label: "Evento / centro estivo",
                ),
                _LegendItem(color: Colors.orange, label: "Uscita anticipata"),
                _LegendItem(color: Colors.purple, label: "Vacanza"),
                _LegendItem(color: Colors.grey, label: "Scuola chiusa"),
                _LegendItem(color: Colors.red, label: "Malattia"),
              ]
            : const [
                _LegendItem(color: Colors.yellow, label: "Mattina"),
                _LegendItem(color: Colors.orange, label: "Pomeriggio"),
                _LegendItem(color: Colors.blue, label: "Notte"),
                _LegendItem(color: Colors.grey, label: "Riposo"),
                _LegendItem(color: Colors.green, label: "Ferie"),
                _LegendItem(color: Colors.red, label: "Malattia"),
              ],
      ),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
