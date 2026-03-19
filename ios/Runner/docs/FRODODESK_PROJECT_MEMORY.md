# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 18 Marzo 2026

## IDENTITÀ DEL PROGETTO

FrodoDesk è un sistema di controllo familiare progettato per simulare la realtà della vita quotidiana e prevenire situazioni di pressione familiare prima che diventino problemi reali.

Non è un semplice calendario o un planner turni.

È un sistema che combina:

- simulazione dei turni
- disponibilità reale delle persone
- eventi familiari
- rete di supporto
- rilevazione automatica dei buchi

per offrire una visione reale della giornata e del futuro.

---

# PERSONE MODELLO

Famiglia principale:

Matteo  
Chiara  
Alice  

Rete di supporto:

Sandra  
altri supporti configurabili

---

# STRATI DEL SISTEMA

Work layer
- turni lavoro
- quarta squadra
- riposo post-notte

Family layer
- eventi Alice
- eventi familiari
- eventi personali

Availability layer
- malattia
- ferie
- override giornalieri

Support layer
- rete supporto
- copertura Sandra

Coverage layer
- rilevazione buchi
- spiegazione copertura

---

# PRINCIPIO DI SVILUPPO

Il calendario deve diventare completamente utilizzabile nella vita reale prima di espandere il sistema.

Solo dopo si svilupperanno altri moduli come finanze, salute e statistiche.

---

# DECISIONI ARCHITETTURALI IMPORTANTI

## Conflitti reali

Il sistema non deve nascondere i conflitti della vita reale.

Quando un evento reale cade dentro un turno di lavoro:

il calendario deve segnalarlo chiaramente come **conflitto reale**.

La risoluzione richiede sempre una decisione umana:

- cambiare turno
- prendere ferie o permesso
- spostare l’evento

Il sistema non decide al posto dell’utente.

---

## Filosofia del calendario

Il calendario FrodoDesk non è solo un calendario eventi.

È una **simulazione operativa della realtà familiare**.

Il suo compito è:

- evidenziare problemi reali
- spiegare perché accadono
- aiutare a prendere decisioni prima che diventino emergenze.

---

# AGGIORNAMENTO — 17 Marzo 2026

## Copertura reale (fix critico validato)

Risolto un caso reale complesso nella gestione della copertura:

Scenario:
- Chiara in ferie
- evento reale Chiara 09:00–10:00
- Matteo presente fino alle 13:00

Problema:
il sistema generava un falso buco “Alice a casa” nonostante la copertura reale fosse continua.

Causa:
la copertura non considerava correttamente la continuità tra Matteo e Chiara nei cambi di presenza durante la giornata.

Soluzione strutturale:
- eventi reali integrati nei busy shifts anche in presenza di ferie/malattia
- segmentazione completa della giornata in micro-fasce temporali
- utilizzo coerente di `isTimeCovered` su copertura combinata multi-persona
- verifica della copertura reale su ogni segmento (non solo sulla fascia intera)

Risultato:
- eliminati i falsi positivi
- copertura coerente con la realtà fisica della giornata
- comportamento stabile anche nei cambi intermedi (staffetta tra persone)

Validazione:
il motore di copertura è stato controllato nei punti critici:

- costruzione busy shifts (turni + eventi reali)
- applicazione override
- logica `_isFasciaCovered`
- funzione `isTimeCovered`
- segmentazione `_uncoveredHomeSegments`

e testato direttamente sull’app reale con esito corretto.

Stato attuale:
la logica di copertura è considerata **affidabile per uso reale**.

---

# AGGIORNAMENTO — 18 Marzo 2026

## Refactor controllato del calendario (inizio fase modulare)

È stata avviata una fase strutturale importante:

👉 alleggerimento controllato del file  
`calendario_screen_stepa.dart`

Motivazione:

- il file ha raggiunto ~5000 righe
- contiene troppe responsabilità insieme:
  - layout
  - UI
  - helper
  - dialog
  - logica ponte

Decisione:

