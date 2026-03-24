# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 24 Marzo 2026

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
---

# AGGIORNAMENTO STATO — 21 MARZO 2026

## Stato attuale sistema

Il calendario FrodoDesk ha raggiunto uno stato stabile per uso reale continuativo.

### Blocchi consolidati

- motore copertura stabile  
- gestione turni + eventi reali coerente  
- modello notte/post-notte corretto  
- centro estivo sopra vacanza funzionante  
- Eventi Alice stabilizzati e coerenti con il motore  
- comportamento Sandra corretto su tutte le fasce (mattina, pranzo, sera)  
- introduzione sezioni comprimibili nella schermata calendario  
- sezione “REALTÀ DEL GIORNO” aperta di default  
- sezione “COPERTURA ALICE” chiusa di default  
- box sezione più compatti quando chiusi

---

## Centro estivo sopra vacanza

Blocco testato e validato su caso reale.

Comportamento corretto:

- prima del centro estivo → Alice a casa  
- durante il centro estivo → Alice fuori casa  
- dopo il centro estivo → ritorno alla vacanza  

I buchi del giorno risultano coerenti con la realtà.

👉 Stato: **CHIUSO**

---

## Eventi Alice

Problemi precedenti:

- incoerenze tra stato giorno e periodi
- lettura non stabile tra vacanza / malattia / scuola

Situazione attuale:

- gestione periodi stabilizzata
- stato giorno coerente con la realtà
- allineamento corretto tra:
  - AliceEventStore
  - UI
  - CoverageEngine

👉 Stato: **CHIUSO**

---

## Sandra (copertura fasce)

Problema precedente:

- mancata attivazione corretta nelle fasce:
  - mattina
  - sera

Situazione attuale:

- Sandra viene richiesta correttamente dal motore quando:
  - Alice è a casa
  - genitori non disponibili
- copertura coerente su:
  - mattina ✔
  - pranzo ✔
  - sera ✔

👉 Stato: **CHIUSO**

---

## Problemi aperti (non bloccanti)

- doppione visuale nei “Buchi del giorno”  
- semplificazione UX/UI necessaria  

👉 non impattano la correttezza del motore  

---

## Direzione operativa

Il sistema è pronto per:

- uso reale continuativo  
- test su casi reali prolungati  

La prossima fase non è strutturale ma di esperienza utente.

---

## Prossima fase

Focus su UX/UI:

- riduzione scroll  
- card compatte  
- sezioni apri/chiudi  
- accesso rapido alle modifiche (tap diretto su persone e copertura)  

---

## Stato UI aggiornato

Nel file:

`calendario_screen_stepa.dart`

sono state introdotte modifiche UX sicure e già verificate in app reale:

- aggiunte variabili di stato per apertura/chiusura sezioni
- header sezione cliccabile
- icona espandi/comprimi
- contenuto sezione nascosto quando chiuso
- padding ridotto quando sezione chiusa

Verifica reale eseguita:

- “REALTÀ DEL GIORNO” si apre/chiude correttamente
- “COPERTURA ALICE” si apre/chiude correttamente
- “COPERTURA ALICE” parte chiusa di default
- layout più compatto confermato in app reale

👉 Stato: **ATTIVO E STABILE**

---

## Stato generale

✔ sistema stabile  
✔ motore affidabile  
✔ pronto per utilizzo reale  
✔ Eventi Alice risolti  
✔ Sandra mattina/sera risolto  
✔ prima ottimizzazione UX/UI completata e verificata  

👉 fase attuale: **ottimizzazione utilizzo e leggibilità**
## 🔥 AGGIORNAMENTO — 21 MARZO 2026 (CHIUSURA FASE 1 REFACTOR)

Durante questa chat è stata completata la **Fase 1 — Helper puri** del refactor del file:

`calendario_screen_stepa.dart`

### Stato refactor

Completato lo spostamento nel file:

`lib/utils/calendario_formatters.dart`

dei seguenti helper:

- `cleanGapTitle()`
- `realEventText()`
- `conflictStateLabel()`
- `conflictStateColor()`

