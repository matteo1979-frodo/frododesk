# FRODODESK — MODULO FINANZE

Stato: Finanze V1 visiva funzionante  
Ultimo aggiornamento: 15 Maggio 2026

---

# IDENTITÀ DEL MODULO

Il modulo Finanze NON è:

❌ una banca  
❌ un home banking  
❌ un gestionale movimenti  
❌ un foglio Excel gigante  

Il modulo Finanze è:

👉 simulazione della stabilità economica futura della famiglia.

---

# DOMANDA PRINCIPALE

Il modulo deve aiutare a rispondere a:

👉 “Dove stiamo andando?”

---

# FILOSOFIA FONDAMENTALE

Il sistema:

✔ simula  
✔ prevede  
✔ stima  
✔ evidenzia pressione futura  

MA:

❌ non decide  
❌ non blocca  
❌ non sostituisce l’umano  

---

# PRINCIPIO STRUTTURALE

# PREVISIONE ≠ REALTÀ

Il sistema deve distinguere sempre:

✔ previsione economica  
da  
✔ situazione economica reale

---

# ESEMPI

## Ricorrenza

Netflix:

17€/mese previsti

NON significa:

✔ pagamento reale effettuato

Il mese reale può essere:

- 17€
- 19€
- sospeso
- annullato

---

## Stipendio

Il sistema può:

✔ stimare andamento futuro

MA:

✔ lo stipendio reale viene inserito manualmente dall’utente

---

# OBIETTIVI REALI DEL MODULO

Il modulo dovrà permettere di capire:

- sostenibilità futura
- margine economico reale
- pressione economica
- rischio futuro
- utilizzo fondi
- andamento familiare

---

# STRUTTURA BASE FUTURA

## Saldi

Ogni persona possiede:

✔ saldo iniziale manuale  
✔ saldo aggiornabile  

---

## Persone

Struttura predisposta per:

✔ Matteo  
✔ Chiara  
✔ Alice  

anche se Alice oggi non possiede ancora:

- conto reale
- spese autonome
- entrate

---

# SIMULAZIONE FUTURA

Il sistema dovrà simulare:

✔ entrate previste  
✔ spese previste  
✔ ricorrenze  
✔ fondi  
✔ andamento mesi futuri  

---

# FONDI

Il sistema dovrà supportare:

✔ fondi dedicati  

Esempi:

- fondo auto
- emergenze
- vacanze
- casa

---

# PRESSIONE ECONOMICA

Il sistema NON deve dire:

❌ “non puoi spendere”

Deve mostrare:

✔ conseguenze future  
✔ abbassamento margine  
✔ pressione crescente  
✔ rischio futuro

---

# PRINCIPIO UMANO

👉 La decisione resta sempre umana.

Anche se:

- il sistema rileva rischio
- il saldo scende
- il fondo viene svuotato
- il futuro peggiora

---

# STIPENDI

Decisione strutturale:

✔ simulazione automatica possibile  
✔ andamento storico possibile  

MA:

✔ conferma reale manuale ogni mese

---

# RICORRENZE

Le ricorrenze rappresentano:

✔ previsione

NON:

✔ evento economico realmente avvenuto

---

# MODELLO RICORRENZE — FINANZE V1

Ogni ricorrenza economica è ora considerata un:

👉 oggetto economico vivo del sistema.

Le ricorrenze non contengono più solo:

- nome
- importo

ma anche:

- categoria
- ricorrenza
- obbligatorietà
- pressione economica
- stato reale
- variabilità
- stabilità
- protezione
- priorità pagamento
- rischio sospensione
- descrizione
- conferma manuale

---

# DISTINZIONI STRUTTURALI INTRODOTTE

## Obbligatorietà

Il sistema distingue:

✔ spese obbligatorie  
✔ spese facoltative

Esempi:

- mutuo → obbligatorio
- bollette → obbligatorie
- Netflix → facoltativa

---

## Pressione economica

Ogni ricorrenza può avere:

- bassa
- media
- alta
- critica

Questa informazione servirà in futuro per:

- IPS economico
- simulazioni crisi
- pressione familiare

---

## Stato reale

Il sistema distingue:

✔ previsto  
✔ confermato

Esempio:

Uno stipendio previsto NON significa:

✔ stipendio realmente ricevuto.

---

## Variabilità

Ogni ricorrenza può essere:

✔ fissa  
✔ variabile

Esempi:

- Netflix → fissa
- bolletta luce → variabile
- mensa Alice → variabile

---

## Stabilità

