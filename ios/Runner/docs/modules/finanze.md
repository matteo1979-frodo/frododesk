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