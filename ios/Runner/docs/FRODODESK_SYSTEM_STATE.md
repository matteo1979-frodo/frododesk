# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 20 Luglio 2026
(H6 in corso — consolidamento architetturale Calendario)

━━━━━━━━━━━━━━━━━━

# STATO GENERALE SISTEMA

━━━━━━━━━━━━━━━━━━

## IDENTITÀ ATTUALE

FrodoDesk è entrato nella fase di consolidamento architetturale.

Il progetto non è più un insieme di schermate evolute ma un ecosistema composto da motori indipendenti, componenti UI modulari e livelli di responsabilità ben separati.

Il sistema NON è più:

❌ prototipo calendario

❌ planner turni

❌ simulatore economico

❌ raccolta di widget

È invece composto da:

✔ Calendario reale

✔ Presence Engine

✔ Coverage Engine

✔ Home operativa

✔ Eventi Globali

✔ Eventi Alice

✔ Observation Engine

✔ Centro Controllo Economico

✔ Planner Decision Engine

✔ Modulo Spese

✔ Sistema Finanze

✔ Modularizzazione stabile

✔ Architettura a responsabilità separate
✔ Metodo CNC formalizzato come principio architetturale: Screen/orchestratore e moduli specializzati per responsabilità

━━━━━━━━━━━━━━━━━━

# ARCHITETTURA UFFICIALE

━━━━━━━━━━━━━━━━━━

Durante H5 è stata consolidata definitivamente l'architettura del progetto.

Ogni nuova funzionalità dovrà rispettare il seguente schema:

Store

↓

Engine

↓

Builder

↓

ViewModel

↓

Widget

Responsabilità:

Store
→ unica sorgente dati.

Engine
→ contiene la logica di business.

Builder
→ trasforma i dati dell'engine in oggetti utilizzabili dalla UI.

ViewModel
→ rappresentazione pronta per la visualizzazione.

Widget
→ sola responsabilità grafica.

Regola fondamentale:

La UI non deve più prendere decisioni.

La UI visualizza esclusivamente informazioni preparate dal ViewModel.

━━━━━━━━━━━━━━━━━━

# STATO CALENDARIO

━━━━━━━━━━━━━━━━━━

## CONSOLIDATO E IN ULTERIORE RAFFINAMENTO H6

Il Calendario rappresenta oggi il modulo architetturalmente più evoluto del progetto, ma H6 sta ancora riducendo responsabilità residue presenti nella Screen e nei grandi metodi.

Sono stati eliminati numerosi blocchi monolitici attraverso estrazioni progressive senza modificare il comportamento funzionale.

Principio seguito durante H5:

✔ una responsabilità per componente

✔ nessun refactoring aggressivo

✔ nessuna modifica funzionale

✔ ogni estrazione deve mantenere comportamento identico

✔ commit frequenti

✔ applicazione sempre verde prima del commit

Stato H6 al 20 luglio 2026:

✔ refactoring incrementale di `_buildDayGapsBox()` in corso;
✔ estrazione progressiva di responsabilità in Builder dedicati;
✔ `AliceLogisticsStatusBuilder`, `AliceEventLogisticsBuilder`, `AliceEventLogisticsTextBuilder`, `DayGapVisualStateBuilder` e `VisibleGapDetailsBuilder` collegati;
✔ preparazione dei riepiloghi della rete di supporto estratta in `DaySupportSummariesBuilder`;
✔ comportamento dell'app mantenuto invariato durante le estrazioni;
✔ analyzer mantenuto pulito e checkpoint Git eseguiti tra i micro-step;
⚠ il Calendario non è ancora dichiarato definitivamente concluso: H6 prosegue finché le responsabilità residue ad alto valore architetturale non saranno separate in modo coerente.

━━━━━━━━━━━━━━━━━━

## COMPONENTI ESTRATTI

Durante H5 sono stati estratti e consolidati numerosi componenti.

Tra quelli principali:

✔ AliceStateBanner

✔ AliceSchoolHeader

✔ AliceEventsSection

✔ AliceEventsHeader