Ogni ricorrenza può essere:

✔ stabile  
✔ instabile

Questa informazione servirà per:

- simulazioni future
- rischio oscillazione
- previsione sostenibilità

---

## Protezione

Il sistema distingue:

✔ elementi protetti  
✔ elementi non protetti

Esempi:

- fondo emergenze → protetto
- stipendio principale → protetto
- Netflix → non protetto

---

## Priorità pagamento

Ogni ricorrenza può avere:

- bassa
- normale
- alta
- critica

Esempi:

- mutuo → critica
- luce → alta
- Netflix → bassa

---

## Rischio sospensione

Il sistema deve poter stimare:

👉 cosa succede se una ricorrenza viene saltata.

Esempi:

- Netflix → rischio basso
- bolletta luce → rischio alto
- mutuo → rischio critico

---

# FONDI — FINANZE V1

Finanze V1 introduce già:

✔ Fondi economici separati

con:

- nome
- descrizione
- importo
- stato protetto/non protetto

Esempi attuali:

- Emergenze
- Fondo Auto

---

# UI FINANZE V1

Finanze V1 possiede già:

✔ Home Finanze funzionante  
✔ Popup Entrate previste  
✔ Popup Uscite previste  
✔ Popup Margine previsto  
✔ Popup Fondi  
✔ Popup dettaglio singola ricorrenza

---

# COMPONENTI UI INTRODOTTI

Finanze V1 introduce:

✔ `_financeBadge()`

come componente UI riutilizzabile per:

- badge stato
- pressione
- protezione
- rischio
- stabilità
- priorità

Decisione architetturale:

👉 modularizzare progressivamente la UI evitando duplicazioni.

---

# DECISIONE ARCHITETTURALE TEMPORANEA

Durante la costruzione di Finanze V1:

alcuni badge/logiche delle Uscite sono stati temporaneamente utilizzati anche nelle Entrate per velocizzare la costruzione.

Decisione ufficiale:

❌ NON rifinire ora.

In futuro:

✔ separare completamente logica/UI Entrate vs Uscite.

---

# ESEMPI FUTURI

- assicurazione auto
- Netflix
- bollette
- mutuo
- telefono
- manutenzioni
- tasse
- mensa Alice
- carburante
- straordinari

---

# COLLEGAMENTO FUTURO CON STATISTICHE

Statistiche dovrà leggere:

✔ andamento economico  
✔ trend spese  
✔ pressione futura  
✔ consumo fondi  
✔ andamento persone  
✔ stabilità economica  
✔ rischio sospensione

---

# DIREZIONE ARCHITETTURALE

Finanze deve inizialmente vivere separato da:

- Spese
- IPS
- Statistiche

e collegarsi gradualmente.

---

# STATO ATTUALE — FINANZE V1

✔ Fondamenta Finanze V1 completate  
✔ Distinzione previsione/realtà consolidata  
✔ Entrate/Uscite separate  
✔ Ricorrenze economiche vive  
✔ Fondi base presenti  
✔ Badge modularizzati  
✔ Modello economico avanzato introdotto  
✔ UI navigabile stabile  
✔ Nessuna persistenza ancora presente

---

# ROADMAP ATTUALE

☑ Filosofia modulo definita  
☑ Distinzione previsione/realtà consolidata  
☑ Struttura persone definita  
☑ Simulazione futura definita  
☑ Ricorrenze definite come previsione  
☑ Fondamenta Finanze V1 costruite  
☑ Popup Entrate/Uscite funzionanti  
☑ Sistema badge modulare introdotto  
☑ Modello ricorrenze avanzato introdotto  

⬜ Persistenza reale dati finanze  
⬜ Inserimento/modifica saldi reali  
⬜ Inserimento/modifica fondi reali  
⬜ Inserimento/modifica ricorrenze reali  
⬜ Prima simulazione economica reale  
⬜ Collegamento futuro con Statistiche  
⬜ Collegamento futuro con IPS economico
---

# EVOLUZIONE UI — PRESSIONE TEMPORALE (MAGGIO 2026)

Durante questa fase è iniziata la trasformazione della UI Finanze da:

❌ lista verticale tecnica

verso:

✔ dashboard economica temporale reale.

---

# NUOVA DIREZIONE UI

Decisione strutturale confermata:

La sezione “Pressione temporale” NON deve essere:

- una semplice lista mesi
- una colonna infinita di card
- una visualizzazione tecnica

Deve diventare:

👉 una lettura temporale economica della vita familiare.

---

# EVOLUZIONE INTRODOTTA

