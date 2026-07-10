# FRODODESK — ARCHITECTURE

Versione: 2.0  
Ultimo aggiornamento: Luglio 2026

---

# SCOPO DEL DOCUMENTO

Questo documento rappresenta l'architettura ufficiale di FrodoDesk.

Non descrive semplicemente come è organizzato il codice, ma definisce i principi, le responsabilità e le regole architetturali che guidano l'intero progetto.

Ogni futura evoluzione dovrà essere coerente con quanto riportato in questo documento.

L'architettura ha lo stesso valore della correttezza funzionale.

Un sistema che funziona ma che cresce in modo disordinato viene considerato un errore progettuale.

---

# FILOSOFIA DEL PROGETTO

FrodoDesk nasce come sistema reale per organizzare la vita quotidiana di una famiglia.

Con il tempo il progetto è evoluto fino a diventare un motore decisionale capace di:

- osservare;
- comprendere;
- simulare;
- organizzare;
- aiutare nelle decisioni.

L'obiettivo non è creare un semplice calendario o un gestionale economico.

L'obiettivo è costruire un ecosistema modulare capace di evolvere per molti anni senza aumentare la complessità del codice.

Ogni nuova funzionalità deve poter essere aggiunta senza compromettere quelle esistenti.

---

# PRINCIPI FONDAMENTALI

## Responsabilità unica

Ogni componente deve avere una sola responsabilità.

Quando un file inizia a svolgere più ruoli significa che deve essere riprogettato.

Non si estraggono file per diminuire il numero di righe.

Si estraggono responsabilità.

---

## Separazione delle responsabilità

La logica non deve vivere nella UI.

Ogni livello del sistema ha uno scopo preciso.

Store conservano.

Engine elaborano.

Builder preparano.

ViewModel rappresentano.

Widget mostrano.

Ogni violazione di questa regola aumenta l'accoppiamento del sistema.

---

## Progettazione prima del codice

Prima di creare qualsiasi nuovo componente è obbligatorio comprenderne la responsabilità.

Non vengono creati Builder, Engine o ViewModel "nel dubbio".

Ogni nuovo componente nasce soltanto quando la sua funzione è chiaramente definita.

---

## Evoluzione incrementale

Le modifiche importanti vengono sempre affrontate attraverso piccoli passi.

Ogni micro-step deve:

- compilare;
- funzionare;
- poter essere verificato nell'app;
- terminare con un commit Git.

Non sono ammessi grandi refactoring non verificabili.

---

## Continuità delle milestone

Ogni milestone ha un solo obiettivo.

Durante una milestone non si cambia strategia.

Se emerge un'idea migliore:

- la milestone corrente viene completata;
- la nuova idea viene pianificata nella milestone successiva.

Questo garantisce stabilità evolutiva e semplicità di manutenzione.

---

# ARCHITETTURA UFFICIALE

A partire dalla milestone H6 tutta l'architettura di FrodoDesk segue ufficialmente questa gerarchia.

```text
Store
   ↓
Engine
   ↓
Builder
   ↓
ViewModel
   ↓
Widget
```

Questa rappresenta la direzione del flusso delle responsabilità.

Non deve essere invertita.

---

# RESPONSABILITÀ DEI LIVELLI

## Store

Gli Store rappresentano la sorgente ufficiale dei dati.

Sono la "Single Source of Truth" del sistema.

Responsabilità:

- mantenere lo stato;
- leggere i dati;
- salvare i dati;
- notificare le modifiche.

Gli Store non devono conoscere la UI.

Non preparano dati grafici.

Non prendono decisioni di business.

---

## Engine

Gli Engine rappresentano il cervello del sistema.

Applicano regole.

Interpretano i dati.

Producono risultati.

Responsabilità:

- business logic;
- simulazioni;
- calcoli;
- interpretazione dello stato.

Gli Engine non devono conoscere Widget o ViewModel.

---

## Builder

I Builder preparano dati già elaborati dai motori.

Responsabilità:

- aggregazione;
- trasformazione;
- composizione;
- eliminazione delle duplicazioni.

Un Builder non prende decisioni.

Riceve dati già validi e li prepara per la rappresentazione.

---

