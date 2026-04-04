# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 4 Aprile 2026

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
- centro estivo

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

# AGGIORNAMENTO — 20 MARZO 2026

## Centro estivo sopra vacanza: entrata nella fase reale

Questa chat ha segnato un passaggio importante del progetto:

👉 il sistema è entrato nel vivo della gestione reale del **centro estivo sovrapposto a vacanza**.

Il punto chiave emerso è questo:

quando Alice ha una vacanza attiva e sopra quella vacanza viene impostato un periodo di centro estivo, il sistema deve ragionare non “per tipo giorno astratto”, ma per **realtà concreta delle fasce**.

Quindi:

- prima dell’inizio del centro estivo → Alice è a casa
- durante il centro estivo → Alice è fuori casa
- dopo la fine del centro estivo → Alice torna a casa
- terminato il centro estivo → deve riemergere correttamente la vacanza sottostante

Questa non è una rifinitura grafica.

È una nuova prova di maturità del motore reale.

---

## Problema reale emerso

Durante i test è emerso che il sistema, con centro estivo sopra vacanza:

- in alcuni casi non allineava bene i “Buchi del giorno”
- poteva mostrare differenze tra:
  - box Buchi del giorno
  - card Copertura Sandra / Babysitter
  - realtà effettiva della presenza Alice
- non sempre ritagliava correttamente le fasce parziali prima e dopo il centro estivo

Tradotto in logica umana:

👉 il sistema rischiava di trattare il centro estivo come se “coprisse tutto il giorno”, oppure di non far tornare correttamente la vacanza appena il centro estivo finiva.

---

## Soluzione implementata

È stata corretta la logica nel `CoverageEngine` in modo che:

- il centro estivo vinca sulla vacanza **solo durante il proprio orario reale**
- i buchi vengano costruiti sulle fasce davvero scoperte
- Sandra venga valutata sulle parti rimaste realmente fuori copertura
- il sistema torni a leggere correttamente Alice “a casa” appena il centro estivo finisce

È stato anche introdotto un passaggio tecnico importante:

- costruzione più precisa delle etichette di fascia ritagliata reale  
  (es. buchi parziali tipo 07:30–08:30 o 13:00–14:30)

---

## Primo caso reale validato

Caso guida corretto e verificato in app reale:

- **Data riferimento:** 17 agosto 2026
- **Turni:** Matteo notte + Chiara pomeriggio
- **Stato Alice:** vacanza con centro estivo sovrapposto

Comportamento corretto osservato:

- prima del centro estivo Alice è letta a casa
- durante il centro estivo Alice non è letta a casa
- dopo la fine del centro estivo il sistema torna a leggere correttamente la vacanza
- i buchi reali tornano coerenti
- la card Sandra e il motore tornano allineati sul caso provato

Questo è il **primo caso reale validato** del blocco centro estivo sopra vacanza.

---

## Stato attuale del blocco centro estivo

✔ un caso reale è corretto  
✔ il motore è entrato in una logica più realistica  
✔ la sovrapposizione centro estivo / vacanza non è più solo teorica  

Ma il blocco NON è ancora da dichiarare chiuso.

Restano da testare obbligatoriamente queste due combinazioni:

1. **Matteo mattina + Chiara notte**
2. **Matteo pomeriggio + Chiara mattina**

Solo dopo questi due test si potrà dire che il blocco centro estivo sopra vacanza è davvero consolidato.

---

## Doppione nei Buchi del giorno

Durante l’ultimo test corretto è emerso un punto aperto non bloccante:

su alcuni casi il sistema può mostrare un doppione logico, ad esempio:

- “Alice a casa: 13:00–14:30”
- “13:00–14:30”

Questo significa che:

- la logica reale è migliorata molto
- ma la presentazione finale del buco va pulita

Decisione:

👉 non blocca la prosecuzione  
👉 va sistemato dopo aver completato i test sulle due combinazioni mancanti

---

## Significato di fase