Sono state introdotte:

✔ card mesi compatte  
✔ stato visivo mese  
✔ colori pressione economica  
✔ vista annuale Gennaio → Dicembre  
✔ struttura predisposta anni multipli  
✔ navigazione temporale futura  

---

# STATI VISIVI MESE

Ogni mese ora può essere:

✔ stabile  
✔ pressione  
✔ critico  

con:

- colore dedicato
- stato visivo
- margine economico

---

# DIREZIONE FUTURA

La sezione evolverà verso:

✔ heatmap pressione economica  
✔ timeline economica reale  
✔ navigazione anni completa  
✔ confronto anni  
✔ pressione economica storica  
✔ pressione futura simulata  

---

# PROBLEMA ATTUALMENTE APERTO

La nuova navigazione anni è stata introdotta ma NON è ancora stabile.

Problemi emersi:

- gestione stato selectedYear
- refactor incompleto della sezione
- rischio perdita popup dettaglio mese durante modifiche rapide

Decisione ufficiale:

❌ fermare modifiche veloci

✔ fare refactor completo e sicuro del blocco “Pressione temporale”

con approccio:

👉 0 rischio
👉 blocco intero
👉 preservazione popup mese
👉 preservazione logica economica esistente.

---

# STATO REALE ATTUALE

✔ struttura dashboard migliorata  
✔ popup mesi più leggibile  
✔ mesi annuali visibili  
✔ base navigazione anni introdotta  

🟡 navigazione anni ancora instabile

---

# FASE FINANZE REALI — MAGGIO 2026

Nuova decisione strutturale ufficiale:

Finanze NON deve evolvere verso:

❌ semplice tracker spese
❌ semplice contabilità
❌ semplice saldo mensile

Finanze deve evolvere verso:

👉 simulazione della stabilità economica familiare reale.

---

# NUOVI CONCETTI UFFICIALI INTRODOTTI

## PRESSIONE ECONOMICA

La pressione economica NON rappresenta:

❌ “quanti soldi restano”

La pressione rappresenta:

✔ fragilità del sistema familiare
✔ capacità di assorbire imprevisti
✔ sostenibilità futura
✔ resilienza reale

---

## PRESSIONE PREVEDIBILE

Esempi:

- mutuo
- bollette
- assicurazione
- revisione
- mensa base

Sono elementi:

✔ prevedibili
✔ simulabili
✔ preparabili

---

## PRESSIONE IMPREVEDIBILE

Esempi:

- dentista
- fisioterapia
- guasti
- visite urgenti
- spese extra improvvise

Queste misurano:

✔ resilienza reale
✔ capacità di sopravvivenza economica

---

## PRESSIONE STATICA vs DINAMICA

### STATICA

Spese relativamente stabili:

- mutuo
- abbonamenti
- rate

### DINAMICA

Spese che nascono dalla vita reale:

- Sandra
- mensa Alice
- centro estivo
- sport
- ripetizioni
- eventi scolastici

La pressione nasce dal comportamento della vita familiare.

---

# RESILIENZA ECONOMICA

Nuovo concetto ufficiale:

Il sistema NON deve leggere solo:

- saldo
- margine

Deve leggere:

✔ quanto il sistema familiare riesce ad assorbire imprevisti
✔ quanti mesi riesce a sostenere pressione
✔ quanto è protetto
✔ quanto è fragile

---

# SIMULAZIONE MULTI-MESE

Decisione ufficiale:

La pressione economica NON deve leggere solo il mese corrente.

Deve simulare:

✔ 3 mesi
✔ 6 mesi
✔ 12 mesi

per capire:

- accumulo pressione
- rischio futuro
- conseguenze delle decisioni

Esempio:

✔ una spesa oggi può creare pressione reale fra 8 mesi.

---

# ENTITÀ ECONOMICHE VIVE

Nuova direzione ufficiale:

Le voci economiche NON devono essere semplici “spese”.

Devono diventare:

👉 entità economiche vive.

Ogni elemento economico deve possedere:

- comportamento
- prevedibilità
- variabilità
- rischio
- stabilità
- periodicità
- protezione
- collegamenti
- memoria
- pressione futura

---

# INSERIMENTO MANUALE OBBLIGATORIO

Decisione strutturale IMPORTANTISSIMA:

❌ NON devono esistere voci economiche precompilate.

Tutto deve nascere da inserimento manuale utente.

Flusso ufficiale:

1. utente crea voce economica
2. sceglie categoria/tipo
3. il sistema fa domande specifiche
4. il motore genera il comportamento economico corretto