✔ AliceEventsList

✔ AliceEventTile

✔ AliceEventExpanded

✔ AliceEventConflictBanner

✔ HiddenAliceEventsLink

✔ SchoolStatusBox

✔ SchoolOutSummary

✔ SchoolCoverageChoiceSection

✔ DayOrganizationSection

✔ FamilyNowCard

Ogni componente possiede una responsabilità specifica.

Il Calendario è diventato progressivamente un orchestratore della UI.

━━━━━━━━━━━━━━━━━━

# VIEWMODEL INTRODOTTI

━━━━━━━━━━━━━━━━━━

H5 ha introdotto ufficialmente il concetto di ViewModel.

Attualmente consolidati:

✔ FamilyNowViewModel

✔ AliceEventTileViewModel

Principio:

Il ViewModel contiene tutto ciò che serve alla UI.

La UI non deve conoscere direttamente la logica del dominio.

━━━━━━━━━━━━━━━━━━

# BUILDER CONSOLIDATI

━━━━━━━━━━━━━━━━━━

Durante H5 sono stati introdotti i primi Builder strutturali del Calendario.

Attualmente consolidati:

✔ AliceEventTileViewModelBuilder

✔ AliceEventConflictBuilder (prima versione architetturale)

Sono inoltre stati predisposti alcuni Builder che verranno completati nella milestone successiva.

Principio consolidato:

Il Builder prepara i dati.

Non contiene codice UI.

Non sostituisce l'Engine.

Non sostituisce il ViewModel.

━━━━━━━━━━━━━━━━━━

# H5 — REFATTORIZZAZIONE CALENDARIO

━━━━━━━━━━━━━━━━━━

## STATO

🟢 COMPLETATA

L'obiettivo della milestone NON era aggiungere funzionalità.

L'obiettivo era ridurre la complessità del Calendario mantenendo invariato il comportamento.

Risultati ottenuti:

✔ estrazione progressiva dei widget

✔ introduzione dei ViewModel

✔ introduzione dei Builder

✔ riduzione delle responsabilità della schermata

✔ maggiore leggibilità del codice

✔ maggiore facilità di manutenzione

✔ nessuna regressione funzionale

━━━━━━━━━━━━━━━━━━

## LEZIONI APPRESE

Durante H5 sono state fissate alcune regole definitive.

Regola 1

Mai estrarre un widget che richiede decine di parametri.

Prima si costruisce un ViewModel.

Poi il widget.

---

Regola 2

Ogni widget deve avere una sola responsabilità.

---

Regola 3

Ogni estrazione deve lasciare l'app perfettamente funzionante.

Mai accettare regressioni temporanee.

---

Regola 4

Prima:

codice funzionante.

Poi:

codice bello.

Mai il contrario.

---

Regola 5

Se una modifica introduce incertezza architetturale:

ci si ferma.

Si riprogetta.

Non si forza il refactoring.

━━━━━━━━━━━━━━━━━━

# STATO HOME

━━━━━━━━━━━━━━━━━━

## CONSOLIDATA

La Home viene considerata architetturalmente stabile.

Le estrazioni principali sono state completate.

Le parti rimaste all'interno della schermata contengono:

✔ orchestrazione

✔ callback

✔ dialog

✔ business logic

Ulteriori estrazioni non sono considerate prioritarie.

━━━━━━━━━━━━━━━━━━

# FAMILY NOW

━━━━━━━━━━━━━━━━━━

FamilyNow rappresenta il prossimo candidato al refactoring logico.

Situazione attuale:

✔ FamilyNowCard estratta

✔ FamilyNowViewModel consolidato

Il metodo:

_buildFamilyNowSnapshot()

rimane volutamente ancora centrale.

Decisione ufficiale:

NON verrà ulteriormente refattorizzato durante H5.

La sua evoluzione appartiene ad H6.

━━━━━━━━━━━━━━━━━━

# H6 — DIREZIONE UFFICIALE

━━━━━━━━━━━━━━━━━━

H6 NON sarà una prosecuzione di H5.

