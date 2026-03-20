# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 20 Marzo 2026

# STATO GENERALE DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Il sistema è costruito con filosofia CNC (Costruzione Non Caotica):

ogni blocco deve essere stabile prima di passare al successivo.

# STATO ATTUALE DELLO SVILUPPO

Fase attuale:

Calendario reale — consolidamento operativo.

Il calendario è il cuore del sistema e deve funzionare in modo affidabile nella vita reale prima di introdurre altri moduli.

Checkpoint tecnico aggiornato:

- UI calendario stabilizzata
- metodo `_cardTurni()` riparato
- bottoni gestione turni ripristinati
- introduzione struttura override turni
- nuova rotazione turni completa (creazione, lettura, persistenza, rimozione)
- conflitto turno ↔ evento visibile nella card Turni
- introduzione gestione conflitto risolto anche tramite **Ferie**
- correzione logica Alice scuola vs vacanza (`AliceEventStore.isSchoolNormalDay`)
- fix crash UI `TextEditingController disposed`
- sistema stabile in esecuzione reale
- verifica profonda completata sul motore di copertura reale
- controllata tutta la catena logica:
  - `_busyShiftsFromRealEventsForPerson`
  - `OverrideApply.applyToBusyShifts`
  - `_isFasciaCovered`
  - `isTimeCovered`
  - `_uncoveredHomeSegments`
- confermato che la copertura combinata Matteo + Chiara è coerente anche nei segmenti intermedi
- verifica finale eseguita in app reale con esito corretto: **Copertura OK**
- avviata estrazione modulare sicura del file `calendario_screen_stepa.dart`
- creato file helper dedicato: `lib/utils/calendario_formatters.dart`
- aggiunto import del nuovo file utils nel calendario
- rimossi dal file principale gli helper:
  - `_fmtShortDate()`
  - `_fmtDateTime()`
  - `_fmtDate()`
  - `_fmt()`
- sostituite nel file principale le chiamate a `_fmt(...)` con `fmtTimeOfDay(...)`
- sostituite nel file principale le chiamate a `_fmtShortDate(...)` con `fmtShortDate(...)`
- app verificata dopo l’estrazione helper: nessun errore rosso, avvio su Edge riuscito
- corretta la logica centro estivo sopra vacanza nel `CoverageEngine`, distinguendo correttamente:
  - Alice a casa prima del centro estivo
  - Alice fuori casa durante il centro estivo
  - Alice di nuovo a casa dopo la fine del centro estivo
- aggiunta gestione più precisa delle fasce buco legate al centro estivo, compresa la lettura corretta di:
  - fascia mattina prima dell’ingresso
  - fascia pranzo se il centro estivo finisce prima
  - fascia sera dopo il rientro
- introdotto helper `_labelDateRange(...)` in `coverage_engine.dart` per mostrare correttamente buchi parziali reali nelle fasce ritagliate dal centro estivo
- verificato in app reale che il centro estivo impostato sopra vacanza prevale correttamente durante la sua fascia e, terminato il centro estivo, il sistema torna a leggere correttamente la vacanza sottostante

# 🔥 FIX CRITICO COMPLETATO (17 Marzo 2026)

## Problema

Caso reale:

- Chiara in ferie
- evento reale Chiara 09:00–10:00
- Matteo presente fino alle 13:00
- Chiara rientra alle 10:00

RISULTATO ERRATO (prima):

→ BUCO 07:30–16:25  
→ RISCHIO ALICE A CASA  

## Comportamento corretto

- 07:30–09:00 → Chiara presente
- 09:00–10:00 → Matteo presente
- 10:00+ → Chiara torna disponibile

→ Alice **non è mai sola**  
→ Copertura **OK tutto il giorno**

## Soluzione implementata

Aggiornata la logica in:

- `coverage_logic.dart`
- `coverage_engine.dart`

Ora il sistema:

- combina correttamente la presenza Matteo + Chiara
- gestisce eventi temporanei (visite)
- gestisce rientro dopo evento
- elimina falsi buchi Alice

## Verifica reale effettuata

✔ Caso 1  
Chiara ferie + visita → COPERTURA OK

✔ Caso 2  
Chiara visita + Matteo visita sovrapposta →  
BUCO reale rilevato → 09:30–10:00

✔ Verifica aggiuntiva di solidità  
Controllata manualmente l’intera catena del motore di copertura sui punti critici senza trovare incoerenze residue.

# 🔥 FIX CRITICI COMPLETATI (18 Marzo 2026)

