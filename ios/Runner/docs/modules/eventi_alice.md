# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 9 Aprile 2026

---

## IDENTITÀ DEL MODULO

Questo modulo gestisce gli **Eventi Alice reali/speciali**, cioè gli eventi della vita reale di Alice che possono influenzare:

- la presenza reale
- la copertura
- le decisioni familiari
- il linguaggio del sistema

---

## 🔥 STATO ATTUALE — EVOLUZIONE MODULO

Gli Eventi Alice NON sono più solo informativi.

👉 Sono entità:
- persistenti
- modificabili
- con impatto reale sul sistema

👉 🔥 NUOVO (APRILE 2026):
- collegamento reale con **linguaggio stato Alice**
- collegamento reale con **copertura**
- base per sistema visivo (emoji + colori)
- etichette umane collegate al nome reale evento

---

## 🧠 ARCHITETTURA — 3 LIVELLI (FONDAMENTALE)

### 1️⃣ LOGICA  
→ dove si trova Alice realmente  

### 2️⃣ LINGUAGGIO  
→ come il sistema descrive lo stato  

### 3️⃣ VISUALE  
→ emoji + colore (status_visual)

---

## 🔧 IMPLEMENTAZIONE ATTUALE (LINGUAGGIO REALE)

Il placeholder è stato eliminato.

Ora il linguaggio legge realmente:

- stato periodo Alice  
- eventi Alice temporizzati  
- eventi reali Alice  
- categorie evento  
- fallback testuale  

---

## 🎯 RISULTATO RAGGIUNTO

Alice genera automaticamente:

- "fuori • scuola"
- "fuori • centro estivo"
- "fuori • sport"
- "fuori • attività"
- "fuori • visita"
- "fuori • gita"
- "a casa • malata"
- "a casa"

👉 senza modificare UI  
👉 senza toccare status_visual  

---

## 🔒 REGOLA FONDAMENTALE

- NON modificare UI  
- NON toccare status_visual  
- il linguaggio nasce SOLO dalla logica reale  

---

## 🧠 LOGICA STATO CASA — AGGIORNAMENTO STRUTTURALE

🔥 **NUOVA REGOLA STABILE INTRODOTTA**

La gestione di "Alice a casa" ora segue una gerarchia precisa.

---

### 1️⃣ STATO GIORNO DOMINANTE

Se il giorno è:

- vacation  
- sickness  
- schoolClosure  

👉 il sistema mostra:

- Alice a casa (Vacanza)  
- Alice a casa (Malata)  
- Alice a casa (Scuola chiusa)  

👉 PRIORITÀ MASSIMA  
👉 non viene mai trasformato in “dopo evento”

---

### 2️⃣ EVENTO TEMPORALE

Se esiste un evento reale:

👉 il sistema genera:

- Alice a casa dopo danza  
- Alice a casa dopo visita  
- Alice a casa dopo sport  

👉 SOLO fuori dall’intervallo evento  

---

### 3️⃣ FALLBACK SCUOLA

Se:

- giorno normale  
- nessun evento  

👉 il sistema genera:

Alice a casa dopo scuola  

---

## 🧠 PRINCIPIO CONSOLIDATO

👉 lo stato giorno NON deve schiacciare la realtà temporale  

MA  

👉 quando è dominante (vacanza / malattia / chiusura scuola)  
vince sempre  

---

## 🔥 LOGICA EVENTI ALICE → COPERTURA

Un evento Alice genera impatto reale:

1️⃣ DURANTE EVENTO → Alice fuori  
2️⃣ PRIMA EVENTO → accompagnamento  
3️⃣ DOPO EVENTO → ritiro  
4️⃣ DOPO → ritorno stato reale  

---

## ⏱️ BUFFER EVENTI

- 20 minuti prima  
- 20 minuti dopo  

---

## 🧠 PRINCIPIO REALTÀ

Evento ≠ genitore occupato tutto il tempo  

✔ accompagnamento → vincolo  
✔ evento → libero  
✔ ritiro → vincolo  

---

## 🧾 LINGUAGGIO UMANO

Prima:
- Ritiro Alice evento  

Ora:
- Ritiro Alice danza  
- Accompagnamento Alice danza  

---

## ⚠️ DECISIONE IMPORTANTE

NON unire automaticamente i buchi  

👉 ogni blocco può avere soluzione diversa  

---

## 🧠 SCOPERTA STRUTTURALE

👉 dopo scuola / evento  
Alice deve tornare a casa  

NON deve restare “fuori”  

---

## 🧩 MODELLO EVENTO

- id  
- label  
- category  
- date  
- start  
- end  
- note  
- enabled  

---

## 🧠 STATO REALE

✔ model  
✔ store  
✔ CoreStore  
✔ editor  
✔ multi-evento  
✔ persistenza  
✔ conflitti  
✔ UI  

---

## 🔥 COMPLETATO RECENTE

✔ linguaggio "Alice a casa dopo..."  
✔ separazione stato giorno vs evento  
✔ eliminazione ricorsione (bug critico risolto)  
✔ funzione pura per stato casa  

---

## 🚧 NON ANCORA FATTO

LOGICA  
⬜ scuola come evento reale  

LINGUAGGIO  
⬜ perfezionamento casi complessi  

SISTEMA  
⬜ conflitti forti  
⬜ suggerimenti  
⬜ IPS  

---

## 🎯 STATO MODULO

🟢 STABILE

✔ crash risolto  
✔ logica coerente  
✔ linguaggio realistico  

---

## 🚀 PROSSIMO STEP

👉 collegare completamente:

- eventi Alice  
- accompagnamento  
- ritiro  
- impatto reale su copertura  

---

## 🧱 NOTA ARCHITETTURALE

Questa modifica:

👉 separa definitivamente:

- logica  
- linguaggio  
- struttura  

👉 elimina dipendenze pericolose  
👉 rende il sistema scalabile