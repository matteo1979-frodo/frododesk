# FRODODESK — MODULO COPERTURA

Ultimo aggiornamento: 1 Maggio 2026 (fix giorni festivi + coerenza Home)

---

# IDENTITÀ DEL MODULO

Questo modulo gestisce la **copertura reale della giornata di Alice**.

Obiettivo:

- capire se Alice è coperta o no
- individuare i buchi reali
- supportare decisioni operative

👉 Questo è il cuore decisionale di FrodoDesk

---

# PRINCIPIO FONDAMENTALE

La copertura NON è:

❌ teoria  
❌ calendario  
❌ presenza generica  

👉 È simulazione reale della giornata

---

# CONCETTI BASE

## 1. PRESENZA ≠ LOGISTICA

Distinzione fondamentale:

- **Presenza in casa**
- **Logistica esterna**

Esempio:

- adulto malato a letto:
  - ✔ presenza → sì
  - ❌ logistica → no

---

## 2. REGOLA MADRE — ALICE A CASA

👉 Questa è la regola più importante del sistema.

Alice è considerata **A CASA** quando NON è:

- a scuola
- in evento valido (danza, pallavolo, centro estivo, gita, ecc.)
- fuori casa per attività tracciata

---

## 🔥 AGGIORNAMENTO — GIORNI FESTIVI

### Problema emerso

Nei giorni festivi (es. 1 maggio):

- Alice risultava correttamente senza scuola  
- ma NON sempre veniva generato il buco  

---

### Causa

Il sistema considerava Alice a casa solo in questi casi:

- evento Alice  
- weekend  

👉 mancava il caso:

- giorno senza scuola  
- NON weekend  
- NON evento  

---

### Soluzione

Alice è considerata **a casa anche quando**:

- non c’è scuola  
- non è weekend  
- non c’è centro estivo attivo  

---

### Regola aggiornata

👉 Se NON c’è scuola → Alice è a casa

E quindi:

👉 si applica SEMPRE la regola copertura

---

### Risultato

✔ Giorni festivi corretti  
✔ Buco generato correttamente  
✔ Coerenza completa tra motore e Home  

---

## 3. REGOLA COPERTURA

Se Alice è a casa:

👉 deve essere SEMPRE coperta da almeno uno tra:

- Matteo
- Chiara
- Sandra (solo se attiva nella fascia)
- Rete di supporto

Se nessuno copre:

👉 ❌ BUCO REALE (sempre)

✔ Regola valida su tutta la giornata  
✔ NON limitata a fasce Sandra  
✔ NON limitata alla scuola  

---

## 4. EVENTI DI ALICE

Gli eventi influenzano la copertura:

- Alice fuori casa → ✔ coperta automaticamente
- Alice a casa → serve copertura reale

---

# MOTORE PRINCIPALE

File principale:

👉 `coverage_engine.dart`

Il motore:

- legge turni
- legge eventi reali
- legge eventi Alice
- legge stati (ferie, malattia)
- legge supporto
- calcola presenza reale
- calcola buchi su tutta la giornata

---

# INPUT DEL MOTORE

- TurnEngine
- RealEventStore
- AliceEventStore
- AliceSpecialEventStore
- DiseasePeriodStore
- FeriePeriodStore
- SupportNetworkStore
- DaySettingsStore
- SchoolStore

---

# OUTPUT DEL MOTORE

- ✔ Copertura OK
- ✔ Buchi del giorno REALI
- ✔ Fasce scoperte reali
- ✔ Stato Sandra (informativo, non vincolante)

---

# LOGICA BUCHI (AGGIORNATA)

Un buco esiste quando:

👉 Alice è a casa  
👉 e NON c’è copertura reale  

✔ controllo su tutta la giornata (00:00–23:59)  
❌ NON limitato a fasce Sandra  
❌ NON limitato a scuola  

---

# COPERTURA COMBINATA

Il sistema combina:

- Matteo
- Chiara
- Supporto

👉 anche su segmenti diversi della stessa fascia

✔ sistema continuo  
✔ non blocchi rigidi  

---

# USCITA IMPRESCINDIBILE (REGOLA)

👉 NON elimina il problema  
👉 NON nasconde il buco  

Significa:

- la persona è fuori comunque
- il sistema deve calcolare il buco reale
- il rischio resta visibile

---

# 🔥 STRATO DECISIONALE — AZIONI (AGGIORNATO)

## IDENTITÀ

Questo strato traduce i buchi in:

👉 **problemi azionabili per l’utente**

NON modifica il motore  
👉 interpreta il risultato  

---

## ⚠️ CAMBIAMENTO STRUTTURALE (IMPORTANTE)

Versione precedente:

❌ suggeriva azioni operative  

Versione attuale:

✔ spiega il problema  
✔ porta al punto corretto  
❌ NON suggerisce soluzioni  

👉 Le soluzioni restano **sempre umane**

---

## INPUT

👉 `cov.gapDetails`

---

## OUTPUT

Per ogni problema:

- descrizione chiara
- fascia oraria
- spiegazione sintetica
- azione unica: **vai al problema**

---

## MULTI-PROBLEMA

👉 ogni buco genera un blocco UI

---

## UI

- lista problemi  
- numerazione  
- fascia oraria  
- spiegazione  

👉 per ogni problema:

✔ bottone: **Vai al problema**  
❌ nessuna soluzione proposta  

---

# 🔁 FLUSSO OPERATIVO DEFINITIVO

1. Home rileva buco reale  
2. mostra problema principale  
3. bottone: **RISOLVI**  
4. apertura popup  
5. popup spiega il problema  
6. bottone: **Vai al problema**  
7. apertura calendario nel giorno corretto  
8. decisione presa dall’utente  

---

# 🎯 PRINCIPIO DECISIONALE

Il sistema:

✔ rende visibile la realtà  
✔ spiega il problema  
✔ porta nel punto corretto  

👉 NON deve:

❌ scegliere al posto dell’utente  
❌ proporre soluzioni automatiche  
❌ semplificare decisioni complesse  

---

# 🧠 SIGNIFICATO STRUTTURALE

👉 Il modulo copertura è un **generatore di problemi reali**

---

# 🔥 EVOLUZIONE FUTURA

Estensione a:

- finanze  
- auto  
- salute  
- scadenze  
- manutenzioni  

---

# GESTIONE NOTTE / POST-NOTTE

✔ riposo fino alle 14:30  
✔ già integrato  

---

# GESTIONE EVENTI

✔ eventi = indisponibilità reale  
✔ integrati nel motore  

---

# GESTIONE CENTRO ESTIVO

✔ dinamico (prima/durante/dopo)  

---

# STATO ATTUALE DEL MODULO

✔ motore copertura REALE  
✔ Alice a casa gestita correttamente  
✔ giorni festivi corretti  
✔ buchi reali su tutta la giornata  
✔ eventi reali integrati  
✔ supporto integrato  
✔ Home coerente con motore  
✔ popup RISOLVI coerente  
✔ spiegazione buchi unificata  

⚠️ naming UI da uniformare  
⚠️ rifinitura UX popup  

---

# PROSSIMO STEP

👉 rifinitura UI + coerenza naming

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — Copertura stabile, giorni festivi corretti, Home coerente con motore. Prossimo passo: rifinitura UX e naming popup.

---

# 🔄 AGGIORNAMENTO 11 Maggio 2026

## 🔥 COPERTURA REALE — ALLINEAMENTO HOME / CALENDARIO

È stata corretta una incoerenza strutturale tra Home e Calendario.

---

## BUG RISOLTO — SUPPORTO REALE

Caso reale:

- buco accompagnamento scuola 08:05–08:25
- supporto Beatrice attivo 08:00–08:30

Prima:

❌ Calendario considerava il problema risolto  
❌ Home continuava a mostrare il problema futuro  

Ora:

✔ Calendario e Home sono coerenti  
✔ se il supporto copre completamente la fascia, il buco sparisce  
✔ se il supporto viene tolto, il buco ricompare  
✔ se il supporto viene rimesso, il buco sparisce di nuovo  

---

## REGOLA CONFERMATA

Una copertura supporto è valida SOLO se copre tutto l’intervallo:

supportStart ≤ gapStart  
supportEnd ≥ gapEnd

---

## 🔥 BUG RISOLTO — ALICE DENTRO EVENTO REALE

Caso reale:

Evento reale con partecipanti:

- Matteo
- Chiara
- Alice

Prima:

❌ Matteo risultava fuori per evento reale  
❌ Chiara risultava occupata  
❌ Alice veniva comunque considerata a casa  
❌ il motore generava falso buco “Alice a casa”  

Ora:

✔ Alice viene riconosciuta dentro l’evento reale  
✔ il motore non genera buco casa  
✔ Home non segnala falso problema  
✔ Calendario resta coerente  