Questa chat è importante perché segna il momento in cui il sistema non sta più solo “risolvendo bug”, ma sta iniziando a dimostrare di saper leggere **situazioni reali stratificate**:

- vacanza
- centro estivo
- turni reali
- Sandra
- buchi parziali

È un passaggio piccolo all’apparenza, ma molto importante sul piano della maturità del progetto.

---

## Stato attuale

✔ sistema stabile  
✔ copertura affidabile nei casi verificati  
✔ refactor avviato correttamente  
✔ nessuna regressione introdotta dopo rollback  
✔ metodo CNC rispettato  
✔ modello notte/post-notte corretto nella logica reale  
✔ primo caso reale centro estivo sopra vacanza corretto  

👉 ma con blocchi ancora da consolidare:

- centro estivo sopra vacanza (test mancanti su 2 combinazioni)
- doppione Buchi del giorno
- Eventi Alice
- Sandra (mattina/sera)

👉 il calendario è pronto per:

- uso reale continuativo  
- test mirati sui blocchi ancora sensibili  
- miglioramenti incrementali controllati
---

# AGGIORNAMENTO — 21 MARZO 2026

## BLOCCO CENTRO ESTIVO SOPRA VACANZA — CHIUSO

Durante questa chat il blocco:

centro estivo sopra vacanza

è stato testato e verificato direttamente in app reale.

### Risultato

- comportamento corretto prima del centro estivo → Alice a casa  
- comportamento corretto durante il centro estivo → Alice fuori casa  
- comportamento corretto dopo il centro estivo → ritorno alla vacanza  
- buchi del giorno coerenti  
- nessuna incoerenza tra motore e card Sandra  

### Decisione

Il blocco è considerato **chiuso e stabile per uso reale**.

---

## EVENTI ALICE — BLOCCO CONSOLIDATO

Il lavoro successivo ha confermato che il sistema eventi Alice è tornato coerente nella pratica reale.

### Situazione consolidata

- stato del giorno letto correttamente
- coerenza recuperata tra periodi e comportamento reale del motore
- allineamento corretto tra:
  - AliceEventStore
  - UI della card Alice/Scuola
  - CoverageEngine

### Decisione

Il blocco Eventi Alice, che in precedenza risultava sensibile, è ora da considerare **stabilizzato per uso reale**.

---

## SANDRA — FASCE MATTINA / PRANZO / SERA CONSOLIDATE

Anche il comportamento Sandra è stato riportato a coerenza strutturale.

### Situazione consolidata

Quando Alice è a casa e i genitori non sono disponibili, il sistema ora richiede correttamente Sandra su tutte le fasce rilevanti:

- mattina ✔
- pranzo ✔
- sera ✔

Questo chiude il problema aperto emerso nel caso guida del 31 agosto 2026.

### Decisione

Il blocco Sandra sulle fasce operative è ora da considerare **stabilizzato per uso reale**.

---

## Punto aperto (non bloccante)

Doppione nei “Buchi del giorno”:

esempio:
- Alice a casa: 13:00–14:30  
- 13:00–14:30  

Significato:

- il motore è corretto  
- il problema è solo di visualizzazione  

### Decisione

Rimandato alla fase UI (pulizia output).

---

## STATO UX/UI — PRIMA OTTIMIZZAZIONE REALE COMPLETATA

Durante questa chat è iniziata davvero la fase UX/UI, senza toccare il motore logico.

### Intervento reale eseguito

Nel file:

`calendario_screen_stepa.dart`

sono state introdotte modifiche sicure e verificate in app reale:

- sezioni principali comprimibili
- header cliccabile sulle sezioni
- icona espandi/comprimi
- contenuto nascosto quando la sezione è chiusa
- padding più compatto quando la sezione è chiusa
- “REALTÀ DEL GIORNO” aperta di default
- “COPERTURA ALICE” chiusa di default

### Verifica reale

Test effettuato con esito corretto:

