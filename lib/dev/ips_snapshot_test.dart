// lib/dev/ips_snapshot_test.dart

import '../models/ips_snapshot.dart';
import '../logic/reason_text_registry.dart';

void runIpsSnapshotTest() {
  final snapshot = IpsSnapshot.v1(
    score: 80,
    level: IpsLevel.red,
    dominantModule: IpsModule.coverage,
    eventCritical: true,
    referenceDate: DateTime.now(),
    dominantReasonKey: "coverage.gap_within_7_days",
    reasons: [
      IpsReason(
        key: "coverage.gap_within_7_days",
        module: IpsModule.coverage,
        eventCritical: true,
        meta: {
          "referenceDate": DateTime.now().toIso8601String(),
          "daysAhead": 3,
        },
      ),
    ],
  );

  final registry = ReasonTextRegistry.build();
  final reasonText = registry.lookup(
    snapshot.dominantModule,
    snapshot.dominantReasonKey,
  );

  print("=== IPS TEST ===");
  print("Title: ${reasonText.title}");
  print("Description: ${reasonText.description}");
}
