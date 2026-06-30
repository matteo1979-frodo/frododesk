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

# NUOVA DIREZIONE ARCHITETTURALE — MULTI FAMIGLIA

## DECISIONE UFFICIALE (GIUGNO 2026)

FrodoDesk non viene più considerato esclusivamente il sistema della famiglia attuale.

La famiglia:

* Matteo
* Chiara
* Alice

rappresenta il primo caso reale di utilizzo e collaudo.

L'architettura futura dovrà supportare qualsiasi famiglia senza modifiche strutturali.

---

## PRINCIPIO

I motori del sistema non devono dipendere da:

* nomi specifici
* persone specifiche
* strutture familiari fisse

Devono lavorare tramite:

* persone
* ruoli
* relazioni
* permessi

---

## EVOLUZIONE PREVISTA

Direzione futura:

Famiglia
↓
Persone
↓
Ruoli
↓
Motori

E NON:

Matteo
↓
Chiara
↓
Alice
↓
Logiche dedicate

---

## CLOUD

L'architettura dovrà prevedere una futura sorgente dati condivisa.

Obiettivo:

* PC
* telefono
* tablet

devono leggere gli stessi dati.

La sincronizzazione sostituirà le attuali procedure manuali di esportazione/importazione.

---

## RUOLI FUTURI

L'architettura dovrà supportare:

### Amministratore

* gestione famiglia
* gestione utenti
* gestione permessi

### Adulto

* utilizzo moduli autorizzati

### Accesso limitato

* accesso parziale ai moduli

### Utente esterno autorizzato

* accesso limitato a specifiche aree

Esempi:

* babysitter
* allenatore
* insegnante
* commercialista

---

## OBIETTIVO

Trasformare progressivamente FrodoDesk da:

"sistema reale della famiglia attuale"

a:

"motore universale di organizzazione della vita familiare".


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

---

# 🔄 AGGIORNAMENTO GIUGNO 2026

# OBSERVATION ENGINE — NUOVO PILASTRO ARCHITETTURALE

## PRINCIPIO

FrodoDesk non deve limitarsi a registrare dati.

FrodoDesk deve:

✔ osservare
✔ interpretare
✔ ordinare
✔ raccontare
✔ aiutare a decidere

---

# NUOVO CONCETTO CENTRALE

È stato introdotto il concetto di:

## `FrodoObservation`

Una osservazione non è una notifica.

È un oggetto vivo che rappresenta qualcosa che FrodoDesk ha capito dalla vita reale della famiglia.

---

# OSSERVAZIONI VIVE

Una osservazione può essere:

* attiva
* risolta
* ignorata
* scaduta

Può avere:

* priorità
* peso
* livello
* categoria
* motivazione
* scadenza
* azione collegata
* tag
* collegamento al modulo sorgente

---

# LIVELLI OSSERVAZIONE

Livelli ufficiali:

* info
* attention
* problem
* opportunity
* success

---

# NUOVI COMPONENTI ARCHITETTURALI

Creati:

```text
lib/models/frodo_observation.dart
lib/engines/observation/observation_engine.dart
lib/engines/observation/observation_provider.dart
lib/engines/observation/observation_registry.dart
lib/engines/observation/modules/spese_observation_provider.dart
lib/core/frododesk_bootstrap.dart
```

---

# OBSERVATION ENGINE

Responsabilità iniziali:

✔ raccogliere osservazioni dai provider registrati
✔ filtrare osservazioni attive
✔ ignorare osservazioni scadute
✔ ordinare per livello, priorità e peso
✔ selezionare le osservazioni migliori per la Home

---

# OBSERVATION PROVIDER

Ogni modulo futuro potrà produrre osservazioni tramite un provider.

Esempi previsti:

```text
SpeseObservationProvider
FinanceObservationProvider
CoverageObservationProvider
CalendarObservationProvider
HealthObservationProvider
```

Il motore centrale non deve conoscere direttamente i singoli moduli.

---

# OBSERVATION REGISTRY

È stato introdotto un registro centrale dei provider.

Principio:

```text
Modulo
↓
Provider
↓
ObservationRegistry
↓
ObservationEngine
↓
Home / Dashboard / Moduli
```

---

# BOOTSTRAP

È stato introdotto il concetto di bootstrap centrale:

```text
FrodoDeskBootstrap
```

Responsabilità:

✔ inizializzare registri
✔ registrare provider
✔ preparare i motori centrali
✔ evitare inizializzazioni sparse nel progetto

---

# MODULO SPESE COME PRIMO CASO REALE

Il modulo Spese è il primo modulo collegato al nuovo sistema osservazioni.

Creato:

```text
SpeseMonthReader
SpeseObservationProvider
```

