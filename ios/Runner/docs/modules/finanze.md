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