## ViewModel

Il ViewModel rappresenta esclusivamente ciò che serve alla UI.

Espone dati già pronti.

Non contiene logica di business.

Un Widget dovrebbe poter essere costruito leggendo soltanto il proprio ViewModel.

---

## Widget

I Widget hanno una sola responsabilità:

visualizzare.

Non effettuano elaborazioni.

Non recuperano dati complessi.

Non prendono decisioni.

Ricevono informazioni già preparate e le mostrano all'utente.

---

# PRINCIPIO DELLE DIPENDENZE

Ogni livello può conoscere esclusivamente il livello immediatamente sottostante.

Schema corretto:

```text
Widget
    ↓
ViewModel
    ↓
Builder
    ↓
Engine
    ↓
Store
```

Sono considerate violazioni architetturali:

- Widget → Store
- Widget → Engine
- ViewModel → Store
- Builder → Widget
- Store → UI

Ridurre le dipendenze significa aumentare la manutenibilità del progetto.

---

# SCHERMATE ORCHESTRATRICI

Le schermate non devono contenere business logic.

Il loro compito è esclusivamente coordinare i componenti.

Una schermata deve:

- richiedere i dati;
- costruire i ViewModel;
- comporre i Widget.

Una schermata deve poter essere letta come la descrizione della pagina e non come un insieme di algoritmi.

---
# STRUTTURA DEL PROGETTO

L'organizzazione del progetto deve riflettere la separazione delle responsabilità.

Ogni cartella rappresenta uno specifico livello architetturale.

```text
lib/
│
├── core/
│
├── models/
│
├── logic/
│   ├── stores/
│   ├── engines/
│   ├── builders/
│   └── viewmodels/
│
├── widgets/
│
├── screens/
│
├── services/
│
└── utils/
```

La struttura potrà evolvere nel tempo, ma dovrà sempre rispettare la gerarchia architetturale definita in questo documento.

---

# MODELS

I Model rappresentano esclusivamente strutture dati.

Non contengono logiche decisionali.

Possono contenere semplici helper strettamente collegati ai dati, ma non devono conoscere il resto del sistema.

Esempi:

- DayOverride
- DiseasePeriod
- RealEvent
- WeekIdentity
- AlicePresenceState
- FrodoObservation

I Model devono essere riutilizzabili da qualsiasi livello dell'applicazione.

---

# STORE

Gli Store rappresentano il punto centrale della persistenza dello stato.

Sono la sorgente ufficiale delle informazioni.

Ogni dato del sistema deve avere uno Store di riferimento.

Esempi attuali:

- OverrideStore
- DiseasePeriodStore
- FeriePeriodStore
- SupportNetworkStore
- RealEventStore
- AliceEventStore
- SchoolStore
- FinanceStore (futuro consolidamento)

Gli Store non devono contenere codice dedicato alla UI.

---

# ENGINE

Gli Engine rappresentano il livello di business.

Ogni Engine deve essere indipendente dall'interfaccia grafica.

Gli Engine possono utilizzare più Store contemporaneamente ma non devono conoscere Widget o schermate.

Principali Engine attualmente presenti:

- CoverageEngine
- TurnEngine
- AlicePresenceEngine
- ObservationEngine
- FinancePlannerEngine
- EmergencyDayLogic
- FourthShiftCycleLogic

Ogni nuovo Engine deve risolvere un problema ben definito.

---

# BUILDER

I Builder rappresentano uno dei pilastri introdotti durante la milestone H5.

La loro responsabilità consiste nel preparare dati già elaborati dai motori.

Non prendono decisioni.

Non implementano business logic.

Aggregano informazioni provenienti da più Engine e costruiscono strutture coerenti per uno specifico utilizzo.

Esempi:

- AliceEventTileViewModelBuilder
- FamilyNowBuilder
- SnapshotBuilder (previsto)
- BusinessBuilder (previsto)

Un Builder nasce soltanto quando esiste una responsabilità chiaramente identificata.

Non vengono creati Builder "preventivi".

---

# VIEWMODEL

I ViewModel rappresentano il contratto tra logica e interfaccia grafica.

Devono contenere esclusivamente i dati necessari alla visualizzazione.

