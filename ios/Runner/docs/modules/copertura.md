# FRODODESK — MODULO COPERTURA

Ultimo aggiornamento: 30 Marzo 2026

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

⚠️ Questo è il punto chiave per il nuovo modulo Eventi Alice

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

Il motore utilizza:

- TurnEngine (turni)
- RealEventStore (eventi adulti)
- AliceEventStore (periodi base Alice)
- AliceSpecialEventStore (eventi reali Alice)
- DiseasePeriodStore
- FeriePeriodStore
- SupportNetworkStore
- DaySettingsStore

---

# OUTPUT DEL MOTORE

Il sistema produce:

- ✔ Copertura OK
- ✔ Buchi del giorno
- ✔ Fasce scoperte
- ✔ Stato Sandra (serve/non serve)

---

# LOGICA BUCHI

Un buco esiste quando:

👉 Alice è a casa  
👉 e NON c’è copertura reale

Il sistema restituisce:

- fascia oraria
- causa
- contesto

---

# COPERTURA COMBINATA

Il sistema combina:

- Matteo
- Chiara
- Supporto

👉 anche nei segmenti intermedi

Questo è stato verificato come corretto.

---

# GESTIONE NOTTE / POST-NOTTE

Regola consolidata:

👉 dopo turno notte → indisponibilità fino alle 14:30

Il sistema considera:

- coda notte
- post-notte
- nuova notte

---

# GESTIONE EVENTI TEMPORANEI

Eventi come:

- visite
- appuntamenti

vengono letti come:

👉 blocchi temporanei di indisponibilità

---

# GESTIONE CENTRO ESTIVO

Logica consolidata:

- prima → Alice a casa
- durante → Alice fuori
- dopo → Alice a casa

Centro estivo NON copre tutto il giorno.

---

# STATO ATTUALE DEL MODULO

✔ stabile  
✔ verificato in app reale  
✔ coerente con i casi testati  
✔ combinazione adulti corretta  

👉 considerato affidabile

---

# COLLEGAMENTO CON EVENTI ALICE

STATO ATTUALE:

- eventi Alice esistono
- sono visibili in UI
- NON influenzano ancora la copertura

---

# PROSSIMO PASSO UFFICIALE

👉 collegare:

Eventi Alice → CoverageEngine

Obiettivo:

- modificare presenza Alice nelle fasce evento
- influenzare i buchi
- generare decisioni reali

---

# SIGNIFICATO DEL PASSO

Quando questo sarà fatto:

👉 FrodoDesk smette di essere calendario  
👉 e diventa sistema decisionale

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — modulo Copertura stabile e verificato. Prossimo passo: collegare Eventi Alice al CoverageEngine per influenzare i buchi reali della giornata.