- la sezione “REALTÀ DEL GIORNO” si apre e si chiude correttamente
- la sezione “COPERTURA ALICE” si apre e si chiude correttamente
- la schermata risulta più leggibile
- lo scroll iniziale è ridotto
- nessuna regressione osservata nel comportamento del calendario

### Significato della fase

Questo passaggio segna l’inizio concreto della nuova fase:

👉 non più fondazione motore  
👉 ma miglioramento dell’uso quotidiano reale

---

## Stato del sistema a fine chat

- motore copertura stabile  
- centro estivo consolidato  
- Eventi Alice stabilizzati  
- Sandra coerente su tutte le fasce  
- nessuna regressione osservata  
- prima ottimizzazione UX/UI completata e verificata  
- calendario utilizzabile per test reali continuativi  

---

## Prossima fase

Miglioramento UX/UI:

- riduzione scroll  
- card compatte  
- apertura/chiusura sezioni  
- accesso rapido alle modifiche (tap diretto su Matteo / Chiara / Alice / Copertura)
---

# AGGIORNAMENTO — 21 MARZO 2026 (CONSOLIDAMENTO FASE REALE)

## Cambio di fase del progetto

Con questa chat FrodoDesk entra ufficialmente in una nuova fase:

👉 da correzione e stabilizzazione motore  
👉 a utilizzo reale continuativo + ottimizzazione UX/UI

Questo segna un passaggio strutturale importante:

il calendario non è più “in costruzione fragile”  
ma diventa uno strumento utilizzabile nella vita reale.

---

## Stato dei blocchi principali

Dopo le ultime verifiche in app reale, i seguenti blocchi sono da considerare consolidati:

### Copertura reale

- combinazione Matteo + Chiara stabile  
- gestione eventi reali integrata correttamente  
- nessun falso positivo nei casi testati  
- comportamento coerente anche nei cambi intermedi  

👉 stato: **affidabile per uso reale**

---

### Modello notte / post-notte

- rappresentazione reale della notte completata  
- indisponibilità fino alle 14:30 sempre rispettata  
- coerenza mantenuta su tutti gli stati Alice  

👉 stato: **fondazione corretta del sistema turni**

---

### Centro estivo sopra vacanza

- gestione per fasce reali (prima / durante / dopo)  
- ritorno corretto alla vacanza sottostante  
- buchi coerenti con la realtà  

👉 stato: **consolidato**

---

### Eventi Alice

- stato del giorno coerente  
- gestione periodi stabile  
- allineamento UI ↔ store ↔ motore  

👉 stato: **stabilizzato per uso reale**

---

### Sandra (copertura)

- attivazione corretta su tutte le fasce:
  - mattina  
  - pranzo  
  - sera  

👉 stato: **coerente con la realtà**

---

## Significato architetturale

Il sistema ha raggiunto un punto chiave:

👉 la simulazione della giornata è credibile  
👉 le decisioni possono essere prese sulla base del sistema  

Questo è il primo vero momento in cui FrodoDesk smette di essere:

- un insieme di logiche  
e diventa:
- un sistema decisionale utilizzabile

---

## Inizio fase UX/UI

Per la prima volta si è intervenuti sull’interfaccia senza toccare il motore.

Intervento:

- sezioni comprimibili  
- header cliccabili  
- layout più compatto  

Risultato:

- migliore leggibilità  
- riduzione dello scroll  
- nessuna regressione  

👉 questa è la direzione della nuova fase

---

## Regola consolidata della nuova fase

Da ora in avanti:

👉 il motore NON si tocca se non per bug reali  
👉 le modifiche principali sono su utilizzo e leggibilità  

---

## Problemi ancora aperti (non bloccanti)

### Doppione “Buchi del giorno”

- duplicazione visiva della stessa fascia  
- problema solo di presentazione  

👉 da risolvere nella fase UI

---

## Direzione operativa aggiornata

Prossimi passi corretti:

