import '../../../utils/status_visual.dart';

class FamilyNowViewModel {
  final StatusVisual matteoVisual;
  final StatusVisual chiaraVisual;
  final StatusVisual aliceVisual;

  final String matteoLabel;
  final String chiaraLabel;
  final String aliceLabel;

  final bool emergency;

  const FamilyNowViewModel({
    required this.matteoVisual,
    required this.chiaraVisual,
    required this.aliceVisual,
    required this.matteoLabel,
    required this.chiaraLabel,
    required this.aliceLabel,
    required this.emergency,
  });
}
