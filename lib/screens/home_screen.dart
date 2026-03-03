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
import '../frodo_calendario.dart';
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

  // ✅ CNC: azione reale da ActionIntent (senza logica IPS qui)
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

      // Placeholder futuri
      case snap.ActionTargetType.financeOverview:
      case snap.ActionTargetType.autoOverview:
      case snap.ActionTargetType.none:
        return;
    }
  }

  static final List<_HomeEvent> _oggiEvents = <_HomeEvent>[
    _HomeEvent(
      time: "07:30",
      title: "Esempio: Scuola Alice",
      category: "Famiglia",
      ipsImpact: true,
      notes: "Placeholder – verrà dal Calendario",
    ),
    _HomeEvent(
      time: "18:00",
      title: "Esempio: Spesa",
      category: "Scadenze",
      ipsImpact: false,
      notes: "Placeholder",
    ),
  ];

  static final List<_HomeDay> _next7Days = <_HomeDay>[
    _HomeDay(
      dayLabel: "Mer 26",
      events: [
        _HomeEvent(
          time: "09:00",
          title: "Esempio: Controllo",
          category: "Salute",
          ipsImpact: true,
        ),
        _HomeEvent(
          time: "17:30",
          title: "Esempio: Allenamento",
          category: "Famiglia",
          ipsImpact: false,
        ),
        _HomeEvent(
          time: "20:00",
          title: "Esempio: Bolletta",
          category: "Scadenze",
          ipsImpact: true,
        ),
        _HomeEvent(
          time: "21:00",
          title: "Extra (non visibile finché non espandi)",
          category: "Lavoro",
          ipsImpact: false,
        ),
      ],
    ),
    _HomeDay(
      dayLabel: "Gio 27",
      events: [
        _HomeEvent(
          time: "07:00",
          title: "Esempio: Turno",
          category: "Lavoro",
          ipsImpact: true,
        ),
      ],
    ),
  ];

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

                // ✅ AZIONE REALE (se esiste rt)
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
    return _buildCollapsibleSection(
      title: "OGGI",
      subtitle: "${_oggiEvents.length} evento/i",
      expanded: _oggiExpanded,
      onToggle: () => setState(() => _oggiExpanded = !_oggiExpanded),
      child: Column(
        children: _oggiEvents
            .map((e) => _buildEventRow(context, e))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildSectionProssimi7(BuildContext context) {
    final giorniConEventi = _next7Days.length;
    return _buildCollapsibleSection(
      title: "PROSSIMI 7 GIORNI",
      subtitle: "$giorniConEventi giorno/i con eventi",
      expanded: _prossimi7Expanded,
      onToggle: () => setState(() => _prossimi7Expanded = !_prossimi7Expanded),
      child: Column(
        children: _next7Days
            .map((day) {
              final maxVisibili = _prossimi7Expanded ? day.events.length : 3;
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
                    ...visibleEvents.map((e) => _buildEventRow(context, e)),
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
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text("Calendario"),
          subtitle: const Text("Blu – gestione eventi e navigazione"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CalendarioScreenStepAStabile(coreStore: coreStore),
              ),
            );

            ipsStore.refresh();
            setState(() {});
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text("Dashboard"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SpesePage()));
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.health_and_safety),
          title: const Text("Salute"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SaluteScreen()));
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.shield),
          title: const Text("Copertura"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CoperturaScreen(coreStore: coreStore),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text("Frodo Calendario (dev)"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FrodoCalendario()));
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
            width: 52,
            child: Text(e.time, style: const TextStyle(fontSize: 12)),
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
