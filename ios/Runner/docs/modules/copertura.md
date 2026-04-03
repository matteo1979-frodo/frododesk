# FRODODESK — MODULO COPERTURA

Ultimo aggiornamento: 3 Aprile 2026

---

# IDENTITÀ DEL MODULO

Questo modulo gestisce la **copertura reale della giornata di Alice**.

Obiettivo:

- capire se Alice è coperta o no
- individuare i buchi reali
- supportare decisioni operative

👉 Questo è il cuore decisionale di FrodoDesk

---

# PRINCIPIO FONDAMENTALE

La copertura NON è:

❌ teoria  
❌ calendario  
❌ presenza generica  

👉 È simulazione reale della giornata

---

# CONCETTI BASE

## 1. PRESENZA ≠ LOGISTICA

Distinzione fondamentale:

- **Presenza in casa**
- **Logistica esterna**

Esempio:

- adulto malato a letto:
  - ✔ presenza → sì
  - ❌ logistica → no

---

## 2. ALICE A CASA

Se Alice è a casa:

👉 serve almeno un adulto presente

Se nessuno è presente:

👉 BUCO reale

---

## 3. EVENTI DI ALICE

Gli eventi influenzano la copertura:

- Alice fuori casa → nessun buco in quella fascia
- Alice a casa → serve copertura

⚠️ Questo è il punto chiave per il nuovo modulo Eventi Alice

---

# MOTORE PRINCIPALE

File principale:

👉 `coverage_engine.dart`

Il motore:

- legge turni
- legge eventi
- legge stati (ferie, malattia)
- calcola presenza reale
- calcola buchi

---

# INPUT DEL MOTORE

Il motore utilizza:

- TurnEngine (turni)
- RealEventStore (eventi adulti)
- AliceEventStore (periodi base Alice)
- AliceSpecialEventStore (eventi reali Alice)
- DiseasePeriodStore
- FeriePeriodStore
- SupportNetworkStore
- DaySettingsStore

---

# OUTPUT DEL MOTORE

Il sistema produce:

- ✔ Copertura OK
- ✔ Buchi del giorno
- ✔ Fasce scoperte
- ✔ Stato Sandra (serve/non serve)

---

# LOGICA BUCHI

Un buco esiste quando:

👉 Alice è a casa  
👉 e NON c’è copertura reale

Il sistema restituisce:

- fascia oraria
- causa
- contesto

---

# COPERTURA COMBINATA

Il sistema combina:

- Matteo
- Chiara
- Supporto

👉 anche nei segmenti intermedi

Questo è stato verificato come corretto.

---

# GESTIONE NOTTE / POST-NOTTE

Regola consolidata:

👉 dopo turno notte → indisponibilità fino alle 14:30

Il sistema considera:

- coda notte
- post-notte
- nuova notte

---

# GESTIONE EVENTI TEMPORANEI

Eventi come:

- visite
- appuntamenti

vengono letti come:

👉 blocchi temporanei di indisponibilità

---

# GESTIONE CENTRO ESTIVO

Logica consolidata:

- prima → Alice a casa
- durante → Alice fuori
- dopo → Alice a casa

Centro estivo NON copre tutto il giorno.

---

# STATO ATTUALE DEL MODULO

✔ stabile  
✔ verificato in app reale  
✔ coerente con i casi testati  
✔ combinazione adulti corretta  

👉 considerato affidabile

---

# COLLEGAMENTO CON EVENTI ALICE

STATO ATTUALE:

- eventi Alice esistono
- sono visibili in UI
- influenzano la copertura reale
- modificano buchi e presenza di Alice nella giornata

---

# EVOLUZIONE INTRODOTTA — USCITA ANTICIPATA / PRANZO

Durante questa fase il modulo Copertura è stato raffinato sulla gestione reale dell’uscita anticipata di Alice.

## Principio introdotto

L’uscita anticipata NON genera un unico blocco indistinto.

Il sistema deve distinguere tra:

### 1. BUCO LOGISTICO / RITIRO
Esempio:
- Alice esce alle 12:00
- serve qualcuno che la prenda
- fascia decisionale breve: 12:00–12:20

### 2. COPERTURA CASA SUCCESSIVA
Dopo il ritiro, il sistema deve verificare:

- chi è ancora presente a casa
- fino a che ora
- quando nasce davvero il nuovo buco reale

---

# NUOVA DISTINZIONE STRUTTURALE

👉 **copertura logistica ≠ copertura casa**

Questa distinzione è ora considerata fondamentale nel modulo Copertura.

Esempio reale corretto:

- 12:00–12:20 → buco logistico ritiro
- 12:20–13:00 → casa coperta da genitore presente
- 13:00–14:30 → nuovo buco reale

---

# DECISIONE PRANZO (USCITA ANTICIPATA)

La “Decisione pranzo” ora va letta come:

👉 finestra logistica corta  
👉 non fascia lunga fino al rientro adulto

Regola:

- start = orario uscita anticipata
- end = uscita anticipata + 20 minuti

Esempi:

- uscita 12:00 → decisione pranzo 12:00–12:20
- uscita 13:00 → decisione pranzo 13:00–13:20
- uscita 13:30 → decisione pranzo 13:30–13:50

---

# SANDRA — REGOLA CORRETTA

Sandra NON deve partire automaticamente dall’uscita anticipata in ogni scenario.

Deve servire dal motore:

👉 solo dal primo momento in cui nasce il bisogno reale di copertura

Quindi:

- se nessuno ritira Alice → Sandra può servire dall’uscita anticipata
- se Alice viene ritirata ma poi resta scoperta dopo → Sandra deve partire dal momento reale di scopertura
- se il genitore che ritira Alice poi resta attivo fino alla sera → Sandra a pranzo non deve servire

---

# ESEMPI REALI VALIDATI

## Caso 1 — Nessuno selezionato al ritiro
- uscita anticipata 12:00
- nessuno in Decisione pranzo

Comportamento atteso:
- buco logistico 12:00–12:20
- poi ulteriore verifica della copertura reale
- Sandra può risultare necessaria già da 12:00 se nessuno copre davvero

## Caso 2 — Genitore selezionato al ritiro ma poi va a lavoro
Comportamento atteso:
- sparisce il buco 12:00–12:20
- resta buco successivo nel momento in cui la casa torna scoperta
- Sandra deve servire dal motore solo da quella nuova ora reale

## Caso 3 — Genitore selezionato al ritiro e poi resta disponibile
Comportamento atteso:
- sparisce il buco logistico
- non nasce il buco successivo
- Sandra a pranzo non serve

---

# NOTA STRUTTURALE IMPORTANTE

Durante questa fase è emerso un principio reale molto importante:

👉 un genitore che viene scelto manualmente per prendere Alice può cambiare lo stato reale della giornata

Questa logica va gestita con cautela perché dipende dal tipo di turno:

- notte
- pomeriggio
- mattina
- uscita futura
- riposo post-notte

Questa parte è stata chiarita concettualmente ma va ancora rifinita del tutto nel motore.

---

# BUG RESIDUO APERTO

Stato attuale a fine chat:

⚠️ rimane un bug residuo semplice ma reale nella gestione completa del pranzo/uscita anticipata

Contesto:

- alcuni scenari con turno notte + pomeriggio
- presenza reale del genitore a casa
- necessità di distinguere meglio:
  - ritiro logistico
  - copertura casa
  - attivazione Sandra dal primo momento davvero scoperto

Il sistema è molto più corretto di prima, ma serve ancora una rifinitura finale.

---

# PROSSIMO PASSO UFFICIALE

👉 rifinire definitivamente il comportamento:

- buco logistico uscita anticipata
- copertura reale successiva
- attivazione Sandra dal momento corretto
- nessun falso buco

---

# SIGNIFICATO DEL PASSO

Con questo avanzamento il modulo Copertura ha fatto un salto strutturale:

👉 non ragiona più solo per fasce generiche  
👉 inizia a distinguere tra:

- movimento reale di Alice
- ritiro
- rientro a casa
- copertura vera nel tempo

Questo consolida FrodoDesk come sistema decisionale reale.

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — modulo Copertura quasi allineato sull’uscita anticipata: buco logistico + copertura reale + Sandra. Resta da chiudere il bug residuo finale nella gestione completa della fascia pranzo.