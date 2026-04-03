# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 2 Aprile 2026

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

## 🧠 NUOVA LOGICA STRUTTURALE (SCUOLA DINAMICA)

Gli orari scuola NON sono più fissi.

Sono ora basati su logica reale con buffer.

---

### 📍 ENTRATA SCUOLA

- orario reale (es: 08:25)
- buffer: -20 minuti

👉 fascia reale:
08:05 – 08:25

---

### 📍 USCITA SCUOLA

- orario reale (es: 16:25)
- buffer: +20 minuti

👉 fascia reale:
16:25 – 16:45

---

### 📍 USCITA ANTICIPATA

Se attiva:

👉 sostituisce completamente l’uscita scuola

Viene utilizzata da:

- UI
- decisione scuola
- CoverageEngine
- buchi reali
- Sandra

---

## 🍽️ PRANZO — LOGICA REALE

Prima:
❌ fisso 13:00–14:30

Ora:

👉 dinamico

- start = uscita anticipata (se presente)
- fallback = 13:00

👉 esempio:
- uscita 13:00 → pranzo 13:00–14:30
- uscita 13:30 → pranzo 13:30–14:30

---

## 👶 SANDRA — ALLINEAMENTO

Sandra NON usa più orari fissi.

👉 legge:

- uscita anticipata
- fallback su fascia standard

---

## ⚠️ PRINCIPIO FONDAMENTALE

TUTTI i livelli devono usare la stessa fonte:

- UI
- CoverageEngine
- decisioni
- Sandra

👉 nessun valore duplicato hardcoded

---

## NUOVA LOGICA INTRODOTTA

Un Evento Alice con orario genera:

### 1️⃣ DURANTE EVENTO
- Alice NON è a casa
- nessun bisogno di copertura casa

---

### 2️⃣ PRIMA EVENTO (ACCOMPAGNAMENTO)

Il sistema verifica:

👉 chi accompagna Alice

Se nessuno è disponibile:

👉 buco reale

---

### 3️⃣ DOPO EVENTO (RITIRO)

Il sistema verifica:

👉 chi è disponibile

Se nessuno:

👉 buco reale

---

### 4️⃣ REGOLA FONDAMENTALE

👉 nessun buco automatico

Il sistema valuta sempre:

- turni
- eventi
- malattia
- ferie
- supporto

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
✔ CoreStore integration  
✔ editor eventi  
✔ multi-evento  
✔ persistenza  
✔ modifica/eliminazione  

✔ conflitti eventi  
✔ UI conflitti  
✔ popup +N eventi  

✔ gestione date  
✔ eventi cross-day  

✔ periodi Alice  
✔ orari dinamici scuola 🔥  
✔ uscita anticipata integrata 🔥  
✔ buffer 20 min entrata/uscita 🔥  
✔ pranzo dinamico 🔥  
✔ Sandra dinamica 🔥  

---

## 🔥 INTEGRAZIONE REALE

✔ Eventi Alice influenzano:

- copertura
- presenza
- decisione scuola
- uscita anticipata
- buchi

✔ sistema reale verificato:

- buco solo se nessuno disponibile
- rete supporto funzionante
- comportamento coerente con uscita variabile

---

## 🔧 STRUTTURA UI

### Eventi Alice del giorno
- lista dinamica
- conflitti visivi
- azioni rapide

---

### Periodi Alice
- scuola
- vacanza
- malattia
- centro estivo

---

## ⚠️ ARCHITETTURA

Sistema volutamente doppio:

- eventi giornalieri
- periodi

👉 NON unificare ora

---

## 🚧 NON ANCORA FATTO

### UI
⬜ pulizia finale

### STRUTTURA
⬜ unificazione eventi/periodi

### LOGICA
⬜ conflitti forti con turni
⬜ suggerimenti automatici
⬜ integrazione IPS completa

---

## 🚀 PRO FUTURI

⬜ Alice al seguito  
⬜ suggerimenti intelligenti  
⬜ eventi ricorrenti  
⬜ statistiche  

---

## 🎯 STATO

✔ COMPLETATO  
✔ STABILE  
✔ USABILE NELLA VITA REALE  

---

## FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — allineamento spiegazione buchi con orari dinamici reali