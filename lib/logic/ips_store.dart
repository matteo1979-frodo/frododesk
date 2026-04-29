// lib/logic/ips_store.dart
import 'package:flutter/foundation.dart';

import '../models/ips_snapshot.dart' as snap;
import '../models/day_override.dart';

import 'coverage_adapter.dart';

class IpsStore extends ValueNotifier<snap.IpsSnapshot> {
  final CoverageAdapter coverage;

  snap.IpsSnapshot snapshotV1 = snap.IpsSnapshot.v1(
    score: 0,
    level: snap.IpsLevel.green,
    dominantModule: snap.IpsModule.coverage,
    eventCritical: false,
    referenceDate: DateTime.now(),
    reasons: const <snap.IpsReason>[],
    dominantReasonKey: 'coverage.no_gaps_30_days',
  );

  IpsStore({required this.coverage})
    : super(
        snap.IpsSnapshot.v1(
          score: 0,
          level: snap.IpsLevel.green,
          dominantModule: snap.IpsModule.coverage,
          eventCritical: false,
          referenceDate: DateTime.now(),
          reasons: const <snap.IpsReason>[
            snap.IpsReason(
              key: 'coverage.no_gaps_30_days',
              module: snap.IpsModule.coverage,
              eventCritical: false,
              meta: <String, dynamic>{},
            ),
          ],
          dominantReasonKey: 'coverage.no_gaps_30_days',
        ),
      );

  void refresh({DateTime? now}) {
    final DateTime base = now ?? DateTime.now();
    final DateTime startDay = DateTime(base.year, base.month, base.day);

    final snap.IpsSnapshot out = _computeV1(startDay: startDay);

    value = out;
    snapshotV1 = out;

    notifyListeners();
  }

