import 'settings_store.dart';
import 'override_store.dart';
import 'day_settings_store.dart';
import 'ferie_period_store.dart';
import 'alice_event_store.dart';
import 'real_event_store.dart';
import 'summer_camp_schedule_store.dart';
import 'summer_camp_special_event_store.dart';
import 'alice_special_event_store.dart';
import 'support_network_store.dart';
import 'disease_period_store.dart';
import 'fourth_shift_store.dart';
import 'turn_override_store.dart';
import 'rotation_override_store.dart';
import 'school_store.dart';

import 'turn_engine.dart';

import 'coverage_engine.dart';
import 'coverage_adapter.dart';
import 'ips_store.dart';
import 'week_store.dart';
import 'system_event_store.dart';
import '../logic/alice_companion_store.dart';

import 'ips/ips_detail_snapshot.dart';
import 'ips/ips_module_status.dart';
import 'ips/ips_types.dart' as types;
import '../models/ips_snapshot.dart' as snap;
import 'promemoria_store.dart';

class CoreStore {
  late final SettingsStore settingsStore;
  late final OverrideStore overrideStore;

  // ✅ impostazioni per giorno (Sandra / Uscita13)
  late final DaySettingsStore daySettingsStore;

  // ✅ NEW: Ferie lunghe (periodi)
  late final FeriePeriodStore feriePeriodStore;

  // ✅ NEW: Malattia a periodo
  late final DiseasePeriodStore diseasePeriodStore;

  // ✅ NEW: Eventi Alice (periodi)
  late final AliceEventStore aliceEventStore;

  // ✅ NEW: Eventi reali
  late final RealEventStore realEventStore;

  // ✅ NEW: Centro estivo settimanale
  late final SummerCampScheduleStore summerCampScheduleStore;

  // ✅ NEW: Eventi speciali centro estivo
  late final SummerCampSpecialEventStore summerCampSpecialEventStore;

  late final AliceSpecialEventStore aliceSpecialEventStore;

  // ✅ NEW: Rete di supporto
  late final SupportNetworkStore supportNetworkStore;

  late final PromemoriaStore promemoriaStore;

  late final AliceCompanionStore aliceCompanionStore;

  // ✅ NEW: Quarta Squadra
  late final FourthShiftStore fourthShiftStore;

  // ✅ NEW: Override turni (giornaliero / periodo / nuova rotazione)
  late final TurnOverrideStore turnOverrideStore;
  late final RotationOverrideStore rotationOverrideStore;

  // ✅ NEW: Scuola strutturata
  late final SchoolStore schoolStore;

  // ✅ NEW: unico motore turni (standard + 4a squadra)
  late final TurnEngine turnEngine;

  late final CoverageEngine coverageEngine;
  late final CoverageAdapter coverageAdapter;

  // ✅ A6: navigazione settimane
  late final WeekStore weekStore;

  // ✅ IPS
  late final IpsStore ipsStore;

  // Eventi di sistema
  final SystemEventStore eventStore = SystemEventStore();

  // ✅ FASE 2: mappa centralizzata navigationKey -> "route id"
  final Map<String, String> navMap = {
    "nav.coverage": "screen.coverage",
    "nav.finances": "screen.finances",
    "nav.health": "screen.health",
    "nav.car": "screen.car",
  };