H6 rappresenta una milestone completamente diversa.

Obiettivo:

estrazione dei motori.

NON della UI.

Il focus diventa:

✔ Engine

✔ Builder

✔ Snapshot Builder

✔ semplificazione della business logic

NON:

❌ nuovi widget

❌ refactoring estetici

❌ modularizzazione della UI

━━━━━━━━━━━━━━━━━━

# ROADMAP H6

━━━━━━━━━━━━━━━━━━

Ordine ufficiale:

1.

FamilyNow

↓

semplificazione del motore

2.

Coverage Engine

↓

riduzione logiche duplicate

3.

Presence Engine

↓

cleanup definitivo

4.

Business Builder

↓

centralizzazione della preparazione dati

5.

Snapshot Builder

↓

riduzione della complessità delle schermate

━━━━━━━━━━━━━━━━━━

# PRESENCE ENGINE

━━━━━━━━━━━━━━━━━━

## STATO

🟢 CONSOLIDATO

PresenceEngine rappresenta la sorgente ufficiale della presenza reale delle persone.

Responsabilità consolidate:

✔ determinazione presenza reale

✔ determinazione posizione Alice

✔ integrazione Eventi Reali

✔ integrazione Eventi Alice

✔ integrazione Centro Estivo

✔ integrazione accompagnamenti

✔ sorgente unica per Coverage Engine

Direzione futura:

✔ ulteriore pulizia del codice

✔ eliminazione completa delle ultime logiche duplicate

Nessuna espansione funzionale prevista prima di H6.

━━━━━━━━━━━━━━━━━━

# COVERAGE ENGINE

━━━━━━━━━━━━━━━━━━

## STATO

🟢 CONSOLIDATO

Coverage Engine è oggi considerato stabile.

Responsabilità:

✔ rilevazione buchi

✔ spiegazione buchi

✔ verifica copertura reale

✔ integrazione Presence Engine

✔ integrazione Eventi Alice

✔ integrazione Eventi Reali

✔ integrazione Supporti

Direzione:

H6 eliminerà definitivamente ogni residuo di logica duplicata.

━━━━━━━━━━━━━━━━━━

# EVENTI ALICE

━━━━━━━━━━━━━━━━━━

## STATO

🟢 CONSOLIDATO

Sistema eventi completamente operativo.

Supporta:

✔ eventi comportamentali

✔ eventi logistici

✔ eventi accompagnati

✔ eventi passivi

✔ eventi con supervisione

✔ eventi con accompagnatore

✔ integrazione Coverage

✔ integrazione Presence

Durante H5 sono stati introdotti:

✔ AliceEventTile

✔ AliceEventExpanded

✔ AliceEventTileViewModel

✔ AliceEventTileViewModelBuilder

Il comportamento funzionale è rimasto invariato.

È cambiata esclusivamente l'architettura.

━━━━━━━━━━━━━━━━━━

# HOME

━━━━━━━━━━━━━━━━━━

## STATO

🟢 STABILE

La Home è considerata conclusa dal punto di vista della modularizzazione.

Ulteriori estrazioni sono sconsigliate.

Le evoluzioni future riguarderanno esclusivamente:

✔ nuove osservazioni

✔ nuovi indicatori

✔ integrazione con Observation Engine

━━━━━━━━━━━━━━━━━━

# OBSERVATION ENGINE

━━━━━━━━━━━━━━━━━━

## STATO

🟢 FONDAMENTA COMPLETE

Observation Engine è diventato il punto di raccolta delle analisi del sistema.

Ogni modulo dovrà produrre osservazioni tramite provider dedicati.

Direzione futura:

✔ CoverageObservationProvider

✔ CalendarObservationProvider

✔ FinanceObservationProvider

✔ HealthObservationProvider

La Home diventerà progressivamente il punto di aggregazione di tutte le osservazioni.

━━━━━━━━━━━━━━━━━━

# MODULO FINANZE

━━━━━━━━━━━━━━━━━━

## STATO

🟢 CONSOLIDATO

Le funzionalità economiche introdotte nelle milestone precedenti sono considerate stabili.

