import '../../../utils/status_visual.dart';

class FamilyMemberNowViewModel {
  final String name;
  final String label;
  final StatusVisual visual;
  final bool busy;
  final bool isAlice;
  final String? turnLabel;

  const FamilyMemberNowViewModel({
    required this.name,
    required this.label,
    required this.visual,
    required this.busy,
    required this.isAlice,
    this.turnLabel,
  });
}
