// lib/screens/calendario_screen_stepa.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/override_store.dart';
import '../logic/emergency_store.dart';
import '../logic/emergency_day_logic.dart';
import '../logic/coverage_engine.dart';
import '../logic/turn_engine.dart';
import '../logic/turn_override_store.dart';
import '../logic/ferie_period_store.dart';
import '../logic/alice_companion_store.dart';

import '../models/day_override.dart';
import '../models/disease_period.dart';
import '../models/real_event.dart';
import '../models/turn_override.dart';
import '../models/work_shift.dart';
import '../models/rotation_override.dart';
import '../models/alice_special_event.dart';
import '../logic/core_store.dart';
import '../logic/alice_special_event_store.dart';
import '../models/week_identity.dart';
import '../logic/settings_store.dart';
import '../logic/ips_store.dart';
import '../logic/day_settings_store.dart';
import '../logic/alice_event_store.dart';

import '../widgets/stepb_override_panel.dart';
import '../widgets/alice_event_panel.dart';
import '../widgets/real_event_panel.dart';
import '../widgets/support_network_panel.dart';
import '../widgets/fourth_shift_panel.dart';
import '../widgets/ferie_period_panel.dart';
import '../widgets/disease_period_panel.dart';
import '../widgets/extra_events_dialog.dart';

// ✅ NEW: Eventi speciali centro estivo
import '../logic/summer_camp_special_event_store.dart';

