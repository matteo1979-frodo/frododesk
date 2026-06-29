# FINANCE OBSERVATION ENGINE

Ultimo aggiornamento: Giugno 2026

---

# SCOPO

Il Finance Observation Engine trasforma i dati economici di FrodoDesk in osservazioni comprensibili.

Non deve mostrare righe del database.

Deve interpretare la situazione economica familiare.

Una Observation finanziaria non rappresenta una voce.

Rappresenta un fatto economico.

---

# PRINCIPIO BASE

Il modulo Finanze deve produrre poche macro-osservazioni intelligenti.

Non 25 notifiche.

Non una card per ogni bolletta.

Non una card per ogni stipendio.

La struttura definitiva è composta da 5 macro-card:

1. Scadenze
2. Entrate
3. Situazione economica
4. Fondi
5. Piano consigliato

---

# STRUTTURA DI UNA OBSERVATION

Ogni Observation deve poter contenere:

* titolo
* messaggio
* dettaglio
* impatto
* azione
* target
* priorità
* livello
* data collegata

Schema ideale:

Titolo
Messaggio breve
Dettaglio
Impatto
Azione consigliata

Non tutti i campi sono obbligatori.

---

# 1. SCADENZE

Domanda a cui risponde:

Cosa devo ancora pagare?

La macro-card Scadenze deve raggruppare:

* scadenze in ritardo
* scadenze di oggi
* scadenze entro 7 giorni
* scadenze del mese
* scadenze future
* scadenze già confermate
* scadenze non confermate

Non deve mostrare una sola bolletta.

Deve raccontare la situazione delle scadenze.

Esempio:

Titolo:
Scadenze

Messaggio:
8 scadenze ancora da confermare per 1.240 €.

Dettaglio:
In ritardo
Luce Octopus -60 €

Entro 7 giorni
Mutuo -730 €
Gas -95 €

Entro il mese
Assicurazione -297 €

Future
IMU dicembre -725 €

Impatto:
Le scadenze non confermate rappresentano gli impegni economici ancora aperti.

Versione definitiva:
La card dovrà anche indicare chi paga, da quale conto, e se la distribuzione prevista crea sofferenza.

---

# 2. ENTRATE

Domanda a cui risponde:

Cosa entrerà e quando?

La macro-card Entrate deve raggruppare le entrate per evento economico, non per singola voce.

Se due stipendi arrivano lo stesso giorno, devono diventare una sola Observation.

Esempio:

Titolo:
Entrate in arrivo

Messaggio:
Il 05/07 sono previste entrate per +3.402 €.

Dettaglio:
Matteo +1.495 €
Chiara +1.906 €

Impatto:
Queste entrate aumenteranno la disponibilità economica del mese.

Versione definitiva:
La card dovrà includere stipendio, assegno unico, rimborsi, tredicesima, quattordicesima, premi produzione ed entrate straordinarie.

---

# 3. SITUAZIONE ECONOMICA

Domanda a cui risponde:

Come stiamo messi?

La macro-card Situazione economica deve sintetizzare:

* disponibilità prevista Matteo
* disponibilità prevista Chiara
* disponibilità familiare
* pressione del mese
* rischio di rosso
* ossigeno operativo
* trend

Esempio:

Titolo:
Situazione economica

Messaggio:
La famiglia chiude il mese con saldo previsto positivo.

Dettaglio:
Matteo +420 €
Chiara +850 €
Famiglia +1.270 €

Impatto:
La distribuzione attuale non genera sofferenza economica immediata.

Versione futura:
Dovrà prevedere se nei mesi successivi emerge rischio di collasso.

---

# 4. FONDI

Domanda a cui risponde:

Siamo protetti?

La macro-card Fondi deve osservare:

* fondo emergenza
* fondo auto
* fondo casa
* fondo salute
* fondo scuola
* fondi generici
* copertura reale
* fondi protetti
* rischio di fondi insufficienti

Esempio:

Titolo:
Stato dei fondi

Messaggio:
I fondi coprono parzialmente gli impegni futuri.

Dettaglio:
Emergenza 1.200 €
Auto 300 €
Casa 0 €

Impatto:
In caso di spesa imprevista, la copertura potrebbe non essere sufficiente.

Versione definitiva:
Ogni fondo dovrà avere un obiettivo o una soglia consigliata.

---

# 5. PIANO CONSIGLIATO

Domanda a cui risponde:

Cosa conviene fare?

Questa macro-card sarà prodotta dal futuro Finance Planner.

Il Planner non guarda una singola bolletta.

Guarda tutto il mese e poi gli orizzonti futuri.

Dovrà simulare:

* chi paga cosa
* da quale conto
* cosa succede se paga Matteo
* cosa succede se paga Chiara
* se serve un fondo
* se una spesa può slittare
* se il mese resta stabile
* se tra 3, 6 o 12 mesi nasce un rischio

Esempio:

Titolo:
Piano consigliato

Messaggio:
La distribuzione attuale è sostenibile, ma conviene lasciare l’assicurazione su Chiara.

