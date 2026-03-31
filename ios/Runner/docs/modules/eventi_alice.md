# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 31 Marzo 2026

## IDENTITÀ DEL MODULO

Questo modulo gestisce gli **Eventi Alice reali/speciali**, cioè gli eventi della vita reale di Alice che possono influenzare la giornata, la copertura e le decisioni familiari.

---

## 🔥 AGGIORNAMENTO STRUTTURALE — INTEGRAZIONE MOTORE

Gli Eventi Alice NON sono più solo informativi.

👉 Sono diventati elementi attivi del motore decisionale.

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

## RISULTATO RAGGIUNTO

Il sistema ora:

✔ genera buchi SOLO se necessari  
✔ elimina falsi positivi  
✔ simula la realtà logistica reale  

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

## STATO REALE ATTUALE

### FATTO

✔ model  
✔ store  
✔ integrazione CoreStore  
✔ editor base  
✔ salvataggio evento  
✔ visualizzazione  
✔ integrazione con CoverageEngine  
✔ logica accompagnamento  
✔ logica ritiro  
✔ eliminazione falsi buchi  
✔ disponibilità reale persone (turni + eventi reali)  
✔ simmetria completa Matteo / Chiara  
✔ fasce spezzate reali per accompagnamento / ritiro  
✔ multi-evento nello stesso giorno  
✔ persistenza eventi (salvataggio stabile)  
✔ modifica evento  
✔ eliminazione evento  
✔ orari evento configurabili  

---

### NON ANCORA FATTO

#### UI / UX
- lista compatta (no lista infinita)  
- gestione “+N altri eventi”  
- ordinamento per orario  
- distinzione visiva attivo / disattivato  
- evento “tutto il giorno”  

#### LOGICA
- gestione conflitti tra eventi (sovrapposizione)  
- evento → influenza copertura in modo esplicito UI  
- evento → interazione completa con scuola / centro estivo  
- evento → conflitto reale con turni genitori (segnalazione forte)  

#### PRO
- Alice al seguito  
- suggerimenti automatici nei buchi  
- integrazione IPS  
- eventi ricorrenti  

---

## PROSSIMO STEP

👉 UI intelligente eventi Alice:

- lista compatta  
- espansione eventi  
- “+N altri”  
- struttura non infinita  

---

## FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — UI eventi Alice (lista compatta + gestione multi-evento avanzata).