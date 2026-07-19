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
import '../models/school_model.dart';
import '../logic/core_store.dart';

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
import '../logic/calendar/view_models/sandra_coverage_view_model.dart';

// ✅ NEW: Eventi speciali centro estivo
import '../logic/summer_camp_special_event_store.dart';

import '../utils/calendario_formatters.dart';
import '../utils/status_visual.dart';

import '../logic/promemoria_store.dart';
import '../models/promemoria.dart';
import '../logic/alice_events/alice_event_behavior_text.dart';
import '../logic/alice_events/alice_event_behavior.dart';
import '../logic/alice_events/alice_event_engine.dart';
import '../logic/calendar/models/family_now_snapshot.dart';
import '../logic/calendar/models/coverage_result_step_a.dart';
import '../logic/calendar/models/day_gap_visual_state.dart';

import '../logic/calendar/models/turn_event_conflict.dart';

import '../widgets/calendar/sandra_coverage_card.dart';
import '../widgets/calendar/alice_state_banner.dart';
import '../widgets/calendar/alice_events_section.dart';
import '../widgets/calendar/alice_event_conflict_banner.dart';
import '../widgets/calendar/alice_school_header.dart';
import '../widgets/calendar/school_status_box.dart';
import '../widgets/calendar/day_organization_section.dart';
import '../widgets/calendar/school_out_summary.dart';
import '../widgets/calendar/school_coverage_choice_section.dart';
import '../widgets/calendar/alice_events_header.dart';
import '../widgets/calendar/hidden_alice_events_link.dart';
import '../widgets/calendar/alice_events_list.dart';
import '../widgets/calendar/alice_event_tile.dart';
import '../widgets/calendar/alice_event_expanded.dart';
import '../logic/calendar/builders/alice_event_tile_view_model_builder.dart';
import '../logic/calendar/builders/alice_event_conflict_builder.dart';
import '../logic/calendar/view_models/alice_event_tile_view_model.dart';
import '../logic/calendar/builders/family_now_view_model_builder.dart';
import '../widgets/calendar/family_now_card.dart';
import '../logic/calendar/builders/family_adult_now_details_builder.dart';
import '../widgets/calendar/family_adult_now_dialog.dart';
import '../logic/calendar/builders/alice_day_context_builder.dart';
import '../logic/calendar/builders/alice_now_details_builder.dart';
import '../widgets/calendar/alice_now_dialog.dart';
import '../logic/calendar/builders/turn_day_builder.dart';
import '../logic/calendar/builders/turn_person_source_builder.dart';
import '../logic/calendar/builders/coverage_gap_filter.dart';
import '../logic/calendar/builders/coverage_summary_builder.dart';
import '../logic/calendar/builders/coverage_support_network_builder.dart';
import '../logic/calendar/builders/alice_logistics_status_builder.dart';
import '../logic/calendar/builders/alice_event_logistics_builder.dart';
import '../logic/calendar/builders/day_gap_visual_state_builder.dart';

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
  PromemoriaStore get _promemoriaStore => coreStore.promemoriaStore;
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
  bool _turnManagementOpen = false;
  bool _showAliceEventEditor = false;
  bool _showAlicePeriodPanel = false;

  final Set<String> _expandedAliceEventIds = <String>{};

  final AliceEventEngine _aliceEventEngine = const AliceEventEngine();

  final TurnPersonSourceBuilder _turnPersonSourceBuilder =
      const TurnPersonSourceBuilder();

  final CoverageGapFilter _coverageGapFilter = const CoverageGapFilter();

  final CoverageSummaryBuilder _coverageSummaryBuilder =
      const CoverageSummaryBuilder();

  final CoverageSupportNetworkBuilder _coverageSupportNetworkBuilder =
      const CoverageSupportNetworkBuilder();

  final AliceLogisticsStatusBuilder _aliceLogisticsStatusBuilder =
      const AliceLogisticsStatusBuilder();

  final AliceEventLogisticsBuilder _aliceEventLogisticsBuilder =
      const AliceEventLogisticsBuilder();

  final DayGapVisualStateBuilder _dayGapVisualStateBuilder =
      const DayGapVisualStateBuilder();

  final TextEditingController _aliceEventNameController =
      TextEditingController();
  final TextEditingController _aliceEventNoteController =
      TextEditingController();

  TimeOfDay _aliceEventStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _aliceEventEnd = const TimeOfDay(hour: 20, minute: 0);
  AliceSpecialEventCategory _aliceEventCategory =
      AliceSpecialEventCategory.activity;

  AliceEventBehavior _aliceEventBehavior = AliceEventBehavior.logistic;

  String? _aliceEventAccompanyingAdultKey;
  String? _aliceEventDropOffAdultKey;
  String? _aliceEventPickUpAdultKey;

  String? _editingAliceSpecialEventId;

  DateTime _aliceEventDate = DateTime.now();

  void _addMockPromemoria({
    required String persona,
    required String testo,
  }) async {
    await _promemoriaStore.add(
      persona: persona,
      testo: testo,
      day: _selectedDay,
    );

    await _promemoriaStore.load();

    setState(() {});
  }

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
  static const TimeOfDay _schoolOutDefaultEnd = TimeOfDay(hour: 16, minute: 45);

  TimeOfDay _effSchoolOutStart(DateTime day) {
    final custom = daySettingsStore.schoolOutStartForDay(day);
    if (custom != null) return custom;

    final d0 = _onlyDate(day);
    final cfg = coreStore.schoolStore
        .activePeriodForDay(d0)
        ?.weekConfig
        .forWeekday(d0.weekday);

    if (cfg == null || !cfg.enabled) {
      return _schoolOutDefaultStart;
    }

    return TimeOfDay(
      hour: cfg.exitRealMinutes ~/ 60,
      minute: cfg.exitRealMinutes % 60,
    );
  }

  TimeOfDay _effSchoolOutEnd(DateTime day) {
    final custom = daySettingsStore.schoolOutEndForDay(day);
    if (custom != null) return custom;

    final d0 = _onlyDate(day);
    final cfg = coreStore.schoolStore
        .activePeriodForDay(d0)
        ?.weekConfig
        .forWeekday(d0.weekday);

    if (cfg == null || !cfg.enabled) {
      return _schoolOutDefaultEnd;
    }

    final returnMinutes = cfg.returnHomeMinutes;

    return TimeOfDay(hour: returnMinutes ~/ 60, minute: returnMinutes % 60);
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
    return _coverageSupportNetworkBuilder.coversRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: day,
      start: start,
      end: end,
    );
  }

  SchoolCoverChoice _effectiveSchoolInCover(DateTime day) {
    final saved = daySettingsStore.schoolInCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;

    final ingressoReale =
        coreStore.aliceEventStore.getEventForDay(day)?.summerCampStart ??
        TimeOfDay(
          hour:
              (coreStore.schoolStore
                      .activePeriodForDay(_onlyDate(day))
                      ?.weekConfig
                      .forWeekday(_onlyDate(day).weekday)
                      .entryMinutes ??
                  (_scuolaStart.hour * 60 + _scuolaStart.minute)) ~/
              60,
          minute:
              (coreStore.schoolStore
                      .activePeriodForDay(_onlyDate(day))
                      ?.weekConfig
                      .forWeekday(_onlyDate(day).weekday)
                      .entryMinutes ??
                  (_scuolaStart.hour * 60 + _scuolaStart.minute)) %
              60,
        );

    final ingressoInizio = TimeOfDay(
      hour: ((ingressoReale.hour * 60 + ingressoReale.minute - 20) ~/ 60) % 24,
      minute: (ingressoReale.hour * 60 + ingressoReale.minute - 20) % 60,
    );

    final coveredBySupport = _supportNetworkCoversRange(
      day: day,
      start: ingressoInizio,
      end: ingressoReale,
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

    // 👉 PRIORITÀ: scelta utente
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

  TimeOfDay _effectiveSandraPranzoStart(DateTime day) {
    final uscitaAt = _effUscitaAnticipataAt(day);
    if (uscitaAt == null) return _engine.sandraPranzoStart;

    final lunchCover = _effectiveLunchCover(day);

    TimeOfDay? firstBusyStartWithinLunch(TimeOfDay from, List<WorkShift> busy) {
      final fromMinutes = from.hour * 60 + from.minute;
      final pranzoEndMinutes =
          _engine.sandraPranzoEnd.hour * 60 + _engine.sandraPranzoEnd.minute;

      for (final shift in busy) {
        final startMinutes = shift.start.hour * 60 + shift.start.minute;

        if (startMinutes >= fromMinutes && startMinutes < pranzoEndMinutes) {
          return TimeOfDay(hour: shift.start.hour, minute: shift.start.minute);
        }
      }

      return null;
    }

    if (lunchCover == SchoolCoverChoice.matteo) {
      final matteoBusy = _turns.busyShiftsForPerson(
        person: TurnPerson.matteo,
        day: day,
      );

      return firstBusyStartWithinLunch(uscitaAt, matteoBusy) ??
          _engine.sandraPranzoEnd;
    }

    if (lunchCover == SchoolCoverChoice.chiara) {
      final chiaraBusy = _turns.busyShiftsForPerson(
        person: TurnPerson.chiara,
        day: day,
      );

      return firstBusyStartWithinLunch(uscitaAt, chiaraBusy) ??
          _engine.sandraPranzoEnd;
    }

    return uscitaAt;
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

  bool _isForcedConflict({
    required String personKey,
    required List<TurnEventConflictResolution> conflicts,
  }) {
    final eventIds = conflicts.map((c) => c.event.id).toList();

    return overrideStore.isForcedConflictForDay(
      day: _selectedDay,
      personKey: personKey,
      eventIds: eventIds,
    );
  }

  void _setForcedConflict({
    required String personKey,
    required List<TurnEventConflictResolution> conflicts,
    required bool forced,
  }) {
    final eventIds = conflicts.map((c) => c.event.id).toList();

    overrideStore.setForcedConflictForDay(
      day: _selectedDay,
      personKey: personKey,
      eventIds: eventIds,
      forced: forced,
    );

    setState(() {});
    ipsStore.refresh(now: _selectedDay);
  }

  bool _isBedSickForPerson({
    required String personKey,
    required PersonDayOverride? manualOverride,
    required DateTime day,
  }) {
    final disease = coreStore.diseasePeriodStore.getPeriodForDay(
      personKey,
      day,
    );

    return manualOverride?.status == OverrideStatus.malattiaALetto ||
        disease?.type == DiseaseType.bed;
  }

  void _showTurnEventConflictActionsSheet({
    required String personName,
    required String personKey,
    required List<TurnEventConflictResolution> conflicts,
  }) {
    final override = overrideStore.getForDay(_selectedDay);

    final personOverride = personKey == "matteo"
        ? override.matteo
        : override.chiara;

    final isBedSick = _isBedSickForPerson(
      personKey: personKey,
      manualOverride: personOverride,
      day: _selectedDay,
    );

    final hasTurnContext = conflicts.any((c) => c.hasTurnContext);
    final isForced = _isForcedConflict(
      personKey: personKey,
      conflicts: conflicts,
    );

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
                  hasTurnContext
                      ? "Il sistema ha rilevato un conflitto reale tra turno ed evento. Qui sotto vedi le strade possibili da valutare."
                      : "Il sistema ha rilevato un conflitto reale tra stato reale bloccante ed evento. Qui sotto vedi le strade possibili da valutare.",
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
                      "• ${realEventText(r.event)} — ${isForced ? "Uscita imprescindibile" : conflictStateLabel(r.state)}${r.detailText == null ? "" : "\n${r.detailText}"}",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (hasTurnContext)
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
                if (hasTurnContext)
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
                if (isBedSick)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isForced
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                    ),
                    title: Text(
                      isForced
                          ? "Togli uscita imprescindibile"
                          : "Uscita imprescindibile",
                    ),
                    subtitle: Text(
                      isForced
                          ? "Rimuove la deroga forzata e riporta il conflitto come problema reale."
                          : "Da usare solo se l’evento è davvero imprescindibile e devi uscire comunque nonostante la malattia a letto.",
                    ),
                    onTap: () {
                      _setForcedConflict(
                        personKey: personKey,
                        conflicts: conflicts,
                        forced: !isForced,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_calendar),
                  title: const Text("Sposta evento"),
                  subtitle: const Text(
                    "Da usare se l’appuntamento è modificabile e conviene spostarlo.",
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

  TimeOfDay get _scuolaStart {
    final d0 = _onlyDate(_selectedDay);
    final cfg = coreStore.schoolStore
        .activePeriodForDay(d0)
        ?.weekConfig
        .forWeekday(d0.weekday);

    if (cfg == null || !cfg.enabled) {
      return const TimeOfDay(hour: 8, minute: 25);
    }

    return TimeOfDay(
      hour: cfg.entryMinutes ~/ 60,
      minute: cfg.entryMinutes % 60,
    );
  }

  TimeOfDay get _scuolaEnd {
    final d0 = _onlyDate(_selectedDay);
    final cfg = coreStore.schoolStore
        .activePeriodForDay(d0)
        ?.weekConfig
        .forWeekday(d0.weekday);

    if (cfg == null || !cfg.enabled) {
      return const TimeOfDay(hour: 17, minute: 15);
    }

    final returnMinutes = cfg.returnHomeMinutes;

    return TimeOfDay(hour: returnMinutes ~/ 60, minute: returnMinutes % 60);
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _gapTitleWithAliceState(String label) {
    final lower = label.toLowerCase();

    if (lower.startsWith('alice pranzo:') ||
        lower.startsWith('alice ingresso:') ||
        lower.startsWith('alice uscita:') ||
        lower.startsWith('alice centro estivo ingresso:') ||
        lower.startsWith('alice centro estivo uscita:')) {
      return label;
    }

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

  String _companionActionTextForGap(CoverageGapDetail gap) {
    final match = RegExp(r'(\d{2}:\d{2})–(\d{2}:\d{2})').firstMatch(gap.label);
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

    final who = person == AliceCompanionPerson.matteo
        ? "Matteo"
        : person == AliceCompanionPerson.chiara
        ? "Chiara"
        : "Nessuno";

    return existing ? "Togli Alice da $who" : "Porta Alice con $who";
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

    final analysis = _engine.analyzeDay(
      day: d0,
      uscita13: uscita13Eff,
      sandraAvailable:
          _effSandraMattina(d0) || _effSandraPranzo(d0) || _effSandraSera(d0),
      overrides: ov,
      ferieStore: coreStore.feriePeriodStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: outStart,
      schoolOutEnd: outEnd,
      lunchCover: lunchCover,
      uscitaAnticipataAt: uscitaAt,
    );

    final filteredGapDetails = _coverageGapFilter.filter(
      details: analysis.details,
      selectedDay: d0,
      now: DateTime.now(),
      uscitaAnticipataActive: uscita13Eff,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      lunchCover: lunchCover,
    );

    final gaps = filteredGapDetails.map((d) => d.label).toList();
    final ok = gaps.isEmpty;

    final summary = _coverageSummaryBuilder.build(
      serveSandraMattina: sandraDecision.serveSandraMattina,
      serveSandraPranzo: sandraDecision.serveSandraPranzo,
      serveSandraSera: sandraDecision.serveSandraSera,
      coverageOk: ok,
      gaps: gaps,
    );

    return CoverageResultStepA(
      ok: ok,
      details: summary.details,
      gapDetails: filteredGapDetails,
      bannerText: summary.bannerText,
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

    final ov = _getOverridesForDay(day);

    final matteoDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'matteo',
      _onlyDate(day),
    );

    final chiaraDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'chiara',
      _onlyDate(day),
    );

    final matteoSick =
        ov.matteo?.status == OverrideStatus.malattiaLeggera ||
        ov.matteo?.status == OverrideStatus.malattiaALetto ||
        matteoDisease != null;

    final chiaraSick =
        ov.chiara?.status == OverrideStatus.malattiaLeggera ||
        ov.chiara?.status == OverrideStatus.malattiaALetto ||
        chiaraDisease != null;

    if (matteoSick) matteoBusy = false;
    if (chiaraSick) chiaraBusy = false;

    final matteoPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: day,
    );
    if (!matteoPlan.isOff) {
      final workStart = toDT(matteoPlan.start);
      final workEnd = toDT(matteoPlan.end);
      matteoBusy = matteoBusy || overlaps(workStart, workEnd, gapStart, gapEnd);
    }

    final chiaraPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.chiara,
      day: day,
    );
    if (!chiaraPlan.isOff) {
      final workStart = toDT(chiaraPlan.start);
      final workEnd = toDT(chiaraPlan.end);
      chiaraBusy = chiaraBusy || overlaps(workStart, workEnd, gapStart, gapEnd);
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

    // entrambi disponibili → scegli Matteo (ok)
    if (!matteoBusy && !chiaraBusy) return AliceCompanionPerson.matteo;

    // entrambi occupati → nessuno può portarla
    return AliceCompanionPerson.nessuno;
  }

  Widget _buildDayGapsBox(CoverageResultStepA cov) {
    final state = cov.gapDetails.isNotEmpty
        ? DayGapVisualState.realGap
        : DayGapVisualState.noProblem;

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

    final ingressoReale = _scuolaStart;
    final ingressoInizio = TimeOfDay(
      hour: ((ingressoReale.hour * 60 + ingressoReale.minute - 20) ~/ 60) % 24,
      minute: (ingressoReale.hour * 60 + ingressoReale.minute - 20) % 60,
    );

    final inSupportSummary = _coverageSupportNetworkBuilder.summaryForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: d0,
      start: ingressoInizio,
      end: _scuolaStart,
      label: "Ingresso scuola",
    );

    final outSupportSummary = _coverageSupportNetworkBuilder.summaryForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: d0,
      start: _effSchoolOutStart(d0),
      end: _effSchoolOutEnd(d0),
      label: "Uscita scuola",
    );

    final lunchSupportSummary = uscita13Eff
        ? _coverageSupportNetworkBuilder.summaryForRange(
            coreStore: coreStore,
            daySettingsStore: daySettingsStore,
            day: d0,
            start: _effUscitaAnticipataAt(d0)!,
            end: _engine.sandraPranzoEnd,
            label: "Pranzo",
          )
        : null;

    final logisticAliceEvents = coreStore.aliceSpecialEventStore
        .eventsForDay(_selectedDay)
        .where((e) => e.behavior == AliceEventBehavior.logistic)
        .toList();

    final aliceLogisticsStatus = _aliceLogisticsStatusBuilder.build(
      day: _selectedDay,
      logisticEvents: logisticAliceEvents,
      aliceEventEngine: _aliceEventEngine,
      isMatteoBusy: (start, end) => _engine.isMatteoBusyBetween(start, end),
      isChiaraBusy: (start, end) => _engine.isChiaraBusyBetween(start, end),
    );

    String adultLabel(String? key) {
      switch (key) {
        case 'matteo':
          return 'Matteo';
        case 'chiara':
          return 'Chiara';
        case 'sandra':
          return 'Sandra';
        case 'supporto':
          return 'Supporto';
        default:
          return 'Non assegnato';
      }
    }

    final hasIncompleteLogistics = aliceLogisticsStatus.hasIncompleteLogistics;

    final hasLogisticConflict = aliceLogisticsStatus.hasLogisticConflict;
    final hasRealCoverageGap = cov.gapDetails.isNotEmpty;

    final visual = _dayGapVisualStateBuilder.build(
      baseState: state,
      baseColor: color,
      baseIcon: icon,
      baseHeadline: headline,
      baseSubline: subline,
      hasLogisticConflict: hasLogisticConflict,
      hasIncompleteLogistics: hasIncompleteLogistics,
      hasRealCoverageGap: hasRealCoverageGap,
    );

    final visibleGapDetails = cov.gapDetails.isNotEmpty
        ? cov.gapDetails
        : coreStore.aliceCompanionStore.entriesForDay(_selectedDay).map((e) {
            final who = e.person == AliceCompanionPerson.matteo
                ? "Matteo"
                : "Chiara";

            return CoverageGapDetail(
              label:
                  "Alice con $who: ${fmtTimeOfDay(TimeOfDay(hour: e.start.hour, minute: e.start.minute))}–${fmtTimeOfDay(TimeOfDay(hour: e.end.hour, minute: e.end.minute))}",
              lines: const [],
              start: TimeOfDay(hour: e.start.hour, minute: e.start.minute),
              end: TimeOfDay(hour: e.end.hour, minute: e.end.minute),
            );
          }).toList();

    final effectiveColor = visual.color;
    final effectiveIcon = visual.icon;
    final effectiveHeadline = visual.headline;
    final effectiveSubline = visual.subline;

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
          color: effectiveColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withOpacity(0.35)),
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
                Icon(effectiveIcon, color: effectiveColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveHeadline,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        effectiveSubline,
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
            if (visual.state == DayGapVisualState.coveredNeed) ...[
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
                logisticAliceEvents.isNotEmpty ||
                coreStore.aliceCompanionStore
                    .entriesForDay(_selectedDay)
                    .isNotEmpty) ...[
              const SizedBox(height: 10),

              if (logisticAliceEvents.isNotEmpty) ...[
                const SizedBox(height: 8),

                const Text(
                  "Logistica eventi Alice",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 6),

                ...logisticAliceEvents.map((e) {
                  final logistics = _aliceEventLogisticsBuilder.build(
                    day: _selectedDay,
                    event: e,
                    aliceEventEngine: _aliceEventEngine,
                    isMatteoBusy: (start, end) =>
                        _engine.isMatteoBusyBetween(start, end),
                    isChiaraBusy: (start, end) =>
                        _engine.isChiaraBusyBetween(start, end),
                    hasEnabledSupport: coreStore.supportNetworkStore.people.any(
                      (p) => p.enabled,
                    ),
                  );

                  final sameAdult = logistics.sameAdult;
                  final missingDropOff = logistics.missingDropOff;
                  final missingPickUp = logistics.missingPickUp;
                  final usesMatteo = logistics.usesMatteo;
                  final usesChiara = logistics.usesChiara;
                  final matteoBusy = logistics.matteoBusy;
                  final chiaraBusy = logistics.chiaraBusy;
                  final canSuggestSupport = logistics.canSuggestSupport;
                  final singleAdultManagesEvent =
                      logistics.singleAdultManagesEvent;
                  final splitLogistics = logistics.splitLogistics;
                  final dropOffConflict = logistics.dropOffConflict;
                  final pickUpConflict = logistics.pickUpConflict;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${e.label} "
                          "(${fmtTimeOfDay(e.start)}–${fmtTimeOfDay(e.end)}) • "
                          "Accompagna: ${adultLabel(e.dropOffAdultKey)} • "
                          "Ritiro: ${adultLabel(e.pickUpAdultKey)}",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        if (sameAdult)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Stessa persona gestisce accompagnamento e ritiro",
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (missingDropOff || missingPickUp)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              missingDropOff && missingPickUp
                                  ? "Logistica incompleta: manca accompagnamento e ritiro"
                                  : missingDropOff
                                  ? "Logistica incompleta: manca chi accompagna"
                                  : "Logistica incompleta: manca chi ritira",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (usesMatteo || usesChiara)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              usesMatteo && usesChiara
                                  ? "Coinvolti: Matteo e Chiara"
                                  : usesMatteo
                                  ? "Coinvolto: Matteo"
                                  : "Coinvolta: Chiara",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (matteoBusy || chiaraBusy)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              matteoBusy && chiaraBusy
                                  ? "Possibile conflitto logistico: Matteo e Chiara potrebbero non riuscire a gestire accompagnamento o ritiro"
                                  : matteoBusy
                                  ? "Possibile conflitto logistico: Matteo potrebbe non riuscire a gestire accompagnamento o ritiro"
                                  : "Possibile conflitto logistico: Chiara potrebbe non riuscire a gestire accompagnamento o ritiro",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (dropOffConflict || pickUpConflict)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              dropOffConflict && pickUpConflict
                                  ? "Conflitto su accompagnamento e ritiro"
                                  : dropOffConflict
                                  ? "Conflitto su accompagnamento"
                                  : "Conflitto su ritiro",
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (canSuggestSupport)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Suggerimento: verifica supporto disponibile per accompagnamento o ritiro",
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (singleAdultManagesEvent)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Nota: un solo adulto gestisce tutta la logistica dell’evento",
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (splitLogistics)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Logistica divisa: accompagnamento e ritiro sono gestiti da persone diverse",
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],

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

                if (!coreStore.aliceCompanionStore
                    .entriesForDay(_selectedDay)
                    .any(
                      (e) =>
                          e.sourceEventId != null &&
                          e.start.hour == visibleGapDetails[i].start.hour &&
                          e.start.minute == visibleGapDetails[i].start.minute &&
                          e.end.hour == visibleGapDetails[i].end.hour &&
                          e.end.minute == visibleGapDetails[i].end.minute,
                    ))
                  ElevatedButton(
                    onPressed: () {
                      final gap = visibleGapDetails[i];

                      final nowDay = _selectedDay;

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
                      _companionActionTextForGap(visibleGapDetails[i]),
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

    final List<CoverageGapDetail> rawDetails = _engine
        .aliceHomeRiskDetailsForDay(
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

    final realNow = DateTime.now();
    final selectedIsToday = _onlyDate(d0) == _onlyDate(realNow);
    final nowMinutes = realNow.hour * 60 + realNow.minute;

    final List<CoverageGapDetail> details = rawDetails.where((d) {
      if (!selectedIsToday) return true;

      final endMinutes = d.end.hour * 60 + d.end.minute;
      return endMinutes > nowMinutes;
    }).toList();

    final bool hasRisk = details.isNotEmpty;

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
    _loadPromemoria();
  }

  Future<void> _loadPromemoria() async {
    await _promemoriaStore.load();
    setState(() {});
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

  Widget _buildRealitySection(CoverageResultStepA cov) {
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
          if (cov.gapDetails.isNotEmpty)
            _buildActionSuggestionsPlaceholder(cov),
          const SizedBox(height: 12),
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
          FeriePeriodPanel(
            store: coreStore.feriePeriodStore,
            selectedDay: _selectedDay,
            onChanged: () {
              setState(() {});
              ipsStore.refresh(now: _selectedDay);
            },
          ),
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
        Expanded(flex: 5, child: _buildRealitySection(cov)),
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
        _buildRealitySection(cov),
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
        _buildRealitySection(cov),
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

  FamilyNowSnapshot _buildFamilyNowSnapshot() {
    final realNow = DateTime.now();

    final now = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      realNow.hour,
      realNow.minute,
      realNow.second,
      realNow.millisecond,
      realNow.microsecond,
    );

    final realEventStore = coreStore.realEventStore;
    final nowDay = _onlyDate(now);

    final matteoOverride = _getOverridesForDay(nowDay).matteo;
    final matteoDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'matteo',
      nowDay,
    );

    final matteoOnHoliday = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.matteo,
      nowDay,
    );

    final matteoBedSick =
        matteoOverride?.status == OverrideStatus.malattiaALetto ||
        matteoDisease?.type == DiseaseType.bed;

    final matteoEventsNow = coreStore.realEventStore
        .eventsForDay(nowDay)
        .where((e) => e.personKey == 'matteo');

    bool matteoBusyForEventNow = false;

    for (final event in matteoEventsNow) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        matteoBusyForEventNow = true;
        break;
      }
    }

    final matteoBusyForTurn = _engine.isMatteoBusyBetween(
      now,
      now.add(const Duration(minutes: 1)),
    );

    final matteoPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: _selectedDay,
    );

    String matteoTurnLabel = "Turno non previsto";

    if (!matteoPlan.isOff) {
      matteoTurnLabel =
          "Turno ${fmtTimeOfDay(matteoPlan.start)}–${fmtTimeOfDay(matteoPlan.end)}";
    }

    final matteoBusyNow =
        matteoBedSick || matteoBusyForTurn || matteoBusyForEventNow;

    final String matteoNowLabel;

    if (matteoDisease?.type == DiseaseType.mild) {
      matteoNowLabel = "malattia leggera";
    } else if (matteoBedSick) {
      matteoNowLabel = "occupato • malattia a letto";
    } else if (matteoOnHoliday) {
      matteoNowLabel = "libero • ferie";
    } else if (matteoBusyForEventNow) {
      matteoNowLabel = "occupato • evento";
    } else if (matteoBusyForTurn) {
      matteoNowLabel = "occupato • turno";
    } else {
      matteoNowLabel = "libero";
    }

    final chiaraOverride = _getOverridesForDay(nowDay).chiara;
    final chiaraDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'chiara',
      nowDay,
    );

    final chiaraOnHoliday = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.chiara,
      nowDay,
    );

    final chiaraBedSick =
        chiaraOverride?.status == OverrideStatus.malattiaALetto ||
        chiaraDisease?.type == DiseaseType.bed;

    final chiaraEventsNow = coreStore.realEventStore
        .eventsForDay(nowDay)
        .where((e) => e.personKey == 'chiara');

    bool chiaraBusyForEventNow = false;

    for (final event in chiaraEventsNow) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        chiaraBusyForEventNow = true;
        break;
      }
    }

    final chiaraBusyForTurn = _engine.isChiaraBusyBetween(
      now,
      now.add(const Duration(minutes: 1)),
    );

    final chiaraPlan = _turns.turnPlanForPersonDay(
      person: TurnPerson.chiara,
      day: _selectedDay,
    );

    String chiaraTurnLabel = "Turno non previsto";

    if (!chiaraPlan.isOff) {
      chiaraTurnLabel =
          "Turno ${fmtTimeOfDay(chiaraPlan.start)}–${fmtTimeOfDay(chiaraPlan.end)}";
    }

    final chiaraBusyNow =
        chiaraBedSick || chiaraBusyForTurn || chiaraBusyForEventNow;

    final String chiaraNowLabel;

    if (chiaraDisease?.type == DiseaseType.mild) {
      chiaraNowLabel = "malattia leggera";
    } else if (chiaraBedSick) {
      chiaraNowLabel = "occupato • malattia a letto";
    } else if (chiaraOnHoliday) {
      chiaraNowLabel = "libero • ferie";
    } else if (chiaraBusyForEventNow) {
      chiaraNowLabel = "occupato • evento";
    } else if (chiaraBusyForTurn) {
      chiaraNowLabel = "occupato • turno";
    } else {
      chiaraNowLabel = "libero";
    }

    final alicePeriodNow = coreStore.aliceEventStore.getEventForDay(nowDay);
    final aliceSpecialEventsNow = coreStore.aliceSpecialEventStore.eventsForDay(
      nowDay,
    );

    bool isNowInsideRange(TimeOfDay start, TimeOfDay end) {
      final rangeStart = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        start.hour,
        start.minute,
      );

      final rangeEnd = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        end.hour,
        end.minute,
      );

      return now.isAfter(rangeStart) && now.isBefore(rangeEnd);
    }

    bool aliceIsOutNow = false;

    final aliceEventsNow = coreStore.realEventStore
        .eventsForDay(nowDay)
        .where((e) => e.personKey == 'alice');

    bool aliceBusyForEventNow = false;

    for (final event in aliceEventsNow) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        aliceBusyForEventNow = true;
        break;
      }
    }

    final isRealSchoolDay = coreStore.schoolStore.hasSchoolOn(nowDay);

    if (aliceBusyForEventNow) {
      aliceIsOutNow = true;
    } else {
      if (alicePeriodNow == null) {
        if (!isRealSchoolDay) {
          aliceIsOutNow = false;
        } else {
          final uscitaAt = _effUscitaAnticipataAt(nowDay);
          final schoolEnd = uscitaAt ?? _effSchoolOutEnd(nowDay);
          final schoolStart = _scuolaStart;

          aliceIsOutNow = isNowInsideRange(schoolStart, schoolEnd);
        }
      } else {
        switch (alicePeriodNow.type) {
          case AliceEventType.schoolNormal:
            if (!isRealSchoolDay) {
              aliceIsOutNow = false;
              break;
            }

            final uscitaAt = _effUscitaAnticipataAt(nowDay);
            final schoolEnd = uscitaAt ?? _effSchoolOutEnd(nowDay);
            final schoolStart = _scuolaStart;

            aliceIsOutNow = isNowInsideRange(schoolStart, schoolEnd);
            break;

          case AliceEventType.summerCamp:
            final campStart =
                alicePeriodNow.summerCampStart ??
                const TimeOfDay(hour: 8, minute: 30);

            final campEnd =
                alicePeriodNow.summerCampEnd ??
                const TimeOfDay(hour: 16, minute: 30);

            aliceIsOutNow = isNowInsideRange(campStart, campEnd);
            break;

          case AliceEventType.vacation:
          case AliceEventType.schoolClosure:
          case AliceEventType.sickness:
            aliceIsOutNow = false;
            break;
        }
      }
    }

    for (final event in aliceSpecialEventsNow) {
      final eventStart = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        event.start.hour,
        event.start.minute,
      );

      final eventEnd = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        event.end.hour,
        event.end.minute,
      );

      final isActiveNow = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isActiveNow && _aliceEventEngine.isAliceOutDuringEvent(event)) {
        aliceIsOutNow = true;
        break;
      }
    }

    final isAliceSick = alicePeriodNow?.type == AliceEventType.sickness;

    AliceSpecialEvent? activeAliceSpecialEventNow;
    for (final event in aliceSpecialEventsNow) {
      final eventStart = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        event.start.hour,
        event.start.minute,
      );

      final eventEnd = DateTime(
        nowDay.year,
        nowDay.month,
        nowDay.day,
        event.end.hour,
        event.end.minute,
      );

      final isActiveNow = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isActiveNow) {
        activeAliceSpecialEventNow = event;
        break;
      }
    }

    RealEvent? activeAliceRealEventNow;
    final aliceRealEventsNow = coreStore.realEventStore
        .eventsForDay(nowDay)
        .where((e) => e.personKey == 'alice');

    for (final event in aliceRealEventsNow) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        activeAliceRealEventNow = event;
        break;
      }
    }

    String aliceOutsideLabelFromText(
      String text, {
      AliceSpecialEventCategory? category,
    }) {
      switch (category) {
        case AliceSpecialEventCategory.school:
          return "fuori • scuola";
        case AliceSpecialEventCategory.health:
          return "fuori • visita";
        case AliceSpecialEventCategory.sport:
          return "fuori • sport";
        case AliceSpecialEventCategory.activity:
          return "fuori • attività";
        case AliceSpecialEventCategory.other:
        case null:
          break;
      }

      final lower = text.toLowerCase();

      if (lower.contains('centro estivo')) return "fuori • centro estivo";
      if (lower.contains('gita')) return "fuori • gita";
      if (lower.contains('visita') ||
          lower.contains('dentista') ||
          lower.contains('medic') ||
          lower.contains('pediatra')) {
        return "fuori • visita";
      }
      if (lower.contains('scuola')) return "fuori • scuola";
      if (lower.contains('danza') ||
          lower.contains('ballo') ||
          lower.contains('pallavolo') ||
          lower.contains('sport')) {
        return "fuori • sport";
      }
      if (lower.contains('teatro') ||
          lower.contains('ripetizioni') ||
          lower.contains('corso')) {
        return "fuori • attività";
      }

      return "fuori";
    }

    final String aliceNowLabel = aliceIsOutNow
        ? (activeAliceSpecialEventNow != null
              ? aliceOutsideLabelFromText(
                  activeAliceSpecialEventNow.label,
                  category: activeAliceSpecialEventNow.category,
                )
              : activeAliceRealEventNow != null
              ? aliceOutsideLabelFromText(activeAliceRealEventNow.title)
              : (alicePeriodNow?.type == AliceEventType.summerCamp
                    ? "fuori • centro estivo"
                    : (coreStore.aliceEventStore.isSchoolNormalDay(_selectedDay)
                          ? "fuori • scuola"
                          : "fuori • casa")))
        : (isAliceSick ? "a casa • malata" : "a casa");

    final cov = _computeCoverageStepA(_selectedDay);
    final isEmergency = _isEmergencyActive();
    final bool showSummerCampSpecialCard = _selectedDayIsSummerCampDay();

    final baseIpsCoverage30 = coreStore.coverageAdapter.riskScore30Days(
      startDay: _selectedDay,
    );

    final hasForcedConflictToday =
        overrideStore.isForcedConflictForDay(
          day: _selectedDay,
          personKey: 'matteo',
          eventIds: _eventsForPersonOnDay(
            personKey: 'matteo',
            day: _selectedDay,
          ).map((e) => e.id).toList(),
        ) ||
        overrideStore.isForcedConflictForDay(
          day: _selectedDay,
          personKey: 'chiara',
          eventIds: _eventsForPersonOnDay(
            personKey: 'chiara',
            day: _selectedDay,
          ).map((e) => e.id).toList(),
        );

    final forcedPenalty = hasForcedConflictToday ? 15 : 0;

    final int ipsCoverage30 = (baseIpsCoverage30 + forcedPenalty).clamp(0, 100);

    final matteoVisual = getStatusVisual(matteoNowLabel);
    final chiaraVisual = getStatusVisual(chiaraNowLabel);
    final aliceVisual = getStatusVisual(aliceNowLabel);

    return FamilyNowSnapshot(
      realNow: realNow,
      now: now,
      realEventStore: realEventStore,
      nowDay: nowDay,
      matteoBusyNow: matteoBusyNow,
      chiaraBusyNow: chiaraBusyNow,
      aliceIsOutNow: aliceIsOutNow,
      matteoNowLabel: matteoNowLabel,
      chiaraNowLabel: chiaraNowLabel,
      aliceNowLabel: aliceNowLabel,
      matteoTurnLabel: matteoTurnLabel,
      chiaraTurnLabel: chiaraTurnLabel,
      cov: cov,
      isEmergency: isEmergency,
      showSummerCampSpecialCard: showSummerCampSpecialCard,
      ipsCoverage30: ipsCoverage30,
      matteoVisual: matteoVisual,
      chiaraVisual: chiaraVisual,
      aliceVisual: aliceVisual,
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyNowSnapshot = _buildFamilyNowSnapshot();
    final cov = familyNowSnapshot.cov;
    final isEmergency = familyNowSnapshot.isEmergency;
    final showSummerCampSpecialCard =
        familyNowSnapshot.showSummerCampSpecialCard;

    final familyNowViewModel = const FamilyNowViewModelBuilder().build(
      familyNowSnapshot,
    );

    final selectedDayEvents = familyNowSnapshot.realEventStore.eventsForDay(
      _selectedDay,
    );

    final adultDetailsBuilder = const FamilyAdultNowDetailsBuilder();

    final matteoDetails = adultDetailsBuilder.build(
      name: 'Matteo',
      personKey: 'matteo',
      day: _selectedDay,
      now: familyNowSnapshot.now,
      nowLabel: familyNowViewModel.matteo.label,
      turnLabel: familyNowViewModel.matteo.turnLabel ?? 'Turno non previsto',
      visual: familyNowViewModel.matteo.visual,
      events: selectedDayEvents,
    );

    final chiaraDetails = adultDetailsBuilder.build(
      name: 'Chiara',
      personKey: 'chiara',
      day: _selectedDay,
      now: familyNowSnapshot.now,
      nowLabel: familyNowViewModel.chiara.label,
      turnLabel: familyNowViewModel.chiara.turnLabel ?? 'Turno non previsto',
      visual: familyNowViewModel.chiara.visual,
      events: selectedDayEvents,
    );

    final aliceDayContext = AliceDayContextBuilder(
      coreStore,
    ).build(_selectedDay);

    final aliceDetails = const AliceNowDetailsBuilder().build(
      context: aliceDayContext,
      day: _selectedDay,
      now: familyNowSnapshot.now,
      nowLabel: familyNowViewModel.alice.label,
      visual: familyNowViewModel.alice.visual,
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
                  color: cov.gapDetails.isNotEmpty ? Colors.red : Colors.green,
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
            _buildIpsPressureLine(familyNowSnapshot.ipsCoverage30),
            FamilyNowCard(
              model: familyNowViewModel,
              realNow: familyNowSnapshot.realNow,
              onTapMatteo: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return FamilyAdultNowDialog(model: matteoDetails);
                  },
                );
              },
              onTapChiara: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return FamilyAdultNowDialog(model: chiaraDetails);
                  },
                );
              },
              onTapAlice: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AliceNowDialog(model: aliceDetails);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            _weekNavBar(),
            _buildTaskSectionMock(),
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

  Widget _buildTaskSectionMock() {
    String emoji(String persona) {
      switch (persona) {
        case 'Matteo':
          return '👨';
        case 'Chiara':
          return '👩';
        case 'Alice':
          return '👧';
        case 'Famiglia':
          return '👨‍👩‍👧';
        default:
          return '📝';
      }
    }

    List<Promemoria> itemsFor(String persona) {
      final selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );

      return _promemoriaStore.items.where((p) {
        if (p.persona != persona) return false;

        final createdDay = DateTime(
          p.createdDay.year,
          p.createdDay.month,
          p.createdDay.day,
        );

        if (createdDay.isAfter(selectedDay)) return false;

        if (p.completedDay == null) {
          return true;
        }

        final completedDay = DateTime(
          p.completedDay!.year,
          p.completedDay!.month,
          p.completedDay!.day,
        );

        return !selectedDay.isAfter(completedDay);
      }).toList();
    }

    Widget buildPromemoriaRow(
      Promemoria p, {
      bool insideDialog = false,
      VoidCallback? refreshDialog,
    }) {
      final selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );

      final bool done =
          p.completedDay != null &&
          DateTime(
                p.completedDay!.year,
                p.completedDay!.month,
                p.completedDay!.day,
              ) ==
              selectedDay;

      final createdDay = DateTime(
        p.createdDay.year,
        p.createdDay.month,
        p.createdDay.day,
      );

      final differenceDays = selectedDay.difference(createdDay).inDays;

      String? carryLabel;
      if (differenceDays == 1) {
        carryLabel = "da ieri";
      } else if (differenceDays > 1) {
        carryLabel = "da $differenceDays giorni";
      } else {
        carryLabel = null;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: done ? Colors.green.withOpacity(0.14) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done
                ? Colors.green.withOpacity(0.45)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: done,
              onChanged: (value) async {
                final newValue = value ?? false;

                await _promemoriaStore.toggleDone(
                  p.id,
                  newValue,
                  completedDay: _selectedDay,
                );

                await _loadPromemoria();

                if (refreshDialog != null) {
                  refreshDialog();
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${emoji(p.persona)} ${p.persona}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (carryLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Text(
                        carryLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    p.testo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: done ? Colors.green.shade800 : Colors.black,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final controller = TextEditingController(text: p.testo);

                    showDialog(
                      context: context,
                      builder: (context) {
                        String persona = p.persona;

                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              title: const Text('Modifica promemoria'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: persona,
                                    isExpanded: true,
                                    items:
                                        [
                                          'Matteo',
                                          'Chiara',
                                          'Alice',
                                          'Famiglia',
                                        ].map((item) {
                                          return DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                              "${emoji(item)}  $item",
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setStateDialog(() {
                                        persona = value;
                                      });
                                    },
                                  ),
                                  TextField(controller: controller),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annulla'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final testo = controller.text.trim();
                                    if (testo.isEmpty) return;

                                    await _promemoriaStore.update(
                                      p.copyWith(
                                        persona: persona,
                                        testo: testo,
                                      ),
                                    );

                                    await _loadPromemoria();

                                    if (refreshDialog != null) {
                                      refreshDialog();
                                    }

                                    Navigator.pop(context);
                                  },
                                  child: const Text('Salva'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _promemoriaStore.remove(p.id);
                    await _loadPromemoria();

                    if (refreshDialog != null) {
                      refreshDialog();
                    }

                    if (insideDialog && itemsFor(p.persona).isEmpty) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    void openPromemoriaPopup(String persona) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              final items = itemsFor(persona);

              return AlertDialog(
                title: Text("Promemoria • $persona"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items
                          .map(
                            (p) => buildPromemoriaRow(
                              p,
                              insideDialog: true,
                              refreshDialog: () {
                                setStateDialog(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Chiudi"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Widget buildPersonaButton(String persona) {
      final items = itemsFor(persona);
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: OutlinedButton(
          onPressed: () => openPromemoriaPopup(persona),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            "${emoji(persona)} $persona (${items.length})",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Promemoria del giorno",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final controller = TextEditingController();
              String persona = 'Matteo';

              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: const Text('Nuovo promemoria'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: persona,
                              isExpanded: true,
                              items: ['Matteo', 'Chiara', 'Alice', 'Famiglia']
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text("${emoji(p)}  $p"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setStateDialog(() {
                                  persona = value;
                                });
                              },
                            ),
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Scrivi il promemoria...',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annulla'),
                          ),
                          TextButton(
                            onPressed: () {
                              final testo = controller.text.trim();
                              if (testo.isEmpty) return;

                              _addMockPromemoria(
                                persona: persona,
                                testo: testo,
                              );

                              Navigator.pop(context);
                            },
                            child: const Text('Salva'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: const Text('+ Aggiungi promemoria'),
          ),
          if (itemsFor('Matteo').isEmpty &&
              itemsFor('Chiara').isEmpty &&
              itemsFor('Alice').isEmpty &&
              itemsFor('Famiglia').isEmpty)
            Text(
              "• Nessun promemoria per oggi",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              children: [
                buildPersonaButton('Matteo'),
                buildPersonaButton('Chiara'),
                buildPersonaButton('Alice'),
                buildPersonaButton('Famiglia'),
              ],
            ),
        ],
      ),
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

    final matteoSourceResult = _turnPersonSourceBuilder.build(
      coreStore: coreStore,
      personKey: 'matteo',
      day: _onlyDate(_selectedDay),
    );

    final chiaraSourceResult = _turnPersonSourceBuilder.build(
      coreStore: coreStore,
      personKey: 'chiara',
      day: _onlyDate(_selectedDay),
    );

    final selectedDayEvents = coreStore.realEventStore.eventsForDay(
      _onlyDate(_selectedDay),
    );

    final turnDayBuilder = const TurnDayBuilder();

    final matteoDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'matteo',
      _onlyDate(_selectedDay),
    );

    final chiaraDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'chiara',
      _onlyDate(_selectedDay),
    );

    final matteoIsBedSick =
        ov.matteo?.status == OverrideStatus.malattiaALetto ||
        matteoDisease?.type == DiseaseType.bed;

    final chiaraIsBedSick =
        ov.chiara?.status == OverrideStatus.malattiaALetto ||
        chiaraDisease?.type == DiseaseType.bed;

    final matteoIsSick =
        ov.matteo?.status == OverrideStatus.malattiaLeggera ||
        ov.matteo?.status == OverrideStatus.malattiaALetto ||
        matteoDisease != null;

    final chiaraIsSick =
        ov.chiara?.status == OverrideStatus.malattiaLeggera ||
        ov.chiara?.status == OverrideStatus.malattiaALetto ||
        chiaraDisease != null;

    final matteoDay = turnDayBuilder.buildPerson(
      person: TurnPerson.matteo,
      personKey: 'matteo',
      displayName: 'Matteo',
      day: _selectedDay,
      plan: m,
      turnSummary: _turnPlanSummary(m),
      manualOverride: ov.matteo,
      diseasePeriod: matteoDisease,
      turnOverrideStatusText: matteoSourceResult.turnOverrideStatusText,
      sourceText: matteoSourceResult.sourceText,
      isOnHoliday: _isPersonOnFerie(
        personKey: 'matteo',
        manualOverride: ov.matteo,
        day: _selectedDay,
      ),
      isSick: matteoIsSick,
      isBedSick: matteoIsBedSick,
      allDayEvents: selectedDayEvents,
    );

    final chiaraDay = turnDayBuilder.buildPerson(
      person: TurnPerson.chiara,
      personKey: 'chiara',
      displayName: 'Chiara',
      day: _selectedDay,
      plan: c,
      turnSummary: _turnPlanSummary(c),
      manualOverride: ov.chiara,
      diseasePeriod: chiaraDisease,
      turnOverrideStatusText: chiaraSourceResult.turnOverrideStatusText,
      sourceText: chiaraSourceResult.sourceText,
      isOnHoliday: _isPersonOnFerie(
        personKey: 'chiara',
        manualOverride: ov.chiara,
        day: _selectedDay,
      ),
      isSick: chiaraIsSick,
      isBedSick: chiaraIsBedSick,
      allDayEvents: selectedDayEvents,
    );

    final turnDay = turnDayBuilder.buildDay(
      day: _selectedDay,
      turnConflict: conflict,
      matteo: matteoDay,
      chiara: chiaraDay,
      allDayEvents: selectedDayEvents,
    );

    return _card(
      title: "Turni",
      subtitle:
          "Orari letti dal motore reale: rotazione standard oppure Quarta Squadra se attiva.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (turnDay.turnConflict.hasConflict) ...[
            _turnConflictBox(turnDay.turnConflict),
            const SizedBox(height: 12),
          ],
          if (turnDay.matteo.conflicts.isNotEmpty) ...[
            _turnEventConflictBox(
              personName: turnDay.matteo.displayName,
              personKey: turnDay.matteo.personKey,
              conflicts: turnDay.matteo.conflicts,
            ),
            const SizedBox(height: 12),
          ],
          if (turnDay.chiara.conflicts.isNotEmpty) ...[
            _turnEventConflictBox(
              personName: turnDay.chiara.displayName,
              personKey: turnDay.chiara.personKey,
              conflicts: turnDay.chiara.conflicts,
            ),
            const SizedBox(height: 12),
          ],
          if (turnDay.familyEvents.isNotEmpty) ...[
            _familyEventsBlock(turnDay.familyEvents),
            const SizedBox(height: 12),
          ],
          _turnRow(
            turnDay.matteo.displayName,
            turnDay.matteo.plan,
            statusText: turnDay.matteo.statusText,
            sourceText: turnDay.matteo.sourceText,
            events: turnDay.matteo.events,
            conflicts: turnDay.matteo.conflicts,
          ),
          const SizedBox(height: 10),
          _turnRow(
            turnDay.chiara.displayName,
            turnDay.chiara.plan,
            statusText: turnDay.chiara.statusText,
            sourceText: turnDay.chiara.sourceText,
            events: turnDay.chiara.events,
            conflicts: turnDay.chiara.conflicts,
          ),
          const SizedBox(height: 12),

          // 🔽 BLOCCO GESTIONE TURNI
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _turnManagementOpen = !_turnManagementOpen;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Gestione turni e rotazioni",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Icon(
                    _turnManagementOpen ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_turnManagementOpen) ...[
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
                          onPressed: () =>
                              Navigator.pop(context, TurnType.notte),
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
                          onPressed: () =>
                              Navigator.pop(context, TurnType.notte),
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

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () async {
                final person = await showDialog<TurnPersonId>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        "Quale nuova rotazione vuoi rimuovere?",
                      ),
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
          ],
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
    required String personKey,
    required List<TurnEventConflictResolution> conflicts,
  }) {
    final override = overrideStore.getForDay(_selectedDay);

    final personOverride = personKey == "matteo"
        ? override.matteo
        : override.chiara;

    final disease = coreStore.diseasePeriodStore.getPeriodForDay(
      personKey,
      _selectedDay,
    );

    final isBedSick =
        personOverride?.status == OverrideStatus.malattiaALetto ||
        disease?.type == DiseaseType.bed;

    final worst = _worstConflictState(conflicts);

    final now = DateTime.now();
    final selectedIsToday = _onlyDate(_selectedDay) == _onlyDate(now);

    final visibleConflicts = conflicts.where((c) {
      if (!selectedIsToday) return true;

      final end = c.overlapRange.end;
      return end.isAfter(now);
    }).toList();

    if (visibleConflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    final isForced = _isForcedConflict(
      personKey: personKey,
      conflicts: conflicts,
    );

    final color = isForced ? Colors.orange : conflictStateColor(worst);

    final String title;
    final String subtitle;

    switch (worst) {
      case TurnEventConflictState.open:
        if (isForced) {
          title = "⚠ Uscita imprescindibile — $personName";
          subtitle =
              "Hai forzato l'uscita nonostante il conflitto. Il sistema non la blocca ma la considera rischio.";
        } else if (isBedSick) {
          title = "⚠ Conflitto reale — $personName";
          subtitle =
              "Evento incompatibile con malattia a letto (uscita non possibile).";
        } else {
          title = "Conflitto turno / evento — $personName";
          subtitle = "Serve una decisione operativa.";
        }
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
          personKey: personKey,
          conflicts: visibleConflicts,
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
            ...visibleConflicts.map(
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
                        "Stato: ${isForced ? "Uscita imprescindibile" : conflictStateLabel(r.state)}",
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
    final now = DateTime.now();
    final selectedIsToday = _onlyDate(_selectedDay) == _onlyDate(now);

    final visibleEvents = events.where((e) {
      if (!selectedIsToday) return true;

      if (e.endTime == null) return true;

      final end = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        e.endTime!.hour,
        e.endTime!.minute,
      );

      return end.isAfter(now);
    }).toList();
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
              if (visibleEvents.isNotEmpty) ...[
                const SizedBox(height: 6),
                _eventPill(
                  text: realEventText(visibleEvents.first),
                  onTap: () => showExtraEventsDialog(
                    context: context,
                    personName: name,
                    events: visibleEvents,
                  ),
                ),
                if (visibleEvents.length > 1) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => showExtraEventsDialog(
                        context: context,
                        personName: name,
                        events: visibleEvents,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "+${visibleEvents.length - 1} altri eventi",
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
                    isMalattiaALetto
                        ? "⚠ Conflitto con stato reale"
                        : "⚠ Conflitto con turno",
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

    bool hasConflict = false;

    for (int i = 0; i < events.length; i++) {
      for (int j = i + 1; j < events.length; j++) {
        final a = events[i];
        final b = events[j];

        final overlap =
            a.start.hour * 60 + a.start.minute <
                b.end.hour * 60 + b.end.minute &&
            b.start.hour * 60 + b.start.minute < a.end.hour * 60 + a.end.minute;

        if (overlap) {
          hasConflict = true;
          break;
        }
      }
      if (hasConflict) break;
    }

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

    _aliceEventBehavior = AliceEventBehavior.logistic;

    _aliceEventAccompanyingAdultKey = null;
    _aliceEventDropOffAdultKey = null;
    _aliceEventPickUpAdultKey = null;

    _editingAliceSpecialEventId = null;

    _aliceEventDate = _selectedDay;

    if (closeEditor) {
      _showAliceEventEditor = false;
    }
  }

  AliceEventTileViewModel _buildAliceEventTileModel({
    required AliceSpecialEvent event,
    required bool isConflict,
  }) {
    return const AliceEventTileViewModelBuilder().build(
      event: event,
      isConflict: isConflict,
      isExpanded: _expandedAliceEventIds.contains(event.id),
      requiresLogistics: _aliceEventEngine.requiresLogistics(event),
      categoryIcon: _aliceSpecialCategoryIcon(event.category),
      categoryLabel: _aliceSpecialCategoryLabel(event.category),
    );
  }

  void _toggleAliceEventExpanded(String eventId) {
    setState(() {
      if (_expandedAliceEventIds.contains(eventId)) {
        _expandedAliceEventIds.remove(eventId);
      } else {
        _expandedAliceEventIds
          ..clear()
          ..add(eventId);
      }
    });
  }

  void _openNewAliceSpecialEventEditor() {
    setState(() {
      _resetAliceSpecialEventEditor(closeEditor: false);
      _aliceEventDate = _selectedDay; // 👈 IMPORTANTE
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

      _aliceEventBehavior = event.behavior;

      _aliceEventAccompanyingAdultKey = event.accompanyingAdultKey;
      _aliceEventDropOffAdultKey = event.dropOffAdultKey;
      _aliceEventPickUpAdultKey = event.pickUpAdultKey;

      _aliceEventDate = event.date;

      _showAliceEventEditor = true;

      _expandedAliceEventIds.add(event.id);
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

  Future<void> _pickAliceSpecialEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _aliceEventDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: "Evento Alice • DATA",
      cancelText: "Annulla",
      confirmText: "OK",
      locale: const Locale('it', 'IT'),
    );

    if (picked == null) return;

    setState(() {
      _aliceEventDate = DateTime(picked.year, picked.month, picked.day);
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

    final day = _onlyDate(_aliceEventDate);
    final store = coreStore.aliceSpecialEventStore;
    if (_editingAliceSpecialEventId != null) {
      for (final d in coreStore.aliceSpecialEventStore.allDates()) {
        final dayEvents = [...store.eventsForDay(d)];

        dayEvents.removeWhere((e) => e.id == _editingAliceSpecialEventId);

        store.replaceEventsForDay(d, dayEvents);
      }
    }

    final events = [...store.eventsForDay(day)];

    final newEvent = AliceSpecialEvent(
      id:
          _editingAliceSpecialEventId ??
          'evt_${DateTime.now().millisecondsSinceEpoch}',

      label: label,

      category: _aliceEventCategory,

      behavior: _aliceEventBehavior,

      accompanyingAdultKey: _aliceEventAccompanyingAdultKey,

      dropOffAdultKey: _aliceEventDropOffAdultKey,

      pickUpAdultKey: _aliceEventPickUpAdultKey,

      date: day,

      start: _aliceEventStart,

      end: _aliceEventEnd,

      note: _aliceEventNoteController.text.trim(),

      enabled: true,
    );

    events.add(newEvent);

    events.sort((a, b) {
      final aMin = a.start.hour * 60 + a.start.minute;
      final bMin = b.start.hour * 60 + b.start.minute;
      return aMin.compareTo(bMin);
    });

    store.replaceEventsForDay(day, events);

    coreStore.aliceCompanionStore.removeEntriesForSourceEvent(newEvent.id);

    final companionPerson = _aliceEventEngine.companionPersonForEvent(newEvent);

    if (companionPerson != null) {
      coreStore.aliceCompanionStore.addEntry(
        AliceCompanionEntry(
          day: day,
          start: newEvent.start,
          end: newEvent.end,
          person: companionPerson,
          sourceEventId: newEvent.id,
        ),
      );
    }

    setState(() {
      _resetAliceSpecialEventEditor(closeEditor: true);
    });

    ipsStore.refresh(now: _selectedDay);
  }

  void _removeAliceSpecialEvent(AliceSpecialEvent event) {
    coreStore.aliceSpecialEventStore.removeEvent(_selectedDay, event.id);

    coreStore.aliceCompanionStore.removeEntriesForSourceEvent(event.id);

    setState(() {
      if (_editingAliceSpecialEventId == event.id) {
        _resetAliceSpecialEventEditor(closeEditor: true);
      }
    });

    ipsStore.refresh(now: _selectedDay);
  }

  Widget _cardScuola() {
    final uscitaAt = _effUscitaAnticipataAt(_selectedDay);
    final uscita13Eff = uscitaAt != null;

    final aliceEvent = coreStore.aliceEventStore.getEventForDay(_selectedDay);

    final outStart = _effSchoolOutStart(_selectedDay);

    final outEnd = aliceEvent?.summerCampEnd ?? _effSchoolOutEnd(_selectedDay);

    final bool hasCustomOut =
        daySettingsStore.schoolOutStartForDay(_selectedDay) != null ||
        daySettingsStore.schoolOutEndForDay(_selectedDay) != null;

    final bool hasAlicePeriodState =
        aliceEvent != null && aliceEvent.type != AliceEventType.schoolNormal;

    final activeSchoolPeriod = coreStore.schoolStore.activePeriodForDay(
      _selectedDay,
    );
    final schoolPeriodLabel =
        activeSchoolPeriod?.name ?? "Nessun periodo attivo";

    final isSchoolDayActive = coreStore.schoolStore.hasSchoolOn(_selectedDay);
    final schoolWeekdayLabel = [
      "Lunedì",
      "Martedì",
      "Mercoledì",
      "Giovedì",
      "Venerdì",
      "Sabato",
      "Domenica",
    ][_selectedDay.weekday - 1];

    final uscitaReale =
        aliceEvent?.summerCampEnd ?? _effSchoolOutStart(_selectedDay);
    final uscitaFine = TimeOfDay(
      hour: ((uscitaReale.hour * 60 + uscitaReale.minute + 20) ~/ 60) % 24,
      minute: (uscitaReale.hour * 60 + uscitaReale.minute + 20) % 60,
    );

    final ingressoReale = aliceEvent?.summerCampStart ?? _scuolaStart;

    final ingressoInizio = TimeOfDay(
      hour: ((ingressoReale.hour * 60 + ingressoReale.minute - 20) ~/ 60) % 24,
      minute: (ingressoReale.hour * 60 + ingressoReale.minute - 20) % 60,
    );
    final accompagnamento = ingressoInizio;

    final ingressoFine = ingressoReale;

    String? alicePeriodStateLabel() {
      if (aliceEvent == null) return null;

      switch (aliceEvent.type) {
        case AliceEventType.schoolNormal:
          return null;
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

    Color alicePeriodStateColor() {
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

    IconData alicePeriodStateIcon() {
      if (aliceEvent == null) return Icons.info_outline;

      switch (aliceEvent.type) {
        case AliceEventType.schoolNormal:
          return Icons.info_outline;
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

    final extraEvents = _sortedAliceSpecialEventsForSelectedDay();
    final bool hasExtraEvents = extraEvents.isNotEmpty;

    bool hasAliceEventConflict = false;

    for (int i = 0; i < extraEvents.length; i++) {
      for (int j = i + 1; j < extraEvents.length; j++) {
        final a = extraEvents[i];
        final b = extraEvents[j];

        final overlap =
            a.start.hour * 60 + a.start.minute <
                b.end.hour * 60 + b.end.minute &&
            b.start.hour * 60 + b.start.minute < a.end.hour * 60 + a.end.minute;

        if (overlap) {
          hasAliceEventConflict = true;
          break;
        }
      }
      if (hasAliceEventConflict) break;
    }

    const int maxVisibleAliceEvents = 2;
    final visibleAliceEvents = hasExtraEvents
        ? extraEvents.take(maxVisibleAliceEvents).toList()
        : <AliceSpecialEvent>[];
    final hiddenAliceEventsCount = hasExtraEvents
        ? (extraEvents.length - visibleAliceEvents.length)
        : 0;

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

      if (aliceEvent != null) {
        switch (aliceEvent.type) {
          case AliceEventType.vacation:
            return "Vacanza";
          case AliceEventType.schoolClosure:
            return "Scuola chiusa";
          case AliceEventType.sickness:
            return "Malattia";
          case AliceEventType.summerCamp:
            return "Centro estivo";
          case AliceEventType.schoolNormal:
            break;
        }
      }

      return isSchoolDayActive ? "Scuola" : "A casa";
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
          AliceStateBanner(
            label: aliceEventLabel(),
            color: aliceEventColor(),
            icon: aliceEventIcon(),
            periodLabel: hasAlicePeriodState ? alicePeriodStateLabel() : null,
            periodColor: alicePeriodStateColor(),
            periodIcon: alicePeriodStateIcon(),
          ),

          AliceSchoolHeader(
            orario:
                "Orario: ${fmtTimeOfDay(aliceEvent?.summerCampStart ?? _scuolaStart)}–${fmtTimeOfDay(uscita13Eff ? uscitaAt : (daySettingsStore.schoolOutStartForDay(_selectedDay) ?? _scuolaEnd))}",
            uscitaAnticipata: uscita13Eff,
          ),

          if (hasAliceEventConflict) ...[const AliceEventConflictBanner()],

          AliceEventsSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AliceEventsHeader(
                  hasExtraEvents: hasExtraEvents,
                  extraEventsCount: extraEvents.length,
                  showAlicePeriodPanel: _showAlicePeriodPanel,
                  onNewAliceEvent: _openNewAliceSpecialEventEditor,
                  onToggleAlicePeriodPanel: () {
                    setState(() {
                      _showAlicePeriodPanel = !_showAlicePeriodPanel;
                    });
                  },
                ),

                if (hasExtraEvents) ...[
                  const SizedBox(height: 12),
                  AliceEventsList(
                    child: Column(
                      children: visibleAliceEvents.map((e) {
                        final conflictResult = const AliceEventConflictBuilder()
                            .build(event: e, allEvents: extraEvents);

                        final tileModel = _buildAliceEventTileModel(
                          event: e,
                          isConflict: conflictResult.isConflict,
                        );

                        final conflictWith = conflictResult.conflictWith;

                        return AliceEventTile(
                          model: tileModel,
                          onTap: () => _toggleAliceEventExpanded(tileModel.id),
                          expandedChild: tileModel.isExpanded
                              ? AliceEventExpanded(
                                  event: e,
                                  conflictWith: conflictWith,
                                  categoryLabel: _aliceSpecialCategoryLabel,
                                  operationalDescription:
                                      _aliceEventEngine.operationalDescription,
                                  realTimeMeaning:
                                      _aliceEventEngine.realTimeMeaning,
                                  isAliceOutDuringEvent:
                                      _aliceEventEngine.isAliceOutDuringEvent,
                                  requiresAdultSupervision: _aliceEventEngine
                                      .requiresAdultSupervision,
                                  canGenerateCoverageProblem: _aliceEventEngine
                                      .canGenerateCoverageProblem,
                                  onEdit: () => _startEditAliceSpecialEvent(e),
                                  onRemove: () => _removeAliceSpecialEvent(e),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          HiddenAliceEventsLink(
            hiddenCount: hiddenAliceEventsCount,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Tutti gli eventi Alice"),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: extraEvents.map((e) {
                            final conflictResult =
                                const AliceEventConflictBuilder().build(
                                  event: e,
                                  allEvents: extraEvents,
                                );

                            final isConflict = conflictResult.isConflict;
                            final conflictWith = conflictResult.conflictWith;

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isConflict
                                    ? Colors.red.withOpacity(0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isConflict
                                      ? Colors.red.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.08),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                                  if (conflictWith.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "In conflitto con: ${conflictWith.join(', ')}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _startEditAliceSpecialEvent(e);
                                          },
                                          icon: const Icon(Icons.edit_calendar),
                                          label: const Text("Sposta evento"),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _removeAliceSpecialEvent(e);
                                          },
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                          label: const Text("Annulla evento"),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _startEditAliceSpecialEvent(e);
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text("Modifica"),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeAliceSpecialEvent(e);
                                        },
                                        icon: const Icon(Icons.delete),
                                        label: const Text("Rimuovi"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Chiudi"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (_showAliceEventEditor) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAliceSpecialEventDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      "Data: ${DateFormat('d MMM yyyy', 'it_IT').format(_aliceEventDate)}",
                    ),
                  ),
                ),
              ],
            ),
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

                        _aliceEventBehavior = _aliceEventEngine
                            .defaultBehaviorForCategory(v);
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<AliceEventBehavior>(
                    value: _aliceEventBehavior,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Comportamento reale",
                      border: OutlineInputBorder(),
                    ),
                    items: AliceEventBehavior.values.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text(aliceEventBehaviorLabel(b)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _aliceEventBehavior = v;
                      });
                    },
                  ),
                  if (_aliceEventBehavior ==
                      AliceEventBehavior.accompanied) ...[
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _aliceEventAccompanyingAdultKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Adulto associato",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'matteo',
                          child: Text("Matteo"),
                        ),
                        DropdownMenuItem(
                          value: 'chiara',
                          child: Text("Chiara"),
                        ),
                        DropdownMenuItem(
                          value: 'sandra',
                          child: Text("Sandra"),
                        ),
                        DropdownMenuItem(
                          value: 'supporto',
                          child: Text("Supporto"),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _aliceEventAccompanyingAdultKey = v;
                        });
                      },
                    ),
                  ],

                  if (_aliceEventBehavior == AliceEventBehavior.logistic) ...[
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _aliceEventDropOffAdultKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Chi accompagna Alice",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'matteo',
                          child: Text("Matteo"),
                        ),
                        DropdownMenuItem(
                          value: 'chiara',
                          child: Text("Chiara"),
                        ),
                        DropdownMenuItem(
                          value: 'sandra',
                          child: Text("Sandra"),
                        ),
                        DropdownMenuItem(
                          value: 'supporto',
                          child: Text("Supporto"),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _aliceEventDropOffAdultKey = v;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _aliceEventPickUpAdultKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Chi ritira Alice",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'matteo',
                          child: Text("Matteo"),
                        ),
                        DropdownMenuItem(
                          value: 'chiara',
                          child: Text("Chiara"),
                        ),
                        DropdownMenuItem(
                          value: 'sandra',
                          child: Text("Sandra"),
                        ),
                        DropdownMenuItem(
                          value: 'supporto',
                          child: Text("Supporto"),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _aliceEventPickUpAdultKey = v;
                        });
                      },
                    ),
                  ],
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

          DayOrganizationSection(
            uscita13Eff: uscita13Eff,
            uscitaAt: uscitaAt,
            onToggleUscitaAnticipata: (v) async {
              await _toggleUscitaAnticipata(v);
            },
          ),

          SchoolStatusBox(
            schoolPeriodLabel: schoolPeriodLabel,
            isSchoolDayActive: isSchoolDayActive,
            schoolWeekdayLabel: schoolWeekdayLabel,
            accompagnamento: accompagnamento,
            ingressoReale: ingressoReale,
            uscitaReale: uscitaReale,
            uscitaFine: uscitaFine,
            onOpenSchoolPanel: _openSchoolPanel,
          ),
          SchoolOutSummary(
            visible: !uscita13Eff,
            outStart: outStart,
            outEnd: outEnd,
            hasCustomOut: hasCustomOut,
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          SchoolCoverageChoiceSection(
            ingressoInizio: ingressoInizio,
            ingressoFine: ingressoFine,
            uscitaReale: uscitaReale,
            uscitaAt: uscitaAt,
            uscita13Eff: uscita13Eff,
            schoolInCover: _effectiveSchoolInCover(_selectedDay),
            schoolOutCover: _effectiveSchoolOutCover(_selectedDay),
            lunchCover: _effectiveLunchCover(_selectedDay),
            labelForChoice: _schoolCoverLabel,
            onSchoolInChanged: (v) {
              setState(() {
                daySettingsStore.setSchoolInCoverForDay(_selectedDay, v);
              });
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
            onSchoolOutChanged: (v) {
              setState(() {
                daySettingsStore.setSchoolOutCoverForDay(_selectedDay, v);
              });
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
            onLunchChanged: (v) {
              setState(() {
                daySettingsStore.setLunchCoverForDay(_selectedDay, v);
              });
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
      ),
    );
  }

  SandraCoverageViewModel _buildSandraCoverageViewModel() {
    final sandraDecision = _sandraDecisionForDay(_selectedDay);

    return SandraCoverageViewModel(
      decision: sandraDecision,
      manualMattina: _effSandraMattina(_selectedDay),
      manualPranzo: _effSandraPranzo(_selectedDay),
      manualSera: _effSandraSera(_selectedDay),
      mattinaStart: _engine.sandraCambioMattinaStart,
      mattinaEnd: _engine.sandraCambioMattinaEnd,
      pranzoStart: _effectiveSandraPranzoStart(_selectedDay),
      pranzoEnd: _engine.sandraPranzoEnd,
      seraStart: _engine.sandraSeraStart,
      seraEnd: _engine.sandraSeraEnd,
    );
  }

  void _editSandraMattina() {
    _editSandraWindow(
      title: "Cambio turno mattina",
      currentStart: _engine.sandraCambioMattinaStart,
      currentEnd: _engine.sandraCambioMattinaEnd,
      onSave: (s, e) => _engine.setSandraCambioMattina(s, e),
    );
  }

  void _editSandraPranzo() {
    _editSandraWindow(
      title: "Cambio turno pranzo",
      currentStart: _engine.sandraPranzoStart,
      currentEnd: _engine.sandraPranzoEnd,
      onSave: (s, e) => _engine.setSandraPranzo(s, e),
    );
  }

  void _editSandraSera() {
    _editSandraWindow(
      title: "Cambio turno sera",
      currentStart: _engine.sandraSeraStart,
      currentEnd: _engine.sandraSeraEnd,
      onSave: (s, e) => _engine.setSandraSera(s, e),
    );
  }

  void _setSandraMattina(bool value) {
    setState(() {
      daySettingsStore.setSandraMattinaForDay(_selectedDay, value);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  void _setSandraPranzo(bool value) {
    setState(() {
      daySettingsStore.setSandraPranzoForDay(_selectedDay, value);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  void _setSandraSera(bool value) {
    setState(() {
      daySettingsStore.setSandraSeraForDay(_selectedDay, value);
    });
    ipsStore.refresh(now: _selectedDay);
  }

  Widget _cardCopertura(CoverageResultStepA cov) {
    return SandraCoverageCard(
      model: _buildSandraCoverageViewModel(),
      onEditMattina: _editSandraMattina,
      onEditPranzo: _editSandraPranzo,
      onEditSera: _editSandraSera,

      onChangedMattina: _setSandraMattina,
      onChangedPranzo: _setSandraPranzo,
      onChangedSera: _setSandraSera,
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

  Widget _buildActionSuggestionsPlaceholder(CoverageResultStepA cov) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Azioni consigliate",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            cov.gapDetails.length == 1
                ? "C'è 1 problema da gestire oggi"
                : "Ci sono ${cov.gapDetails.length} problemi da gestire oggi",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Valuta di attivare un supporto o modificare un turno",
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (cov.gapDetails.isNotEmpty) ...[
            ...cov.gapDetails.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final gap = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Problema $index",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _gapTitleWithAliceState(
                      gap.label.contains("Alice")
                          ? gap.label
                          : "Alice a casa: ${gap.label}",
                    ),
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSmartSandraSuggestion(gap.label),
                  const SizedBox(height: 8),
                ],
              );
            }),
            const SizedBox(height: 8),
            Text(
              "Problemi rilevati (${cov.gapDetails.length}):",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartSandraSuggestion(String label) {
    final regex = RegExp(r'(\d{2}):(\d{2})');
    final matches = regex.allMatches(label).toList();

    if (matches.length < 2) {
      return Text(
        "Suggerimento: verifica copertura manuale",
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
      );
    }

    final startTime = TimeOfDay(
      hour: int.parse(matches[0].group(1)!),
      minute: int.parse(matches[0].group(2)!),
    );

    final endTime = TimeOfDay(
      hour: int.parse(matches[1].group(1)!),
      minute: int.parse(matches[1].group(2)!),
    );

    final startMin = startTime.hour * 60 + startTime.minute;
    final endMin = endTime.hour * 60 + endTime.minute;

    final startDT = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      startTime.hour,
      startTime.minute,
    );

    final endDT = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      endTime.hour,
      endTime.minute,
    );

    final matteoLibero = !_engine.isMatteoBusyBetween(startDT, endDT);
    final chiaraLibera = !_engine.isChiaraBusyBetween(startDT, endDT);

    final supportoDisponibile = _supportNetworkCoversRange(
      day: _selectedDay,
      start: startTime,
      end: endTime,
    );

    final sandraMattinaCopre =
        _effSandraMattina(_selectedDay) &&
        (_engine.sandraCambioMattinaStart.hour * 60 +
                _engine.sandraCambioMattinaStart.minute) <=
            startMin &&
        (_engine.sandraCambioMattinaEnd.hour * 60 +
                _engine.sandraCambioMattinaEnd.minute) >=
            endMin;

    final sandraPranzoCopre =
        _effSandraPranzo(_selectedDay) &&
        (_effectiveSandraPranzoStart(_selectedDay).hour * 60 +
                _effectiveSandraPranzoStart(_selectedDay).minute) <=
            startMin &&
        (_engine.sandraPranzoEnd.hour * 60 + _engine.sandraPranzoEnd.minute) >=
            endMin;

    final sandraSeraCopre =
        _effSandraSera(_selectedDay) &&
        (_engine.sandraSeraStart.hour * 60 + _engine.sandraSeraStart.minute) <=
            startMin &&
        (_engine.sandraSeraEnd.hour * 60 + _engine.sandraSeraEnd.minute) >=
            endMin;

    final sandraDisponibile =
        sandraMattinaCopre || sandraPranzoCopre || sandraSeraCopre;

    String suggestion;

    if (matteoLibero && chiaraLibera) {
      suggestion = "Suggerimento: possono coprire Matteo o Chiara";
    } else if (matteoLibero) {
      suggestion = "Suggerimento: può coprire Matteo";
    } else if (chiaraLibera) {
      suggestion = "Suggerimento: può coprire Chiara";
    } else if (supportoDisponibile && sandraDisponibile) {
      suggestion = "Suggerimento: verifica Supporto oppure Sandra";
    } else if (supportoDisponibile) {
      suggestion = "Suggerimento: verifica Supporto";
    } else if (sandraDisponibile) {
      suggestion = "Suggerimento: attiva Sandra";
    } else {
      suggestion = suggestion =
          "Suggerimento: nessun genitore libero: attiva Sandra o Supporto oppure modifica turno / chiedi permesso";
    }

    return Text(
      suggestion,
      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
    );
  }

  void _openSchoolPanel() {
    final activeSchoolPeriod = coreStore.schoolStore.activePeriodForDay(
      _selectedDay,
    );

    final schoolPeriodLabel =
        activeSchoolPeriod?.name ?? "Nessun periodo attivo";

    final isSchoolDayActive = coreStore.schoolStore.hasSchoolOn(_selectedDay);

    final schoolWeekdayLabel = [
      "Lunedì",
      "Martedì",
      "Mercoledì",
      "Giovedì",
      "Venerdì",
      "Sabato",
      "Domenica",
    ][_selectedDay.weekday - 1];

    final ingressoReale =
        coreStore.aliceEventStore
            .getEventForDay(_selectedDay)
            ?.summerCampStart ??
        _scuolaStart;

    final uscitaReale =
        coreStore.aliceEventStore.getEventForDay(_selectedDay)?.summerCampEnd ??
        _effSchoolOutStart(_selectedDay);

    final accompagnamento = TimeOfDay(
      hour: ((ingressoReale.hour * 60 + ingressoReale.minute - 20) ~/ 60) % 24,
      minute: (ingressoReale.hour * 60 + ingressoReale.minute - 20) % 60,
    );

    final rientro = TimeOfDay(
      hour: ((uscitaReale.hour * 60 + uscitaReale.minute + 20) ~/ 60) % 24,
      minute: (uscitaReale.hour * 60 + uscitaReale.minute + 20) % 60,
    );

    void openDayEditor({
      required SchoolPeriod period,
      required String dayLabel,
      required SchoolDayConfig current,
      required SchoolPeriod Function(SchoolDayConfig updatedDay)
      buildUpdatedPeriod,
    }) {
      bool active = current.enabled;

      TimeOfDay ingresso = TimeOfDay(
        hour: current.entryMinutes ~/ 60,
        minute: current.entryMinutes % 60,
      );

      TimeOfDay uscita = TimeOfDay(
        hour: current.exitRealMinutes ~/ 60,
        minute: current.exitRealMinutes % 60,
      );

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(dayLabel),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text("Giorno attivo"),
                      value: active,
                      onChanged: (v) {
                        setStateDialog(() {
                          active = v;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: ingresso,
                        );
                        if (picked == null) return;

                        setStateDialog(() {
                          ingresso = picked;
                        });
                      },
                      icon: const Icon(Icons.login),
                      label: Text("Ingresso: ${fmtTimeOfDay(ingresso)}"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: uscita,
                        );
                        if (picked == null) return;

                        setStateDialog(() {
                          uscita = picked;
                        });
                      },
                      icon: const Icon(Icons.logout),
                      label: Text("Uscita: ${fmtTimeOfDay(uscita)}"),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annulla"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final updatedDay = current.copyWith(
                        enabled: active,
                        entryMinutes: ingresso.hour * 60 + ingresso.minute,
                        exitRealMinutes: uscita.hour * 60 + uscita.minute,
                      );

                      final updatedPeriod = buildUpdatedPeriod(updatedDay);

                      setState(() {
                        coreStore.schoolStore.updatePeriod(updatedPeriod);
                      });

                      Navigator.pop(context); // chiude popup giorno
                      Navigator.pop(context); // chiude popup settimana
                    },
                    child: const Text("Salva"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Widget buildWeekDayRow({
      required String label,
      required SchoolDayConfig config,
      required VoidCallback onTap,
    }) {
      final ingresso = TimeOfDay(
        hour: config.entryMinutes ~/ 60,
        minute: config.entryMinutes % 60,
      );

      final uscita = TimeOfDay(
        hour: config.exitRealMinutes ~/ 60,
        minute: config.exitRealMinutes % 60,
      );

      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                config.enabled ? "ATTIVO" : "OFF",
                style: TextStyle(
                  color: config.enabled ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                config.enabled
                    ? "${fmtTimeOfDay(ingresso)}–${fmtTimeOfDay(uscita)}"
                    : "-",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Scuola"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Periodo attivo: $schoolPeriodLabel"),
              const SizedBox(height: 6),
              Text(
                isSchoolDayActive
                    ? "Oggi: giorno scuola attivo"
                    : "Oggi: nessuna scuola prevista",
                style: TextStyle(
                  color: isSchoolDayActive ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text("Giorno: $schoolWeekdayLabel"),
              const Divider(height: 20),
              Text("Accompagnamento: ${fmtTimeOfDay(accompagnamento)}"),
              Text("Ingresso reale: ${fmtTimeOfDay(ingressoReale)}"),
              Text("Uscita reale: ${fmtTimeOfDay(uscitaReale)}"),
              Text("Rientro: ${fmtTimeOfDay(rientro)}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                final periods = coreStore.schoolStore.periods;

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Periodi scuola"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: periods.isEmpty
                            ? const Text("Nessun periodo scuola salvato.")
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: periods.map((p) {
                                  final isActive =
                                      coreStore.schoolStore
                                          .activePeriodForDay(_selectedDay)
                                          ?.id ==
                                      p.id;

                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.green
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      "Periodo: ${p.name}",
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Nome: ${p.name}",
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          "Inizio: ${DateFormat('d MMM yyyy', 'it_IT').format(p.startDate)}",
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          "Fine: ${DateFormat('d MMM yyyy', 'it_IT').format(p.endDate)}",
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                    "Settimana: ${p.name}",
                                                                  ),
                                                                  content: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Lunedì",
                                                                        config: p
                                                                            .weekConfig
                                                                            .monday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Lunedì",
                                                                            current:
                                                                                p.weekConfig.monday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    monday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Martedì",
                                                                        config: p
                                                                            .weekConfig
                                                                            .tuesday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Martedì",
                                                                            current:
                                                                                p.weekConfig.tuesday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    tuesday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Mercoledì",
                                                                        config: p
                                                                            .weekConfig
                                                                            .wednesday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Mercoledì",
                                                                            current:
                                                                                p.weekConfig.wednesday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    wednesday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Giovedì",
                                                                        config: p
                                                                            .weekConfig
                                                                            .thursday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Giovedì",
                                                                            current:
                                                                                p.weekConfig.thursday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    thursday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Venerdì",
                                                                        config: p
                                                                            .weekConfig
                                                                            .friday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Venerdì",
                                                                            current:
                                                                                p.weekConfig.friday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    friday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      buildWeekDayRow(
                                                                        label:
                                                                            "Sabato",
                                                                        config: p
                                                                            .weekConfig
                                                                            .saturday,
                                                                        onTap: () {
                                                                          openDayEditor(
                                                                            period:
                                                                                p,
                                                                            dayLabel:
                                                                                "Sabato",
                                                                            current:
                                                                                p.weekConfig.saturday,
                                                                            buildUpdatedPeriod:
                                                                                (
                                                                                  updatedDay,
                                                                                ) => p.copyWith(
                                                                                  weekConfig: p.weekConfig.copyWith(
                                                                                    saturday: updatedDay,
                                                                                  ),
                                                                                ),
                                                                          );
                                                                        },
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      _dayRow(
                                                                        "Domenica",
                                                                        false,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                            context,
                                                                          ),
                                                                      child: const Text(
                                                                        "Chiudi",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          },
                                                          icon: const Icon(
                                                            Icons
                                                                .calendar_month,
                                                          ),
                                                          label: const Text(
                                                            "Modifica settimana",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Chiudi",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${p.name}${isActive ? " (attivo)" : ""}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: isActive
                                                        ? Colors.green
                                                        : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${DateFormat('d MMM yyyy', 'it_IT').format(p.startDate)} → ${DateFormat('d MMM yyyy', 'it_IT').format(p.endDate)}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              coreStore.schoolStore
                                                  .removePeriod(p.id);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);

                            final nameController = TextEditingController();

                            DateTime? startDate;
                            DateTime? endDate;

                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      title: const Text("Nuovo periodo scuola"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: const InputDecoration(
                                              labelText: "Nome periodo",
                                              hintText:
                                                  "Es. Elementari 2025/2026",
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          OutlinedButton(
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2030),
                                                  );
                                              if (picked != null) {
                                                setStateDialog(
                                                  () => startDate = picked,
                                                );
                                              }
                                            },
                                            child: Text(
                                              startDate == null
                                                  ? "Data inizio"
                                                  : "Inizio: ${DateFormat('d MMM yyyy', 'it_IT').format(startDate!)}",
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        startDate ??
                                                        DateTime.now(),
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2030),
                                                  );
                                              if (picked != null) {
                                                setStateDialog(
                                                  () => endDate = picked,
                                                );
                                              }
                                            },
                                            child: Text(
                                              endDate == null
                                                  ? "Data fine"
                                                  : "Fine: ${DateFormat('d MMM yyyy', 'it_IT').format(endDate!)}",
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Annulla"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (nameController.text
                                                    .trim()
                                                    .isEmpty ||
                                                startDate == null ||
                                                endDate == null) {
                                              return;
                                            }

                                            coreStore.schoolStore.addPeriod(
                                              SchoolPeriod(
                                                id: DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString(),
                                                name: nameController.text
                                                    .trim(),
                                                startDate: startDate!,
                                                endDate: endDate!,
                                                weekConfig: SchoolWeekConfig(
                                                  monday: const SchoolDayConfig(
                                                    enabled: true,
                                                    entryMinutes: 8 * 60 + 25,
                                                    exitRealMinutes:
                                                        16 * 60 + 25,
                                                  ),
                                                  tuesday:
                                                      const SchoolDayConfig(
                                                        enabled: true,
                                                        entryMinutes:
                                                            8 * 60 + 25,
                                                        exitRealMinutes:
                                                            16 * 60 + 25,
                                                      ),
                                                  wednesday:
                                                      const SchoolDayConfig(
                                                        enabled: true,
                                                        entryMinutes:
                                                            8 * 60 + 25,
                                                        exitRealMinutes:
                                                            16 * 60 + 25,
                                                      ),
                                                  thursday:
                                                      const SchoolDayConfig(
                                                        enabled: true,
                                                        entryMinutes:
                                                            8 * 60 + 25,
                                                        exitRealMinutes:
                                                            16 * 60 + 25,
                                                      ),
                                                  friday: const SchoolDayConfig(
                                                    enabled: true,
                                                    entryMinutes: 8 * 60 + 25,
                                                    exitRealMinutes:
                                                        16 * 60 + 25,
                                                  ),
                                                  saturday:
                                                      const SchoolDayConfig.off(),
                                                ),
                                              ),
                                            );

                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Salva"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: const Text("Nuovo periodo"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Chiudi"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text("Gestisci periodi"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Chiudi"),
            ),
          ],
        );
      },
    );
  }

  Widget _dayRow(String label, bool active) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          active ? "ATTIVO" : "OFF",
          style: TextStyle(
            color: active ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
