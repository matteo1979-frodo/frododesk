// lib/calendario_alice.dart

class Intervallo {
  final String nome;
  final int inizioMin;
  final int fineMin;

  Intervallo(this.nome, this.inizioMin, this.fineMin);
}

int hhmmToMin(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return h * 60 + m;
}

bool dentro(int min, int inizio, int fine) => min >= inizio && min < fine;

void main() {
  // ASSENZE (viaggi inclusi)
  final tuAssente =
      Intervallo("Tu", hhmmToMin("07:00"), hhmmToMin("17:30"));
  final chiaraAssente =
      Intervallo("Chiara", hhmmToMin("05:00"), hhmmToMin("14:30"));

  // SCUOLA
  final scuola =
      Intervallo("Scuola", hhmmToMin("08:25"), hhmmToMin("13:00"));

  // BACKUP (ordine di priorità)
  final backup = <Intervallo>[
    Intervallo("Sandra", hhmmToMin("00:00"), hhmmToMin("23:59")),
    Intervallo("Zia Beatrice", hhmmToMin("13:00"), hhmmToMin("22:30")),
    Intervallo("Laura", hhmmToMin("13:00"), hhmmToMin("22:30")),
    Intervallo("Marco", hhmmToMin("13:00"), hhmmToMin("22:30")),
    Intervallo("Zia Lea", hhmmToMin("16:25"), hhmmToMin("18:00")),
  ];

  // ATTIVITÀ EXTRA
  final attivita = <Intervallo>[
    Intervallo("Mattina dai nonni", hhmmToMin("09:00"), hhmmToMin("13:00")),
    Intervallo("Chiara parrucchiere", hhmmToMin("16:00"), hhmmToMin("17:30")),
    Intervallo("Chiara riunione", hhmmToMin("20:00"), hhmmToMin("21:30")),
  ];

  // CALCOLO COPERTURA (ogni 15 minuti)
  for (int min = 0; min < 24 * 60; min += 15) {
    String copertura;

    if (dentro(min, scuola.inizioMin, scuola.fineMin)) {
      copertura = "🔵 Scuola";
    } else {
      final tuPresente =
          !dentro(min, tuAssente.inizioMin, tuAssente.fineMin);
      final chiaraPresente =
          !dentro(min, chiaraAssente.inizioMin, chiaraAssente.fineMin);

      if (tuPresente || chiaraPresente) {
        final presenti = <String>[];
        if (tuPresente) presenti.add("Tu");
        if (chiaraPresente) presenti.add("Chiara");

        copertura = "🟢 ${presenti.join(" & ")}";
      } else {
        final b = backup.firstWhere(
          (x) => dentro(min, x.inizioMin, x.fineMin),
          orElse: () => Intervallo("NESSUNO", 0, 0),
        );

        copertura =
            b.nome == "NESSUNO" ? "🔴 Nessuno" : "🟡 ${b.nome}";
      }
    }

    final sovra = attivita
        .where((a) => dentro(min, a.inizioMin, a.fineMin))
        .map((a) => "⚪ ${a.nome}")
        .toList();

    final hh = (min ~/ 60).toString().padLeft(2, '0');
    final mm = (min % 60).toString().padLeft(2, '0');

    final extra = sovra.isEmpty ? "" : "  " + sovra.join(" | ");
    print("$hh:$mm  $copertura$extra");
  }
}