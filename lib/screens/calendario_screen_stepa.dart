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
import '../models/real_event.dart';
import '../models/turn_override.dart';
import '../models/rotation_override.dart';
import '../models/alice_special_event.dart';
import '../models/school_model.dart';
import '../logic/core_store.dart';

import '../models/week_identity.dart';
import '../logic/settings_store.dart';
import '../logic/ips_store.dart';
import '../logic/day_settings_store.dart';

import '../widgets/stepb_override_panel.dart';
import '../widgets/alice_event_panel.dart';
import '../widgets/real_event_panel.dart';
import '../widgets/support_network_panel.dart';
import '../widgets/fourth_shift_panel.dart';
import '../widgets/ferie_period_panel.dart';
import '../widgets/disease_period_panel.dart';
import '../widgets/extra_events_dialog.dart';
import '../widgets/calendar/alice_event_logistics_details.dart';
import '../logic/calendar/view_models/sandra_coverage_view_model.dart';
// ✅ NEW: Eventi speciali centro estivo
import '../logic/summer_camp_special_event_store.dart';
import '../utils/calendario_formatters.dart';
import '../logic/promemoria_store.dart';
import '../models/promemoria.dart';
import '../logic/alice_events/alice_event_behavior_text.dart';
import '../logic/alice_events/alice_event_behavior.dart';
import '../logic/alice_events/alice_event_engine.dart';
import '../logic/calendar/models/family_now_snapshot.dart';
import '../logic/calendar/models/coverage_result_step_a.dart';
import '../logic/calendar/models/day_gap_visual_state.dart';
import '../logic/calendar/models/turn_event_conflict.dart';
import '../logic/calendar/models/turn_presentation_state.dart';
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
import '../logic/calendar/builders/family_now_view_model_builder.dart';
import '../logic/calendar/builders/family_now_snapshot_coordinator.dart';
import '../widgets/calendar/family_now_card.dart';
import '../widgets/calendar/family_day_overview_card.dart';
import '../logic/calendar/builders/family_adult_now_details_builder.dart';
import '../widgets/calendar/family_adult_now_dialog.dart';
import '../logic/calendar/builders/alice_day_context_builder.dart';
import '../logic/calendar/builders/alice_now_details_builder.dart';
import '../widgets/calendar/alice_now_dialog.dart';
import '../logic/calendar/builders/turn_day_builder.dart';
import '../logic/calendar/builders/turn_presentation_state_builder.dart';
import '../logic/calendar/builders/turn_person_source_builder.dart';
import '../logic/calendar/builders/coverage_support_network_builder.dart';
import '../logic/calendar/builders/alice_logistics_status_builder.dart';
import '../logic/calendar/builders/alice_event_logistics_coordinator.dart';
import '../logic/calendar/builders/alice_event_logistics_text_builder.dart';
import '../logic/calendar/builders/day_gap_visual_state_builder.dart';
import '../logic/calendar/builders/calendar_day_status_builder.dart';
import '../logic/calendar/presenters/calendar_day_status_visual_presenter.dart';
import '../logic/calendar/builders/visible_gap_details_builder.dart';
import '../logic/calendar/builders/day_support_summaries_builder.dart';
import '../logic/calendar/builders/coverage_gap_companion_resolver.dart';
import '../logic/calendar/builders/gap_title_with_alice_state_builder.dart';
import '../logic/calendar/builders/person_effective_status_builder.dart';
import '../logic/calendar/builders/turn_event_conflict_visual_state_builder.dart';
import '../logic/calendar/builders/turn_ui_observation_filter.dart';
import '../logic/calendar/builders/family_day_overview_snapshot_builder.dart';
import '../logic/calendar/models/family_day_overview_snapshot.dart';
import '../logic/calendar/builders/family_day_overview_view_model_builder.dart';
import '../logic/calendar/builders/effective_school_day_timing_reader.dart';
import '../logic/calendar/builders/coverage_criticality_view_model_builder.dart';
import '../logic/calendar/view_models/coverage_criticality_view_model.dart';
import '../widgets/calendar/coverage_criticalities_panel.dart';
import '../logic/calendar/builders/coverage_gap_recommendation_view_model_builder.dart';
import '../widgets/calendar/coverage_gap_recommendations_panel.dart';
import '../logic/calendar/builders/calendar_day_coverage_coordinator.dart';
import '../logic/calendar/builders/calendar_day_coverage_input_resolver.dart';
import '../logic/calendar/builders/alice_home_risk_view_model_builder.dart';
import '../logic/calendar/calendar_day_navigation.dart';
import '../logic/calendar/view_models/alice_home_risk_view_model.dart';
import '../logic/calendar/builders/alice_school_day_view_model_builder.dart';
import '../logic/adult_logistics_availability_resolver.dart';
import '../logic/calendar/builders/alice_logistic_provider_availability_resolver.dart';
import '../logic/calendar/builders/calendar_logistics_availability_resolver.dart';
import '../logic/calendar/builders/alice_summer_camp_logistics_coordinator.dart';
import '../logic/calendar/builders/alice_summer_camp_logistics_view_model_builder.dart';
import '../logic/calendar/models/alice_summer_camp_logistics.dart';
import '../logic/calendar/models/alice_event_logistics.dart';
import '../logic/calendar/view_models/alice_summer_camp_logistics_view_model.dart';
import '../widgets/calendar/summer_camp_logistics_section.dart';

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

