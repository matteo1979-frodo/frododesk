FRODODESK — ROADMAP

Ultimo aggiornamento: Aprile 2026

---

# OBIETTIVO GENERALE

FrodoDesk deve diventare un sistema di controllo familiare che simula la realtà della vita quotidiana per aiutare a prevenire problemi prima che accadano.

Lo sviluppo segue filosofia CNC:
un passo alla volta, blocchi stabili prima di passare al successivo.

---

# FASE ATTUALE

🔥 BLOCCO SCUOLA — INTEGRAZIONE REALE NEL SISTEMA

---

## SIGNIFICATO DELLA FASE

Il sistema entra in una nuova evoluzione:

👉 da costruzione strutturale della scuola  
👉 a **allineamento completo tra motore, stato Alice e UI**

---

# CRITERI DI MATURITÀ DEL CALENDARIO

✔ Persistenza dati completa  
✔ Eventi reali gestiti correttamente  
✔ Conflitti gravi rilevati  
✔ Visione futura reale  

👉 STATO: RAGGIUNTI

---

# BLOCCO A — FONDAMENTA SISTEMA

Stato: COMPLETATO

---

# BLOCCO B — SPIEGAZIONE REALTÀ

Stato: COMPLETATO

---

# BLOCCO C — EVENTI REALI

Stato: COMPLETATO (LOGICA)

✔ Eventi reali funzionanti  
✔ Conflitti funzionanti  
✔ Permessi operativi  
✔ Copertura integrata  

👉 Rimane solo rifinitura UI (non prioritaria ora)

---

# BLOCCO D — CALENDARIO REALE

Stato: COMPLETATO (USO REALE)

✔ Sistema utilizzabile nella vita reale  
✔ Motore stabile  
✔ Copertura affidabile  

---

# 🔥 BLOCCO E — SCUOLA

## Stato: QUASI COMPLETATO (STRUTTURA + MOTORE OK)

---

## COSA È STATO COMPLETATO

### STEP 1 — STRUTTURA DATI
✔ SchoolPeriod  
✔ SchoolWeekConfig  
✔ SchoolDayConfig

### STEP 2 — STORE
✔ SchoolStore

### STEP 3 — UI PERIODI
✔ creazione periodo  
✔ eliminazione periodo  
✔ visualizzazione periodo attivo  
✔ dettaglio periodo

### STEP 4 — UI SETTIMANA
✔ popup settimana  
✔ giorni letti dal periodo  
✔ stato ATTIVO / OFF  
✔ modifica attivo/off  
✔ modifica ingresso  
✔ modifica uscita reale  
✔ visualizzazione orari accanto ai giorni  
✔ salvataggio reale per lun–sab

### STEP 5 — MOTORE
✔ CoverageEngine legge SchoolStore  
✔ il giorno scuola viene deciso dal periodo attivo  
✔ il motore legge ingresso / uscita / rientro dal nuovo sistema

---

## LOGICA COMPLETA ATTUALE

Ordine corretto del sistema:

1. Eventi Alice
2. Eventi Alice temporanei
3. Periodo scuola attivo
4. Orario settimanale
5. Motore copertura

---

## OBIETTIVO DEL BLOCCO

👉 trasformare la scuola in:

✔ sistema stabile  
✔ automatico  
✔ coerente con la realtà  
✔ fonte unica di verità

---

## PROBLEMA ATTUALE RESIDUO

⚠️ NON è più un problema di struttura o motore

Il problema rimasto è:

👉 alcune parti UI leggono ancora la logica vecchia di Alice/scuola

Sintomi già verificati:
- compare ancora “Stato Alice: Scuola normale” quando non dovrebbe
- compare ancora “Alice fuori · scuola” anche quando il nuovo sistema dice altro
- incongruenza tra box scuola e stato reale Alice

---

## STEP OPERATIVI AGGIORNATI

### STEP E1 — STRUTTURA SCUOLA
✔ COMPLETATO

### STEP E2 — PERIODI SCUOLA
✔ COMPLETATO

### STEP E3 — SETTIMANA MODIFICABILE
✔ COMPLETATO

### STEP E4 — MOTORE COLLEGATO A SCHOOLSTORE
✔ COMPLETATO

### STEP E5 — ALLINEAMENTO UI A STATO ALICE REALE
🔥 IN CORSO

Obiettivo:
- eliminare letture vecchie
- fare leggere la UI solo dal nuovo sistema
- rendere coerenti:
  - box scuola
  - stato Alice
  - realtà del giorno
  - copertura

---

# BLOCCO F — CONFLITTI AVANZATI

Stato: FUTURO

---

# BLOCCO G — SISTEMA IPS

Stato: FUTURO

---

# DIREZIONE FUTURA

Dopo BLOCCO SCUOLA:

👉 Azioni consigliate (Livello B)  
👉 Miglioramento decisionale  
👉 Evoluzione sistema predittivo  

---

# MODULI FUTURI

FINANZE  
SPESE  
SALUTE  
AUTO  
STATISTICHE  

---

# STATO ATTUALE

✔ Sistema stabile  
✔ Copertura reale funzionante  
✔ Eventi Alice funzionanti  
✔ Conflitti gestiti  
✔ Periodi scuola funzionanti  
✔ Settimana scuola modificabile funzionante  
✔ Motore scuola collegato al nuovo sistema  

🔥 In corso:

👉 allineamento UI allo stato reale di Alice/scuola

---

# DIREZIONE OPERATIVA

NON fare:

❌ modifiche multiple  
❌ salti di fase  
❌ rattoppi UI senza capire la fonte dati

Fare:

✔ un passo alla volta  
✔ fonte di verità unica  
✔ test immediato  
✔ motore prima, UI coerente dopo

---

# PROSSIMA RIPARTENZA

Ripartiamo da FrodoDesk — BLOCCO SCUOLA

STEP 1:
👉 analisi di `calendario_screen_stepa.dart` per trovare dove la UI legge ancora la vecchia logica di Alice/scuola e riallinearla completamente al nuovo sistema.