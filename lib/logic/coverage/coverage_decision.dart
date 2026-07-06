class CoverageDecision {
  final String id;
  final CoverageDecisionType type;
  final CoverageDecisionLevel level;
  final String title;
  final String message;
  final int priority;
  final DateTime targetDate;
  final List<CoverageDecisionTrace> decisionTrace;

  const CoverageDecision({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    required this.priority,
    required this.targetDate,
    this.decisionTrace = const [],
  });

  bool get hasDecisionTrace => decisionTrace.isNotEmpty;
}

enum CoverageDecisionType {
  noIssue,
  aliceUncovered,
  supportAvailable,
  sandraSuggested,
  monitor,
}

enum CoverageDecisionLevel { info, attention, problem, opportunity, success }

enum CoverageDecisionReason {
  aliceAtHome,
  aliceSchool,
  aliceEvent,
  matteoUnavailable,
  chiaraUnavailable,
  sandraUnavailable,
  supportUnavailable,
  supportAvailable,
  coverageGap,
  generic,
}

enum CoverageDecisionTraceLevel { positive, neutral, warning, critical }

class CoverageDecisionTrace {
  final CoverageDecisionReason reason;
  final CoverageDecisionTraceLevel level;
  final String message;
  final bool visibleToUser;

  const CoverageDecisionTrace({
    required this.reason,
    required this.level,
    required this.message,
    this.visibleToUser = true,
  });
}
