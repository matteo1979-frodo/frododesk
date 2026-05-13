# FRODODESK — ARCHITECTURE

Ultimo aggiornamento: 14 Marzo 2026

## PRINCIPIO ARCHITETTURALE

FrodoDesk è costruito con architettura modulare.

Ogni parte del sistema vive in moduli indipendenti.

Obiettivo:
modificare un blocco senza rompere gli altri.

Regola fondamentale:
la logica non deve vivere dentro la UI.

---

# STRUTTURA GENERALE PROGETTO

Struttura principale del progetto:

lib/
 ├─ models
 ├─ logic
 │   ├─ engines
 │   └─ stores
 ├─ widgets
 ├─ screens

Nota:
la cartella `logic` contiene sia i motori del sistema sia gli store che gestiscono lo stato.

---

# MODELS

I models rappresentano le strutture dati del sistema.

Contengono solo dati, senza logica complessa.

Esempi:

DayOverride  
DiseasePeriod  
RealEvent  
WeekIdentity  

---

# LOGIC

La cartella `logic` contiene la logica reale del sistema.

Qui non deve vivere la UI.

La logica è divisa in due grandi gruppi:

- engines
- stores

---

# ENGINES (MOTORI)

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

---

# STORES (STATO SISTEMA)

OverrideStore  
DiseasePeriodStore  
FeriePeriodStore  
SupportNetworkStore  
RealEventStore  
AliceEventStore  

---

# UI

La UI collega i moduli senza mescolare la logica.

Schermata principale attuale:

Calendario reale.

File principale:

lib/screens/calendario_screen_stepa.dart

---

# 🔄 AGGIORNAMENTO 11 Maggio 2026

# NUOVA DIREZIONE ARCHITETTURALE — PRESENZA REALE

## PRINCIPIO

Il sistema sta evolvendo da:

❌ simulazione eventi

👉 a

✔ simulazione presenza reale della famiglia nel tempo

---

# PROBLEMA ARCHITETTURALE IDENTIFICATO

La presenza reale di Alice è oggi distribuita tra più moduli:

- SchoolStore
- AliceEventStore
- RealEventStore
- SupportNetworkStore
- CoverageEngine
- Home
- Stato Ora

Questo crea rischio futuro di:

❌ duplicazioni logiche  
❌ incoerenze  
❌ falsi buchi  
❌ divergenza Home ↔ Calendario ↔ Coverage  

---

# NUOVA DIREZIONE DECISA

La presenza reale deve essere centralizzata.

---

# NUOVO ENGINE PREVISTO

## alice_presence_engine.dart

Responsabilità:

✔ determinare dove si trova Alice realmente  
✔ determinare se Alice è a casa  
✔ determinare se Alice è dentro evento reale  
✔ determinare se Alice è accompagnata  
✔ determinare se Alice è coperta da supporto  
✔ fornire una sola verità al sistema  

---

# PRINCIPIO ARCHITETTURALE NUOVO

CoverageEngine NON deve continuare ad accumulare logiche presenza Alice.

👉 deve leggere una sorgente unica.

---

# FLUSSO FUTURO CORRETTO

SchoolStore
↓
AliceEventStore
↓
RealEventStore
↓
SupportNetworkStore
↓
alice_presence_engine.dart
↓
CoverageEngine / Home / IPS / UI

---

# NUOVO CONCETTO STRUTTURALE

Il sistema deve distinguere:

- evento
- posizione reale
- copertura reale

---

# ESEMPIO IMPORTANTE

Evento reale:

- Matteo
- Chiara
- Alice

NON significa:

❌ Alice a casa

MA:

✔ famiglia fuori insieme

---

# OBIETTIVO

Una sola verità centrale sulla presenza reale di Alice.

---

# DIREZIONE FUTURA

Questa architettura sarà la base per:

- IPS reale
- statistiche reali
- timeline presenza
- comportamento autonomo futuro
- simulazione familiare avanzata

---

# 🔄 AGGIORNAMENTO 12 Maggio 2026

# MOTORE PRESENZA REALE ALICE — CONSOLIDAMENTO ARCHITETTURALE

## STATO

Il motore previsto `alice_presence_engine.dart` è stato creato ed è ora attivo.

Non è più solo una direzione teorica.

---

# NUOVI COMPONENTI ARCHITETTURALI

## `lib/logic/alice_presence_engine.dart`

Responsabilità attuali:

✔ determinare lo stato reale di Alice su una fascia temporale  
✔ distinguere Alice a casa  
✔ distinguere Alice a scuola  
✔ distinguere Alice al centro estivo  
✔ distinguere Alice dentro evento temporizzato  
✔ distinguere Alice dentro evento reale  
✔ distinguere Alice accompagnata  
✔ distinguere Alice coperta da supporto reale  

---

## `lib/models/alice_presence_state.dart`

Modello centrale degli stati presenza Alice.

Stati attuali:

- home
- school
- timedEvent
- realEvent
- summerCamp
- accompanied
- support

Stati futuri previsti:

- outsideWithFamily
- autonomousFuture

---

# NUOVO FLUSSO ARCHITETTURALE REALE

La direzione ora è:

Store reali
↓
AlicePresenceEngine
↓
CoverageEngine
↓
Calendario / Home / IPS futuro

---

# CoverageEngine — NUOVO RUOLO

CoverageEngine sta passando da:

❌ proprietario della logica presenza Alice

a:

✔ consumatore della verità fornita da AlicePresenceEngine

---

# LOGICHE GIÀ CENTRALIZZATE NEL PRESENCE ENGINE

✔ giorno Alice a casa  
✔ giorno scuola normale  
✔ centro estivo operativo  
✔ tipo evento Alice  
✔ periodo centro estivo  
✔ configurazione centro estivo  
✔ evento speciale centro estivo  
✔ eventi temporizzati Alice ordinati  
✔ evento reale con Alice  
✔ copertura rete supporto  
✔ stato presenza su fascia tramite `stateForRange()`  

---

# BUG CENTRO ESTIVO RISOLTO

È stato risolto un bug strutturale del centro estivo:

Prima:

❌ uscita centro estivo mostrata fino alle 18:00  
❌ mancava il buco casa dopo rientro  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ Alice a casa dopo centro estivo 16:50–21:00  
✔ fascia Sandra sera separata 21:00–22:35  
✔ supporto reale spezza correttamente i buchi  

---

# PRINCIPIO ARCHITETTURALE CONSOLIDATO

Alice non deve essere interpretata da UI o da logiche sparse.

La domanda:

👉 “Dove si trova realmente Alice in questa fascia?”

deve essere gestita da una sorgente centrale:

👉 `AlicePresenceEngine`

---

# PROSSIMA DIREZIONE ARCHITETTURALE

Continuare la pulizia progressiva di CoverageEngine:

⬜ eliminare residui legacy  
⬜ valutare spostamento segmentazione eventi Alice  
⬜ valutare spostamento tagli temporali  
⬜ solo dopo collegare Home direttamente alla stessa verità  
⬜ IPS solo dopo consolidamento completo  
