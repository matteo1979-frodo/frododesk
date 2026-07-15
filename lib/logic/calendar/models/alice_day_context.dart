import '../view_models/alice_now_event_view_model.dart';

class AliceDayContext {
  final String? dayStateLabel;

  final bool isSchoolDay;
  final bool isSummerCampDay;

  final List<AliceNowEventViewModel> events;

  const AliceDayContext({
    required this.dayStateLabel,
    required this.isSchoolDay,
    required this.isSummerCampDay,
    required this.events,
  });
}