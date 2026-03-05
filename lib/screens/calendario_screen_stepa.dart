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

import '../widgets/stepb_override_panel.dart';

// ✅ NEW: Ferie lunghe panel
import '../widgets/ferie_period_panel.dart';

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

  // ✅ NEW: uscita anticipata ORARIO effettivo per giorno (fallback su default globale)
  TimeOfDay? _effUscitaAnticipataAt(DateTime day) {
    final t = daySettingsStore.uscitaAnticipataTimeForDay(day);
    if (t != null) return t;

    // fallback legacy: se globale attivo, usa default (13:00)
    if (settingsStore.isUscita13) {
      return settingsStore.uscitaAnticipataDefaultTime;
    }

    return null;
  }

  bool _effUscita13(DateTime day) => _effUscitaAnticipataAt(day) != null;

  bool _effSandraMattina(DateTime day) => daySettingsStore.effectiveSandraMattina(
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
  // ✅ STEP 1: Uscita scuola per giorno (fallback default)
  // =========================
  static const TimeOfDay _schoolOutDefaultStart =
      TimeOfDay(hour: 16, minute: 25);
  static const TimeOfDay _schoolOutDefaultEnd = TimeOfDay(hour: 17, minute: 15);

  TimeOfDay _effSchoolOutStart(DateTime day) =>
      daySettingsStore.schoolOutStartForDay(day) ?? _schoolOutDefaultStart;

  TimeOfDay _effSchoolOutEnd(DateTime day) =>
      daySettingsStore.schoolOutEndForDay(day) ?? _schoolOutDefaultEnd;

  Future<void> _editSchoolOutTimesForDay() async {
    final start0 = _effSchoolOutStart(_selectedDay);
    final end0 = _effSchoolOutEnd(_selectedDay);

    final start = await showTimePicker(
      context: context,
      initialTime: start0,
      helpText: "Uscita scuola • INIZIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: end0,
      helpText: "Uscita scuola • FINE",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (end == null) return;

    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (endMin <= startMin) return;

    setState(() {
      daySettingsStore.setSchoolOutTimesForDay(_selectedDay, start, end);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  // (non usato dopo rimozione UI reset — lasciato qui per eventuale futuro)
  void _resetSchoolOutTimesForDay() {
    setState(() {
      daySettingsStore.clearSchoolOutTimesForDay(_selectedDay);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  // =========================
  // ✅ NEW: toggle uscita anticipata con scelta orario
  // =========================
  Future<void> _toggleUscitaAnticipata(bool enabled) async {
    if (!enabled) {
      setState(() {
        daySettingsStore.clearUscitaAnticipataForDay(_selectedDay);
      });
      ipsStore.refresh(now: _selectedDay);
      return;
    }

    final initial =
        _effUscitaAnticipataAt(_selectedDay) ?? settingsStore.uscitaAnticipataDefaultTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: "Uscita anticipata • ORARIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );

    // Se annulli, NON attiviamo nulla (resta OFF)
    if (picked == null) return;

    setState(() {
      daySettingsStore.setUscitaAnticipataTimeForDay(_selectedDay, picked);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  String _schoolCoverLabel(SchoolCoverChoice c) {
    switch (c) {
      case SchoolCoverChoice.none:
        return "Nessuno (BUCO)";
      case SchoolCoverChoice.matteo:
        return "Matteo";
      case SchoolCoverChoice.chiara:
        return "Chiara";
      case SchoolCoverChoice.sandra:
        return "Sandra";
      case SchoolCoverChoice.altro:
        return "Altro…";
    }
  }

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

  // ✅ A6: Navigazione GIORNO per GIORNO
  void _prevDay() {
    setState(() {
      _selectedDay = _onlyDate(_selectedDay.subtract(const Duration(days: 1)));
      _syncWeekWithSelectedDay();
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDay = _onlyDate(_selectedDay.add(const Duration(days: 1)));
      _syncWeekWithSelectedDay();
    });
  }

  // Emergency (PRO)
  final EmergencyStore emergencyStore = EmergencyStore();
  final EmergencyDayLogic emergencyLogic = EmergencyDayLogic();

  DayOverrides _getOverridesForDay(DateTime day) => overrideStore.getForDay(day);

  void _setOverridesForDay(DateTime day, DayOverrides ov) {
    overrideStore.setForDay(day, ov);
  }

  // ---- Scuola ----
  TimeOfDay _scuolaStart = const TimeOfDay(hour: 8, minute: 25);
  TimeOfDay _scuolaEnd = const TimeOfDay(hour: 16, minute: 30);

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  CoverageResultStepA _computeCoverageStepA(DateTime day) {
    final d0 = _onlyDate(day);

    final ov = _getOverridesForDay(d0);

    final uscitaAt = _effUscitaAnticipataAt(d0);
    final uscita13Eff = uscitaAt != null;

    final outStart = _effSchoolOutStart(d0);
    final outEnd = _effSchoolOutEnd(d0);

    final gaps = _engine.gapsForDayV2(
      day: d0,
      uscita13: uscita13Eff,
      sandraMattinaOn: _effSandraMattina(d0),
      sandraPranzoOn: _effSandraPranzo(d0),
      sandraSeraOn: _effSandraSera(d0),
      schoolStart: _scuolaStart,
      overrides: ov,

      // ✅ NEW: ferie lunghe → CoverageEngine
      ferieStore: coreStore.feriePeriodStore,

      // ✅ Decisioni scuola dal DaySettingsStore
      schoolInCover: daySettingsStore.schoolInCoverForDay(d0),
      schoolOutCover: daySettingsStore.schoolOutCoverForDay(d0),
      schoolOutStart: outStart,
      schoolOutEnd: outEnd,

      // ✅ NUOVO: decisione pranzo (solo se uscita anticipata)
      lunchCover: daySettingsStore.lunchCoverForDay(d0),

      // ✅ NEW: orario uscita anticipata (inizio finestra pranzo)
      uscitaAnticipataAt: uscitaAt,
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

    final bannerText =
        ok ? "Copertura OK" : "BUCO (${gaps.length}): ${gaps.join(' • ')}";

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
                        emergencyStore.setAfternoonRange(_selectedDay, newRange);
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
    final gapsText =
        firstLine.startsWith('BUCO') ? firstLine : 'BUCO: controlla copertura';

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
          color: ok ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
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
    final ovSelected = overrideStore.getEffectiveForDay(
      day: _selectedDay,
      ferieStore: coreStore.feriePeriodStore,
    );
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
            if (!isEmergency) _buildDayGapsBox(cov),
            if (!isEmergency) _banner(cov.ok, cov.bannerText),
            const SizedBox(height: 12),
            _layoutRow3(
              leftA: _cardTurni(),
              leftB: _cardScuola(),
              leftC: Column(
                children: [
                  _cardOverrideStepB(ovSelected),
                  const SizedBox(height: 12),
                  FeriePeriodPanel(store: coreStore.feriePeriodStore),
                ],
              ),
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
          tooltip: "Giorno precedente",
          onPressed: _prevDay,
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
          tooltip: "Giorno successivo",
          onPressed: _nextDay,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // =========================
  // ✅ CARD TURNI
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

  // =========================
  // ✅ OVERRIDE STEP B
  // =========================
  Widget _cardOverrideStepB(DayOverrides ovSelected) {
    return _card(
      title: "Override (Step B)",
      subtitle: "Imposta stato giornaliero (influenza subito la copertura).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepBOverridePanel(
            day: _selectedDay,
            current: ovSelected,
            onSave: (updated) {
              setState(() => _setOverridesForDay(_selectedDay, updated));
            },
            onAfterChange: () {
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

  // =========================
  // ✅ SCUOLA (uscita anticipata con ORARIO)
  // =========================
  Widget _cardScuola() {
    final inChoice = daySettingsStore.schoolInCoverForDay(_selectedDay);
    final outChoice = daySettingsStore.schoolOutCoverForDay(_selectedDay);

    final uscitaAt = _effUscitaAnticipataAt(_selectedDay);
    final uscita13Eff = uscitaAt != null;

    final lunchChoice = daySettingsStore.lunchCoverForDay(_selectedDay);

    final outStart = _effSchoolOutStart(_selectedDay);
    final outEnd = _effSchoolOutEnd(_selectedDay);

    final bool hasCustomOut =
        daySettingsStore.schoolOutStartForDay(_selectedDay) != null ||
            daySettingsStore.schoolOutEndForDay(_selectedDay) != null;

    return _card(
      title: "Alice / Scuola",
      subtitle: "Orari scuola + uscita anticipata rapida (con orario).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Orario: ${_fmt(_scuolaStart)}–${_fmt(_scuolaEnd)}"),
          const SizedBox(height: 12),

          // ✅ Toggle + orario
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              uscita13Eff
                  ? "Uscita anticipata: ${_fmt(uscitaAt!)}"
                  : "Uscita anticipata (tocca per impostare orario)",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            value: uscita13Eff,
            onChanged: (v) async {
              await _toggleUscitaAnticipata(v);
            },
          ),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickSchoolTimes,
            icon: const Icon(Icons.edit),
            label: const Text("Modifica scuola"),
          ),

          // ✅ MODIFICA RICHIESTA:
          // Se uscita anticipata è attiva, NASCONDIAMO completamente:
          // - "Uscita: 16:25–17:15"
          // - "Modifica uscita"
          // - (e sotto anche il dropdown decisione uscita normale)
          if (!uscita13Eff) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Uscita: ${_fmt(outStart)}–${_fmt(outEnd)}${hasCustomOut ? " (personalizzata)" : ""}",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _editSchoolOutTimesForDay,
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Modifica uscita"),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            "Decisione scuola (copertura)",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<SchoolCoverChoice>(
            value: inChoice,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Ingresso 07:30–${_fmt(_scuolaStart)}",
            ),
            items: SchoolCoverChoice.values.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(_schoolCoverLabel(c)),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() =>
                  daySettingsStore.setSchoolInCoverForDay(_selectedDay, v));
              if (v == SchoolCoverChoice.altro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Altro: lista persone arriverà dopo (placeholder)."),
                  ),
                );
              }
              ipsStore.refresh(now: _selectedDay);
            },
          ),

          // ✅ Uscita normale: solo se NON c’è uscita anticipata
          if (!uscita13Eff) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<SchoolCoverChoice>(
              value: outChoice,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Uscita ${_fmt(outStart)}–${_fmt(outEnd)}",
              ),
              items: SchoolCoverChoice.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(_schoolCoverLabel(c)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() =>
                    daySettingsStore.setSchoolOutCoverForDay(_selectedDay, v));
                if (v == SchoolCoverChoice.altro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Altro: lista persone arriverà dopo (placeholder)."),
                    ),
                  );
                }
                ipsStore.refresh(now: _selectedDay);
              },
            ),
          ],

          if (uscita13Eff) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Decisione pranzo (uscita anticipata)",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<SchoolCoverChoice>(
              value: lunchChoice,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Pranzo ${_fmt(uscitaAt!)}–${_fmt(_engine.sandraPranzoEnd)}",
              ),
              items: SchoolCoverChoice.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(_schoolCoverLabel(c)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() =>
                    daySettingsStore.setLunchCoverForDay(_selectedDay, v));
                if (v == SchoolCoverChoice.altro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Altro: lista persone arriverà dopo (placeholder)."),
                    ),
                  );
                }
                ipsStore.refresh(now: _selectedDay);
              },
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // ✅ COPERTURA
  // =========================
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
            title: "Cambio turno mattina (IN CASA)",
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
            title: "Pranzo (LOGISTICA ESTERNA se uscita anticipata)",
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
            title: const Text("Sandra – Fascia mattina"),
            value: effMattina,
            onChanged: (v) {
              setState(() =>
                  daySettingsStore.setSandraMattinaForDay(_selectedDay, v));
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia pranzo"),
            value: effPranzo,
            onChanged: (v) {
              setState(() =>
                  daySettingsStore.setSandraPranzoForDay(_selectedDay, v));
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia sera (21:00–22:35)"),
            value: effSera,
            onChanged: (v) {
              setState(() =>
                  daySettingsStore.setSandraSeraForDay(_selectedDay, v));
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const Divider(),
          Text(
            uscita13Eff ? "Uscita anticipata attiva" : "Uscita anticipata non attiva",
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