### Decisione strutturale

- `_turnLabel()` NON è stato spostato
- resta nel file calendario per evitare dipendenze non controllate

### Stato tecnico

- file utils collegato correttamente
- import funzionante
- presente dipendenza temporanea da `TurnEventConflictState`

Nota:

questa dipendenza sarà pulita in una fase successiva di refactor

### Verifica reale

✔ app avviata dopo ogni modifica  
✔ nessun errore rosso  
✔ nessuna regressione  
✔ UI invariata  
✔ logica invariata  

👉 refactor considerato stabile

### Stato fase

👉 **Fase 1 — COMPLETATA**

### Prossimo step

Fase 2 — Dialog / BottomSheet extraction

Non ancora iniziata
---

# 🔥 AGGIORNAMENTO — 23 MARZO 2026 (VALIDAZIONE CONFLITTI + DECISIONE NUOVA FASE UI)

## Stato reale della chat

Durante questa chat il lavoro non è stato di semplice manutenzione visiva.

È stato fatto un passaggio reale di validazione del sistema decisionale sul blocco:

- conflitto turno ↔ evento
- permesso come risoluzione umana
- distinzione tra presenza in casa e logistica esterna

👉 Questo significa che la chat ha lavorato su:

- validazione logica reale
- uso reale del sistema
- pulizia UI minima
- preparazione della prossima riorganizzazione strutturale della schermata

---

## Validazione completa conflitto turno ↔ evento

Il sistema è stato testato direttamente in app reale su un caso concreto.

### Sequenza validata

1. **Conflitto aperto**
   - evento dentro il turno
   - box conflitto mostrato correttamente
   - fascia in conflitto letta correttamente

2. **Conflitto risolto**
   - inserimento permesso sull’intera fascia evento
   - stato aggiornato correttamente in:
     - **Conflitto risolto**
   - causa risoluzione mostrata correttamente:
     - permesso sulla fascia coperta

3. **Conflitto parziale**
   - permesso solo su una parte della fascia
   - stato aggiornato correttamente in:
     - **Conflitto parziale**
   - parte coperta e parte scoperta lette correttamente

4. **Conflitto parziale invertito**
   - permesso spostato sulla seconda metà
   - sistema ancora coerente
   - fascia residua scoperta calcolata correttamente

5. **Ritorno a conflitto aperto**
   - rimozione del permesso
   - sistema tornato correttamente a:
     - **Conflitto aperto**

👉 Stato del blocco:

**VALIDATO REALMENTE IN APP**

---

## Chiarimento strutturale importante — presenza vs logistica

Durante i test è stato chiarito un punto fondamentale del sistema:

### Malattia a letto

- la persona è considerata **presente in casa**
- quindi può evitare un buco di semplice presenza
- ma **non può coprire logistica esterna**

Esempio corretto:

- Alice a casa + adulto malattia a letto in casa
  - **nessun buco di presenza**

- Alice da portare / prendere fuori
  - se manca altra persona disponibile
  - **buco reale di logistica**

👉 Questa distinzione è stata verificata direttamente in app ed è risultata coerente con la realtà.

---

## Pulizia UI effettuata

È stata rimossa dalla schermata la chiamata:

- `_turnOverrideDebugBox()`

Risultato:

- sparite le righe debug tipo:
  - “Matteo oggi: nessuno”
  - “Chiara oggi: nessuno”
- card Turni più pulita
- nessuna regressione osservata
- app avviata correttamente dopo modifica

👉 Stato:

**FATTO e verificato in app reale**

---

## Nuova consapevolezza sulla fase del progetto

Durante la chat è stato chiarito che il progetto, in questo punto, non è più in una fase di sola stabilità logica pura.

La situazione reale è questa:

- la logica base del motore è già utilizzabile
- il sistema viene testato su casi reali
- la UI adesso deve aiutare a leggere e decidere meglio

Quindi la fase attuale è da considerare:

### uso reale + validazione decisionale + rifinitura strutturale UI

---

## Problema reale emerso sulla schermata

È stato confermato un problema pratico d’uso:

