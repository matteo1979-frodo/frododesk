# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 9 Aprile 2026

---

## IDENTITÀ DEL MODULO

Questo modulo gestisce gli **Eventi Alice reali/speciali**, cioè gli eventi della vita reale di Alice che possono influenzare:

- la presenza reale
- la copertura
- le decisioni familiari
- il linguaggio del sistema

---

## 🔥 STATO ATTUALE — EVOLUZIONE MODULO

Gli Eventi Alice NON sono più solo informativi.

👉 Sono entità:
- persistenti
- modificabili
- con impatto reale sul sistema

👉 🔥 NUOVO (APRILE 2026):
- collegamento reale con **linguaggio stato Alice**
- collegamento reale con **copertura**
- base per sistema visivo (emoji + colori)
- etichette umane collegate al nome reale evento

---

## 🧠 ARCHITETTURA — 3 LIVELLI (FONDAMENTALE)

### 1️⃣ LOGICA  
→ dove si trova Alice realmente  

### 2️⃣ LINGUAGGIO  
→ come il sistema descrive lo stato  

### 3️⃣ VISUALE  
→ emoji + colore (status_visual)

---

## 🔧 IMPLEMENTAZIONE ATTUALE (LINGUAGGIO REALE)

Il placeholder è stato eliminato.

Ora il linguaggio legge realmente:

- stato periodo Alice  
- eventi Alice temporizzati  
- eventi reali Alice  
- categorie evento  
- fallback testuale  

---

## 🎯 RISULTATO RAGGIUNTO

Alice genera automaticamente:

- "fuori • scuola"
- "fuori • centro estivo"
- "fuori • sport"
- "fuori • attività"
- "fuori • visita"
- "fuori • gita"
- "a casa • malata"
- "a casa"

👉 senza modificare UI  
👉 senza toccare status_visual  

---

## 🔒 REGOLA FONDAMENTALE

- NON modificare UI  
- NON toccare status_visual  
- il linguaggio nasce SOLO dalla logica reale  

---

## 🧠 LOGICA STATO CASA — AGGIORNAMENTO STRUTTURALE

🔥 **NUOVA REGOLA STABILE INTRODOTTA**

La gestione di "Alice a casa" ora segue una gerarchia precisa.

---

### 1️⃣ STATO GIORNO DOMINANTE

Se il giorno è:

- vacation  
- sickness  
- schoolClosure  

👉 il sistema mostra:

- Alice a casa (Vacanza)  
- Alice a casa (Malata)  
- Alice a casa (Scuola chiusa)  

👉 PRIORITÀ MASSIMA  
👉 non viene mai trasformato in “dopo evento”

---

### 2️⃣ EVENTO TEMPORALE

Se esiste un evento reale:

👉 il sistema genera:

- Alice a casa dopo danza  
- Alice a casa dopo visita  
- Alice a casa dopo sport  

👉 SOLO fuori dall’intervallo evento  

---

### 3️⃣ FALLBACK SCUOLA

Se:

- giorno normale  
- nessun evento  

👉 il sistema genera:

Alice a casa dopo scuola  

---

## 🧠 PRINCIPIO CONSOLIDATO

👉 lo stato giorno NON deve schiacciare la realtà temporale  

MA  

👉 quando è dominante (vacanza / malattia / chiusura scuola)  
vince sempre  

---

## 🔥 LOGICA EVENTI ALICE → COPERTURA

Un evento Alice genera impatto reale:

1️⃣ DURANTE EVENTO → Alice fuori  
2️⃣ PRIMA EVENTO → accompagnamento  
3️⃣ DOPO EVENTO → ritiro  
4️⃣ DOPO → ritorno stato reale  

---

## ⏱️ BUFFER EVENTI

- 20 minuti prima  
- 20 minuti dopo  

---

## 🧠 PRINCIPIO REALTÀ

Evento ≠ genitore occupato tutto il tempo  

✔ accompagnamento → vincolo  
✔ evento → libero  
✔ ritiro → vincolo  

---

## 🧾 LINGUAGGIO UMANO

Prima:
- Ritiro Alice evento  

Ora:
- Ritiro Alice danza  
- Accompagnamento Alice danza  

---

## ⚠️ DECISIONE IMPORTANTE

NON unire automaticamente i buchi  

👉 ogni blocco può avere soluzione diversa  

