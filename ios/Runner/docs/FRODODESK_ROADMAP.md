FRODODESK — ROADMAP

Ultimo aggiornamento: Aprile 2026 (post fix motore scuola + support network)

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
👉 a allineamento completo tra motore, stato Alice, copertura e UI

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

## Stato: MOTORE QUASI COMPLETATO / RIFINITURA FINALE IN CORSO

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

### STEP E7 — FIX MOTORE SCUOLA REALE
✔ CoverageEngine ora usa lo SchoolStore reale del CoreStore  
✔ bug `DEBUG PERIOD -> null` risolto  
✔ buchi ingresso/uscita tornati a comparire correttamente  
✔ uscita scuola letta in modo dinamico dal periodo reale  
✔ rientro automatico (+20 min) funzionante nel motore  
✔ ingresso scuola verificato e confermato dinamico  
✔ support network validato sul tempo reale  
✔ eliminato falso positivo di copertura con fascia non compatibile

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

⚠️ NON è più un problema generale della scuola  
⚠️ NON è più un problema di lettura ingresso/uscita standard

Il problema rimasto è:

👉 uscita anticipata non ancora collegata correttamente al motore di copertura

Sintomo attuale:
- la UI aggiorna correttamente l’orario
- la decisione scuola copertura si aggiorna
- ❌ il buco non si chiude

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
🔄 PARZIALMENTE SUPERATO DALLA PRIORITÀ MOTORE

### STEP E7 — FIX MOTORE SCUOLA REALE
✔ COMPLETATO

### STEP E8 — USCITA ANTICIPATA NEL MOTORE
🔥 IN CORSO

Obiettivo:
- collegare uscita anticipata reale al CoverageEngine
- chiudere davvero il buco quando la copertura è impostata correttamente
- verificare coerenza completa UI → decisione → motore

---

# PIANO OPERATIVO CONFERMATO

## A — fix uscita anticipata nel motore
👉 priorità immediata

## B — test reale completo casi scuola
👉 subito dopo A

## C — rifinitura UI card Alice / Scuola
👉 dopo stabilizzazione motore

## D — chiusura finale blocco scuola
👉 dopo test strutturale completo

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
✔ Ingresso scuola letto correttamente dal sistema reale  
✔ Uscita scuola letta correttamente dal sistema reale  
✔ Support network verificato su fascia reale  

🔥 In corso:

👉 fix uscita anticipata nel motore copertura

---

# DIREZIONE OPERATIVA

NON fare:

❌ modifiche multiple  
❌ salti di fase  
❌ rattoppi UI senza capire la fonte dati  
❌ considerare valida una copertura solo perché “attiva”

Fare:

✔ un passo alla volta  
✔ fonte di verità unica  
✔ test immediato  
✔ motore prima, UI coerente dopo  
✔ copertura valida solo se compatibile con la fascia reale

---

# PROSSIMA RIPARTENZA

Ripartiamo da FrodoDesk — BLOCCO SCUOLA

STEP A:
👉 fix uscita anticipata nel motore di copertura

Poi:
👉 STEP B — test reale completo scuola  
👉 STEP C — rifinitura UI card Alice / Scuola  
👉 STEP D — chiusura finale blocco scuola