1. migliorare UX/UI  
2. rendere il calendario sempre più rapido da usare  
3. test prolungati nella vita reale  
4. individuare eventuali nuovi casi limite  

---

## Stato del progetto

✔ sistema stabile  
✔ motore affidabile  
✔ calendario utilizzabile davvero  
✔ base pronta per evoluzione  

👉 FrodoDesk entra nella fase di utilizzo reale continuo

🔥 AGGIORNAMENTO — 23 MARZO 2026 (UI + STABILITÀ LOGICA CONFERMATA)
Verifica reale in app

Durante questa fase è stata eseguita una verifica diretta sull’app con:

inserimento eventi reali
assegnazione corretta persona evento
verifica conflitto turno ↔ evento
verifica copertura Alice
Caso testato
evento reale “visita Matteo” inserito correttamente
evento assegnato a Chiara con nota “accompagnare Matteo”
conflitto turno visibile correttamente
nessun buco generato (Alice a scuola)
Risultato

👉 sistema coerente con la realtà
👉 nessun falso buco
👉 conflitto correttamente rilevato

Chiarimento importante — MALATTIA A LETTO

È stata confermata una regola fondamentale:

👉 Malattia a letto = adulto presente in casa

MA:

NON disponibile per logistica esterna
NON può accompagnare/prendere Alice
MA copre la presenza in casa
Implicazione nel motore
se Alice è a casa → NON genera buco presenza
se serve accompagnamento scuola → genera buco

👉 distinzione chiave tra:

presenza in casa ✔
copertura logistica ❌

Questa distinzione è confermata come fondamentale per il sistema.

Stato reale della fase

Questa chat NON è stata una fase di sviluppo nuovo codice.

👉 È stata una fase di:

verifica reale sistema
validazione comportamento logico
conferma coerenza motore
Decisione

👉 il motore di copertura è confermato stabile anche nei casi:

eventi reali + turni
conflitti reali
malattia a letto
Alice a scuola vs Alice a casa
Direzione immediata

Il lavoro in corso NON è:

❌ stabilità logica (già raggiunta)

MA:

👉 UX/UI e organizzazione della schermata

Indicazione UI emersa

Problema reale:

👉 colonna troppo lunga nella sezione “REALTÀ DEL GIORNO”

Decisione già emersa:

👉 suddivisione futura in 3 blocchi:

Realtà del giorno
Alice / Scuola
Buchi del giorno

⚠️ NON implementata ancora
👉 rimandata a fase UI

Stato finale della chat

✔ motore stabile
✔ comportamento reale verificato
✔ nessun bug logico emerso
✔ sistema coerente con la vita reale

👉 fase attuale: UX/UI e organizzazione schermata

Prossima ripartenza corretta

La prossima chat NON riparte da bug o logica.

Riparte da:

👉 miglioramento UI calendario
👉 gestione spazi e leggibilità
👉 organizzazione blocchi

📌 IMPORTANTE (continuità progetto)

Questa chat conferma definitivamente che:

👉 la fase “stabilità logica calendario” è chiusa
---

# AGGIORNAMENTO — 24 MARZO 2026

## NUOVA REGOLA PRATICA DI SVILUPPO SU FILE GRANDI

Durante il lavoro reale su `calendario_screen_stepa.dart` è emerso in modo definitivo un problema operativo:

quando il file diventa molto lungo, la risposta completa in un unico messaggio può diventare instabile e interrompersi prima della consegna completa.

Questo non è un problema teorico ma un caso reale emerso durante lo sviluppo.

### Effetto pratico osservato

- Matteo riesce a inviare il file completo reale
- Frodo riesce a lavorarci
- ma la restituzione in un solo messaggio può andare in timeout o interrompersi

Questo rompe il flusso CNC e crea frustrazione operativa.

---

## Decisione consolidata

Da ora in poi il metodo corretto è questo:

### Se la modifica è piccola
si continua con micro-step chirurgico normale.