---

## 🧠 SCOPERTA STRUTTURALE

👉 dopo scuola / evento  
Alice deve tornare a casa  

NON deve restare “fuori”  

---

## 🧩 MODELLO EVENTO

- id  
- label  
- category  
- date  
- start  
- end  
- note  
- enabled  

---

## 🧠 STATO REALE

✔ model  
✔ store  
✔ CoreStore  
✔ editor  
✔ multi-evento  
✔ persistenza  
✔ conflitti  
✔ UI  

---

## 🔥 COMPLETATO RECENTE

✔ linguaggio "Alice a casa dopo..."  
✔ separazione stato giorno vs evento  
✔ eliminazione ricorsione (bug critico risolto)  
✔ funzione pura per stato casa  

---

## 🚧 NON ANCORA FATTO

LOGICA  
⬜ scuola come evento reale  

LINGUAGGIO  
⬜ perfezionamento casi complessi  

SISTEMA  
⬜ conflitti forti  
⬜ suggerimenti  
⬜ IPS  

---

## 🎯 STATO MODULO

🟢 STABILE

✔ crash risolto  
✔ logica coerente  
✔ linguaggio realistico  

---

## 🚀 PROSSIMO STEP

👉 collegare completamente:

- eventi Alice  
- accompagnamento  
- ritiro  
- impatto reale su copertura  

---

## 🧱 NOTA ARCHITETTURALE

Questa modifica:

👉 separa definitivamente:

- logica  
- linguaggio  
- struttura  

👉 elimina dipendenze pericolose  
👉 rende il sistema scalabile

---

# 🔥 AGGIORNAMENTO STRUTTURALE — MAGGIO 2026

## ✅ EVENTI REALI FAMILIARI

Nuova regola reale introdotta nel motore:

👉 se Alice partecipa a un Evento Reale insieme ai genitori

ALLORA:

- Alice NON è considerata "a casa"
- NON viene generato buco automatico
- Home e Calendario leggono Alice come "dentro evento reale"

---

## 🧠 PRINCIPIO REALTÀ

Prima:

evento reale = solo genitore occupato

Ora:

evento reale con Alice = famiglia insieme fuori casa

👉 il sistema distingue:

- genitore fuori
- Alice a casa

DA:

- famiglia insieme all’evento

---

## 🔧 FIX MOTORE INTRODOTTO

Nuova funzione strutturale:

- `_isAliceInsideRealEvent()`

Utilizzata dentro:

- analyzeDayV2()

per impedire falsi buchi:

- "Alice a casa"
- "Alice a casa dopo evento"

quando Alice è realmente dentro l’evento.

---

## ✅ RISULTATO

Corretto il bug:

❌ falso rischio:
"Matteo fuori per evento reale"
mentre Alice era dentro lo stesso evento

✔ ora il sistema:
- non genera buco
- non genera rischio Home
- considera Alice presente con i genitori

---

## 🚀 NUOVA DIREZIONE UFFICIALE

Il sistema entra ora nella fase:

# "Motore presenza reale Alice"

Obiettivo:

non ragionare più per eventi sparsi,
ma tramite UNA sorgente unica di verità:

👉 "Dove si trova realmente Alice?"

---

## 📌 ROADMAP UFFICIALE

☑ Evento logistico Alice  
☑ Accompagnamento / ritiro  
☑ Supporto reale sincronizzato  
☑ Alice dentro evento reale = niente falso buco  

⬜ Creare `alice_presence_engine.dart`
⬜ Stati presenza Alice centralizzati
⬜ CoverageEngine legge il motore presenza
⬜ Home legge il motore presenza
⬜ Pulizia doppioni logici
⬜ Test presenza reale complessi
⬜ Collegamento IPS futuro

---

# 🔄 AGGIORNAMENTO 12 Maggio 2026

# 🔥 MOTORE PRESENZA REALE ALICE — FASE ATTIVA

La roadmap PresenceEngine non è più solo teorica.

È stato creato e collegato:

`alice_presence_engine.dart`

---

# 🧠 NUOVO PRINCIPIO STRUTTURALE

Gli Eventi Alice non devono più decidere direttamente la presenza reale finale.

Gli eventi diventano:

👉 INPUT del PresenceEngine

Il PresenceEngine diventa:

👉 sorgente unica di verità sulla presenza reale di Alice

