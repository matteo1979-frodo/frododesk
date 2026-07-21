class AdultNowState {
  final bool isBusyNow;
  final bool isBusyForEventNow;
  final bool isBusyForTurn;
  final bool isBedSick;
  final bool isOnHoliday;
  final String nowLabel;
  final String turnLabel;

  const AdultNowState({
    required this.isBusyNow,
    required this.isBusyForEventNow,
    required this.isBusyForTurn,
    required this.isBedSick,
    required this.isOnHoliday,
    required this.nowLabel,
    required this.turnLabel,
  });
}
