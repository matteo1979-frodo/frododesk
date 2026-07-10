import '../../../models/real_event.dart';
import '../../../utils/status_visual.dart';

class FamilyAdultNowDetailsViewModel {
  final String name;
  final String nowLabel;
  final String turnLabel;
  final StatusVisual visual;

  final List<RealEvent> pastEvents;
  final List<RealEvent> currentEvents;
  final List<RealEvent> futureEvents;

  const FamilyAdultNowDetailsViewModel({
    required this.name,
    required this.nowLabel,
    required this.turnLabel,
    required this.visual,
    required this.pastEvents,
    required this.currentEvents,
    required this.futureEvents,
  });
}