👉 la colonna **“REALTÀ DEL GIORNO”** è troppo lunga

Effetti reali:

- troppo scroll
- lettura lenta
- difficoltà a capire rapidamente la giornata
- struttura non più allineata al modo reale in cui il sistema viene usato

---

## Decisione presa per la prossima chat

È stata presa una decisione strutturale chiara:

### prossima modifica da fare:
separare la schermata in 3 blocchi distinti

1. **Realtà del giorno**
   - turni
   - eventi adulti
   - stato persone

2. **Alice / Scuola**
   - scuola
   - eventi Alice
   - accompagnamenti / coperture scuola

3. **Buchi / Decisioni**
   - buchi reali
   - conflitti
   - azioni e decisioni

⚠️ Nota importante:

- questa modifica NON è ancora stata implementata in questa chat
- è stata solo decisa e preparata
- verrà fatta nella prossima chat lavorando sul file completo reale

---

## Stato finale a chiusura chat

- app aperta e funzionante
- nessun errore rosso
- conflitto turno ↔ evento validato
- distinzione presenza/logistica validata
- debug UI rimosso
- prossima direzione UI chiarita

👉 Stato generale:

**sistema stabile, coerente e pronto per la prossima riorganizzazione della schermata**

---

## Nuovo prossimo passo ufficiale

Il prossimo passo corretto ora è:

- aprire nuova chat
- inviare file completo reale `calendario_screen_stepa.dart`
- applicare in modo sicuro la nuova struttura UI in 3 blocchi
- senza toccare la logica del motore

---

## Frase di ripartenza aggiornata

Ripartiamo da FrodoDesk — validato conflitto turno/evento + presenza vs logistica + rimozione debug UI fatta; prossimo passo: separazione schermata in 3 blocchi (Realtà / Alice / Buchi) lavorando sul file completo reale.
---

# 🔥 AGGIORNAMENTO — 24 MARZO 2026 (UI 3 BLOCCHI + QUARTA SQUADRA DENTRO TURNI + METODO ANTI-TIMEOUT)

## Stato reale della chat

In questa chat è stata eseguita una modifica reale sul file:

`lib/screens/calendario_screen_stepa.dart`

con verifica finale positiva in app reale.

La chat ha anche chiarito e consolidato un nuovo metodo tecnico obbligatorio per lavorare sui file molto grandi senza perdere continuità operativa.

---

## Modifica UI realmente applicata

La schermata calendario è stata riorganizzata in **3 blocchi distinti**.

### Nuova struttura reale

1. **REALTÀ DEL GIORNO**  
2. **ALICE / SCUOLA**  
3. **BUCHI / DECISIONI**

### Effetto pratico

Questa separazione ha migliorato la leggibilità della schermata e ha confermato che la direzione UX/UI è corretta per l’uso reale.

Validazione utente emersa in chat:

- schermata percepita **più chiara**
- ma ancora **non abbastanza compatta**
- serve ulteriore lavoro sulla riduzione della lunghezza verticale

---

## Quarta Squadra spostata dentro Turni

Durante la stessa chat è stata applicata una modifica strutturale UI importante:

👉 **Quarta Squadra non è più mostrata come blocco separato nella colonna principale**

Ora viene richiamata dalla card **Turni** tramite bottone dedicato, mantenendo la logica esistente intatta.

### Significato della modifica

Questa decisione riflette meglio la natura reale della Quarta Squadra:

- non è “realtà del giorno”
- è una **azione strutturale sui turni**

Quindi è stata correttamente avvicinata a:

- Cambio turno (solo oggi)
- Cambio turno (periodo)
- Nuova rotazione
- Rimuovi nuova rotazione

### Stato

✔ modifica applicata  
✔ app avviata correttamente  
✔ nessun errore rosso  
✔ logica preservata  

---

## Verifica reale conclusiva

Dopo la modifica completa:

- il file è stato ricostruito correttamente
- la restituzione è avvenuta in blocchi
- l’utente ha ricopiato il file
- l’app è partita correttamente

Esito confermato:

👉 **funziona**

---

## Nuova criticità emersa in uso reale

