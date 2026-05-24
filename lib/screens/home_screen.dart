// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import '../logic/ips_store.dart';

import '../logic/settings_store.dart';
import '../models/ips_snapshot.dart' as snap;
import '../models/promemoria.dart';
import '../models/finance_fund.dart';
import '../models/finance_recurring_item.dart';
import 'calendario_screen_stepa.dart';
import 'copertura_screen.dart';
import 'dashboard.dart';

import 'salute_screen.dart';

import '../logic/coverage_engine.dart';
import '../logic/day_settings_store.dart';
import 'statistiche_screen.dart';
import '../widgets/home_people_panel.dart';
import '../stores/finance_store.dart';

import '../widgets/finance/finance_time_item_card.dart';
import '../models/fund_transaction.dart';
import 'package:intl/intl.dart';
import '../widgets/finance/finance_year_dashboard.dart';
import '../widgets/finance/finance_month_detail_dialog.dart';
import '../widgets/finance/finance_pressure_summary_card.dart';

import '../widgets/home/home_overview_metrics.dart';
import '../widgets/shared/mini_action_chip.dart';
import '../widgets/home/coverage_quick_actions_box.dart';

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
  CoverageEngine get _engine => coreStore.coverageEngine;

  final FinanceStore financeStore = FinanceStore();

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    await financeStore.loadInitialRealData();

    financeStore.saveSnapshot(DateTime.now());

    if (mounted) {
      setState(() {});
    }
  }

  String _actionLabelFromModule(snap.IpsModule module) {
    switch (module) {
      case snap.IpsModule.coverage:
        return "RISOLVI";
      case snap.IpsModule.finance:
        return "Controlla finanze";
      case snap.IpsModule.health:
        return "Apri salute";
      case snap.IpsModule.auto:
        return "Controlla auto";
      default:
        return "Apri dettaglio";
    }
  }

  String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  bool _isSchoolInGapLabel(dynamic label) {
    final l = label.toString().toLowerCase();

    return l.contains("ingresso") ||
        l.contains("accompagnamento") ||
        l.contains("scuola");
  }

  bool _isSchoolOutGapLabel(dynamic label) {
    final l = label.toString().toLowerCase();

    return l.contains("uscita") ||
        l.contains("ritiro") ||
        l.contains("rientro");
  }

  bool _isLunchGapLabel(dynamic label) {
    final l = label.toString().toLowerCase();

    return l.contains("pranzo") || l.contains("uscita anticipata");
  }

  List<CoverageGapDetail> _todayCoverageDetails() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final rawDetails = coreStore.coverageEngine.aliceHomeRiskDetailsForDay(
      day: today,
      uscita13:
          coreStore.daySettingsStore.uscita13ForDay(today) ??
          settingsStore.isUscita13,
      sandraMattinaOn:
          coreStore.daySettingsStore.sandraMattinaForDay(today) ?? false,
      sandraPranzoOn:
          coreStore.daySettingsStore.sandraPranzoForDay(today) ?? false,
      sandraSeraOn: coreStore.daySettingsStore.sandraSeraForDay(today) ?? false,
      schoolStart: TimeOfDay(
        hour:
            (coreStore.schoolStore.schoolDayConfigFor(today)?.entryMinutes ??
                505) ~/
            60,
        minute:
            (coreStore.schoolStore.schoolDayConfigFor(today)?.entryMinutes ??
                505) %
            60,
      ),
      overrides: coreStore.overrideStore.getEffectiveForDay(
        day: today,
        ferieStore: coreStore.feriePeriodStore,
      ),
      ferieStore: coreStore.feriePeriodStore,
      schoolInCover: coreStore.daySettingsStore.schoolInCoverForDay(today),
      schoolOutCover: coreStore.daySettingsStore.schoolOutCoverForDay(today),
      schoolOutStart:
          coreStore.daySettingsStore.schoolOutStartForDay(today) ??
          const TimeOfDay(hour: 16, minute: 25),
      schoolOutEnd:
          coreStore.daySettingsStore.schoolOutEndForDay(today) ??
          const TimeOfDay(hour: 16, minute: 45),
      lunchCover: coreStore.daySettingsStore.lunchCoverForDay(today),
      uscitaAnticipataAt: coreStore.daySettingsStore.uscitaAnticipataTimeForDay(
        today,
      ),
    );

    return rawDetails.where((detail) {
      final gapStart = DateTime(
        today.year,
        today.month,
        today.day,
        detail.start.hour,
        detail.start.minute,
      );

      final gapEnd = DateTime(
        today.year,
        today.month,
        today.day,
        detail.end.hour,
        detail.end.minute,
      );

      for (final person in coreStore.supportNetworkStore.people) {
        if (!person.enabled) continue;

        final enabledForDay = coreStore.daySettingsStore
            .isSupportPersonEnabledForDay(today, person.id);

        if (!enabledForDay) continue;

        final supportStart = DateTime(
          today.year,
          today.month,
          today.day,
          person.start.hour,
          person.start.minute,
        );

        final supportEnd = DateTime(
          today.year,
          today.month,
          today.day,
          person.end.hour,
          person.end.minute,
        );

        final covers =
            !supportStart.isAfter(gapStart) && !supportEnd.isBefore(gapEnd);

        if (covers) return false;
      }

      return true;
    }).toList();
  }

  _HomeCoverageIssue? _relevantCoverageIssueFromNow() {
    return _todayCoverageIssueFromNow() ?? _futureCoverageIssueFromTomorrow();
  }

  _HomeCoverageIssue? _todayCoverageIssueFromNow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final nowTime = TimeOfDay.now();
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;

    final details = _todayCoverageDetails().where((detail) {
      final endMinutes = detail.end.hour * 60 + detail.end.minute;
      return endMinutes > nowMinutes;
    }).toList();

    if (details.isEmpty) return null;

    details.sort((a, b) {
      final aStart = a.start.hour * 60 + a.start.minute;
      final bStart = b.start.hour * 60 + b.start.minute;
      return aStart.compareTo(bStart);
    });

    return _HomeCoverageIssue(day: today, details: details);
  }

  _HomeCoverageIssue? _futureCoverageIssueFromTomorrow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool supportCoversRange({
      required DateTime day,
      required TimeOfDay start,
      required TimeOfDay end,
    }) {
      final d0 = DateTime(day.year, day.month, day.day);

      final rangeStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        start.hour,
        start.minute,
      );

      final rangeEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        end.hour,
        end.minute,
      );

      for (final person in coreStore.supportNetworkStore.people) {
        if (!person.enabled) continue;

        final enabledForDay = coreStore.daySettingsStore
            .isSupportPersonEnabledForDay(d0, person.id);

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
            !supportStart.isAfter(rangeStart) && !supportEnd.isBefore(rangeEnd);

        if (coversFullRange) return true;
      }

      return false;
    }

    for (int i = 1; i <= 30; i++) {
      final day = today.add(Duration(days: i));
      final d0 = DateTime(day.year, day.month, day.day);

      final uscitaAt = coreStore.daySettingsStore.uscitaAnticipataTimeForDay(
        d0,
      );

      final uscita13Eff = uscitaAt != null;

      final cfg = coreStore.schoolStore
          .activePeriodForDay(d0)
          ?.weekConfig
          .forWeekday(d0.weekday);

      final schoolStart = TimeOfDay(
        hour: (cfg?.entryMinutes ?? 505) ~/ 60,
        minute: (cfg?.entryMinutes ?? 505) % 60,
      );

      final ingressoInizio = TimeOfDay(
        hour: ((schoolStart.hour * 60 + schoolStart.minute - 20) ~/ 60) % 24,
        minute: (schoolStart.hour * 60 + schoolStart.minute - 20) % 60,
      );

      final schoolOutStart =
          coreStore.daySettingsStore.schoolOutStartForDay(d0) ??
          TimeOfDay(
            hour: (cfg?.exitRealMinutes ?? 985) ~/ 60,
            minute: (cfg?.exitRealMinutes ?? 985) % 60,
          );

      final schoolOutEnd =
          coreStore.daySettingsStore.schoolOutEndForDay(d0) ??
          TimeOfDay(
            hour: (cfg?.returnHomeMinutes ?? 1035) ~/ 60,
            minute: (cfg?.returnHomeMinutes ?? 1035) % 60,
          );

      final savedSchoolInCover = coreStore.daySettingsStore.schoolInCoverForDay(
        d0,
      );

      final savedSchoolOutCover = coreStore.daySettingsStore
          .schoolOutCoverForDay(d0);

      final savedLunchCover = coreStore.daySettingsStore.lunchCoverForDay(d0);

      final supportCoversIn = supportCoversRange(
        day: d0,
        start: ingressoInizio,
        end: schoolStart,
      );

      final supportCoversOut = supportCoversRange(
        day: d0,
        start: schoolOutStart,
        end: schoolOutEnd,
      );

      final supportCoversLunch =
          uscitaAt != null &&
          supportCoversRange(
            day: d0,
            start: uscitaAt,
            end: _engine.sandraPranzoEnd,
          );

      final schoolInCover = savedSchoolInCover != SchoolCoverChoice.none
          ? savedSchoolInCover
          : supportCoversIn
          ? SchoolCoverChoice.altro
          : SchoolCoverChoice.none;

      final schoolOutCover = savedSchoolOutCover != SchoolCoverChoice.none
          ? savedSchoolOutCover
          : supportCoversOut
          ? SchoolCoverChoice.altro
          : SchoolCoverChoice.none;

      final lunchCover = savedLunchCover != SchoolCoverChoice.none
          ? savedLunchCover
          : supportCoversLunch
          ? SchoolCoverChoice.altro
          : SchoolCoverChoice.none;

      final analysis = _engine.analyzeDay(
        day: d0,
        uscita13: uscita13Eff,
        sandraAvailable:
            (coreStore.daySettingsStore.sandraMattinaForDay(d0) ?? false) ||
            (coreStore.daySettingsStore.sandraPranzoForDay(d0) ?? false) ||
            (coreStore.daySettingsStore.sandraSeraForDay(d0) ?? false),
        overrides: coreStore.overrideStore.getEffectiveForDay(
          day: d0,
          ferieStore: coreStore.feriePeriodStore,
        ),
        ferieStore: coreStore.feriePeriodStore,
        schoolInCover: schoolInCover,
        schoolOutCover: schoolOutCover,
        schoolOutStart: schoolOutStart,
        schoolOutEnd: schoolOutEnd,
        lunchCover: lunchCover,
        uscitaAnticipataAt: uscitaAt,
      );

      final filteredDetails = analysis.details.where((d) {
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

      if (filteredDetails.isNotEmpty) {
        filteredDetails.sort((a, b) {
          final aStart = a.start.hour * 60 + a.start.minute;
          final bStart = b.start.hour * 60 + b.start.minute;
          return aStart.compareTo(bStart);
        });

        return _HomeCoverageIssue(day: d0, details: filteredDetails);
      }
    }

    return null;
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

  Future<void> _openCalendarForDay(DateTime day) async {
    final cleanDay = DateTime(day.year, day.month, day.day);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalendarioScreenStepAStabile(
          coreStore: coreStore,
          initialSelectedDay: cleanDay,
        ),
      ),
    );

    ipsStore.refresh();
    if (mounted) setState(() {});
  }

  DateTime _firstCoverageProblemDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 30; i++) {
      final day = today.add(Duration(days: i));
      final details = ipsStore.coverage.realGapDetailsForDay(day);

      if (details.isNotEmpty) {
        return day;
      }
    }

    return today;
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

    return _getAllEventsForDay(selectedDay);
  }

  List<_HomeEvent> _getAllEventsForDay(DateTime day) {
    final List<_HomeEvent> items = [];

    final realEvents = coreStore.realEventStore.eventsForDay(day);

    for (final e in realEvents) {
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

      items.add(
        _HomeEvent(
          id: e.id,
          time: time,
          title: e.title,
          category: category,
          source: "real",
          participants: e.effectiveParticipantKeys.map((key) {
            switch (key) {
              case "matteo":
                return "Matteo";
              case "chiara":
                return "Chiara";
              case "alice":
                return "Alice";
              case "sandra":
                return "Sandra";
              case "family":
                return "Famiglia";
              default:
                return key;
            }
          }).toList(),
          ipsImpact: true,
          notes: e.notes,
        ),
      );
    }

    final aliceEvents = coreStore.aliceSpecialEventStore
        .eventsForDay(day)
        .where((event) => event.enabled)
        .toList();

    for (final e in aliceEvents) {
      final sh = e.start.hour.toString().padLeft(2, '0');
      final sm = e.start.minute.toString().padLeft(2, '0');
      final eh = e.end.hour.toString().padLeft(2, '0');
      final em = e.end.minute.toString().padLeft(2, '0');

      items.add(
        _HomeEvent(
          id: e.id,
          time: "$sh:$sm-$eh:$em",
          title: e.label,
          category: "Alice",
          source: "alice",
          participants: const ["Alice"],
          ipsImpact: true,
          notes: e.note,
        ),
      );
    }

    items.sort((a, b) => a.time.compareTo(b.time));

    return items;
  }

  List<_HomeDay> _buildNext7DaysReal() {
    final now = DateTime.now();
    final List<_HomeDay> result = [];

    final endOfYear = DateTime(now.year, 12, 31);
    final daysToScan = endOfYear
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    for (int i = 1; i <= daysToScan; i++) {
      final day = now.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);

      final mappedEvents = _getAllEventsForDay(dayKey);

      if (mappedEvents.isEmpty) continue;

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
      title: "Eventi globali",
      subtitle: "Eventi futuri fino a fine anno",
      child: _buildNext7DaysDialogContent(next7Days: next7Days),
    );
  }

  Future<void> _showYearMonthsPopup({required int year}) async {
    final months = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    final monthIndexMap = {
      "Gennaio": 1,
      "Febbraio": 2,
      "Marzo": 3,
      "Aprile": 4,
      "Maggio": 5,
      "Giugno": 6,
      "Luglio": 7,
      "Agosto": 8,
      "Settembre": 9,
      "Ottobre": 10,
      "Novembre": 11,
      "Dicembre": 12,
    };

    await _showHomeDialog(
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF43A047),
      title: "$year",
      subtitle: "Scegli un mese",
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
        children: months.map((m) {
          final monthIndex = monthIndexMap[m]!;

          int eventCount = 0;
          final end = DateTime(year, monthIndex + 1, 0);

          for (int i = 0; i < end.day; i++) {
            final day = DateTime(year, monthIndex, i + 1);
            eventCount += coreStore.realEventStore.eventsForDay(day).length;
          }

          final hasEvents = eventCount > 0;

          return InkWell(
            onTap: hasEvents
                ? () {
                    _showMonthEventsPopup(year: year, monthName: m);
                  }
                : null,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasEvents
                      ? [
                          const Color(0xFF43A047).withOpacity(0.28),
                          const Color(0xFF8BC34A).withOpacity(0.12),
                        ]
                      : [
                          Colors.white.withOpacity(0.28),
                          Colors.white.withOpacity(0.12),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: hasEvents
                      ? const Color(0xFF43A047).withOpacity(0.42)
                      : Colors.white.withOpacity(0.28),
                ),
                boxShadow: [
                  if (hasEvents)
                    BoxShadow(
                      color: const Color(0xFF43A047).withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasEvents
                        ? Icons.event_available_rounded
                        : Icons.calendar_month_outlined,
                    size: 22,
                    color: hasEvents
                        ? const Color(0xFF2E7D32)
                        : Colors.black.withOpacity(0.25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: hasEvents
                          ? Colors.black.withOpacity(0.86)
                          : Colors.black.withOpacity(0.35),
                    ),
                  ),
                  if (hasEvents)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    eventCount == 1 ? "1 evento" : "$eventCount eventi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: hasEvents
                          ? Colors.black.withOpacity(0.62)
                          : Colors.black.withOpacity(0.28),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _eventCountForYear(int year) {
    int count = 0;

    for (final event in coreStore.realEventStore.allEvents) {
      final startYear = event.startDate.year;
      final endYear = event.endDate.year;

      if (startYear <= year && endYear >= year) {
        count++;
      }
    }

    for (final day in coreStore.aliceSpecialEventStore.allDates()) {
      if (day.year != year) continue;

      count += coreStore.aliceSpecialEventStore
          .eventsForDay(day)
          .where((event) => event.enabled)
          .length;
    }

    return count;
  }

  Future<void> _showFutureYearsPopup() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear + index + 1);

    await _showHomeDialog(
      icon: Icons.auto_awesome_motion_rounded,
      color: const Color(0xFF5E35B1),
      title: "Eventi futuri",
      subtitle: "Anni successivi al $currentYear",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: years.map((year) {
          final count = _eventCountForYear(year);
          final hasEvents = count > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildGlobalEventEntryCard(
              icon: Icons.calendar_month_rounded,
              title: "$year ($count)",
              subtitle: hasEvents
                  ? "Apri gli eventi del $year"
                  : "Nessun evento inserito",
              color: hasEvents ? const Color(0xFF5E35B1) : Colors.grey,
              onTap: hasEvents
                  ? () {
                      _showYearEventsPopup(year: year);
                    }
                  : () {},
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showPastYearsPopup() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - index - 1);

    await _showHomeDialog(
      icon: Icons.history_rounded,
      color: const Color(0xFF8D6E63),
      title: "Eventi passati",
      subtitle: "Archivio degli anni precedenti",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: years.map((year) {
          final count = _eventCountForYear(year);
          final hasEvents = count > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildGlobalEventEntryCard(
              icon: Icons.history_rounded,
              title: "$year ($count)",
              subtitle: hasEvents
                  ? "Apri gli eventi del $year"
                  : "Nessun evento archiviato",
              color: hasEvents ? const Color(0xFF8D6E63) : Colors.grey,
              onTap: hasEvents
                  ? () {
                      _showYearEventsPopup(year: year);
                    }
                  : () {},
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showYearEventsPopup({required int year}) async {
    await _showHomeDialog(
      icon: Icons.event_note_rounded,
      color: const Color(0xFF5E35B1),
      title: "$year",
      subtitle: "Eventi dell’anno",
      child: StatefulBuilder(
        builder: (context, dialogSetState) {
          final List<_HomeEvent> events = [];

          final start = DateTime(year, 1, 1);
          final end = DateTime(year, 12, 31);

          DateTime cursor = start;

          while (!cursor.isAfter(end)) {
            final dayEvents = _getAllEventsForDay(cursor);

            for (final e in dayEvents) {
              events.add(
                _HomeEvent(
                  id: e.id,
                  time:
                      "${cursor.day}/${cursor.month}/${cursor.year} • ${e.time}",
                  title: e.title,
                  category: e.category,
                  source: e.source,
                  participants: e.participants,
                  ipsImpact: e.ipsImpact,
                  notes: e.notes,
                ),
              );
            }

            cursor = cursor.add(const Duration(days: 1));
          }

          return events.isEmpty
              ? _buildDialogEmptyState(
                  icon: Icons.event_note_rounded,
                  title: "Nessun evento",
                  subtitle: "Non ci sono eventi in questo anno",
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildEventsGroupedByDay(
                    events,
                    onSaved: () {
                      dialogSetState(() {});
                    },
                  ),
                );
        },
      ),
    );
  }

  Future<void> _showMonthEventsPopup({
    required int year,
    required String monthName,
  }) async {
    await _showHomeDialog(
      icon: Icons.event_note_rounded,
      color: const Color(0xFF43A047),
      title: "$monthName $year",
      subtitle: "Eventi del mese",
      child: StatefulBuilder(
        builder: (context, dialogSetState) {
          final monthIndex = {
            "Gennaio": 1,
            "Febbraio": 2,
            "Marzo": 3,
            "Aprile": 4,
            "Maggio": 5,
            "Giugno": 6,
            "Luglio": 7,
            "Agosto": 8,
            "Settembre": 9,
            "Ottobre": 10,
            "Novembre": 11,
            "Dicembre": 12,
          }[monthName]!;

          final List<_HomeEvent> events = [];

          final end = DateTime(year, monthIndex + 1, 0);

          for (int i = 0; i < end.day; i++) {
            final day = DateTime(year, monthIndex, i + 1);
            final dayEvents = _getAllEventsForDay(day);

            for (final e in dayEvents) {
              events.add(
                _HomeEvent(
                  id: e.id,
                  time: "${day.day}/${day.month} • ${e.time}",
                  title: e.title,
                  category: e.category,
                  source: e.source,
                  participants: e.participants,
                  ipsImpact: e.ipsImpact,
                  notes: e.notes,
                ),
              );
            }
          }

          return events.isEmpty
              ? _buildDialogEmptyState(
                  icon: Icons.event_note_rounded,
                  title: "Nessun evento",
                  subtitle: "Non ci sono eventi in questo mese",
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildEventsGroupedByDay(
                    events,
                    onSaved: () {
                      dialogSetState(() {});
                    },
                  ),
                );
        },
      ),
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

  Future<void> _openTodayCoverageActions() async {
    final issue = _relevantCoverageIssueFromNow();
    final details = issue?.details ?? [];

    await _showHomeDialog(
      icon: Icons.front_hand_rounded,
      color: const Color(0xFFE57373),
      title: "Problema copertura",
      subtitle: details.isEmpty
          ? "Nessun buco attivo o futuro da ora in poi"
          : "${details.length} problema/i oggi da capire",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isEmpty)
            _buildDialogEmptyState(
              icon: Icons.verified_rounded,
              title: "Tutto coperto",
              subtitle: "Da ora in poi non risultano buchi per Alice.",
            )
          else
            ...details.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final gap = entry.value;

              final whyText = gap.lines.isNotEmpty
                  ? gap.lines.join("\n")
                  : "Perché: il motore non trova nessun adulto o supporto che copra completamente questo intervallo.";

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.42)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Problema $index oggi",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${_formatTime(gap.start)}–${_formatTime(gap.end)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Alice risulta scoperta in questa fascia.",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      whyText,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.62),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openCalendarToday,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text("Vai al problema"),
                    ),
                  ],
                ),
              );
            }),
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

  Widget _buildCompactEventTile(_HomeEvent e, {VoidCallback? onSaved}) {
    return InkWell(
      onTap: () {
        _showEventDetailPopup(e, onSaved: onSaved);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                    e.participants.join(", "),
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
    );
  }

  Future<void> _showEventDetailPopup(
    _HomeEvent event, {
    VoidCallback? onSaved,
  }) async {
    final parts = event.time.split("•");
    final datePart = parts.first.trim();
    final timePart = parts.length > 1 ? parts[1].trim() : "";

    final dateParts = datePart.split("/");
    final dayNumber = int.tryParse(dateParts[0]) ?? 1;
    final monthNumber = int.tryParse(dateParts[1]) ?? 1;
    final year = DateTime.now().year;

    final weekdays = [
      "Lunedì",
      "Martedì",
      "Mercoledì",
      "Giovedì",
      "Venerdì",
      "Sabato",
      "Domenica",
    ];

    final months = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    final date = DateTime(year, monthNumber, dayNumber);
    final readableDate =
        "${weekdays[date.weekday - 1]} $dayNumber ${months[monthNumber - 1]}";

    final controller = TextEditingController(text: event.notes ?? "");

    await _showHomeDialog(
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF3F51B5),
      title: event.title,
      subtitle: readableDate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5).withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3F51B5).withOpacity(0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  readableDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                if (timePart.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        timePart,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                if (timePart.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.group_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      event.participants.join(", "),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Memoria evento",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            maxLines: 7,
            decoration: InputDecoration(
              hintText:
                  "Scrivi cosa è successo, dettagli, appunti importanti...",
              filled: true,
              fillColor: Colors.white.withOpacity(0.82),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF3F51B5),
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (event.source == "alice") {
                  final parts = event.time.split("•");
                  final datePart = parts.first.trim();

                  final dateParts = datePart.split("/");
                  final day = int.parse(dateParts[0]);
                  final month = int.parse(dateParts[1]);
                  final year = DateTime.now().year;

                  final date = DateTime(year, month, day);

                  final list = coreStore.aliceSpecialEventStore.eventsForDay(
                    date,
                  );

                  final updated = list.map((e) {
                    if (e.id == event.id) {
                      return e.copyWith(note: controller.text);
                    }
                    return e;
                  }).toList();

                  coreStore.aliceSpecialEventStore.replaceEventsForDay(
                    date,
                    updated,
                  );
                } else {
                  coreStore.realEventStore.updateEventNotes(
                    id: event.id,
                    notes: controller.text,
                  );
                }

                Navigator.of(context).pop();

                if (onSaved != null) {
                  onSaved();
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text("Salva memoria"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventsGroupedByDay(
    List<_HomeEvent> events, {
    VoidCallback? onSaved,
  }) {
    final Map<String, List<_HomeEvent>> grouped = {};

    for (final e in events) {
      final parts = e.time.split("•");
      final dayPart = parts.first.trim(); // es: "12/5"

      grouped.putIfAbsent(dayPart, () => []).add(e);
    }

    final weekdays = [
      "Lunedì",
      "Martedì",
      "Mercoledì",
      "Giovedì",
      "Venerdì",
      "Sabato",
      "Domenica",
    ];

    final months = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];

    final List<Widget> widgets = [];

    for (final entry in grouped.entries) {
      final dateParts = entry.key.split("/");
      final dayNumber = int.tryParse(dateParts[0]) ?? 1;
      final monthNumber = int.tryParse(dateParts[1]) ?? 1;
      final year = DateTime.now().year;

      final date = DateTime(year, monthNumber, dayNumber);
      final readableDay =
          "${weekdays[date.weekday - 1]} $dayNumber ${months[monthNumber - 1]}";

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            readableDay,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      );

      widgets.addAll(
        entry.value.map(
          (event) => _buildCompactEventTile(event, onSaved: onSaved),
        ),
      );
    }

    return widgets;
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
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Centro eventi del sistema",
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildGlobalEventEntryCard(
          icon: Icons.history_rounded,
          title: "Eventi passati",
          subtitle: "Archivio degli anni precedenti",
          color: const Color(0xFF8D6E63),
          onTap: _showPastYearsPopup,
        ),
        const SizedBox(height: 10),
        _buildGlobalEventEntryCard(
          icon: Icons.calendar_month_rounded,
          title: "$currentYear",
          subtitle: "Eventi dell’anno corrente",
          color: const Color(0xFF43A047),
          onTap: () {
            _showYearMonthsPopup(year: currentYear);
          },
        ),
        const SizedBox(height: 10),
        _buildGlobalEventEntryCard(
          icon: Icons.auto_awesome_motion_rounded,
          title: "Eventi futuri",
          subtitle: "Anni successivi al $currentYear",
          color: const Color(0xFF5E35B1),
          onTap: _showFutureYearsPopup,
        ),
      ],
    );
  }

  Widget _buildGlobalEventEntryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withOpacity(0.45),
            ),
          ],
        ),
      ),
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
      builder: (context, ips, _) {
        final todayIssue = _todayCoverageIssueFromNow();
        final todayDetails = todayIssue?.details ?? [];

        final bool hasTodayCoverageIssue = todayIssue != null;
        final bool hasIpsIssue = false;
        final bool hasIssue = hasTodayCoverageIssue;

        final color = hasTodayCoverageIssue
            ? const Color(0xFFE57373)
            : const Color(0xFF8BC34A);

        final stateText = hasTodayCoverageIssue
            ? "✋ Problema oggi"
            : "😌 Sistema stabilizzato";

        final mainSentence = hasTodayCoverageIssue
            ? "Oggi: Alice non coperta"
            : "Nessuna criticità oggi";

        String systemDetail;

        if (hasTodayCoverageIssue) {
          final first = todayDetails.first;
          systemDetail =
              "Copertura: Alice scoperta oggi ${_formatTime(first.start)}–${_formatTime(first.end)}";
        } else {
          systemDetail = "Nessuna criticità oggi";
        }

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
                    child: Center(
                      child: Text(
                        hasTodayCoverageIssue
                            ? "✋"
                            : ips.level == snap.IpsLevel.green
                            ? "😌"
                            : ips.level == snap.IpsLevel.yellow
                            ? "😐"
                            : "😨",
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
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
                          mainSentence,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.3,
                            color: const Color(0xFF8BC34A), // verde FrodoDesk
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF8BC34A).withOpacity(0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (hasTodayCoverageIssue || hasIpsIssue)
                          Text(
                            systemDetail,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.25,
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        CoverageQuickActionsBox(
                          todayDetails: todayDetails,
                          onResolveTap: _openTodayCoverageActions,
                          onFutureTap: () {
                            final futureIssue =
                                _futureCoverageIssueFromTomorrow();

                            if (futureIssue != null) {
                              _openCalendarForDay(futureIssue.day);
                            }
                          },
                          futureProblemText: () {
                            final futureIssue =
                                _futureCoverageIssueFromTomorrow();

                            if (todayDetails.isNotEmpty ||
                                futureIssue == null) {
                              return null;
                            }

                            final first = futureIssue.details.first;

                            return first.label.contains(":")
                                ? "Prossimo problema: ${first.label}"
                                : "Prossimo problema copertura: Alice scoperta ${_formatTime(first.start)}–${_formatTime(first.end)}";
                          }(),
                        ),
                        if (hasIssue && !hasTodayCoverageIssue) ...[
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              switch (ips.dominantModule) {
                                case snap.IpsModule.coverage:
                                  final targetDay = _firstCoverageProblemDay();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CalendarioScreenStepAStabile(
                                            coreStore: coreStore,
                                            initialSelectedDay: targetDay,
                                          ),
                                    ),
                                  );
                                  break;

                                case snap.IpsModule.finance:
                                  break;

                                case snap.IpsModule.health:
                                  break;

                                case snap.IpsModule.auto:
                                  break;

                                default:
                                  break;
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _actionLabelFromModule(ips.dominantModule),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                  MiniActionChip(
                    icon: Icons.calendar_today_rounded,
                    label: "Apri calendario",
                    onTap: _openCalendarToday,
                  ),
                  MiniActionChip(
                    icon: Icons.shield_rounded,
                    label: "Dettaglio copertura",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CoperturaScreen(coreStore: coreStore),
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
          FinancePressureSummaryCard(financeStore: financeStore),
          HomeOverviewMetrics(
            promemoriaCount: promemoriaCount,
            eventiCount: eventiCount,
            prossimiGiorniCount: prossimiGiorniCount,
            onPromemoriaTap: onPromemoriaTap,
            onEventiTap: onEventiTap,
            onPeopleTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => HomePeoplePanel(coreStore: coreStore),
              );
            },
            onNext7DaysTap: onNext7DaysTap,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withOpacity(0.58),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinancePresentPopup() async {
    await _showHomeDialog(
      icon: Icons.today_rounded,
      color: const Color(0xFFE53935),
      title: "Presente economico",
      subtitle: "Scadenze attive e pressione immediata",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final items = financeStore.presentRecurringItems();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return _buildFinanceTimeItem(
                item,
                onChanged: () {
                  refreshDialog(() {});
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showFinancePastPopup() async {
    await _showHomeDialog(
      icon: Icons.history_rounded,
      color: const Color(0xFF8D6E63),
      title: "Passato economico",
      subtitle: "Ricorrenze già confermate",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final items = financeStore.pastRecurringItems();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return _buildFinanceTimeItem(
                item,
                onChanged: () {
                  refreshDialog(() {});
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showFinanceFuturePopup() async {
    await _showHomeDialog(
      icon: Icons.event_available_rounded,
      color: const Color(0xFF1E88E5),
      title: "Futuro economico",
      subtitle: "Prossime scadenze previste",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final items = financeStore.futureRecurringItems();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return _buildFinanceTimeItem(
                item,
                onChanged: () {
                  refreshDialog(() {});
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFinanceTimeItem(
    FinanceRecurringItem item, {
    VoidCallback? onChanged,
  }) {
    return FinanceTimeItemCard(
      item: item,
      financeStore: financeStore,
      getMonthName: _getMonthName,
      onTap: () {
        _showSingleRecurringItemPopup(item);
      },
      onChanged: onChanged,
      onConfirm: () async {
        await financeStore.confirmRecurringItem(item.id);

        if (mounted) {
          setState(() {});
        }
      },
      onEdit: () async {
        await _showEditRecurringItemPopup(item);

        if (mounted) {
          setState(() {});
        }
      },
      onDelete: () async {
        await financeStore.removeRecurringItem(item.id);

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _showFinancePopup() async {
    await _showHomeDialog(
      icon: Icons.euro_rounded,
      color: const Color(0xFF8D6E63),
      title: "Finanze",
      subtitle: "Riepilogo economico familiare",
      child: StatefulBuilder(
        builder: (context, refreshFinancePopup) {
          final pastItems = financeStore.pastRecurringItems();
          final presentItems = financeStore.presentRecurringItems();
          final futureItems = financeStore.futureRecurringItems();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _showFinanceBalancesPopup();
                        refreshFinancePopup(() {});
                      },
                      child: _buildFinanceInfoCard(
                        title: "Saldo totale",
                        value:
                            "€${financeStore.totalBalance().toStringAsFixed(0)}",
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF43A047),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _showFinanceFundsPopup();
                        refreshFinancePopup(() {});
                      },
                      child: _buildFinanceInfoCard(
                        title: "Fondi",
                        value:
                            "€${financeStore.totalFunds().toStringAsFixed(0)}",
                        icon: Icons.savings_rounded,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _showFinanceMarginPopup,
                child: _buildFinanceInfoCard(
                  title: "Margine previsto",
                  value:
                      "€${financeStore.projectedMonthlyMargin().toStringAsFixed(0)}",
                  icon: Icons.trending_up_rounded,
                  color: financeStore.isUnderPressure()
                      ? const Color(0xFFE53935)
                      : const Color(0xFF43A047),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _showFinanceIncomePopup,
                      child: _buildFinanceInfoCard(
                        icon: Icons.arrow_downward_rounded,
                        title: "Entrate previste",
                        value:
                            "€${financeStore.projectedMonthlyIncome().toStringAsFixed(0)}",
                        color: const Color(0xFF43A047),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _showFinanceExpensesPopup,
                      child: _buildFinanceInfoCard(
                        icon: Icons.arrow_upward_rounded,
                        title: "Uscite previste",
                        value:
                            "€${financeStore.projectedMonthlyExpenses().toStringAsFixed(0)}",
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _showFinancePastPopup();
                        refreshFinancePopup(() {});
                      },
                      child: _buildFinanceInfoCard(
                        title: "Passato",
                        value:
                            "${pastItems.length} • €${financeStore.totalRecurringAmount(pastItems).toStringAsFixed(0)}",
                        icon: Icons.history_rounded,
                        color: const Color(0xFF8D6E63),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _showFinancePresentPopup();
                        refreshFinancePopup(() {});
                      },
                      child: _buildFinanceInfoCard(
                        title: "Presente",
                        value:
                            "${presentItems.length} • €${financeStore.totalRecurringAmount(presentItems).toStringAsFixed(0)}",
                        icon: Icons.today_rounded,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _showFinanceFuturePopup();
                        refreshFinancePopup(() {});
                      },
                      child: _buildFinanceInfoCard(
                        title: "Futuro",
                        value:
                            "${futureItems.length} • €${financeStore.totalRecurringAmount(futureItems).toStringAsFixed(0)}",
                        icon: Icons.event_available_rounded,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              FinanceYearDashboard(
                financeStore: financeStore,
                onMonthTap: (projection, color) async {
                  final monthItems = financeStore.itemsForProjectionMonth(
                    projection.month,
                  );

                  monthItems.sort(
                    (a, b) => a.nextDueDate.compareTo(b.nextDueDate),
                  );

                  final monthIncomeItems = monthItems
                      .where((item) => item.isIncome)
                      .toList();

                  final monthExpenseItems = monthItems
                      .where((item) => !item.isIncome)
                      .toList();

                  await _showHomeDialog(
                    icon: Icons.calendar_month_rounded,
                    color: color,
                    title: DateFormat(
                      'MMMM yyyy',
                      'it_IT',
                    ).format(projection.month),
                    subtitle: "Dettaglio economico del mese",
                    child: FinanceMonthDetailDialog(
                      financeStore: financeStore,
                      projection: projection,
                      monthIncomeItems: monthIncomeItems,
                      monthExpenseItems: monthExpenseItems,
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: financeStore.isUnderPressure()
                      ? const Color(0xFFE53935).withOpacity(0.12)
                      : const Color(0xFF43A047).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  financeStore.isUnderPressure()
                      ? "Il sistema rileva pressione economica."
                      : "Situazione economica stabile.",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.78),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditFundAmountPopup({
    required String fundId,
    required String fundName,
    required double currentAmount,
  }) async {
    final fund = financeStore.funds.firstWhere((f) => f.id == fundId);

    final nameController = TextEditingController(text: fund.name);
    final descriptionController = TextEditingController(text: fund.description);
    final amountController = TextEditingController(
      text: fund.amount.toStringAsFixed(2),
    );

    bool isProtected = fund.protected;
    FinanceFundCategory selectedCategory = fund.category;

    await _showHomeDialog(
      icon: Icons.edit_rounded,
      color: const Color(0xFF1E88E5),
      title: "Modifica fondo",
      subtitle: fund.name,
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nome fondo",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Descrizione",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Importo fondo",
                  hintText: "Es. 1200.00",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<FinanceFundCategory>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: FinanceFundCategory.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.name));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                value: isProtected,
                title: const Text("Fondo protetto"),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  refreshDialog(() {
                    isProtected = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final raw = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );
                    final value = double.tryParse(raw);

                    if (value == null) {
                      return;
                    }

                    await financeStore.updateFund(
                      FinanceFund(
                        id: fund.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        amount: value,
                        protected: isProtected,
                        category: selectedCategory,
                      ),
                    );

                    if (mounted) {
                      setState(() {});
                    }

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("Salva fondo"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFundPopup() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    bool isProtected = false;

    FinanceFundCategory selectedCategory = FinanceFundCategory.generic;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Nuovo fondo"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome fondo",
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Descrizione",
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Importo"),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<FinanceFundCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Categoria"),
                      items: FinanceFundCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      value: isProtected,
                      title: const Text("Fondo protetto"),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setDialogState(() {
                          isProtected = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Annulla"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;

                    final newFund = FinanceFund(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      amount: amount,
                      protected: isProtected,
                      category: selectedCategory,
                    );

                    financeStore.funds.add(newFund);

                    await financeStore.saveFunds();

                    if (mounted) {
                      setState(() {});
                    }

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
  }

  Future<void> _showAddFundTransactionPopup(FinanceFund fund) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    FundTransactionType selectedType = FundTransactionType.deposit;

    await _showHomeDialog(
      icon: Icons.swap_vert_rounded,
      color: const Color(0xFF1E88E5),
      title: "Movimento fondo",
      subtitle: fund.name,
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FundTransactionType>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: "Tipo movimento",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: FundTransactionType.deposit,
                    child: Text("Versamento"),
                  ),
                  DropdownMenuItem(
                    value: FundTransactionType.withdraw,
                    child: Text("Utilizzo"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedType = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Descrizione",
                  hintText: "Es. versamento mensile / gomme auto",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Importo",
                  hintText: "Es. 50.00",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final raw = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );
                    final value = double.tryParse(raw);

                    if (value == null || value <= 0) {
                      return;
                    }

                    await financeStore.addFundTransaction(
                      fundId: fund.id,
                      description: descriptionController.text.trim(),
                      amount: value,
                      type: selectedType,
                    );

                    if (mounted) {
                      setState(() {});
                    }

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("Salva movimento"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showFinanceFundsPopup() async {
    await _showHomeDialog(
      icon: Icons.savings_rounded,
      color: const Color(0xFF1E88E5),
      title: "Fondi",
      subtitle: "${financeStore.funds.length} fondi economici della famiglia",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddFundPopup();

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Aggiungi fondo"),
                ),
              ),

              const SizedBox(height: 14),

              ...financeStore.funds.map((fund) {
                final transactions =
                    financeStore.fundTransactions
                        .where((t) => t.fundId == fund.id)
                        .toList()
                      ..sort((a, b) => b.date.compareTo(a.date));
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.38)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF1E88E5),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fund.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fund.description,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.58),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "€${fund.amount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.72),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (fund.protected)
                            _financeBadge("PROTETTO", const Color(0xFFE53935)),
                          IconButton(
                            tooltip: "Movimento fondo",
                            onPressed: () async {
                              await _showAddFundTransactionPopup(fund);

                              if (mounted) {
                                setState(() {});
                              }

                              refreshDialog(() {});
                            },
                            icon: const Icon(
                              Icons.swap_vert_rounded,
                              size: 18,
                              color: Color(0xFF26A69A),
                            ),
                          ),
                          IconButton(
                            tooltip: "Modifica fondo",
                            onPressed: () async {
                              await _showEditFundAmountPopup(
                                fundId: fund.id,
                                fundName: fund.name,
                                currentAmount: fund.amount,
                              );

                              refreshDialog(() {});
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                          ),
                          IconButton(
                            tooltip: "Elimina fondo",
                            onPressed: () async {
                              await financeStore.removeFund(fund.id);

                              if (mounted) {
                                setState(() {});
                              }

                              refreshDialog(() {});
                            },
                            icon: const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),

                      if (transactions.isNotEmpty) ...[
                        const SizedBox(height: 14),

                        Text(
                          "Ultimi movimenti",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.72),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ...transactions.take(3).map((t) {
                          final isDeposit =
                              t.type == FundTransactionType.deposit;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isDeposit
                                      ? Icons.add_circle_rounded
                                      : Icons.remove_circle_rounded,
                                  size: 16,
                                  color: isDeposit
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFFE53935),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    t.description.isEmpty
                                        ? "Movimento fondo"
                                        : t.description,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.68),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Text(
                                  "${isDeposit ? '+' : '-'}€${t.amount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: isDeposit
                                        ? const Color(0xFF43A047)
                                        : const Color(0xFFE53935),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSingleFundPopup(FinanceFund fund) async {
    final controller = TextEditingController(
      text: fund.amount.toStringAsFixed(2),
    );

    await _showHomeDialog(
      icon: Icons.savings_rounded,
      color: const Color(0xFF1E88E5),
      title: fund.name,
      subtitle: "Dettaglio fondo",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinanceInfoCard(
            title: "Importo disponibile",
            value: "€${fund.amount.toStringAsFixed(0)}",
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF1E88E5),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Nuovo importo fondo",
              hintText: "Es. 2500",
              filled: true,
              fillColor: Colors.white.withOpacity(0.82),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final raw = controller.text.trim().replaceAll(',', '.');

                final value = double.tryParse(raw);

                if (value == null) {
                  return;
                }

                await financeStore.updateFundAmount(
                  fundId: fund.id,
                  newAmount: value,
                );

                if (mounted) {
                  setState(() {});
                }

                Navigator.of(context).pop();

                await _showSingleFundPopup(
                  financeStore.funds.firstWhere((f) => f.id == fund.id),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text("Salva fondo"),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fund.protected
                  ? const Color(0xFFE53935).withOpacity(0.12)
                  : const Color(0xFF43A047).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              fund.protected
                  ? "Questo fondo è protetto: rappresenta una sicurezza familiare."
                  : "Questo fondo è utilizzabile per spese previste o dedicate.",
              style: TextStyle(
                color: Colors.black.withOpacity(0.76),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRecurringItemPopup(FinanceRecurringItem item) async {
    final nameController = TextEditingController(text: item.name);

    final amountController = TextEditingController(
      text: item.expectedAmount.toStringAsFixed(2),
    );

    final descriptionController = TextEditingController(text: item.description);

    DateTime selectedDate = item.nextDueDate;

    await _showHomeDialog(
      icon: Icons.edit_rounded,
      color: const Color(0xFF1E88E5),
      title: "Modifica ricorrenza",
      subtitle: item.name,
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nome",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Importo previsto",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked == null) return;

                  refreshDialog(() {
                    selectedDate = picked;
                  });
                },
                child: _buildFinanceInfoCard(
                  title: "Data prevista",
                  value:
                      "${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}",
                  icon: Icons.event_rounded,
                  color: const Color(0xFF8D6E63),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Descrizione",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final raw = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final amount = double.tryParse(raw);

                    if (amount == null) {
                      return;
                    }

                    final updatedItem = item.copyWith(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      expectedAmount: amount,
                      nextDueDate: selectedDate,
                    );

                    await financeStore.updateRecurringItem(updatedItem);

                    if (mounted) {
                      setState(() {});
                    }

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("Salva modifiche"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSingleRecurringItemPopup(FinanceRecurringItem item) async {
    final realAmountController = TextEditingController(
      text: item.expectedAmount.toStringAsFixed(2),
    );
    await _showHomeDialog(
      icon: item.isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: item.isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: item.name,
      subtitle: item.isIncome ? "Entrata prevista" : "Uscita prevista",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.58),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.description,
              style: TextStyle(
                color: Colors.black.withOpacity(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _showEditRecurringItemPopup(item);

                if (mounted) {
                  setState(() {});
                }

                Navigator.of(context).pop();

                await _showSingleRecurringItemPopup(
                  financeStore.recurringItems.firstWhere(
                    (r) => r.id == item.id,
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text("Modifica ricorrenza"),
            ),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Importo previsto",
            value: "€${item.expectedAmount.toStringAsFixed(0)}",
            icon: item.isIncome
                ? Icons.payments_rounded
                : Icons.receipt_long_rounded,
            color: item.isIncome
                ? const Color(0xFF43A047)
                : const Color(0xFFE53935),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Prossima scadenza",
            value:
                "${item.nextDueDate.day} ${_getMonthName(item.nextDueDate.month)} ${item.nextDueDate.year}",
            icon: Icons.event_rounded,
            color: const Color(0xFF8D6E63),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Ricorrenza",
            value: item.recurringType == FinanceRecurringType.monthly
                ? "Mensile"
                : item.recurringType == FinanceRecurringType.yearly
                ? "Annuale"
                : item.recurringType == FinanceRecurringType.oneShot
                ? "Singola"
                : "Ogni ${item.customInterval ?? 1} ${item.customIntervalUnit == 'days'
                      ? 'giorni'
                      : item.customIntervalUnit == 'years'
                      ? 'anni'
                      : 'mesi'}",
            icon: Icons.repeat_rounded,
            color: const Color(0xFF5E35B1),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Categoria",
            value: item.category == FinanceCategory.salary
                ? "Stipendio"
                : item.category == FinanceCategory.entertainment
                ? "Intrattenimento"
                : item.category == FinanceCategory.house
                ? "Casa"
                : item.category == FinanceCategory.auto
                ? "Auto"
                : item.category == FinanceCategory.school
                ? "Scuola"
                : item.category == FinanceCategory.health
                ? "Salute"
                : "Generica",
            icon: Icons.category_rounded,
            color: const Color(0xFF3949AB),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Conferma manuale",
            value: item.requiresManualConfirmation
                ? "Richiesta"
                : "Non richiesta",
            icon: Icons.verified_user_rounded,
            color: item.requiresManualConfirmation
                ? const Color(0xFFFF9800)
                : const Color(0xFF43A047),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Obbligatorietà",
            value: item.mandatory ? "Obbligatoria" : "Facoltativa",
            icon: item.mandatory ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: item.mandatory
                ? const Color(0xFFE53935)
                : const Color(0xFF43A047),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Pressione economica",
            value: item.pressureLevel == FinancePressureLevel.low
                ? "Bassa"
                : item.pressureLevel == FinancePressureLevel.medium
                ? "Media"
                : item.pressureLevel == FinancePressureLevel.high
                ? "Alta"
                : "Critica",
            icon: Icons.warning_amber_rounded,
            color: item.pressureLevel == FinancePressureLevel.low
                ? const Color(0xFF43A047)
                : item.pressureLevel == FinancePressureLevel.medium
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Stato reale",
            value: item.confirmed ? "Confermato" : "Previsto",
            icon: item.confirmed
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            color: item.confirmed
                ? const Color(0xFF43A047)
                : const Color(0xFFFF9800),
          ),

          const SizedBox(height: 14),

          if (item.realAmount != null)
            _buildFinanceInfoCard(
              title: "Importo reale",
              value: "€${item.realAmount!.toStringAsFixed(2)}",
              icon: Icons.payments_rounded,
              color: const Color(0xFF1E88E5),
            ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Variabilità",
            value: item.variability == FinanceVariability.fixed
                ? "Fissa"
                : "Variabile",
            icon: Icons.tune_rounded,
            color: item.variability == FinanceVariability.fixed
                ? const Color(0xFF43A047)
                : const Color(0xFFFF9800),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Priorità pagamento",
            value: item.paymentPriority == FinancePaymentPriority.low
                ? "Bassa"
                : item.paymentPriority == FinancePaymentPriority.normal
                ? "Normale"
                : item.paymentPriority == FinancePaymentPriority.high
                ? "Alta"
                : "Critica",
            icon: Icons.priority_high_rounded,
            color: item.paymentPriority == FinancePaymentPriority.low
                ? const Color(0xFF43A047)
                : item.paymentPriority == FinancePaymentPriority.normal
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Protezione",
            value: item.protectionLevel == FinanceProtectionLevel.none
                ? "Nessuna"
                : item.protectionLevel == FinanceProtectionLevel.protected
                ? "Protetta"
                : "Critica",
            icon: item.protectionLevel == FinanceProtectionLevel.none
                ? Icons.lock_open_rounded
                : Icons.shield_rounded,
            color: item.protectionLevel == FinanceProtectionLevel.none
                ? const Color(0xFF43A047)
                : const Color(0xFFE53935),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Stabilità",
            value: item.stability == FinanceStability.stable
                ? "Stabile"
                : "Instabile",
            icon: item.stability == FinanceStability.stable
                ? Icons.check_circle_outline_rounded
                : Icons.change_circle_rounded,
            color: item.stability == FinanceStability.stable
                ? const Color(0xFF43A047)
                : const Color(0xFFFF9800),
          ),

          const SizedBox(height: 14),

          _buildFinanceInfoCard(
            title: "Rischio sospensione",
            value: item.suspensionRisk == FinanceSuspensionRisk.low
                ? "Basso"
                : item.suspensionRisk == FinanceSuspensionRisk.medium
                ? "Medio"
                : item.suspensionRisk == FinanceSuspensionRisk.high
                ? "Alto"
                : "Critico",
            icon: Icons.report_problem_rounded,
            color: item.suspensionRisk == FinanceSuspensionRisk.low
                ? const Color(0xFF43A047)
                : item.suspensionRisk == FinanceSuspensionRisk.medium
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935),
          ),

          const SizedBox(height: 14),

          if (!item.confirmed) ...[
            TextField(
              controller: realAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Importo reale",
                hintText: "Es. 17.99",
                filled: true,
                fillColor: Colors.white.withOpacity(0.82),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final raw = realAmountController.text.trim().replaceAll(
                    ',',
                    '.',
                  );

                  final value = double.tryParse(raw);

                  await financeStore.confirmRecurringItem(
                    item.id,
                    realAmount: value,
                  );

                  if (mounted) {
                    setState(() {});
                  }

                  Navigator.of(context).pop();

                  await _showSingleRecurringItemPopup(
                    financeStore.recurringItems.firstWhere(
                      (r) => r.id == item.id,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  item.isIncome
                      ? "Conferma entrata ricevuta"
                      : "Conferma uscita pagata",
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await financeStore.removeRecurringItem(item.id);

                if (mounted) {
                  setState(() {});
                }

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_rounded),
              label: const Text("Elimina ricorrenza"),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isIncome
                  ? const Color(0xFF43A047).withOpacity(0.12)
                  : const Color(0xFFE53935).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.isIncome
                  ? "Questa entrata contribuisce alla stabilità economica prevista."
                  : "Questa uscita contribuisce alla pressione economica prevista.",
              style: TextStyle(
                color: Colors.black.withOpacity(0.76),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecurringItemPopup({required bool isIncome}) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    FinanceRecurringType selectedRecurringType = FinanceRecurringType.monthly;
    final customIntervalController = TextEditingController(text: '1');

    String selectedCustomUnit = 'months';

    await _showHomeDialog(
      icon: isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: isIncome ? "Nuova entrata" : "Nuova uscita",
      subtitle: "Aggiungi una ricorrenza economica",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nome",
                  hintText: isIncome ? "Es. Stipendio" : "Es. Bolletta luce",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Importo previsto",
                  hintText: "Es. 50.00",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked == null) return;

                  refreshDialog(() {
                    selectedDate = picked;
                  });
                },
                child: _buildFinanceInfoCard(
                  title: isIncome
                      ? "Data entrata prevista"
                      : "Data scadenza prevista",
                  value:
                      "${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}",
                  icon: Icons.event_rounded,
                  color: const Color(0xFF8D6E63),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<FinanceRecurringType>(
                value: selectedRecurringType,
                decoration: InputDecoration(
                  labelText: "Tipo ricorrenza",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: FinanceRecurringType.monthly,
                    child: Text("Mensile"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.yearly,
                    child: Text("Annuale"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.oneShot,
                    child: Text("Una tantum"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.custom,
                    child: Text("Personalizzata"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedRecurringType = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              if (selectedRecurringType == FinanceRecurringType.custom) ...[
                TextField(
                  controller: customIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Ogni quanto",
                    hintText: "Es. 3",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.82),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: selectedCustomUnit,
                  decoration: InputDecoration(
                    labelText: "Unità",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.82),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'days', child: Text("Giorni")),
                    DropdownMenuItem(value: 'months', child: Text("Mesi")),
                    DropdownMenuItem(value: 'years', child: Text("Anni")),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    refreshDialog(() {
                      selectedCustomUnit = value;
                    });
                  },
                ),

                const SizedBox(height: 14),
              ],

              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Descrizione",
                  hintText: "Scrivi una nota breve",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.82),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    final description = descriptionController.text.trim();

                    final rawAmount = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );

                    final amount = double.tryParse(rawAmount);

                    if (name.isEmpty || amount == null) {
                      return;
                    }

                    final now = DateTime.now();

                    await financeStore.addRecurringItem(
                      FinanceRecurringItem(
                        id: 'recurring_${now.microsecondsSinceEpoch}',

                        name: name,

                        description: description.isEmpty
                            ? (isIncome
                                  ? "Entrata inserita manualmente"
                                  : "Uscita inserita manualmente")
                            : description,

                        expectedAmount: amount,

                        nextDueDate: DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ),

                        isIncome: isIncome,

                        recurringType: selectedRecurringType,

                        customInterval:
                            selectedRecurringType == FinanceRecurringType.custom
                            ? int.tryParse(customIntervalController.text.trim())
                            : null,
                        customIntervalUnit:
                            selectedRecurringType == FinanceRecurringType.custom
                            ? selectedCustomUnit
                            : null,

                        category: isIncome
                            ? FinanceCategory.salary
                            : FinanceCategory.generic,

                        requiresManualConfirmation: true,

                        mandatory: !isIncome,

                        pressureLevel: isIncome
                            ? FinancePressureLevel.low
                            : FinancePressureLevel.medium,

                        confirmed: false,

                        realAmount: null,

                        variability: FinanceVariability.fixed,

                        paymentPriority: isIncome
                            ? FinancePaymentPriority.high
                            : FinancePaymentPriority.normal,

                        protectionLevel: isIncome
                            ? FinanceProtectionLevel.protected
                            : FinanceProtectionLevel.none,

                        paymentOwner: FinancePaymentOwner.shared,

                        stability: FinanceStability.stable,

                        suspensionRisk: isIncome
                            ? FinanceSuspensionRisk.low
                            : FinanceSuspensionRisk.medium,
                      ),
                    );

                    if (mounted) {
                      setState(() {});
                    }

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    isIncome ? "Aggiungi entrata" : "Aggiungi uscita",
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showFinanceIncomePopup() async {
    await _showHomeDialog(
      icon: Icons.arrow_downward_rounded,
      color: const Color(0xFF43A047),
      title: "Entrate previste",
      subtitle: "Entrate economiche previste",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final incomeItems = financeStore.recurringItems
              .where((item) => item.isIncome)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddRecurringItemPopup(isIncome: true);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Aggiungi entrata"),
                ),
              ),

              const SizedBox(height: 14),

              ...incomeItems.map((item) {
                return FinanceTimeItemCard(
                  item: item,
                  financeStore: financeStore,
                  getMonthName: _getMonthName,
                  onTap: () async {
                    await _showSingleRecurringItemPopup(item);

                    refreshDialog(() {});
                  },
                  onConfirm: () async {
                    await financeStore.confirmRecurringItem(item.id);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  onEdit: () async {
                    await _showEditRecurringItemPopup(item);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  onDelete: () async {
                    await financeStore.removeRecurringItem(item.id);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _financeBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _showFinanceExpensesPopup() async {
    await _showHomeDialog(
      icon: Icons.arrow_upward_rounded,
      color: const Color(0xFFE53935),
      title: "Uscite previste",
      subtitle: "Uscite economiche previste",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final expenseItems = financeStore.recurringItems
              .where((item) => !item.isIncome)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddRecurringItemPopup(isIncome: false);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Aggiungi uscita"),
                ),
              ),

              const SizedBox(height: 14),

              ...expenseItems.map((item) {
                return FinanceTimeItemCard(
                  item: item,
                  financeStore: financeStore,
                  getMonthName: _getMonthName,
                  onTap: () async {
                    await _showSingleRecurringItemPopup(item);

                    refreshDialog(() {});
                  },
                  onConfirm: () async {
                    await financeStore.confirmRecurringItem(item.id);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  onEdit: () async {
                    await _showEditRecurringItemPopup(item);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                  onDelete: () async {
                    await financeStore.removeRecurringItem(item.id);

                    if (mounted) {
                      setState(() {});
                    }

                    refreshDialog(() {});
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditBalancePopup({
    required String personId,
    required String personName,
    required double currentAmount,
  }) async {
    final controller = TextEditingController(
      text: currentAmount.toStringAsFixed(2),
    );

    await _showHomeDialog(
      icon: Icons.edit_rounded,
      color: const Color(0xFF43A047),
      title: "Modifica saldo",
      subtitle: personName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Saldo attuale",
              hintText: "Es. 993.32",
              filled: true,
              fillColor: Colors.white.withOpacity(0.82),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final raw = controller.text.trim().replaceAll(',', '.');
                final value = double.tryParse(raw);

                if (value == null) {
                  return;
                }

                await financeStore.updateBalance(
                  personId: personId,
                  newAmount: value,
                );

                if (mounted) {
                  setState(() {});
                }

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text("Salva saldo"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinanceBalancesPopup() async {
    await _showHomeDialog(
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF43A047),
      title: "Saldo totale",
      subtitle: "Saldi economici della famiglia",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: financeStore.balances.map((balance) {
              final person = financeStore.people.firstWhere(
                (p) => p.id == balance.personId,
              );

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.38)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Color(0xFF43A047)),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        person.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "€${balance.currentAmount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(width: 8),

                        IconButton(
                          tooltip: "Modifica saldo",
                          onPressed: () async {
                            await _showEditBalancePopup(
                              personId: balance.personId,
                              personName: person.name,
                              currentAmount: balance.currentAmount,
                            );

                            refreshDialog(() {});
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showFinanceMarginPopup() async {
    final income = financeStore.projectedMonthlyIncome();
    final expenses = financeStore.projectedMonthlyExpenses();
    final margin = financeStore.projectedMonthlyMargin();

    await _showHomeDialog(
      icon: Icons.trending_up_rounded,
      color: margin < 0 ? const Color(0xFFE53935) : const Color(0xFF43A047),
      title: "Margine previsto",
      subtitle: "Simulazione economica mensile",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinanceInfoCard(
            title: "Entrate previste",
            value: "€${income.toStringAsFixed(0)}",
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF43A047),
          ),

          const SizedBox(height: 12),

          _buildFinanceInfoCard(
            title: "Uscite previste",
            value: "€${expenses.toStringAsFixed(0)}",
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFE53935),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: margin < 0
                  ? const Color(0xFFE53935).withOpacity(0.12)
                  : const Color(0xFF43A047).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Margine finale",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "€${margin.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: margin < 0
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  margin < 0
                      ? "Le uscite previste superano le entrate."
                      : "Le entrate previste coprono le uscite.",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  subtitle:
                      "Saldo €${financeStore.totalBalance().toStringAsFixed(0)} • Margine €${financeStore.projectedMonthlyMargin().toStringAsFixed(0)}",
                  badge: financeStore.isUnderPressure()
                      ? "Pressione"
                      : "Stabile",
                  badgeColor: const Color(0xFFB08D57),
                  startColor: const Color(0xFF8D6E63),
                  endColor: const Color(0xFFBCAAA4),
                  onTap: _showFinancePopup,
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

                _DashboardModuleCard(
                  icon: Icons.bar_chart_rounded,
                  title: "Statistiche",
                  subtitle: "Analizza andamento e storico",
                  badge: "Insight",
                  badgeColor: const Color(0xFFB08D57),
                  startColor: const Color(0xFFFF8F00),
                  endColor: const Color(0xFFFFCA28),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticheScreen(coreStore: coreStore),
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
  final String id;
  final String time;
  final String title;
  final String category;
  final String source;
  final List<String> participants;
  final bool ipsImpact;
  final String? notes;

  const _HomeEvent({
    required this.id,
    required this.time,
    required this.title,
    required this.category,
    required this.source,
    required this.participants,
    required this.ipsImpact,
    this.notes,
  });
}

class _HomeDay {
  final String dayLabel;
  final List<_HomeEvent> events;

  const _HomeDay({required this.dayLabel, required this.events});
}

class _HomeCoverageIssue {
  final DateTime day;
  final List<CoverageGapDetail> details;

  const _HomeCoverageIssue({required this.day, required this.details});
}

String _getMonthName(int month) {
  const months = [
    "Gennaio",
    "Febbraio",
    "Marzo",
    "Aprile",
    "Maggio",
    "Giugno",
    "Luglio",
    "Agosto",
    "Settembre",
    "Ottobre",
    "Novembre",
    "Dicembre",
  ];
  return months[month - 1];
}