Il modulo Spese ora può produrre osservazioni come:

* destinazione principale delle spese
* categoria più pesante
* confronto con mese precedente
* concentrazione temporale delle spese
* volume movimenti registrati
* totale mese

---

# NUOVO PRINCIPIO ARCHITETTURALE

La Home NON deve analizzare.

La Home deve leggere osservazioni già prodotte dai motori.

Principio corretto:

```text
Motori reali
↓
ObservationProvider
↓
ObservationEngine
↓
Home
```

E NON:

```text
Home
↓
logiche proprie
↓
interpretazioni duplicate
```

---

# PRINCIPIO DELLE DOMANDE

Ogni osservazione nasce dalla risposta a una domanda reale.

Esempi:

* Alice è coperta?
* Questo mese cosa ha pesato di più?
* Il fondo auto è sufficiente?
* Ci sono anomalie?
* La famiglia sta migliorando o peggiorando?
* Cosa richiede attenzione oggi?

Da ora FrodoDesk non deve progettare solo funzioni.

Deve progettare domande utili alla vita reale.

---

# SIGNIFICATO STRUTTURALE

L’Observation Engine diventa un nuovo pilastro di FrodoDesk insieme a:

* Coverage Engine
* Finance Engine
* Presence Engine
* Persistence / Bootstrap
* Observation Engine

---

# FRASE GUIDA

FrodoDesk non registra la vita.

La osserva, la comprende e la restituisce in forma utile.

---

# 🔄 AGGIORNAMENTO GIUGNO 2026

# FINANCE PLANNER ENGINE — NUOVO PILASTRO DECISIONALE

## PRINCIPIO

Il modulo Finanze evolve da semplice simulatore economico a motore decisionale.

Il Planner non genera più direttamente scenari e raccomandazioni.

Analizza prima ogni singola voce economica e costruisce successivamente le proposte per l'utente.

---

# NUOVA ARCHITETTURA

Il Planner viene suddiviso in componenti indipendenti.

Struttura ufficiale:

FinancePlannerEngine

↓

PlannerDecisionEngine

↓

PlannerDecision

↓

PlannerScenarioBuilder

↓

PlannerRecommendationBuilder

↓

FinancePlannerResult

↓

FinanceObservationReader

↓

Observation Engine

↓

UI

---

# PLANNER DECISION

Viene introdotto il concetto di decisione economica.

Ogni ricorrenza viene trasformata in una decisione motivata.

Una decisione rappresenta il comportamento che il Planner ritiene più corretto per quella specifica voce economica.

Esempi:

* payNow
* keepCovered
* waitIncome
* delay
* useFunds
* blocked
* monitor

---

# DECISION ENGINE

Il Decision Engine rappresenta il cervello del Planner.

Responsabilità:

✔ analizzare ogni ricorrenza singolarmente

✔ applicare regole economiche

✔ attribuire priorità

✔ produrre decisioni spiegabili

Il Decision Engine NON costruisce scenari.

Produce esclusivamente decisioni.

---

# SCENARIO BUILDER

Lo Scenario Builder non contiene logiche economiche.

Riceve le decisioni prodotte dal Decision Engine e costruisce automaticamente:

* scenario consigliato
* scenario alternativo
* passi operativi

In questo modo gli scenari non sono più scritti manualmente.

---

# RECOMMENDATION BUILDER

Le raccomandazioni vengono generate automaticamente a partire dalle decisioni.

Il builder traduce il ragionamento del Planner in suggerimenti leggibili dall'utente.

---

# SEPARAZIONE DELLE RESPONSABILITÀ

Decisione architetturale ufficiale:

FinancePlannerEngine

coordina il processo.

PlannerDecisionEngine

decide.

PlannerScenarioBuilder

racconta gli scenari.

PlannerRecommendationBuilder

genera le raccomandazioni.

Ogni componente possiede una sola responsabilità.

---

# PRIME REGOLE DECISIONALI

La prima versione del motore introduce:

* RID non spostabili;
* priorità delle spese critiche;
* valutazione delle entrate imminenti;
* distinzione tra spese rimandabili e non rimandabili.

Le regole sono indipendenti dall'interfaccia grafica.

---

# DIREZIONE FUTURA

L'architettura è predisposta per una crescita progressiva del Planner.

Ogni nuova regola dovrà essere aggiunta senza modificare i componenti già esistenti.

L'obiettivo è costruire un motore decisionale estensibile, spiegabile e facilmente manutenibile.

---

# NUOVO PRINCIPIO ARCHITETTURALE

Il Planner non deve più ragionare sul mese.

Deve ragionare sulle singole entità economiche.

Le simulazioni del mese diventano una conseguenza delle decisioni prese sulle singole voci economiche.