### Se la modifica è strutturale su file grande
si usa il metodo:

1. Matteo invia il file reale completo  
2. Frodo lavora sull’intero file  
3. Frodo restituisce il file completo spezzato in più blocchi ordinati  

Formato pratico:

- BLOCCO 1
- BLOCCO 2
- BLOCCO 3

Matteo:

- cancella il file originale
- incolla i blocchi nell’ordine
- salva
- testa subito in app reale

---

## Validazione reale del metodo

Questo metodo è stato verificato nella pratica come la strada più affidabile per continuare a lavorare su FrodoDesk su file molto grandi senza perdere continuità.

Principio consolidato:

👉 meglio più blocchi completi e stabili che una risposta unica troncata

---

## Stato UI emerso nella pratica reale

Dopo la nuova organizzazione della schermata calendario è emerso chiaramente che la direzione è giusta, ma la pagina non è ancora abbastanza compatta per l’uso reale quotidiano.

### Osservazione reale dell’utente

La schermata è risultata:

- più chiara di prima
- ma ancora troppo lunga
- ancora troppo pesante in alcune sezioni

---

## Decisione UX/UI consolidata

La nuova direzione confermata è:

- ridurre ancora la lunghezza visiva
- chiudere i blocchi di default
- usare sempre di più sezioni espandibili / comprimibili
- trasformare le liste lunghe in componenti apri/chiudi

Questo è ormai parte della filosofia pratica di utilizzo reale del calendario.

---

## Prossimo passo ufficiale

La prossima ripartenza corretta NON è su logica motore.

La prossima modifica ufficiale da fare è:

### Periodi salvati Alice → blocco espandibile / collapsable

Motivazione:

- la lista dei periodi salvati Alice cresce troppo in altezza
- se vengono aggiunti più eventi, la schermata diventa lunga e scomoda
- serve una UI che permetta di aprire/chiudere quella sezione solo quando necessario

### Decisione operativa

Il prossimo step corretto è:

- rendere “Periodi salvati Alice” apribile/chiudibile
- mantenere l’informazione disponibile
- ridurre la lunghezza verticale della schermata

---

## Significato di fase

Questa fase conferma una cosa molto importante:

👉 la stabilità logica del calendario è ormai considerata chiusa  
👉 la fase attuale è uso reale + miglioramento usabilità + controllo visivo della complessità
---

# 🔥 AGGIORNAMENTO — 24 MARZO 2026 (PERMESSO COME AZIONE RAPIDA + CHIAREZZA TURNI)

## Evoluzione UX del Permesso

Durante questa chat è emersa una decisione importante sull’interpretazione del **Permesso** nel sistema.

### Chiarimento strutturale

Il permesso NON è uno stato della persona (come malattia o ferie).

👉 È una **azione operativa sulla giornata**, simile a:

- cambio turno
- nuova rotazione
- quarta squadra

### Decisione applicata

Il permesso è stato:

- tolto dal concetto di “stato giornaliero”
- spostato nella card **Turni**
- reso accessibile tramite bottone dedicato

---

## Nuovo comportamento reale del Permesso

Ora il sistema funziona così:

- bottone: **Apri permessi**
- apertura pannello con:
  - Matteo
  - Chiara
- per ogni persona:
  - bottone **Permesso**
  - apertura popup orario
  - visualizzazione orario sotto
  - bottone **Rimuovi permesso**

---

## Validazione reale in app

Test effettuato:

- inserito permesso su Chiara (21:00–22:00)
- visualizzazione immediata nella card Turni:
  - “Stato: Permesso 21:00–22:00”
- rimozione funzionante
- aggiornamento UI immediato

👉 risultato:

✔ comportamento naturale  
✔ rapido  
✔ coerente con uso reale  

---

## Miglioramento leggibilità Turni

È stata introdotta anche una maggiore chiarezza nella lettura dei turni.

Ora il sistema rende più evidente:

👉 da dove deriva il turno mostrato

