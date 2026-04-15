# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: Aprile 2026 (post fix scuola UI)

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

🔥 FIX COMPLETATO:

✔ UI ora allineata allo stato reale scuola  
✔ Giorni OFF scuola correttamente gestiti  
✔ Stato Alice coerente tra:
- card principale
- popup stato attuale
- eventi giornata  

✔ Eliminata duplicazione logica stato Alice  
✔ Rimossa logica legacy non allineata  

---

# 🧠 LOGICA CONSOLIDATA (POST FIX)

Fonte unica di verità:

👉 SchoolStore + AliceEventStore

La UI NON decide più lo stato  
👉 lo legge dal motore

---

# 🔥 PROBLEMA RISOLTO (CRITICO)

Sintomo precedente:

❌ “Alice fuori • scuola” anche nei giorni OFF  
❌ popup incoerente (scuola visiva ma non reale)

Causa:

❌ duplicazione logica (UI + motore)  
❌ uso di funzioni legacy (isSchoolNormalDay non coerente)

Soluzione:

✔ centralizzazione su SchoolStore  
✔ uso di isRealSchoolDay coerente  
✔ rimozione aliceNowLabel duplicato  

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
✔ stato Alice ora coerente  

⚠️ AREA DA RIFINIRE:

👉 blocco UI Alice / Scuola ancora da pulire completamente

---

# DIREZIONE OPERATIVA

## 1️⃣ PRIORITÀ ATTUALE
👉 pulizia completa UI blocco Alice

## 2️⃣ STEP CONFERMATI

A — pulizia card Alice / Scuola  
B — allineamento box scuola + popup  
C — pulizia editor eventi Alice  
D — test strutturale completo  

---

# SIGNIFICATO DELLA FASE

Il sistema evolve da:

❌ UI scollegata dalla logica  
👉 verso  
✔ UI = specchio esatto del motore  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — PULIZIA BLOCCO ALICE (STEP A): eliminare residui UI non coerenti e rendere la card Alice perfettamente allineata al sistema scuola e al motore di copertura.