---

## NUOVA FUNZIONE STRUTTURALE

Introdotta nel motore:

`_isAliceInsideRealEvent()`

Responsabilità:

✔ verificare se Alice partecipa a un evento reale  
✔ controllare sovrapposizione temporale  
✔ impedire falsi buchi casa durante evento reale  

---

## PRINCIPIO STRUTTURALE

Evento reale con Alice ≠ Alice a casa.

Se Alice partecipa all’evento:

👉 Alice è fisicamente dentro l’evento.

---

## STATO MODULO AGGIORNATO

✔ copertura reale stabile  
✔ supporto reale coerente  
✔ Home e Calendario allineati  
✔ eventi reali multi-persona corretti  
✔ falso buco Alice a casa eliminato  

---

## DIREZIONE PROSSIMA

La copertura non deve più continuare ad accumulare logiche sparse sulla presenza Alice.

Prossimo step strutturale:

👉 creare `alice_presence_engine.dart`

Obiettivo:

✔ centralizzare presenza Alice  
✔ ridurre doppioni nel CoverageEngine  
✔ rendere più stabile Home / Calendario / IPS futuro  

---

## FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — Motore Presenza Reale Alice: centralizzare la presenza di Alice e far leggere CoverageEngine dalla stessa sorgente unica.

---

# 🔄 AGGIORNAMENTO 12 Maggio 2026

# COPERTURA + MOTORE PRESENZA REALE ALICE

## CAMBIO STRUTTURALE

Il modulo Copertura non deve più essere il proprietario diretto della logica di presenza Alice.

Il nuovo flusso corretto è:

AlicePresenceEngine  
↓  
CoverageEngine  
↓  
Calendario / Home / IPS futuro

---

# NUOVO MOTORE COLLEGATO

È stato creato e collegato:

`alice_presence_engine.dart`

Il motore risponde alla domanda:

👉 “Dove si trova realmente Alice in questa fascia?”

---

# MODELLO PRESENZA

È stato introdotto:

`AlicePresenceState`

Stati attuali:

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Stati futuri:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

# CoverageEngine — STATO ATTUALE

CoverageEngine ora legge dal PresenceEngine per:

☑ `isAliceAtHomeDay()`  
☑ `isAliceSchoolNormalDay()`  
☑ `isAliceSummerCampOperationalDay()`  
☑ `getAliceEventTypeForDay()`  
☑ `getSummerCampPeriodForDay()`  
☑ `getSummerCampConfigForDay()`  
☑ `getSummerCampSpecialEventForDay()`  
☑ `hasSummerCampSpecialEventForDay()`  
☑ `enabledTimedEventsForDay()`  
☑ `_isCoveredBySupportNetwork()`  
☑ `_isAliceInsideRealEvent()`  

---

# SUPPORTO REALE

La copertura della rete supporto è ora centralizzata nel PresenceEngine.

Regola confermata:

✔ supporto attivo  
✔ abilitato nel giorno  
✔ copre tutta la fascia reale  

Solo in questo caso il supporto è valido.

---

# SANDRA RESTA SEPARATA

Sandra NON è stata fusa con la rete supporto.

Regola:

- rete supporto = supporti generici
- Sandra = categoria separata con fasce dedicate

---

# CENTRO ESTIVO — FIX REALE

È stato corretto il comportamento del centro estivo.

Caso reale testato:

- centro estivo fino a 16:30
- rientro logistico 20 minuti
- genitori non disponibili
- Sandra sera separata
- supporto parziale possibile

Prima:

❌ uscita centro estivo mostrata 16:30–18:00  
❌ mancava buco reale casa dopo rientro  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ Alice a casa dopo centro estivo 16:50–21:00  
✔ fascia Sandra sera 21:00–22:35 separata  
✔ supporto reale spezza correttamente il buco  

---

# SIGNIFICATO TECNICO

Il sistema ora distingue meglio:

- logistica uscita centro estivo
- rientro a casa
- Alice a casa dopo centro estivo
- fascia Sandra sera
- supporto reale parziale

Questo evita che il centro estivo venga trattato come blocco unico artificiale.

---

# PROSSIMA DIREZIONE

Continuare a ripulire CoverageEngine dai residui legacy.

In particolare:

⬜ segmentazione eventi Alice  
⬜ tagli temporali  
⬜ logiche ancora dirette dentro `analyzeDayV2()`  

Non lavorare ancora su Home.  
Non lavorare ancora su IPS.