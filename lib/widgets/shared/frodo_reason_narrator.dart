import '../../models/frodo_observation.dart';

class FrodoReasonNarrator {
  static String opening(FrodoObservation observation) {
    switch (observation.category) {
      case FrodoObservationCategory.finance:
        return 'Prima di suggerirti qualsiasi cosa ho ricostruito la situazione economica attuale. Ho controllato le spese, i conti, le protezioni e le entrate previste, cercando la soluzione più sicura e sostenibile.';

      case FrodoObservationCategory.coverage:
        return 'Prima di arrivare a questa conclusione ho verificato la presenza reale delle persone, le eventuali sovrapposizioni e le possibili coperture.';

      case FrodoObservationCategory.calendar:
        return 'Ho ricostruito gli eventi della giornata e verificato se esistono conflitti, sovrapposizioni o momenti scoperti.';

      case FrodoObservationCategory.expenses:
        return 'Ho analizzato l’andamento delle spese cercando anomalie, opportunità di risparmio e comportamenti ricorrenti.';

      case FrodoObservationCategory.health:
        return 'Ho valutato le informazioni disponibili cercando eventuali situazioni che potrebbero influenzare la pianificazione.';

      case FrodoObservationCategory.home:
        return 'Ho raccolto le informazioni provenienti dai vari moduli della casa e le ho ordinate in base alla loro importanza.';

      case FrodoObservationCategory.system:
        return 'Ho controllato lo stato generale del sistema e verificato che tutti i dati disponibili fossero coerenti.';
    }
  }

  static String pathIntro(FrodoObservation observation) {
    if (observation.explanations.isEmpty) {
      return 'Per questa osservazione non sono ancora disponibili dettagli sul ragionamento.';
    }

    if (observation.explanations.length == 1) {
      return 'La decisione è stata influenzata principalmente da un singolo controllo.';
    }

    return 'Questo è il percorso che ho seguito prima di arrivare alla conclusione.';
  }

  static String conclusion(FrodoObservation observation) {
    switch (observation.level) {
      case FrodoObservationLevel.problem:
        return 'Dopo aver valutato tutti questi elementi ritengo che sia meglio intervenire prima che la situazione possa peggiorare.';

      case FrodoObservationLevel.attention:
        return 'La situazione è ancora gestibile, ma alcuni segnali meritano attenzione per evitare problemi successivi.';

      case FrodoObservationLevel.opportunity:
        return 'Ho individuato una possibilità che potrebbe migliorare la situazione senza introdurre rischi particolari.';

      case FrodoObservationLevel.success:
        return 'Con i dati attuali non emergono criticità rilevanti e la situazione risulta equilibrata.';

      case FrodoObservationLevel.info:
        return 'Per ora si tratta semplicemente di un’informazione utile da tenere presente nelle prossime decisioni.';
    }
  }

  static String stepTitle(FrodoObservationExplanation explanation) {
    switch (explanation.reasonKey) {
      case 'criticalExpense':
        return '🚨 Per prima cosa ho cercato le spese che non possono aspettare';

      case 'automaticPayment':
        return '🏦 Ho verificato i pagamenti automatici';

      case 'protectedExpense':
        return '🛡️ Ho controllato le voci protette';

      case 'protectedFunds':
        return '🛡️ Ho controllato i fondi protetti';

      case 'minimumBalance':
        return '💰 Ho verificato il saldo dei conti';

      case 'ownerUnderPressure':
        return '👤 Ho valutato la situazione economica personale';

      case 'incomeForecast':
        return '📅 Ho controllato le entrate in arrivo';

      case 'delayAllowed':
        return '⏳ Ho cercato spese che possono essere rimandate';

      case 'usableFunds':
        return '💵 Ho valutato i fondi disponibili';

      case 'sharedPayment':
        return '👨‍👩‍👧 Ho analizzato le spese condivise';

      case 'familyPriority':
        return '🏡 Ho valutato le priorità della famiglia';

      case 'personalPriority':
        return '👤 Ho valutato le priorità personali';

      case 'suggestedAccount':
        return '💳 Ho scelto il conto più adatto';

      case 'thirteenthSalary':
        return '💶 Ho considerato la tredicesima';

      case 'fourteenthSalary':
        return '💶 Ho considerato la quattordicesima';

      case 'productionBonus':
        return '🎁 Ho considerato il premio produzione';

      case 'extraordinaryIncome':
        return '📈 Ho considerato entrate straordinarie';

      case 'opportunity':
        return "✨ Ho individuato un'opportunità";

      default:
        return '🧩 Ho completato un controllo generale';
    }
  }
}