  CoreStore({DateTime? initialDate}) {
    final now = (initialDate ?? DateTime.now());
    final DateTime init = DateTime(now.year, now.month, now.day);

    // 1) Store centrali
    settingsStore = SettingsStore();
    overrideStore = OverrideStore();
    daySettingsStore = DaySettingsStore();

    // ✅ NEW: Ferie lunghe (periodi)
    feriePeriodStore = FeriePeriodStore();

    // ✅ NEW: Malattia a periodo
    diseasePeriodStore = DiseasePeriodStore();

    // ✅ NEW: Eventi Alice (periodi)
    aliceEventStore = AliceEventStore();

    // ✅ NEW: Eventi reali
    realEventStore = RealEventStore();

    // ✅ NEW: Centro estivo settimanale
    summerCampScheduleStore = SummerCampScheduleStore();

    // ✅ NEW: Eventi speciali centro estivo
    summerCampSpecialEventStore = SummerCampSpecialEventStore();

    aliceSpecialEventStore = AliceSpecialEventStore();

    // ✅ NEW: Rete di supporto
    supportNetworkStore = SupportNetworkStore();

    promemoriaStore = PromemoriaStore();
    promemoriaStore.load();

    aliceCompanionStore = AliceCompanionStore();

    // ✅ NEW: Quarta Squadra
    fourthShiftStore = FourthShiftStore();

    // ✅ NEW: Override turni
    turnOverrideStore = TurnOverrideStore();
    rotationOverrideStore = RotationOverrideStore();

    // ✅ NEW: Scuola strutturata
    schoolStore = SchoolStore();

    // 2) TurnEngine (stato reale centrale)
    turnEngine = TurnEngine(
      fourthShiftStore: fourthShiftStore,
      turnOverrideStore: turnOverrideStore,
      rotationOverrideStore: rotationOverrideStore,
    );

    // 3) Motore copertura
    coverageEngine = CoverageEngine(
      turnEngine: turnEngine,
      overrideStore: overrideStore,
      daySettingsStore: daySettingsStore,
      supportNetworkStore: supportNetworkStore,
      diseasePeriodStore: diseasePeriodStore,
      realEventStore: realEventStore,
      aliceCompanionStore: aliceCompanionStore,
      aliceEventStore: aliceEventStore,
      aliceSpecialEventStore: aliceSpecialEventStore,
      summerCampScheduleStore: summerCampScheduleStore,
      summerCampSpecialEventStore: summerCampSpecialEventStore,
      schoolStore: schoolStore,
    );

    // 4) Adapter Copertura
    coverageAdapter = CoverageAdapter(
      overrideStore: overrideStore,
      engine: coverageEngine,
      ferieStore: feriePeriodStore,
      sandraDisponibileForDay: (day) =>
          daySettingsStore.sandraForDay(day) ??
          settingsStore.isSandraDisponibile,
      uscita13ForDay: (day) =>
          daySettingsStore.uscita13ForDay(day) ?? settingsStore.isUscita13,
    );

    // 5) WeekStore (A6)
    weekStore = WeekStore();
    weekStore.setFromDate(init);

    // 6) IPSStore usa coverageAdapter certificato
    ipsStore = IpsStore(coverage: coverageAdapter);
  }

  /// ✅ Bootstrap asincrono degli store persistenti
  Future<void> init() async {
    await overrideStore.load();
    await daySettingsStore.load();
    await feriePeriodStore.load();
    await diseasePeriodStore.load();
    await aliceEventStore.load();
    await aliceSpecialEventStore.load();
    await summerCampSpecialEventStore.load();
    await supportNetworkStore.load();
    await fourthShiftStore.load();
    await rotationOverrideStore.load();
    await realEventStore.load();
    await schoolStore.load();
  }

  /// Risolve una navigationKey (da IpsDetail) in una destinazione logica.
  /// NON fa push diretto: la UI resta proprietaria della navigazione.
  String? resolveDestination(String navigationKey) {
    return navMap[navigationKey];
  }

  // ============================================================
  // CNC: Dettaglio IPS – Snapshot strutturale puro
  // ============================================================

  IpsDetailSnapshot buildIpsDetailSnapshot() {
    final snap.IpsSnapshot v1 = ipsStore.snapshotV1;

    final types.IpsModuleId moduleId = _mapModule(v1.dominantModule);
    final types.IpsLevel level = _mapLevel(v1.level);
    final types.ModuleReasonCode reasonCode = _mapReasonCode(
      v1.dominantReasonKey,
    );

    return IpsDetailSnapshot(
      moduleId: moduleId,
      score: v1.score,
      level: level,
      isCriticalEvent: v1.eventCritical,
      reasonCode: reasonCode,
      referenceDate: null,
      payload: null,
    );
  }