(es: quarta squadra, nuova rotazione, ecc.)

Questo elimina ambiguità nell’uso quotidiano.

---

## Significato della modifica

Questa modifica non è estetica.

È una evoluzione importante del sistema:

- separa **stato persona** da **azione operativa**
- riduce confusione mentale
- aumenta velocità di utilizzo reale
- migliora la leggibilità immediata della giornata

---

## Stato della fase

👉 motore stabile  
👉 UX in evoluzione  
👉 sistema sempre più vicino all’uso reale quotidiano  

---

## Direzione confermata

Il lavoro continua su:

- semplificazione UI
- riduzione scroll
- accesso rapido alle azioni
- leggibilità immediata

---

## Prossimo passo (confermato)

### Periodi salvati Alice → blocco espandibile / collapsable

Obiettivo:

- ridurre altezza schermata
- evitare liste lunghe
- migliorare usabilità reale

---

# 🔥 AGGIORNAMENTO — 24 MARZO 2026 (PERIODI SALVATI ALICE COLLAPSABLE + BANNER STATO ALICE)

## Evoluzione della lettura visiva di Alice

Durante questa chat è emersa una decisione importante sulla gerarchia visiva del blocco **Alice / Scuola**.

### Chiarimento strutturale

Lo stato reale dominante di Alice nella giornata non deve essere nascosto dentro:

- periodi salvati
- buchi del giorno
- dettagli secondari

👉 Deve essere visibile **subito**, in cima alla card **Alice / Scuola**

Decisione consolidata:

- il banner stato Alice NON va sotto i controlli scuola
- il banner stato Alice NON va vicino ai toggle operativi
- il banner stato Alice va **all’inizio della card**, come contesto dominante della giornata

Questo è coerente con la filosofia FrodoDesk:

👉 prima si vede la realtà  
👉 poi si leggono i dettagli operativi

---

## Periodi salvati Alice — comportamento collapsable completato

Il blocco “Periodi salvati Alice” era già stato trasformato in sezione apri/chiudi, ma il comportamento non era ancora perfettamente coerente:

- da chiuso poteva comparire comunque il messaggio:
  - “Nessun periodo salvato”

### Correzione completata

Nel widget `alice_event_panel.dart` è stata rifinita la logica in modo che:

- blocco chiuso → nessun contenuto visibile
- blocco aperto + nessun periodo → compare “Nessun periodo salvato”
- blocco aperto + periodi presenti → compare la lista completa

### Significato della modifica

Questo rende finalmente coerente la decisione UX:

👉 un blocco chiuso deve davvero alleggerire la schermata

e non occupare spazio inutile.

### Risultato reale

Testato in app reale con esito corretto:

- schermata più corta quando il blocco è chiuso
- contenuto visibile solo quando richiesto

---

## Banner “Stato Alice” introdotto nella card Alice / Scuola

È stato introdotto un nuovo elemento visivo in cima alla card **Alice / Scuola** che mostra immediatamente l’evento Alice dominante attivo sul giorno.

### Esempi di stato ora leggibili subito

- Vacanza
- Malattia
- Centro estivo
- Scuola chiusa

### Principio consolidato

Il colore NON rappresenta solo il nome tecnico dell’evento.

👉 rappresenta l’impatto reale sulla giornata

Decisione cromatica consolidata emersa in chat:

- **Malattia** → rosso
- **Scuola chiusa** → arancione
- **Vacanza** → teal
- **Centro estivo** → verde

Questo migliora moltissimo il colpo d’occhio:

- si capisce subito **perché** la giornata è diversa
- si collega più facilmente lo stato Alice ai buchi e alle decisioni
- la realtà del giorno viene letta prima ancora dei dettagli

### Significato architetturale

Questa non è una modifica grafica secondaria.

È una evoluzione importante della capacità del sistema di:

- spiegare la giornata
- mostrare il contesto dominante
- ridurre il carico mentale dell’utente

---