Dopo la riorganizzazione, l’utente ha osservato un problema UX concreto:

### Alice / Scuola → Periodi salvati Alice

Quando i periodi salvati aumentano, la lista verticale cresce troppo e rende la schermata ancora lunga.

### Decisione operativa presa

Il prossimo intervento corretto NON è sul motore logico.

Il prossimo intervento ufficiale è:

👉 rendere **“Periodi salvati Alice” espandibile / collapsable**

Motivazione:

- evitare lista infinita
- ridurre altezza verticale
- aprire il dettaglio solo quando serve
- mantenere continuità con la nuova filosofia UI basata su sezioni comprimibili

---

## Nuovo stato della fase progetto

La chat conferma ancora una volta che:

👉 la fase di stabilità logica del calendario è chiusa  
👉 la fase attuale è **UX/UI reale + usabilità + contenimento della complessità visiva**

---

## Nuovo metodo tecnico consolidato — file molto grandi

Durante questa chat è stato consolidato definitivamente un nuovo metodo operativo per i file grandi come:

`calendario_screen_stepa.dart`

### Problema reale emerso

Quando il file è troppo lungo, la risposta completa in un unico messaggio può:

- interrompersi
- andare in timeout
- risultare incompleta
- bloccare il flusso di lavoro

### Metodo corretto deciso e validato

Se la modifica è strutturale e il file è molto grande:

1. Matteo invia il file reale completo  
2. Frodo modifica l’intero file  
3. Frodo restituisce il file completo in blocchi ordinati  

Formato operativo valido:

- BLOCCO 1
- BLOCCO 2
- BLOCCO 3

L’utente:

- cancella il file originale
- incolla i blocchi nell’ordine
- salva
- testa in app reale

### Stato del metodo

✔ testato nella pratica  
✔ necessario  
✔ da considerare standard ufficiale quando serve  

Principio consolidato:

👉 meglio più blocchi completi che una risposta unica troncata

---

## Stato attuale della schermata

La schermata calendario ora è:

✔ più leggibile di prima  
✔ separata in aree logiche corrette  
✔ più coerente con l’uso reale  

ma ancora:

⚠️ non abbastanza compatta  
⚠️ ancora migliorabile sulle liste lunghe  
⚠️ ancora da alleggerire visivamente in alcune sezioni

---

## Prossimo passo ufficiale aggiornato

Il prossimo passo corretto ora è:

### **Periodi salvati Alice → blocco espandibile / collapsable**

Solo dopo si continuerà con altre rifiniture UX/UI della schermata.

---

## Frase di ripartenza aggiornata

Ripartiamo da FrodoDesk — UI in 3 blocchi applicata e verificata + Quarta Squadra spostata dentro Turni + metodo file grandi a blocchi consolidato; prossimo passo: rendere “Periodi salvati Alice” espandibile/collapsable per ridurre la lunghezza della schermata.

---

# 🔥 AGGIORNAMENTO — 24 MARZO 2026 (TURNI: FONTE TURNO VISIBILE + PERMESSO COME AZIONE RAPIDA)

## Stato reale della chat

In questa chat il lavoro è rimasto nel file:

`lib/screens/calendario_screen_stepa.dart`

con una rifinitura UI reale e verificata in app, più un riassetto locale del file:

`lib/widgets/stepb_override_panel.dart`

per rendere il permesso più rapido da usare nella pratica quotidiana.

La modifica NON ha toccato il motore di copertura.

Ha toccato:

- leggibilità immediata dei turni
- posizione UI del permesso
- velocità operativa di inserimento/rimozione permesso

---

## Fonte turno resa visibile nella card Turni

È stata introdotta una lettura esplicita della **fonte del turno mostrato** accanto alla riga persona quando il turno deriva da una fonte strutturale diversa dalla rotazione base.

### Casi ora visibili

Il sistema può mostrare in riga turno, accanto all’orario:

- **Quarta squadra**
- **Nuova rotazione**
- **Cambio turno (solo oggi)**
- **Cambio turno (periodo)**

### Significato pratico