Non devono conoscere Store.

Non devono interrogare Engine.

Non devono prendere decisioni.

Esempi:

- FamilyNowViewModel
- AliceEventTileViewModel

La UI deve poter essere costruita leggendo soltanto il ViewModel.

---

# WIDGET

I Widget rappresentano l'ultimo livello dell'architettura.

Ogni Widget dovrebbe avere una responsabilità molto limitata.

Durante H5 il progetto è stato progressivamente suddiviso in Widget specializzati.

Tra i principali:

- AliceEventTile
- AliceEventExpanded
- AliceEventsHeader
- AliceEventsList
- AliceStateBanner
- AliceSchoolHeader
- HiddenAliceEventsLink
- SchoolStatusBox
- SchoolOutSummary
- SchoolCoverageChoiceSection
- DayOrganizationSection
- FamilyNowCard

L'obiettivo è ottenere componenti piccoli, riutilizzabili e facilmente testabili.

---

# SCREEN

Le schermate rappresentano esclusivamente il punto di composizione della pagina.

Una Screen deve:

- richiedere dati;
- coordinare Builder;
- costruire ViewModel;
- comporre Widget.

Non deve contenere logiche di business.

Il calendario reale rappresenta oggi il modello architetturale di riferimento del progetto.

La milestone H5 ha trasformato il Calendario nel modulo più evoluto dal punto di vista architetturale.

---

# FLUSSO ARCHITETTURALE

Il flusso ufficiale delle informazioni è il seguente.

```text
Store
        ↓
Engine
        ↓
Builder
        ↓
ViewModel
        ↓
Widget
        ↓
Screen
```

La Screen orchestra.

Il Widget visualizza.

Il ViewModel rappresenta.

Il Builder prepara.

L'Engine decide.

Lo Store conserva.

Ogni livello possiede una responsabilità precisa e non deve invadere quella degli altri.

---
# EVOLUZIONE ARCHITETTURALE

L'architettura di FrodoDesk non è considerata definitiva.

Ogni evoluzione deve perseguire un unico obiettivo:

ridurre la complessità complessiva del progetto.

Ogni nuova funzionalità deve aumentare le capacità del sistema senza aumentare il numero di responsabilità dei componenti esistenti.

Quando questo non è possibile significa che è necessario introdurre un nuovo livello architetturale.

---

# ARCHITETTURA MULTI-FAMIGLIA

## Decisione ufficiale

A partire da giugno 2026 FrodoDesk non viene più considerato il software dedicato esclusivamente alla famiglia di sviluppo.

La famiglia reale rappresenta semplicemente il primo caso di utilizzo.

L'architettura deve essere progettata per funzionare con qualsiasi nucleo familiare.

---

## Principio

I motori non devono conoscere persone specifiche.

Devono ragionare tramite concetti astratti.

Ad esempio:

- persona;
- ruolo;
- relazione;
- permessi;
- gruppo familiare.

Mai tramite nomi fissi.

Schema corretto:

```text
Famiglia
      ↓
Persone
      ↓
Ruoli
      ↓
Motori
```

e non:

```text
Matteo
      ↓
Chiara
      ↓
Alice
      ↓
Business Logic
```

Questa separazione permetterà al sistema di adattarsi a qualsiasi famiglia senza modifiche strutturali.

---

# PERSISTENZA E CLOUD

L'attuale sistema utilizza una persistenza locale con procedure di esportazione e importazione.

L'architettura è però predisposta per una futura sincronizzazione centralizzata.

Obiettivo:

- PC;
- smartphone;
- tablet;

devono condividere la stessa sorgente dati.

Il cloud dovrà sostituire progressivamente le attuali procedure manuali mantenendo invariata l'architettura dei livelli superiori.

---

# GESTIONE RUOLI

L'architettura è predisposta per supportare differenti tipologie di utenti.

Ruoli previsti:

### Amministratore

Gestisce:

- famiglia;
- configurazione;
- utenti;
- permessi.

---

### Adulto

Può utilizzare tutti i moduli autorizzati.

---

### Accesso limitato

Può consultare esclusivamente una parte delle informazioni.

---

### Utente esterno

Accesso limitato a specifici moduli.

