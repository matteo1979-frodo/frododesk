# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: Aprile 2026 (post fix scuola motore + support network)

---

# IDENTITÀ DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Principio fondamentale:

👉 Il sistema suggerisce  
👉 La decisione resta sempre umana

---

# FILOSOFIA DI SVILUPPO

Il sistema è costruito con filosofia CNC (Costruzione Non Caotica):

- un passo alla volta
- zero modifiche multiple insieme
- ogni blocco deve essere stabile prima di passare al successivo
- lavoro sempre su file reali

---

# FASE ATTUALE DEL PROGETTO

👉 Calendario reale — COMPLETO E FUNZIONANTE

Il sistema è:

✔ utilizzabile nella vita reale  
✔ testato su casi concreti  
✔ stabile nei motori principali  

---

# 🔥 NUOVA FASE ATTIVA

👉 BLOCCO SCUOLA — INTEGRAZIONE COMPLETA NEL SISTEMA

Obiettivo:

- eliminare completamente gestione manuale giornaliera
- rendere la scuola una fonte unica di verità
- collegare scuola → stato Alice → copertura → UI

---

# 🧠 DECISIONE STRUTTURALE (FONDAMENTALE)

La scuola NON è più:

❌ modifica giornaliera  
❌ gestione separata dalla logica  

Diventa:

✔ sistema strutturato a periodi  
✔ orario settimanale stabile  
✔ fonte unica per lo stato di Alice  
✔ integrata nel motore di copertura  

---

# STATO REALE BLOCCO SCUOLA

✔ SchoolStore attivo  
✔ Periodi funzionanti  
✔ Lettura settimanale funzionante  
✔ Orari letti correttamente dal motore  

---

# 🔧 FIX SCUOLA — APRILE 2026

✔ Orario ingresso letto da SchoolStore  
✔ Orario uscita letto da SchoolStore  
✔ Rientro automatico = uscita + 20 min (calcolato, non salvato)  

✔ Buco ingresso calcolato su orario reale  
✔ Buco uscita calcolato su orario reale  

✔ UI completamente allineata al motore  

---

# 🔥 FIX CRITICO — SUPPORT NETWORK

Problema precedente:

❌ Il sistema considerava copertura valida anche se NON compatibile con l’orario reale  
(es: Sandra 07:00–08:25 copriva ingresso 09:05–09:25)

Causa:

❌ uso di fallback orario fisso (08:25)  
❌ mancato controllo reale della fascia temporale  

Soluzione:

✔ ingresso reale ora letto da SchoolStore anche nel controllo copertura  
✔ validazione supporto fatta su intervallo reale  

Risultato:

👉 la copertura è valida SOLO se copre davvero la fascia richiesta  

---

# 🧠 LOGICA CONSOLIDATA (POST FIX)

Fonte unica di verità:

👉 SchoolStore + AliceEventStore

La UI NON decide più lo stato  
👉 lo legge dal motore

---

# PRINCIPIO CHIAVE (IMPORTANTISSIMO)

Separazione obbligatoria:

### DATO REALE
- ingresso scuola = dato vero
- uscita scuola = dato vero

### LOGICA
- accompagnamento = ingresso - 20 min  
- rientro = uscita + 20 min  

👉 Il sistema NON deve mai confondere i due

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione post-notte corretta  
✔ gestione eventi temporanei corretta  
✔ gestione centro estivo funzionante  
✔ gestione accompagnamento / ritiro funzionante  

✔ support network ora validato correttamente nel tempo  

👉 considerato affidabile sui casi testati  

---

# ⚠️ BUG ATTIVO IDENTIFICATO

👉 USCITA ANTICIPATA NON IMPATTA IL MOTORE

Sintomo:

- UI aggiorna correttamente orario uscita anticipata  
- decisione scuola si aggiorna  
- ❌ il buco NON si chiude  

Causa probabile:

👉 CoverageEngine NON usa ancora uscita anticipata reale  

Stato:

👉 da correggere nel prossimo step (motore)

---

# STATO EVENTI ALICE

✔ AliceEventStore attivo  
✔ AliceSpecialEventStore attivo  
✔ eventi temporanei integrati  
✔ gestione accompagnamento / ritiro  
✔ eliminati falsi buchi  

---

# MOTORI ATTIVI

- TurnEngine  
- CoverageEngine  
- EmergencyDayLogic  
- FourthShiftCycleLogic  

---

# STORE PRINCIPALI

- CoreStore  
- OverrideStore  
- TurnOverrideStore  
- RotationOverrideStore  
- RealEventStore  
- AliceEventStore  
- AliceSpecialEventStore  
- SupportNetworkStore  
- FeriePeriodStore  
- DiseasePeriodStore  
- FourthShiftStore  
- SettingsStore  
- SummerCampScheduleStore  
- SummerCampSpecialEventStore  
- SchoolStore ✅

---

# STATO UI

✔ calendario funzionante  
✔ struttura a blocchi attiva  
✔ eventi Alice integrati  
✔ stato Alice coerente  

✔ scuola completamente allineata al motore  

---

# DIREZIONE OPERATIVA

## 1️⃣ PRIORITÀ ATTUALE
👉 fix uscita anticipata nel motore copertura

## 2️⃣ STEP CONFERMATI

A — collegare uscita anticipata al CoverageEngine  
B — verificare chiusura buchi dinamici  
C — test completo casi reali  
D — rifinitura UI finale  

---

# SIGNIFICATO DELLA FASE

Il sistema evolve da:

❌ simulazione approssimativa  
👉 verso  
✔ simulazione reale basata su tempo e logica coerente  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — FIX USCITA ANTICIPATA: collegare l’orario reale al motore di copertura e verificare la chiusura corretta dei buchi.