# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 1 Aprile 2026

## IDENTITÀ DEL MODULO

Questo modulo gestisce gli **Eventi Alice reali/speciali**, cioè gli eventi della vita reale di Alice che possono influenzare la giornata, la copertura e le decisioni familiari.

---

## 🔥 STATO ATTUALE — EVOLUZIONE MODULO

Gli Eventi Alice NON sono più solo informativi.

👉 Sono diventati entità reali, persistenti e modificabili  
👉 Supportano conflitti, azioni e spostamenti nel tempo  

👉 🔥 NUOVO:
- influenzano già la logica reale di copertura (buchi / presenza)
- integrati con decisione scuola e uscita anticipata

---

## NUOVA LOGICA INTRODOTTA

Un Evento Alice con orario genera:

### 1️⃣ DURANTE EVENTO
- Alice NON è a casa
- nessun bisogno di copertura casa

---

### 2️⃣ PRIMA EVENTO (ACCOMPAGNAMENTO)

Il sistema deve verificare:

👉 chi accompagna Alice

Se nessuno è disponibile:

👉 viene generato un buco reale

---

### 3️⃣ DOPO EVENTO (RITIRO)

Il sistema verifica:

👉 chi è disponibile a prendere Alice

- se qualcuno è disponibile → nessun buco
- se nessuno è disponibile → buco reale

---

### 4️⃣ REGOLA FONDAMENTALE

👉 NON si generano buchi automatici

Il sistema deve sempre verificare:

- disponibilità reale persone
- turni
- eventi
- stato (malattia, ferie, ecc.)

---

## MODELLO EVENTO ALICE

Campi ufficiali:

- `id`
- `label`
- `category`
- `date`
- `start`
- `end`
- `note`
- `enabled`

---

## 🧠 STATO REALE ATTUALE

### FATTO

✔ model  
✔ store  
✔ integrazione CoreStore  
✔ editor base  
✔ salvataggio evento  
✔ visualizzazione  
✔ multi-evento nello stesso giorno  
✔ persistenza eventi stabile  
✔ modifica evento  
✔ eliminazione evento  
✔ orari evento configurabili  

✔ rilevazione conflitti tra eventi  
✔ evidenziazione conflitti  
✔ popup +N eventi  

✔ gestione DATA evento  
✔ spostamento eventi tra giorni  
✔ store cross-day  

---

## 🔥 NUOVO (1 Aprile — STRADA A QUASI COMPLETA)

### PERIODI ALICE (AliceEventPanel)

✔ gestione completa periodi:
- scuola normale
- vacanza
- malattia
- chiusura scuola
- centro estivo

✔ popup editor (stile eventi del giorno)

✔ aggiunto bottone ANNULLA → reset editor

✔ orari dinamici per evento:

- ✔ Centro estivo → ingresso/uscita configurabili  
- ✔ Scuola normale → ingresso/uscita configurabili 🔥 NUOVO  
- ✔ Vacanza → nessun orario  
- ✔ Malattia → nessun orario  
- ✔ Chiusura scuola → nessun orario  

✔ UI dinamica corretta:
- mostra orari SOLO se servono
- label cambia automaticamente:
  - "Orari scuola"
  - "Orari centro estivo"

---

## 🔥 INTEGRAZIONE REALE GIÀ ATTIVA

✔ Eventi Alice influenzano già:

- copertura giornata
- presenza Alice in casa
- decisione scuola
- uscita anticipata
- buchi reali

✔ gestione reale verificata:
- se nessuno disponibile → BUCO
- possibilità uso rete supporto
- comportamento corretto con uscita 13:00

---

## 🔧 STRUTTURA UI ATTUALE

### 1️⃣ Eventi Alice del giorno (NUOVO)
- UI moderna
- eventi cliccabili
- conflitti visivi
- azioni rapide

---

### 2️⃣ Periodi Alice (STABILE)

👉 AliceEventPanel

Funzionalità:
- creazione
- modifica
- eliminazione
- gestione orari dinamici
- popup editor
- reset stato

---

## ⚠️ STATO ARCHITETTURALE

👉 sistema DUPLICATO (voluto)

- sopra → eventi giornalieri
- sotto → periodi

---

## 🎯 STRATEGIA CONFERMATA

NON unificare subito

---

## 🚧 NON ANCORA FATTO

### STRADA A (quasi completa)

☑ editor popup  
☑ orari dinamici  
☑ annulla/reset  
⬜ pulizia UI finale  

---

### STRADA B (NON INIZIATA)

⬜ unificazione completa eventi + periodi  
⬜ eliminazione AliceEventPanel  
⬜ tutto dentro _cardScuola  

---

### LOGICA AVANZATA

⬜ eventi → segnalazione forte conflitto con turni  
⬜ eventi → suggerimenti automatici  
⬜ eventi → integrazione completa IPS  

---

### PRO FUTURI

⬜ Alice al seguito  
⬜ suggerimenti intelligenti  
⬜ eventi ricorrenti  
⬜ storico/statistiche  

---

## 🔥 STEP STRATEGICO FUTURO

👉 TEST REALI SISTEMA

Obiettivo:

Verificare:

- eventi → copertura
- eventi → decisione scuola
- eventi → buchi reali
- eventi → rete supporto

---

## PROSSIMO STEP

👉 TEST GUIDATI

(simulazione casi reali per trovare bug)

---

## FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — test collegamento Eventi Alice → copertura reale