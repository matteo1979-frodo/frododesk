enum AdultConstraintKind { work, outboundTravel, returnTravel, recovery }

extension AdultConstraintKindItalianPresentation on AdultConstraintKind {
  String get italianLabel {
    switch (this) {
      case AdultConstraintKind.work:
        return 'lavoro';
      case AdultConstraintKind.outboundTravel:
        return 'viaggio di andata';
      case AdultConstraintKind.returnTravel:
        return 'viaggio di rientro';
      case AdultConstraintKind.recovery:
        return 'recupero post-notte';
    }
  }
}

String adultConstraintPersonDisplayName(String personId) {
  switch (personId) {
    case 'matteo':
      return 'Matteo';
    case 'chiara':
      return 'Chiara';
    default:
      return personId;
  }
}

class AdultConstraintInterval {
  final String personId;
  final DateTime start;
  final DateTime end;
  final AdultConstraintKind kind;
  final bool canBeSacrificedForCare;

  const AdultConstraintInterval({
    required this.personId,
    required this.start,
    required this.end,
    required this.kind,
    required this.canBeSacrificedForCare,
  });
}
