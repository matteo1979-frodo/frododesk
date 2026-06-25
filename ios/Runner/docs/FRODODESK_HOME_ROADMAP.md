FRODODESK — HOME ROADMAP

Ultimo aggiornamento: 13 Maggio 2026
(PresenceEngine attivo + Home rimandata dopo consolidamento motore)

OBIETTIVO
Trasformare la Home in:
- cruscotto reale della giornata
- punto di ingresso al sistema
- lettura immediata della situazione familiare
- primo livello decisionale del sistema FrodoDesk

--------------------------------------------------

FASE 1 — HOME VIVA (DATI REALI)

[✔] Mostrare chiaramente lo stato del giorno
[✔] Sezione "Oggi" leggibile in 2 secondi
[✔] Promemoria compatti e navigabili
[✔] Collegamenti rapidi reali (tap → calendario sul punto giusto)
[✔] Separazione chiara:
      - cosa devo fare
      - cosa succede oggi
[✔] Panoramica numerica migliorata (promemoria, eventi, persone)
[✔] Collegamento reale con il motore copertura (buchi → Home)
[✔] La Home legge i buchi reali del motore copertura
[✔] La Home distingue problema copertura da stato IPS generico

--------------------------------------------------

FASE 2 — HOME INTELLIGENTE

[✔] Spiegazioni semplici
[✔] IPS collegato a linguaggio umano iniziale
[✔] Evidenziazione anomalie reali
[✔] Stato reale Alice visibile
[✔] Problema copertura mostrato chiaramente nella card principale
[✔] Numero problemi/buchi visibile nella Home
[✔] Primo buco visibile con orario
[✔] Bottone RISOLVI collegato al popup della Home
[✔] Popup RISOLVI mostra il perché del problema
[✔] Popup RISOLVI coerente con “Buchi del giorno”
[✔] Giorni festivi gestiti correttamente
[✔] Supporto reale sincronizzato Home / Calendario
[✔] Evento reale con Alice non genera falso buco
[✔] Home non segnala falsi problemi se il motore li considera risolti

[ ] Micro-avvisi non invasivi
[ ] Gestione temporale reale completa:
      - passato → archiviato
      - presente → problema in corso
      - futuro → problema da gestire

NOTA:
IPS attualmente NON è ancora coerente al 100% con il motore reale.
Da rifondare dopo il consolidamento del PresenceEngine.

--------------------------------------------------

FASE 3 — HOME AZIONABILE

STATO: RIMANDATA

Motivo:
la Home non deve diventare azionabile sopra una logica di presenza Alice ancora in pulizia dentro CoverageEngine.

Prima serve completare:

1. PresenceEngine
2. cleanup CoverageEngine
3. una sola verità temporale su Alice
4. test reali strutturati

Solo dopo si passa alla Home azionabile.

[ ] Azioni rapide REALI
[ ] Attivazione diretta Sandra dalla Home
[ ] Accesso diretto ai punti critici
[ ] Riduzione click per arrivare alle decisioni
[ ] Tap diretto sui buchi → apertura punto preciso nel calendario
[ ] Azione rapida “risolvi buco”:
      - attiva Sandra
      - assegna supporto
      - porta Alice con te
[ ] Sistema “RISOLVI” multi-problema futuro:
      - copertura
      - banca
      - assicurazioni
      - auto
      - salute
      - scadenze
      - altri moduli

--------------------------------------------------

FASE 4 — RIFINITURA UI

[✔] Uniformare stile card
[✔] Migliorare gerarchie visive
[✔] Pulizia spazi e colori
[✔] Effetto “app pronta”

[ ] Rifinire ulteriormente la card principale se diventa troppo ripetitiva
[ ] Valutare se il testo lungo del problema va lasciato nella Home o solo nel popup RISOLVI

--------------------------------------------------

BUG / CORREZIONI GIÀ CONSOLIDATE

[✔] Bug giorni festivi: Alice senza scuola non sempre generava buco
[✔] Correzione: giorno festivo = Alice a casa
[✔] Test reale 1 maggio validato
[✔] Popup RISOLVI coerente con calendario
[✔] Home e calendario allineati su supporto reale
[✔] Beatrice 08:00–08:30 copre buco 08:05–08:25
[✔] Togliendo supporto il buco torna
[✔] Rimettendo supporto il buco sparisce
[✔] Evento reale multi-persona con Alice non genera falso buco “Alice a casa”

--------------------------------------------------

AGGIORNAMENTO 13 MAGGIO 2026 — BLOCCO G

In questa fase è stato consolidato il lavoro sul Motore Presenza Reale Alice.

COMPLETATO:

[✔] PresenceEngine creato
[✔] AlicePresenceState creato
[✔] stati presenza attuali:
      - home
      - school
      - timedEvent
      - realEvent
      - summerCamp
      - accompanied
      - support
