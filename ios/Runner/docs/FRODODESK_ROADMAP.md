FRODODESK — ROADMAP

Ultimo aggiornamento: Aprile 2026 (post fix UI scuola)

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
👉 a allineamento completo tra motore, stato Alice e UI

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

## Stato: IN FASE FINALE DI RIFINITURA UI

---

## COSA È STATO COMPLETATO

### STEP E1 — STRUTTURA DATI
✔ SchoolPeriod  
✔ SchoolWeekConfig  
✔ SchoolDayConfig

### STEP E2 — STORE
✔ SchoolStore

### STEP E3 — UI PERIODI
✔ creazione periodo  
✔ eliminazione periodo  
✔ visualizzazione periodo attivo  
✔ dettaglio periodo

### STEP E4 — UI SETTIMANA
✔ popup settimana  
✔ giorni letti dal periodo  
✔ stato ATTIVO / OFF  
✔ modifica attivo/off  
✔ modifica ingresso  
✔ modifica uscita reale  
✔ visualizzazione orari accanto ai giorni  
✔ salvataggio reale per lun–sab

### STEP E5 — MOTORE
✔ CoverageEngine legge SchoolStore  
✔ il giorno scuola viene deciso dal periodo attivo  
✔ il motore legge ingresso / uscita / rientro dal nuovo sistema

### STEP E6 — ALLINEAMENTO UI STATO ALICE
✔ risolto “Alice fuori • scuola” nei giorni OFF  
✔ risolto popup incoerente  
✔ risolto stato Alice non allineato al motore  
✔ introdotto uso coerente di SchoolStore nella UI  
✔ eliminata duplicazione `aliceNowLabel`  
✔ rimosso utilizzo improprio di `schoolNormal` come evento speciale

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

⚠️ NON è più un problema di motore

Il problema rimasto è:

👉 rifinitura finale UI del blocco Alice / Scuola

In particolare:
- card Alice / Scuola ancora da pulire
- box scuola e popup scuola da rendere più coerenti quando il giorno è OFF
- editor Eventi Alice da ripulire definitivamente

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
✔ COMPLETATO

### STEP E6 — RIFINITURA UI BLOCCO ALICE
🔥 IN CORSO

Obiettivo:
- eliminare residui UI non coerenti
- rifinire card Alice / Scuola
- rifinire box scuola / popup
- chiudere definitivamente editor eventi Alice

---

# PIANO OPERATIVO CONFERMATO

## A — pulizia card Alice / Scuola
👉 priorità immediata

## B — allineamento box scuola + popup
👉 subito dopo A

## C — pulizia editor eventi Alice
👉 dopo B

## D — test strutturale completo
👉 chiusura finale blocco scuola

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
✔ Stato Alice corretto  
✔ Popup Alice corretto  
✔ Giorni ON/OFF scuola letti correttamente  

🔥 In corso:

👉 rifinitura finale UI blocco Alice / Scuola

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

STEP A:
👉 pulizia completa della card Alice / Scuola

Poi:
👉 STEP B — allineamento box scuola + popup  
👉 STEP C — pulizia editor eventi Alice  
👉 STEP D — test strutturale completo