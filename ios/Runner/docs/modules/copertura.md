# FRODODESK — MODULO COPERTURA

Ultimo aggiornamento: 5 Aprile 2026

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

## 2. ALICE A CASA

Se Alice è a casa:

👉 serve almeno un adulto presente

Se nessuno è presente:

👉 BUCO reale

---

## 3. EVENTI DI ALICE

Gli eventi influenzano la copertura:

- Alice fuori casa → nessun buco in quella fascia
- Alice a casa → serve copertura

---

# MOTORE PRINCIPALE

File principale:

👉 `coverage_engine.dart`

Il motore:

- legge turni
- legge eventi
- legge stati (ferie, malattia)
- calcola presenza reale
- calcola buchi

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

---

# OUTPUT DEL MOTORE

- ✔ Copertura OK
- ✔ Buchi del giorno
- ✔ Fasce scoperte
- ✔ Stato Sandra (serve/non serve)

---

# LOGICA BUCHI

Un buco esiste quando:

👉 Alice è a casa  
👉 e NON c’è copertura reale

---

# COPERTURA COMBINATA

Il sistema combina:

- Matteo
- Chiara
- Supporto

👉 anche su segmenti diversi della stessa fascia

---

# 🆕 STRATO DECISIONALE — AZIONI CONSIGLIATE

## IDENTITÀ

Questo strato traduce i buchi in:

👉 **azioni concrete per l’utente**

NON modifica il motore  
👉 ma interpreta il risultato

---

## INPUT

👉 `cov.gapDetails`

Ogni gap contiene:

- fascia oraria reale (es. 21:00–22:35)
- descrizione problema

---

## LOGICA

Per ogni gap:

### 1. Parsing orario
Estrazione da label:

21:00–22:35 → start / end

---

### 2. Conversione
Orari → minuti:

- startMin
- endMin

---

### 3. Lettura turni reali

- Matteo
- Chiara

---

### 4. Valutazione copertura

#### ✔ Copertura piena
Una persona copre tutta la fascia

#### ⚠️ Copertura combinata (staffetta)
Due persone coprono insieme:

- uno copre inizio
- uno copre fine

#### ❌ Buco reale
Nessuno copre completamente

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

Sistema attivo:

👉 ogni gap genera un blocco UI

- Problema 1
- Problema 2
- …

---

## UI

- lista problemi
- numerazione
- conteggio totale
- suggerimento sotto ogni problema

---

# GESTIONE NOTTE / POST-NOTTE

👉 riposo fino alle 14:30

---

# GESTIONE EVENTI TEMPORANEI

👉 blocchi di indisponibilità

---

# GESTIONE CENTRO ESTIVO

- prima → casa
- durante → fuori
- dopo → casa

---

# USCITA ANTICIPATA — DISTINZIONE FONDAMENTALE

👉 copertura logistica ≠ copertura casa

---

# STATO ATTUALE DEL MODULO

✔ motore stabile  
✔ decisioni attive  
✔ multi-problema attivo  
✔ copertura combinata reale  

---

# PROSSIMO STEP

👉 mostrare anche:

- descrizione completa del buco sotto ogni problema

(es. “Alice a casa da sola 21:00–22:35”)

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — modulo Copertura con sistema decisionale multi-problema attivo. Prossimo passo: mostrare il dettaglio completo del buco sotto ogni problema.