# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 19 Marzo 2026

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

# AGGIORNAMENTO — 19 MARZO 2026

## Consolidamento reale dopo test e rollback controllato

Durante questa fase di lavoro:

- sono stati effettuati test reali su copertura e buchi
- sono stati individuati bug importanti
- è stato eseguito un **ripristino controllato del codice funzionante**
- il sistema è stato riportato allo stato stabile verificato

Decisione metodologica rafforzata:

👉 in caso di dubbio, tornare sempre alla versione stabile reale del codice  
👉 il codice reale resta sempre la fonte di verità

---

## Scoperta importante — comportamento reale del sistema

Sono stati validati due comportamenti fondamentali:

### 1. Coerenza buco reale con eventi

Caso reale:

- Alice a casa (vacanza)
- Chiara appuntamento 16:00–17:25
- Matteo al lavoro

Risultato corretto:

- buco reale: **16:00–17:25**
- sistema ora allineato con la realtà

---

### 2. Copertura Sandra legata allo stato Alice

È stato chiarito un punto fondamentale:

👉 il comportamento di Sandra dipende da:

- Alice a scuola  
- Alice a casa (vacanza / malattia)

Il sistema deve reagire correttamente in entrambi i casi.

---

## BUG STRUTTURALE IDENTIFICATO — EVENTI ALICE

Problema osservato:

- inserendo più periodi (es. vacanza + malattia)
- salvando un nuovo evento
- il sistema può:

  - far sparire un periodo precedente
  - non leggere correttamente lo stato del giorno
  - riportare “Scuola normale” anche quando non dovrebbe

Implicazioni:

- incoerenza tra UI e stato reale
- generazione di buchi scuola non corretti
- perdita di affidabilità nella simulazione

Conclusione:

👉 il sistema eventi Alice NON è ancora robusto  
👉 gestione periodi sovrapposti da rivedere

---

## BUG STRUTTURALE IDENTIFICATO — SANDRA (FASCE)

Comportamento atteso:

Se:

- Alice è a casa (vacanza o malattia)
- entrambi i genitori lavorano

Sandra deve risultare:

- necessaria a **pranzo ✔ (già corretto)**
- necessaria a **mattina ❌ (bug)**
- necessaria a **sera ❌ (bug)**

Fasce coinvolte:

- Mattina: 05:00–06:35  
- Pranzo: 13:00–14:30  
- Sera: 21:00–22:35  

Stato attuale iniziale:

- pranzo → corretto  
- mattina → NON rilevato  
- sera → NON rilevato  

Conclusione iniziale:

👉 logica Sandra non ancora coerente su tutte le fasce  
👉 dipendenza incompleta dallo stato Alice

---

## FIX STRUTTURALE VALIDATO — MODELLO NOTTE / POST-NOTTE

Durante il debug del caso guida del **31 agosto 2026** è emerso che il problema osservato con Alice malata **non nasceva da AliceEventStore** ma dal modo in cui il motore rappresentava il turno `N`.

### Situazione reale chiarita

Nel sistema FrodoDesk, quando una persona ha `N` in un giorno, quel giorno rappresenta contemporaneamente:

- la **coda della notte precedente** `00:00–06:30`
- il **post-notte** con indisponibilità fino alle `14:30`
- la **nuova notte** che riparte la sera `21:00–06:30`

Il modello precedente invece trattava `N` principalmente come notte che parte la sera, aggiungendo il post-notte solo se **ieri** era notte.

### Effetto del bug

Questo poteva far risultare la persona:

- disponibile dopo le `06:30`
- quando invece doveva restare indisponibile fino alle `14:30`

Il bug diventava evidente soprattutto nei casi:

- Alice malata a casa
- Matteo di mattina
- Chiara di notte
- Sandra mattina attivabile correttamente solo sulla prima fascia

### Soluzione implementata

È stata aggiornata la funzione:

- `TurnEngine.busyShiftsForPerson(...)`

Nuova regola consolidata:

👉 **Se un giorno è `N`, il post-notte viene sempre aggiunto come blocco reale `00:00–14:30`, indipendentemente dal contesto Alice.**

Questa è ora una regola strutturale del sistema, non un caso speciale.

### Risultato

Dopo il fix:

- il buco mattina viene rilevato correttamente
- Sandra mattina copre solo la sua finestra reale
- il buco fino alle `14:30` resta correttamente aperto
- il comportamento è tornato coerente tra:
  - Alice a scuola
  - Alice in vacanza
  - Alice malata

### Significato architetturale

Questa correzione non è una rifinitura UI.

È una **correzione di fondazione** del modello turni.

Il sistema ora rappresenta meglio la realtà fisica della notte e del recupero post-notte.

---

## DIREZIONE TECNICA CONSOLIDATA

Prossima fase NON è UI.

Ordine corretto:

1. stabilizzare Eventi Alice  
2. allineare stato giorno ↔ motore  
3. rifinire Sandra mattina/sera  
4. solo dopo tornare su UX/UI

---

## RIFERIMENTO OPERATIVO UFFICIALE

Caso guida per debug:

👉 **31 Agosto 2026**

Motivo:

- Alice a casa (vacanza / malattia)
- possibili sovrapposizioni eventi
- presenza bug Sandra mattina/sera
- presenza bug Eventi Alice
- caso reale che ha fatto emergere il problema notte/post-notte

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
✔ copertura affidabile nei casi verificati  
✔ refactor avviato correttamente  
✔ nessuna regressione introdotta dopo rollback  
✔ metodo CNC rispettato  
✔ modello notte/post-notte corretto nella logica reale  

👉 ma con due blocchi ancora da consolidare:

- Eventi Alice  
- Sandra (mattina/sera)

👉 il calendario è pronto per:

- uso reale continuativo  
- test mirati sui bug identificati  
- miglioramenti incrementali controllati