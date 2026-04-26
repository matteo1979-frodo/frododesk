// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import '../logic/ips_store.dart';
import '../logic/reason_text_registry.dart';
import '../logic/settings_store.dart';
import '../models/ips_snapshot.dart' as snap;
import '../models/promemoria.dart';
import 'calendario_screen_stepa.dart';
import 'copertura_screen.dart';
import 'dashboard.dart';
import 'ips_detail_screen.dart';
import 'salute_screen.dart';

class HomeScreen extends StatefulWidget {
  final IpsStore ipsStore;
  final CoreStore coreStore;

  const HomeScreen({
    super.key,
    required this.ipsStore,
    required this.coreStore,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CoreStore get coreStore => widget.coreStore;
  SettingsStore get settingsStore => coreStore.settingsStore;
  IpsStore get ipsStore => widget.ipsStore;

  String _stateTextFromLevel(snap.IpsLevel level) {
    switch (level) {
      case snap.IpsLevel.green:
        return "Sistema stabilizzato";
      case snap.IpsLevel.yellow:
        return "Attenzione";
      case snap.IpsLevel.red:
        return "Criticità";
    }
  }

  Color _levelColor(snap.IpsLevel level) {
    switch (level) {
      case snap.IpsLevel.green:
        return const Color(0xFF8BC34A);
      case snap.IpsLevel.yellow:
        return const Color(0xFFFFB300);
      case snap.IpsLevel.red:
        return const Color(0xFFE57373);
    }
  }

  IconData _levelIcon(snap.IpsLevel level) {
    switch (level) {
      case snap.IpsLevel.green:
        return Icons.check_rounded;
      case snap.IpsLevel.yellow:
        return Icons.priority_high_rounded;
      case snap.IpsLevel.red:
        return Icons.warning_amber_rounded;
    }
  }

  Future<void> _handleActionIntent({
    required snap.ActionIntent intent,
    required DateTime fallbackDate,
  }) async {
    switch (intent.target) {
      case snap.ActionTargetType.calendarDay:
        final DateTime targetDay = intent.payload.referenceDate ?? fallbackDate;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CalendarioScreenStepAStabile(
              coreStore: coreStore,
              initialSelectedDay: targetDay,
            ),
          ),
        );

        ipsStore.refresh();
        if (mounted) setState(() {});
        return;

      case snap.ActionTargetType.coverage:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoperturaScreen(coreStore: coreStore),
          ),
        );
        if (mounted) setState(() {});
        return;

