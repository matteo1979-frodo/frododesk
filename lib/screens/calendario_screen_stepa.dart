// lib/screens/calendario_screen_stepa.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/override_store.dart';
import '../logic/emergency_store.dart';
import '../logic/emergency_day_logic.dart';
import '../logic/coverage_engine.dart';
import '../logic/turn_engine.dart';

import '../models/day_override.dart';
import '../logic/core_store.dart';
import '../models/week_identity.dart';
import '../logic/settings_store.dart';
import '../logic/ips_store.dart';
import '../logic/day_settings_store.dart';

class CalendarioScreenStepAStabile extends StatefulWidget {
  final CoreStore coreStore;
  final DateTime? initialSelectedDay;

  const CalendarioScreenStepAStabile({
    super.key,
    required this.coreStore,
    this.initialSelectedDay,
  });

  @override
  State<CalendarioScreenStepAStabile> createState() =>
      _CalendarioScreenStepAStabileState();
}

class _CalendarioScreenStepAStabileState
    extends State<CalendarioScreenStepAStabile> {
  CoreStore get coreStore => widget.coreStore;

  IpsStore get ipsStore => coreStore.ipsStore;
  SettingsStore get settingsStore => coreStore.settingsStore;
  DaySettingsStore get daySettingsStore => coreStore.daySettingsStore;

  WeekIdentity get _activeWeek => coreStore.weekStore.activeWeek;

  OverrideStore get overrideStore => coreStore.overrideStore;

  CoverageEngine get _engine => coreStore.coverageEngine;
  TurnEngine get _turns => coreStore.turnEngine;

  bool _effUscita13(DateTime day) =>
      daySettingsStore.uscita13ForDay(day) ?? settingsStore.isUscita13;

  bool _effSandraMattina(DateTime day) =>
      daySettingsStore.effectiveSandraMattina(
        day,
        fallbackGlobal: settingsStore.isSandraDisponibile,
      );

  bool _effSandraPranzo(DateTime day) => daySettingsStore.effectiveSandraPranzo(
    day,
    fallbackGlobal: settingsStore.isSandraDisponibile,
  );

  bool _effSandraSera(DateTime day) => daySettingsStore.effectiveSandraSera(
    day,
    fallbackGlobal: settingsStore.isSandraDisponibile,
  );

  // =========================
  // EDIT RANGE (INIZIO + FINE) — EMERGENZA
  // =========================
  Future<void> _editEmergencyTimeRange({
    required String title,
    required EmergencyTimeRange currentRange,
    required void Function(EmergencyTimeRange newRange) onSave,
  }) async {
    final startHourCtrl = TextEditingController(
      text: (currentRange.startMin ~/ 60).toString(),
    );
    final startMinCtrl = TextEditingController(
      text: (currentRange.startMin % 60).toString().padLeft(2, '0'),
    );

    final endHourCtrl = TextEditingController(
      text: (currentRange.endMin ~/ 60).toString(),
    );
    final endMinCtrl = TextEditingController(
      text: (currentRange.endMin % 60).toString().padLeft(2, '0'),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Orario INIZIO"),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: startHourCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Ora"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: startMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Min"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Orario FINE"),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: endHourCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Ora"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: endMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Min"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final sh = int.tryParse(startHourCtrl.text.trim()) ?? 0;
                final sm = int.tryParse(startMinCtrl.text.trim()) ?? 0;
                final eh = int.tryParse(endHourCtrl.text.trim()) ?? 0;
                final em = int.tryParse(endMinCtrl.text.trim()) ?? 0;

                final start = sh.clamp(0, 23) * 60 + sm.clamp(0, 59);
                final end = eh.clamp(0, 23) * 60 + em.clamp(0, 59);

                if (end <= start) {
                  Navigator.of(context).pop();
                  return;
                }

                onSave(EmergencyTimeRange(startMin: start, endMin: end));
                Navigator.of(context).pop();
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );

    startHourCtrl.dispose();
    startMinCtrl.dispose();
    endHourCtrl.dispose();
    endMinCtrl.dispose();
  }

  // =========================
  // ✅ EDIT ORARI SANDRA (penna)
  // =========================
  Future<void> _editSandraWindow({
    required String title,
    required TimeOfDay currentStart,
    required TimeOfDay currentEnd,
    required void Function(TimeOfDay start, TimeOfDay end) onSave,
  }) async {
    final start = await showTimePicker(
      context: context,
      initialTime: currentStart,
      helpText: "$title • INIZIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: currentEnd,
      helpText: "$title • FINE",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (end == null) return;

    // validazione base: se uguali -> non salva
    if (start.hour == end.hour && start.minute == end.minute) return;

    onSave(start, end);
    setState(() {});
    ipsStore.refresh(now: _selectedDay);
  }

  // Giorno selezionato
  late DateTime _selectedDay;

  void _syncWeekWithSelectedDay() {
    coreStore.weekStore.setFromDate(_selectedDay);
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: 'Seleziona data',
      cancelText: 'Annulla',
      confirmText: 'OK',
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
      _syncWeekWithSelectedDay();
    });
  }

  void _prevWeek() {
    setState(() {
      _selectedDay = _onlyDate(_selectedDay.subtract(const Duration(days: 7)));
      _syncWeekWithSelectedDay();
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedDay = _onlyDate(_selectedDay.add(const Duration(days: 7)));
      _syncWeekWithSelectedDay();
    });
  }

  // Emergency (PRO)
  final EmergencyStore emergencyStore = EmergencyStore();
  final EmergencyDayLogic emergencyLogic = EmergencyDayLogic();

  DayOverrides _getOverridesForDay(DateTime day) =>
      overrideStore.getForDay(day);

  void _setOverridesForDay(DateTime day, DayOverrides ov) {
    overrideStore.setForDay(day, ov);
  }

  // ---- Scuola ----
  TimeOfDay _scuolaStart = const TimeOfDay(hour: 8, minute: 25);
  TimeOfDay _scuolaEnd = const TimeOfDay(hour: 16, minute: 30);

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _weekdayName(int weekday) {
    const names = {
      1: "Lun",
      2: "Mar",
      3: "Mer",
      4: "Gio",
      5: "Ven",
      6: "Sab",
      7: "Dom",
    };
    return names[weekday] ?? "???";
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  // ✅ CNC: Permesso NON deve mai creare PersonDayOverride senza permessoRange
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

  CoverageResultStepA _computeCoverageStepA(DateTime day) {
    final d0 = _onlyDate(day);

    final ov = _getOverridesForDay(d0);
    final uscita13Eff = _effUscita13(d0);

    final gaps = _engine.gapsForDayV2(
      day: d0,
      uscita13: uscita13Eff,
      sandraMattinaOn: _effSandraMattina(d0),
      sandraPranzoOn: _effSandraPranzo(d0),
      sandraSeraOn: _effSandraSera(d0),
      schoolStart: _scuolaStart,
      overrides: ov,
    );

    final ok = gaps.isEmpty;

    final details = <String>[];
    if (ok) {
      details.add("OK Nessun buco rilevato dal motore.");
    } else {
      for (final g in gaps) {
        details.add("BUCO $g (serve decisione: genitore / Sandra / extra).");
      }
    }

    final bannerText = ok
        ? "Copertura OK"
        : "BUCO (${gaps.length}): ${gaps.join(' • ')}";

    return CoverageResultStepA(
      ok: ok,
      details: details,
      bannerText: bannerText,
    );
  }

  bool _isEmergencyActive() {
    final settings = emergencyStore.getForDay(_selectedDay);

    final ov = _getOverridesForDay(_selectedDay);
    final matteo = ov.matteo?.status ?? OverrideStatus.normal;
    final chiara = ov.chiara?.status ?? OverrideStatus.normal;

    final forced = emergencyLogic.isForcedEmergency(
      matteo: matteo,
      chiara: chiara,
    );
    return settings.effectiveEnabled(forced: forced);
  }

  Widget _buildEmergencyBannerDebug() {
    final settings = emergencyStore.getForDay(_selectedDay);

    final ov = _getOverridesForDay(_selectedDay);
    final matteo = ov.matteo?.status ?? OverrideStatus.normal;
    final chiara = ov.chiara?.status ?? OverrideStatus.normal;

    final forced = emergencyLogic.isForcedEmergency(
      matteo: matteo,
      chiara: chiara,
    );
    final enabled = settings.effectiveEnabled(forced: forced);

    if (!enabled) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB71C1C)),
      ),
      child: Text(
        forced
            ? '🚨 MODALITÀ EMERGENZA (FORZATA) — Centro Controllo Alice'
            : '🚨 MODALITÀ EMERGENZA (MANUALE) — Centro Controllo Alice',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildEmergencyPanelPlaceholder() {
    final settings = emergencyStore.getForDay(_selectedDay);

    final ov = _getOverridesForDay(_selectedDay);
    final matteo = ov.matteo?.status ?? OverrideStatus.normal;
    final chiara = ov.chiara?.status ?? OverrideStatus.normal;

    final forced = emergencyLogic.isForcedEmergency(
      matteo: matteo,
      chiara: chiara,
    );
    final enabled = settings.effectiveEnabled(forced: forced);

    if (!enabled) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Centro Controllo Alice (Emergenza)",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "🕗 Mattina: ${settings.morningRange.toDisplayString()}",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: "Modifica orario mattina",
                  onPressed: () {
                    _editEmergencyTimeRange(
                      title: "Modifica orario mattina",
                      currentRange: settings.morningRange,
                      onSave: (newRange) {
                        emergencyStore.setMorningRange(_selectedDay, newRange);
                        setState(() {});
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text("🟧 Stato: Da valutare"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "🕘 Pomeriggio: ${settings.afternoonRange.toDisplayString()}",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: "Modifica orario pomeriggio",
                  onPressed: () {
                    _editEmergencyTimeRange(
                      title: "Modifica orario pomeriggio",
                      currentRange: settings.afternoonRange,
                      onSave: (newRange) {
                        emergencyStore.setAfternoonRange(
                          _selectedDay,
                          newRange,
                        );
                        setState(() {});
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text("🟧 Rientro casa: Da definire"),
          ],
        ),
      ),
    );
  }

  Widget _buildIpsPressureLine(int score) {
    final int s = score.clamp(0, 100);

    String label;
    Color color;

    if (s >= 70) {
      label = "Alta";
      color = Colors.red;
    } else if (s >= 40) {
      label = "Media";
      color = Colors.orange;
    } else {
      label = "Bassa";
      color = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Pressione IPS (copertura, 30gg): $s/100 • $label",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGapsBox(CoverageResultStepA cov) {
    if (cov.ok) return const SizedBox.shrink();

    final firstLine = cov.bannerText.split('\n').first;
    final gapsText = firstLine.startsWith('BUCO')
        ? firstLine
        : 'BUCO: controlla copertura';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BUCHI DEL GIORNO",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(gapsText, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            "Vai alla card Copertura per vedere le fasce e decidere l’azione.",
            style: TextStyle(color: Colors.black.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }

  Widget _banner(bool ok, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            _fmtDate(_selectedDay),
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final d = widget.initialSelectedDay ?? DateTime.now();
    _selectedDay = DateTime(d.year, d.month, d.day);
    _syncWeekWithSelectedDay();
  }

  // ✅ Layout “come prima”: 3 blocchi + colonna destra
  Widget _layoutRow3({
    required Widget leftA,
    required Widget leftB,
    required Widget leftC,
    required Widget right,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        if (w >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftA),
              const SizedBox(width: 12),
              Expanded(child: leftB),
              const SizedBox(width: 12),
              Expanded(child: leftC),
              const SizedBox(width: 12),
              SizedBox(width: 360, child: right),
            ],
          );
        }

        if (w >= 800) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftA),
                  const SizedBox(width: 12),
                  Expanded(child: leftB),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftC),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            leftA,
            const SizedBox(height: 12),
            leftB,
            const SizedBox(height: 12),
            leftC,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ovSelected = _getOverridesForDay(_selectedDay);
    final cov = _computeCoverageStepA(_selectedDay);
    final isEmergency = _isEmergencyActive();

    final int ipsCoverage30 = coreStore.coverageAdapter.riskScore30Days(
      startDay: _selectedDay,
    );

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _pickCalendarDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 20),
              const SizedBox(width: 8),
              Text(
                "Calendario • ${DateFormat('EEEE d MMMM yyyy', 'it_IT').format(_selectedDay)}",
              ),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cov.ok ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildIpsPressureLine(ipsCoverage30),
            const SizedBox(height: 8),

            _weekNavBar(),
            const SizedBox(height: 8),

            _buildEmergencyBannerDebug(),

            // Se vuoi anche la tabella settimanale qui sopra (come “stato settimana”),
            // la rimettiamo dopo: ora ti riporto la posizione “a 3 blocchi + Sandra”
            // _weekGrid4Col(),
            // const SizedBox(height: 12),
            if (!isEmergency) _buildDayGapsBox(cov),
            if (!isEmergency) _banner(cov.ok, cov.bannerText),
            const SizedBox(height: 12),

            _layoutRow3(
              leftA: _cardTurni(),
              leftB: _cardScuola(),
              leftC: _cardOverrideStepB(ovSelected),
              right: isEmergency
                  ? _buildEmergencyPanelPlaceholder()
                  : _cardCopertura(cov),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _weekNavBar() {
    final start = _activeWeek.weekStart;
    final end = start.add(const Duration(days: 6));
    final label =
        "${DateFormat('d MMM', 'it_IT').format(start)} – ${DateFormat('d MMM yyyy', 'it_IT').format(end)}";

    return Row(
      children: [
        IconButton(
          tooltip: "Settimana precedente",
          onPressed: _prevWeek,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        IconButton(
          tooltip: "Settimana successiva",
          onPressed: _nextWeek,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // =========================
  // ✅ CARD TURNI (come prima)
  // =========================
  Widget _cardTurni() {
    final m = _turns.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: _selectedDay,
    );
    final c = _turns.turnPlanForPersonDay(
      person: TurnPerson.chiara,
      day: _selectedDay,
    );

    return _card(
      title: "Turni",
      subtitle: "Turno standard (per ora). Quarta Squadra arriva dopo.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _turnRow("Matteo", m),
          const SizedBox(height: 10),
          _turnRow("Chiara", c),
          const SizedBox(height: 8),
          Text(
            "Nota: il riposo post-notte fino alle 14:30 viene applicato dal motore (busy shifts).",
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnRow(String name, TurnPlan p) {
    final label = _turnLabel(p.type);
    final time = p.isOff ? "OFF" : "${_fmt(p.start)}–${_fmt(p.end)}";
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "$label • $time",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _turnLabel(TurnType t) {
    switch (t) {
      case TurnType.mattina:
        return "Mattina";
      case TurnType.pomeriggio:
        return "Pomeriggio";
      case TurnType.notte:
        return "Notte";
      case TurnType.off:
        return "Off";
    }
  }

  String _overrideLabelShort(OverrideStatus s) {
    switch (s) {
      case OverrideStatus.normal:
        return "Normal";
      case OverrideStatus.ferie:
        return "Ferie";
      case OverrideStatus.permesso:
        return "Permesso";
      case OverrideStatus.malattiaLeggera:
        return "M. leggera";
      case OverrideStatus.malattiaALetto:
        return "A letto";
    }
  }

  Widget _cardOverrideStepB(DayOverrides ovSelected) {
    return _card(
      title: "Override (Step B)",
      subtitle: "Imposta stato giornaliero (influenza subito la copertura).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _overrideRow(
            label: "Matteo",
            value: ovSelected.matteo?.status ?? OverrideStatus.normal,
            onChanged: (newStatus) {
              final updated = DayOverrides(
                day: _selectedDay,
                matteo: _buildPersonOverrideSafe(newStatus),
                chiara: ovSelected.chiara,
              );
              setState(() => _setOverridesForDay(_selectedDay, updated));
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const SizedBox(height: 12),
          _overrideRow(
            label: "Chiara",
            value: ovSelected.chiara?.status ?? OverrideStatus.normal,
            onChanged: (newStatus) {
              final updated = DayOverrides(
                day: _selectedDay,
                matteo: ovSelected.matteo,
                chiara: _buildPersonOverrideSafe(newStatus),
              );
              setState(() => _setOverridesForDay(_selectedDay, updated));
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const SizedBox(height: 10),
          Text(
            "DEBUG: ${_getOverridesForDay(_selectedDay)}",
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overrideRow({
    required String label,
    required OverrideStatus value,
    required ValueChanged<OverrideStatus> onChanged,
  }) {
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
            items: OverrideStatus.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(_overrideLabel(s)));
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

  Widget _cardScuola() {
    return _card(
      title: "Alice / Scuola",
      subtitle: "Orari scuola + uscita anticipata (attiva finestra pranzo).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Orario: ${_fmt(_scuolaStart)}–${_fmt(_scuolaEnd)}"),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Uscita anticipata alle 13:00"),
            value:
                daySettingsStore.uscita13ForDay(_selectedDay) ??
                settingsStore.isUscita13,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setUscita13ForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickSchoolTimes,
            icon: const Icon(Icons.edit),
            label: const Text("Modifica scuola"),
          ),
        ],
      ),
    );
  }

  Widget _cardCopertura(CoverageResultStepA cov) {
    final uscita13Eff = _effUscita13(_selectedDay);

    final effMattina = _effSandraMattina(_selectedDay);
    final effPranzo = _effSandraPranzo(_selectedDay);
    final effSera = _effSandraSera(_selectedDay);

    final bool sandraGlobaleOn = effMattina && effPranzo && effSera;

    return _card(
      title: "Copertura (Step A)",
      subtitle: "Sandra (toggle) + fasce orarie editabili (penna).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Globale (mattina + pranzo + sera)"),
            value: sandraGlobaleOn,
            onChanged: (v) {
              setState(() {
                daySettingsStore.setSandraMattinaForDay(_selectedDay, v);
                daySettingsStore.setSandraPranzoForDay(_selectedDay, v);
                daySettingsStore.setSandraSeraForDay(_selectedDay, v);
              });
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const Divider(),

          _sandraWindowRow(
            title: "Cambio turno mattina (IN CASA, Sandra NON copre)",
            start: _engine.sandraCambioMattinaStart,
            end: _engine.sandraCambioMattinaEnd,
            onEdit: () {
              _editSandraWindow(
                title: "Cambio turno mattina",
                currentStart: _engine.sandraCambioMattinaStart,
                currentEnd: _engine.sandraCambioMattinaEnd,
                onSave: (s, e) => _engine.setSandraCambioMattina(s, e),
              );
            },
          ),
          const SizedBox(height: 8),
          _sandraWindowRow(
            title: "Pranzo (solo se uscita 13, LOGISTICA ESTERNA)",
            start: _engine.sandraPranzoStart,
            end: _engine.sandraPranzoEnd,
            onEdit: () {
              _editSandraWindow(
                title: "Pranzo",
                currentStart: _engine.sandraPranzoStart,
                currentEnd: _engine.sandraPranzoEnd,
                onSave: (s, e) => _engine.setSandraPranzo(s, e),
              );
            },
          ),
          const SizedBox(height: 8),
          _sandraWindowRow(
            title: "Sera (IN CASA)",
            start: _engine.sandraSeraStart,
            end: _engine.sandraSeraEnd,
            onEdit: () {
              _editSandraWindow(
                title: "Sera",
                currentStart: _engine.sandraSeraStart,
                currentEnd: _engine.sandraSeraEnd,
                onSave: (s, e) => _engine.setSandraSera(s, e),
              );
            },
          ),

          const Divider(),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia mattina (ingresso scuola)"),
            value: effMattina,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraMattinaForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia pranzo (solo se uscita 13)"),
            value: effPranzo,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraPranzoForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia sera (21:00–22:35)"),
            value: effSera,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraSeraForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const Divider(),
          Text(
            uscita13Eff ? "Uscita 13:00 attiva" : "Uscita 13:00 non attiva",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...cov.details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text("• $d"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sandraWindowRow({
    required String title,
    required TimeOfDay start,
    required TimeOfDay end,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$title\n${_fmt(start)}–${_fmt(end)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: "Modifica fascia",
          onPressed: onEdit,
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _pickSchoolTimes() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _scuolaStart,
    );
    if (start == null) return;

    final end = await showTimePicker(context: context, initialTime: _scuolaEnd);
    if (end == null) return;

    if (!mounted) return;

    setState(() {
      _scuolaStart = start;
      _scuolaEnd = end;
    });
  }
}

class CoverageResultStepA {
  final bool ok;
  final List<String> details;
  final String bannerText;

  const CoverageResultStepA({
    required this.ok,
    required this.details,
    required this.bannerText,
  });
}
