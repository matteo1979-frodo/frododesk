# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 8 Aprile 2026

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
- collegamento iniziale con **linguaggio stato Alice**
- base per sistema visivo (emoji + colori)

---

## 🧠 ARCHITETTURA — 3 LIVELLI (FONDAMENTALE)

Il modulo ora segue questa separazione:

### 1️⃣ LOGICA
→ dove si trova Alice realmente

### 2️⃣ LINGUAGGIO
→ come il sistema descrive lo stato

### 3️⃣ VISUALE
→ emoji + colore (status_visual)

---

## 🔧 IMPLEMENTAZIONE ATTUALE (LINGUAGGIO BASE)

```dart
final isAliceSick = alicePeriodNow?.type == AliceEventType.sickness;

// ⚠️ TEMPORANEO (placeholder)
final isSchoolNow = aliceIsOutNow;

final aliceNowLabel = aliceIsOutNow
    ? (isSchoolNow ? "fuori • scuola" : "fuori")
    : (isAliceSick ? "a casa • malata" : "a casa");
    ## ⚠️ LIMITAZIONE ATTUALE

- `isSchoolNow` NON è reale  
- NON legge gli eventi Alice  
- è solo un placeholder tecnico per evitare blocchi  

👉 il sistema è pronto, ma non ancora collegato ai dati reali  

---

## 🎯 OBIETTIVO PROSSIMO STEP

Collegare Alice agli eventi reali già presenti nel sistema:

- scuola  
- centro estivo  
- gite  
- danza / attività  
- visite  

---

## 🚀 RISULTATO ATTESO

Alice deve generare automaticamente:

- "fuori • scuola"  
- "fuori • centro estivo"  
- "fuori • danza"  
- "fuori • gita"  
- "fuori • visita"  
- "a casa • malata"  
- "a casa"  

👉 senza modificare la UI  

---

## 🔒 REGOLA FONDAMENTALE

- NON modificare la UI  
- NON toccare `status_visual`  
- modificare SOLO il linguaggio (`aliceNowLabel`)  

---

## 🧠 LOGICA SCUOLA DINAMICA

Gli orari scuola NON sono più fissi.

### 📍 ENTRATA
- orario reale (es: 08:25)  
- buffer: -20 minuti  

👉 fascia reale:  
08:05 – 08:25  

---

### 📍 USCITA
- orario reale (es: 16:25)  
- buffer: +20 minuti  

👉 fascia reale:  
16:25 – 16:45  

---

### 📍 USCITA ANTICIPATA

Se attiva:

👉 sostituisce completamente l’uscita scuola  

Usata da:
- UI  
- CoverageEngine  
- Sandra  
- buchi reali  

---

## 🍽️ PRANZO — LOGICA DINAMICA

Prima:  
❌ fisso 13:00–14:30  

Ora:

👉 dinamico  

- start = uscita anticipata (se presente)  
- fallback = 13:00  

---

## 👶 SANDRA — ALLINEAMENTO

Sandra NON usa più orari fissi.

👉 legge:

- uscita anticipata  
- fasce reali  
- CoverageEngine  

---

## ⚠️ PRINCIPIO SISTEMA

TUTTO usa la stessa fonte:

- UI  
- CoverageEngine  
- decisioni  
- Sandra  

👉 nessun valore duplicato  

---

## 🔥 LOGICA EVENTI REALI

Un evento Alice genera:

### 1️⃣ DURANTE EVENTO
- Alice NON è a casa  

---

### 2️⃣ PRIMA EVENTO
→ verifica accompagnamento  

---

### 3️⃣ DOPO EVENTO
→ verifica ritiro  

---

### 4️⃣ REGOLA

👉 il sistema NON inventa buchi  
👉 valuta sempre:

- turni  
- eventi  
- malattia  
- ferie  
- supporto  

---

## 🧩 MODELLO EVENTO

Campi:

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

### ✔ COMPLETATO

- model ✔  
- store ✔  
- CoreStore ✔  
- editor ✔  
- multi-evento ✔  
- persistenza ✔  
- conflitti ✔  
- UI eventi ✔  

---

### 🔥 COMPLETATO RECENTE

- orari scuola dinamici ✔  
- uscita anticipata ✔  
- pranzo dinamico ✔  
- Sandra dinamica ✔  
- base linguaggio Alice ✔  

---

## 🚧 NON ANCORA FATTO

### LOGICA
⬜ collegamento eventi → stato Alice (**PRIORITÀ**)  

### UI
⬜ rifinitura  

### SISTEMA
⬜ conflitti forti turni/eventi  
⬜ suggerimenti automatici  
⬜ IPS completo  

---

## 🚀 FUTURO

- Alice al seguito  
- suggerimenti intelligenti  
- eventi ricorrenti  
- statistiche  

---

## 🎯 STATO MODULO

🟡 IN COSTRUZIONE (fase avanzata)

- sistema reale ✔  
- linguaggio base ✔  
- collegamento eventi ❌ (prossimo step)  