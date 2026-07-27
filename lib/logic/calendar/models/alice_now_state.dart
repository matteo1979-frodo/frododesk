import '../../../utils/status_visual.dart';

class AliceNowState {
  final bool isOutNow;
  final String nowLabel;
  final StatusVisual visual;

  const AliceNowState({
    required this.isOutNow,
    required this.nowLabel,
    required this.visual,
  });
}