      case snap.ActionTargetType.healthOverview:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SaluteScreen()));
        if (mounted) setState(() {});
        return;

      case snap.ActionTargetType.financeOverview:
      case snap.ActionTargetType.autoOverview:
      case snap.ActionTargetType.none:
        return;
    }
  }

  Future<void> _openCalendarToday() async {
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

    ipsStore.refresh();
    if (mounted) setState(() {});
  }

  List<Promemoria> _buildTodayPromemoria() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final store = coreStore.promemoriaStore;
    final items = store.items;

    return items.where((p) {
      final created = DateTime(
        p.createdDay.year,
        p.createdDay.month,
        p.createdDay.day,
      );

      final completed = p.completedDay == null
          ? null
          : DateTime(
              p.completedDay!.year,
              p.completedDay!.month,
              p.completedDay!.day,
            );

      final isVisible =
          (created.isBefore(today) || created == today) &&
          (!p.done || completed == today);

      return isVisible;
    }).toList();
  }

  List<_HomeEvent> _buildTodayRealEvents() {
    final day = DateTime.now();
    final selectedDay = DateTime(day.year, day.month, day.day);

    final realEvents = coreStore.realEventStore.eventsForDay(selectedDay);

    final items = realEvents.map((e) {
      String time = "Tutto il giorno";

      if (e.startTime != null && e.endTime != null) {
        final sh = e.startTime!.hour.toString().padLeft(2, '0');
        final sm = e.startTime!.minute.toString().padLeft(2, '0');
        final eh = e.endTime!.hour.toString().padLeft(2, '0');
        final em = e.endTime!.minute.toString().padLeft(2, '0');
        time = "$sh:$sm-$eh:$em";
      } else if (e.startTime != null) {
        final sh = e.startTime!.hour.toString().padLeft(2, '0');
        final sm = e.startTime!.minute.toString().padLeft(2, '0');
        time = "$sh:$sm";
      }

      final category = (e.personKey == null || e.personKey!.trim().isEmpty)
          ? "Evento"
          : e.personKey!;

      return _HomeEvent(
        time: time,
        title: e.title,
        category: category,
        ipsImpact: true,
        notes: null,
      );
    }).toList();

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  List<_HomeDay> _buildNext7DaysReal() {
    final now = DateTime.now();
    final List<_HomeDay> result = [];

    for (int i = 1; i <= 7; i++) {
      final day = now.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);

      final events = coreStore.realEventStore.eventsForDay(dayKey);
      if (events.isEmpty) continue;

      final mappedEvents = events.map((e) {
        String time = "Tutto il giorno";

        if (e.startTime != null && e.endTime != null) {
          final sh = e.startTime!.hour.toString().padLeft(2, '0');
          final sm = e.startTime!.minute.toString().padLeft(2, '0');
          final eh = e.endTime!.hour.toString().padLeft(2, '0');
          final em = e.endTime!.minute.toString().padLeft(2, '0');
          time = "$sh:$sm-$eh:$em";
        } else if (e.startTime != null) {
          final sh = e.startTime!.hour.toString().padLeft(2, '0');
          final sm = e.startTime!.minute.toString().padLeft(2, '0');
          time = "$sh:$sm";
        }

        final category = (e.personKey == null || e.personKey!.trim().isEmpty)
            ? "Evento"
            : e.personKey!;

        return _HomeEvent(
          time: time,
          title: e.title,
          category: category,
          ipsImpact: true,
          notes: null,
        );
      }).toList();

      mappedEvents.sort((a, b) => a.time.compareTo(b.time));

      final weekday = [
        "Lun",
        "Mar",
        "Mer",
        "Gio",
        "Ven",
        "Sab",
        "Dom",
      ][day.weekday - 1];

      final label = "$weekday ${day.day}/${day.month}";
      result.add(_HomeDay(dayLabel: label, events: mappedEvents));
    }

    return result;
  }

  Map<String, List<Promemoria>> _groupPromemoriaByPersona(
    List<Promemoria> items,
  ) {
    final Map<String, List<Promemoria>> grouped = {};

    for (final p in items) {
      grouped.putIfAbsent(p.persona, () => []).add(p);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => _personaOrder(a.key).compareTo(_personaOrder(b.key)));

    return {for (final e in entries) e.key: e.value};
  }

  int _personaOrder(String persona) {
    switch (persona.toLowerCase()) {
      case "matteo":
        return 0;
      case "chiara":
        return 1;
      case "alice":
        return 2;
      case "famiglia":
        return 3;
      default:
        return 99;
    }
  }

  Color _colorForPersona(String persona) {
    switch (persona.toLowerCase()) {
      case "matteo":
        return const Color(0xFFD7CCC8);
      case "chiara":
        return const Color(0xFFC8E6C9);
      case "alice":
        return const Color(0xFFBBDEFB);
      case "famiglia":
        return const Color(0xFFE1BEE7);
      default:
        return Colors.grey.shade300;
    }
  }

  IconData _iconForPersona(String persona) {
    switch (persona.toLowerCase()) {
      case "matteo":
        return Icons.person_rounded;
      case "chiara":
        return Icons.person_rounded;
      case "alice":
        return Icons.child_care_rounded;
      case "famiglia":
        return Icons.family_restroom_rounded;
      default:
        return Icons.label_rounded;
    }
  }

  Future<void> _showHomeDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.84),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black.withOpacity(0.88),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.25,
                                  color: Colors.black.withOpacity(0.60),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: "Chiudi",
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTodayPopup({
    required Map<String, List<Promemoria>> groupedPromemoria,
    required List<_HomeEvent> todayEvents,
    required int promemoriaCount,
  }) async {
    await _showHomeDialog(
      icon: Icons.today_rounded,
      color: const Color(0xFF43A047),
      title: "Oggi",
      subtitle: "Promemoria ed eventi reali della giornata",
      child: _buildOggiDialogContent(
        groupedPromemoria: groupedPromemoria,
        todayEvents: todayEvents,
        promemoriaCount: promemoriaCount,
      ),
    );
  }

  Future<void> _showNext7DaysPopup({required List<_HomeDay> next7Days}) async {
    await _showHomeDialog(
      icon: Icons.date_range_rounded,
      color: const Color(0xFF42A5F5),
      title: "Prossimi 7 giorni",
      subtitle: "Panoramica rapida dei giorni con eventi in arrivo",
      child: _buildNext7DaysDialogContent(next7Days: next7Days),
    );
  }

  Future<void> _showEventsPopup({required List<_HomeEvent> todayEvents}) async {
    await _showHomeDialog(
      icon: Icons.event_note_rounded,
      color: const Color(0xFF3F51B5),
      title: "Eventi",
      subtitle: todayEvents.isEmpty
          ? "Nessun evento presente oggi"
          : "${todayEvents.length} evento/i della giornata",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todayEvents.isEmpty)
            _buildDialogEmptyState(
              icon: Icons.event_note_rounded,
              title: "Nessun evento oggi",
              subtitle: "La giornata è libera 🎉",
            )
          else
            ...todayEvents.map(_buildCompactEventTile),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openCalendarToday,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text("Vai al calendario"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Colors.black.withOpacity(0.86),
        ),
      ),
    );
  }

  Widget _buildDialogEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.black.withOpacity(0.45)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEventTile(_HomeEvent e) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.42)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              e.time,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  e.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOggiDialogContent({
    required Map<String, List<Promemoria>> groupedPromemoria,
    required List<_HomeEvent> todayEvents,
    required int promemoriaCount,
  }) {
    if (groupedPromemoria.isEmpty && todayEvents.isEmpty) {
      return _buildDialogEmptyState(
        icon: Icons.event_available_rounded,
        title: "Nessun evento in programma",
        subtitle: "La tua giornata è libera 🎉",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$promemoriaCount promemoria • ${todayEvents.length} eventi",
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        if (groupedPromemoria.isNotEmpty) ...[
          _buildSectionTitle("Da fare oggi"),
          ...groupedPromemoria.entries.map((entry) {
            final persona = entry.key;
            final list = entry.value;
            final color = _colorForPersona(persona);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openCalendarToday,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.42),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForPersona(persona),
                          color: Colors.black.withOpacity(0.74),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "$persona (${list.length})",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black.withOpacity(0.82),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              list.first.testo,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black.withOpacity(0.82),
                              ),
                            ),
                            if (list.length > 1) ...[
                              const SizedBox(height: 4),
                              Text(
                                "+${list.length - 1} altro/i",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        if (todayEvents.isNotEmpty) ...[
          if (groupedPromemoria.isNotEmpty) const SizedBox(height: 8),
          _buildSectionTitle("Succede oggi"),
          ...todayEvents.map(_buildCompactEventTile),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _openCalendarToday,
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text("Apri calendario"),
          ),
        ),
      ],
    );
  }

  Widget _buildNext7DaysDialogContent({required List<_HomeDay> next7Days}) {
    if (next7Days.isEmpty) {
      return _buildDialogEmptyState(
        icon: Icons.date_range_rounded,
        title: "Nessun evento nei prossimi 7 giorni",
        subtitle: "Per ora la settimana sembra tranquilla",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${next7Days.length} giorno/i con eventi",
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        ...next7Days.map((day) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.dayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...day.events.map(_buildCompactEventTile),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _openCalendarToday,
            child: const Text("Vedi calendario"),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsDialogContent({
    required List<_HomeEvent> todayEvents,
    required List<_HomeDay> next7Days,
  }) {
    final totalEvents =
        todayEvents.length +
        next7Days.fold<int>(0, (sum, day) => sum + day.events.length);

    if (totalEvents == 0) {
      return _buildDialogEmptyState(
        icon: Icons.event_note_rounded,
        title: "Nessun evento da mostrare",
        subtitle:
            "La Home non sta leggendo eventi tra oggi e i prossimi 7 giorni",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayEvents.isNotEmpty) ...[
          _buildSectionTitle("Oggi"),
          ...todayEvents.map(_buildCompactEventTile),
          const SizedBox(height: 8),
        ],
        if (next7Days.isNotEmpty) ...[
          _buildSectionTitle("Prossimi 7 giorni"),
          ...next7Days.map((day) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.68),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.38)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.dayLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withOpacity(0.84),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...day.events.map(_buildCompactEventTile),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayPromemoria = _buildTodayPromemoria();
    final todayEvents = _buildTodayRealEvents();
    final next7Days = _buildNext7DaysReal();
    final groupedPromemoria = _groupPromemoriaByPersona(todayPromemoria);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("FrodoDesk"),
        actions: [
          IconButton(
            tooltip: "Aggiorna",
            onPressed: () {
              ipsStore.refresh();
              setState(() {});
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Home aggiornata")));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.22),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 980;

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildSystemStatusCard()),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPanoramicaOggiCard(
                                  promemoriaCount: todayPromemoria.length,
                                  eventiCount: todayEvents.length,
                                  personeCount: groupedPromemoria.length,
                                  prossimiGiorniCount: next7Days.length,
                                  onPromemoriaTap: () => _showTodayPopup(
                                    groupedPromemoria: groupedPromemoria,
                                    todayEvents: todayEvents,
                                    promemoriaCount: todayPromemoria.length,
                                  ),
                                  onEventiTap: () => _showEventsPopup(
                                    todayEvents: todayEvents,
                                  ),
                                  onNext7DaysTap: () =>
                                      _showNext7DaysPopup(next7Days: next7Days),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildSystemStatusCard(),
                            const SizedBox(height: 16),
                            _buildPanoramicaOggiCard(
                              promemoriaCount: todayPromemoria.length,
                              eventiCount: todayEvents.length,
                              personeCount: groupedPromemoria.length,
                              prossimiGiorniCount: next7Days.length,
                              onPromemoriaTap: () => _showTodayPopup(
                                groupedPromemoria: groupedPromemoria,
                                todayEvents: todayEvents,
                                promemoriaCount: todayPromemoria.length,
                              ),
                              onEventiTap: () =>
                                  _showEventsPopup(todayEvents: todayEvents),
                              onNext7DaysTap: () =>
                                  _showNext7DaysPopup(next7Days: next7Days),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildModulesSection(),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        "FrodoDesk • Organizzazione familiare intelligente",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Bentornato, Matteo 👋",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.8,
            shadows: [
              Shadow(blurRadius: 18, color: Colors.black.withOpacity(0.28)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Ecco la situazione aggiornata della tua organizzazione familiare",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.25)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatusCard() {
    return ValueListenableBuilder<snap.IpsSnapshot>(
      valueListenable: ipsStore,
      builder: (context, v1, _) {
        final level = v1.level;
        final registry = ReasonTextRegistry.build();
        final rt = (v1.dominantReasonKey.isEmpty)
            ? null
            : registry.lookup(v1.dominantModule, v1.dominantReasonKey);

        final color = _levelColor(level);
        final stateText = _stateTextFromLevel(level);

        return _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Icon(_levelIcon(level), color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rt == null
                              ? "Copertura stabile • Nei prossimi 30 giorni non risultano buchi di copertura."
                              : "${rt.title} • ${rt.description}",
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.25,
                            color: Colors.white.withOpacity(0.88),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MiniActionChip(
                    icon: Icons.calendar_today_rounded,
                    label: "Apri calendario",
                    onTap: _openCalendarToday,
                  ),
                  _MiniInfoPill(
                    icon: Icons.tune_rounded,
                    title: "Sandra",
                    value: settingsStore.isSandraDisponibile
                        ? "presente"
                        : "assente",
                    color: const Color(0xFFA5D6A7),
                  ),
                  _MiniInfoPill(
                    icon: Icons.schedule_send_rounded,
                    title: "Uscita 13",
                    value: settingsStore.isUscita13 ? "attiva" : "non attiva",
                    color: const Color(0xFFFFAB91),
                  ),
                  _MiniActionChip(
                    icon: Icons.analytics_outlined,
                    label: "Dettaglio IPS",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IpsDetailScreen(coreStore: coreStore),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanoramicaOggiCard({
    required int promemoriaCount,
    required int eventiCount,
    required int personeCount,
    required int prossimiGiorniCount,
    required VoidCallback onPromemoriaTap,
    required VoidCallback onEventiTap,
    required VoidCallback onNext7DaysTap,
  }) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Panoramica oggi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MetricTile(
                icon: Icons.notifications_none_rounded,
                label: "Promemoria",
                value: promemoriaCount.toString(),
                color: const Color(0xFF7E57C2),
                onTap: onPromemoriaTap,
              ),
              _MetricTile(
                icon: Icons.event_note_rounded,
                label: "Eventi",
                value: eventiCount.toString(),
                color: const Color(0xFF3F51B5),
                onTap: onEventiTap,
              ),
              _MetricTile(
                icon: Icons.groups_2_rounded,
                label: "Persone",
                value: personeCount.toString(),
                color: const Color(0xFF26A69A),
              ),
              _MetricTile(
                icon: Icons.upcoming_rounded,
                label: "Nei 7 giorni",
                value: prossimiGiorniCount.toString(),
                color: const Color(0xFFEC407A),
                onTap: onNext7DaysTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOggiCard({
    required Map<String, List<Promemoria>> groupedPromemoria,
    required List<_HomeEvent> todayEvents,
    required int promemoriaCount,
  }) {
    return _DashboardCard(
      child: _buildOggiDialogContent(
        groupedPromemoria: groupedPromemoria,
        todayEvents: todayEvents,
        promemoriaCount: promemoriaCount,
      ),
    );
  }

  Widget _buildNext7DaysCard({required List<_HomeDay> next7Days}) {
    return _DashboardCard(
      child: _buildNext7DaysDialogContent(next7Days: next7Days),
    );
  }

  Widget _buildModulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            "Moduli",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;

            if (constraints.maxWidth >= 1100) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth >= 850) {
              crossAxisCount = 3;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: constraints.maxWidth >= 1100 ? 0.86 : 0.95,
              children: [
                _DashboardModuleCard(
                  icon: Icons.calendar_month_rounded,
                  title: "Calendario",
                  subtitle: "Gestisci turni, eventi e promemoria",
                  badge: "Attivo",
                  badgeColor: const Color(0xFF43A047),
                  startColor: const Color(0xFF7C4DFF),
                  endColor: const Color(0xFFB388FF),
                  onTap: _openCalendarToday,
                ),
                _DashboardModuleCard(
                  icon: Icons.favorite_rounded,
                  title: "Salute",
                  subtitle: "Monitora il benessere",
                  badge: "Disponibile",
                  badgeColor: const Color(0xFF26A69A),
                  startColor: const Color(0xFF1AA7B8),
                  endColor: const Color(0xFF4DD0E1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaluteScreen()),
                    );
                  },
                ),
                _DashboardModuleCard(
                  icon: Icons.euro_rounded,
                  title: "Finanze",
                  subtitle: "Controlla le finanze",
                  badge: "Presto disponibile",
                  badgeColor: const Color(0xFFB08D57),
                  startColor: const Color(0xFF8D6E63),
                  endColor: const Color(0xFFBCAAA4),
                  onTap: () {},
                ),
                _DashboardModuleCard(
                  icon: Icons.receipt_long_rounded,
                  title: "Spese",
                  subtitle: "Traccia le spese",
                  badge: "Disponibile",
                  badgeColor: const Color(0xFF5D6D7E),
                  startColor: const Color(0xFF3FA2D6),
                  endColor: const Color(0xFF7FDBFF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpesePage()),
                    );
                  },
                ),
                _DashboardModuleCard(
                  icon: Icons.shield_rounded,
                  title: "Copertura",
                  subtitle: "Analizza la copertura",
                  badge: "Disponibile",
                  badgeColor: const Color(0xFF3E2723),
                  startColor: const Color(0xFF243B87),
                  endColor: const Color(0xFF3949AB),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoperturaScreen(coreStore: coreStore),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;

  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.28), color.withOpacity(0.12)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 ICONA FRODODESK PRO
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(1), color.withOpacity(0.65)],
                  ),
                  boxShadow: [
                    // glow esterno
                    BoxShadow(
                      color: color.withOpacity(0.65),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    // ombra sotto (profondità)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ✨ luce sopra (effetto reale)
                    Positioned(
                      top: 6,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(child: Icon(icon, color: Colors.white, size: 26)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return tile;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: tile,
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.34)),
        backgroundColor: Colors.white.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MiniInfoPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardModuleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color startColor;
  final Color endColor;
  final VoidCallback onTap;

  const _DashboardModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.startColor,
    required this.endColor,
    required this.onTap,
  });

  @override
  State<_DashboardModuleCard> createState() => _DashboardModuleCardState();
}

class _DashboardModuleCardState extends State<_DashboardModuleCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 110),
            scale: _pressed ? 0.97 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.startColor.withOpacity(0.35),
                    widget.endColor.withOpacity(0.20),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: widget.startColor.withOpacity(
                      0.20 + (_glowController.value * 0.25),
                    ),
                    blurRadius: 30 + (_glowController.value * 20),
                    spreadRadius: -12 + (_glowController.value * 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          widget.startColor.withOpacity(0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.startColor.withOpacity(
                            0.50 + (_glowController.value * 0.25),
                          ),
                          blurRadius: 22 + (_glowController.value * 8),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 6,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            widget.icon,
                            color: widget.startColor,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Text(
                      widget.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeEvent {
  final String time;
  final String title;
  final String category;
  final bool ipsImpact;
  final String? notes;

  const _HomeEvent({
    required this.time,
    required this.title,
    required this.category,
    required this.ipsImpact,
    this.notes,
  });
}

class _HomeDay {
  final String dayLabel;
  final List<_HomeEvent> events;

  const _HomeDay({required this.dayLabel, required this.events});
}

class _ShireBackground extends StatelessWidget {
  const _ShireBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF7FB3D5),
                  Color(0xFFE5B96A),
                  Color(0xFF6C8A3E),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFF3C4).withOpacity(0.92),
                  const Color(0xFFFFE08A).withOpacity(0.50),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _ShirePainter())),
        Positioned(
          left: -40,
          bottom: 140,
          child: _HobbitHouse(width: 170, doorColor: const Color(0xFF2E5D34)),
        ),
        Positioned(
          right: 16,
          bottom: 160,
          child: _HobbitHouse(
            width: 110,
            doorColor: const Color(0xFF3F5C2A),
            small: true,
          ),
        ),
      ],
    );
  }
}

class _HobbitHouse extends StatelessWidget {
  final double width;
  final Color doorColor;
  final bool small;

  const _HobbitHouse({
    required this.width,
    required this.doorColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 0.82;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF61853B), const Color(0xFF3F5F23)],
                ),
              ),
            ),
          ),
          Positioned(
            left: width * 0.12,
            right: width * 0.12,
            bottom: height * 0.18,
            child: Container(
              height: height * 0.46,
              decoration: BoxDecoration(
                color: const Color(0xFF4C311B),
                borderRadius: BorderRadius.circular(width),
                border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
              ),
            ),
          ),
          Positioned(
            bottom: height * 0.19,
            child: Container(
              width: width * 0.40,
              height: width * 0.40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: doorColor,
                border: Border.all(color: const Color(0xFF6E4C22), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: width * 0.035,
                  height: width * 0.035,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8D7A0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          if (!small)
            Positioned(
              left: width * 0.06,
              bottom: height * 0.10,
              child: Container(
                width: width * 0.14,
                height: width * 0.14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD180).withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Positioned(
            left: width * 0.22,
            bottom: 0,
            right: width * 0.22,
            child: Container(
              height: height * 0.10,
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63).withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hill1 = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FA34C), Color(0xFF486D2E)],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.38, size.width, size.height),
          );

    final path1 = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.48,
        size.width * 0.42,
        size.height * 0.60,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.70,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, hill1);

    final hill2 = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF93B05C), Color(0xFF5A7E38)],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.48, size.width, size.height),
          );

    final path2 = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.58,
        size.width * 0.34,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.82,
        size.width * 0.70,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.56,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, hill2);

    final hill3 = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB7C97F), Color(0xFF709048)],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.52, size.width, size.height),
          );

    final path3 = Path()
      ..moveTo(0, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.66,
        size.width * 0.46,
        size.height * 0.83,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.96,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, hill3);

    final treePaint = Paint()
      ..color = const Color(0xFF1F3A1B).withOpacity(0.82);

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.17),
      95,
      treePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.07, size.height * 0.10),
      80,
      treePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.14),
      88,
      treePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.10),
      70,
      treePaint,
    );

    final trunk = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.065, size.height * 0.18, 16, 135),
      trunk,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.905, size.height * 0.17, 16, 150),
      trunk,
    );

    final glow = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);

    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.34), 130, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
