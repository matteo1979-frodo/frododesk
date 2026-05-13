# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 12 Maggio 2026  
(BLOCCO G — Motore Presenza Reale Alice)

---

# IDENTITÀ DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Principio fondamentale:

👉 Il sistema suggerisce  
👉 La decisione resta sempre umana

---

# FILOSOFIA DI SVILUPPO

Il sistema è costruito con filosofia CNC:

- un passo alla volta
- zero modifiche multiple insieme
- ogni blocco deve essere stabile prima di passare al successivo
- lavoro sempre su file reali
- motore prima
- UI dopo
- test reale continuo

---

# FASE ATTUALE DEL PROGETTO

🔥 CALENDARIO REALE COMPLETO  
🔥 COPERTURA REALE CONSOLIDATA  
🔥 HOME AZIONABILE V1.1 CONSOLIDATA  
🔥 EVENTI GLOBALI V1  
🔥 MODULO STATISTICHE AVVIATO  
🔥 MOTORE PRESENZA REALE ALICE IN CONSOLIDAMENTO

Il sistema è:

✔ utilizzabile nella vita reale  
✔ testato su casi concreti  
✔ stabile nei motori principali  
✔ coerente tra motore → calendario → Home  
✔ capace di distinguere oggi e problemi futuri  
✔ capace di trasformare un buco reale in problema visibile  
✔ capace di portare direttamente al giorno del problema  
✔ capace di navigare eventi nel tempo  
✔ capace di salvare memoria reale sugli eventi  
✔ entrato nella fase di simulazione presenza reale Alice  

---

# EVOLUZIONE STRUTTURALE

Il sistema ha fatto questi passaggi:

❌ simulazione parziale  
✔ simulazione reale della giornata  

❌ Home solo informativa  
✔ Home operativa e gerarchica  

❌ eventi temporanei  
✔ eventi come memoria persistente  

🔥 NUOVO PASSAGGIO:

❌ Alice come semplice evento/calendario  
✔ Alice come presenza reale nel tempo  

---

# BLOCCO SCUOLA

Stato: COMPLETATO

✔ SchoolStore attivo  
✔ Periodi funzionanti  
✔ Orari letti correttamente  
✔ Stato Alice coerente  
✔ Support network validato  
✔ UI allineata al motore  
✔ Giorni festivi riconosciuti correttamente  

---

# BLOCCO COPERTURA REALE

Stato: COMPLETATO / CONSOLIDATO

---

## REGOLA FONDAMENTALE

Alice deve essere coperta quando è realmente a casa.

La copertura dipende da:

- Matteo
- Chiara
- rete supporto
- Sandra se attiva nella fascia corretta
- eventi reali
- scuola
- centro estivo
- accompagnamento
- rientro reale a casa

---

## RISULTATO

✔ Buchi reali corretti  
✔ Eventi reali influenzano la copertura  
✔ Supporto integrato correttamente  
✔ Calendario coerente  
✔ Home coerente  
✔ giorni festivi corretti  
✔ Sandra separata dalla rete supporto  

---

# BLOCCO HOME AZIONABILE V1.1

Stato: COMPLETATO E VALIDATO

La Home:

✔ legge i buchi reali della copertura  
✔ separa stato reale di oggi e problema futuro  
✔ mostra il problema principale  
✔ apre il calendario sul giorno corretto  
✔ non propone soluzioni automatiche  
✔ mantiene decisione umana  

---

# BLOCCO EVENTI GLOBALI

Stato: IMPLEMENTATO V1

✔ navigazione anno → mesi → eventi  
✔ mesi in griglia  
✔ dettaglio evento  
✔ memoria evento persistente  
✔ eventi multi-persona  

Limite attuale:

❌ Eventi Alice non ancora completamente integrati negli Eventi Globali

---

# BLOCCO STATISTICHE

Stato: AVVIATO / BASE STRUTTURALE CONSOLIDATA

Principio:

👉 le statistiche leggono solo dati reali vivi  
👉 non inventano dati  
👉 sono supporto decisionale, non decorazione

Struttura temporale:

✔ Giorno  
✔ Settimana  
✔ Mese  
✔ Anno  

---

# BLOCCO G — MOTORE PRESENZA REALE ALICE

Stato: IN CONSOLIDAMENTO AVANZATO

---

## OBIETTIVO

Centralizzare la domanda:

👉 “Dove si trova realmente Alice in questa fascia?”

---

## FILE / COMPONENTI CREATI

✔ `lib/logic/alice_presence_engine.dart`  
✔ `lib/models/alice_presence_state.dart`  

---

## STATI PRESENZA ATTUALI

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Mancano:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

## COMPLETATO NEL BLOCCO G