  types.IpsModuleId _mapModule(snap.IpsModule m) {
    switch (m) {
      case snap.IpsModule.coverage:
        return types.IpsModuleId.coverage;
      case snap.IpsModule.finance:
        return types.IpsModuleId.finance;
      case snap.IpsModule.health:
        return types.IpsModuleId.health;
      case snap.IpsModule.auto:
        return types.IpsModuleId.auto;
      case snap.IpsModule.unknown:
        return types.IpsModuleId.coverage;
    }
  }

  types.IpsLevel _mapLevel(snap.IpsLevel l) {
    switch (l) {
      case snap.IpsLevel.green:
        return types.IpsLevel.green;
      case snap.IpsLevel.yellow:
        return types.IpsLevel.yellow;
      case snap.IpsLevel.red:
        return types.IpsLevel.red;
    }
  }

  types.ModuleReasonCode _mapReasonCode(String key) {
    switch (key) {
      case 'coverage.no_gaps_30_days':
        return CoverageReasonCode.noGaps30Days;
      case 'coverage.gap_within_30_days':
        return CoverageReasonCode.gapWithin30Days;
      case 'coverage.gap_within_7_days':
        return CoverageReasonCode.gapWithin7Days;
      case 'coverage.no_coverage_today':
        return CoverageReasonCode.noCoverageToday;
      default:
        return CoverageReasonCode.noGaps30Days;
    }
  }

  IpsModuleStatus _statusCoverage() {
    final int score = coverageAdapter.riskScore30Days();

    final bool isCritical = score >= 70;

    final CoverageReasonCode reason = (score >= 80)
        ? CoverageReasonCode.gapWithin7Days
        : (score >= 60)
        ? CoverageReasonCode.gapWithin30Days
        : CoverageReasonCode.noGaps30Days;

    return IpsModuleStatus(
      moduleId: types.IpsModuleId.coverage,
      score: score,
      isCriticalEvent: isCritical,
      reasonCode: reason,
    );
  }

  IpsModuleStatus _statusFinancePlaceholder() {
    return IpsModuleStatus(
      moduleId: types.IpsModuleId.finance,
      score: 0,
      isCriticalEvent: false,
      reasonCode: FinanceReasonCode.placeholder,
    );
  }

  IpsModuleStatus _statusHealthPlaceholder() {
    return IpsModuleStatus(
      moduleId: types.IpsModuleId.health,
      score: 0,
      isCriticalEvent: false,
      reasonCode: HealthReasonCode.placeholder,
    );
  }

  IpsModuleStatus _statusAutoPlaceholder() {
    return IpsModuleStatus(
      moduleId: types.IpsModuleId.auto,
      score: 0,
      isCriticalEvent: false,
      reasonCode: AutoReasonCode.placeholder,
    );
  }
}

// --------------------------------------------------
// ReasonCode placeholder
// --------------------------------------------------

enum CoverageReasonCode implements types.ModuleReasonCode {
  noGaps30Days,
  gapWithin30Days,
  gapWithin7Days,
  noCoverageToday;

  @override
  String code() {
    switch (this) {
      case CoverageReasonCode.noGaps30Days:
        return 'coverage.no_gaps_30_days';
      case CoverageReasonCode.gapWithin30Days:
        return 'coverage.gap_within_30_days';
      case CoverageReasonCode.gapWithin7Days:
        return 'coverage.gap_within_7_days';
      case CoverageReasonCode.noCoverageToday:
        return 'coverage.no_coverage_today';
    }
  }
}

enum FinanceReasonCode implements types.ModuleReasonCode {
  placeholder;

  @override
  String code() => 'finance.placeholder';
}

enum HealthReasonCode implements types.ModuleReasonCode {
  placeholder;

  @override
  String code() => 'health.placeholder';
}

enum AutoReasonCode implements types.ModuleReasonCode {
  placeholder;

  @override
  String code() => 'auto.placeholder';
}
