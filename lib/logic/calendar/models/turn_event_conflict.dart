import '../../../models/real_event.dart';
import 'date_range.dart';

enum TurnEventConflictState { open, partial, resolved }

class TurnEventConflictResolution {
  final RealEvent event;
  final TurnEventConflictState state;
  final DateRange overlapRange;
  final String? detailText;
  final bool hasTurnContext;

  const TurnEventConflictResolution({
    required this.event,
    required this.state,
    required this.overlapRange,
    this.detailText,
    this.hasTurnContext = true,
  });
}

extension TurnEventConflictResolutionListX
    on List<TurnEventConflictResolution> {
  List<String> get eventIds => map((conflict) => conflict.event.id).toList();
  bool get hasTurnContext => any((conflict) => conflict.hasTurnContext);
  TurnEventConflictState get worstState {
    if (any((c) => c.state == TurnEventConflictState.open)) {
      return TurnEventConflictState.open;
    }

    if (any((c) => c.state == TurnEventConflictState.partial)) {
      return TurnEventConflictState.partial;
    }

    return TurnEventConflictState.resolved;
  }

  List<TurnEventConflictResolution> visibleAt({
    required DateTime selectedDay,
    required DateTime now,
  }) {
    final selectedDate = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    final currentDate = DateTime(now.year, now.month, now.day);

    final selectedIsToday = selectedDate == currentDate;

    if (!selectedIsToday) {
      return List.unmodifiable(this);
    }

    return where((conflict) => conflict.overlapRange.end.isAfter(now)).toList();
  }
}