---

# ESEMPI DIREZIONE FUTURA

## MUTUO

Il sistema dovrà poter leggere:

- rata
- fisso/variabile
- rischio aumento
- scadenza
- fine mutuo
- periodicità

---

## LUCE

Il sistema dovrà poter leggere:

- quota stimata
- variabilità
- fornitore
- scadenza offerta
- rinnovo contratto

e generare:

✔ avvisi preventivi
✔ prevenzione aumento costi
✔ simulazione futura

---

## SANDRA

Sandra NON è considerata:

❌ spesa fissa

Sandra è:

👉 pressione logistica trasformata in pressione economica.

Dipende da:

- turni
- scuola
- eventi Alice
- ferie
- malattie
- copertura reale

---

## MENSA ALICE

La mensa NON è totalmente prevedibile.

Dipende da:

- presenza reale Alice
- malattia
- uscite anticipate
- gite
- eventi scolastici

---

# DIREZIONE OPERATIVA UFFICIALE

Decisione ufficiale Maggio 2026:

⚠️ NON espandere nuove aree funzionali.

Priorità assoluta:

➡️ consolidare modulo Finanze
➡️ costruire pressione economica reale
➡️ costruire simulazione futura reale
➡️ mantenere calendario stabile durante utilizzo vita reale

---

# DNA ECONOMICO — LEGGI COMPORTAMENTALI H2

Questa sezione consolida le decisioni emerse durante la fase H2 del motore economico reale.

Le seguenti leggi NON rappresentano ancora formule matematiche definitive.

Rappresentano il comportamento reale che il motore dovrà leggere e simulare.

---

## OSSIGENO ECONOMICO

L’ossigeno economico NON rappresenta:

❌ il saldo disponibile

❌ il denaro totale posseduto

❌ la semplice differenza tra entrate e uscite

L’ossigeno economico rappresenta:

👉 la capacità della famiglia di assorbire la vita reale senza entrare in sofferenza strutturale.

Due famiglie con lo stesso denaro possono avere livelli di ossigeno completamente diversi.

Dipende da:

- pressione presente
- pressione futura
- protezioni disponibili
- resilienza
- vulnerabilità
- sincronizzazione economica

---

## LEGGE 1 — PRESSIONE REALE

Una spesa non genera pressione in base al suo importo.

Genera pressione in base a quanto il sistema era preparato ad assorbirla.

Esempio:

- assicurazione prevista → pressione limitata
- guasto improvviso → pressione elevata

anche con importo identico.

---

## LEGGE 2 — DANNO RESIDUO

La pressione non misura il costo dell’evento.

Misura quanto l’evento ha indebolito la capacità futura della famiglia di assorbire la vita.

Due spese uguali possono produrre danni completamente diversi.

---

## LEGGE 3 — CONSUMO DI RESILIENZA

Un fondo utilizzato non genera necessariamente pressione immediata.

Riduce però la resilienza futura del sistema.

L’utilizzo di una protezione NON è mai completamente gratuito.

---

## LEGGE 4 — RESILIENZA STRUTTURATA

Non tutta la liquidità ha lo stesso valore.

Una liquidità organizzata in protezioni dedicate:

- aumenta la capacità di assorbire eventi
- aumenta la resilienza
- riduce la pressione futura

Fondi e protezioni hanno un valore sistemico superiore alla semplice liquidità non organizzata.

---

## LEGGE 5 — VULNERABILITÀ ACQUISITA

Quando una protezione viene consumata:

il sistema non diventa automaticamente instabile.

Diventa però più vulnerabile a una specifica categoria di eventi futuri.

Esempio:

Fondo Auto svuotato.

La famiglia può essere ancora stabile oggi.

Ma il prossimo evento Auto avrà un impatto potenzialmente molto maggiore.

---

## LEGGE 6 — DIREZIONE DEL SISTEMA

Lo stato della famiglia non dipende solo dalle risorse disponibili.

Dipende anche dalla direzione in cui il sistema si sta muovendo.

Differenza fondamentale:

### Sistema che sopravvive

- resiste
- non peggiora
- non recupera

### Sistema che guarisce

- ricostruisce protezioni
- recupera resilienza
- migliora progressivamente la propria stabilità

La traiettoria del sistema è importante quanto il suo stato attuale.

---

## DISTINZIONE UFFICIALE

### DENARO

Risponde alla domanda:

👉 Quanto possiedo oggi?

---

### OSSIGENO

Risponde alla domanda:

👉 Quanto posso ancora assorbire la vita senza entrare in sofferenza?

---

### RESILIENZA

Risponde alla domanda:

👉 Quanto sono preparato al prossimo colpo?

---

### PROTEZIONE

Risponde alla domanda:

👉 Quali categorie di rischio sono già coperte?

---

### DIREZIONE

Risponde alla domanda:

👉 Sto guarendo oppure sto semplicemente sopravvivendo?

---

Decisione ufficiale H2:

Il motore economico di FrodoDesk NON deve leggere solo il denaro.

Deve leggere:

✔ denaro

✔ ossigeno

✔ resilienza

✔ protezioni

✔ vulnerabilità

✔ direzione del sistema

# CONSOLIDAMENTO VITA REALE — GIUGNO 2026

Durante la fase di consolidamento del motore economico reale, il modulo Finanze ha completato la transizione da semplice popup della Home a vero e proprio Centro Controllo Economico.

---

## NUOVA DIREZIONE UI

La gestione Finanze non vive più come semplice finestra modale.

Diventa una schermata dedicata, mantenendo però tutta la filosofia originaria del modulo.

Decisione ufficiale:

👉 la UI deve facilitare la lettura della situazione economica reale della famiglia.

---

## CENTRO CONTROLLO ECONOMICO

La schermata Finanze assume ufficialmente il ruolo di:

✔ lettura dei conti reali

✔ lettura delle ricorrenze

✔ lettura della pressione temporale

✔ lettura dei fondi

✔ simulazione economica futura

senza trasformarsi in un home banking.

---

## DISTINZIONE SALDO / PREVISIONE

Viene consolidata e verificata la regola fondamentale del modulo.

### Saldo reale

Rappresenta esclusivamente il denaro realmente disponibile.

Non deve essere influenzato dalle ricorrenze non ancora confermate.

---

### Pressione futura

Rappresenta la previsione economica della famiglia.

Può considerare:

* ricorrenze
* stipendi previsti
* fondi
* simulazioni

senza modificare il saldo reale.

---

## CONFERMA MANUALE

Le ricorrenze continuano ad essere considerate:

👉 previsione.

Solo la conferma manuale dell'utente trasforma una previsione in evento economico reale.

Regole consolidate:

✔ ricorrenza creata → saldo invariato

✔ conferma ricorrenza → saldo aggiornato

✔ annullamento conferma → saldo ripristinato

---

## COERENZA CONTI REALI

Decisione strutturale ufficiale:

Home e schermate dettaglio devono leggere lo stesso insieme di conti attivi.

I conti disattivati o eliminati NON devono contribuire ai saldi aggregati.

---

## COLLAUDO VITA REALE

Il motore è stato verificato con test pratici.

Scenario testato:

* creazione uscita di prova
* conferma manuale
* aggiornamento saldo
* eliminazione conferma
* ripristino saldo

Esito:

✔ comportamento corretto.

---

## NUOVA FASE OPERATIVA

Il modulo Finanze entra ufficialmente nella fase:

### H3.5 — Consolidamento Vita Reale

Obiettivo:

verificare che il comportamento del sistema coincida con il comportamento della vita reale prima di espandere ulteriormente il motore economico.

# CONSOLIDAMENTO VITA REALE — GIUGNO 2026

Durante la fase di consolidamento del motore economico reale, il modulo Finanze ha completato la transizione da semplice popup della Home a vero e proprio Centro Controllo Economico.

---

## NUOVA DIREZIONE UI

La gestione Finanze non vive più come semplice finestra modale.

Diventa una schermata dedicata, mantenendo però tutta la filosofia originaria del modulo.

Decisione ufficiale:

👉 la UI deve facilitare la lettura della situazione economica reale della famiglia.

---

## CENTRO CONTROLLO ECONOMICO

La schermata Finanze assume ufficialmente il ruolo di:

✔ lettura dei conti reali

✔ lettura delle ricorrenze

✔ lettura della pressione temporale

✔ lettura dei fondi

✔ simulazione economica futura

senza trasformarsi in un home banking.

---

## DISTINZIONE SALDO / PREVISIONE

Viene consolidata e verificata la regola fondamentale del modulo.

### Saldo reale

Rappresenta esclusivamente il denaro realmente disponibile.

Non deve essere influenzato dalle ricorrenze non ancora confermate.

---

### Pressione futura

Rappresenta la previsione economica della famiglia.

Può considerare:

* ricorrenze
* stipendi previsti
* fondi
* simulazioni

senza modificare il saldo reale.