## Problema 1

Dopo alcune correzioni, il sistema aveva smesso di considerare correttamente i giorni normali di scuola.

RISULTATO ERRATO (prima):

- giorno senza evento speciale Alice
- ingresso/uscita scuola non rientravano più correttamente nel comportamento atteso
- il motore poteva saltare la logica scuola in modo incoerente

## Soluzione implementata

Corretta la funzione:

- `AliceEventStore.isSchoolNormalDay`

Nuova logica:

- un giorno è considerato scuola normale se **non** è:
  - `vacation`
  - `schoolClosure`
  - `sickness`
  - `summerCamp`

## Problema 2

Giorni con **chiusura scuola** venivano ancora trattati come giorni normali di scuola.

RISULTATO ERRATO (prima):

- comparivano buchi di ingresso/uscita scuola
- il motore ragionava come se Alice dovesse andare e tornare da scuola
- incoerenza evidente tra card Alice/Scuola e box Buchi del giorno

## Soluzione implementata

Aggiornata di nuovo la logica di:

- `AliceEventStore.isSchoolNormalDay`

Ora:

- `schoolClosure` esclude correttamente il giorno dalla logica scuola
- il motore non genera più falsi buchi di ingresso/uscita nei giorni di chiusura scuola

## Verifica reale effettuata

✔ Giorni normali di scuola tornati coerenti  
✔ Giorni con chiusura scuola non trattati più come scuola attiva  
✔ Buchi del giorno di nuovo coerenti con lo stato reale di Alice/Scuola

# 🔥 AGGIORNAMENTO CHAT DEL 19 MARZO 2026

## Stato reale del codice a fine chat

Durante questa chat sono stati fatti test, tentativi di modifica UI e ripristini controllati.

Alla fine della chat il progetto è stato riportato allo stato stabile corretto tramite recupero della versione funzionante di `coverage_engine.dart` e verifica immediata in app reale.

Quindi la fonte di verità a fine chat è:

- codice reale funzionante
- UI tornata al punto stabile di partenza della mattina
- motore di copertura di nuovo allineato con i casi reali già verificati

## Verifiche confermate in app reale

Sono stati ricontrollati con esito corretto questi casi:

### Caso A — Sandra pranzo in vacanza

Scenario reale:

- Alice a casa tutto il giorno perché in vacanza
- genitori al lavoro
- buco reale a pranzo 13:00–14:30

Comportamento corretto verificato:

- il box “Buchi del giorno” mostra il buco reale
- la card “Copertura Sandra / Babysitter” segnala correttamente:
  - **Pranzo → Serve dal motore**

### Caso B — Buco reale con evento Chiara

Scenario reale:

- Matteo lavora il pomeriggio
- Chiara lavora la mattina
- Alice a casa tutto il giorno perché in vacanza
- Chiara ha appuntamento reale “tagliando” 16:00–17:25

Comportamento corretto verificato:

- il sistema mostra correttamente:
  - **Alice a casa: 16:00–17:25**
- il buco non viene più troncato a 16:25
- il popup dei buchi e la UI tornano allineati con la realtà

## Tentativo UI annullato

Durante la chat è stato tentato uno spostamento del blocco:

- “Decisione scuola (copertura)”

dalla sezione Alice/Scuola alla zona Copertura Sandra / Babysitter.

Esito finale:

- tentativo annullato
- file riportato allo stato stabile
- nessuna modifica UI permanente da considerare consolidata nei docs

Quindi **non** va registrato come cambiamento definitivo dell’interfaccia.

# 🔥 FIX CRITICO COMPLETATO (19 Marzo 2026 — notte/post-notte)

## Problema reale individuato

Caso reale di debug:

- Alice malata sopra periodo vacanza
- Matteo di mattina
- Chiara di notte
- il sistema in alcuni casi non mostrava il buco corretto del mattino/pranzo
- con Alice malata il motore poteva considerare erroneamente la fascia coperta, mentre con Alice in vacanza il comportamento appariva corretto

Durante il debug è stato verificato che il problema **non** nasceva da:

- `AliceEventStore`
- `coverage_logic.dart`
- `WorkShift.overlaps(...)`
- Sandra
- lettura dell’evento `sickness`

Il problema reale era nel modello turni:

- il giorno segnato come `N` veniva interpretato solo come notte che **parte alle 22:00**
- ma nella realtà FrodoDesk quel giorno deve valere anche come:
  - coda della notte precedente `00:00–06:30`
  - indisponibilità post-notte fino alle `14:30`
  - nuova notte la sera stessa `21:00–06:30`