## Nuova direzione emersa — Buchi del giorno più intelligenti

Durante la stessa chat è emersa una nuova direzione concettuale chiara.

Dopo aver reso visibile il banner stato Alice, il passo successivo naturale è questo:

👉 portare la causa evento Alice anche dentro **“Buchi del giorno”**

Esempio desiderato:

- “Alice a casa (Vacanza): 13:00–14:30”
- “Alice a casa (Malattia): 13:00–14:30”

### Decisione di posizione

Questa spiegazione va:

- **dentro “Buchi del giorno”**

e NON va:

- dentro “Rischio Alice a casa”

Motivo:

- “Rischio Alice a casa” deve restare un segnale pulito del motore
- “Buchi del giorno” è il punto giusto per la spiegazione umana del problema

⚠️ Importante:

questa evoluzione è stata **decisa concettualmente**
ma **non ancora implementata** in questa chat.

---

## Stato della fase

Con questa chat la direzione UX/UI del calendario diventa ancora più matura:

- meno altezza inutile
- più chiarezza immediata
- migliore legame tra causa reale e lettura della giornata

👉 il sistema continua a evolvere non nel motore, ma nella sua capacità di farsi capire al volo nella vita reale
---

## 🔥 AGGIORNAMENTO — 25 MARZO 2026 (PORTA ALICE DINAMICO)

### Nuova capacità del sistema

Introdotta gestione dinamica e reversibile della soluzione:

👉 “Porta Alice con [persona]”

### Principio

Il sistema NON deve mai:

- applicare soluzioni definitive non reversibili
- nascondere la realtà originale (buco)

Il sistema deve:

- proporre una soluzione
- permettere attivazione
- permettere disattivazione
- ripristinare lo stato reale originale

### Comportamento consolidato

- il sistema identifica la persona realmente disponibile
- il bottone è contestuale (Matteo / Chiara)
- attivando:
  - il buco viene risolto
- disattivando:
  - il buco torna visibile

### Significato per FrodoDesk

Questo introduce un concetto fondamentale:

👉 le azioni sono **simulazioni operative reversibili**

Non sono:

- modifiche strutturali permanenti
- automatismi nascosti

### Stato

✔ implementato  
✔ testato in app reale  
✔ comportamento coerente con la filosofia del sistema  

---

# 🔥 AGGIORNAMENTO — 4 APRILE 2026

## Refactor reale della sezione “Realtà del giorno”

Durante questa chat è stato fatto un salto importante nella leggibilità reale del calendario, senza toccare la logica di base del motore.

La direzione emersa è stata questa:

👉 nella sezione **Realtà del giorno** devono restare subito visibili solo le informazioni da leggere al volo  
👉 tutto ciò che è azione/configurazione deve essere compatto e apribile solo quando serve

Questa distinzione è diventata un principio strutturale della UI FrodoDesk.

---

## Ferie lunghe — evoluzione completa della UI

Il pannello `FeriePeriodPanel` è stato trasformato nello stesso linguaggio visivo di `DiseasePeriodPanel` e della parte evoluta di Alice.

### Prima
- lista semplice
- lettura piatta
- nessuna gerarchia visiva
- persona filtrata nel dropdown
- poca percezione dello stato attivo

### Dopo
- pannello collassabile
- card singole espandibili
- visualizzazione di tutti i periodi salvati
- occhio 👁 sul periodo attivo rispetto al giorno selezionato
- pulsanti **Modifica** / **Rimuovi**
- formato data coerente col resto del sistema (`gg-mm-aaaa`)

### Significato
Questo non è solo un miglioramento estetico.

👉 il sistema ora mostra meglio la realtà attiva e riduce il carico mentale  
👉 ferie e malattia parlano finalmente lo stesso linguaggio visivo

---

## Malattia a periodo — evoluzione completa della UI

Anche `DiseasePeriodPanel` è stato portato a una forma molto più leggibile e coerente con il resto del calendario.