enum CalendarTemporalMode { now, dayOverview }

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

  CalendarTemporalMode _temporalModeFor({
    required DateTime selectedDay,
    required DateTime realNow,
  }) {
    final selectedDate = _onlyDate(selectedDay);
    final today = _onlyDate(realNow);

    return selectedDate == today
        ? CalendarTemporalMode.now
        : CalendarTemporalMode.dayOverview;
  }

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
  final TurnPresentationStateBuilder _turnPresentationStateBuilder =
      const TurnPresentationStateBuilder();

  final CoverageCriticalityViewModelBuilder _criticalityViewModelBuilder =
      const CoverageCriticalityViewModelBuilder();

  final CoverageGapRecommendationViewModelBuilder
  _gapRecommendationViewModelBuilder =
      const CoverageGapRecommendationViewModelBuilder();

  final CoverageSupportNetworkBuilder _coverageSupportNetworkBuilder =
      const CoverageSupportNetworkBuilder();

  final AliceLogisticsStatusBuilder _aliceLogisticsStatusBuilder =
      const AliceLogisticsStatusBuilder();

  final CoverageGapCompanionResolver _gapCompanionResolver =
      const CoverageGapCompanionResolver();

  final GapTitleWithAliceStateBuilder _gapTitleWithAliceStateBuilder =
      const GapTitleWithAliceStateBuilder();

  final PersonEffectiveStatusBuilder _personEffectiveStatusBuilder =
      const PersonEffectiveStatusBuilder();

  final TurnEventConflictVisualStateBuilder
  _turnEventConflictVisualStateBuilder =
      const TurnEventConflictVisualStateBuilder();

  final TurnUiObservationFilter _turnUiObservationFilter =
      const TurnUiObservationFilter();

  final CalendarDayNavigation _dayNavigation = const CalendarDayNavigation();

  final AliceEventLogisticsTextBuilder _aliceEventLogisticsTextBuilder =
      const AliceEventLogisticsTextBuilder();

  final DayGapVisualStateBuilder _dayGapVisualStateBuilder =
      const DayGapVisualStateBuilder();

  final CalendarDayStatusBuilder _calendarDayStatusBuilder =
      const CalendarDayStatusBuilder();

  final CalendarDayStatusVisualPresenter _calendarDayStatusVisualPresenter =
      const CalendarDayStatusVisualPresenter();

  final VisibleGapDetailsBuilder _visibleGapDetailsBuilder =
      const VisibleGapDetailsBuilder();

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
    return EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(day).earlySchoolExitAt;
  }

  CoverageSandraDecision _sandraDecisionForDay(DateTime day) {
    final inputs = _coverageInputs(day);
    return CoverageSandraDecision(
      serveSandraMattina: inputs.serveSandraMattina,
      serveSandraPranzo: inputs.serveSandraPranzo,
      serveSandraSera: inputs.serveSandraSera,
    );
  }

  TimeOfDay _effSchoolOutStart(DateTime day) {
    return EffectiveSchoolDayTimingReader(coreStore).read(day).schoolExitAt;
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

  SchoolCoverChoice _effectiveSchoolInCover(DateTime day) {
    return _coverageInputs(day).schoolInCover;
  }

  SchoolCoverChoice _effectiveSchoolOutCover(DateTime day) {
    return _coverageInputs(day).schoolOutCover;
  }

  SchoolCoverChoice _effectiveLunchCover(DateTime day) {
    return _coverageInputs(day).lunchCover;
  }

  TimeOfDay _effectiveSandraPranzoStart(DateTime day) {
    return _coverageInputs(day).sandraLunchStart;
  }

  CalendarDayCoverageInputs _coverageInputs(DateTime day) {
    final d0 = _onlyDate(day);
    return CalendarDayCoverageInputResolver(
      coreStore: coreStore,
    ).resolve(selectedDay: d0, overrides: _getOverridesForDay(d0));
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
    return overrideStore.isForcedConflictForDay(
      day: _selectedDay,
      personKey: personKey,
      eventIds: conflicts.eventIds,
    );
  }

  void _setForcedConflict({
    required String personKey,
    required List<TurnEventConflictResolution> conflicts,
    required bool forced,
  }) {
    overrideStore.setForcedConflictForDay(
      day: _selectedDay,
      personKey: personKey,
      eventIds: conflicts.eventIds,
      forced: forced,
    );

    setState(() {});
    ipsStore.refresh(now: _selectedDay);
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

    final disease = coreStore.diseasePeriodStore.getPeriodForDay(
      personKey,
      _selectedDay,
    );

    final feriePerson = personKey == 'matteo'
        ? FeriePerson.matteo
        : FeriePerson.chiara;

    final isInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      feriePerson,
      _onlyDate(_selectedDay),
    );

    final effectiveStatus = _personEffectiveStatusBuilder.build(
      manualOverride: personOverride,
      diseasePeriod: disease,
      isInHolidayPeriod: isInHolidayPeriod,
    );

    final isBedSick = effectiveStatus.isBedSick;

    final hasTurnContext = conflicts.hasTurnContext;
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
                      "• ${realEventText(r.event)} — ${effectiveConflictStateLabel(state: r.state, isForced: isForced)}${r.detailText == null ? "" : "\n${r.detailText}"}",
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
      _selectedDay = _dayNavigation.previous(_selectedDay);
      _syncWeekWithSelectedDay();
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDay = _dayNavigation.next(_selectedDay);
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
    return EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(_selectedDay).schoolEntryAt;
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _gapTitleWithAliceState(String label) {
    return _gapTitleWithAliceStateBuilder.build(
      label: label,
      aliceEventType: coreStore.aliceEventStore.getEventTypeForDay(
        _selectedDay,
      ),
      cleanGapTitle: cleanGapTitle,
    );
  }

  String _companionActionTextForGap(CoverageGapDetail gap) {
    final start = gap.start;
    final end = gap.end;

    final person = _companionForGap(gap);

    return coreStore.aliceCompanionStore.companionActionTextForExactRange(
      day: _selectedDay,
      start: start,
      end: end,
      person: person,
    );
  }

  Color _turnSourceColor(TurnSourceTone tone) {
    switch (tone) {
      case TurnSourceTone.fourthShift:
        return Colors.orange;
      case TurnSourceTone.manualOverride:
        return Colors.amber.shade800;
      case TurnSourceTone.rotationOverride:
        return Colors.deepPurple;
      case TurnSourceTone.standard:
        return Colors.blueGrey;
    }
  }

  Color _turnStatusColor(TurnPresentationTone tone) {
    switch (tone) {
      case TurnPresentationTone.sickness:
        return Colors.red;
      case TurnPresentationTone.manualOverride:
        return Colors.deepPurple;
      case TurnPresentationTone.standard:
      case TurnPresentationTone.rest:
        return Theme.of(context).colorScheme.primary;
    }
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

  CoverageResultStepA _buildDayCoverage({
    required DateTime day,
    required DateTime observedAt,
  }) {
    final d0 = _onlyDate(day);
    final inputs = _coverageInputs(d0);

    final coordinator = CalendarDayCoverageCoordinator(
      analyze: (request) => _engine.analyzeDay(
        day: request.day,
        uscita13: request.uscita13,
        sandraMorningAvailable: request.sandraMorningAvailable,
        sandraLunchAvailable: request.sandraLunchAvailable,
        sandraEveningAvailable: request.sandraEveningAvailable,
        overrides: request.overrides,
        ferieStore: request.ferieStore,
        schoolInCover: request.schoolInCover,
        schoolOutCover: request.schoolOutCover,
        schoolOutStart: request.schoolOutStart,
        schoolOutEnd: request.schoolOutEnd,
        lunchCover: request.lunchCover,
        uscitaAnticipataAt: request.uscitaAnticipataAt,
      ),
    );
    return coordinator.build(
      selectedDay: d0,
      observedAt: observedAt,
      inputs: inputs,
    );
  }

  List<CoverageCriticalityViewModel> _criticalityViewModels(
    CoverageResultStepA coverage,
  ) {
    return _criticalityViewModelBuilder.build(
      details: coverage.criticalityDetails,
      supportPeople: coreStore.supportNetworkStore.people,
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

    if (!_isEmergencyActive()) {
      return const SizedBox.shrink();
    }

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

  CoverageGapCompanionResolution _resolveCompanions(CoverageGapDetail gap) {
    final availability = _coverageInputs(_selectedDay).logisticsAvailability;
    return _gapCompanionResolver.resolve(
      day: _selectedDay,
      gap: gap,
      isMatteoBusy: _engine.isMatteoBusyBetween,
      isChiaraBusy: _engine.isChiaraBusyBetween,
      availability: availability,
    );
  }

  AliceCompanionPerson _companionForGap(CoverageGapDetail gap) {
    return _resolveCompanions(gap).suggestedAliceCompanion;
  }

  Widget _buildDayGapsBox(
    CoverageResultStepA cov,
    List<AliceEventLogisticsResolution> aliceEventLogistics,
  ) {
    final d0 = _onlyDate(_selectedDay);
    final timing = EffectiveSchoolDayTimingReader(coreStore).read(d0);
    final earlySchoolExitAt = timing.earlySchoolExitAt;
    final uscita13Eff = timing.hasEarlySchoolExit;
    final coverageInputs = _coverageInputs(d0);
    final inCover = coverageInputs.schoolInCover;
    final outCover = coverageInputs.schoolOutCover;
    final lunchCover = coverageInputs.lunchCover;
    final sandraDecision = CoverageSandraDecision(
      serveSandraMattina: coverageInputs.serveSandraMattina,
      serveSandraPranzo: coverageInputs.serveSandraPranzo,
      serveSandraSera: coverageInputs.serveSandraSera,
    );

    final ingressoInizio = TimeOfDay(
      hour:
          ((timing.schoolEntryAt.hour * 60 +
                  timing.schoolEntryAt.minute -
                  20) ~/
              60) %
          24,
      minute:
          (timing.schoolEntryAt.hour * 60 + timing.schoolEntryAt.minute - 20) %
          60,
    );

    final supportSummaries = const DaySupportSummariesBuilder().build(
      coverageSupportNetworkBuilder: _coverageSupportNetworkBuilder,
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: d0,
      schoolInStart: ingressoInizio,
      schoolInEnd: timing.schoolEntryAt,
      schoolOutStart: timing.schoolExitAt,
      schoolOutEnd: timing.schoolPickupWindowEnd,
      earlySchoolExitActive: uscita13Eff,
      earlySchoolExitAt: earlySchoolExitAt,
      lunchEnd: _engine.sandraPranzoEnd,
    );

    final aliceLogisticsStatus = _aliceLogisticsStatusBuilder.build(
      resolutions: aliceEventLogistics,
    );

    final summerCampLogistics = _summerCampLogisticsViewModel(
      operational: AliceSchoolDayViewModelBuilder(coreStore)
          .build(day: d0, expandedEventIds: _expandedAliceEventIds)
          .showSummerCampSpecialCard,
      effectiveStart: timing.schoolEntryAt,
      effectiveEnd: timing.schoolExitAt,
    );

    final visual = _dayGapVisualStateBuilder.build(
      hasLogisticConflict: aliceLogisticsStatus.hasLogisticConflict,
      hasIncompleteLogistics: aliceLogisticsStatus.hasIncompleteLogistics,
      hasRealCoverageGap: cov.gapDetails.isNotEmpty,
      hasSummerCampLogisticGaps: summerCampLogistics?.hasLogisticGaps ?? false,
    );

    final companionEntries = coreStore.aliceCompanionStore.entriesForDay(d0);

    final visibleGapDetails = _visibleGapDetailsBuilder.build(
      realGapDetails: cov.gapDetails,
      companionEntries: companionEntries,
      formatTime: fmtTimeOfDay,
    );

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
          color: visual.color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: visual.color.withOpacity(0.35)),
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
                Icon(visual.icon, color: visual.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visual.headline,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visual.subline,
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
                  coverageInputs
                      .logisticsAvailability
                      .sandraWindows[0]
                      .available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• Sandra copre la fascia mattina (${fmtTimeOfDay(_engine.sandraCambioMattinaStart)}–${fmtTimeOfDay(_engine.sandraCambioMattinaEnd)})",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (sandraDecision.serveSandraPranzo &&
                  coverageInputs
                      .logisticsAvailability
                      .sandraWindows[1]
                      .available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• Sandra copre la fascia pranzo (${fmtTimeOfDay(_engine.sandraPranzoStart)}–${fmtTimeOfDay(_engine.sandraPranzoEnd)})",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              if (sandraDecision.serveSandraSera &&
                  coverageInputs
                      .logisticsAvailability
                      .sandraWindows[2]
                      .available)
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
                  supportSummaries.schoolIn != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    supportSummaries.schoolIn!,
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
                  supportSummaries.schoolOut != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    supportSummaries.schoolOut!,
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
                  supportSummaries.lunch != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    supportSummaries.lunch!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
            if (visual.state == DayGapVisualState.realGap ||
                aliceEventLogistics.isNotEmpty ||
                companionEntries.isNotEmpty) ...[
              const SizedBox(height: 10),

              if (aliceEventLogistics.isNotEmpty) ...[
                const SizedBox(height: 8),

                const Text(
                  "Logistica eventi Alice",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 6),

                ...aliceEventLogistics.map((logistics) {
                  final e = logistics.event;
                  final logisticsText = _aliceEventLogisticsTextBuilder.build(
                    logistics,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${e.label} "
                          "(${fmtTimeOfDay(e.start)}–${fmtTimeOfDay(e.end)}) • "
                          "Accompagna: ${_aliceEventLogisticsTextBuilder.adultLabel(e.dropOffAdultKey)} • "
                          "Ritiro: ${_aliceEventLogisticsTextBuilder.adultLabel(e.pickUpAdultKey)}",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        AliceEventLogisticsDetails(
                          logisticsText: logisticsText,
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
                    .hasSourceEventEntryForExactRange(
                      day: d0,
                      start: visibleGapDetails[i].start,
                      end: visibleGapDetails[i].end,
                    ))
                  ElevatedButton(
                    onPressed: () {
                      final gap = visibleGapDetails[i];

                      coreStore.aliceCompanionStore.toggleEntryForExactRange(
                        AliceCompanionEntry(
                          day: d0,
                          start: gap.start,
                          end: gap.end,
                          person: _companionForGap(gap),
                        ),
                      );

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

  Widget _buildAliceHomeRiskBox(AliceHomeRiskViewModel model) {
    final bool hasRisk = model.hasRisk;

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

  Widget _buildRealitySection(
    CoverageResultStepA cov, {
    required DateTime observedAt,
  }) {
    final criticalities = _criticalityViewModels(cov);
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
          if (criticalities.isNotEmpty) ...[
            CoverageCriticalityRealityList(items: criticalities),
            const SizedBox(height: 12),
          ],
          if (cov.gapDetails.isNotEmpty)
            _buildCoverageGapRecommendationsPanel(cov),
          const SizedBox(height: 12),
          Container(
            key: _turniKey,
            child: _cardTurni(observedAt: observedAt),
          ),
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
    required AliceHomeRiskViewModel aliceHomeRisk,
    required bool isEmergency,
    required List<AliceEventLogisticsResolution> aliceEventLogistics,
  }) {
    final criticalities = _criticalityViewModels(cov);
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
          if (!isEmergency && cov.gapDetails.isNotEmpty) ...[
            const Text(
              'Buchi reali',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
          ],
          if (!isEmergency) _buildDayGapsBox(cov, aliceEventLogistics),
          if (!isEmergency && criticalities.isNotEmpty) ...[
            CoverageCriticalitiesPanel(items: criticalities),
            const SizedBox(height: 12),
          ],
          if (!isEmergency) _buildAliceHomeRiskBox(aliceHomeRisk),
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
    required DateTime observedAt,
    required AliceHomeRiskViewModel aliceHomeRisk,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
    required List<AliceEventLogisticsResolution> aliceEventLogistics,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildRealitySection(cov, observedAt: observedAt),
        ),
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
          child: _buildDecisionsSection(
            cov: cov,
            aliceHomeRisk: aliceHomeRisk,
            isEmergency: isEmergency,
            aliceEventLogistics: aliceEventLogistics,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout({
    required CoverageResultStepA cov,
    required DateTime observedAt,
    required AliceHomeRiskViewModel aliceHomeRisk,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
    required List<AliceEventLogisticsResolution> aliceEventLogistics,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRealitySection(cov, observedAt: observedAt),
        const SizedBox(height: 12),
        _buildAliceSection(
          showSummerCampSpecialCard: showSummerCampSpecialCard,
        ),
        const SizedBox(height: 12),
        _buildDecisionsSection(
          cov: cov,
          aliceHomeRisk: aliceHomeRisk,
          isEmergency: isEmergency,
          aliceEventLogistics: aliceEventLogistics,
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required CoverageResultStepA cov,
    required DateTime observedAt,
    required AliceHomeRiskViewModel aliceHomeRisk,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
    required List<AliceEventLogisticsResolution> aliceEventLogistics,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRealitySection(cov, observedAt: observedAt),
        const SizedBox(height: 12),
        _buildAliceSection(
          showSummerCampSpecialCard: showSummerCampSpecialCard,
        ),
        const SizedBox(height: 12),
        _buildDecisionsSection(
          cov: cov,
          aliceHomeRisk: aliceHomeRisk,
          isEmergency: isEmergency,
          aliceEventLogistics: aliceEventLogistics,
        ),
      ],
    );
  }

  Widget _buildMainLayout({
    required CoverageResultStepA cov,
    required DateTime observedAt,
    required AliceHomeRiskViewModel aliceHomeRisk,
    required bool showSummerCampSpecialCard,
    required bool isEmergency,
    required List<AliceEventLogisticsResolution> aliceEventLogistics,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        if (w >= 1200) {
          return _buildDesktopThreeColumns(
            cov: cov,
            observedAt: observedAt,
            aliceHomeRisk: aliceHomeRisk,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
            aliceEventLogistics: aliceEventLogistics,
          );
        }

        if (w >= 800) {
          return _buildTabletLayout(
            cov: cov,
            observedAt: observedAt,
            aliceHomeRisk: aliceHomeRisk,
            showSummerCampSpecialCard: showSummerCampSpecialCard,
            isEmergency: isEmergency,
            aliceEventLogistics: aliceEventLogistics,
          );
        }

        return _buildMobileLayout(
          cov: cov,
          observedAt: observedAt,
          aliceHomeRisk: aliceHomeRisk,
          showSummerCampSpecialCard: showSummerCampSpecialCard,
          isEmergency: isEmergency,
          aliceEventLogistics: aliceEventLogistics,
        );
      },
    );
  }

  FamilyDayOverviewSnapshot _buildFamilyDayOverviewSnapshot() {
    return const FamilyDayOverviewSnapshotBuilder().build(
      coreStore: coreStore,
      day: _selectedDay,
      overrides: _getOverridesForDay(_selectedDay),
    );
  }

  int _computeIpsCoverage30() {
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

    return ipsCoverage30;
  }

  FamilyNowSnapshot _buildFamilyNowSnapshot({required DateTime observedAt}) {
    return const FamilyNowSnapshotCoordinator().build(
      selectedDay: _selectedDay,
      observedAt: observedAt,
      coreStore: coreStore,
      overrides: _getOverridesForDay(_selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    final observedAt = DateTime.now();

    final temporalMode = _temporalModeFor(
      selectedDay: _selectedDay,
      realNow: observedAt,
    );

    final isNowMode = temporalMode == CalendarTemporalMode.now;
    final isDayOverviewMode = temporalMode == CalendarTemporalMode.dayOverview;

    final familyDayOverviewSnapshot = isDayOverviewMode
        ? _buildFamilyDayOverviewSnapshot()
        : null;

    assert(!isDayOverviewMode || familyDayOverviewSnapshot != null);

    final familyDayOverviewViewModel = familyDayOverviewSnapshot != null
        ? const FamilyDayOverviewViewModelBuilder().build(
            familyDayOverviewSnapshot,
          )
        : null;

    final familyNowSnapshot = isNowMode
        ? _buildFamilyNowSnapshot(observedAt: observedAt)
        : null;

    final cov = _buildDayCoverage(day: _selectedDay, observedAt: observedAt);
    final aliceHomeRisk = const AliceHomeRiskViewModelBuilder().build(
      gapDetails: cov.gapDetails,
      selectedDay: _selectedDay,
      observedAt: observedAt,
    );
    final isEmergency = _isEmergencyActive();
    final showSummerCampSpecialCard = AliceSchoolDayViewModelBuilder(coreStore)
        .build(day: _selectedDay, expandedEventIds: _expandedAliceEventIds)
        .showSummerCampSpecialCard;
    final selectedDayTiming = EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(_selectedDay);
    final summerCampLogistics = _summerCampLogisticsViewModel(
      operational: showSummerCampSpecialCard,
      effectiveStart: selectedDayTiming.schoolEntryAt,
      effectiveEnd: selectedDayTiming.schoolExitAt,
    );
    final selectedDayLogisticEvents = coreStore.aliceSpecialEventStore
        .eventsForDay(_onlyDate(_selectedDay))
        .where((event) => event.behavior == AliceEventBehavior.logistic)
        .toList();
    final selectedDayEventLogistics = _aliceEventLogisticsResolutions(
      day: _onlyDate(_selectedDay),
      events: selectedDayLogisticEvents,
      logisticsAvailability: _coverageInputs(
        _onlyDate(_selectedDay),
      ).logisticsAvailability,
    );
    final selectedDayLogisticsStatus = _aliceLogisticsStatusBuilder.build(
      resolutions: selectedDayEventLogistics,
    );
    final dayStatus = _calendarDayStatusBuilder.build(
      gapDetails: cov.gapDetails,
      criticalityDetails: cov.criticalityDetails,
      hasLogisticGaps:
          selectedDayLogisticsStatus.hasLogisticConflict ||
          selectedDayLogisticsStatus.hasIncompleteLogistics ||
          (summerCampLogistics?.hasLogisticGaps ?? false),
    );
    final dayStatusColor = _calendarDayStatusVisualPresenter.colorFor(
      dayStatus,
    );
    final ipsCoverage30 = _computeIpsCoverage30();

    final familyNowViewModel = familyNowSnapshot != null
        ? const FamilyNowViewModelBuilder().build(
            familyNowSnapshot,
            isEmergency: isEmergency,
          )
        : null;

    final selectedDayEvents = isNowMode
        ? coreStore.realEventStore.eventsForDay(_selectedDay)
        : const <RealEvent>[];

    final adultDetailsBuilder = const FamilyAdultNowDetailsBuilder();

    final matteoDetails =
        familyNowSnapshot != null && familyNowViewModel != null
        ? adultDetailsBuilder.build(
            name: 'Matteo',
            personKey: 'matteo',
            day: _selectedDay,
            now: familyNowSnapshot.now,
            nowLabel: familyNowViewModel.matteo.label,
            turnLabel:
                familyNowViewModel.matteo.turnLabel ?? 'Turno non previsto',
            visual: familyNowViewModel.matteo.visual,
            events: selectedDayEvents,
          )
        : null;

    final chiaraDetails =
        familyNowSnapshot != null && familyNowViewModel != null
        ? adultDetailsBuilder.build(
            name: 'Chiara',
            personKey: 'chiara',
            day: _selectedDay,
            now: familyNowSnapshot.now,
            nowLabel: familyNowViewModel.chiara.label,
            turnLabel:
                familyNowViewModel.chiara.turnLabel ?? 'Turno non previsto',
            visual: familyNowViewModel.chiara.visual,
            events: selectedDayEvents,
          )
        : null;

    final aliceDayContext = isNowMode
        ? AliceDayContextBuilder(coreStore).build(_selectedDay)
        : null;

    final aliceDetails =
        familyNowSnapshot != null &&
            familyNowViewModel != null &&
            aliceDayContext != null
        ? const AliceNowDetailsBuilder().build(
            context: aliceDayContext,
            day: _selectedDay,
            now: familyNowSnapshot.now,
            nowLabel: familyNowViewModel.alice.label,
            visual: familyNowViewModel.alice.visual,
          )
        : null;

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
                  color: dayStatusColor,
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
            if (isDayOverviewMode)
              FamilyDayOverviewCard(model: familyDayOverviewViewModel!)
            else
              FamilyNowCard(
                model: familyNowViewModel!,
                realNow: familyNowSnapshot!.realNow,
                onTapMatteo: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return FamilyAdultNowDialog(model: matteoDetails!);
                    },
                  );
                },
                onTapChiara: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return FamilyAdultNowDialog(model: chiaraDetails!);
                    },
                  );
                },
                onTapAlice: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AliceNowDialog(model: aliceDetails!);
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
              observedAt: observedAt,
              aliceHomeRisk: aliceHomeRisk,
              showSummerCampSpecialCard: showSummerCampSpecialCard,
              isEmergency: isEmergency,
              aliceEventLogistics: selectedDayEventLogistics,
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

  Widget _cardTurni({required DateTime observedAt}) {
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

    final matteoIsInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.matteo,
      _onlyDate(_selectedDay),
    );

    final matteoEffectiveStatus = _personEffectiveStatusBuilder.build(
      manualOverride: ov.matteo,
      diseasePeriod: matteoDisease,
      isInHolidayPeriod: matteoIsInHolidayPeriod,
    );

    final chiaraDisease = coreStore.diseasePeriodStore.getPeriodForDay(
      'chiara',
      _onlyDate(_selectedDay),
    );

    final chiaraIsInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      FeriePerson.chiara,
      _onlyDate(_selectedDay),
    );

    final chiaraEffectiveStatus = _personEffectiveStatusBuilder.build(
      manualOverride: ov.chiara,
      diseasePeriod: chiaraDisease,
      isInHolidayPeriod: chiaraIsInHolidayPeriod,
    );

    final matteoIsBedSick = matteoEffectiveStatus.isBedSick;

    final chiaraIsBedSick = chiaraEffectiveStatus.isBedSick;

    final matteoIsSick = matteoEffectiveStatus.isSick;

    final chiaraIsSick = chiaraEffectiveStatus.isSick;

    final matteoDay = turnDayBuilder.buildPerson(
      person: TurnPerson.matteo,
      personKey: 'matteo',
      displayName: 'Matteo',
      day: _selectedDay,
      plan: m,
      turnSummary: _turnPresentationStateBuilder.summaryFor(m),
      manualOverride: ov.matteo,
      diseasePeriod: matteoDisease,
      turnOverrideStatusText: matteoSourceResult.turnOverrideStatusText,
      sourceText: matteoSourceResult.sourceText,
      sourceKind: matteoSourceResult.sourceKind,
      isManualShiftChange: matteoSourceResult.isManualShiftChange,
      observedAt: observedAt,
      isOnHoliday: matteoEffectiveStatus.isOnHoliday,
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
      turnSummary: _turnPresentationStateBuilder.summaryFor(c),
      manualOverride: ov.chiara,
      diseasePeriod: chiaraDisease,
      turnOverrideStatusText: chiaraSourceResult.turnOverrideStatusText,
      sourceText: chiaraSourceResult.sourceText,
      sourceKind: chiaraSourceResult.sourceKind,
      isManualShiftChange: chiaraSourceResult.isManualShiftChange,
      observedAt: observedAt,
      isOnHoliday: chiaraEffectiveStatus.isOnHoliday,
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
              observedAt: observedAt,
            ),
            const SizedBox(height: 12),
          ],
          if (turnDay.chiara.conflicts.isNotEmpty) ...[
            _turnEventConflictBox(
              personName: turnDay.chiara.displayName,
              personKey: turnDay.chiara.personKey,
              conflicts: turnDay.chiara.conflicts,
              observedAt: observedAt,
            ),
            const SizedBox(height: 12),
          ],
          if (turnDay.familyEvents.isNotEmpty) ...[
            _familyEventsBlock(turnDay.familyEvents),
            const SizedBox(height: 12),
          ],
          _turnRow(
            turnDay.matteo.displayName,
            turnDay.matteo.presentation,
            observedAt: observedAt,
            events: turnDay.matteo.events,
            conflicts: turnDay.matteo.conflicts,
          ),
          const SizedBox(height: 10),
          _turnRow(
            turnDay.chiara.displayName,
            turnDay.chiara.presentation,
            observedAt: observedAt,
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
    required DateTime observedAt,
  }) {
    final override = overrideStore.getForDay(_selectedDay);

    final personOverride = personKey == "matteo"
        ? override.matteo
        : override.chiara;

    final disease = coreStore.diseasePeriodStore.getPeriodForDay(
      personKey,
      _selectedDay,
    );

    final feriePerson = personKey == 'matteo'
        ? FeriePerson.matteo
        : FeriePerson.chiara;

    final isInHolidayPeriod = coreStore.feriePeriodStore.isOnHoliday(
      feriePerson,
      _onlyDate(_selectedDay),
    );

    final effectiveStatus = _personEffectiveStatusBuilder.build(
      manualOverride: personOverride,
      diseasePeriod: disease,
      isInHolidayPeriod: isInHolidayPeriod,
    );

    final isBedSick = effectiveStatus.isBedSick;

    final visibleConflicts = conflicts.visibleAt(
      selectedDay: _selectedDay,
      now: observedAt,
    );

    if (visibleConflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    final worst = conflicts.worstState;

    final isForced = _isForcedConflict(
      personKey: personKey,
      conflicts: conflicts,
    );

    final visualState = _turnEventConflictVisualStateBuilder.build(
      worst: worst,
      isForced: isForced,
      isBedSick: isBedSick,
      personName: personName,
    );

    final color = visualState.color;

    final String title = visualState.title;
    final String subtitle = visualState.subtitle;

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
                        "Stato: ${effectiveConflictStateLabel(state: r.state, isForced: isForced)}",
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
    TurnPresentationState presentation, {
    required DateTime observedAt,
    List<RealEvent> events = const [],
    List<TurnEventConflictResolution> conflicts = const [],
  }) {
    final visibleEvents = _turnUiObservationFilter.visibleEvents(
      events: events,
      selectedDay: _selectedDay,
      observedAt: observedAt,
    );

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
                    "${presentation.turnLabel} • ${presentation.timeLabel}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (presentation.statusText != null &&
                      presentation.statusText!.isNotEmpty)
                    Text(
                      "• Stato: ${presentation.statusText}",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _turnStatusColor(presentation.statusTone),
                      ),
                    ),
                  if (presentation.sourceText != null &&
                      presentation.sourceText!.isNotEmpty)
                    Text(
                      "• ${presentation.sourceText}",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _turnSourceColor(presentation.sourceTone),
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
                    presentation.isBedSick
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
    final model = AliceSchoolDayViewModelBuilder(
      coreStore,
    ).build(day: _selectedDay, expandedEventIds: _expandedAliceEventIds);
    final uscitaAt = model.hasEarlySchoolExit
        ? EffectiveSchoolDayTimingReader(
            coreStore,
          ).read(_selectedDay).earlySchoolExitAt
        : null;
    final uscita13Eff = model.hasEarlySchoolExit;
    final extraEvents = model.events;
    final visibleAliceEvents = model.visibleEvents;
    final hasExtraEvents = extraEvents.isNotEmpty;
    final summerCampLogistics = _summerCampLogisticsViewModel(
      operational: model.showSummerCampSpecialCard,
      effectiveStart: model.schoolEntryAt,
      effectiveEnd: model.schoolExitAt,
    );

    return _card(
      title: model.title,
      subtitle: model.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AliceStateBanner(
            label: model.stateLabel,
            color: model.stateColor,
            icon: model.stateIcon,
            periodLabel: model.periodLabel,
            periodColor: model.periodColor,
            periodIcon: model.periodIcon,
          ),

          AliceSchoolHeader(
            orario: model.schoolHoursLabel,
            uscitaAnticipata: uscita13Eff,
          ),

          if (model.hasEventConflict) ...[const AliceEventConflictBanner()],

          AliceEventsSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AliceEventsHeader(
                  hasExtraEvents: hasExtraEvents,
                  extraEventsCount: model.events.length,
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
                      children: visibleAliceEvents.map((eventModel) {
                        final e = eventModel.event;
                        final tileModel = eventModel.tile;
                        return AliceEventTile(
                          model: tileModel,
                          onTap: () => _toggleAliceEventExpanded(tileModel.id),
                          expandedChild: tileModel.isExpanded
                              ? AliceEventExpanded(
                                  event: e,
                                  conflictWith: eventModel.conflictWith,
                                  categoryLabel: (_) =>
                                      eventModel.tile.categoryLabel,
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
            hiddenCount: model.hiddenEventsCount,
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
                          children: extraEvents.map((eventModel) {
                            final e = eventModel.event;
                            final isConflict = eventModel.tile.isConflict;
                            final conflictWith = eventModel.conflictWith;

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
                                        eventModel.tile.categoryIcon,
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
                                    eventModel.categoryText,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.72),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    eventModel.timeText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (eventModel.noteText != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      eventModel.noteText!,
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
                    items: model.categoryOptions.map((option) {
                      return DropdownMenuItem(
                        value: option.value,
                        child: Row(
                          children: [
                            Icon(option.icon, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(option.label)),
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
            schoolPeriodLabel: model.schoolPeriodLabel,
            isSchoolDayActive: model.isSchoolDayActive,
            schoolWeekdayLabel: model.schoolWeekdayLabel,
            accompagnamento: model.accompanimentStart,
            ingressoReale: model.schoolEntryAt,
            uscitaReale: model.schoolExitAt,
            uscitaFine: model.schoolExitWindowEnd,
            onOpenSchoolPanel: _openSchoolPanel,
          ),
          SchoolOutSummary(
            visible: !uscita13Eff,
            outStart: model.schoolOutStart,
            outEnd: model.schoolOutEnd,
            hasCustomOut: model.hasCustomSchoolOut,
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          if (summerCampLogistics != null)
            SummerCampLogisticsSection(
              model: summerCampLogistics,
              onDropOffChanged: (provider) =>
                  _saveSummerCampLogistics(AliceLogisticLeg.dropOff, provider),
              onPickUpChanged: (provider) =>
                  _saveSummerCampLogistics(AliceLogisticLeg.pickUp, provider),
            )
          else
            SchoolCoverageChoiceSection(
              ingressoInizio: model.accompanimentStart,
              ingressoFine: model.schoolEntryAt,
              uscitaReale: model.schoolExitAt,
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

  AliceSummerCampLogisticsViewModel? _summerCampLogisticsViewModel({
    required bool operational,
    required TimeOfDay effectiveStart,
    required TimeOfDay effectiveEnd,
  }) {
    final day = _onlyDate(_selectedDay);
    DateTime at(TimeOfDay time) =>
        DateTime(day.year, day.month, day.day, time.hour, time.minute);
    final logisticsAvailability = _coverageInputs(day).logisticsAvailability;
    final availability = _aliceLogisticProviderAvailabilityResolver(
      logisticsAvailability,
    );
    final result =
        AliceSummerCampLogisticsCoordinator(
          daySettingsStore: daySettingsStore,
          availabilityResolver: availability,
        ).resolveDay(
          day: day,
          summerCampOperational: operational,
          effectiveStart: at(effectiveStart),
          effectiveEnd: at(effectiveEnd),
          overrides: _getOverridesForDay(day),
          ferieStore: coreStore.feriePeriodStore,
        );
    return const AliceSummerCampLogisticsViewModelBuilder().build(
      result: result,
      supportPeople: coreStore.supportNetworkStore.people,
    );
  }

  AliceLogisticProviderAvailabilityResolver
  _aliceLogisticProviderAvailabilityResolver(
    CalendarLogisticsAvailabilityResult logisticsAvailability,
  ) => AliceLogisticProviderAvailabilityResolver(
    adultResolver: AdultLogisticsAvailabilityResolver(
      turnEngine: coreStore.turnEngine,
      diseasePeriodStore: coreStore.diseasePeriodStore,
      realEventStore: coreStore.realEventStore,
    ),
    logisticsAvailability: logisticsAvailability,
  );

  List<AliceEventLogisticsResolution> _aliceEventLogisticsResolutions({
    required DateTime day,
    required List<AliceSpecialEvent> events,
    required CalendarLogisticsAvailabilityResult logisticsAvailability,
  }) {
    final coordinator = AliceEventLogisticsCoordinator(
      availabilityResolver: _aliceLogisticProviderAvailabilityResolver(
        logisticsAvailability,
      ),
    );
    return events
        .map(
          (event) => coordinator.resolve(
            day: day,
            event: event,
            overrides: _getOverridesForDay(day),
            ferieStore: coreStore.feriePeriodStore,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _saveSummerCampLogistics(
    AliceLogisticLeg leg,
    AliceLogisticProviderRef? provider,
  ) async {
    if (leg == AliceLogisticLeg.dropOff) {
      await daySettingsStore.setSummerCampDropOffProviderForDay(
        _selectedDay,
        provider,
      );
    } else {
      await daySettingsStore.setSummerCampPickUpProviderForDay(
        _selectedDay,
        provider,
      );
    }
    if (!mounted) return;
    setState(() {});
    ipsStore.refresh(now: _selectedDay);
  }

  SandraCoverageViewModel _buildSandraCoverageViewModel() {
    final sandraDecision = _sandraDecisionForDay(_selectedDay);
    return SandraCoverageViewModel(
      decision: sandraDecision,
      manualMattina: daySettingsStore.sandraMattinaForDay(_selectedDay) == true,
      manualPranzo: daySettingsStore.sandraPranzoForDay(_selectedDay) == true,
      manualSera: daySettingsStore.sandraSeraForDay(_selectedDay) == true,
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

  Widget _buildCoverageGapRecommendationsPanel(CoverageResultStepA cov) {
    final resolutions = cov.gapDetails
        .map(_resolveCompanions)
        .toList(growable: false);
    final model = _gapRecommendationViewModelBuilder.buildAll(
      day: _selectedDay,
      gaps: cov.gapDetails,
      resolutions: resolutions,
    );
    return CoverageGapRecommendationsPanel(model: model);
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
                    onPressed: () async {
                      final updatedDay = current.copyWith(
                        enabled: active,
                        entryMinutes: ingresso.hour * 60 + ingresso.minute,
                        exitRealMinutes: uscita.hour * 60 + uscita.minute,
                      );

                      final updatedPeriod = buildUpdatedPeriod(updatedDay);

                      final navigator = Navigator.of(context);
                      await coreStore.schoolStore.updatePeriod(updatedPeriod);
                      if (!mounted || !navigator.mounted) return;
                      setState(() {});
                      navigator.pop(); // chiude popup giorno
                      navigator.pop(); // chiude popup settimana
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
                                          onPressed: () async {
                                            await coreStore.schoolStore
                                                .removePeriod(p.id);
                                            if (!mounted) return;
                                            setState(() {});
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
                                          onPressed: () async {
                                            if (nameController.text
                                                    .trim()
                                                    .isEmpty ||
                                                startDate == null ||
                                                endDate == null) {
                                              return;
                                            }

                                            final navigator = Navigator.of(
                                              context,
                                            );
                                            await coreStore.schoolStore.addPeriod(
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
                                            if (!mounted ||
                                                !navigator.mounted) {
                                              return;
                                            }
                                            setState(() {});
                                            navigator.pop();
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
