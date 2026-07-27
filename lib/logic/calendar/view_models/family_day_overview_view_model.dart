import 'family_member_day_overview_view_model.dart';
import 'alice_day_overview_view_model.dart';

class FamilyDayOverviewViewModel {
  final DateTime day;

  final FamilyMemberDayOverviewViewModel matteo;
  final FamilyMemberDayOverviewViewModel chiara;
  final AliceDayOverviewViewModel alice;

  const FamilyDayOverviewViewModel({
    required this.day,
    required this.matteo,
    required this.chiara,
    required this.alice,
  });
}
