# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 30 Marzo 2026

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

# STATO ATTUALE — NUOVA FASE

👉 Costruzione modulo **Eventi Alice (reali)**

Obiettivo:

- rappresentare la vita reale di Alice
- integrare eventi dentro il motore
- collegare eventi → copertura → decisioni

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

---

# FUNZIONALITÀ ATTUALI

Il sistema gestisce:

- turni lavoro automatici  
- quarta squadra  
- riposo post-notte  
- eventi reali calendario  
- eventi Alice (periodi base)  
- eventi Alice reali (nuovo sistema in costruzione)  
- rete di supporto  
- copertura Sandra  
- rilevazione buchi giornata  
- override giornalieri  
- ferie lunghe  
- malattia a periodo  
- conflitti turno ↔ evento  
- gestione permesso / ferie come risoluzione  

---

# STATO EVENTI ALICE

✔ creato model `AliceSpecialEvent`  
✔ creato store `AliceSpecialEventStore`  
✔ integrato in CoreStore  
✔ lettura eventi in `_cardScuola()`  
✔ editor base funzionante  
✔ inserimento evento reale funzionante  

Esempio reale validato:

👉 pallavolo (18:00–20:00)

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione post-notte corretta  
✔ gestione eventi temporanei corretta  
✔ gestione centro estivo funzionante  

👉 considerato affidabile sui casi testati  

---

# 🔥 AGGIORNAMENTO — EVENTI ALICE → COPERTURA (FASE A COMPLETATA)

Durante questa sessione è stato realizzato il primo collegamento reale tra:

👉 Eventi Alice  
👉 motore di copertura  

### Risultato ottenuto:

Il sistema ora gestisce correttamente:

#### ✔ 1. DURANTE EVENTO
- Alice NON viene più considerata “a casa”
- nessun bisogno di copertura casa

#### ✔ 2. PRIMA EVENTO (ACCOMPAGNAMENTO)
- viene generato un buco SOLO se nessuno è disponibile
- eliminati falsi positivi

#### ✔ 3. DOPO EVENTO (RITIRO)
- introdotta logica di verifica disponibilità
- buco NON generato se un adulto è disponibile

#### ✔ 4. CONTROLLO REALE DISPONIBILITÀ
- introdotto primo livello di logica:
  👉 non basta evento → serve verifica persone

---

### Stato attuale del motore:

👉 Il sistema NON genera più buchi finti  
👉 I buchi sono coerenti con la realtà operativa  

---

# STATO UI

✔ calendario funzionante  
✔ struttura a blocchi attiva  
✔ card leggibili  
✔ editor eventi Alice integrato  

⚠️ UI ancora da rifinire (fase successiva)

---

# STATO REFACTOR

✔ fase 1 helper completata  
✔ file calendario alleggerito  
✔ nessun errore introdotto  

---

# BUG ATTIVI (RIDOTTI)

Attualmente:

- piccoli problemi UI (non bloccanti)
- possibili duplicazioni nei “Buchi del giorno”

👉 nessun bug critico bloccante

---

# DIREZIONE OPERATIVA

Ordine ufficiale aggiornato:

## 1️⃣ PRIORITÀ ATTUALE
👉 stabilizzazione logica eventi Alice (FASE A completata)

## 2️⃣ PROSSIMO STEP
👉 rendere reale il controllo disponibilità (`isSomeoneAvailable`)

## 3️⃣ DOPO
👉 sviluppo completo modulo Eventi Alice (UI + salvataggio + modifica)

---

# SIGNIFICATO DELLA FASE ATTUALE

Il sistema è ufficialmente passato a:

✔ motore decisionale reale basato su eventi

Non è più:

❌ calendario evoluto

---

# MODULI DOCS ATTIVI

- core/SYSTEM_STATE.md  
- core/RULES.md  
- modules/eventi_alice.md  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — Eventi Alice collegati alla copertura reale (FASE A completata: accompagnamento + ritiro con controllo disponibilità). Prossimo passo: rendere reale `isSomeoneAvailable` e avviare sviluppo completo modulo Eventi Alice (editor avanzato + salvataggio).