## Soluzione implementata

Aggiornata la funzione:

- `TurnEngine.busyShiftsForPerson(...)`

Nuova regola applicata:

- se **ieri** era notte → aggiunge il blocco post-notte `00:00–14:30`
- se **oggi** è notte → aggiunge comunque il blocco post-notte `00:00–14:30`
- il giorno `N` viene quindi trattato come:
  - coda notte + post-notte la mattina
  - nuova notte la sera

## Effetto reale del fix

Ora, quando una persona è di notte, il motore la considera coerentemente:

- occupata nella coda notte
- indisponibile fino alle `14:30`
- di nuovo occupata nella notte successiva

Questo rende corretti i buchi nei casi:

- Alice malata a casa
- Alice in vacanza a casa
- copertura Sandra mattina
- copertura Sandra pranzo
- lettura reale della disponibilità dopo la notte

## Verifica reale effettuata

✔ Sul **31 agosto 2026** il sistema ora mostra correttamente il buco mattina  
✔ Attivando Sandra mattina si chiude solo la fascia coperta da Sandra  
✔ Resta il buco fino alle `14:30` perché la persona post-notte è indisponibile  
✔ Il comportamento è tornato coerente con la realtà  
✔ I debug temporanei sono stati rimossi dopo verifica finale

# 🔥 AGGIORNAMENTO CHAT DEL 20 MARZO 2026 — CENTRO ESTIVO SOPRA VACANZA

## Stato reale del codice a fine chat

In questa chat il lavoro si è spostato sul comportamento del **centro estivo sovrapposto a vacanza**, cioè sui giorni in cui:

- Alice ha un periodo vacanza attivo
- sopra quel periodo viene impostato un periodo centro estivo
- il motore deve capire correttamente quando Alice:
  - è a casa
  - è al centro estivo
  - torna a casa dopo il centro estivo

Il punto chiave emerso è questo:

👉 il sistema non può trattare “giorno di centro estivo” come se Alice fosse fuori tutto il giorno  
👉 deve invece leggere correttamente le fasce reali:

- prima dell’inizio centro estivo = Alice a casa
- durante centro estivo = Alice fuori casa
- dopo la fine centro estivo = Alice di nuovo a casa

## Problema reale individuato

Durante i test reali, con **centro estivo sopra vacanza**, il motore:

- in alcuni casi continuava a mostrare buchi non coerenti
- in altri casi non mostrava nei “Buchi del giorno” una fascia che invece la card Sandra segnalava come “Serve dal motore”
- non stava raccontando in modo uniforme la realtà tra:
  - box Buchi del giorno
  - card Copertura Sandra / Babysitter
  - stato Alice (casa / centro estivo)

## Soluzione implementata

È stata corretta la logica in `coverage_engine.dart` in modo che:

- le fasce Sandra vengano ritagliate rispetto all’orario reale del centro estivo
- i buchi del giorno possano mostrare correttamente i pezzi di fascia che restano davvero scoperti
- il sistema torni a leggere la vacanza sottostante appena il centro estivo finisce
- il centro estivo vinca solo **durante la propria finestra oraria**, non per tutto il giorno

In particolare:

- è stato corretto il comportamento del blocco `aliceSummerCamp`
- è stata sistemata la costruzione dei buchi su:
  - mattina
  - pranzo
  - sera
- è stato introdotto `_labelDateRange(...)` per mostrare correttamente buchi parziali reali ritagliati dalle fasce centro estivo

## Verifica reale effettuata

### Caso validato

Caso test reale verificato con esito corretto:

- **Data riferimento:** 17 agosto 2026
- **Turni:** Matteo notte + Chiara pomeriggio
- **Stato Alice:** vacanza con centro estivo sovrapposto

Comportamento corretto verificato:

- il centro estivo viene letto sopra la vacanza
- prima dell’ingresso Alice è considerata a casa
- durante il centro estivo Alice non è considerata a casa
- dopo il centro estivo il sistema torna a leggere correttamente la vacanza sottostante
- i buchi reali sono tornati coerenti con la situazione testata
- la card Sandra e il motore sono di nuovo allineati sul caso validato

## Stato attuale del blocco centro estivo

✔ **Caso validato correttamente:**
- Matteo notte + Chiara pomeriggio
- riferimento reale: **17 agosto 2026**

⚠️ **Casi ancora da provare per chiudere davvero il blocco:**