Esempi:

- babysitter;
- insegnante;
- allenatore;
- commercialista;
- consulenti.

L'intero sistema dovrà basarsi sui permessi e non su verifiche distribuite nei singoli moduli.

---

# PRESENCE ENGINE

Il Presence Engine rappresenta uno dei pilastri principali di FrodoDesk.

Il suo obiettivo è fornire una sola verità sulla posizione reale dei membri della famiglia.

La domanda:

> "Dove si trova realmente una persona in questo momento?"

deve ricevere una sola risposta valida per tutto il sistema.

---

## AlicePresenceEngine

Attualmente il primo motore completamente consolidato riguarda Alice.

Responsabilità:

- presenza a casa;
- scuola;
- centro estivo;
- eventi temporizzati;
- eventi reali;
- accompagnamento;
- rete di supporto.

Tutti gli altri moduli devono leggere questa informazione senza reinterpretarla.

---

## Principio

La presenza reale viene determinata una sola volta.

Successivamente viene semplicemente consumata da:

- Coverage Engine;
- Home;
- Calendario;
- statistiche;
- futuri moduli.

Questo elimina duplicazioni e riduce il rischio di incoerenze.

---

# COVERAGE ENGINE

Il Coverage Engine rappresenta il motore che verifica la copertura della famiglia.

Con H5 il suo ruolo è stato progressivamente ridotto.

Non deve più interpretare direttamente la presenza reale.

Il suo compito consiste nel leggere le informazioni prodotte dal Presence Engine e valutare esclusivamente la copertura.

Questa separazione rappresenta una delle decisioni architetturali più importanti del progetto.

---

# OBSERVATION ENGINE

L'Observation Engine costituisce un nuovo pilastro dell'architettura.

FrodoDesk non deve limitarsi a registrare dati.

Deve interpretarli.

Ogni osservazione nasce dalla risposta a una domanda significativa sulla vita reale della famiglia.

Le osservazioni vengono prodotte dai singoli moduli tramite Provider dedicati.

Schema:

```text
Modulo
      ↓
Observation Provider
      ↓
Observation Registry
      ↓
Observation Engine
      ↓
Home
```

La Home non interpreta.

Visualizza esclusivamente osservazioni già elaborate.

---

# BOOTSTRAP

L'inizializzazione dei motori viene centralizzata nel bootstrap del sistema.

Responsabilità:

- registrazione provider;
- inizializzazione motori;
- configurazione servizi comuni.

L'obiettivo è eliminare inizializzazioni distribuite all'interno delle schermate.

---

# FINANCE PLANNER

Il modulo Finanze sta evolvendo verso un motore decisionale.

L'architettura prevista è la seguente.

```text
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
Observation Engine
            ↓
UI
```

Ogni componente svolge una sola responsabilità.

Le decisioni economiche vengono prese prima della costruzione degli scenari.

Gli scenari rappresentano una conseguenza delle decisioni e non il contrario.

---

# DIREZIONE FUTURA

Le prossime milestone dovranno consolidare ulteriormente l'architettura introducendo progressivamente:

- Business Builder;
- Snapshot Builder;
- FamilyNow Builder;
- ulteriore alleggerimento delle Screen;
- riduzione definitiva delle responsabilità dei motori più complessi.

Ogni nuovo componente dovrà nascere esclusivamente da una responsabilità chiaramente individuata.

---
# CRONOLOGIA EVOLUTIVA

L'architettura di FrodoDesk è cresciuta progressivamente.

Le decisioni riportate di seguito rappresentano l'evoluzione reale del progetto e costituiscono parte integrante della sua storia.

---

# MARZO 2026

## Architettura modulare

La prima architettura ufficiale introduce la separazione tra:

- Models
- Logic
- Widgets
- Screens

Viene definito un primo principio fondamentale:

la logica non deve vivere nella UI.

La cartella `logic` raccoglie sia gli Engine che gli Store.

L'obiettivo principale è permettere la modifica di un modulo senza compromettere gli altri.

Questa rappresenta la base dell'intero progetto.

---

# MAGGIO 2026

## Presenza reale

Durante lo sviluppo emerge un nuovo problema architetturale.

