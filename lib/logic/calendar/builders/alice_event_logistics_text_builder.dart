import '../models/alice_event_logistics.dart';
import '../models/alice_summer_camp_logistics.dart';

class AliceEventLogisticsTextResult {
  final AliceLogisticProviderRef? dropOffProvider;
  final AliceLogisticProviderRef? pickUpProvider;
  final AliceLogisticProviderRef? dropOffSuggestedProvider;
  final AliceLogisticProviderRef? pickUpSuggestedProvider;
  final String? sameAdultText;
  final String? incompleteText;
  final String? involvedAdultsText;
  final String? busyWarningText;
  final String? conflictText;
  final String? supportSuggestionText;
  final String? singleAdultText;
  final String? splitLogisticsText;

  const AliceEventLogisticsTextResult({
    required this.dropOffProvider,
    required this.pickUpProvider,
    required this.dropOffSuggestedProvider,
    required this.pickUpSuggestedProvider,
    required this.sameAdultText,
    required this.incompleteText,
    required this.involvedAdultsText,
    required this.busyWarningText,
    required this.conflictText,
    required this.supportSuggestionText,
    required this.singleAdultText,
    required this.splitLogisticsText,
  });
}

class AliceEventLogisticsTextBuilder {
  const AliceEventLogisticsTextBuilder();

  AliceEventLogisticsTextResult build(
    AliceEventLogisticsResolution logistics,
  ) {
    final sameAdultText = logistics.sameAdult
        ? 'Stessa persona gestisce accompagnamento e ritiro'
        : null;

    final incompleteText = logistics.missingDropOff && logistics.missingPickUp
        ? 'Logistica incompleta: manca accompagnamento e ritiro'
        : logistics.missingDropOff
        ? 'Logistica incompleta: manca chi accompagna'
        : logistics.missingPickUp
        ? 'Logistica incompleta: manca chi ritira'
        : null;

    final involvedAdultsText = logistics.usesMatteo && logistics.usesChiara
        ? 'Coinvolti: Matteo e Chiara'
        : logistics.usesMatteo
        ? 'Coinvolto: Matteo'
        : logistics.usesChiara
        ? 'Coinvolta: Chiara'
        : null;

    final busyWarningText = logistics.matteoBusy && logistics.chiaraBusy
        ? 'Possibile conflitto logistico: Matteo e Chiara potrebbero non riuscire a gestire accompagnamento o ritiro'
        : logistics.matteoBusy
        ? 'Possibile conflitto logistico: Matteo potrebbe non riuscire a gestire accompagnamento o ritiro'
        : logistics.chiaraBusy
        ? 'Possibile conflitto logistico: Chiara potrebbe non riuscire a gestire accompagnamento o ritiro'
        : null;

    final conflictText = logistics.dropOffConflict && logistics.pickUpConflict
        ? 'Conflitto su accompagnamento e ritiro'
        : logistics.dropOffConflict
        ? 'Conflitto su accompagnamento'
        : logistics.pickUpConflict
        ? 'Conflitto su ritiro'
        : null;

    final supportSuggestionText = logistics.canSuggestSupport
        ? 'Suggerimento: verifica supporto disponibile per accompagnamento o ritiro'
        : null;

    final singleAdultText = logistics.singleAdultManagesEvent
        ? 'Nota: un solo adulto gestisce tutta la logistica dell’evento'
        : null;

    final splitLogisticsText = logistics.splitLogistics
        ? 'Logistica divisa: accompagnamento e ritiro sono gestiti da persone diverse'
        : null;

    return AliceEventLogisticsTextResult(
      dropOffProvider: logistics.outboundProvider,
      pickUpProvider: logistics.returnProvider,
      dropOffSuggestedProvider: logistics.outbound.suggestedProvider,
      pickUpSuggestedProvider: logistics.returnLeg.suggestedProvider,
      sameAdultText: sameAdultText,
      incompleteText: incompleteText,
      involvedAdultsText: involvedAdultsText,
      busyWarningText: busyWarningText,
      conflictText: conflictText,
      supportSuggestionText: supportSuggestionText,
      singleAdultText: singleAdultText,
      splitLogisticsText: splitLogisticsText,
    );
  }

  String adultLabel(String? key) {
    switch (key) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'sandra':
        return 'Sandra';
      case 'supporto':
        return 'Supporto';
      default:
        return 'Non assegnato';
    }
  }
}
