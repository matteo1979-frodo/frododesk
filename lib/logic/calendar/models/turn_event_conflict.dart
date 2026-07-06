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
