import '../../../utils/status_visual.dart';
import 'alice_now_event_view_model.dart';

class AliceNowDetailsViewModel {
  final String nowLabel;
  final String? dayStateLabel;
  final StatusVisual visual;

  final List<AliceNowEventViewModel> pastEvents;
  final List<AliceNowEventViewModel> currentEvents;
  final List<AliceNowEventViewModel> futureEvents;

  const AliceNowDetailsViewModel({
    required this.nowLabel,
    required this.dayStateLabel,
    required this.visual,
    required this.pastEvents,
    required this.currentEvents,
    required this.futureEvents,
  });
}
