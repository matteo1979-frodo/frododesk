// lib/screens/calendario_screen_stepa.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/override_store.dart';
import '../logic/emergency_store.dart';
import '../logic/emergency_day_logic.dart';
import '../logic/coverage_engine.dart';
import '../logic/turn_engine.dart';
import '../logic/disease_period_store.dart';

import '../models/day_override.dart';
import '../logic/core_store.dart';
import '../models/week_identity.dart';
import '../logic/settings_store.dart';
import '../logic/ips_store.dart';
import '../logic/day_settings_store.dart';

import '../widgets/stepb_override_panel.dart';
import '../widgets/alice_event_panel.dart';
import '../widgets/support_network_panel.dart';
import '../widgets/disease_period_panel.dart';
import '../widgets/fourth_shift_panel.dart';

// ✅ NEW: Ferie lunghe panel
import '../widgets/ferie_period_panel.dart';

// ✅ NEW: Eventi speciali centro estivo
import '../logic/summer_camp_special_event_store.dart';

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
  DiseasePeriodStore get diseasePeriodStore => coreStore.diseasePeriodStore;

  CoverageEngine get _engine => coreStore.coverageEngine;
  TurnEngine get _turns => coreStore.turnEngine;

  TimeOfDay? _effUscitaAnticipataAt(DateTime day) {
    final t = daySettingsStore.uscitaAnticipataTimeForDay(day);
    if (t != null) return t;

    if (settingsStore.isUscita13) {
      return settingsStore.uscitaAnticipataDefaultTime;
    }

    return null;
  }

  bool _effUscita13(DateTime day) => _effUscitaAnticipataAt(day) != null;

  bool _effSandraMattina(DateTime day) =>
      daySettingsStore.sandraMattinaForDay(day) ?? false;

  bool _effSandraPranzo(DateTime day) =>
      daySettingsStore.sandraPranzoForDay(day) ?? false;

  bool _effSandraSera(DateTime day) =>
      daySettingsStore.sandraSeraForDay(day) ?? false;

  CoverageSandraDecision _sandraDecisionForDay(DateTime day) {
    final d0 = _onlyDate(day);
    final ov = _getOverridesForDay(d0);
    final uscitaAt = _effUscitaAnticipataAt(d0);

    return _engine.sandraDecisionForDay(
      day: d0,
      uscita13: uscitaAt != null,
      overrides: ov,
      ferieStore: coreStore.feriePeriodStore,
      lunchCover: _effectiveLunchCover(d0),
      uscitaAnticipataAt: uscitaAt,
    );
  }

  static const TimeOfDay _schoolOutDefaultStart = TimeOfDay(
    hour: 16,
    minute: 25,
  );
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

  void _resetSchoolOutTimesForDay() {
    setState(() {
      daySettingsStore.clearSchoolOutTimesForDay(_selectedDay);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  Future<void> _toggleUscitaAnticipata(bool enabled) async {
    if (!enabled) {
      setState(() {
        daySettingsStore.clearUscitaAnticipataForDay(_selectedDay);
      });
      ipsStore.refresh(now: _selectedDay);
      return;
    }

    final initial =
        _effUscitaAnticipataAt(_selectedDay) ??
        settingsStore.uscitaAnticipataDefaultTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: "Uscita anticipata • ORARIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );

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

  bool _supportNetworkCoversRange({
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final d0 = _onlyDate(day);

    final fasciaStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      start.hour,
      start.minute,
    );

    final fasciaEnd = DateTime(d0.year, d0.month, d0.day, end.hour, end.minute);

    for (final person in coreStore.supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        d0,
        person.id,
      );
      if (!enabledForDay) continue;

      final supportStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.start.hour,
        person.start.minute,
      );

      final supportEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.end.hour,
        person.end.minute,
      );

      final coversFullRange =
          !supportStart.isAfter(fasciaStart) && !supportEnd.isBefore(fasciaEnd);

      if (coversFullRange) return true;
    }

    return false;
  }

  List<String> _supportNetworkCoverageLines({
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
    required String contextLabel,
  }) {
    final d0 = _onlyDate(day);

    final fasciaStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      start.hour,
      start.minute,
    );

    final fasciaEnd = DateTime(d0.year, d0.month, d0.day, end.hour, end.minute);

    final lines = <String>[];

    for (final person in coreStore.supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        d0,
        person.id,
      );
      if (!enabledForDay) continue;

      final supportStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.start.hour,
        person.start.minute,
      );

      final supportEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.end.hour,
        person.end.minute,
      );

      final coversFullRange =
          !supportStart.isAfter(fasciaStart) && !supportEnd.isBefore(fasciaEnd);

      if (!coversFullRange) continue;

      lines.add(
        "• Supporto $contextLabel: ${person.name} ${_fmt(person.start)}–${_fmt(person.end)}",
      );
    }

    return lines;
  }

  String? _supportCoverageSummaryLine({
    required List<String> lines,
    required String label,
  }) {
    if (lines.isEmpty) return null;

    final first = lines.first;
    final prefixEnd = first.indexOf(':');
    if (prefixEnd == -1 || prefixEnd + 1 >= first.length) return null;

    final payload = first.substring(prefixEnd + 1).trim();
    final parts = payload.split(' ');
    if (parts.length < 2) return null;

    final name = parts.first;
    final time = parts.sublist(1).join(' ');

    final prettyName = name.isEmpty
        ? name
        : "${name[0].toUpperCase()}${name.substring(1)}";

    return "• $label coperto da $prettyName ($time)";
  }

  SchoolCoverChoice _effectiveSchoolInCover(DateTime day) {
    final saved = daySettingsStore.schoolInCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;

    final coveredBySupport = _supportNetworkCoversRange(
      day: day,
      start: const TimeOfDay(hour: 7, minute: 30),
      end: _scuolaStart,
    );

    return coveredBySupport ? SchoolCoverChoice.altro : SchoolCoverChoice.none;
  }

  SchoolCoverChoice _effectiveSchoolOutCover(DateTime day) {
    final saved = daySettingsStore.schoolOutCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;

    final outStart = _effSchoolOutStart(day);
    final outEnd = _effSchoolOutEnd(day);

    final coveredBySupport = _supportNetworkCoversRange(
      day: day,
      start: outStart,
      end: outEnd,
    );

    return coveredBySupport ? SchoolCoverChoice.altro : SchoolCoverChoice.none;
  }

  SchoolCoverChoice _effectiveLunchCover(DateTime day) {
    final saved = daySettingsStore.lunchCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;

    final uscitaAt = _effUscitaAnticipataAt(day);
    if (uscitaAt == null) return SchoolCoverChoice.none;

    final coveredBySupport = _supportNetworkCoversRange(
      day: day,
      start: uscitaAt,
      end: _engine.sandraPranzoEnd,
    );

    return coveredBySupport ? SchoolCoverChoice.altro : SchoolCoverChoice.none;
  }

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

  bool _selectedDayIsSummerCampDay() {
    return _engine.isAliceSummerCampOperationalDay(_selectedDay);
  }

  SummerCampSpecialEvent? _selectedDaySpecialCampEvent() {
    return _engine.getSummerCampSpecialEventForDay(_selectedDay);
  }

  Future<void> _editSummerCampSpecialEventForSelectedDay() async {
    final current = _selectedDaySpecialCampEvent();

    final labelCtrl = TextEditingController(text: current?.label ?? "");

    final savedLabel = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Evento speciale centro estivo"),
          content: TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(
              labelText: "Nome evento",
              hintText: "Es. Gita / Mare / Uscita speciale",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = labelCtrl.text.trim();
                Navigator.of(context).pop(text);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    labelCtrl.dispose();

    if (savedLabel == null) return;

    final initialStart = current?.start ?? const TimeOfDay(hour: 8, minute: 30);
    final pickedStart = await showTimePicker(
      context: context,
      initialTime: initialStart,
      helpText: "Evento speciale • INIZIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (pickedStart == null) return;

    final initialEnd = current?.end ?? const TimeOfDay(hour: 17, minute: 30);
    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: initialEnd,
      helpText: "Evento speciale • FINE",
      cancelText: "Annulla",
      confirmText: "OK",
    );
    if (pickedEnd == null) return;

    final startMin = pickedStart.hour * 60 + pickedStart.minute;
    final endMin = pickedEnd.hour * 60 + pickedEnd.minute;
    if (endMin <= startMin) return;

    setState(() {
      _engine.summerCampSpecialEventStore.setForDay(
        _selectedDay,
        SummerCampSpecialEvent(
          enabled: true,
          label: savedLabel.isEmpty ? "Evento speciale" : savedLabel,
          start: pickedStart,
          end: pickedEnd,
        ),
      );
    });
    ipsStore.refresh(now: _selectedDay);
  }

  void _removeSummerCampSpecialEventForSelectedDay() {
    setState(() {
      _engine.summerCampSpecialEventStore.removeForDay(_selectedDay);
    });
    ipsStore.refresh(now: _selectedDay);
  }

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

  final EmergencyStore emergencyStore = EmergencyStore();
  final EmergencyDayLogic emergencyLogic = EmergencyDayLogic();

  DayOverrides _getOverridesForDay(DateTime day) =>
      overrideStore.getForDay(day);

  void _setOverridesForDay(DateTime day, DayOverrides ov) {
    overrideStore.setForDay(day, ov);
  }

  TimeOfDay _scuolaStart = const TimeOfDay(hour: 8, minute: 25);
  TimeOfDay _scuolaEnd = const TimeOfDay(hour: 16, minute: 30);

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  String _cleanGapTitle(String label) {
    final lower = label.toLowerCase();

    if (lower.contains('alice ingresso')) {
      return 'Ingresso scuola';
    }

    if (lower.contains('alice uscita')) {
      return 'Uscita scuola';
    }

    if (lower.contains('pranzo')) {
      return 'Pranzo';
    }

    if (lower.contains('sera')) {
      return 'Sera';
    }

    if (lower.contains('mattina')) {
      return 'Mattina';
    }

    return label;
  }

  String? _extractGapTime(String label) {
    final parts = label.split(': ');
    if (parts.length < 2) return null;

    final candidate = parts.last.trim();
    if (candidate.contains('–')) return candidate;

    return null;
  }

  CoverageResultStepA _computeCoverageStepA(DateTime day) {
    final d0 = _onlyDate(day);

    final ov = _getOverridesForDay(d0);

    final uscitaAt = _effUscitaAnticipataAt(d0);
    final uscita13Eff = uscitaAt != null;

    final outStart = _effSchoolOutStart(d0);
    final outEnd = _effSchoolOutEnd(d0);

    final sandraDecision = _sandraDecisionForDay(d0);

    final analysis = _engine.analyzeDayV2(
      day: d0,
      uscita13: uscita13Eff,
      sandraMattinaOn: _effSandraMattina(d0),
      sandraPranzoOn: _effSandraPranzo(d0),
      sandraSeraOn: _effSandraSera(d0),
      schoolStart: _scuolaStart,
      overrides: ov,
      ferieStore: coreStore.feriePeriodStore,
      schoolInCover: _effectiveSchoolInCover(d0),
      schoolOutCover: _effectiveSchoolOutCover(d0),
      schoolOutStart: outStart,
      schoolOutEnd: outEnd,
      lunchCover: _effectiveLunchCover(d0),
      uscitaAnticipataAt: uscitaAt,
    );

    final gaps = analysis.gaps;
    final ok = gaps.isEmpty;

    final summaryDetails = <String>[];
    if (sandraDecision.serveSandraMattina) {
      summaryDetails.add("Sandra serve in fascia mattina.");
    }
    if (sandraDecision.serveSandraPranzo) {
      summaryDetails.add("Sandra serve in fascia pranzo.");
    }
    if (sandraDecision.serveSandraSera) {
      summaryDetails.add("Sandra serve in fascia sera.");
    }

    if (ok) {
      summaryDetails.add("OK Nessun buco rilevato dal motore.");
    } else {
      summaryDetails.add("Il motore ha rilevato ${gaps.length} buco/i reali.");
    }

    final bannerText = ok
        ? "Copertura OK"
        : "BUCO (${gaps.length}): ${gaps.join(' • ')}";

    return CoverageResultStepA(
      ok: ok,
      details: summaryDetails,
      gapDetails: analysis.details,
      bannerText: bannerText,
    );
  }

  DayGapVisualState _dayGapVisualState(CoverageResultStepA cov) {
    if (!cov.ok) return DayGapVisualState.realGap;

    final d0 = _selectedDay;
    final sandraDecision = _sandraDecisionForDay(d0);
    final uscita13Eff = _effUscita13(d0);

    final bool sandraHelps =
        (sandraDecision.serveSandraMattina && _effSandraMattina(d0)) ||
        (sandraDecision.serveSandraPranzo && _effSandraPranzo(d0)) ||
        (sandraDecision.serveSandraSera && _effSandraSera(d0));

    final bool schoolInHelp =
        _effectiveSchoolInCover(d0) != SchoolCoverChoice.none;

    final bool schoolOutHelp =
        !uscita13Eff && _effectiveSchoolOutCover(d0) != SchoolCoverChoice.none;

    final bool lunchHelp =
        uscita13Eff && _effectiveLunchCover(d0) != SchoolCoverChoice.none;

    if (sandraHelps || schoolInHelp || schoolOutHelp || lunchHelp) {
      return DayGapVisualState.coveredNeed;
    }

    return DayGapVisualState.noProblem;
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
    final state = _dayGapVisualState(cov);

    late final Color color;
    late final IconData icon;
    late final String headline;
    late final String subline;

    switch (state) {
      case DayGapVisualState.noProblem:
        color = Colors.green;
        icon = Icons.check_circle;
        headline = "✓ Nessun problema oggi";
        subline = "Nessun buco rilevato dal motore.";
        break;

      case DayGapVisualState.coveredNeed:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        headline = "⚠ Copertura necessaria ma risolta";
        subline =
            "La giornata è coperta, ma solo grazie a supporti o decisioni manuali.";
        break;

      case DayGapVisualState.realGap:
        color = Colors.red;
        icon = Icons.error;
        headline = "❗ Buco reale da risolvere";
        subline = "Esistono fasce senza copertura reale.";
        break;
    }

    final d0 = _selectedDay;
    final sandraDecision = _sandraDecisionForDay(d0);
    final uscita13Eff = _effUscita13(d0);
    final inCover = _effectiveSchoolInCover(d0);
    final outCover = _effectiveSchoolOutCover(d0);
    final lunchCover = _effectiveLunchCover(d0);

    final supportInLines = _supportNetworkCoverageLines(
      day: d0,
      start: const TimeOfDay(hour: 7, minute: 30),
      end: _scuolaStart,
      contextLabel: "ingresso",
    );

    final supportOutLines = _supportNetworkCoverageLines(
      day: d0,
      start: _effSchoolOutStart(d0),
      end: _effSchoolOutEnd(d0),
      contextLabel: "uscita",
    );

    final supportLunchLines = uscita13Eff
        ? _supportNetworkCoverageLines(
            day: d0,
            start: _effUscitaAnticipataAt(d0)!,
            end: _engine.sandraPranzoEnd,
            contextLabel: "pranzo",
          )
        : <String>[];

    final inSupportSummary = _supportCoverageSummaryLine(
      lines: supportInLines,
      label: "Ingresso scuola",
    );

    final outSupportSummary = _supportCoverageSummaryLine(
      lines: supportOutLines,
      label: "Uscita scuola",
    );

    final lunchSupportSummary = _supportCoverageSummaryLine(
      lines: supportLunchLines,
      label: "Pranzo",
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BUCHI DEL GIORNO",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subline,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.68),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state == DayGapVisualState.coveredNeed) ...[
            const SizedBox(height: 10),
            if (sandraDecision.serveSandraMattina &&
                _effSandraMattina(_selectedDay))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Sandra copre la fascia mattina (${_fmt(_engine.sandraCambioMattinaStart)}–${_fmt(_engine.sandraCambioMattinaEnd)})",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (sandraDecision.serveSandraPranzo &&
                _effSandraPranzo(_selectedDay))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Sandra copre la fascia pranzo (${_fmt(_engine.sandraPranzoStart)}–${_fmt(_engine.sandraPranzoEnd)})",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (sandraDecision.serveSandraSera && _effSandraSera(_selectedDay))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Sandra copre la fascia sera (${_fmt(_engine.sandraSeraStart)}–${_fmt(_engine.sandraSeraEnd)})",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

            if (inCover != SchoolCoverChoice.none &&
                inCover != SchoolCoverChoice.altro)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Ingresso scuola coperto da ${_schoolCoverLabel(inCover)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (inCover == SchoolCoverChoice.altro && inSupportSummary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  inSupportSummary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

            if (!uscita13Eff &&
                outCover != SchoolCoverChoice.none &&
                outCover != SchoolCoverChoice.altro)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Uscita scuola coperta da ${_schoolCoverLabel(outCover)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (!uscita13Eff &&
                outCover == SchoolCoverChoice.altro &&
                outSupportSummary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  outSupportSummary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

            if (uscita13Eff &&
                lunchCover != SchoolCoverChoice.none &&
                lunchCover != SchoolCoverChoice.altro)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• Pranzo coperto da ${_schoolCoverLabel(lunchCover)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (uscita13Eff &&
                lunchCover == SchoolCoverChoice.altro &&
                lunchSupportSummary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  lunchSupportSummary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
          if (state == DayGapVisualState.realGap) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < cov.gapDetails.length; i++) ...[
              Text(
                "BUCO ${i + 1} — ${_cleanGapTitle(cov.gapDetails[i].label)}",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (_extractGapTime(cov.gapDetails[i].label) != null) ...[
                const SizedBox(height: 2),
                Text(
                  _extractGapTime(cov.gapDetails[i].label)!,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              ...cov.gapDetails[i].lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    "⚠ $line",
                    style: TextStyle(color: Colors.black.withOpacity(0.72)),
                  ),
                ),
              ),
              if (i != cov.gapDetails.length - 1) const SizedBox(height: 10),
            ],
          ],
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

  Widget _buildAliceArea(bool showSummerCampSpecialCard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AliceEventPanel(
          selectedDay: _selectedDay,
          store: coreStore.aliceEventStore,
          onChanged: () {
            setState(() {});
            ipsStore.refresh(now: _selectedDay);
          },
        ),
        if (showSummerCampSpecialCard) ...[
          const SizedBox(height: 12),
          _cardSummerCampSpecialEvent(),
        ],
      ],
    );
  }

  Widget _buildDesktopThreeColumns({
    required DayOverrides ovSelected,
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTurni(),
              const SizedBox(height: 12),
              _cardOverrideStepB(ovSelected),
              const SizedBox(height: 12),
              FeriePeriodPanel(store: coreStore.feriePeriodStore),
              const SizedBox(height: 12),
              DiseasePeriodPanel(
                store: coreStore.diseasePeriodStore,
                onChanged: () {
                  setState(() {});
                  ipsStore.refresh(now: _selectedDay);
                },
              ),
              const SizedBox(height: 12),
              FourthShiftPanel(
                store: coreStore.fourthShiftStore,
                onChanged: () {
                  setState(() {});
                  ipsStore.refresh(now: _selectedDay);
                },
              ),
              const SizedBox(height: 12),
              SupportNetworkPanel(
                selectedDay: _selectedDay,
                store: coreStore.supportNetworkStore,
                daySettingsStore: daySettingsStore,
                onChanged: () {
                  setState(() {});
                  ipsStore.refresh(now: _selectedDay);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardScuola(),
              const SizedBox(height: 12),
              _buildAliceArea(showSummerCampSpecialCard),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 360,
          child: isEmergency
              ? _buildEmergencyPanelPlaceholder()
              : _cardCopertura(cov),
        ),
      ],
    );
  }

  Widget _buildTabletLayout({
    required DayOverrides ovSelected,
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardTurni(),
                  const SizedBox(height: 12),
                  _cardOverrideStepB(ovSelected),
                  const SizedBox(height: 12),
                  FeriePeriodPanel(store: coreStore.feriePeriodStore),
                  const SizedBox(height: 12),
                  DiseasePeriodPanel(
                    store: coreStore.diseasePeriodStore,
                    onChanged: () {
                      setState(() {});
                      ipsStore.refresh(now: _selectedDay);
                    },
                  ),
                  const SizedBox(height: 12),
                  FourthShiftPanel(
                    store: coreStore.fourthShiftStore,
                    onChanged: () {
                      setState(() {});
                      ipsStore.refresh(now: _selectedDay);
                    },
                  ),
                  const SizedBox(height: 12),
                  SupportNetworkPanel(
                    selectedDay: _selectedDay,
                    store: coreStore.supportNetworkStore,
                    daySettingsStore: daySettingsStore,
                    onChanged: () {
                      setState(() {});
                      ipsStore.refresh(now: _selectedDay);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardScuola(),
                  const SizedBox(height: 12),
                  _buildAliceArea(showSummerCampSpecialCard),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        isEmergency ? _buildEmergencyPanelPlaceholder() : _cardCopertura(cov),
      ],
    );
  }

  Widget _buildMobileLayout({
    required DayOverrides ovSelected,
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardTurni(),
        const SizedBox(height: 12),
        _cardOverrideStepB(ovSelected),
        const SizedBox(height: 12),
        FeriePeriodPanel(store: coreStore.feriePeriodStore),
        const SizedBox(height: 12),
        DiseasePeriodPanel(
          store: coreStore.diseasePeriodStore,
          onChanged: () {
            setState(() {});
            ipsStore.refresh(now: _selectedDay);
          },
        ),
        const SizedBox(height: 12),
        FourthShiftPanel(
          store: coreStore.fourthShiftStore,
          onChanged: () {
            setState(() {});
            ipsStore.refresh(now: _selectedDay);
          },
        ),
        const SizedBox(height: 12),
        SupportNetworkPanel(
          selectedDay: _selectedDay,
          store: coreStore.supportNetworkStore,
          daySettingsStore: daySettingsStore,
          onChanged: () {
            setState(() {});
            ipsStore.refresh(now: _selectedDay);
          },
        ),
        const SizedBox(height: 12),
        _cardScuola(),
        const SizedBox(height: 12),
        _buildAliceArea(showSummerCampSpecialCard),
        const SizedBox(height: 12),
        isEmergency ? _buildEmergencyPanelPlaceholder() : _cardCopertura(cov),
      ],
    );
  }

  Widget _buildMainLayout({
    required DayOverrides ovSelected,
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        if (w >= 1100) {
          return _buildDesktopThreeColumns(
            ovSelected: ovSelected,
            cov: cov,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
          );
        }

        if (w >= 800) {
          return _buildTabletLayout(
            ovSelected: ovSelected,
            cov: cov,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
          );
        }

        return _buildMobileLayout(
          ovSelected: ovSelected,
          cov: cov,
          showSummerCampSpecialCard: showSummerCampSpecialCard,
          isEmergency: isEmergency,
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
    final bool showSummerCampSpecialCard = _selectedDayIsSummerCampDay();

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildIpsPressureLine(ipsCoverage30),
            const SizedBox(height: 8),
            _weekNavBar(),
            const SizedBox(height: 8),
            _buildEmergencyBannerDebug(),
            if (!isEmergency) _buildDayGapsBox(cov),
            const SizedBox(height: 12),
            _buildMainLayout(
              ovSelected: ovSelected,
              cov: cov,
              showSummerCampSpecialCard: showSummerCampSpecialCard,
              isEmergency: isEmergency,
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
      subtitle:
          "Orari letti dal motore reale: rotazione standard oppure Quarta Squadra se attiva.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _turnRow("Matteo", m),
          const SizedBox(height: 10),
          _turnRow("Chiara", c),
          const SizedBox(height: 8),
          Text(
            "Nota: se per Matteo o Chiara esiste un periodo attivo di Quarta Squadra, i turni mostrati qui sono già quelli della Quarta Squadra.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Il riposo post-notte fino alle 14:30 continua a essere applicato dal motore.",
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

  Widget _cardOverrideStepB(DayOverrides ovSelected) {
    return _card(
      title: "Stato giornaliero",
      subtitle: "Imposta lo stato del giorno (influenza subito la copertura).",
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

  Widget _cardSummerCampSpecialEvent() {
    final isCampDay = _selectedDayIsSummerCampDay();
    final current = _selectedDaySpecialCampEvent();

    return _card(
      title: "Centro estivo – Evento speciale",
      subtitle:
          "Override giornaliero del centro estivo per la data selezionata.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Data: ${DateFormat('EEEE d MMMM yyyy', 'it_IT').format(_selectedDay)}",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (!isCampDay)
            Text(
              "Nessun centro estivo attivo in questo giorno. L’override speciale si usa solo nei giorni di centro estivo.",
              style: TextStyle(color: Colors.black.withOpacity(0.65)),
            ),
          if (isCampDay && current == null) ...[
            const Text(
              "Nessun evento speciale impostato per questo giorno.",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _editSummerCampSpecialEventForSelectedDay,
              icon: const Icon(Icons.add),
              label: const Text("Aggiungi evento speciale"),
            ),
          ],
          if (isCampDay && current != null) ...[
            Text(
              "Evento: ${current.label}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              "Orario: ${_fmt(current.start)}–${_fmt(current.end)}",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editSummerCampSpecialEventForSelectedDay,
                    icon: const Icon(Icons.edit),
                    label: const Text("Modifica"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removeSummerCampSpecialEventForSelectedDay,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Rimuovi"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
              setState(
                () => daySettingsStore.setSchoolInCoverForDay(_selectedDay, v),
              );
              if (v == SchoolCoverChoice.altro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Altro: lista persone arriverà dopo (placeholder).",
                    ),
                  ),
                );
              }
              ipsStore.refresh(now: _selectedDay);
            },
          ),
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
                setState(
                  () =>
                      daySettingsStore.setSchoolOutCoverForDay(_selectedDay, v),
                );
                if (v == SchoolCoverChoice.altro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Altro: lista persone arriverà dopo (placeholder).",
                      ),
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
                labelText:
                    "Pranzo ${_fmt(uscitaAt!)}–${_fmt(_engine.sandraPranzoEnd)}",
              ),
              items: SchoolCoverChoice.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(_schoolCoverLabel(c)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(
                  () => daySettingsStore.setLunchCoverForDay(_selectedDay, v),
                );
                if (v == SchoolCoverChoice.altro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Altro: lista persone arriverà dopo (placeholder).",
                      ),
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

  Widget _cardCopertura(CoverageResultStepA cov) {
    final uscita13Eff = _effUscita13(_selectedDay);
    final sandraDecision = _sandraDecisionForDay(_selectedDay);

    final manualMattina = _effSandraMattina(_selectedDay);
    final manualPranzo = _effSandraPranzo(_selectedDay);
    final manualSera = _effSandraSera(_selectedDay);

    return _card(
      title: "Copertura Sandra / Babysitter",
      subtitle: "Motore informativo + scelta manuale umana.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            subtitle: _sandraNeedText(
              serve: sandraDecision.serveSandraMattina,
              manual: manualMattina,
            ),
            value: manualMattina,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraMattinaForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Sandra – Fascia pranzo"),
            subtitle: _sandraNeedText(
              serve: sandraDecision.serveSandraPranzo,
              manual: manualPranzo,
            ),
            value: manualPranzo,
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
            subtitle: _sandraNeedText(
              serve: sandraDecision.serveSandraSera,
              manual: manualSera,
            ),
            value: manualSera,
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraSeraForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const Divider(),
          Text(
            uscita13Eff
                ? "Uscita anticipata attiva"
                : "Uscita anticipata non attiva",
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

  Widget _sandraNeedText({required bool serve, required bool manual}) {
    String text;
    Color color;

    if (serve && manual) {
      text = "Serve dal motore • attivata manualmente";
      color = Colors.orange;
    } else if (serve) {
      text = "Serve dal motore";
      color = Colors.red;
    } else if (manual) {
      text = "Attivata manualmente";
      color = Colors.blueGrey;
    } else {
      text = "Non serve dal motore";
      color = Colors.green;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
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

enum DayGapVisualState { noProblem, coveredNeed, realGap }

class CoverageResultStepA {
  final bool ok;
  final List<String> details;
  final List<CoverageGapDetail> gapDetails;
  final String bannerText;

  const CoverageResultStepA({
    required this.ok,
    required this.details,
    required this.gapDetails,
    required this.bannerText,
  });
}