[✔] supporto reale centralizzato nel PresenceEngine
[✔] eventi reali Alice centralizzati
[✔] eventi temporizzati Alice centralizzati
[✔] accompagnamento Alice centralizzato
[✔] isAliceAccompaniedDuringRange()
[✔] aliceCompanionEndForRange()
[✔] CoverageEngine legge sempre più dal PresenceEngine
[✔] bug centro estivo corretto:
      - uscita 16:30–16:50
      - casa dopo centro estivo 16:50–21:00
[✔] bug serale evento reale 21:00–22:30 corretto
[✔] buco serale ora rispetta il range reale dell’evento
[✔] rete supporto non si attiva solo perché viene modificato l’orario
[✔] supporto parziale spezza correttamente il buco
[✔] Sandra resta separata dalla rete supporto
[✔] CoverageEngine ridotto a consumatore progressivo del PresenceEngine

--------------------------------------------------

REGOLA BASE HOME

La Home:

- NON deve inventare nulla
- deve leggere il sistema
- deve aiutare a decidere
- deve mostrare prima il problema vero
- deve spiegare il perché solo dove serve
- deve diventare azionabile un passo alla volta
- NON deve duplicare logiche del CoverageEngine
- NON deve duplicare logiche del PresenceEngine

--------------------------------------------------

REGOLA STRUTTURALE NUOVA

La Home futura dovrà leggere la stessa verità di:

PresenceEngine
↓
CoverageEngine
↓
Home

La Home NON deve decidere dove si trova Alice.

La Home deve solo mostrare ciò che il motore ha già stabilito.

--------------------------------------------------

STATO ATTUALE

[✔] Motore copertura coerente con eventi reali
[✔] Alice a casa gestita correttamente
[✔] Buchi reali visibili e spiegati
[✔] Home collegata al motore reale
[✔] Card Home coerente con problema copertura
[✔] Popup RISOLVI funzionante e spiegato
[✔] Giorni festivi gestiti come giorni con Alice a casa
[✔] Supporto reale sincronizzato
[✔] Evento reale con Alice corretto
[✔] PresenceEngine attivo
[✔] CoverageEngine in progressiva pulizia
[⚠] IPS ancora parziale
[⚠] Home non ancora completamente guidata dal PresenceEngine
[⚠] Home azionabile rimandata

--------------------------------------------------

PROSSIMO STEP

🔥 PRIORITÀ STRUTTURALE AGGIORNATA

La priorità NON è ancora:

❌ Home azionabile completa
❌ rifondazione IPS
❌ nuove UI avanzate

Prima serve consolidare:

# MOTORE PRESENZA REALE ALICE

Priorità operative corrette:

1. Consolidare `alice_presence_engine.dart`
2. Eliminare doppioni legacy nel CoverageEngine
3. Centralizzare completamente la presenza reale Alice
4. Ripulire `analyzeDayV2()`
5. Verificare casi reali complessi
6. Far leggere Home dalla stessa verità
7. Solo dopo → riallineamento IPS reale
8. Solo dopo → Home realmente azionabile

--------------------------------------------------

COSA RESTA DA FARE

⬜ eliminazione doppioni legacy
⬜ pulizia `analyzeDayV2()`
⬜ spostamento progressivo segmentazione eventi/tagli fascia nel PresenceEngine
⬜ Home completamente guidata dal PresenceEngine
⬜ test presenza reale complessi
⬜ IPS reale coerente
⬜ Home azionabile finale

--------------------------------------------------

SIGNIFICATO STRUTTURALE

La Home NON deve diventare intelligente da sola.

La Home deve diventare lo schermo chiaro di una verità già calcolata bene dal sistema.

Prima:

✔ una sola verità presenza
✔ una sola segmentazione temporale
✔ una sola interpretazione reale di Alice

Dopo:

✔ Home azionabile
✔ IPS reale
✔ azioni rapide intelligenti

--------------------------------------------------

FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — Home rimandata dopo consolidamento PresenceEngine.

Prossimo obiettivo:
👉 eliminare doppioni legacy dal CoverageEngine
👉 consolidare PresenceEngine come sorgente unica di verità
👉 solo dopo riallineare Home e IPS

--------------------------------------------------

AGGIORNAMENTO STRATEGICO — HOME FUTURA MULTI-FAMIGLIA

Decisione Giugno 2026:

La Home attuale usa Matteo / Chiara / Alice come caso reale di collaudo.

In futuro la Home dovrà leggere:

- famiglia attiva
- persone della famiglia
- ruoli
- permessi
- notifiche personali
- dati sincronizzati cloud

senza dipendere da nomi fissi.

Principio:

La Home deve diventare il cruscotto della famiglia attiva, non della sola famiglia attuale.

NOTA:

Questa evoluzione NON cambia la priorità attuale.

Prima restano:

1. consolidamento PresenceEngine
2. cleanup CoverageEngine
3. Home allineata alla stessa verità
4. IPS reale solo dopo