1. Matteo mattina + Chiara notte  
2. Matteo pomeriggio + Chiara mattina  

Questi due casi sono da considerare **obbligatori** prima di dichiarare il blocco centro estivo completamente chiuso.

## Problema aperto non bloccante

Durante l’ultimo test corretto è emerso un punto da rifinire:

👉 presenza possibile di **doppione nei Buchi del giorno**

Esempio logico:

- “Alice a casa: 13:00–14:30”
- “13:00–14:30”

Stato del problema:

- la logica base ora è molto più corretta
- il problema sembra essere di **presentazione / duplicazione del buco**
- **non blocca** il comportamento reale del motore
- va però ricordato come rifinitura da fare appena finiti i test turni mancanti

# MOTORI ATTIVI

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

# STORE PRINCIPALI

OverrideStore  
TurnOverrideStore  
RotationOverrideStore  
RealEventStore  
AliceEventStore  
SupportNetworkStore  
FeriePeriodStore  
DiseasePeriodStore  
FourthShiftStore  
SettingsStore  
SummerCampScheduleStore  
SummerCampSpecialEventStore  

# FUNZIONALITÀ ATTUALI

Il sistema gestisce:

- turni lavoro automatici
- quarta squadra
- riposo post-notte
- eventi reali calendario
- eventi Alice scuola
- rete di supporto
- copertura Sandra
- rilevazione buchi giornata
- override giornalieri
- ferie lunghe
- malattia a periodo
- override turni giornalieri
- override turni a periodo
- nuova rotazione turni persistente
- rimozione mirata della nuova rotazione attiva
- rilevazione conflitto turno ↔ evento
- gestione conflitto risolto tramite:
  - permesso
  - ferie
- spiegazione del conflitto nella UI Turni
- indicatore rapido conflitto sotto la riga del turno
- copertura combinata reale Matteo + Chiara ✔
- prima estrazione helper fuori dal file calendario ✔
- modello notte corretto con post-notte obbligatorio ✔
- gestione centro estivo sopra vacanza ✔ (parzialmente validata su caso reale)

# GERARCHIA SISTEMA TURNI

Override giornaliero  
↓  
Override periodo  
↓  
Nuova rotazione  
↓  
Quarta squadra  
↓  
Rotazione base  

# LOGICA CONFLITTO TURNO ↔ EVENTO

Il sistema rileva automaticamente quando:

evento ∩ turno ≠ ∅

e classifica:

🔴 Conflitto aperto  
🟠 Conflitto parziale  
🟢 Conflitto risolto  

Supporto attivo:

- Permesso ✔
- Ferie ✔

# STATO UI

File:

`calendario_screen_stepa.dart`

Situazione attuale:

- UI stabilizzata e funzionante
- nessun errore di compilazione
- nessuna modifica strutturale UI consolidata in questa chat

✔ Miglioramento già presente:

- rimozione dettagli buchi dal box principale
- introduzione popup su "Buchi del giorno"
- visualizzazione dettagli solo su richiesta utente
- aggiunta indicatori visivi ⚠ nelle cause del buco

Risultato:

- UI più pulita
- migliore leggibilità
- separazione tra sintesi (box) e dettaglio (popup)

# STATO REFACTOR FILE CALENDARIO

Obiettivo attivo:

alleggerire in modo sicuro `calendario_screen_stepa.dart` senza toccare il cuore della logica.

Fase attuale:

**Fase 1 — Helper puri (avviata)**

✔ completato:

- creazione `lib/utils/calendario_formatters.dart`
- spostamento helper di formattazione base
- rimozione helper duplicati dal file principale
- sostituzione chiamate principali nel calendario
- verifica avvio app reale

⬜ ancora da completare nella Fase 1:

- `_turnLabel()`
- `_cleanGapTitle()`
- `_realEventText()`
- `_conflictStateLabel()`
- `_conflictStateColor()`

Fasi successive previste ma non ancora iniziate:

- Fase 2 — Dialog / BottomSheet
- Fase 3 — Box UI semplici

Vincolo operativo confermato:

- non toccare ancora `_cardTurni()`, `_cardScuola()`, `_cardCopertura()` come estrazione strutturale completa
- non toccare ancora `_computeCoverageStepA()` e la logica ponte col motore

# STATO GENERALE

Sistema stabile e utilizzabile.

