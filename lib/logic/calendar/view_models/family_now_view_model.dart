import 'family_member_now_view_model.dart';

class FamilyNowViewModel {
  final FamilyMemberNowViewModel matteo;
  final FamilyMemberNowViewModel chiara;
  final FamilyMemberNowViewModel alice;

  final bool emergency;

  const FamilyNowViewModel({
    required this.matteo,
    required this.chiara,
    required this.alice,
    required this.emergency,
  });
}