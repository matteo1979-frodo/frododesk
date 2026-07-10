# FRODODESK — MASTER ROADMAP V5

Versione: 5.0
Ultimo aggiornamento: Luglio 2026

---

# SCOPO DEL DOCUMENTO

La MASTER ROADMAP rappresenta l'unico documento ufficiale che descrive l'evoluzione futura di FrodoDesk.

Non contiene documentazione tecnica.

Non descrive l'architettura del sistema.

Non sostituisce:

- FRODODESK_SYSTEM_STATE
- FRODODESK_PROJECT_MEMORY
- FRODODESK_RULES
- FRODODESK_ARCHITECTURE

Il suo unico obiettivo è definire:

- dove si trova oggi il progetto;
- quali milestone sono concluse;
- quale milestone è attualmente in corso;
- quali saranno le prossime evoluzioni.

---

# IDENTITÀ DEL PROGETTO

FrodoDesk non è un semplice software gestionale.

È un sistema progettato per aiutare una famiglia a comprendere meglio la propria vita quotidiana e prendere decisioni più consapevoli.

Il progetto integra:

- organizzazione;
- simulazione;
- osservazione;
- pianificazione;
- supporto decisionale.

Ogni modulo contribuisce a costruire una rappresentazione coerente della realtà familiare.

---

# PRINCIPIO GUIDA

FrodoDesk osserva.

FrodoDesk interpreta.

FrodoDesk organizza.

FrodoDesk propone.

**La decisione finale rimane sempre umana.**

L'obiettivo non è sostituire l'utente.

L'obiettivo è aiutarlo a prendere decisioni migliori attraverso informazioni affidabili, spiegabili e contestualizzate.

---

# OBIETTIVO STRATEGICO

L'obiettivo del progetto non è aggiungere continuamente nuove funzionalità.

L'obiettivo è costruire un sistema che possa evolvere per anni senza aumentare la complessità.

Ogni milestone deve lasciare FrodoDesk:

- più semplice;
- più leggibile;
- più modulare;
- più stabile;
- più estendibile.

Una nuova funzionalità viene considerata completata soltanto quando è coerente con l'architettura del progetto.

---

# STATO UFFICIALE DEL PROGETTO

## Architettura

🟢 Consolidata.

La milestone H5 ha introdotto definitivamente:

- Store
- Engine
- Builder
- ViewModel
- Widget

come gerarchia ufficiale del progetto.

---

## Calendario

🟢 Modulo consolidato.

È oggi il modulo architetturalmente più evoluto del progetto.

La UI è stata alleggerita mantenendo invariato il comportamento dell'applicazione.

---

## Presence Engine

🟢 Consolidato.

La presenza reale viene determinata da un'unica sorgente di verità.

---

## Coverage Engine

🟢 Consolidato.

Le responsabilità principali sono state separate dal motore di presenza.

Il cleanup definitivo sarà completato durante H6.

---

## Observation Engine

🟢 Operativo.

Il framework delle osservazioni è parte integrante dell'architettura.

La Home utilizza progressivamente osservazioni prodotte dai motori invece di logiche locali.

---

## Modulo Finanze

🟢 Fondazioni completate.

Il Planner dispone della nuova architettura decisionale.

Le future evoluzioni riguarderanno principalmente il miglioramento della qualità delle decisioni e non l'aggiunta di nuove schermate.

---
# MILESTONE CONCLUSE

Le milestone concluse rappresentano il patrimonio evolutivo del progetto.

Non costituiscono più la direzione operativa corrente, ma definiscono le fondamenta su cui costruire le evoluzioni future.

---

# H1 — FONDAZIONI

🟢 COMPLETATA

Prima struttura del progetto.

Obiettivi raggiunti:

- organizzazione iniziale;
- primi modelli;
- primi Store;
- prime logiche di simulazione.

Questa milestone ha posto le basi dell'intero ecosistema FrodoDesk.

---

# H2 — CONSOLIDAMENTO

🟢 COMPLETATA

Introduzione e consolidamento della persistenza.

Obiettivi raggiunti:

- stabilizzazione dei dati;
- miglioramento dell'affidabilità;
- prime regole strutturali.

---

# H3 — MODULO FINANZE

🟢 COMPLETATA

Nasce il vero motore economico.

Risultati principali:

- conti multipli;
- fondi;
- ricorrenze;
- movimenti;
- dashboard economica;
- snapshot;
- timeline;
- Centro Controllo Economico.

Il modulo viene utilizzato nella vita reale.

---

# H4 — PLANNER DECISIONALE

🟢 COMPLETATA

Il Planner evolve da insieme di regole statiche a motore decisionale.

Vengono introdotti:

- FinancePlannerEngine;
- PlannerDecisionEngine;
- PlannerScenarioBuilder;
- PlannerRecommendationBuilder.

Il Planner inizia a produrre decisioni spiegabili invece di semplici risultati.

Questa milestone conclude la costruzione dell'architettura del Planner.

L'espansione delle regole decisionali continuerà nelle milestone future, senza modificare la struttura introdotta in H4.

---

# H5 — RIFATTORIZZAZIONE ARCHITETTURALE

🟢 COMPLETATA

H5 rappresenta la più importante milestone architetturale del progetto.

Obiettivo:

migliorare la struttura mantenendo invariato il comportamento dell'applicazione.

Risultati raggiunti:

- introduzione stabile dei Builder;
- introduzione dei ViewModel;
- estrazione dei Widget dedicati;
- schermate trasformate in orchestratori;
- drastica riduzione delle responsabilità della UI;
- separazione rigorosa tra business logic e presentazione.

Il Calendario diventa il modulo di riferimento per tutta l'architettura futura.

---

# MILESTONE ATTUALE

