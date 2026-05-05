# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 4 Maggio 2026 (Eventi Globali V1 + Memoria Evento Persistente)

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

🔥 CALENDARIO REALE COMPLETO + COPERTURA REALE + HOME AZIONABILE V1.1 CONSOLIDATA + EVENTI GLOBALI V1

Il sistema è:

✔ utilizzabile nella vita reale  
✔ testato su casi concreti  
✔ stabile nei motori principali  
✔ coerente tra motore → calendario → Home  
✔ capace di distinguere tra stato reale di oggi e problemi futuri  
✔ capace di trasformare un buco reale in problema visibile dalla Home  
✔ capace di portare direttamente al giorno del problema  
✔ coerente anche nei giorni festivi senza scuola  
✔ capace di navigare eventi nel tempo (anno → mesi → eventi)  
✔ capace di salvare memoria reale sugli eventi  

---

# 🧠 EVOLUZIONE STRUTTURALE

Il sistema ha fatto il passaggio chiave:

❌ prima → simulazione parziale  
✔ ora → simulazione reale della giornata  

Nuova evoluzione:

❌ prima → Home solo informativa  
✔ ora → Home operativa e gerarchica (oggi vs futuro)

🔥 NUOVO PASSAGGIO:

❌ prima → eventi = dati temporanei  
✔ ora → eventi = memoria persistente  

---

# 🔥 BLOCCO SCUOLA

Stato: COMPLETATO

---

## RISULTATO

✔ SchoolStore attivo  
✔ Periodi funzionanti  
✔ Orari letti correttamente  
✔ Stato Alice coerente  
✔ Support network validato  
✔ UI allineata al motore  
✔ giorni festivi riconosciuti correttamente come “nessuna scuola prevista”  

👉 La scuola è ora fonte unica di verità

---

# 🔥 BLOCCO COPERTURA REALE

Stato: COMPLETATO / CONSOLIDATO

---

## REGOLA FONDAMENTALE

Alice è considerata **A CASA** quando NON è:

- a scuola
- in evento valido
- fuori casa per attività reale

---

## REGOLA COPERTURA

Se Alice è a casa:

👉 deve essere SEMPRE coperta da:

- Matteo
- Chiara
- Supporto
- Sandra (solo se attiva)

Se nessuno copre:

👉 ❌ BUCO REALE

---

## CAMBIAMENTO CHIAVE

✔ controllo esteso su tutta la giornata  
❌ NON più limitato a fasce Sandra  
❌ NON più legato solo alla scuola  
✔ valido anche nei giorni festivi  
✔ valido anche quando Alice è a casa perché scuola chiusa / festa / weekend  

---

## RISULTATO

✔ Buchi reali corretti  
✔ Eventi reali influenzano la copertura  
✔ Supporto integrato correttamente  
✔ Calendario coerente  
✔ Home coerente  
✔ test 1 Maggio validato  

👉 Sistema finalmente affidabile

---

# 🔥 BLOCCO HOME AZIONABILE V1

Stato: IMPLEMENTAZIONE COMPLETATA E TESTATA

---

## RISULTATO

La Home ora:

✔ legge i buchi reali della copertura  
✔ mostra il problema copertura nella card principale  
✔ indica quanti problemi ci sono oggi  
✔ mostra il primo buco da gestire  
✔ bottone principale: **RISOLVI**  
✔ apre un popup con il problema  

---

# 🔥 BLOCCO HOME AZIONABILE V1.1 (NUOVO)

Stato: COMPLETATO E VALIDATO

---

## CAMBIAMENTO CHIAVE

La Home ora separa:

👉 STATO REALE DI OGGI  
👉 PROBLEMA FUTURO  

---

## COMPORTAMENTO

### OGGI

✔ Se tutto è coperto → verde  
✔ testo: **“Nessuna criticità oggi”**  
✔ nessun falso allarme  

---

### FUTURO

✔ Il problema viene comunque mostrato  
✔ visibile subito  
✔ cliccabile  

Esempio reale:

👉 Alice scoperta sabato 30 maggio 13:00–14:30  

---

## DECISIONE STRUTTURALE IMPORTANTE

❌ eliminata la logica:

"Nessun problema nei prossimi 30 giorni"

✔ sostituita da:

👉 verità reale sempre visibile  

---

## RISULTATO

✔ nessuna confusione  
✔ nessuna falsa sicurezza  
✔ navigazione diretta al problema  
✔ comportamento reale  

---

## REGOLA UX PRINCIPALE

Quando c’è un problema principale:

👉 la Home deve mostrare UNA cosa sola da fare

---

## FLUSSO DECISO

1. Home mostra stato reale (oggi)  
2. Mostra eventuale problema futuro  
3. Click → calendario  
4. Decisione umana  

---

## REGOLA DECISIONALE

Il sistema:

✔ spiega il problema  
✔ porta nel punto giusto  
❌ NON propone soluzioni automatiche  

---

## NOTA IMPORTANTE

👉 la Home ora è affidabile per uso reale quotidiano  

---

# 🔥 BLOCCO EVENTI GLOBALI (NUOVO)

Stato: IMPLEMENTATO (V1)

---

## STRUTTURA