👉 NON spezzare tutto  
👉 procedere con **estrazione chirurgica a rischio zero**

---

## Metodo adottato (CNC rigoroso)

È stato formalizzato il metodo corretto:

1. un solo micro-passo alla volta  
2. nessuna modifica multipla  
3. verifica immediata su app reale  
4. mai modificare parti centrali senza isolamento  
5. prima estrarre elementi “sicuri”  

---

## Fase attiva

### 🥇 FASE 1 — Helper puri

Primo blocco scelto per l’estrazione perché:

- non hanno stato
- non dipendono da widget
- non toccano il motore
- rischio zero

---

## Intervento effettuato

Creato file:

`lib/utils/calendario_formatters.dart`

Contenuto:

- `fmtTimeOfDay(...)`
- `fmtShortDate(...)`

---

## Pulizia del file principale

Rimossi dal calendario:

- `_fmt()`
- `_fmtDate()`
- `_fmtDateTime()`
- `_fmtShortDate()`

Sostituzioni effettuate:

- `_fmt(...)` → `fmtTimeOfDay(...)`
- `_fmtShortDate(...)` → `fmtShortDate(...)`

---

## Metodo tecnico utilizzato

Importante per memoria futura:

👉 NON sostituzione in blocco  
👉 NON refactor automatico

Ma:

- rimozione funzione
- errore controllato
- sostituzione **una chiamata alla volta**
- verifica continua

---

## Risultato

- codice più pulito
- nessuna regressione
- app avviata e funzionante
- primo alleggerimento reale del file calendario riuscito

---

## Nota importante (disciplina di progetto)

Durante il refactor è stata introdotta una modifica non richiesta:

- abbreviazione `_turnLabel` (M/P/N)

Questa modifica è stata:

❌ fuori metodo  
❌ non coerente con il flusso deciso  

Decisione:

👉 ogni modifica UI deve essere **sempre esplicita e confermata dall’utente**

---

## Stato mentale del progetto

Questa fase segna un passaggio importante:

da:
👉 costruzione funzionale

a:
👉 consolidamento + qualità + mantenibilità

---

## Direzione futura

Il refactor continuerà così:

1. completamento helper puri  
2. estrazione dialog  
3. estrazione box semplici  
4. SOLO DOPO eventuale lavoro su card principali  

---

## NUOVE DECISIONI SISTEMA — MARZO 2026

### Alice al seguito (gestione buchi)

Quando si crea un buco perché un genitore ha un evento ma è l’unico disponibile:

👉 il sistema deve offrire una soluzione rapida:

“Porta Alice con te”

Effetto:

- il buco viene risolto
- Alice viene considerata coperta durante l’evento
- alternativa resta rete di supporto

---

### Stati malattia differenziati

Distinzione strutturale:

Malattia leggera:
- persona autonoma
- può accompagnare/prendere Alice
- può muoversi

Malattia a letto:
- persona non autonoma
- non può uscire
- non può coprire attività esterne

---

### Regola override bloccante

Se stato = Malattia a letto:

👉 NON è possibile impostare override di turno

Sistema deve:

- bloccare azione
oppure
- mostrare avviso chiaro

---

### Regola INPS malattia

Durante malattia (leggera o a letto):

Fasce obbligatorie:

- 10:00 – 12:00  
- 17:00 – 19:00  

Sistema deve:

- considerare persona non disponibile in quelle fasce
- segnalare eventuali conflitti
- permettere violazione consapevole

---

### Override consapevole rischio

In presenza di conflitti INPS:

👉 il sistema deve offrire:

“Ignora rischio”

Effetto:

- utente può procedere
- decisione consapevole
- rischio tracciato

---

## Stato attuale

✔ sistema stabile  
✔ copertura affidabile  
✔ refactor avviato correttamente  
✔ nessuna regressione introdotta  
✔ metodo CNC rispettato  

👉 il calendario è ora pronto per:

- uso reale continuativo  
- test su più giorni  
- miglioramenti incrementali controllati