Il focus non è più costruire il motore.

Il focus è verificarne il comportamento nella vita reale.

Principio consolidato:

La vita reale ha sempre priorità sulla simulazione.

━━━━━━━━━━━━━━━━━━

# MILESTONE COMPLETATE

━━━━━━━━━━━━━━━━━━

🟢 Calendario Reale

🟢 Presence Engine

🟢 Coverage Engine

🟢 Home

🟢 Eventi Globali

🟢 Eventi Alice

🟢 Observation Engine (fondazione)

🟢 Planner Decision Engine

🟢 Modulo Spese

🟢 Centro Controllo Economico

🟢 H5 — Refactoring Architetturale Calendario

━━━━━━━━━━━━━━━━━━

# REGOLE OPERATIVE UFFICIALI

━━━━━━━━━━━━━━━━━━

Le seguenti regole sono considerate definitive.

Devono essere rispettate in tutte le milestone future.

✔ Una sola responsabilità per ogni componente.

✔ Prima il comportamento corretto.

Poi il refactoring.

✔ Nessuna regressione è accettabile.

✔ Ogni estrazione deve lasciare il progetto completamente funzionante.

✔ Sempre compilazione verde prima di ogni commit.

✔ Commit piccoli e frequenti.

✔ Nessuna modularizzazione fine a sé stessa.

✔ Ogni nuovo file deve avere una responsabilità chiaramente definita.

✔ Nessun Builder viene creato senza conoscere la sua destinazione architetturale.

✔ Nessun ViewModel deve contenere logica di business.

✔ Nessun Widget deve prendere decisioni.

✔ Le schermate devono diventare progressivamente orchestratori.

━━━━━━━━━━━━━━━━━━

# STATO GIT

━━━━━━━━━━━━━━━━━━

Ultima milestone conclusa:

H5 — Refactoring Calendario

Stato repository:

✔ compilazione pulita

✔ nessun errore

✔ nessuna regressione nota

✔ commit incrementali completati durante tutta H5

Il progetto è considerato stabile.

━━━━━━━━━━━━━━━━━━

# DIREZIONE OPERATIVA

━━━━━━━━━━━━━━━━━━

NON fare:

❌ nuove funzionalità casuali

❌ refactoring aggressivi

❌ duplicazioni

❌ widget monolitici

❌ business logic nella UI

❌ Builder senza responsabilità precisa

Fare:

✔ consolidamento architetturale

✔ motori indipendenti

✔ business logic centralizzata

✔ ViewModel puliti

✔ Builder specializzati

✔ UI sempre più semplice

━━━━━━━━━━━━━━━━━━

# STATO REALE DEL PROGETTO

━━━━━━━━━━━━━━━━━━

Il progetto FrodoDesk è oggi composto da moduli autonomi che collaborano attraverso responsabilità chiaramente separate.

La milestone H5 ha rappresentato il passaggio definitivo da una struttura basata sulle schermate ad una struttura basata sull'architettura.

La UI non costituisce più il centro del sistema.

Il cuore del progetto diventa l'insieme dei motori (Engine), dei Builder e dei ViewModel.

La direzione futura è orientata alla progressiva riduzione della complessità delle schermate e all'aumento della qualità architetturale del codice.

━━━━━━━━━━━━━━━━━━

# FRASE UFFICIALE DI RIPARTENZA

Ripartiamo da FrodoDesk.

H5 è ufficialmente conclusa.

Il Calendario è stato rifattorizzato mantenendo il comportamento invariato e introducendo una separazione stabile tra Widget, ViewModel e Builder.

La prossima milestone sarà H6.

Priorità assoluta:

trasferire progressivamente la business logic dai grandi metodi ai motori dedicati, mantenendo sempre il progetto completamente funzionante, con modifiche piccole, verificabili e accompagnate da commit frequenti.

H6 non introdurrà nuove funzionalità.

L'obiettivo sarà consolidare definitivamente l'architettura interna di FrodoDesk.

━━━━━━━━━━━━━━━━━━

FINE DOCUMENTO