---

## CONFERMA MANUALE

Le ricorrenze continuano ad essere considerate:

👉 previsione.

Solo la conferma manuale dell'utente trasforma una previsione in evento economico reale.

Regole consolidate:

✔ ricorrenza creata → saldo invariato

✔ conferma ricorrenza → saldo aggiornato

✔ annullamento conferma → saldo ripristinato

---

## COERENZA CONTI REALI

Decisione strutturale ufficiale:

Home e schermate dettaglio devono leggere lo stesso insieme di conti attivi.

I conti disattivati o eliminati NON devono contribuire ai saldi aggregati.

---

## COLLAUDO VITA REALE

Il motore è stato verificato con test pratici.

Scenario testato:

* creazione uscita di prova
* conferma manuale
* aggiornamento saldo
* eliminazione conferma
* ripristino saldo

Esito:

✔ comportamento corretto.

---

## NUOVA FASE OPERATIVA

Il modulo Finanze entra ufficialmente nella fase:

### H3.5 — Consolidamento Vita Reale

Obiettivo:

verificare che il comportamento del sistema coincida con il comportamento della vita reale prima di espandere ulteriormente il motore economico.

---

# CONSOLIDAMENTO MODULO SPESE REALE — GIUGNO 2026

Durante la fase H3.5 di Consolidamento Vita Reale viene completata la prima implementazione operativa del modulo Spese.

Questa fase conferma e rafforza il principio strutturale fondamentale:

## PREVISIONE ≠ REALTÀ

Il modulo Finanze continua a rappresentare:

✔ simulazione futura
✔ pressione economica
✔ sostenibilità familiare
✔ resilienza economica

Il modulo Spese rappresenta invece:

✔ denaro realmente mosso
✔ eventi economici realmente avvenuti
✔ memoria economica storica della famiglia.

---

## NUOVA DISTINZIONE CONSOLIDATA

### FINANZE

Risponde alla domanda:

👉 "Dove stiamo andando?"

Lavora su:

* ricorrenze;
* simulazioni;
* pressione futura;
* scenari economici.

### SPESE

Risponde alla domanda:

👉 "Che cosa è successo davvero?"

Lavora su:

* spese reali;
* prelievi contanti;
* entrate extra;
* cronologia economica vissuta.

---

## INTEGRAZIONE TRA I MODULI

Il modulo Spese non sostituisce Finanze e Finanze non sostituisce Spese.

I due sistemi evolvono separatamente e comunicano attraverso dati reali.

Regola consolidata:

* Finanze NON crea movimenti reali.
* Spese NON modifica simulazioni future.

---

## NUOVA FONTE DI VERITÀ ECONOMICA

Con il completamento del CRUD dei movimenti reali, il modulo Spese diventa la sorgente ufficiale dei dati economici storici.

Ogni movimento reale può essere:

✔ creato;
✔ modificato;
✔ eliminato;
✔ registrato con data e ora effettive.

La cronologia economica viene costruita utilizzando il momento reale dell'evento e non quello dell'inserimento.

---

## DIREZIONE FUTURA

Il consolidamento del modulo Spese autorizza la futura costruzione del collegamento:

**Spese → Statistiche Economiche**

senza rompere la separazione strutturale tra:

* memoria del passato;
* simulazione del futuro.

Principio confermato:

👉 una sola verità economica reale, molte letture e interpretazioni del sistema.

---

# 🌍 EVOLUZIONE STRUTTURALE FUTURA — FAMIGLIE, CLOUD E PERMESSI

## PRINCIPIO

Il modulo Finanze dovrà evolvere da:

👉 finanze della famiglia attuale

verso:

👉 motore economico universale per qualsiasi famiglia.

---

## MULTI FAMIGLIA

Ogni famiglia deve possedere:

- propri conti
- propri fondi
- proprie ricorrenze
- proprie simulazioni
- propria pressione economica

senza alcuna condivisione automatica con altre famiglie.

---

## CLOUD

Le finanze devono poter essere utilizzate contemporaneamente da:

- PC
- telefono
- tablet

leggendo sempre gli stessi dati.

Il cloud rappresenta la futura sorgente unica di verità.

---

## RUOLI E PERMESSI

Non tutti i membri della famiglia devono avere gli stessi poteri.

Esempio:

### Amministratore

Può:

✔ creare conti
✔ eliminare conti
✔ modificare struttura economica
✔ gestire accessi

### Membro Adulto

Può:

✔ aggiungere spese
✔ aggiungere entrate
✔ utilizzare i moduli economici autorizzati