Prima il turno cambiava correttamente, ma non era sempre chiaro **perché** fosse quello.

Adesso nella card Turni si vede subito se il turno deriva da:

- override manuale
- nuova rotazione
- quarta squadra

Questo migliora l’uso reale perché rende leggibile la giornata senza dover ricordare a memoria quale meccanismo è attivo.

### Verifica reale effettuata

Caso reale verificato in app:

- Chiara in giorno coperto da **Quarta Squadra**
- la riga Turni mostra correttamente:
  - turno della giornata
  - etichetta **Quarta squadra**

👉 risultato validato positivamente in uso reale.

---

## Permesso separato dallo “stato giornaliero”

Durante questa chat è stata chiarita e applicata una decisione UX importante:

👉 **Permesso non è uno stato persona come malattia o ferie**
👉 è una **azione operativa sulla giornata**, simile ai controlli turni.

Per questo motivo il permesso è stato spostato dalla zona “stato giornaliero” alla card **Turni**, sotto i pulsanti operativi.

### Nuova posizione

Dentro la card Turni ora il permesso vive come azione dedicata, vicina a:

- Cambio turno (solo oggi)
- Cambio turno (periodo)
- Nuova rotazione
- Quarta squadra

### Significato strutturale

Questa modifica allinea la UI alla logica reale di FrodoDesk:

- malattia / ferie = stati della persona
- permesso = azione operativa sulla giornata

---

## Nuovo comportamento UI del permesso

Il componente `stepb_override_panel.dart` è stato semplificato e reso più pratico.

### Prima

- presenza di tendina / gestione più tecnica
- il permesso era meno immediato da usare

### Ora

- compare un bottone **Apri permessi**
- aprendolo si vedono:
  - Matteo
  - Chiara
- per ciascuno:
  - bottone **Permesso**
  - popup orario
  - se attivo: bottone **Rimuovi permesso**
  - orario visibile sotto

### Comportamento reale validato

Test effettuato in app:

- inserito permesso reale su Chiara
- selezionata fascia oraria serale
- il sistema ha mostrato correttamente in Turni:
  - **Stato: Permesso 21:00–22:00**
- il bottone di rimozione ha funzionato correttamente
- il permesso può quindi essere:
  - creato
  - visualizzato
  - rimosso
  in modo rapido e coerente

👉 risultato confermato come **molto efficace in uso reale**.

---

## Esito pratico della modifica

Questa rifinitura ha prodotto tre miglioramenti reali:

1. **maggiore chiarezza della fonte turno**
2. **permesso più rapido da inserire**
3. **minor confusione tra stato persona e azione operativa**

La modifica è risultata particolarmente riuscita perché il permesso ora:

- si imposta in pochi tocchi
- si vede subito nei Turni
- si rimuove rapidamente
- non sporca più la logica mentale dello “stato giornaliero”

---

## Stato finale a chiusura chat

- app funzionante
- nessun errore rosso
- fonte turno visibile correttamente
- quarta squadra visibile in riga turno
- permesso spostato nella card Turni
- apri/chiudi permessi funzionante
- popup orario permesso funzionante
- rimozione permesso funzionante
- stato turno aggiornato correttamente dopo inserimento permesso

👉 modifica considerata **stabile e riuscita in uso reale**

---

## Effetto sulla fase progetto

Questa chat conferma ancora la direzione attuale del progetto:

👉 motore stabile  
👉 interventi concentrati su **uso reale, chiarezza e velocità operativa**

Non è una modifica “estetica”.

È una modifica di **qualità d’uso reale del calendario**.

---

## Prossimo passo

Dopo questa rifinitura, il prossimo passo ufficiale NON cambia.

Resta:

### **Periodi salvati Alice → blocco espandibile / collapsable**

per continuare a ridurre la lunghezza verticale della schermata.

---

## Nuova frase di ripartenza aggiornata

Ripartiamo da FrodoDesk — fonte turno visibile in card Turni + permesso spostato come azione rapida dentro Turni e validato in app; prossimo passo: rendere “Periodi salvati Alice” espandibile/collapsable per ridurre la lunghezza della schermata.