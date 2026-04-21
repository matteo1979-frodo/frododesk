// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import '../logic/ips_store.dart';
import '../logic/core_store.dart';
import '../logic/settings_store.dart';

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
import '../models/promemoria.dart';

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
  bool _oggiExpanded = true;
  bool _prossimi7Expanded = false;

  CoreStore get coreStore => widget.coreStore;
  SettingsStore get settingsStore => coreStore.settingsStore;
  IpsStore get ipsStore => widget.ipsStore;

  Widget _dot(snap.IpsLevel level) {
    Color color;
    switch (level) {
      case snap.IpsLevel.green:
        color = Colors.green;
        break;
      case snap.IpsLevel.yellow:
        color = Colors.orange;
        break;
      case snap.IpsLevel.red:
        color = Colors.red;
        break;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  String _stateTextFromLevel(snap.IpsLevel level) {
    switch (level) {
      case snap.IpsLevel.green:
        return "Sistema stabilizzato — monitoraggio attivo";
      case snap.IpsLevel.yellow:
        return "Attenzione — pressione in aumento";
      case snap.IpsLevel.red:
        return "Criticità — intervento consigliato";
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoperturaScreen(coreStore: coreStore),
          ),
        );
        return;

      case snap.ActionTargetType.healthOverview:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SaluteScreen()));
        return;

      case snap.ActionTargetType.financeOverview:
      case snap.ActionTargetType.autoOverview:
      case snap.ActionTargetType.none:
        return;
    }
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

      final label = "${day.day}/${day.month}";

      result.add(_HomeDay(dayLabel: label, events: mappedEvents));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutto sotto controllo oggi"),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: "Aggiorna IPS (manuale)",
            onPressed: () {
              ipsStore.refresh();
              setState(() {});
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("IPS aggiornato")));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIpsBar(context),
            const SizedBox(height: 12),
            _buildSectionOggi(context),
            const SizedBox(height: 12),
            _buildSectionProssimi7(context),
            const SizedBox(height: 12),
            _buildModuli(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIpsBar(BuildContext context) {
    return ValueListenableBuilder<snap.IpsSnapshot>(
      valueListenable: ipsStore,
      builder: (context, v1, _) {
        final snap.IpsLevel level = v1.level;
        final bool ok = level == snap.IpsLevel.green;

        final registry = ReasonTextRegistry.build();
        final rt = (v1.dominantReasonKey.isEmpty)
            ? null
            : registry.lookup(v1.dominantModule, v1.dominantReasonKey);

        final String stateText = _stateTextFromLevel(level);

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => IpsDetailScreen(coreStore: coreStore),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Home IPS",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stateText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _dot(level),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rt == null
                      ? "Nessuna criticità rilevata."
                      : "${rt.title} - ${rt.description}",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: ok ? FontWeight.w400 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (rt != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () {
                        _handleActionIntent(
                          intent: rt.action,
                          fallbackDate: v1.referenceDate,
                        );
                      },
                      child: Text(rt.actionLabel),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  "Impostazioni attive: Sandra ${settingsStore.isSandraDisponibile ? "presente" : "assente"} • Uscita 13 ${settingsStore.isUscita13 ? "attiva" : "non attiva"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionOggi(BuildContext context) {
    final oggiEvents = _buildTodayRealEvents();
    final oggiPromemoria = _buildTodayPromemoria();
    return _buildCollapsibleSection(
      title: "OGGI",
      subtitle:
          "${oggiPromemoria.length} promemoria • ${oggiEvents.length} evento/i",
      expanded: _oggiExpanded,
      onToggle: () => setState(() => _oggiExpanded = !_oggiExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Da fare oggi",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          if (oggiPromemoria.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "• Nessun promemoria per oggi",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: oggiPromemoria
                  .map((p) => Text("• ${p.testo}"))
                  .toList(),
            ),

          const SizedBox(height: 6),
          const Text(
            "Succede oggi",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          if (oggiEvents.isEmpty)
            Text(
              "• Nessun evento per oggi",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: oggiEvents
                  .map((e) => _buildEventRow(context, e))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionProssimi7(BuildContext context) {
    final next7Days = _buildNext7DaysReal();
    final giorniConEventi = next7Days.length;

    return _buildCollapsibleSection(
      title: "PROSSIMI 7 GIORNI",
      subtitle: "$giorniConEventi giorno/i con eventi",
      expanded: _prossimi7Expanded,
      onToggle: () => setState(() => _prossimi7Expanded = !_prossimi7Expanded),
      child: next7Days.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "• Nessun evento nei prossimi 7 giorni",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : Column(
              children: next7Days
                  .map((day) {
                    final maxVisibili = _prossimi7Expanded
                        ? day.events.length
                        : 3;
                    final visibleEvents = day.events.take(maxVisibili).toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.dayLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...visibleEvents.map(
                            (e) => _buildEventRow(context, e),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildModuli(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MODULI", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 3;

            if (constraints.maxWidth > 900) {
              crossAxisCount = 5;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _AnimatedAppIcon(
                  icon: Icons.calendar_month,
                  label: "Calendario",
                  color: const Color(0xFF8D6E63),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CalendarioScreenStepAStabile(coreStore: coreStore),
                      ),
                    );
                    ipsStore.refresh();
                    if (mounted) setState(() {});
                  },
                ),
                _AnimatedAppIcon(
                  icon: Icons.favorite,
                  label: "Salute",
                  color: const Color(0xFF6D8B74),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SaluteScreen()),
                    );
                  },
                ),
                _AnimatedAppIcon(
                  icon: Icons.euro,
                  label: "Finanze",
                  color: const Color(0xFFB08D57),
                  onTap: () {},
                ),
                _AnimatedAppIcon(
                  icon: Icons.receipt_long,
                  label: "Spese",
                  color: const Color(0xFF5D6D7E),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpesePage()),
                    );
                  },
                ),
                _AnimatedAppIcon(
                  icon: Icons.shield,
                  label: "Copertura",
                  color: const Color(0xFF3E2723),
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

  Widget _buildCollapsibleSection({
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (expanded) ...[const SizedBox(height: 10), child],
        ],
      ),
    );
  }

  Widget _buildEventRow(BuildContext context, _HomeEvent e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              e.time,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(e.category, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _AnimatedAppIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedAppIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<_AnimatedAppIcon> {
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
        scale: _pressed ? 0.94 : 1.0,
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_pressed ? 0.10 : 0.22),
                    blurRadius: _pressed ? 3 : 8,
                    offset: Offset(0, _pressed ? 1 : 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
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