Dettaglio:
Se paga Matteo: saldo previsto 80 €
Se paga Chiara: saldo previsto 620 €
Fondo emergenza non necessario.

Impatto:
Spostare il pagamento mantiene entrambi i conti sopra soglia.

---

# ORIZZONTI DI PREVISIONE

Il sistema dovrà ragionare su più orizzonti:

* oggi
* 7 giorni
* mese corrente
* 3 mesi
* 6 mesi
* 12 mesi

Obiettivo finale:

FrodoDesk deve poter dire:

A luglio sei stabile.
Ad agosto sei ancora coperto.
A novembre nasce una sofferenza.
A dicembre rischi collasso se non aumenti la copertura.

---

# REGOLA FONDAMENTALE

Le Observation non rappresentano record.

Rappresentano eventi economici.

Esempio sbagliato:

Stipendio Panna
Stipendio Panna

Esempio corretto:

Entrate in arrivo
Matteo +1.495 €
Chiara +1.906 €

---

# ROADMAP PUNTO 2

Implementazione in ordine:

1. Rifattorizzare FinanceObservationReader in metodi privati.
2. Completare macro-card Scadenze.
3. Completare macro-card Entrate.
4. Creare macro-card Situazione economica.
5. Creare macro-card Fondi.
6. Preparare struttura per Piano consigliato.
7. Solo dopo iniziare il Finance Planner vero.

---

# STATO ATTUALE

Già fatto:

* Observation Engine H4
* macro-card Entrate in arrivo
* prima macro-card Scadenze impostata
* pagina Observation Finanze
* modello FrodoObservation esteso con details e impact

Prossimo passo tecnico:

Rifattorizzare FinanceObservationReader per arrivare a questa struttura:

analyze() {
_buildUpcomingDeadlinesObservation();
_buildUpcomingIncomeObservation();
_buildEconomicSituationObservation();
_buildFundsObservation();
_buildPlannerObservation();
}

---

# REGOLA DI SVILUPPO

Da ora in poi non si aggiungono Observation isolate.

Ogni nuova informazione deve appartenere a una delle 5 macro-card.

Se non appartiene a nessuna macro-card, va ripensata.

---

# SCENARI DI RIFERIMENTO

Il Finance Observation Engine dovrà essere validato attraverso scenari reali.

Ogni nuova funzionalità dovrà essere verificata confrontandola con questi scenari.

Se uno scenario non è ancora risolvibile, significa che il motore non è ancora completo.

---

## SCENARIO 1 — Conto in sofferenza

Matteo termina il mese con saldo negativo.

Chiara termina il mese con saldo positivo.

Il Planner deve verificare se alcune spese possono essere spostate su Chiara mantenendo invariato il saldo familiare.

---

## SCENARIO 2 — Entrate prima delle uscite

Gli stipendi arrivano prima delle principali scadenze.

Il Planner deve riconoscere che non è necessario utilizzare il fondo emergenza.

---

## SCENARIO 3 — Entrate dopo le uscite

Le principali scadenze arrivano prima degli stipendi.

Il Planner deve individuare la migliore soluzione temporanea:

* utilizzo del fondo emergenza;
* spostamento dei pagamenti;
* utilizzo di un altro conto;
* altre strategie disponibili.

---

## SCENARIO 4 — Utilizzo dei fondi

Una spesa straordinaria deve essere coperta.

Se esiste un fondo dedicato con disponibilità sufficiente, il Planner deve preferire quel fondo rispetto ai conti correnti.

---

## SCENARIO 5 — Riduzione delle entrate

Una delle entrate previste viene meno.

Il Planner deve ricalcolare automaticamente la situazione economica dei mesi successivi e individuare eventuali criticità.

---

## SCENARIO 6 — Pagamento alternativo

Una spesa può essere sostenuta sia da Matteo che da Chiara.

Il Planner deve simulare entrambe le possibilità e proporre quella economicamente più favorevole.

---

## SCENARIO 7 — Distribuzione dei pagamenti

Durante il mese sono presenti numerose scadenze.

Il Planner deve distribuire automaticamente i pagamenti tra i conti disponibili in modo da ridurre la pressione economica.

---

## SCENARIO 8 — Simulazione a medio termine

Il Planner deve essere in grado di simulare la situazione economica a:

* 7 giorni;
* fine mese;
* 3 mesi;
* 6 mesi;
* 12 mesi.

L'obiettivo non è prevedere il futuro con certezza, ma individuare con anticipo eventuali criticità.

---

## SCENARIO 9 — Rischio di collasso

Se la simulazione individua un punto nel quale uno o più conti non riusciranno più a sostenere le uscite previste, il Planner deve:

* individuare il momento del collasso;
* spiegarne le cause;
* proporre almeno una strategia alternativa.

---

## SCENARIO 10 — Ottimizzazione automatica

Quando esistono più strategie possibili, il Planner deve confrontarle e scegliere quella che mantiene la migliore stabilità economica complessiva.

---

# PRINCIPIO FONDAMENTALE DEL PLANNER

