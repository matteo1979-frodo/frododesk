// lib/logic/alice_events/alice_event_behavior_text.dart

import 'alice_event_behavior.dart';

String aliceEventBehaviorLabel(AliceEventBehavior behavior) {
  switch (behavior) {
    case AliceEventBehavior.passive:
      return "Passivo";
    case AliceEventBehavior.logistic:
      return "Logistico";
    case AliceEventBehavior.accompanied:
      return "Accompagnato";
    case AliceEventBehavior.futureAutonomous:
      return "Autonomo futuro";
  }
}

String aliceEventBehaviorDescription(AliceEventBehavior behavior) {
  switch (behavior) {
    case AliceEventBehavior.passive:
      return "Occupa Alice ma non richiede spostamenti.";
    case AliceEventBehavior.logistic:
      return "Richiede accompagnamento, ritiro o gestione reale.";
    case AliceEventBehavior.accompanied:
      return "Alice segue un adulto e non crea buco.";
    case AliceEventBehavior.futureAutonomous:
      return "Da usare in futuro quando Alice potrà essere autonoma.";
  }
}



List<String> aliceEventBehaviorExamples(AliceEventBehavior behavior) {
  switch (behavior) {
    case AliceEventBehavior.passive:
      return ["Compiti", "Studio", "Amica a casa"];

    case AliceEventBehavior.logistic:
      return ["Pallavolo", "Musica", "Dentista"];

    case AliceEventBehavior.accompanied:
      return ["Alice al seguito"];

    case AliceEventBehavior.futureAutonomous:
      return ["Evento autonomo futuro"];
  }
}