  String getDecisionMessage() {
    final s = snapshotV1;

    if (s.level == snap.IpsLevel.green) {
      return "Nessun problema nei prossimi 30 giorni.";
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int nowMinutes = now.hour * 60 + now.minute;

    final todayDetails = coverage.realGapDetailsForDay(today);

    // 🔴 Problema in corso
    for (final detail in todayDetails) {
      final startMinutes = detail.start.hour * 60 + detail.start.minute;
      final endMinutes = detail.end.hour * 60 + detail.end.minute;

      if (startMinutes <= nowMinutes && endMinutes > nowMinutes) {
        return "Problema in corso: serve intervento immediato.";
      }
    }

    // 🟡 Problema oggi
    for (final detail in todayDetails) {
      final endMinutes = detail.end.hour * 60 + detail.end.minute;

      if (endMinutes > nowMinutes) {
        final time = _humanGapTime(detail);
        return "Attenzione: problema oggi alle $time — Copertura Alice.";
      }
    }

    // 🔮 FUTURO (QUI FIX COMPLETO)
    for (int i = 1; i < 30; i++) {
      final day = today.add(Duration(days: i));
      final details = coverage.realGapDetailsForDay(day);

      if (details.isNotEmpty) {
        final time = _humanGapTime(details.first);
        final giorno = _formatDay(day);

        return "Attenzione: problema $giorno alle $time — Copertura Alice.";
      }
    }

    if (s.level == snap.IpsLevel.red) {
      return "Problema in corso: serve intervento immediato.";
    }

    return "Attenzione: possibile problema nei prossimi giorni.";
  }

  /// 🔥 ORARIO UMANO CORRETTO
  String _humanGapTime(dynamic detail) {
    final label = detail.label.toString();

    final match = RegExp(r'(\d{2}:\d{2})[–-](\d{2}:\d{2})').firstMatch(label);

    if (match != null) {
      return match.group(1)!;
    }

    final start = detail.start;
    final hh = start.hour.toString().padLeft(2, '0');
    final mm = start.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  String _formatDay(DateTime d) {
    const giorni = [
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ];

    const mesi = [
      '',
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    final g = giorni[d.weekday - 1];
    final m = mesi[d.month];

    return "$g ${d.day} $m";
  }

  // ---------------------------------------------------------
  // CALCOLO
  // ---------------------------------------------------------

  snap.IpsSnapshot _computeV1({required DateTime startDay}) {
    int score = coverage.riskScore30Days(startDay: startDay);

    final _FamilyDiscomfort discomfort = _scanFamilyDiscomfort30Days(startDay);

    if (discomfort.bothParentsBedriddenWithin30) {
      final int minScore = discomfort.bothParentsBedriddenWithin7 ? 80 : 60;
      if (score < minScore) score = minScore;
    }

    if (discomfort.oneParentBedriddenWithin30) {
      final int minScore = discomfort.oneParentBedriddenWithin7 ? 60 : 40;
      if (score < minScore) score = minScore;
    }

    final int s = score.clamp(0, 100);

    final snap.IpsLevel lvlV1 = (s >= 70)
        ? snap.IpsLevel.red
        : (s >= 40)
        ? snap.IpsLevel.yellow
        : snap.IpsLevel.green;

    String reasonKey;

    if (discomfort.bothParentsBedriddenWithin30) {
      reasonKey = discomfort.bothParentsBedriddenWithin7
          ? 'coverage.gap_within_7_days'
          : 'coverage.gap_within_30_days';
    } else if (discomfort.oneParentBedriddenWithin30) {
      reasonKey = discomfort.oneParentBedriddenWithin7
          ? 'coverage.gap_within_7_days'
          : 'coverage.gap_within_30_days';
    } else {
      if (s >= 80) {
        reasonKey = 'coverage.gap_within_7_days';
      } else if (s >= 60) {
        reasonKey = 'coverage.gap_within_30_days';
      } else {
        reasonKey = 'coverage.no_gaps_30_days';
      }
    }

    final List<snap.IpsReason> reasons = <snap.IpsReason>[
      snap.IpsReason(
        key: reasonKey,
        module: snap.IpsModule.coverage,
        eventCritical: (lvlV1 == snap.IpsLevel.red),
        meta: <String, dynamic>{'referenceDate': startDay.toIso8601String()},
      ),
    ];

    return snap.IpsSnapshot.v1(
      score: s,
      level: lvlV1,
      dominantModule: snap.IpsModule.coverage,
      eventCritical: (lvlV1 == snap.IpsLevel.red),
      referenceDate: startDay,
      reasons: reasons,
      dominantReasonKey: reasonKey,
    );
  }

  _FamilyDiscomfort _scanFamilyDiscomfort30Days(DateTime startDay) {
    final os = coverage.overrideStore;

    bool oneWithin30 = false;
    bool oneWithin7 = false;

    bool bothWithin30 = false;
    bool bothWithin7 = false;

    for (int i = 0; i < 30; i++) {
      final day = DateTime(
        startDay.year,
        startDay.month,
        startDay.day,
      ).add(Duration(days: i));

      final DayOverrides ov = os.getForDay(day);
      final m = ov.matteo?.status ?? OverrideStatus.normal;
      final c = ov.chiara?.status ?? OverrideStatus.normal;

      final bool mBed = m == OverrideStatus.malattiaALetto;
      final bool cBed = c == OverrideStatus.malattiaALetto;

      if (mBed || cBed) {
        oneWithin30 = true;
        if (i < 7) oneWithin7 = true;
      }

      if (mBed && cBed) {
        bothWithin30 = true;
        if (i < 7) bothWithin7 = true;
      }
    }

    return _FamilyDiscomfort(
      oneParentBedriddenWithin30: oneWithin30 && !bothWithin30,
      oneParentBedriddenWithin7: oneWithin7 && !bothWithin7,
      bothParentsBedriddenWithin30: bothWithin30,
      bothParentsBedriddenWithin7: bothWithin7,
    );
  }
}

class _FamilyDiscomfort {
  final bool oneParentBedriddenWithin30;
  final bool oneParentBedriddenWithin7;
  final bool bothParentsBedriddenWithin30;
  final bool bothParentsBedriddenWithin7;

  const _FamilyDiscomfort({
    required this.oneParentBedriddenWithin30,
    required this.oneParentBedriddenWithin7,
    required this.bothParentsBedriddenWithin30,
    required this.bothParentsBedriddenWithin7,
  });
}