La presenza reale di Alice viene calcolata da numerosi moduli differenti.

Questo genera:

- duplicazioni;
- incoerenze;
- punti di manutenzione multipli.

Nasce così il concetto di **Presence Engine**.

La presenza viene centralizzata.

Il Coverage Engine smette progressivamente di interpretare la posizione di Alice e diventa consumatore di una sorgente unica.

Questo rappresenta il primo grande processo di centralizzazione della logica del progetto.

---

# MAGGIO 2026

## AlicePresenceEngine

Il motore di presenza viene implementato.

Nascono:

- AlicePresenceEngine;
- AlicePresenceState.

Da questo momento ogni domanda relativa alla posizione reale di Alice deve ricevere una sola risposta valida per tutto il sistema.

La presenza non viene più ricostruita dalla UI o da logiche distribuite.

---

# GIUGNO 2026

## Observation Engine

Il progetto evolve ulteriormente.

FrodoDesk non deve più limitarsi a registrare informazioni.

Deve comprenderle.

Nasce il concetto di:

**FrodoObservation**

Ogni modulo può produrre osservazioni tramite Provider dedicati.

L'Observation Engine raccoglie, ordina e restituisce alla Home esclusivamente le osservazioni più rilevanti.

Viene introdotto anche il Bootstrap centrale del progetto.

Questa evoluzione segna il passaggio da gestionale a sistema decisionale.

---

# GIUGNO 2026

## Finance Planner

Il modulo Finanze evolve verso un motore decisionale.

Le simulazioni non vengono più costruite direttamente.

Prima vengono prodotte decisioni economiche.

Successivamente vengono costruiti:

- scenari;
- raccomandazioni;
- osservazioni.

Questo consente al Planner di crescere senza aumentare la complessità.

---

# H5 — GIUGNO/LUGLIO 2026

## Rifattorizzazione architetturale

La milestone H5 rappresenta il più importante intervento architetturale realizzato fino a oggi.

L'obiettivo non era introdurre nuove funzionalità.

L'obiettivo era ridurre le responsabilità dei componenti mantenendo invariato il comportamento dell'applicazione.

Durante H5 vengono introdotti stabilmente:

- Builder;
- ViewModel;
- Widget dedicati;
- schermate orchestratrici;
- separazione rigorosa delle responsabilità.

Il Calendario diventa il modulo architetturalmente più evoluto dell'intero progetto.

L'applicazione mantiene lo stesso comportamento funzionale, ma con una struttura molto più semplice da comprendere ed evolvere.

---

# H6 — DIREZIONE UFFICIALE

Con H5 conclusa, il progetto entra ufficialmente nella milestone H6.

L'obiettivo non è più rifattorizzare la UI.

L'attenzione si sposta sui motori.

Le principali attività previste sono:

- completamento del refactoring di FamilyNow;
- riduzione delle responsabilità residue del Coverage Engine;
- consolidamento del Presence Engine;
- introduzione dei Business Builder;
- introduzione degli Snapshot Builder;
- ulteriore alleggerimento delle schermate.

Ogni modifica dovrà seguire rigorosamente il metodo consolidato durante H5.

---

# METODO DI LAVORO UFFICIALE

Ogni futura evoluzione del progetto dovrà seguire questa sequenza.

1. Analisi.

2. Progettazione.

3. Un solo micro-step.

4. Compilazione.

5. Verifica nell'app.

6. Commit Git.

7. Passo successivo.

Non sono ammessi:

- grandi modifiche contemporanee;
- Builder lasciati incompleti;
- file creati senza responsabilità definita;
- cambi di strategia durante una milestone.

---

# OBIETTIVO ARCHITETTURALE

FrodoDesk non deve diventare un progetto grande.

Deve diventare un progetto ordinato.

Ogni nuova funzionalità dovrà ridurre la complessità percepita del sistema.

L'architettura rappresenta un patrimonio del progetto e dovrà essere trattata con la stessa cura riservata al codice.

---

# FRASE GUIDA

> **La qualità architetturale ha lo stesso valore della correttezza funzionale.**

Un sistema che funziona ma non è in grado di evolvere non può essere considerato completato.

---

**FINE DOCUMENTO**