---

# 🔥 NUOVO MODELLO PRESENZA

Introdotto:

`AlicePresenceState`

Stati attivi:

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Stati futuri:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

# EVENTI TEMPORIZZATI

Gli eventi Alice temporizzati sono ora letti centralmente dal PresenceEngine.

Nuova funzione centrale:

`enabledTimedEventsForDay()`

Obiettivo:

✔ eliminare doppioni nel CoverageEngine  
✔ evitare letture sparse degli eventi  
✔ mantenere una sola verità temporale  

---

# 🔥 EVENTI REALI FAMILIARI

La gestione eventi reali multi-persona è ora completamente integrata nel PresenceEngine.

Caso:

Evento reale con:

- Matteo
- Chiara
- Alice

Risultato corretto:

✔ Alice dentro evento reale  
✔ Alice NON a casa  
✔ nessun falso buco  

---

# 🧠 PRESENZA RELAZIONALE

Il sistema ora distingue realmente:

- Alice a casa
- Alice accompagnata
- Alice sotto supporto
- Alice dentro evento reale
- Alice dentro evento temporizzato

Questa NON è solo copertura.

👉 È presenza fisica reale nel tempo.

---

# 🔥 SUPPORTO REALE

La rete supporto è stata integrata nel PresenceEngine.

Una persona supporto è valida solo se:

✔ attiva  
✔ abilitata nel giorno  
✔ copre tutta la fascia reale  

---

# 🔥 CENTRO ESTIVO — EVOLUZIONE

Il centro estivo non viene più trattato come semplice stato giornata.

Ora il sistema distingue:

1. uscita verso centro estivo  
2. permanenza reale  
3. rientro logistico  
4. casa dopo centro estivo  

---

# FIX IMPORTANTE — CASA DOPO CENTRO ESTIVO

Caso reale corretto:

Prima:

❌ Alice risultava "fuori" troppo a lungo  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ ritorno Alice a casa 16:50  
✔ da lì torna la regola copertura reale  

---

# 🧠 SIGNIFICATO EVOLUTIVO

Il modulo Eventi Alice non rappresenta più:

❌ semplici eventi calendario

Ma:

✔ comportamento reale della presenza Alice  
✔ relazioni Alice ↔ adulti  
✔ spostamenti reali  
✔ ritorni reali  
✔ copertura reale nel tempo  

---

# 📌 STATO ATTUALE REALE

COMPLETATI:

☑ PresenceEngine creato  
☑ modello presenza creato  
☑ supporto reale centralizzato  
☑ eventi temporizzati centralizzati  
☑ eventi reali centralizzati  
☑ CoverageEngine collegato al PresenceEngine  
☑ fix centro estivo reale  
☑ fix casa dopo centro estivo  

RESTA:

⬜ eliminazione doppioni legacy residui  
⬜ pulizia analyzeDayV2()  
⬜ Home completamente guidata dal PresenceEngine  
⬜ test strutturati presenza reale  
⬜ riallineamento IPS futuro  

# 🌍 EVOLUZIONE STRUTTURALE FUTURA — EVENTI FIGLI

## PRINCIPIO

Il modulo "Eventi Alice" rappresenta oggi il primo caso reale di gestione eventi di un figlio.

In futuro il sistema dovrà evolvere verso un modello generico:

- Figlio 1
- Figlio 2
- Figlio 3
- altri membri familiari

senza dipendere dal nome Alice.

---

## DIREZIONE

Gli Eventi Alice devono essere considerati il prototipo del futuro modulo:

👉 Eventi Persona

dove ogni persona della famiglia può avere:

- eventi
- attività
- visite
- sport
- scuola
- impegni

con lo stesso motore.

---

## OBIETTIVO FUTURO

Passare gradualmente da:

Eventi Alice

a:

Eventi Persona

mantenendo compatibilità con il sistema attuale.

---

## ESEMPI FUTURI

- Alice → danza
- Alice → scuola
- Figlio 2 → calcio
- Matteo → visita medica
- Chiara → corso formazione

Tutti gestiti tramite la stessa architettura.

---

## NOTA

Questa NON è una priorità della fase attuale.

Priorità attuale:

✔ completamento calendario reale
✔ consolidamento PresenceEngine
✔ test vita reale

La generalizzazione del modulo verrà affrontata in una fase successiva.