✔ Navigazione:

- Anno
- Mesi (griglia 4x3)
- Eventi del mese
- Scheda evento

---

## RISULTATO

✔ eventi organizzati per anno  
✔ mesi visualizzati come cruscotto  
✔ conteggio eventi per mese  
✔ accesso diretto ai mesi con eventi  
✔ UI non più lista ma struttura visiva  

---

## LIMITAZIONE ATTUALE

👉 legge solo:

✔ RealEventStore  

❌ NON ancora inclusi:

- AliceEventStore  
- AliceSpecialEventStore  

👉 integrazione prevista nella prossima fase

---

# 🔥 BLOCCO MEMORIA EVENTO (NUOVO)

Stato: COMPLETATO E VALIDATO

---

## FUNZIONALITÀ

✔ apertura evento  
✔ campo note modificabile  
✔ salvataggio reale nello store  
✔ persistenza dopo riavvio app  

---

## RISULTATO

✔ ogni evento può diventare memoria  
✔ dati non più temporanei  
✔ base per storico reale  

---

## SIGNIFICATO

👉 primo passo verso:

- diario eventi  
- storico familiare  
- analisi futura  

---

# 🔥 STRATO AZIONI UNIVERSALE (FUTURO)

Stato: DEFINITO CONCETTUALMENTE, NON ANCORA IMPLEMENTATO

---

# 📚 STORICO / ANALISI ANNUALE

Stato: IDEA EMERSA, NON ANCORA IMPLEMENTATA

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione eventi reali corretta  
✔ gestione supporto corretta  
✔ gestione Alice a casa corretta  
✔ gestione giorni festivi corretta  
✔ buchi reali letti dalla Home  

---

# STATO EVENTI ALICE

✔ AliceEventStore attivo  
✔ AliceSpecialEventStore attivo  
✔ eventi integrati nel motore  
❌ NON ancora integrati negli Eventi Globali  

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
- SchoolStore  

---

# STATO UI

✔ calendario funzionante  
✔ eventi reali integrati  
✔ stato Alice coerente  
✔ Home collegata al motore reale  
✔ Home separa oggi vs futuro  
✔ navigazione diretta al problema  
✔ Eventi Globali navigabili  
✔ mesi in griglia FrodoDesk  
✔ scheda evento con memoria  

---

# ⚠️ STATO IPS

👉 NON ancora coerente con il sistema reale

---

# 🎯 PROSSIMA FASE

🔥 INTEGRAZIONE EVENTI ALICE → EVENTI GLOBALI

---

# DIREZIONE OPERATIVA

✔ un passo alla volta  
✔ motore prima  
✔ UI dopo  
✔ test reale continuo  
✔ decisione sempre umana  

---

# SIGNIFICATO ATTUALE

Il sistema ora:

👉 legge la realtà  
👉 distingue oggi da futuro  
👉 non nasconde problemi  
👉 guida l’utente  
👉 inizia a costruire memoria reale  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — Eventi Globali V1 + Memoria Evento attiva. Prossima fase: integrazione Eventi Alice negli Eventi Globali.
---

## 🔄 AGGIORNAMENTO 5 Maggio 2026

### HOME + EVENTI GLOBALI + MEMORIA EVENTO

✔ introdotta struttura completa Eventi Globali  
✔ navigazione anno → mesi → eventi funzionante  
✔ mesi visualizzati in griglia con conteggio eventi  
✔ accesso ai mesi solo se contengono eventi  

✔ aggiunta scheda dettaglio evento  
✔ introdotto campo memoria evento (note)  
✔ salvataggio persistente verificato  
✔ memoria evento stabile dopo riavvio  

✔ supporto eventi multi-persona  
✔ introduzione participants negli eventi  
✔ integrazione corretta nel CoverageEngine  

✔ Home aggiornata per leggere eventi reali + eventi Alice  
✔ migliorata coerenza tra eventi e copertura  

---

### EVENTI GLOBALI — EVOLUZIONE

✔ introdotta distinzione temporale:

- Eventi passati  
- Eventi anno corrente  
- Eventi futuri  

✔ definita regola:

- anno corrente = presente  
- anni precedenti = passato  
- anni successivi = futuro  

✔ introdotta base UI per anni futuri  

⚠️ stato attuale:

- anni visibili ma non ancora apribili se vuoti  
- sistema pronto per espansione  

---

### ARCHITETTURA MODULARE

✔ decisione strutturale:

👉 Home NON deve contenere logiche complesse  

✔ definito principio:

- Home = orchestratore  
- moduli = logica reale  

✔ preparazione per:

- modulo Statistiche  
- moduli grafici  
- espansione futura sistema  

---

### NUOVO BLOCCO — STATISTICHE

✔ introdotto concetto modulo Statistiche  

✔ decisione:

- modulo separato  
- NON dentro Home  
- base per grafici  

✔ direzione:

👉 grafici = lettura immediata della realtà  
👉 elemento chiave del sistema futuro  

---

### STATO

✔ stabile  
✔ testato su app reale  
✔ memoria eventi funzionante  
✔ Eventi Globali funzionanti  
✔ Home coerente con sistema  
✔ struttura pronta per espansione