ma NON può:

❌ eliminare conti
❌ modificare struttura economica
❌ modificare permessi famiglia

---

## ACCESSI ESTERNI FUTURI

Il sistema dovrà permettere accessi limitati a persone esterne.

Esempi:

- commercialista
- consulente
- familiare delegato

tramite autorizzazioni specifiche.

---

## PRINCIPIO COLLABORATIVO

La modifica strutturale dei dati economici deve restare protetta.

Le attività quotidiane devono invece poter essere condivise tra i membri autorizzati della famiglia.

---

## NOTA

Questa evoluzione NON modifica le priorità attuali.

Priorità attuale:

✔ consolidamento H3.5 vita reale
✔ test del motore economico reale
✔ stabilizzazione modulo Spese

La trasformazione cloud e multi-famiglia verrà affrontata in una fase successiva.

---

# H4 — MOTORE DECISIONALE DEL PLANNER (GIUGNO 2026)

Con H4 il modulo Finanze introduce ufficialmente il primo motore decisionale.

Il Planner non produce più semplici suggerimenti statici.

Analizza le singole voci economiche e costruisce automaticamente scenari e raccomandazioni.

---

## NUOVA ARCHITETTURA

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

Observation

↓

UI

Ogni componente ha una responsabilità unica.

Questo permette di espandere il motore senza aumentare la complessità del codice.

---

## PLANNER DECISION ENGINE

Viene introdotto il concetto di decisione economica.

Ogni ricorrenza viene analizzata singolarmente.

Il risultato NON è più direttamente uno scenario.

Il risultato è una decisione motivata.

Esempi:

- pagare subito
- mantenere copertura
- attendere entrata
- rimandare
- usare fondi
- monitorare

---

## REGOLE DECISIONALI INTRODOTTE

Prima implementazione ufficiale delle regole del Planner.

### RID

Le spese con pagamento automatico (RID/addebiti automatici):

- non vengono proposte come rimandabili;
- non vengono proposte come spostabili;
- devono rimanere coperte.

---

### PRIORITÀ

Le spese critiche vengono sempre analizzate prima delle spese normali.

La priorità considera:

- obbligatorietà;
- priorità pagamento;
- livello di protezione.

---

### ENTRATE IMMINENTI

Il Planner valuta le entrate previste nei prossimi giorni.

Se un'entrata è sufficiente a riportare il sistema in equilibrio:

preferisce attendere l'entrata invece di suggerire immediatamente l'utilizzo dei fondi.

---

### SPESE RIMANDABILI

Solo le ricorrenze realmente flessibili possono essere suggerite come rimandabili.

Il Planner utilizza il comportamento economico della ricorrenza e non semplicemente la categoria.

---

## GENERAZIONE AUTOMATICA

Gli scenari non vengono più costruiti manualmente.

PlannerScenarioBuilder genera automaticamente:

- scenario consigliato;
- scenario alternativo;
- passi operativi.

PlannerRecommendationBuilder genera automaticamente:

- raccomandazioni;
- priorità;
- motivazioni.

---

## PRINCIPIO FONDAMENTALE

Il Planner non decide al posto dell'utente.

Il Planner:

- interpreta;
- confronta;
- spiega;
- suggerisce.

La decisione finale rimane sempre dell'utente.

---

## DIREZIONE FUTURA

L'architettura H4 è predisposta per l'introduzione progressiva di nuove regole decisionali.

Tra le evoluzioni previste:

- utilizzo intelligente dei fondi;
- protezione dei fondi dedicati;
- simulazioni multi-scenario;
- spiegazione completa delle decisioni;
- valutazione automatica dello scenario migliore;
- motore decisionale estensibile tramite regole indipendenti.

Decisione architetturale ufficiale:

Il Planner evolve da insieme di condizioni statiche a motore decisionale modulare.

---

# H2 — PRESSIONI A DURATA DEFINITA E TIPI ECONOMICI

Decisioni concettuali consolidate — Maggio/Giugno 2026

Questa sezione consolida due concetti strutturali emersi durante la popolazione reale del modulo Finanze.

Non rappresentano necessariamente funzionalità già implementate.

Rappresentano direzioni ufficiali da preservare nell’evoluzione futura del motore economico.

---

## PRESSIONI A DURATA DEFINITA

Alcune pressioni economiche non devono essere interpretate come semplici spese ricorrenti permanenti.

Esempi:

- mutui;
- finanziamenti;
- prestiti;
- cessioni del quinto;
- prestiti auto;
- rateizzazioni importanti.