Il Finance Planner non deve limitarsi a descrivere i problemi.

Deve cercare automaticamente la migliore soluzione utilizzando tutte le informazioni disponibili nel sistema.

Prima di segnalare una criticità deve sempre verificare se esiste una strategia migliore ottenibile tramite:

* diversa distribuzione dei pagamenti;
* utilizzo dei fondi;
* modifica del conto utilizzato;
* utilizzo delle entrate imminenti;
* spostamento di spese non urgenti;
* qualsiasi altra informazione disponibile nel modello economico.

L'obiettivo finale del Planner è comportarsi come un consulente finanziario personale.

Non deve limitarsi a dire cosa sta succedendo.

Deve spiegare perché sta succedendo e proporre la migliore soluzione possibile.

---

# ROADMAP DI IMPLEMENTAZIONE

Il Finance Observation Engine verrà sviluppato in fasi progressive.

Ogni fase dovrà produrre un sistema funzionante e coerente, evitando funzionalità parziali o duplicate.

## FASE 1 — Fondamenta (in corso)

Obiettivo:

Creare il framework delle Observation economiche.

Comprende:

* struttura di FrodoObservation;
* Observation Engine;
* FinanceObservationReader;
* pagina Observation Finanze;
* supporto a details e impact;
* rifattorizzazione in macro-card.

---

## FASE 2 — Macro-card

Realizzare completamente le cinque macro-card fondamentali.

1. Scadenze
2. Entrate
3. Situazione economica
4. Stato dei fondi
5. Piano consigliato (prima versione)

Ogni macro-card dovrà essere indipendente e mantenibile.

---

## FASE 3 — Simulatore economico

Il sistema dovrà iniziare a simulare scenari futuri.

Previsioni:

* fine settimana;
* fine mese;
* 3 mesi;
* 6 mesi;
* 12 mesi.

---

## FASE 4 — Planner intelligente

Il Planner dovrà confrontare automaticamente strategie differenti.

Esempi:

* paga Matteo;
* paga Chiara;
* usa il fondo;
* rinvia la spesa;
* distribuisci le uscite.

Per ogni strategia dovrà calcolare vantaggi e svantaggi.

---

## FASE 5 — Consulente finanziario

Il Planner non dovrà più limitarsi a rispondere.

Dovrà iniziare a proporre.

Esempi:

* "Conviene anticipare questa spesa."
* "Meglio attendere lo stipendio."
* "Il fondo emergenza non è necessario."
* "Questa scelta riduce il rischio dei prossimi tre mesi."

---

## FASE 6 — Decision Engine

Versione definitiva.

Il Planner dovrà essere in grado di simulare contemporaneamente centinaia di combinazioni possibili e scegliere automaticamente quella che massimizza la stabilità economica familiare.

Il suo obiettivo non sarà soltanto prevedere il futuro.

Sarà aiutare la famiglia a prendere decisioni migliori.

---

# ARCHITETTURA INTERNA DEL FINANCE OBSERVATION ENGINE

Le macro-card non devono leggere direttamente il `FinanceStore`.

Ogni macro-card deve essere costruita in due fasi.

## FASE 1 — Analisi

Il Reader trasforma i dati grezzi del FinanceStore in un modello di situazione.

Esempi:

```text
FinanceStore
      ↓

FinanceDeadlinesSituation

FinanceIncomeSituation

FinanceEconomicSituation

FinanceFundsSituation
```

Questi modelli rappresentano la situazione economica elaborata e non contengono elementi grafici.

Devono essere completamente riutilizzabili.

---

## FASE 2 — Presentazione

Le macro-card trasformano i modelli di situazione in Observation.

Schema definitivo:

```text
FinanceStore

↓

Analyzer

↓

FinanceSituation

↓

Observation

↓

UI
```

---

# PRINCIPIO DI RIUTILIZZO

Il futuro Finance Planner non dovrà leggere direttamente il FinanceStore.

Utilizzerà esclusivamente i modelli prodotti dagli Analyzer.

Schema definitivo del motore:

```text
FinanceStore

↓

Deadlines Analyzer
↓

FinanceDeadlinesSituation

Income Analyzer
↓

FinanceIncomeSituation

Economic Analyzer
↓

FinanceEconomicSituation

Funds Analyzer
↓

FinanceFundsSituation

↓

Finance Planner

↓

PlannerDecision

↓

Observation
```

---

# VANTAGGI

* Nessuna duplicazione della logica.
* Una sola fonte di verità per ogni analisi.
* Le macro-card diventano semplici viste dei dati.
* Il Planner utilizza gli stessi risultati mostrati all'utente.
* Ogni Analyzer può essere testato in modo indipendente.
* L'architettura rimane estendibile senza modificare il Reader.

---

# REGOLA ARCHITETTURALE

Ogni nuova analisi economica deve essere implementata come Analyzer indipendente.

Il Reader coordina gli Analyzer.

Le Observation visualizzano il risultato.

Il Planner prende decisioni utilizzando esclusivamente i modelli di situazione prodotti dagli Analyzer.