import '../utils/calendario_formatters.dart';

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
  TurnOverrideStore get turnOverrideStore => coreStore.turnOverrideStore;

  CoverageEngine get _engine => coreStore.coverageEngine;
  TurnEngine get _turns => coreStore.turnEngine;

  late DateTime _selectedDay;

  final GlobalKey _turniKey = GlobalKey();
  final GlobalKey _overrideKey = GlobalKey();
  final GlobalKey _eventiKey = GlobalKey();

  bool _realitySectionOpen = true;
  bool _aliceSectionOpen = true;
  bool _decisionsSectionOpen = false;
  bool _permessoPanelOpen = false;
  bool _showAliceEventEditor = false;

  final TextEditingController _aliceEventNameController =
      TextEditingController();
  final TextEditingController _aliceEventNoteController =
      TextEditingController();

  TimeOfDay _aliceEventStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _aliceEventEnd = const TimeOfDay(hour: 20, minute: 0);
  AliceSpecialEventCategory _aliceEventCategory =
      AliceSpecialEventCategory.activity;
  String? _editingAliceSpecialEventId;

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  void _closeSheetAndScrollTo(GlobalKey key) {
    Navigator.of(context).pop();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _scrollTo(key);
    });
  }

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
        ". Supporto $contextLabel: ${person.name} ${fmtTimeOfDay(person.start)}-${fmtTimeOfDay(person.end)}",
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

  Future<void> _showNuovaRotazioneDialog() async {
    TurnPerson selectedPerson = TurnPerson.matteo;
    DateTime selectedStartDate = _selectedDay;
    TurnType selectedStartShift = TurnType.mattina;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuova rotazione"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TurnPerson>(
                    value: selectedPerson,
                    decoration: const InputDecoration(labelText: "Persona"),
                    items: const [
                      DropdownMenuItem(
                        value: TurnPerson.matteo,
                        child: Text("Matteo"),
                      ),
                      DropdownMenuItem(
                        value: TurnPerson.chiara,
                        child: Text("Chiara"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedPerson = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  ListTile(
                    title: const Text("Data inizio"),
                    subtitle: Text(
                      "${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          selectedStartDate = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<TurnType>(
                    value: selectedStartShift,
                    decoration: const InputDecoration(
                      labelText: "Turno iniziale",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TurnType.mattina,
                        child: Text("Mattina"),
                      ),
                      DropdownMenuItem(
                        value: TurnType.pomeriggio,
                        child: Text("Pomeriggio"),
                      ),
                      DropdownMenuItem(
                        value: TurnType.notte,
                        child: Text("Notte"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedStartShift = value;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Chiudi"),
            ),

            ElevatedButton(
              onPressed: () {
                coreStore.rotationOverrideStore.add(
                  RotationOverride(
                    person: selectedPerson == TurnPerson.matteo
                        ? TurnPersonId.matteo
                        : TurnPersonId.chiara,
                    startDate: selectedStartDate,
                    startPoint: selectedStartShift == TurnType.mattina
                        ? RotationStartPoint.mattina
                        : selectedStartShift == TurnType.pomeriggio
                        ? RotationStartPoint.pomeriggio
                        : RotationStartPoint.notte,
                  ),
                );

                setState(() {});

                Navigator.pop(context);
              },
              child: const Text("Conferma"),
            ),
          ],
        );
      },
    );
  }

  void _showTurnEventConflictActionsSheet({
    required String personName,
    required List<TurnEventConflictResolution> conflicts,
  }) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Scelte possibili — $personName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Il sistema ha rilevato un conflitto reale tra turno ed evento. Qui sotto vedi le strade possibili da valutare.",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...conflicts.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "• ${realEventText(r.event)} — ${conflictStateLabel(r.state)}${r.detailText == null ? "" : "\n${r.detailText}"}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text("Cambia turno"),
                  subtitle: const Text(
                    "Da usare se il problema si risolve spostando il turno di lavoro.",
                  ),
                  onTap: () {
                    _closeSheetAndScrollTo(_turniKey);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy),
                  title: const Text("Segna permesso / ferie"),
                  subtitle: const Text(
                    "Da usare se l’evento va mantenuto e serve liberare la fascia di lavoro.",
                  ),
                  onTap: () {
                    _closeSheetAndScrollTo(_overrideKey);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_calendar),
                  title: const Text("Sposta evento"),
                  subtitle: const Text(
                    "Da usare se l’appuntamento è modificabile e conviene spostarlo fuori turno.",
                  ),
                  onTap: () {
                    _closeSheetAndScrollTo(_eventiKey);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  DateTime _atDayTime(DateTime day, TimeOfDay t) {
    final d0 = _onlyDate(day);
    return DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);
  }

  TimeOfDay? _parseTimeOfDayFromText(String text) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (m == null) return null;

    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null) return null;
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;

    return TimeOfDay(hour: h, minute: min);
  }

  _DateRange? _permessoRangeFromDisplayString(dynamic pr, DateTime day) {
    try {
      final dynamic displayDyn = pr.toDisplayString();
      if (displayDyn is! String) return null;

      final parts = displayDyn.split(RegExp(r'[–-]'));
      if (parts.length != 2) return null;

      final start = _parseTimeOfDayFromText(parts[0].trim());
      final end = _parseTimeOfDayFromText(parts[1].trim());
      if (start == null || end == null) return null;

      final startDT = _atDayTime(day, start);
      final endDT = _atDayTime(day, end);
      if (!endDT.isAfter(startDT)) return null;

      return _DateRange(start: startDT, end: endDT);
    } catch (_) {
      return null;
    }
  }

  bool _isSchoolInGapLabel(String label) {
    final lower = label.toLowerCase();
    return lower.contains('alice ingresso') ||
        lower.contains('ingresso scuola');
  }

  bool _isSchoolOutGapLabel(String label) {
    final lower = label.toLowerCase();
    return lower.contains('alice uscita') || lower.contains('uscita scuola');
  }

  bool _isLunchGapLabel(String label) {
    final lower = label.toLowerCase();
    return lower.contains('pranzo');
  }

  String _gapTitleWithAliceState(String label) {
    final clean = cleanGapTitle(label);

    if (!clean.toLowerCase().startsWith('alice a casa')) {
      return clean;
    }

    final aliceEvent = coreStore.aliceEventStore.getEventForDay(_selectedDay);
    if (aliceEvent == null) return clean;

    String? stateLabel;
    switch (aliceEvent.type) {
      case AliceEventType.schoolNormal:
        stateLabel = null;
        break;
      case AliceEventType.vacation:
        stateLabel = "Vacanza";
        break;
      case AliceEventType.schoolClosure:
        stateLabel = "Scuola chiusa";
        break;
      case AliceEventType.sickness:
        stateLabel = "Malattia";
        break;
      case AliceEventType.summerCamp:
        stateLabel = "Centro estivo";
        break;
    }

    if (stateLabel == null || stateLabel.isEmpty) return clean;

    final parts = clean.split(':');
    if (parts.length < 2) {
      return "Alice a casa ($stateLabel)";
    }

    final left = parts.first.trim();
    final right = parts.sublist(1).join(':').trim();

    return "$left ($stateLabel): $right";
  }

  String _companionActionTextForGap(String label) {
    final match = RegExp(r'(\d{2}:\d{2})–(\d{2}:\d{2})').firstMatch(label);
    if (match == null) return "Porta Alice con te";

    TimeOfDay parse(String t) {
      final p = t.split(":");
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    final start = parse(match.group(1)!);
    final end = parse(match.group(2)!);

    final person = _whoCanBringAliceForGap(start: start, end: end);

    final existing = coreStore.aliceCompanionStore
        .entriesForDay(_selectedDay)
        .any(
          (e) =>
              e.person == person &&
              e.start.hour == start.hour &&
              e.start.minute == start.minute &&
              e.end.hour == end.hour &&
              e.end.minute == end.minute,
        );

    final who = person == AliceCompanionPerson.matteo ? "Matteo" : "Chiara";

    return existing ? "Togli Alice da $who" : "Porta Alice con $who";
  }

  String _companionButtonTextForGap(String label) {
    final match = RegExp(r'(\d{2}:\d{2})–(\d{2}:\d{2})').firstMatch(label);
    if (match == null) return "Porta Alice con te";

    TimeOfDay parse(String t) {
      final p = t.split(":");
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    final start = parse(match.group(1)!);
    final end = parse(match.group(2)!);

    final person = _whoCanBringAliceForGap(start: start, end: end);

    final active = coreStore.aliceCompanionStore
        .entriesForDay(_selectedDay)
        .any(
          (e) =>
              e.person == person &&
              e.start.hour == start.hour &&
              e.start.minute == start.minute &&
              e.end.hour == end.hour &&
              e.end.minute == end.minute,
        );

    final who = person == AliceCompanionPerson.matteo ? "Matteo" : "Chiara";

    return active ? "Alice con $who ✅" : "Porta Alice con $who";
  }

  _DateRange? _rangeOverlap(_DateRange a, _DateRange b) {
    final start = a.start.isAfter(b.start) ? a.start : b.start;
    final end = a.end.isBefore(b.end) ? a.end : b.end;

    if (!end.isAfter(start)) return null;
    return _DateRange(start: start, end: end);
  }

  _DateRange? _eventRangeForConflict(RealEvent event, DateTime day) {
    final d0 = _onlyDate(day);

    if (event.startTime == null && event.endTime == null) {
      return _DateRange(
        start: DateTime(d0.year, d0.month, d0.day, 0, 0),
        end: DateTime(d0.year, d0.month, d0.day, 23, 59),
      );
    }

    if (event.startTime != null && event.endTime != null) {
      final start = _atDayTime(d0, event.startTime!);
      final end = _atDayTime(d0, event.endTime!);

      if (!end.isAfter(start)) return null;

      return _DateRange(start: start, end: end);
    }

    if (event.startTime != null) {
      final start = _atDayTime(d0, event.startTime!);
      return _DateRange(
        start: start,
        end: start.add(const Duration(minutes: 1)),
      );
    }

    final end = _atDayTime(d0, event.endTime!);
    return _DateRange(
      start: end.subtract(const Duration(minutes: 1)),
      end: end,
    );
  }

  _DateRange? _permessoRangeFromOverride(
    PersonDayOverride? manualOverride,
    DateTime day,
  ) {
    if (manualOverride == null) return null;
    if (manualOverride.status != OverrideStatus.permesso) return null;

    final dynamic pr = manualOverride.permessoRange;
    if (pr == null) return null;

    final parsedFromDisplay = _permessoRangeFromDisplayString(pr, day);
    if (parsedFromDisplay != null) return parsedFromDisplay;

    TimeOfDay? start;
    TimeOfDay? end;

    if (pr is Map) {
      final dynamic s1 = pr['start'];
      final dynamic e1 = pr['end'];
      final dynamic s2 = pr['from'];
      final dynamic e2 = pr['to'];
      final dynamic s3 = pr['startTime'];
      final dynamic e3 = pr['endTime'];

      if (s1 is TimeOfDay && e1 is TimeOfDay) {
        start = s1;
        end = e1;
      } else if (s2 is TimeOfDay && e2 is TimeOfDay) {
        start = s2;
        end = e2;
      } else if (s3 is TimeOfDay && e3 is TimeOfDay) {
        start = s3;
        end = e3;
      }
    } else {
      try {
        final dynamic s1 = pr.start;
        final dynamic e1 = pr.end;
        if (s1 is TimeOfDay && e1 is TimeOfDay) {
          start = s1;
          end = e1;
        }
      } catch (_) {}

      if (start == null || end == null) {
        try {
          final dynamic s2 = pr.from;
          final dynamic e2 = pr.to;
          if (s2 is TimeOfDay && e2 is TimeOfDay) {
            start = s2;
            end = e2;
          }
        } catch (_) {}
      }

      if (start == null || end == null) {
        try {
          final dynamic s3 = pr.startTime;
          final dynamic e3 = pr.endTime;
          if (s3 is TimeOfDay && e3 is TimeOfDay) {
            start = s3;
            end = e3;
          }
        } catch (_) {}
      }
    }

    if (start == null || end == null) return null;

    final startDT = _atDayTime(day, start);
    final endDT = _atDayTime(day, end);

    if (!endDT.isAfter(startDT)) return null;

    return _DateRange(start: startDT, end: endDT);
  }

  String _rangeLabel(_DateRange range) {
    return "${fmtDateTimeHHmm(range.start)}-${fmtDateTimeHHmm(range.end)}";
  }

  bool _isPersonOnFerie({
    required String personKey,
    required PersonDayOverride? manualOverride,
    required DateTime day,
  }) {
    if (manualOverride?.status == OverrideStatus.ferie) {
      return true;
    }

    FeriePerson? feriePerson;
    if (personKey == 'matteo') feriePerson = FeriePerson.matteo;
    if (personKey == 'chiara') feriePerson = FeriePerson.chiara;

    if (feriePerson == null) return false;

    return coreStore.feriePeriodStore.isOnHoliday(feriePerson, _onlyDate(day));
  }

  String _turnPlanSummary(TurnPlan plan) {
    final label = _turnLabel(plan.type);
    if (plan.isOff) return "OFF";
    return "$label ${fmtTimeOfDay(plan.start)} ${fmtTimeOfDay(plan.end)}";
  }

  String _buildOpenConflictDetail({
    required TurnPlan turnPlan,
    required _DateRange overlap,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: ${_turnPlanSummary(turnPlan)}\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}";
  }

  String _buildPartialConflictDetail({
    required TurnPlan turnPlan,
    required _DateRange overlap,
    required _DateRange covered,
    required List<String> uncoveredParts,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: ${_turnPlanSummary(turnPlan)}\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Permesso copre: ${_rangeLabel(covered)}\n"
        "Resta scoperto: ${uncoveredParts.join(" + ")}";
  }

  String _buildResolvedConflictDetail({
    required TurnPlan turnPlan,
    required _DateRange overlap,
    required _DateRange covered,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: ${_turnPlanSummary(turnPlan)}\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Causa risoluzione: permesso ${_rangeLabel(covered)}";
  }

  String _buildResolvedConflictDetailFerie({
    required TurnPlan turnPlan,
    required _DateRange overlap,
  }) {
    return "Evento dentro il turno di lavoro.\n"
        "Turno: ${_turnPlanSummary(turnPlan)}\n"
        "Fascia in conflitto: ${_rangeLabel(overlap)}\n"
        "Causa risoluzione: ferie";
  }

  TurnEventConflictState _worstConflictState(
    List<TurnEventConflictResolution> conflicts,
  ) {
    if (conflicts.any((c) => c.state == TurnEventConflictState.open)) {
      return TurnEventConflictState.open;
    }

    if (conflicts.any((c) => c.state == TurnEventConflictState.partial)) {
      return TurnEventConflictState.partial;
    }

    return TurnEventConflictState.resolved;
  }

  TurnPersonId? _personIdFromKey(String personKey) {
    switch (personKey) {
      case 'matteo':
        return TurnPersonId.matteo;
      case 'chiara':
        return TurnPersonId.chiara;
      default:
        return null;
    }
  }

  String _turnOverrideShiftLabel(TurnOverrideShift shift) {
    switch (shift) {
      case TurnOverrideShift.mattina:
        return "Mattina";
      case TurnOverrideShift.pomeriggio:
        return "Pomeriggio";
      case TurnOverrideShift.notte:
        return "Notte";
      case TurnOverrideShift.off:
        return "Off";
    }
  }

  String? _turnOverrideStatusTextForPerson({
    required String personKey,
    required DateTime day,
  }) {
    final person = _personIdFromKey(personKey);
    if (person == null) return null;

    final daily = coreStore.turnOverrideStore.dailyOverrideFor(
      person: person,
      day: day,
    );
    if (daily != null && daily.shift != null) {
      return "Turno cambiato manualmente • ${_turnOverrideShiftLabel(daily.shift!)} (solo oggi)";
    }

    final period = coreStore.turnOverrideStore.periodOverrideFor(
      person: person,
      day: day,
    );
    if (period != null && period.shift != null && period.endDate != null) {
      return "Turno cambiato manualmente • ${_turnOverrideShiftLabel(period.shift!)} (${fmtShortDate(period.startDate)} → ${fmtShortDate(period.endDate!)})";
    }

    return null;
  }

  // 🆕 Fonte strutturale del turno mostrato oggi
  String? _turnSourceTextForPerson({
    required String personKey,
    required DateTime day,
  }) {
    final person = _personIdFromKey(personKey);
    if (person == null) return null;

    final daily = coreStore.turnOverrideStore.dailyOverrideFor(
      person: person,
      day: day,
    );
    if (daily != null && daily.shift != null) {
      return "Cambio turno (solo oggi)";
    }

    final period = coreStore.turnOverrideStore.periodOverrideFor(
      person: person,
      day: day,
    );
    if (period != null && period.shift != null) {
      return "Cambio turno (periodo)";
    }

    final activeRotation = coreStore.rotationOverrideStore.activeFor(
      person: person,
      day: day,
    );
    if (activeRotation != null) {
      return "Nuova rotazione";
    }

    final isFourthShiftActive = coreStore.fourthShiftStore
        .isActiveForPersonOnDay(person.name, _onlyDate(day));
    if (isFourthShiftActive) {
      return "Quarta squadra";
    }

    return null;
  }

  Color _turnSourceColor(String sourceText) {
    final lower = sourceText.toLowerCase();

    if (lower.contains('quarta squadra')) {
      return Colors.orange;
    }

    if (lower.contains('cambio turno')) {
      return Colors.amber.shade800;
    }

    if (lower.contains('nuova rotazione')) {
      return Colors.deepPurple;
    }

    return Colors.blueGrey;
  }

  void _addDailyTurnOverrideTest({
    required TurnPersonId person,
    required TurnOverrideShift shift,
  }) {
    coreStore.turnOverrideStore.add(
      TurnOverride(
        type: TurnOverrideType.dailyShiftChange,
        person: person,
        startDate: _selectedDay,
        shift: shift,
      ),
    );
    setState(() {});
  }

  void _addPeriodTurnOverrideTest({
    required TurnPersonId person,
    required TurnOverrideShift shift,
  }) {
    coreStore.turnOverrideStore.add(
      TurnOverride(
        type: TurnOverrideType.periodShiftChange,
        person: person,
        startDate: _selectedDay,
        endDate: _selectedDay.add(const Duration(days: 2)),
        shift: shift,
      ),
    );
    setState(() {});
  }

  void _clearTurnOverrideTests() {
    coreStore.turnOverrideStore.clearAll();
    setState(() {});
  }

  Widget _turnOverrideDebugBox() {
    final matteoDaily = coreStore.turnOverrideStore.dailyOverrideFor(
      person: TurnPersonId.matteo,
      day: _selectedDay,
    );
    final chiaraDaily = coreStore.turnOverrideStore.dailyOverrideFor(
      person: TurnPersonId.chiara,
      day: _selectedDay,
    );
    final matteoPeriod = coreStore.turnOverrideStore.periodOverrideFor(
      person: TurnPersonId.matteo,
      day: _selectedDay,
    );
    final chiaraPeriod = coreStore.turnOverrideStore.periodOverrideFor(
      person: TurnPersonId.chiara,
      day: _selectedDay,
    );

    String fmtOverride(TurnOverride? item) {
      if (item == null || item.shift == null) return "nessuno";
      if (item.type == TurnOverrideType.dailyShiftChange) {
        return "${_turnOverrideShiftLabel(item.shift!)} (solo oggi)";
      }
      if (item.endDate != null) {
        return "${_turnOverrideShiftLabel(item.shift!)} (${fmtShortDate(item.startDate)} → ${fmtShortDate(item.endDate!)})";
      }
      return _turnOverrideShiftLabel(item.shift!);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DEBUG TEST — Cambio turno",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "Usa questi pulsanti solo per verificare che il motore legga davvero i nuovi override turno.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.68),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Matteo oggi: ${fmtOverride(matteoDaily)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            "Chiara oggi: ${fmtOverride(chiaraDaily)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            "Matteo periodo: ${fmtOverride(matteoPeriod)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            "Chiara periodo: ${fmtOverride(chiaraPeriod)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {
                  _addDailyTurnOverrideTest(
                    person: TurnPersonId.matteo,
                    shift: TurnOverrideShift.pomeriggio,
                  );
                },
                child: const Text("Test Matteo oggi → Pomeriggio"),
              ),
              OutlinedButton(
                onPressed: () {
                  _addDailyTurnOverrideTest(
                    person: TurnPersonId.chiara,
                    shift: TurnOverrideShift.mattina,
                  );
                },
                child: const Text("Test Chiara oggi → Mattina"),
              ),
              OutlinedButton(
                onPressed: () {
                  _addPeriodTurnOverrideTest(
                    person: TurnPersonId.matteo,
                    shift: TurnOverrideShift.notte,
                  );
                },
                child: const Text("Test Matteo periodo → Notte"),
              ),
              OutlinedButton(
                onPressed: () {
                  _addPeriodTurnOverrideTest(
                    person: TurnPersonId.chiara,
                    shift: TurnOverrideShift.pomeriggio,
                  );
                },
                child: const Text("Test Chiara periodo → Pomeriggio"),
              ),
              OutlinedButton(
                onPressed: _clearTurnOverrideTests,
                child: const Text("Pulisci test turni"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TurnEventConflictResolution> _turnEventResolutionsForPerson({
    required String personKey,
    required TurnPlan turnPlan,
    required PersonDayOverride? manualOverride,
    required DateTime day,
  }) {
    if (turnPlan.isOff) return const [];

    final turnRange = _DateRange(
      start: _atDayTime(day, turnPlan.start),
      end: _atDayTime(day, turnPlan.end),
    );

    final permessoRange = _permessoRangeFromOverride(manualOverride, day);
    final isOnFerie = _isPersonOnFerie(
      personKey: personKey,
      manualOverride: manualOverride,
      day: day,
    );
    final personEvents = _eventsForPersonOnDay(personKey: personKey, day: day);

    final resolutions = <TurnEventConflictResolution>[];

    for (final event in personEvents) {
      final eventRange = _eventRangeForConflict(event, day);
      if (eventRange == null) continue;

      final overlap = _rangeOverlap(turnRange, eventRange);
      if (overlap == null) continue;

      if (isOnFerie) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.resolved,
            overlapRange: overlap,
            detailText: _buildResolvedConflictDetailFerie(
              turnPlan: turnPlan,
              overlap: overlap,
            ),
          ),
        );
        continue;
      }

      if (permessoRange == null) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.open,
            overlapRange: overlap,
            detailText: _buildOpenConflictDetail(
              turnPlan: turnPlan,
              overlap: overlap,
            ),
          ),
        );
        continue;
      }

      final covered = _rangeOverlap(overlap, permessoRange);

      if (covered == null) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.open,
            overlapRange: overlap,
            detailText: _buildOpenConflictDetail(
              turnPlan: turnPlan,
              overlap: overlap,
            ),
          ),
        );
        continue;
      }

      final fullyCovered =
          covered.start.isAtSameMomentAs(overlap.start) &&
          covered.end.isAtSameMomentAs(overlap.end);

      if (fullyCovered) {
        resolutions.add(
          TurnEventConflictResolution(
            event: event,
            state: TurnEventConflictState.resolved,
            overlapRange: overlap,
            detailText: _buildResolvedConflictDetail(
              turnPlan: turnPlan,
              overlap: overlap,
              covered: covered,
            ),
          ),
        );
        continue;
      }

      _DateRange? uncoveredBefore;
      _DateRange? uncoveredAfter;

      if (covered.start.isAfter(overlap.start)) {
        uncoveredBefore = _DateRange(start: overlap.start, end: covered.start);
      }
      if (covered.end.isBefore(overlap.end)) {
        uncoveredAfter = _DateRange(start: covered.end, end: overlap.end);
      }

      final uncoveredParts = <String>[];
      if (uncoveredBefore != null) {
        uncoveredParts.add(_rangeLabel(uncoveredBefore));
      }
      if (uncoveredAfter != null) {
        uncoveredParts.add(_rangeLabel(uncoveredAfter));
      }

      resolutions.add(
        TurnEventConflictResolution(
          event: event,
          state: TurnEventConflictState.partial,
          overlapRange: overlap,
          detailText: _buildPartialConflictDetail(
            turnPlan: turnPlan,
            overlap: overlap,
            covered: covered,
            uncoveredParts: uncoveredParts,
          ),
        ),
      );
    }

    return resolutions;
  }

  String? _extractGapTime(String label) {
    final parts = label.split(': ');
    if (parts.length < 2) return null;

    final candidate = parts.last.trim();
    if (candidate.contains('–')) return null;
    if (candidate.contains('-')) return null;

    return null;
  }

  List<RealEvent> _eventsForPersonOnDay({
    required String personKey,
    required DateTime day,
  }) {
    final events = coreStore.realEventStore.eventsForDay(_onlyDate(day));

    final filtered = events.where((e) => e.personKey == personKey).toList();

    filtered.sort((a, b) {
      final aMin = a.startTime == null
          ? 9999
          : a.startTime!.hour * 60 + a.startTime!.minute;
      final bMin = b.startTime == null
          ? 9999
          : b.startTime!.hour * 60 + b.startTime!.minute;
      return aMin.compareTo(bMin);
    });

    return filtered;
  }

  List<RealEvent> _familyEventsOnDay(DateTime day) {
    final events = coreStore.realEventStore.eventsForDay(_onlyDate(day));

    final filtered = events
        .where(
          (e) =>
              (e.personKey?.toLowerCase() == 'family') ||
              (e.personKey?.toLowerCase() == 'generale'),
        )
        .toList();

    filtered.sort((a, b) {
      final aMin = a.startTime == null
          ? 9999
          : a.startTime!.hour * 60 + a.startTime!.minute;
      final bMin = b.startTime == null
          ? 9999
          : b.startTime!.hour * 60 + b.startTime!.minute;
      return aMin.compareTo(bMin);
    });

    return filtered;
  }

  String? _personRealStatusText({
    required String personKey,
    required PersonDayOverride? manualOverride,
    required DateTime day,
  }) {
    final d0 = _onlyDate(day);

    final turnOverrideText = _turnOverrideStatusTextForPerson(
      personKey: personKey,
      day: d0,
    );
    if (turnOverrideText != null) return turnOverrideText;

    if (manualOverride != null) {
      switch (manualOverride.status) {
        case OverrideStatus.normal:
          break;
        case OverrideStatus.permesso:
          final range = manualOverride.permessoRange;
          if (range != null) {
            return "Permesso ${range.toDisplayString()}";
          }
          return "Permesso";
        case OverrideStatus.ferie:
          return "Ferie";
        case OverrideStatus.malattiaLeggera:
          return "Malattia leggera";
        case OverrideStatus.malattiaALetto:
          return "Malattia a letto";
      }
    }

    final disease = coreStore.diseasePeriodStore.getPeriodForDay(personKey, d0);
    if (disease != null) {
      switch (disease.type) {
        case DiseaseType.mild:
          return "Malattia leggera";
        case DiseaseType.bed:
          return "Malattia a letto";
      }
    }

    FeriePerson? feriePerson;
    if (personKey == 'matteo') feriePerson = FeriePerson.matteo;
    if (personKey == 'chiara') feriePerson = FeriePerson.chiara;

    if (feriePerson != null &&
        coreStore.feriePeriodStore.isOnHoliday(feriePerson, d0)) {
      return "Ferie";
    }

    return null;
  }

  CoverageResultStepA _computeCoverageStepA(DateTime day) {
    final d0 = _onlyDate(day);

    final ov = _getOverridesForDay(d0);

    final uscitaAt = _effUscitaAnticipataAt(d0);
    final uscita13Eff = uscitaAt != null;

    final outStart = _effSchoolOutStart(d0);
    final outEnd = _effSchoolOutEnd(d0);

    final schoolInCover = _effectiveSchoolInCover(d0);
    final schoolOutCover = _effectiveSchoolOutCover(d0);
    final lunchCover = _effectiveLunchCover(d0);

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
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: outStart,
      schoolOutEnd: outEnd,
      lunchCover: lunchCover,
      uscitaAnticipataAt: uscitaAt,
    );

    final filteredGapDetails = analysis.details.where((d) {
      final label = d.label;

      if (schoolInCover != SchoolCoverChoice.none &&
          _isSchoolInGapLabel(label)) {
        return false;
      }

      if (!uscita13Eff &&
          schoolOutCover != SchoolCoverChoice.none &&
          _isSchoolOutGapLabel(label)) {
        return false;
      }

      if (uscita13Eff &&
          lunchCover != SchoolCoverChoice.none &&
          _isLunchGapLabel(label)) {
        return false;
      }

      return true;
    }).toList();

    final gaps = filteredGapDetails.map((d) => d.label).toList();
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
      gapDetails: filteredGapDetails,
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

  AliceCompanionPerson _whoCanBringAliceForGap({
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final day = _selectedDay;

    DateTime toDT(TimeOfDay t) =>
        DateTime(day.year, day.month, day.day, t.hour, t.minute);

    final gapStart = toDT(start);
    final gapEnd = toDT(end);

    bool overlaps(
      DateTime aStart,
      DateTime aEnd,
      DateTime bStart,
      DateTime bEnd,
    ) {
      return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    bool matteoBusy = false;
    bool chiaraBusy = false;

    final matteoPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: day,
    );
    if (!matteoPlan.isOff) {
      final workStart = toDT(matteoPlan.start);
      final workEnd = toDT(matteoPlan.end);
      matteoBusy = overlaps(workStart, workEnd, gapStart, gapEnd);
    }

    final chiaraPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.chiara,
      day: day,
    );
    if (!chiaraPlan.isOff) {
      final workStart = toDT(chiaraPlan.start);
      final workEnd = toDT(chiaraPlan.end);
      chiaraBusy = overlaps(workStart, workEnd, gapStart, gapEnd);
    }

    final events = coreStore.realEventStore.eventsForDay(_onlyDate(day));
    for (final e in events) {
      if (e.startTime == null || e.endTime == null) continue;

      final eventStart = toDT(e.startTime!);
      final eventEnd = toDT(e.endTime!);
      final hit = overlaps(eventStart, eventEnd, gapStart, gapEnd);

      if (!hit) continue;

      if (e.personKey == 'matteo') matteoBusy = true;
      if (e.personKey == 'chiara') chiaraBusy = true;
    }

    for (final e in events) {
      if (e.startTime == null || e.endTime == null) continue;

      final eventStart = toDT(e.startTime!);
      final eventEnd = toDT(e.endTime!);
      final hit = overlaps(eventStart, eventEnd, gapStart, gapEnd);

      if (!hit) continue;

      if (e.personKey == 'chiara') return AliceCompanionPerson.chiara;
      if (e.personKey == 'matteo') return AliceCompanionPerson.matteo;
    }

    if (!matteoBusy && chiaraBusy) return AliceCompanionPerson.matteo;
    if (!chiaraBusy && matteoBusy) return AliceCompanionPerson.chiara;

    return AliceCompanionPerson.matteo;
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

    final visibleGapDetails = cov.gapDetails.isNotEmpty
        ? cov.gapDetails
        : coreStore.aliceCompanionStore.entriesForDay(_selectedDay).map((e) {
            final who = e.person == AliceCompanionPerson.matteo
                ? "Matteo"
                : "Chiara";

            return CoverageGapDetail(
              label:
                  "Alice con $who: ${fmtTimeOfDay(e.start)}–${fmtTimeOfDay(e.end)}",
              lines: const [],
            );
          }).toList();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Buchi del giorno"),
            content: Text(
              cov.gapDetails
                  .map((g) => g.lines.map((l) => "⚠ $l").join("\n"))
                  .join("\n\n"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi"),
              ),
            ],
          ),
        );
      },
      child: Container(
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
                    "• Sandra copre la fascia mattina (${fmtTimeOfDay(_engine.sandraCambioMattinaStart)}–${fmtTimeOfDay(_engine.sandraCambioMattinaEnd)})",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (sandraDecision.serveSandraPranzo &&
                  _effSandraPranzo(_selectedDay))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• Sandra copre la fascia pranzo (${fmtTimeOfDay(_engine.sandraPranzoStart)}–${fmtTimeOfDay(_engine.sandraPranzoEnd)})",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (sandraDecision.serveSandraSera &&
                  _effSandraSera(_selectedDay))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• Sandra copre la fascia sera (${fmtTimeOfDay(_engine.sandraSeraStart)}–${fmtTimeOfDay(_engine.sandraSeraEnd)})",
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
              if (inCover == SchoolCoverChoice.altro &&
                  inSupportSummary != null)
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
            if (state == DayGapVisualState.realGap ||
                coreStore.aliceCompanionStore
                    .entriesForDay(_selectedDay)
                    .isNotEmpty) ...[
              const SizedBox(height: 10),

              for (int i = 0; i < visibleGapDetails.length; i++) ...[
                Text(
                  "BUCO ${i + 1} — ${_gapTitleWithAliceState(visibleGapDetails[i].label)}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                if (visibleGapDetails[i].lines.isNotEmpty)
                  Text(
                    visibleGapDetails[i].lines.join("\n"),
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),

                ElevatedButton(
                  onPressed: () {
                    final gap = visibleGapDetails[i];

                    final nowDay = _selectedDay;

                    // parsing orari dalla label (es: 16:00–17:25)
                    final match = RegExp(
                      r'(\d{2}:\d{2})–(\d{2}:\d{2})',
                    ).firstMatch(gap.label);
                    if (match == null) return;

                    final times = [match.group(1)!, match.group(2)!];

                    TimeOfDay parse(String t) {
                      final p = t.split(":");
                      return TimeOfDay(
                        hour: int.parse(p[0]),
                        minute: int.parse(p[1]),
                      );
                    }

                    final start = parse(times[0]);
                    final end = parse(times[1]);

                    final entry = AliceCompanionEntry(
                      day: nowDay,
                      start: start,
                      end: end,
                      person: _whoCanBringAliceForGap(start: start, end: end),
                    );

                    final existing = coreStore.aliceCompanionStore
                        .entriesForDay(nowDay)
                        .any(
                          (e) =>
                              e.start.hour == start.hour &&
                              e.start.minute == start.minute &&
                              e.end.hour == end.hour &&
                              e.end.minute == end.minute,
                        );

                    if (existing) {
                      coreStore.aliceCompanionStore.removeEntry(entry);
                    } else {
                      coreStore.aliceCompanionStore.addEntry(entry);
                    }

                    setState(() {
                      // trigger rebuild
                    });
                  },
                  child: Text(
                    _companionActionTextForGap(visibleGapDetails[i].label),
                  ),
                ),

                const SizedBox(height: 6),
                if (i != cov.gapDetails.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAliceHomeRiskBox() {
    final d0 = _onlyDate(_selectedDay);
    final ov = _getOverridesForDay(d0);
    final uscitaAt = _effUscitaAnticipataAt(d0);
    final uscita13Eff = uscitaAt != null;
    final outStart = _effSchoolOutStart(d0);
    final outEnd = _effSchoolOutEnd(d0);

    final bool hasRisk = _engine.hasAliceHomeRiskForDay(
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
    final List<CoverageGapDetail> details = _engine.aliceHomeRiskDetailsForDay(
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

    final color = hasRisk ? Colors.red : Colors.green;
    final icon = hasRisk ? Icons.home_work_rounded : Icons.home_outlined;
    final title = hasRisk
        ? "⚠ Rischio automatico: Alice a casa"
        : "✓ Nessun rischio automatico Alice a casa";
    final subtitle = hasRisk
        ? "Il motore ha rilevato una situazione in cui Alice potrebbe trovarsi a casa senza adulto disponibile."
        : "Il motore non rileva situazioni di Alice a casa senza adulto disponibile.";

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Rischio Alice a casa"),
            content: Text(subtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Chiudi"),
              ),
            ],
          ),
        );
      },
      child: Container(
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
              "RISCHIO ALICE A CASA",
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
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
          ],
        ),
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

  @override
  void dispose() {
    _aliceEventNameController.dispose();
    _aliceEventNoteController.dispose();
    super.dispose();
  }

  Widget _buildSectionBox({
    required String title,
    required String subtitle,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isOpen ? 14 : 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.22)),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isOpen) child,
        ],
      ),
    );
  }

  Widget _buildRealitySection() {
    return _buildSectionBox(
      title: "REALTÀ DEL GIORNO",
      subtitle: "Turni, eventi adulti e stato reale delle persone oggi.",
      isOpen: _realitySectionOpen,
      onToggle: () {
        setState(() {
          _realitySectionOpen = !_realitySectionOpen;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(key: _turniKey, child: _cardTurni()),
          const SizedBox(height: 12),
          Container(
            key: _eventiKey,
            child: RealEventPanel(
              selectedDay: _selectedDay,
              store: coreStore.realEventStore,
              onChanged: () {
                setState(() {});
                ipsStore.refresh(now: _selectedDay);
              },
            ),
          ),
          const SizedBox(height: 12),
          FeriePeriodPanel(store: coreStore.feriePeriodStore),
          const SizedBox(height: 12),
          DiseasePeriodPanel(
            selectedDay: _selectedDay,
            store: coreStore.diseasePeriodStore,
            onChanged: () {
              setState(() {});
              ipsStore.refresh(now: _selectedDay);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAliceSection({required bool showSummerCampSpecialCard}) {
    return _buildSectionBox(
      title: "ALICE / SCUOLA",
      subtitle: "Scuola, eventi Alice e stato reale della giornata di Alice.",
      isOpen: _aliceSectionOpen,
      onToggle: () {
        setState(() {
          _aliceSectionOpen = !_aliceSectionOpen;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardScuola(),
          const SizedBox(height: 12),
          AliceEventPanel(
            selectedDay: _selectedDay,
            store: coreStore.aliceEventStore,
            summerCampSpecialEventStore: coreStore.summerCampSpecialEventStore,
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
      ),
    );
  }

  Widget _buildDecisionsSection({
    required CoverageResultStepA cov,
    required bool isEmergency,
  }) {
    return _buildSectionBox(
      title: "BUCHI / DECISIONI",
      subtitle:
          "Buchi reali, supporti e decisioni operative per coprire la giornata.",
      isOpen: _decisionsSectionOpen,
      onToggle: () {
        setState(() {
          _decisionsSectionOpen = !_decisionsSectionOpen;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEmergency) _buildDayGapsBox(cov),
          if (!isEmergency) _buildAliceHomeRiskBox(),
          isEmergency ? _buildEmergencyPanelPlaceholder() : _cardCopertura(cov),
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
    );
  }

  Widget _buildDesktopThreeColumns({
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildRealitySection()),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _buildAliceSection(
            showSummerCampSpecialCard: showSummerCampSpecialCard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: _buildDecisionsSection(cov: cov, isEmergency: isEmergency),
        ),
      ],
    );
  }

  Widget _buildTabletLayout({
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRealitySection(),
        const SizedBox(height: 12),
        _buildAliceSection(
          showSummerCampSpecialCard: showSummerCampSpecialCard,
        ),
        const SizedBox(height: 12),
        _buildDecisionsSection(cov: cov, isEmergency: isEmergency),
      ],
    );
  }

  Widget _buildMobileLayout({
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRealitySection(),
        const SizedBox(height: 12),
        _buildAliceSection(
          showSummerCampSpecialCard: showSummerCampSpecialCard,
        ),
        const SizedBox(height: 12),
        _buildDecisionsSection(cov: cov, isEmergency: isEmergency),
      ],
    );
  }

  Widget _buildMainLayout({
    required CoverageResultStepA cov,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        if (w >= 1200) {
          return _buildDesktopThreeColumns(
            cov: cov,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
          );
        }

        if (w >= 800) {
          return _buildTabletLayout(
            cov: cov,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
          );
        }

        return _buildMobileLayout(
          cov: cov,
          showSummerCampSpecialCard: showSummerCampSpecialCard,
          isEmergency: isEmergency,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 12),
            _buildMainLayout(
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
    final conflict = _turns.sameDayConflictFor(_selectedDay);
    final ov = _getOverridesForDay(_selectedDay);

    final matteoStatus = _personRealStatusText(
      personKey: 'matteo',
      manualOverride: ov.matteo,
      day: _selectedDay,
    );

    final chiaraStatus = _personRealStatusText(
      personKey: 'chiara',
      manualOverride: ov.chiara,
      day: _selectedDay,
    );

    final matteoSource = _turnSourceTextForPerson(
      personKey: 'matteo',
      day: _selectedDay,
    );

    final chiaraSource = _turnSourceTextForPerson(
      personKey: 'chiara',
      day: _selectedDay,
    );

    final matteoEvents = _eventsForPersonOnDay(
      personKey: 'matteo',
      day: _selectedDay,
    );

    final chiaraEvents = _eventsForPersonOnDay(
      personKey: 'chiara',
      day: _selectedDay,
    );

    final matteoEventConflicts = _turnEventResolutionsForPerson(
      personKey: 'matteo',
      turnPlan: m,
      manualOverride: ov.matteo,
      day: _selectedDay,
    );

    final chiaraEventConflicts = _turnEventResolutionsForPerson(
      personKey: 'chiara',
      turnPlan: c,
      manualOverride: ov.chiara,
      day: _selectedDay,
    );

    final familyEvents = _familyEventsOnDay(_selectedDay);

    return _card(
      title: "Turni",
      subtitle:
          "Orari letti dal motore reale: rotazione standard oppure Quarta Squadra se attiva.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conflict.hasConflict) ...[
            _turnConflictBox(conflict),
            const SizedBox(height: 12),
          ],
          if (matteoEventConflicts.isNotEmpty) ...[
            _turnEventConflictBox(
              personName: "Matteo",
              conflicts: matteoEventConflicts,
            ),
            const SizedBox(height: 12),
          ],
          if (chiaraEventConflicts.isNotEmpty) ...[
            _turnEventConflictBox(
              personName: "Chiara",
              conflicts: chiaraEventConflicts,
            ),
            const SizedBox(height: 12),
          ],
          if (familyEvents.isNotEmpty) ...[
            _familyEventsBlock(familyEvents),
            const SizedBox(height: 12),
          ],
          _turnRow(
            "Matteo",
            m,
            statusText: matteoStatus,
            sourceText: matteoSource,
            events: matteoEvents,
            conflicts: matteoEventConflicts,
          ),
          const SizedBox(height: 10),
          _turnRow(
            "Chiara",
            c,
            statusText: chiaraStatus,
            sourceText: chiaraSource,
            events: chiaraEvents,
            conflicts: chiaraEventConflicts,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final person = await showDialog<TurnPerson>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Chi cambia turno?"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPerson.matteo),
                        child: const Text("Matteo"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPerson.chiara),
                        child: const Text("Chiara"),
                      ),
                    ],
                  );
                },
              );

              if (person == null) return;

              final newTurn = await showDialog<TurnType>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Nuovo turno"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnType.mattina),
                        child: const Text("Mattina"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnType.pomeriggio),
                        child: const Text("Pomeriggio"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, TurnType.notte),
                        child: const Text("Notte"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, TurnType.off),
                        child: const Text("OFF"),
                      ),
                    ],
                  );
                },
              );

              if (newTurn == null) return;

              final personId = person == TurnPerson.matteo
                  ? TurnPersonId.matteo
                  : TurnPersonId.chiara;

              final shiftId = newTurn == TurnType.mattina
                  ? TurnOverrideShift.mattina
                  : newTurn == TurnType.pomeriggio
                  ? TurnOverrideShift.pomeriggio
                  : newTurn == TurnType.notte
                  ? TurnOverrideShift.notte
                  : TurnOverrideShift.off;

              turnOverrideStore.setDailyOverride(
                person: personId,
                day: _selectedDay,
                newShift: shiftId,
              );

              setState(() {});
            },
            icon: const Icon(Icons.swap_horiz),
            label: const Text("Cambio turno (solo oggi)"),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final person = await showDialog<TurnPerson>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Chi cambia turno nel periodo?"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPerson.matteo),
                        child: const Text("Matteo"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPerson.chiara),
                        child: const Text("Chiara"),
                      ),
                    ],
                  );
                },
              );

              if (person == null) return;
              final startDay = await showDatePicker(
                context: context,
                initialDate: _selectedDay,
                firstDate: DateTime(2024, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                helpText: 'Data inizio periodo',
                cancelText: 'Annulla',
                confirmText: 'OK',
                locale: const Locale('it', 'IT'),
              );

              if (startDay == null) return;

              final endDay = await showDatePicker(
                context: context,
                initialDate: startDay,
                firstDate: startDay,
                lastDate: DateTime(2035, 12, 31),
                helpText: 'Data fine periodo',
                cancelText: 'Annulla',
                confirmText: 'OK',
                locale: const Locale('it', 'IT'),
              );

              if (endDay == null) return;

              final newTurn = await showDialog<TurnType>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Nuovo turno per il periodo"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnType.mattina),
                        child: const Text("Mattina"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnType.pomeriggio),
                        child: const Text("Pomeriggio"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, TurnType.notte),
                        child: const Text("Notte"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, TurnType.off),
                        child: const Text("OFF"),
                      ),
                    ],
                  );
                },
              );

              if (newTurn == null) return;

              final personId = person == TurnPerson.matteo
                  ? TurnPersonId.matteo
                  : TurnPersonId.chiara;

              final shiftId = newTurn == TurnType.mattina
                  ? TurnOverrideShift.mattina
                  : newTurn == TurnType.pomeriggio
                  ? TurnOverrideShift.pomeriggio
                  : newTurn == TurnType.notte
                  ? TurnOverrideShift.notte
                  : TurnOverrideShift.off;

              turnOverrideStore.setPeriodOverride(
                person: personId,
                startDay: startDay,
                endDay: endDay,
                newShift: shiftId,
              );

              setState(() {});
            },
            icon: const Icon(Icons.date_range),
            label: const Text("Cambio turno (periodo)"),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _showNuovaRotazioneDialog,
            icon: const Icon(Icons.autorenew),
            label: const Text("Nuova rotazione"),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FourthShiftPanel(
                        store: coreStore.fourthShiftStore,
                        onChanged: () {
                          setState(() {});
                          ipsStore.refresh(now: _selectedDay);
                        },
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.repeat),
            label: const Text("Quarta squadra"),
          ),

          const SizedBox(height: 8),

          _cardOverrideStepB(_getOverridesForDay(_selectedDay)),

          OutlinedButton.icon(
            onPressed: () async {
              final person = await showDialog<TurnPersonId>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Quale nuova rotazione vuoi rimuovere?"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPersonId.matteo),
                        child: const Text("Matteo"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, TurnPersonId.chiara),
                        child: const Text("Chiara"),
                      ),
                    ],
                  );
                },
              );

              if (person == null) return;

              final removed = coreStore.rotationOverrideStore.removeActiveFor(
                person: person,
                day: _selectedDay,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    removed
                        ? "Nuova rotazione rimossa con successo."
                        : "Nessuna nuova rotazione attiva da rimuovere.",
                  ),
                ),
              );

              setState(() {});
            },
            icon: const Icon(Icons.restore),
            label: const Text("Rimuovi nuova rotazione attiva"),
          ),

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

  Widget _turnConflictBox(TurnConflictInfo conflict) {
    String detail;

    switch (conflict.conflictCode) {
      case 'mattina_mattina':
        detail = "Mattina + mattina";
        break;
      case 'pomeriggio_pomeriggio':
        detail = "Pomeriggio + pomeriggio";
        break;
      case 'notte_notte':
        detail = "Notte + notte";
        break;
      default:
        detail = "Conflitto turni";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Conflitto turni rilevato",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            "Matteo e Chiara hanno lo stesso tipo di turno nello stesso giorno.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnEventConflictBox({
    required String personName,
    required List<TurnEventConflictResolution> conflicts,
  }) {
    final worst = _worstConflictState(conflicts);
    final color = conflictStateColor(worst);

    final String title;
    final String subtitle;

    switch (worst) {
      case TurnEventConflictState.open:
        title = "Conflitto turno / evento — $personName";
        subtitle = "Serve una decisione operativa.";
        break;
      case TurnEventConflictState.partial:
        title = "Conflitto turno / evento — $personName";
        subtitle = "Esiste una copertura parziale.";
        break;
      case TurnEventConflictState.resolved:
        title = "Conflitto turno / evento — $personName";
        subtitle = "Conflitto risolto da una decisione valida.";
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _showTurnEventConflictActionsSheet(
          personName: personName,
          conflicts: conflicts,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.black.withOpacity(0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...conflicts.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        realEventText(r.event),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Stato: ${conflictStateLabel(r.state)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: conflictStateColor(r.state),
                        ),
                      ),
                      if (r.detailText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.detailText!,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.72),
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tocca per vedere le azioni possibili.",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnRow(
    String name,
    TurnPlan p, {
    String? statusText,
    String? sourceText,
    List<RealEvent> events = const [],
    List<TurnEventConflictResolution> conflicts = const [],
  }) {
    final label = _turnLabel(p.type);
    final time = p.isOff
        ? "OFF"
        : "${fmtTimeOfDay(p.start)}–${fmtTimeOfDay(p.end)}";

    final isMalattiaALetto =
        statusText != null &&
        statusText.toLowerCase().contains('malattia a letto');

    final isTurnChanged =
        statusText != null &&
        statusText.toLowerCase().contains('turno cambiato manualmente');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    "$label • $time",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (statusText != null && statusText.isNotEmpty)
                    Text(
                      "• Stato: $statusText",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isMalattiaALetto
                            ? Colors.red
                            : isTurnChanged
                            ? Colors.deepPurple
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (sourceText != null && sourceText.isNotEmpty)
                    Text(
                      "• $sourceText",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _turnSourceColor(sourceText),
                      ),
                    ),
                ],
              ),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 6),
                _eventPill(
                  text: realEventText(events.first),
                  onTap: () => showExtraEventsDialog(
                    context: context,
                    personName: name,
                    events: events,
                  ),
                ),
                if (events.length > 1) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => showExtraEventsDialog(
                        context: context,
                        personName: name,
                        events: events,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "+${events.length - 1} altri eventi",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (conflicts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "⚠ Conflitto con turno",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _familyEventsBlock(List<RealEvent> events) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Evento generale / famiglia",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _eventPill(
            text: realEventText(events.first),
            onTap: () => showExtraEventsDialog(
              context: context,
              personName: "Famiglia",
              events: events,
            ),
          ),
          if (events.length > 1) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => showExtraEventsDialog(
                  context: context,
                  personName: "Famiglia",
                  events: events,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    "+${events.length - 1} altri eventi",
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _eventPill({required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event, size: 15, color: Colors.blueGrey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _turnLabel(TurnType t) {
    switch (t) {
      case TurnType.mattina:
        return "M";
      case TurnType.pomeriggio:
        return "P";
      case TurnType.notte:
        return "N";
      case TurnType.off:
        return "OFF";
    }
  }

  Widget _cardOverrideStepB(DayOverrides ovSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔘 SOLO BOTTONE (stile Quarta squadra)
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _permessoPanelOpen = !_permessoPanelOpen;
            });
          },
          icon: Icon(
            _permessoPanelOpen
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
          ),
          label: Text(_permessoPanelOpen ? "Chiudi permessi" : "Apri permessi"),
        ),

        /// 📦 CONTENUTO (solo se aperto)
        if (_permessoPanelOpen) ...[
          const SizedBox(height: 12),

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
        ],
      ],
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
              "Orario: ${fmtTimeOfDay(current.start)}–${fmtTimeOfDay(current.end)}",
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

  List<AliceSpecialEvent> _sortedAliceSpecialEventsForSelectedDay() {
    final events = [
      ...coreStore.aliceSpecialEventStore.eventsForDay(_selectedDay),
    ];

    events.sort((a, b) {
      final aMin = a.start.hour * 60 + a.start.minute;
      final bMin = b.start.hour * 60 + b.start.minute;
      return aMin.compareTo(bMin);
    });

    return events;
  }

  String _aliceSpecialCategoryLabel(AliceSpecialEventCategory category) {
    switch (category) {
      case AliceSpecialEventCategory.school:
        return "Scuola";
      case AliceSpecialEventCategory.sport:
        return "Sport";
      case AliceSpecialEventCategory.health:
        return "Salute";
      case AliceSpecialEventCategory.activity:
        return "Attività";
      case AliceSpecialEventCategory.other:
        return "Altro";
    }
  }

  IconData _aliceSpecialCategoryIcon(AliceSpecialEventCategory category) {
    switch (category) {
      case AliceSpecialEventCategory.school:
        return Icons.school_outlined;
      case AliceSpecialEventCategory.sport:
        return Icons.sports_volleyball_outlined;
      case AliceSpecialEventCategory.health:
        return Icons.medical_information_outlined;
      case AliceSpecialEventCategory.activity:
        return Icons.event_outlined;
      case AliceSpecialEventCategory.other:
        return Icons.label_outline;
    }
  }

  void _resetAliceSpecialEventEditor({bool closeEditor = true}) {
    _aliceEventNameController.clear();
    _aliceEventNoteController.clear();
    _aliceEventStart = const TimeOfDay(hour: 18, minute: 0);
    _aliceEventEnd = const TimeOfDay(hour: 20, minute: 0);
    _aliceEventCategory = AliceSpecialEventCategory.activity;
    _editingAliceSpecialEventId = null;
    if (closeEditor) {
      _showAliceEventEditor = false;
    }
  }

  void _openNewAliceSpecialEventEditor() {
    setState(() {
      _resetAliceSpecialEventEditor(closeEditor: false);
      _showAliceEventEditor = true;
    });
  }

  void _startEditAliceSpecialEvent(AliceSpecialEvent event) {
    setState(() {
      _editingAliceSpecialEventId = event.id;
      _aliceEventNameController.text = event.label;
      _aliceEventNoteController.text = event.note;
      _aliceEventStart = event.start;
      _aliceEventEnd = event.end;
      _aliceEventCategory = event.category;
      _showAliceEventEditor = true;
    });
  }

  void _cancelAliceSpecialEventEditor() {
    setState(() {
      _resetAliceSpecialEventEditor(closeEditor: true);
    });
  }

  Future<void> _pickAliceSpecialEventStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _aliceEventStart,
      helpText: "Evento Alice • ORA INIZIO",
      cancelText: "Annulla",
      confirmText: "OK",
    );

    if (picked == null) return;

    final pickedMin = picked.hour * 60 + picked.minute;
    final currentEndMin = _aliceEventEnd.hour * 60 + _aliceEventEnd.minute;

    setState(() {
      _aliceEventStart = picked;
      if (pickedMin >= currentEndMin) {
        final nextHour = picked.hour < 23 ? picked.hour + 1 : picked.hour;
        _aliceEventEnd = TimeOfDay(hour: nextHour, minute: picked.minute);
      }
    });
  }

  Future<void> _pickAliceSpecialEventEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _aliceEventEnd,
      helpText: "Evento Alice • ORA FINE",
      cancelText: "Annulla",
      confirmText: "OK",
    );

    if (picked == null) return;

    final startMin = _aliceEventStart.hour * 60 + _aliceEventStart.minute;
    final endMin = picked.hour * 60 + picked.minute;

    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "L'orario di fine deve essere dopo l'orario di inizio.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _aliceEventEnd = picked;
    });
  }

  void _saveAliceSpecialEvent() {
    final label = _aliceEventNameController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Scrivi il nome dell'evento Alice.")),
      );
      return;
    }

    final startMin = _aliceEventStart.hour * 60 + _aliceEventStart.minute;
    final endMin = _aliceEventEnd.hour * 60 + _aliceEventEnd.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "L'orario di fine deve essere dopo l'orario di inizio.",
          ),
        ),
      );
      return;
    }

    final day = _onlyDate(_selectedDay);
    final store = coreStore.aliceSpecialEventStore;
    final events = [...store.eventsForDay(day)];

    final newEvent = AliceSpecialEvent(
      id:
          _editingAliceSpecialEventId ??
          'evt_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      category: _aliceEventCategory,
      date: day,
      start: _aliceEventStart,
      end: _aliceEventEnd,
      note: _aliceEventNoteController.text.trim(),
      enabled: true,
    );

    if (_editingAliceSpecialEventId != null) {
      final index = events.indexWhere(
        (e) => e.id == _editingAliceSpecialEventId,
      );
      if (index != -1) {
        events[index] = newEvent;
      } else {
        events.add(newEvent);
      }
    } else {
      events.add(newEvent);
    }

    events.sort((a, b) {
      final aMin = a.start.hour * 60 + a.start.minute;
      final bMin = b.start.hour * 60 + b.start.minute;
      return aMin.compareTo(bMin);
    });

    store.replaceEventsForDay(day, events);

    setState(() {
      _resetAliceSpecialEventEditor(closeEditor: true);
    });

    ipsStore.refresh(now: _selectedDay);
  }

  void _removeAliceSpecialEvent(AliceSpecialEvent event) {
    coreStore.aliceSpecialEventStore.removeEvent(_selectedDay, event.id);

    setState(() {
      if (_editingAliceSpecialEventId == event.id) {
        _resetAliceSpecialEventEditor(closeEditor: true);
      }
    });

    ipsStore.refresh(now: _selectedDay);
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

    final aliceEvent = coreStore.aliceEventStore.getEventForDay(_selectedDay);

    final extraEvents = _sortedAliceSpecialEventsForSelectedDay();
    final bool hasExtraEvents = extraEvents.isNotEmpty;

    String aliceEventLabel() {
      final specialCamp = coreStore.summerCampSpecialEventStore.getForDay(
        _selectedDay,
      );

      if (specialCamp != null && specialCamp.enabled) {
        return specialCamp.label;
      }

      if (extraEvents.isNotEmpty) {
        return extraEvents.first.label;
      }

      if (aliceEvent == null) return "Scuola normale";

      switch (aliceEvent.type) {
        case AliceEventType.schoolNormal:
          return "Scuola normale";
        case AliceEventType.vacation:
          return "Vacanza";
        case AliceEventType.schoolClosure:
          return "Scuola chiusa";
        case AliceEventType.sickness:
          return "Malattia";
        case AliceEventType.summerCamp:
          return "Centro estivo";
      }
    }

    Color aliceEventColor() {
      if (aliceEvent == null) return Colors.grey;

      switch (aliceEvent.type) {
        case AliceEventType.schoolNormal:
          return Colors.grey;
        case AliceEventType.vacation:
          return Colors.teal;
        case AliceEventType.schoolClosure:
          return Colors.orange;
        case AliceEventType.sickness:
          return Colors.red;
        case AliceEventType.summerCamp:
          return Colors.green;
      }
    }

    IconData aliceEventIcon() {
      if (aliceEvent == null) return Icons.school_outlined;

      switch (aliceEvent.type) {
        case AliceEventType.schoolNormal:
          return Icons.menu_book_rounded;
        case AliceEventType.vacation:
          return Icons.beach_access_outlined;
        case AliceEventType.schoolClosure:
          return Icons.event_busy_outlined;
        case AliceEventType.sickness:
          return Icons.sick_outlined;
        case AliceEventType.summerCamp:
          return Icons.park_outlined;
      }
    }

    return _card(
      title: "Alice / Scuola",
      subtitle: "Orari scuola + uscita anticipata rapida (con orario).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: aliceEventColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: aliceEventColor().withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(aliceEventIcon(), size: 18, color: aliceEventColor()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Stato Alice: ${aliceEventLabel()}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: aliceEventColor().withOpacity(1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Text(
            "Orario: ${fmtTimeOfDay(coreStore.summerCampSpecialEventStore.getForDay(_selectedDay)?.start ?? (extraEvents.isNotEmpty ? extraEvents.first.start : (aliceEvent?.summerCampStart ?? _scuolaStart)))}–${fmtTimeOfDay(coreStore.summerCampSpecialEventStore.getForDay(_selectedDay)?.end ?? (extraEvents.isNotEmpty ? extraEvents.first.end : (aliceEvent?.summerCampEnd ?? _scuolaEnd)))}",
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Eventi Alice del giorno",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  hasExtraEvents
                      ? "Eventi salvati: ${extraEvents.length}"
                      : "Nessun evento Alice salvato per questo giorno.",
                  style: TextStyle(color: Colors.black.withOpacity(0.68)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openNewAliceSpecialEventEditor,
                        icon: const Icon(Icons.add),
                        label: const Text("Nuovo evento Alice"),
                      ),
                    ),
                  ],
                ),
                if (hasExtraEvents) ...[
                  const SizedBox(height: 12),
                  ...extraEvents.map(
                    (e) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _aliceSpecialCategoryIcon(e.category),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Categoria: ${_aliceSpecialCategoryLabel(e.category)}",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.72),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Orario: ${fmtTimeOfDay(e.start)}–${fmtTimeOfDay(e.end)}",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (e.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Nota: ${e.note}",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.72),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _startEditAliceSpecialEvent(e),
                                  icon: const Icon(Icons.edit),
                                  label: const Text("Modifica"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _removeAliceSpecialEvent(e),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text("Rimuovi"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_showAliceEventEditor) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingAliceSpecialEventId == null
                        ? "Nuovo evento Alice"
                        : "Modifica evento Alice",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aliceEventNameController,
                    decoration: const InputDecoration(
                      labelText: "Nome evento",
                      hintText: "Es. Pallavolo / Musica / Dentista",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AliceSpecialEventCategory>(
                    value: _aliceEventCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Categoria",
                      border: OutlineInputBorder(),
                    ),
                    items: AliceSpecialEventCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(_aliceSpecialCategoryIcon(c), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_aliceSpecialCategoryLabel(c)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _aliceEventCategory = v;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAliceSpecialEventStart,
                          icon: const Icon(Icons.login),
                          label: Text(
                            "Inizio: ${fmtTimeOfDay(_aliceEventStart)}",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAliceSpecialEventEnd,
                          icon: const Icon(Icons.logout),
                          label: Text("Fine: ${fmtTimeOfDay(_aliceEventEnd)}"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aliceEventNoteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Note",
                      hintText: "Nota facoltativa",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveAliceSpecialEvent,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _editingAliceSpecialEventId == null
                                ? "Salva evento"
                                : "Salva modifica",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelAliceSpecialEventEditor,
                          icon: const Icon(Icons.close),
                          label: const Text("Annulla"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              uscita13Eff
                  ? "Uscita anticipata: ${fmtTimeOfDay(uscitaAt!)}"
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
                    "Uscita: ${fmtTimeOfDay(outStart)}–${fmtTimeOfDay(outEnd)}${hasCustomOut ? " (personalizzata)" : ""}",
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
            value: _effectiveSchoolInCover(_selectedDay),
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Ingresso 07:30–${fmtTimeOfDay(_scuolaStart)}",
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
              value: _effectiveSchoolOutCover(_selectedDay),
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    "Uscita ${fmtTimeOfDay(outStart)}–${fmtTimeOfDay(outEnd)}",
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
              value: _effectiveLunchCover(_selectedDay),
              isExpanded: true,
              decoration: InputDecoration(
                labelText:
                    "Pranzo ${fmtTimeOfDay(uscitaAt!)}–${fmtTimeOfDay(_engine.sandraPranzoEnd)}",
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
    final sandraDecision = _sandraDecisionForDay(_selectedDay);

    final manualMattina = _effSandraMattina(_selectedDay);
    final manualPranzo = _effSandraPranzo(_selectedDay);
    final manualSera = _effSandraSera(_selectedDay);

    return _card(
      title: "Copertura Sandra / Babysitter",
      subtitle: "Fasce rapide con modifica orario e attivazione manuale.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sandraCompactRow(
            title: "Mattina",
            start: _engine.sandraCambioMattinaStart,
            end: _engine.sandraCambioMattinaEnd,
            serve: sandraDecision.serveSandraMattina,
            manual: manualMattina,
            onEdit: () {
              _editSandraWindow(
                title: "Cambio turno mattina",
                currentStart: _engine.sandraCambioMattinaStart,
                currentEnd: _engine.sandraCambioMattinaEnd,
                onSave: (s, e) => _engine.setSandraCambioMattina(s, e),
              );
            },
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraMattinaForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const SizedBox(height: 8),
          _sandraCompactRow(
            title: "Pranzo",
            start: _engine.sandraPranzoStart,
            end: _engine.sandraPranzoEnd,
            serve: sandraDecision.serveSandraPranzo,
            manual: manualPranzo,
            onEdit: () {
              _editSandraWindow(
                title: "Pranzo",
                currentStart: _engine.sandraPranzoStart,
                currentEnd: _engine.sandraPranzoEnd,
                onSave: (s, e) => _engine.setSandraPranzo(s, e),
              );
            },
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraPranzoForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
          ),
          const SizedBox(height: 8),
          _sandraCompactRow(
            title: "Sera",
            start: _engine.sandraSeraStart,
            end: _engine.sandraSeraEnd,
            serve: sandraDecision.serveSandraSera,
            manual: manualSera,
            onEdit: () {
              _editSandraWindow(
                title: "Sera",
                currentStart: _engine.sandraSeraStart,
                currentEnd: _engine.sandraSeraEnd,
                onSave: (s, e) => _engine.setSandraSera(s, e),
              );
            },
            onChanged: (v) {
              setState(
                () => daySettingsStore.setSandraSeraForDay(_selectedDay, v),
              );
              ipsStore.refresh(now: _selectedDay);
            },
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

  Widget _sandraCompactRow({
    required String title,
    required TimeOfDay start,
    required TimeOfDay end,
    required bool serve,
    required bool manual,
    required VoidCallback onEdit,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "$title   ${fmtTimeOfDay(start)}–${fmtTimeOfDay(end)}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: "Modifica fascia",
                onPressed: onEdit,
              ),
              Switch(value: manual, onChanged: onChanged),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 2),
            child: _sandraNeedText(serve: serve, manual: manual),
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
            "$title\n${fmtTimeOfDay(start)}–${fmtTimeOfDay(end)}",
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

  void _showExtraEventsDialog({
    required String personName,
    required List<RealEvent> events,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eventi $personName"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: events.map((e) {
                  String time = "";

                  if (e.startTime != null && e.endTime != null) {
                    time =
                        "${fmtTimeOfDay(e.startTime!)}–${fmtTimeOfDay(e.endTime!)}";
                  } else if (e.startTime != null) {
                    time = fmtTimeOfDay(e.startTime!);
                  } else {
                    time = "Tutto il giorno";
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text("${e.title} • $time")),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Chiudi"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
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

enum TurnEventConflictState { open, partial, resolved }

class TurnEventConflictResolution {
  final RealEvent event;
  final TurnEventConflictState state;
  final _DateRange overlapRange;
  final String? detailText;

  const TurnEventConflictResolution({
    required this.event,
    required this.state,
    required this.overlapRange,
    this.detailText,
  });
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
