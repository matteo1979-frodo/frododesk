import '../../alice_event_store.dart';

class GapTitleWithAliceStateBuilder {
  const GapTitleWithAliceStateBuilder();

  String build({
    required String label,
    required AliceEventType? aliceEventType,
    required String Function(String label) cleanGapTitle,
  }) {
    final lower = label.toLowerCase();

    if (lower.startsWith('alice pranzo:') ||
        lower.startsWith('alice ingresso:') ||
        lower.startsWith('alice uscita:') ||
        lower.startsWith('alice centro estivo ingresso:') ||
        lower.startsWith('alice centro estivo uscita:')) {
      return label;
    }

    final clean = cleanGapTitle(label);

    if (!clean.toLowerCase().startsWith('alice a casa')) {
      return clean;
    }

    if (aliceEventType == null) {
      return clean;
    }

    String? stateLabel;

    switch (aliceEventType) {
      case AliceEventType.schoolNormal:
        stateLabel = null;
        break;
      case AliceEventType.vacation:
        stateLabel = 'Vacanza';
        break;
      case AliceEventType.schoolClosure:
        stateLabel = 'Scuola chiusa';
        break;
      case AliceEventType.sickness:
        stateLabel = 'Malattia';
        break;
      case AliceEventType.summerCamp:
        stateLabel = 'Centro estivo';
        break;
    }

    if (stateLabel == null || stateLabel.isEmpty) {
      return clean;
    }

    final parts = clean.split(':');

    if (parts.length < 2) {
      return 'Alice a casa ($stateLabel)';
    }

    final left = parts.first.trim();
    final right = parts.sublist(1).join(':').trim();

    return '$left ($stateLabel): $right';
  }
}
