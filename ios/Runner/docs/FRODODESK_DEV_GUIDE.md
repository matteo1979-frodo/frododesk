```text
# FRODODESK — DEVELOPMENT GUIDE

Ultimo aggiornamento: 13 Maggio 2026
(PresenceEngine attivo + consolidamento metodo CNC reale)

Questo documento spiega come lavorare sul progetto FrodoDesk.

Serve per mantenere:

- ordine
- sicurezza
- continuità
- coerenza architetturale

durante lo sviluppo reale del sistema.

---

# PRINCIPIO FONDAMENTALE

La fonte di verità tecnica è sempre:

👉 il codice reale nel progetto

La documentazione guida lo sviluppo, ma:

se docs ≠ codice  
✔ vale SEMPRE il codice

---

# IDENTITÀ DELLO SVILUPPO

FrodoDesk NON viene sviluppato come:

- semplice app Flutter
- semplice calendario
- semplice gestionale

Viene sviluppato come:

👉 simulatore reale della vita familiare

Questo cambia il metodo di sviluppo.

Molte modifiche apparentemente “UI” in realtà sono:

- logica reale
- simulazione temporale
- interpretazione della presenza
- interpretazione relazionale

---

# FILOSOFIA CNC

FrodoDesk segue sviluppo CNC:

👉 Costruzione Non Caotica

Principi:

✔ un passo alla volta
✔ micro-step
✔ test continuo
✔ motore prima
✔ UI dopo
✔ zero modifiche cieche
✔ nessun mega-refactor improvviso

---

# STRUTTURA DOCUMENTAZIONE

La documentazione vive in:

docs/

File principali:

FRODODESK_SYSTEM_STATE.md  
FRODODESK_RULES.md  
FRODODESK_ROADMAP.md  
FRODODESK_PROJECT_MEMORY.md  
FRODODESK_HOME_ROADMAP.md  
FRODODESK_ARCHITECTURE.md

---

# CICLO DI LAVORO

Flusso corretto:

Micro-step
↓
Test reale
↓
Conferma stabilità
↓
Aggiornamento docs
↓
Git + tag
↓
Nuova chat

---

# REGOLA MICRO-STEP

Ogni modifica deve essere:

✔ piccola
✔ isolata
✔ verificabile

Vietato:

❌ modifiche multiple grandi insieme
❌ patch sparse in più moduli senza controllo
❌ refactor enormi senza consolidamento

Obiettivo:

👉 ridurre il rischio di rompere il sistema

---

# REGOLA FILE REALI

Quando si lavora con assistenza AI:

✔ Matteo invia SEMPRE il file reale corrente
✔ Frodo modifica SOLO quel file reale
✔ il file reale resta la fonte di verità

Vietato:

❌ ricostruire file grandi da memoria
❌ ipotizzare contenuti mancanti
❌ inventare porzioni di file

Obiettivo:

👉 0 rischio

---

# REGOLA ANALISI FILE

Quando Matteo invia un file reale:

Frodo deve:

1. leggere il file reale
2. individuare il punto corretto
3. spiegare il primo problema
4. proporre UNA sola modifica
5. attendere test reale

---

# REGOLA “UN PASSO ALLA VOLTA”

Quando Matteo scrive:

- “guarda”
- “controlla”
- “vedi”
- oppure manda screenshot/codice

Frodo deve:

✔ dare un solo passo
✔ aspettare risposta
✔ non anticipare passaggi successivi

---

# REGOLA TEST

Ogni modifica deve essere testata sull’app reale.

Comando standard:

flutter run -d edge --web-port 8080

---

# REGOLA TEST REALI

Le modifiche NON si considerano completate finché:

✔ non sono testate
✔ non sono verificate su casi reali
✔ non sono provate nel calendario reale

---

# REGOLA MOTORE PRIMA DELLA UI

Ordine corretto:

Motore
↓
Store
↓
Engine
↓
Validazione logica
↓
UI

Mai il contrario.

---

# REGOLA PRESENCE ENGINE

(Introdotta Maggio 2026)

La presenza reale di Alice deve essere centralizzata.

Nuova architettura:

AlicePresenceEngine
↓
CoverageEngine
↓
Home / Calendario / IPS

---

# REGOLA CRITICA — NO PATCH SPARSE

Ogni nuova logica relativa a:

- presenza Alice
- eventi Alice
- accompagnamento
- supporto
- segmentazione temporale

deve essere valutata PRIMA dentro:

`alice_presence_engine.dart`

Vietato:

❌ patch dirette sparse in Home
❌ patch dirette sparse nel Calendario
❌ patch dirette sparse nel CoverageEngine

senza verificare prima il PresenceEngine.

---

# REGOLA COVERAGE ENGINE

CoverageEngine NON deve diventare proprietario della presenza Alice.

CoverageEngine deve diventare progressivamente:

✔ consumatore del PresenceEngine
✔ interprete buchi
✔ interprete copertura

e NON:

❌ interprete diretto della presenza Alice

---

# REGOLA CLEANUP LEGACY

Quando si consolida un motore:

NON basta aggiungere nuove funzioni.

Bisogna anche:

✔ eliminare doppioni
✔ eliminare logiche legacy
✔ eliminare vecchi percorsi paralleli

---

# REGOLA SEGMENTAZIONE TEMPORALE

Le fasce temporali devono essere reali.

Esempi:

✔ scuola reale
✔ centro estivo reale
✔ accompagnamento reale
✔ rientro reale
✔ evento reale
✔ supporto reale

Vietato:

❌ blocchi artificiali
❌ giornata “tutta uguale”
❌ presenza implicita non temporale

---

# REGOLA SUPPORTO

Una copertura supporto è valida SOLO se:

supportStart ≤ gapStart
AND
supportEnd ≥ gapEnd

Coperture parziali:

✔ spezzano il buco
❌ NON eliminano automaticamente tutto il problema

---

# REGOLA EVENTI REALI

Evento reale con Alice:

👉 Alice NON è considerata a casa

Il motore deve distinguere:

✔ famiglia insieme fuori
da
❌ Alice sola a casa

---

# REGOLA HOME

La Home NON deve:

❌ ricostruire logiche proprie
❌ interpretare Alice
❌ decidere la presenza

La Home deve:

✔ leggere il sistema
✔ mostrare la verità
✔ mostrare problemi reali
✔ portare al punto corretto

---

# REGOLA IPS

IPS resta rimandato fino a:

1. consolidamento PresenceEngine
2. cleanup CoverageEngine
3. Home guidata dalla stessa verità
4. test reali strutturati

---

# REGOLA RIAPERTURA CHAT

Quando si apre una nuova chat:

1. scrivere:

FRODODESK — RIPRESA SVILUPPO

2. Frodo richiede i docs necessari

3. Matteo invia:
- docs richiesti
- file reale completo

4. Frodo analizza
5. sviluppo riprende in micro-step

---

# REGOLA CHIUSURA CHAT

Alla chiusura:

Matteo scrive:

“Quali file docs dobbiamo aggiornare?”

Frodo:

✔ analizza la chat
✔ richiede SOLO i docs necessari
✔ aggiorna i file completi
✔ conferma quando non serve altro

---

# REGOLA FILE GRANDI / ANTI-TIMEOUT

Per file molto grandi:

esempio:

`lib/screens/calendario_screen_stepa.dart`

si usa metodo a blocchi.

---

# MICRO MODIFICA

Se modifica minima:

✔ modifica chirurgica
✔ solo righe necessarie

---

# MODIFICA STRUTTURALE

Se modifica ampia:

1. Matteo invia file completo
2. Frodo modifica tutto il file
3. Frodo restituisce file completo a blocchi

Formato:

BLOCCO 1
BLOCCO 2
BLOCCO 3

---

# REGOLA OPERATIVA BLOCCHI

Matteo:

✔ svuota file
✔ incolla blocchi in ordine
✔ salva
✔ testa subito

---

# REGOLA CONTINUITÀ DOCUMENTALE

I docs NON devono essere:

❌ ridotti
❌ riassunti
❌ compressi

Devono restare:

✔ memoria viva
✔ coerenti
✔ leggibili
✔ utili per ripartenza chat

---

# REGOLA GIT

Quando il sistema è stabile:

✔ git add .
✔ git commit -m "..."
✔ git push

Per checkpoint importanti:

✔ tag Git obbligatorio

---

# REGOLA CHECKPOINT

Ogni bug critico risolto o passaggio architetturale importante deve avere:

✔ commit chiaro
✔ tag Git dedicato

Obiettivo:

👉 punto di ritorno sicuro

---

# SIGNIFICATO ATTUALE DELLO SVILUPPO

FrodoDesk non sta più costruendo solo schermate.

Sta costruendo:

✔ simulazione reale familiare
✔ presenza temporale reale
✔ presenza relazionale
✔ interpretazione dei problemi
✔ motore decisionale umano-assistito

---

# DIREZIONE ATTUALE

Priorità attuale:

🔥 consolidamento PresenceEngine

NON:

❌ Home avanzata
❌ IPS avanzato
❌ UI estetica
❌ nuove feature caotiche

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — PresenceEngine attivo, CoverageEngine in cleanup progressivo.

Prossimo obiettivo:
👉 eliminare residui legacy presenza Alice
👉 consolidare una sola verità temporale
👉 solo dopo riallineare Home e IPS
```
