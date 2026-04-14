# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: Aprile 2026

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

⚠️ PROBLEMA ATTUALE:

👉 La UI NON è ancora completamente allineata al nuovo sistema

Sintomi:

- “Stato Alice: scuola normale” mostrato anche quando NON dovrebbe
- “Alice fuori · scuola” non coerente con la logica reale

👉 Questo indica che:

❌ alcune parti UI leggono ancora la logica vecchia  
✔ il motore invece è corretto  

---

# STRUTTURA BLOCCO SCUOLA

## Livello 1 — Periodi

Il sistema gestisce più periodi:

- Elementari
- Medie
- Futuri periodi

Ogni periodo contiene:

- nome periodo
- data inizio
- data fine
- configurazione settimanale

---

## Livello 2 — Orario settimanale

Per ogni giorno (lun–sab):

- attivo / non attivo
- ora ingresso
- ora uscita reale

👉 Il sistema calcola automaticamente:

- rientro a casa = uscita + 20 minuti

⚠️ IMPORTANTE:
Il rientro NON viene salvato  
È sempre calcolato

---

# 🧠 LOGICA DI PRIORITÀ

Ordine corretto del sistema:

1. Eventi Alice (vacanza, malattia, centro estivo)
2. Eventi temporanei Alice (giornalieri)
3. Periodo scuola attivo
4. Orario settimanale
5. Motore copertura

---

# 🔥 CORREZIONE CRITICA ESEGUITA

Problema risolto:

❌ Il sistema usava l’orario di fine come uscita scuola  
✔ Ora distingue correttamente:

- uscita reale = orario scuola
- rientro = uscita + 20 min

---

# PRINCIPIO CHIAVE (IMPORTANTISSIMO)

Separazione obbligatoria:

### DATO REALE
- uscita scuola = dato vero

### LOGICA
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

👉 considerato affidabile sui casi testati  

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

⚠️ PROBLEMA ATTUALE (CRITICO):

👉 UI non allineata alla nuova logica scuola

- stato Alice letto ancora da vecchia logica
- incongruenza tra motore e visualizzazione

👉 PROSSIMO INTERVENTO:

✔ allineamento completo UI → CoverageEngine / SchoolStore  

---

# DIREZIONE OPERATIVA

## 1️⃣ PRIORITÀ ATTUALE
👉 allineamento UI allo stato reale del sistema

## 2️⃣ STEP IMMEDIATO
👉 correggere lettura stato Alice in UI

## 3️⃣ DOPO
👉 rifinitura blocco scuola UI (popup unico)

---

# SIGNIFICATO DELLA FASE

Il sistema evolve da:

❌ UI scollegata dalla logica  
👉 verso  
✔ UI = specchio esatto del motore  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — ALLINEAMENTO UI STATO ALICE: eliminare letture vecchie e collegare completamente la UI al nuovo sistema scuola e al motore di copertura.