# H6 — CONSOLIDAMENTO DEI MOTORI

🟡 IN CORSO

H6 inaugura una nuova fase del progetto.

L'attenzione non è più rivolta principalmente alla UI.

L'obiettivo diventa consolidare definitivamente il cuore logico di FrodoDesk.

Le attività previste sono:

- completamento del refactoring di FamilyNow;
- analisi e rifattorizzazione di `_buildFamilyNowSnapshot()`;
- completamento della separazione delle responsabilità del Coverage Engine;
- cleanup finale del Presence Engine;
- introduzione dei Business Builder;
- introduzione degli Snapshot Builder;
- riduzione definitiva della complessità delle Screen.

---

## Metodo obbligatorio

Ogni attività di H6 seguirà rigorosamente questa sequenza.

1. Analisi.

2. Progettazione.

3. Un solo micro-step.

4. Compilazione.

5. Test nell'app.

6. Commit Git.

7. Passo successivo.

Non saranno effettuati grandi refactoring non verificabili.

La qualità architetturale ha la stessa importanza della correttezza funzionale.

---

# OBIETTIVO DI H6

Al termine della milestone il progetto dovrà avere:

- motori più semplici;
- responsabilità ancora meglio distribuite;
- Builder pienamente consolidati;
- schermate ancora più leggere;
- basi solide per l'espansione futura.

H6 non introduce grandi funzionalità.

Introduce qualità strutturale.

---
# MILESTONE FUTURE

Le milestone riportate di seguito rappresentano la direzione strategica del progetto.

L'ordine potrà essere modificato soltanto attraverso una decisione architetturale ufficiale.

---

# H7 — INTELLIGENZA DECISIONALE

🔵 PREVISTA

Conclusa la pulizia architetturale dei motori, il focus tornerà sulla qualità delle decisioni.

L'obiettivo non sarà aggiungere nuove schermate.

L'obiettivo sarà insegnare a FrodoDesk a ragionare meglio.

Aree di sviluppo previste:

- nuove regole del Planner;
- miglioramento delle spiegazioni;
- simulazioni economiche più realistiche;
- valutazione automatica degli scenari;
- confronto tra alternative;
- maggiore capacità predittiva.

Ogni decisione dovrà essere:

- motivata;
- spiegabile;
- verificabile.

---

# H8 — OBSERVATION EVOLUTION

🔵 PREVISTA

L'Observation Engine diventerà il punto di incontro dei diversi motori del sistema.

Ogni modulo dovrà essere in grado di produrre osservazioni significative.

Provider previsti:

- Finance;
- Coverage;
- Calendar;
- Statistics;
- Health;
- Home;
- Maintenance;
- Future modules.

La Home dovrà diventare progressivamente un semplice lettore delle osservazioni prodotte dal sistema.

---

# H9 — ECOSISTEMA FRODODESK

🔵 PREVISTA

Questa milestone riguarda l'espansione dell'intero ecosistema.

Argomenti previsti:

- multi-famiglia;
- ruoli;
- permessi;
- sincronizzazione cloud;
- dispositivi multipli;
- backup evoluti;
- collaborazione tra utenti.

Questa fase inizierà solo quando il nucleo del progetto sarà considerato stabile.

---

# IDEE PARCHEGGIATE

Le idee riportate in questa sezione sono considerate interessanti ma non prioritarie.

Non autorizzano automaticamente lo sviluppo.

Potranno essere pianificate soltanto quando coerenti con la roadmap ufficiale.

Tra le principali:

- IPS evoluto;
- suggerimenti proattivi;
- statistiche avanzate;
- simulazioni familiari;
- manutenzione della casa;
- salute;
- energia domestica;
- manutenzione veicoli;
- ecosistema documentale;
- integrazione cloud;
- sincronizzazione intelligente.

---

# REGOLE DI EVOLUZIONE

Ogni nuova funzionalità dovrà seguire questo percorso.

```text
Idea
    ↓
Analisi
    ↓
Decisione architetturale
    ↓
Aggiornamento della Roadmap
    ↓
Implementazione
    ↓
Consolidamento
    ↓
Utilizzo reale
    ↓
Evoluzione
```

Mai il contrario.

---

# CRITERI DI PRIORITÀ

Quando sarà necessario scegliere tra più sviluppi possibili verranno seguiti questi criteri.

Priorità assoluta:

1. stabilità;
2. qualità architetturale;
3. correttezza funzionale;
4. semplicità;
5. esperienza d'uso;
6. nuove funzionalità.

Una nuova funzione non verrà sviluppata se compromette la qualità dell'architettura.

---

# DEFINIZIONE DI "COMPLETATO"

Una milestone viene considerata conclusa soltanto quando soddisfa tutti i seguenti requisiti.

- architettura coerente;
- codice compilabile;
- test effettuati;
- utilizzo nella vita reale;
- documentazione aggiornata;
- commit conclusivi;
- nessuna regressione nota.

Solo a quel punto il progetto può passare alla milestone successiva.

---

# VISIONE STRATEGICA

FrodoDesk non nasce per sostituire le persone.

Nasce per renderle più consapevoli.

Il sistema deve:

- osservare;
- comprendere;
- collegare informazioni;
- interpretare i dati;
- simulare conseguenze;
- proporre alternative.

Ogni suggerimento deve essere spiegabile.

Ogni simulazione deve essere verificabile.

Ogni decisione deve poter essere compresa.

---

# PRINCIPIO FONDAMENTALE

> **FrodoDesk osserva, interpreta, organizza e propone.**
>
> **La decisione finale rimane sempre umana.**

Questo principio guida ogni scelta architetturale e rappresenta il confine tra il sistema e l'utente.

---

# FINE DOCUMENTO