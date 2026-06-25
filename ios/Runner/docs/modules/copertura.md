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
---

# 🔄 AGGIORNAMENTO 14 Maggio 2026

# CONSOLIDAMENTO STEP G3 — PRESENCE ENGINE

Il modulo Copertura sta entrando nella nuova fase strutturale:

👉 CoverageEngine smette progressivamente di interpretare Alice direttamente.

La presenza reale Alice viene centralizzata nel:

`alice_presence_engine.dart`

---

# OBIETTIVO STRUTTURALE

CoverageEngine deve diventare:

✔ motore copertura  
✔ interprete buchi  
✔ lettore range reali  

e NON più:

❌ proprietario presenza Alice  
❌ segmentatore manuale eventi Alice  
❌ lettore diretto CompanionStore  

---

# CENTRALIZZAZIONI COMPLETATE

Completato:

☑ centralizzazione accompagnamento Alice
☑ centralizzazione overlap accompagnamento
☑ centralizzazione companion end
☑ centralizzazione support network reale
☑ centralizzazione eventi reali Alice
☑ centralizzazione eventi temporizzati Alice

---

# NUOVE API PRESENCE ENGINE

Introdotte:

✔ `isAliceAccompaniedDuringRange()`
✔ `aliceCompanionEndForRange()`

CoverageEngine ora legge il PresenceEngine invece di leggere direttamente:

- CompanionStore
- supporti accompagnamento
- overlap manuali

---

# RIMOZIONE DIPENDENZE DIRETTE

Eliminato:

☑ `_getAliceCompanionEnd()`

CoverageEngine NON legge più direttamente CompanionStore in:

☑ `_isFasciaCovered()`
☑ `_uncoveredHomeSegments()`
☑ filtro finale `analyzeDayV2()`

---

# FIX STRUTTURALE — BUCHI DUPLICATI

## Problema reale

Caso testato:

- evento reale 21:00–22:30
- supporto reale 21:00–22:00

Risultato errato precedente:

❌ doppio buco:
- 21:00–22:30
- 22:00–22:30

Il motore manteneva ancora un gap legacy serale completo.

---

# CAUSA

CoverageEngine continuava a generare:

- fascia Sandra legacy
- gap completo legacy

anche dopo segmentazione reale support network.

---

# SOLUZIONE

Aggiunto filtro strutturale anti-duplicazione:

✔ il motore verifica ora:
- presenza gap Alice reale già esistente
- stessa fascia iniziale

e impedisce creazione doppione legacy.

---

# RISULTATO

Ora il sistema genera correttamente:

✔ SOLO il residuo reale:
22:00–22:30

---

# SIGNIFICATO STRUTTURALE

Questo fix conferma il cambio architetturale reale:

❌ fasce statiche legacy
❌ blocchi artificiali

→ sostituiti progressivamente da:

✔ segmentazione reale
✔ range reali
✔ copertura reale
✔ supporto reale parziale

---

# STATO ATTUALE STEP G3

Completato:

☑ CoverageEngine legge PresenceEngine per presenza Alice
☑ accompagnamento centralizzato
☑ support network centralizzato
☑ eventi reali centralizzati
☑ fix duplicazione buchi legacy
☑ supporto reale parziale funzionante

Residui ancora presenti:

⬜ segmentazione legacy dentro analyzeDayV2()
⬜ tagli temporali legacy
⬜ logiche “Alice a casa dopo…”
⬜ letture dirette store Alice residue

---

# DIREZIONE UFFICIALE

CoverageEngine deve progressivamente:

❌ smettere di interpretare Alice
❌ smettere di conoscere CompanionStore
❌ smettere di segmentare presenza Alice

e diventare:

✔ consumatore puro del PresenceEngine
✔ motore copertura reale
✔ interprete buchi
✔ NON proprietario presenza Alice

---

---

# 🌍 EVOLUZIONE STRUTTURALE FUTURA — MULTI FAMIGLIA

## PRINCIPIO

Il modulo Copertura NON deve restare legato a persone specifiche.

I nomi:

- Matteo
- Chiara
- Alice
- Sandra

devono essere considerati esempi della famiglia attuale.

In futuro il motore dovrà funzionare per qualsiasi famiglia.

Esempio:

- Figlio 1
- Figlio 2
- Figlio 3
- Supporto esterno
- Babysitter
- Nonno
- Zio

senza modifiche al motore.

---

## DIREZIONE

CoverageEngine deve ragionare su:

✔ Persone
✔ Ruoli
✔ Disponibilità
✔ Presenza reale

e NON sui nomi delle persone.

---

## OBIETTIVO FUTURO

Permettere a qualsiasi nuova famiglia di:

- creare i propri membri
- definire i propri supporti
- usare il motore copertura senza configurazioni tecniche

Il motore deve essere universale.

---

## NOTA

Questa evoluzione NON è prioritaria nella fase attuale.

Priorità attuale:

✔ completamento calendario reale
✔ stabilizzazione copertura
✔ test vita reale

La trasformazione multi-famiglia verrà affrontata in una fase successiva.

# PROSSIMO STEP

Continuare consolidamento STEP G3.

NON lavorare ancora su:

❌ Home
❌ IPS

Lavorare invece su:

👉 eliminazione residui legacy CoverageEngine
👉 segmentazione eventi Alice
👉 tagli temporali
👉 logiche presenza ancora dirette dentro analyzeDayV2()