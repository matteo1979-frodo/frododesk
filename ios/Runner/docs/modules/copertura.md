# FRODODESK — MODULO COPERTURA

Ultimo aggiornamento: 28 Aprile 2026

---

# IDENTITÀ DEL MODULO

Questo modulo gestisce la **copertura reale della giornata di Alice**.

Obiettivo:

- capire se Alice è coperta o no
- individuare i buchi reali
- supportare decisioni operative

👉 Questo è il cuore decisionale di FrodoDesk

---

# PRINCIPIO FONDAMENTALE

La copertura NON è:

❌ teoria  
❌ calendario  
❌ presenza generica  

👉 È simulazione reale della giornata

---

# CONCETTI BASE

## 1. PRESENZA ≠ LOGISTICA

Distinzione fondamentale:

- **Presenza in casa**
- **Logistica esterna**

Esempio:

- adulto malato a letto:
  - ✔ presenza → sì
  - ❌ logistica → no

---

## 2. REGOLA MADRE — ALICE A CASA

👉 Questa è la regola più importante del sistema.

Alice è considerata **A CASA** quando NON è:

- a scuola
- in evento valido (danza, pallavolo, centro estivo, gita, ecc.)
- fuori casa per attività tracciata

---

## 3. REGOLA COPERTURA

Se Alice è a casa:

👉 deve essere SEMPRE coperta da almeno uno tra:

- Matteo
- Chiara
- Sandra (solo se attiva nella fascia)
- Rete di supporto

Se nessuno copre:

👉 ❌ BUCO REALE (sempre)

---

## 4. EVENTI DI ALICE

Gli eventi influenzano la copertura:

- Alice fuori casa → ✔ coperta automaticamente
- Alice a casa → serve copertura reale

---

# MOTORE PRINCIPALE

File principale:

👉 `coverage_engine.dart`

Il motore:

- legge turni
- legge eventi reali
- legge eventi Alice
- legge stati (ferie, malattia)
- legge supporto
- calcola presenza reale
- calcola buchi su tutta la giornata

---

# INPUT DEL MOTORE

- TurnEngine
- RealEventStore
- AliceEventStore
- AliceSpecialEventStore
- DiseasePeriodStore
- FeriePeriodStore
- SupportNetworkStore
- DaySettingsStore
- SchoolStore

---

# OUTPUT DEL MOTORE

- ✔ Copertura OK
- ✔ Buchi del giorno REALI
- ✔ Fasce scoperte reali
- ✔ Stato Sandra (informativo, non vincolante)

---

# LOGICA BUCHI (AGGIORNATA)

Un buco esiste quando:

👉 Alice è a casa  
👉 e NON c’è copertura reale

✔ controllo su tutta la giornata (00:00–23:59)  
❌ NON limitato a fasce Sandra  
❌ NON limitato a scuola  

---

# COPERTURA COMBINATA

Il sistema combina:

- Matteo
- Chiara
- Supporto

👉 anche su segmenti diversi della stessa fascia

---

# USCITA IMPRESCINDIBILE (REGOLA)

👉 NON elimina il problema  
👉 NON nasconde il buco  

Significa:

- la persona è fuori comunque
- il sistema deve calcolare il buco reale
- il rischio resta visibile

---

# 🆕 STRATO DECISIONALE — AZIONI CONSIGLIATE

## IDENTITÀ

Questo strato traduce i buchi in:

👉 **azioni concrete per l’utente**

NON modifica il motore  
👉 interpreta il risultato

---

## INPUT

👉 `cov.gapDetails`

Ogni gap contiene:

- fascia oraria reale (es. 21:00–23:30)
- descrizione problema

---

## LOGICA

Per ogni gap:

### 1. Parsing orario
21:00–23:30 → start / end

### 2. Conversione
Orari → minuti

### 3. Lettura copertura reale

### 4. Valutazione

✔ Copertura piena  
⚠️ Copertura combinata  
❌ Buco reale  

---

## OUTPUT

Per ogni problema:

- suggerimento automatico
- classificazione:

✔ Copertura presente  
⚠️ Copertura combinata  
❌ Azione necessaria  

---

## MULTI-PROBLEMA

👉 ogni buco genera un blocco UI

- Problema 1
- Problema 2
- …

---

## UI

- lista problemi
- numerazione
- conteggio totale
- suggerimento per ogni problema

---

# GESTIONE NOTTE / POST-NOTTE

👉 riposo fino alle 14:30

---

# GESTIONE EVENTI

👉 gli eventi sono blocchi reali di indisponibilità  
👉 influenzano direttamente la copertura

---

# GESTIONE CENTRO ESTIVO

- prima → casa
- durante → fuori
- dopo → casa

---

# STATO ATTUALE DEL MODULO

✔ motore copertura REALE  
✔ Alice a casa gestita correttamente  
✔ buchi reali su tutta la giornata  
✔ eventi reali integrati  
✔ supporto integrato  
✔ Home coerente con motore  

⚠️ IPS NON ancora coerente (parziale)

---

# PROSSIMO STEP

👉 allineare IPS al motore reale

(obiettivo: IPS basato su buchi veri, non su simulazioni)

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — Copertura reale completata. Prossimo passo: IPS basato su dati reali.