Queste pressioni possiedono una caratteristica fondamentale:

👉 hanno una durata definita e, quando terminano, liberano capacità economica.

Il sistema dovrà poter considerare progressivamente:

- data di inizio;
- data di fine;
- tempo residuo;
- impatto economico periodico;
- capacità economica recuperata alla conclusione.

---

## TEMPO RESIDUO

Per una pressione a durata definita, la sola data finale non rappresenta necessariamente l'informazione più utile per la persona.

Il sistema dovrà privilegiare anche una lettura comprensibile del tempo residuo.

Esempio:

"Mancano 14 mesi alla fine del finanziamento."

può essere più significativo di una semplice data di scadenza.

Il tempo residuo permette di leggere la pressione come qualcosa che evolve nel tempo e non come una spesa permanente.

---

## CAPACITÀ ECONOMICA RECUPERATA

Quando una pressione a durata definita termina, il sistema familiare recupera capacità economica periodica.

Esempio:

Finanziamento:

280 €/mese

Fine prevista:

fra 14 mesi

Capacità economica recuperata alla fine:

+280 €/mese

Questa liberazione futura può influenzare:

- ossigeno economico;
- capacità di risparmio;
- ricostruzione dei fondi;
- resilienza;
- sostenibilità futura;
- direzione del sistema.

---

## CASO SPECIALE — CESSIONE DEL QUINTO

La cessione del quinto non deve essere interpretata soltanto come una normale spesa.

Può essere letta concettualmente come:

Reddito potenziale
↓
Vincolo temporaneo
↓
Reddito disponibile reale

Quando il vincolo termina:

- aumenta il reddito disponibile;
- aumenta la capacità economica mensile;
- può aumentare l'ossigeno economico;
- aumenta la possibilità di ricostruire protezioni e resilienza.

---

# TIPI ECONOMICI

Durante la popolazione reale del modulo Finanze è emersa la necessità futura di distinguere:

TIPO ECONOMICO

da

RICORRENZA REALE

Principio:

👉 il Tipo Economico descrive COS'È un fenomeno economico.

👉 la Ricorrenza Reale descrive COME quel fenomeno esiste concretamente nella vita di una specifica famiglia.

---

## ESEMPI DI TIPI ECONOMICI

Entrate:

- Stipendio;
- Assegno Unico;
- Pensione;
- Rimborso 730;
- Bonus;
- Entrata straordinaria.

Uscite:

- Mutuo;
- Prestito;
- Cessione del Quinto;
- Assicurazione;
- Tassa;
- Utenza;
- Abbonamento.

Questi esempi non rappresentano voci economiche precompilate obbligatorie.

Restano valido il principio dell'inserimento manuale dell'utente e la configurabilità del sistema.

---

## TIPO ECONOMICO ≠ RICORRENZA REALE

Esempio concettuale:

Stipendio
+
Persona
+
Origine / rapporto economico
+
Conto
+
Parametri specifici

↓

Ricorrenza reale della famiglia

Il Tipo Economico fornisce significato e comportamento.

La Ricorrenza Reale rappresenta l'istanza concreta configurata dalla famiglia.

Questa distinzione potrà permettere in futuro:

- maggiore coerenza dei dati;
- statistiche più intelligenti;
- comportamenti economici riutilizzabili;
- cambio di lavoro o fornitore senza perdere il significato economico;
- distinzione tra categoria concettuale e singola voce reale;
- evoluzione multi-famiglia senza dipendere da nomi specifici.

---

## PRINCIPIO MULTI-FAMIGLIA

I Tipi Economici non devono dipendere dalla famiglia laboratorio attuale.

Il modello futuro deve poter funzionare allo stesso modo per qualsiasi famiglia.

Non:

"Stipendio Matteo - Panna" come tipo universale.

Ma:

Tipo Economico: Stipendio

↓

istanza configurata dalla famiglia

↓

persona + origine + conto + parametri

La famiglia attuale rimane il caso reale di collaudo, non la struttura definitiva del modello.

---

## STATO DI IMPLEMENTAZIONE

Questi concetti sono decisioni architetturali e concettuali consolidate.

Non implicano che esistano già nel codice:

- un modello `PressioneDurataDefinita`;
- un archivio `TipoEconomico`;
- nuovi engine dedicati;
- nuove strutture persistenti.

Regola:

👉 non anticipare implementazioni finché l'architettura reale e la roadmap non richiederanno questi componenti.

La fonte di verità operativa resta sempre il codice reale del progetto.