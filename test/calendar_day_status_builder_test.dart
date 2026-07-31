import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_status_builder.dart';
import 'package:frododesk/logic/calendar/models/calendar_day_status.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/models/coverage_criticality_detail.dart';

void main() {
  const builder = CalendarDayStatusBuilder();

  const gap = CoverageGapDetail(
    label: 'testo irrilevante',
    lines: ['testo irrilevante'],
    start: TimeOfDay(hour: 5, minute: 0),
    end: TimeOfDay(hour: 6, minute: 35),
  );

  CoverageCriticalityDetail criticality(CoverageCriticalityKind kind) =>
      CoverageCriticalityDetail(
        kind: kind,
        personId: 'person-id',
        start: DateTime(2026, 8, 11, 6, 35),
        end: DateTime(2026, 8, 11, 14, 30),
        source: CoverageSource.parentForced,
        coverageProviderId: null,
      );

  CalendarDayStatus build({
    List<CoverageGapDetail> gaps = const [],
    List<CoverageCriticalityDetail> criticalities = const [],
    bool logistics = false,
  }) => builder.build(
    gapDetails: gaps,
    criticalityDetails: criticalities,
    hasLogisticGaps: logistics,
  );

  test('zero gap, logistica e criticita produce verde', () {
    expect(build(), CalendarDayStatus.ok);
  });

  test('un gap coverage produce rosso', () {
    expect(build(gaps: const [gap]), CalendarDayStatus.problem);
  });

  test('un buco logistico produce rosso', () {
    expect(build(logistics: true), CalendarDayStatus.problem);
  });

  test('coverage ha priorita su recoverySacrificed', () {
    expect(
      build(
        gaps: const [gap],
        criticalities: [
          criticality(CoverageCriticalityKind.recoverySacrificed),
        ],
      ),
      CalendarDayStatus.problem,
    );
  });

  test('logistica ha priorita su recoverySacrificed', () {
    expect(
      build(
        logistics: true,
        criticalities: [
          criticality(CoverageCriticalityKind.recoverySacrificed),
        ],
      ),
      CalendarDayStatus.problem,
    );
  });

  test('solo un recoverySacrificed produce giallo', () {
    expect(
      build(
        criticalities: [
          criticality(CoverageCriticalityKind.recoverySacrificed),
        ],
      ),
      CalendarDayStatus.attention,
    );
  });

  test('piu recoverySacrificed producono giallo', () {
    expect(
      build(
        criticalities: [
          criticality(CoverageCriticalityKind.recoverySacrificed),
          criticality(CoverageCriticalityKind.recoverySacrificed),
        ],
      ),
      CalendarDayStatus.attention,
    );
  });

  test('solo recoveryProtected produce verde', () {
    expect(
      build(
        criticalities: [criticality(CoverageCriticalityKind.recoveryProtected)],
      ),
      CalendarDayStatus.ok,
    );
  });

  test('protected e sacrificed producono giallo', () {
    expect(
      build(
        criticalities: [
          criticality(CoverageCriticalityKind.recoveryProtected),
          criticality(CoverageCriticalityKind.recoverySacrificed),
        ],
      ),
      CalendarDayStatus.attention,
    );
  });
}