☑ creare `alice_presence_engine.dart`  
☑ creare `AlicePresenceState`  
☑ centralizzare primo stato presenza Alice  
☑ collegare CoverageEngine al motore presenza  
☑ centralizzare evento reale Alice  
☑ centralizzare evento temporizzato Alice  
☑ introdurre `AlicePresenceState.accompanied`  
☑ collegare `AliceCompanionStore`  
☑ introdurre presenza relazionale  
☑ introdurre `findCompanionForRange()`  
☑ CoverageEngine legge `stateForRange()`  
☑ introdurre `AlicePresenceState.support`  
☑ collegare `SupportNetworkStore`  
☑ collegare `DaySettingsStore`  
☑ distinguere supporto reale attivo sulla fascia  
☑ scuola resa temporale reale  
☑ centro estivo reso temporale reale  
☑ centralizzare accesso eventi temporizzati Alice  
☑ centralizzare copertura rete supporto  
☑ centralizzare controllo evento reale Alice  
☑ CoverageEngine ridotto a consumatore progressivo del PresenceEngine  

---

# BUG CENTRO ESTIVO RISOLTO

Caso reale testato:

- centro estivo attivo
- uscita 16:30
- rientro logistico 20 minuti
- Matteo e Chiara entrambi pomeriggio
- supporto parziale possibile
- Sandra sera separata

Prima:

❌ uscita centro estivo mostrata fino alle 18:00  
❌ mancava il buco casa 16:50–21:00  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ Alice a casa dopo centro estivo 16:50–21:00  
✔ fascia Sandra sera 21:00–22:35 separata  
✔ supporto reale spezza correttamente i buchi  

Checkpoint:

`summer-camp-real-home-gaps`

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione eventi reali corretta  
✔ gestione supporto corretta  
✔ gestione Alice a casa corretta  
✔ gestione giorni festivi corretta  
✔ buchi reali letti dalla Home  
✔ PresenceEngine inizia a guidare la logica Alice  

---

# STATO EVENTI ALICE

✔ AliceEventStore attivo  
✔ AliceSpecialEventStore attivo  
✔ eventi integrati nel motore  
✔ eventi accompagnati funzionanti  
✔ companion automatiche funzionanti  
✔ cleanup lifecycle funzionante  
✔ eventi temporizzati letti dal PresenceEngine  
❌ non ancora completamente integrati negli Eventi Globali  

---

# MOTORI ATTIVI

- TurnEngine  
- CoverageEngine  
- AlicePresenceEngine  
- EmergencyDayLogic  
- FourthShiftCycleLogic  

---

# STORE PRINCIPALI

- CoreStore  
- OverrideStore  
- TurnOverrideStore  
- RotationOverrideStore  
- RealEventStore  
- AliceEventStore  
- AliceSpecialEventStore  
- AliceCompanionStore  
- SupportNetworkStore  
- FeriePeriodStore  
- DiseasePeriodStore  
- FourthShiftStore  
- SettingsStore  
- DaySettingsStore  
- SummerCampScheduleStore  
- SummerCampSpecialEventStore  
- SchoolStore  

---

# STATO UI

✔ calendario funzionante  
✔ eventi reali integrati  
✔ stato Alice coerente  
✔ Home collegata al motore reale  
✔ Home separa oggi vs futuro  
✔ navigazione diretta al problema  
✔ Eventi Globali navigabili  
✔ mesi in griglia FrodoDesk  
✔ scheda evento con memoria  

Nota:

👉 Home non è ancora guidata direttamente dal PresenceEngine.

---

# STATO IPS

⚠️ NON ancora coerente con il sistema reale

Decisione:

👉 IPS resta rimandato fino al completamento del Motore Presenza Reale Alice.

---

# PROSSIMA FASE OPERATIVA

Non fare Home.  
Non fare IPS.

Prossimo fronte:

👉 continuare la pulizia di CoverageEngine dai residui legacy presenza Alice.

In particolare:

⬜ eliminare altri doppioni logici  
⬜ valutare spostamento segmentazione eventi/tagli fascia  
⬜ verificare logiche presenza Alice ancora dirette dentro `analyzeDayV2()`  
⬜ solo dopo → Home guidata dal PresenceEngine  

---

# DIREZIONE OPERATIVA

✔ un passo alla volta  
✔ motore prima  
✔ UI dopo  
✔ test reale continuo  
✔ decisione sempre umana  
✔ file reali sempre  
✔ nessun mega-refactor  

---

# SIGNIFICATO ATTUALE

FrodoDesk ora non sta più solo leggendo eventi.

Sta iniziando a modellare:

👉 presenza reale familiare  
👉 presenza relazionale  
👉 stato Alice nel tempo  
👉 copertura reale dinamica  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — BLOCCO G: PresenceEngine già attivo, CoverageEngine in progressiva pulizia. Prossimo passo: eliminare residui legacy di presenza Alice dentro CoverageEngine senza toccare Home e senza riallineare IPS.