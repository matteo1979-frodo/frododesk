import 'alice_presence_state.dart';

class AliceCoverageWindow {
  final DateTime start;
  final DateTime end;
  final bool requiresAdult;
  final AlicePresenceState state;

  const AliceCoverageWindow({
    required this.start,
    required this.end,
    required this.requiresAdult,
    required this.state,
  });
}

class AliceCoverageTimeline {
  final bool isSupported;
  final List<AliceCoverageWindow> windows;

  const AliceCoverageTimeline._({
    required this.isSupported,
    required this.windows,
  });

  const AliceCoverageTimeline.unsupported()
    : this._(isSupported: false, windows: const []);

  AliceCoverageTimeline.supported(List<AliceCoverageWindow> windows)
    : this._(isSupported: true, windows: List.unmodifiable(windows));
}