### Evoluzione introdotta
- pannello collassabile
- card singole espandibili
- segnale visivo del periodo attivo sul giorno selezionato
- pulsanti **Modifica** / **Rimuovi**
- struttura coerente con Alice e Ferie

### Significato
Matteo può ora leggere rapidamente:
- chi è malato
- di che tipo di malattia si tratta
- se quel periodo è attivo oggi
- ed eventualmente modificarlo senza caos

Questo conferma un nuovo standard visivo FrodoDesk:

👉 lista lunga piatta = da evitare  
👉 card vive, richiudibili, leggibili al volo = strada corretta

---

## Turni — separazione realtà / azione

Il cambiamento più importante di questa chat riguarda la card **Turni**.

### Osservazione reale emersa
La parte alta della card era corretta e piacevole:

- Matteo
- Chiara
- turno
- stato reale
- eventi / conflitti

Ma la parte sotto era diventata un muro di bottoni:

- cambio turno
- cambio turno periodo
- nuova rotazione
- quarta squadra
- permessi
- rimozione rotazione attiva

Questo occupava troppo spazio e mescolava la realtà con gli strumenti operativi.

### Decisione applicata
È stato introdotto un nuovo blocco collassabile:

👉 **Gestione turni e rotazioni**

Dentro questo blocco vivono ora i comandi operativi:

- cambio turno (solo oggi)
- cambio turno (periodo)
- nuova rotazione
- quarta squadra
- permessi
- rimuovi nuova rotazione attiva

### Significato architetturale
Questa modifica è molto più importante di quanto sembri.

Da ora in poi la card Turni separa:

### sopra = realtà
- cosa sta succedendo oggi
- chi lavora
- chi è in ferie o malattia
- quali eventi/conflitti esistono

### sotto = azione
- cosa posso fare per cambiare la realtà

Questa è una decisione strutturale molto forte nella filosofia FrodoDesk:

👉 prima si legge  
👉 poi si agisce

### Effetto pratico
- meno rumore visivo
- maggiore scalabilità futura
- spazio pronto per evoluzioni (es. quinta squadra)
- uso più naturale nella vita reale

---

## Nuova decisione strategica — passaggio a Livello B

A fine chat è stata presa una decisione di fase molto importante.

FrodoDesk non deve più essere solo:

- uno strumento operativo potente
- una UI che mostra realtà e comandi

Deve iniziare a diventare anche:

👉 un sistema che **guida** nelle decisioni

### Significato del Livello B
Il sistema deve iniziare a proporre:

- quali azioni hanno senso
- quali alternative esistono
- quale scelta è coerente con il problema rilevato

Senza decidere al posto dell’utente.

### Esempio target
Se esiste un conflitto reale tra:

- turno
- evento
- copertura

il sistema dovrà iniziare a mostrare qualcosa tipo:

👉 Azioni consigliate:
- cambia turno
- prendi permesso
- sposta evento
- porta Alice con te

### Principio confermato
FrodoDesk NON diventa un sistema automatico.

Resta confermato il principio:

👉 il sistema suggerisce  
👉 la decisione resta umana

Ma entra in una nuova fase:

👉 da strumento operativo  
👉 a **motore decisionale assistito**

---

## Stato della fase a fine chat

Con questa chat la UI del calendario ha fatto un salto importante:

- Ferie coerenti
- Malattia coerente
- Turni più puliti
- Realtà del giorno più leggibile
- separazione netta realtà / azione

E soprattutto è stata definita la prossima direzione ufficiale del progetto:

👉 costruzione del primo blocco **Azioni consigliate**  
👉 sopra i Turni  
👉 con primo caso semplice:
- conflitto turno + evento

---

## Direzione corretta della prossima chat

La prossima chat NON riparte da bug.

Riparte da:

- Livello B
- primo blocco decisionale
- “Azioni consigliate”
- mantenendo la logica fuori dalla UI
- partendo da un caso semplice e leggibile