Logica copertura:
✔ corretta sui casi già sistemati  
✔ verificata su casi reali  
✔ senza falsi positivi nei casi già confermati  
✔ controllata nei punti logici più delicati  
✔ confermata in app reale nei casi testati  
✔ coerente anche sui giorni `N` con post-notte reale  
✔ corretta sul primo caso reale centro estivo sopra vacanza  
⚠️ da completare la validazione centro estivo sulle altre due combinazioni turni  

UI:
✔ stabile  
✔ leggibile  
✔ coerente con uso reale  
✔ nessuna modifica strutturale permanente introdotta in questa chat  
⚠️ da pulire il possibile doppione nei Buchi del giorno sul blocco centro estivo  

Refactor:
✔ avviato in modo sicuro  
✔ prima estrazione helper riuscita  
✔ nessun errore rosso dopo il primo alleggerimento del file calendario

# BUG APERTI PRIORITARI

## 1. Centro estivo sopra vacanza — validazione incompleta

Riferimento operativo da usare nella prossima chat:

- **17 agosto 2026** come caso guida già validato
- completare poi le altre combinazioni turni

Stato attuale:

- il caso **Matteo notte + Chiara pomeriggio** è corretto
- restano da provare:
  - **Matteo mattina + Chiara notte**
  - **Matteo pomeriggio + Chiara mattina**

Decisione:

- questo blocco va chiuso prima di dichiarare stabile il centro estivo reale

## 2. Buchi del giorno — possibile doppione fascia

Problema osservato:

- su alcuni casi centro estivo corretti il motore può mostrare un doppione logico del buco
- esempio:
  - “Alice a casa: 13:00–14:30”
  - “13:00–14:30”

Stato attuale:

- problema non bloccante
- logica reale molto migliorata
- da rifinire appena completati i test centro estivo sui turni mancanti

## 3. Eventi Alice — gestione periodi sovrapposti / stato giorno errato

Riferimento operativo da usare dopo il blocco centro estivo:

- **31 agosto 2026**

Problemi osservati:

- in Eventi Alice, salvando alcuni periodi, lo stato del giorno può tornare incoerente
- salvando malattia/chiusura scuola in presenza di altri periodi, può sparire o non essere più letto correttamente il periodo vacanze
- la card Alice/Scuola può mostrare:
  - “Scuola normale”
  anche quando la realtà del giorno non dovrebbe esserlo
- in questi casi il motore torna a generare buchi di ingresso/uscita scuola non coerenti con la realtà

Decisione:

- il blocco **Eventi Alice** va rivisto nel dettaglio
- bisogna verificare bene la coesistenza reale di:
  - vacanza
  - scuola chiusa
  - malattia
- va controllato l’allineamento tra:
  - UI card Alice
  - AliceEventStore
  - motore CoverageEngine

## 4. Sandra — bug ancora aperto su mattina e sera

Anche questo va ripreso con riferimento:

- **31 agosto 2026**

Problema osservato:

- se Alice è in vacanza o malata
- e i genitori lavorano entrambi
- Sandra deve risultare “serve dal motore” non solo a pranzo
- ma anche nelle fasce:
  - **Mattina 05:00–06:35**
  - **Sera 21:00–22:35**

Stato attuale:

- il pranzo è stato verificato corretto
- il caso mattina collegato alla notte/post-notte è stato corretto
- sul centro estivo il motore è stato corretto sul primo caso reale
- resta da verificare e consolidare il comportamento generale Sandra mattina/sera in tutti i casi Alice a casa

# PROSSIMO PASSO

Il prossimo passo corretto adesso **non** è ancora il blocco Eventi Alice.

Il prossimo passo è:

- chiudere davvero il blocco **centro estivo sopra vacanza**
- usare come riferimento operativo il **17 agosto 2026**
- completare i test mancanti sulle due combinazioni turni:

  1. Matteo mattina + Chiara notte  
  2. Matteo pomeriggio + Chiara mattina  

- verificare per entrambi:
  - buchi del giorno
  - coerenza Sandra
  - ritorno corretto a vacanza dopo la fine del centro estivo

Solo dopo:

- rifinire il possibile doppione nei Buchi del giorno
- tornare sul blocco **Eventi Alice (31 agosto)**

File previsti per la ripartenza:

- `coverage_engine.dart`
- `calendario_screen_stepa.dart` (solo se serve lettura UI del problema)
- poi successivamente:
  - `lib/logic/alice_event_store.dart`
  - file/widget collegato alla card Eventi Alice

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — completare validazione centro estivo sopra vacanza (caso guida 17 agosto già corretto) + test delle 2 combinazioni turni mancanti + poi pulizia del doppione nei Buchi del giorno.