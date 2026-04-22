// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import '../logic/ips_store.dart';
import '../logic/core_store.dart';
import '../logic/settings_store.dart';
import '../models/promemoria.dart';

// Modello IPS v1 (unica verità per Home)
import '../models/ips_snapshot.dart' as snap;

// Schermate moduli
import 'calendario_screen_stepa.dart';
import 'dashboard.dart';
import 'salute_screen.dart';
import 'copertura_screen.dart';

// Dettaglio IPS
import 'ips_detail_screen.dart';
import '../logic/reason_text_registry.dart';

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
        return const Color(0xFF43A047);
      case snap.IpsLevel.yellow:
        return const Color(0xFFFB8C00);
      case snap.IpsLevel.red:
        return const Color(0xFFE53935);
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
        return const Color(0xFF7B5E57);
      case "chiara":
        return const Color(0xFF5E8C61);
      case "alice":
        return const Color(0xFF5DADE2);
      case "famiglia":
        return const Color(0xFF8E44AD);
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    final todayPromemoria = _buildTodayPromemoria();
    final todayEvents = _buildTodayRealEvents();
    final next7Days = _buildNext7DaysReal();
    final groupedPromemoria = _groupPromemoriaByPersona(todayPromemoria);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutto sotto controllo oggi"),
        centerTitle: false,
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1220),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;

                    if (wide) {
                      return Column(
                        children: [
                          Row(
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildOggiCard(
                                  groupedPromemoria: groupedPromemoria,
                                  todayEvents: todayEvents,
                                  promemoriaCount: todayPromemoria.length,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildNext7DaysCard(
                                  next7Days: next7Days,
                                ),
                              ),
                            ],
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
                        ),
                        const SizedBox(height: 16),
                        _buildOggiCard(
                          groupedPromemoria: groupedPromemoria,
                          todayEvents: todayEvents,
                          promemoriaCount: todayPromemoria.length,
                        ),
                        const SizedBox(height: 16),
                        _buildNext7DaysCard(next7Days: next7Days),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildModulesSection(),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    "FrodoDesk • Organizzazione familiare intelligente",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tutto sotto controllo oggi 👋",
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w800,
            color: Colors.black.withOpacity(0.90),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Ecco la situazione aggiornata della tua organizzazione familiare",
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withOpacity(0.58),
            fontWeight: FontWeight.w500,
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
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_levelIcon(level), color: color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateText,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.88),
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
                            color: Colors.black.withOpacity(0.60),
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
                    color: const Color(0xFF43A047),
                  ),
                  _MiniInfoPill(
                    icon: Icons.schedule_send_rounded,
                    title: "Uscita 13",
                    value: settingsStore.isUscita13 ? "attiva" : "non attiva",
                    color: const Color(0xFFE53935),
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
  }) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Panoramica oggi",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.88),
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
              ),
              _MetricTile(
                icon: Icons.event_note_rounded,
                label: "Eventi",
                value: eventiCount.toString(),
                color: const Color(0xFF3F51B5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  color: Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Oggi",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$promemoriaCount promemoria • ${todayEvents.length} eventi",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (groupedPromemoria.isEmpty && todayEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 42,
                    color: Colors.black.withOpacity(0.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Nessun evento in programma",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.82),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "La tua giornata è libera 🎉",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (groupedPromemoria.isNotEmpty) ...[
              Text(
                "Da fare oggi",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Colors.black.withOpacity(0.86),
                ),
              ),
              const SizedBox(height: 10),
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
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.22)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForPersona(persona),
                              color: color,
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
                                          color: color,
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
              const SizedBox(height: 6),
              Text(
                "Succede oggi",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Colors.black.withOpacity(0.86),
                ),
              ),
              const SizedBox(height: 10),
              ...todayEvents
                  .take(2)
                  .map(
                    (e) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 78,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                    ),
                  ),
            ],
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
      ),
    );
  }

  Widget _buildNext7DaysCard({required List<_HomeDay> next7Days}) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prossimi 7 giorni",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next7Days.isEmpty
                          ? "Nessun giorno con eventi"
                          : "${next7Days.length} giorno/i con eventi",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (next7Days.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Text(
                "Nessun evento nei prossimi 7 giorni",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: next7Days.take(3).map((day) {
                final first = day.events.first;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF42A5F5).withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF42A5F5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.dayLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              first.title,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.75),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (day.events.length > 1) ...[
                              const SizedBox(height: 4),
                              Text(
                                "+${day.events.length - 1} altro/i",
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
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _openCalendarToday,
              child: const Text("Vedi calendario"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Moduli",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black.withOpacity(0.88),
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
                  startColor: const Color(0xFF7E57C2),
                  endColor: const Color(0xFF5E35B1),
                  onTap: _openCalendarToday,
                ),
                _DashboardModuleCard(
                  icon: Icons.favorite_rounded,
                  title: "Salute",
                  subtitle: "Monitora il benessere",
                  badge: "Disponibile",
                  badgeColor: const Color(0xFF26A69A),
                  startColor: const Color(0xFF80DEEA),
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
                  startColor: const Color(0xFFF3D7A8),
                  endColor: const Color(0xFFE7C58B),
                  onTap: () {},
                ),
                _DashboardModuleCard(
                  icon: Icons.receipt_long_rounded,
                  title: "Spese",
                  subtitle: "Traccia le spese",
                  badge: "Disponibile",
                  badgeColor: const Color(0xFF5D6D7E),
                  startColor: const Color(0xFF9CC7F5),
                  endColor: const Color(0xFF7FB3E8),
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
                  startColor: const Color(0xFF3949AB),
                  endColor: const Color(0xFF283593),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
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
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
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

class _DashboardModuleCardState extends State<_DashboardModuleCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.startColor, widget.endColor],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.08 : 0.14),
                blurRadius: _pressed ? 6 : 14,
                offset: Offset(0, _pressed ? 2 : 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w500,
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
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
