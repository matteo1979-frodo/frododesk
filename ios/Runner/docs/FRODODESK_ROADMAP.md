FRODODESK — ROADMAP

Ultimo aggiornamento: 14 Maggio 2026  
(BLOCCO G — Consolidamento avanzato PresenceEngine)

---

# OBIETTIVO GENERALE

FrodoDesk deve diventare un sistema di controllo familiare che simula la realtà della vita quotidiana per aiutare a prevenire problemi prima che accadano.

Lo sviluppo segue filosofia CNC:

- un passo alla volta
- blocchi stabili prima di passare al successivo
- motore prima
- UI dopo
- test reale continuo
- decisione sempre umana

---

# STATO GENERALE ATTUALE

🔥 CALENDARIO REALE COMPLETO  
🔥 COPERTURA REALE STABILE  
🔥 HOME COERENTE  
🔥 STATISTICHE AVVIATE  
🔥 MOTORE PRESENZA REALE ALICE IN CONSOLIDAMENTO AVANZATO

Il sistema ha fatto il passaggio da:

❌ calendario intelligente

a

✔ simulazione reale della presenza familiare

---

# CRITERI DI MATURITÀ DEL CALENDARIO

✔ Persistenza dati completa  
✔ Eventi reali gestiti correttamente  
✔ Conflitti gravi rilevati  
✔ Visione futura reale  

👉 STATO: RAGGIUNTI

---

# BLOCCO A — FONDAMENTA SISTEMA

Stato: COMPLETATO

---

# BLOCCO B — SPIEGAZIONE REALTÀ

Stato: COMPLETATO

---

# BLOCCO C — EVENTI REALI

Stato: COMPLETATO

✔ Eventi reali funzionanti  
✔ Conflitti funzionanti  
✔ Permessi operativi  
✔ Copertura integrata  
✔ Eventi multi-persona funzionanti  

---

# BLOCCO D — CALENDARIO REALE

Stato: COMPLETATO / USO REALE

✔ Sistema utilizzabile nella vita reale  
✔ Motore stabile  
✔ Copertura affidabile  
✔ Home collegata al calendario  
✔ Navigazione giorno funzionante  

---

# BLOCCO E — SCUOLA

Stato: COMPLETATO

✔ SchoolStore funzionante  
✔ Periodi scuola funzionanti  
✔ Settimana modificabile  
✔ Motore collegato  
✔ Stato Alice corretto  
✔ Support network verificato  
✔ Ingresso/uscita reali funzionanti  
✔ Rientro automatico funzionante  

---

# BLOCCO F — COPERTURA REALE

Stato: COMPLETATO / CONSOLIDATO

---

## SIGNIFICATO

Alice NON dipende più solo dalle fasce Sandra.

La copertura viene calcolata sulla realtà:

- Alice a casa
- adulti presenti
- eventi reali
- scuola
- centro estivo
- supporto
- accompagnamento
- rientro a casa

---

## REGOLE DEFINITIVE

✔ Alice a casa → serve copertura sempre  
✔ Nessun adulto/supporto valido → BUCO reale  
✔ Controllo su tutta la giornata reale  
✔ Eventi reali influenzano la copertura  
✔ Supporto integrato nel motore  
✔ Sandra resta categoria separata dalla rete supporto  

---

## RISULTATO

✔ Buchi reali corretti  
✔ Calendario coerente  
✔ Home coerente  
✔ Sistema affidabile nella vita reale  

---

# BLOCCO G — MOTORE PRESENZA REALE ALICE

Stato: CONSOLIDAMENTO AVANZATO

---

## OBIETTIVO

Centralizzare la domanda fondamentale:

👉 “Dove si trova realmente Alice in questa fascia?”

Il sistema deve distinguere:

- Alice a casa
- Alice a scuola
- Alice al centro estivo
- Alice dentro evento temporizzato
- Alice dentro evento reale
- Alice accompagnata
- Alice coperta da supporto
- Alice fuori con famiglia
- futura autonomia

---

## COMPONENTI CREATI

✔ `alice_presence_engine.dart`  
✔ `AlicePresenceState`  

---

## STATI PRESENZA ATTUALI

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Mancano:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

## COMPLETATI NEL BLOCCO G

☑ creare `alice_presence_engine.dart`  
☑ creare `AlicePresenceState`  
☑ centralizzare primo stato presenza Alice  
☑ collegare CoverageEngine al motore presenza  
☑ centralizzare evento reale Alice  
☑ centralizzare evento temporizzato Alice  
☑ introdurre `AlicePresenceState.accompanied`  
☑ collegare `AliceCompanionStore`  
☑ introdurre presenza relazionale  
☑ introdurre `findCompanionForRange()`  
☑ CoverageEngine legge `stateForRange()`  
☑ introdurre `AlicePresenceState.support`  
☑ collegare `SupportNetworkStore`  
☑ collegare `DaySettingsStore`  
☑ distinguere supporto reale attivo sulla fascia  
☑ scuola resa temporale reale  
☑ centro estivo reso temporale reale  
☑ fix centro estivo: uscita 16:30–16:50  
☑ fix casa dopo centro estivo: buco reale 16:50–21:00  
☑ buchi coerenti con supporto reale e Sandra  
☑ centralizzare accesso eventi temporizzati Alice  
☑ centralizzare copertura rete supporto  
☑ centralizzare controllo evento reale Alice  
☑ CoverageEngine ridotto a consumatore progressivo del PresenceEngine  

☑ centralizzare accompagnamento Alice nel PresenceEngine  
☑ aggiungere `isAliceAccompaniedDuringRange()`  
☑ aggiungere `aliceCompanionEndForRange()`  
☑ CoverageEngine non legge più direttamente CompanionStore in `_isFasciaCovered()`  
☑ CoverageEngine non legge più direttamente CompanionStore in `_uncoveredHomeSegments()`  
☑ CoverageEngine non legge più direttamente CompanionStore nel filtro finale `analyzeDayV2()`  
☑ eliminata funzione legacy `_getAliceCompanionEnd()`  
☑ fix duplicazione buchi legacy con supporto reale parziale  
☑ supporto reale segmentato funzionante  

---

## STEP G2 — MODELLO PRESENZA UNICO

Stato: QUASI COMPLETATO

Attuale:

☑ home  
☑ school  
☑ timedEvent  
☑ realEvent  
☑ summerCamp  
☑ accompanied  
☑ support  

Mancano:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

## STEP G3 — CoverageEngine guidato dal PresenceEngine

Stato: CONSOLIDAMENTO AVANZATO

---

### FATTO

☑ `isAliceAtHomeDay()` passa da PresenceEngine  
☑ `isAliceSchoolNormalDay()` passa da PresenceEngine  
☑ `isAliceSummerCampOperationalDay()` passa da PresenceEngine  
☑ `getAliceEventTypeForDay()` passa da PresenceEngine  
☑ `getSummerCampPeriodForDay()` passa da PresenceEngine  
☑ `getSummerCampConfigForDay()` passa da PresenceEngine  
☑ `getSummerCampSpecialEventForDay()` passa da PresenceEngine  
☑ `hasSummerCampSpecialEventForDay()` passa da PresenceEngine  
☑ `enabledTimedEventsForDay()` passa da PresenceEngine  
☑ `_isCoveredBySupportNetwork()` passa da PresenceEngine  
☑ `_isAliceInsideRealEvent()` passa da PresenceEngine  

☑ accompagnamento Alice centralizzato  
☑ overlap accompagnamento centralizzato  
☑ companion end centralizzato  
☑ support network reale centralizzato  
☑ eventi reali Alice centralizzati  
☑ eventi temporizzati Alice centralizzati  

☑ CoverageEngine non legge più direttamente CompanionStore  
☑ eliminata funzione legacy `_getAliceCompanionEnd()`  

☑ fix duplicazione buchi legacy con supporto reale segmentato  
☑ supporto reale parziale funzionante  

---

### BUG STRUTTURALE RISOLTO — DUPLICAZIONE BUCHI

Caso reale testato:

- evento reale 21:00–22:30
- supporto reale 21:00–22:00

Prima:

❌ doppio buco:
- 21:00–22:30
- 22:00–22:30

Causa:

CoverageEngine manteneva ancora gap legacy completi dopo la segmentazione reale.

Ora:

✔ viene generato SOLO il residuo reale:
22:00–22:30

---

### SIGNIFICATO STRUTTURALE

Il sistema sta passando da:

❌ fasce statiche legacy  
❌ blocchi artificiali  

a:

✔ range reali  
✔ presenza reale  
✔ segmentazione reale  
✔ supporto reale parziale  
✔ accompagnamento reale  

---

### RESTA

⬜ eliminare altri doppioni legacy residui  
⬜ valutare spostamento segmentazione eventi/tagli fascia  
⬜ verificare logiche presenza Alice ancora dirette dentro `analyzeDayV2()`  
⬜ ridurre ulteriormente letture dirette store Alice nel CoverageEngine  

---

## BUG CENTRO ESTIVO RISOLTO

Caso reale:

- Alice al centro estivo fino a 16:30
- rientro logistico 16:30–16:50
- genitori entrambi pomeriggio
- nessuna copertura fino a sera

Prima:

❌ buco uscita mostrato 16:30–18:00  
❌ mancava buco reale casa 16:50–21:00  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ Alice a casa dopo centro estivo 16:50–21:00  
✔ fascia Sandra sera 21:00–22:35 separata  
✔ supporto reale spezza correttamente i buchi  

Checkpoint:

`summer-camp-real-home-gaps`

---

# BLOCCO H — HOME GUIDATA DAL PRESENCE ENGINE

Stato: NON ANCORA INIZIATO

---

## OBIETTIVO

La Home dovrà leggere la stessa verità del calendario:

👉 PresenceEngine → CoverageEngine → Home

Non deve ricostruire logiche proprie.

---

# BLOCCO IPS

Stato: RIMANDATO

---

## DECISIONE

IPS NON è più priorità immediata.

Prima serve completare:

1. Motore Presenza Reale Alice
2. CoverageEngine guidato dal PresenceEngine
3. Home coerente con la stessa verità
4. Test presenza reale strutturati

Solo dopo:

👉 riallineamento IPS completo al sistema reale.

---

# BLOCCO EVENTI GLOBALI

Stato: IMPLEMENTATO V1

✔ navigazione anno → mesi → eventi → dettaglio  
✔ memoria evento persistente  
✔ eventi multi-persona  

Limite attuale:

❌ Eventi Alice non ancora completamente integrati negli Eventi Globali  

---

# BLOCCO STATISTICHE

Stato: AVVIATO / BASE STRUTTURALE CONSOLIDATA

Principio:

👉 le statistiche NON devono inventare dati  
👉 devono leggere solo moduli reali vivi  

Struttura temporale:

✔ Giorno  
✔ Settimana  
✔ Mese  
✔ Anno  

Direzione futura:

- supporto
- copertura
- eventi
- costi
- IPS
- salute

---

# MODULI FUTURI

FINANZE  
SPESE  
SALUTE  
AUTO  
STATISTICHE AVANZATE  
IPS REALE  

---

# DIREZIONE OPERATIVA ATTUALE

NON fare:

❌ Home ora  
❌ IPS ora  
❌ mega-refactor  
❌ spostamenti ciechi  
❌ duplicazioni logiche  

Fare:

✔ completare PresenceEngine  
✔ ripulire CoverageEngine dai residui legacy  
✔ un passo alla volta  
✔ test reale dopo ogni modifica  
✔ mantenere Sandra separata dalla rete supporto  
✔ mantenere decisione sempre umana  

---

# PROSSIMA RIPARTENZA

Ripartiamo da FrodoDesk — BLOCCO G consolidamento avanzato PresenceEngine.

Stato:

✔ PresenceEngine proprietario progressivo presenza Alice  
✔ accompagnamento centralizzato  
✔ supporto reale centralizzato  
✔ eventi reali Alice centralizzati  
✔ eventi temporizzati Alice centralizzati  
✔ CoverageEngine progressivamente semplificato  
✔ CompanionStore non più letto direttamente nei punti principali  
✔ fix duplicazione buchi legacy completato  
✔ supporto reale segmentato funzionante  

---

# DIREZIONE REALE ATTUALE

CoverageEngine deve progressivamente:

❌ smettere di interpretare Alice  
❌ smettere di conoscere CompanionStore  
❌ smettere di segmentare manualmente la presenza Alice  

e diventare:

✔ consumatore puro del PresenceEngine  
✔ motore copertura reale  
✔ interprete buchi  
✔ NON proprietario presenza Alice  

---

# PROSSIMO FRONTE

Continuare la pulizia legacy dentro CoverageEngine.

In particolare:

👉 segmentazione eventi Alice  
👉 tagli temporali legacy  
👉 logiche “Alice a casa dopo...”  
👉 logiche presenza ancora dirette dentro `analyzeDayV2()`  

---

# NON FARE ANCORA

❌ Home  
❌ IPS  
❌ mega-refactor  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — BLOCCO G consolidamento avanzato: PresenceEngine proprietario progressivo della presenza Alice, CoverageEngine in pulizia legacy. Prossimo passo: eliminare segmentazioni manuali residue dentro analyzeDayV2() senza toccare ancora Home e IPS.
---

# BLOCCO FINANZE / SPESE

Stato: FONDAZIONE CONCETTUALE COMPLETATA

---

## SIGNIFICATO

FrodoDesk entra nella simulazione economica familiare reale.

NON come:
- banca
- gestionale
- Excel movimenti

MA come:

👉 sistema di lettura della stabilità economica familiare.

---

# PRINCIPIO FONDAMENTALE

# PREVISIONE ≠ REALTÀ

Regola strutturale globale del progetto.

Il sistema deve distinguere sempre:

✔ previsione  
✔ simulazione  
✔ ricorrenza  

da:

✔ realtà  
✔ importo reale  
✔ evento realmente avvenuto  

---

## ESEMPI

### Spese ricorrenti

Netflix 17€/mese

NON genera automaticamente:

✔ spesa reale

Genera:

✔ previsione futura

che può essere:

- confermata
- modificata
- saltata
- annullata

---

### Stipendi

Il sistema può:

✔ stimare  
✔ simulare andamento  

ma:

✔ l’utente inserisce manualmente il valore reale mensile

---

# MODULO FINANZE

Stato: DEFINIZIONE FILOSOFICA COMPLETATA

---

## OBIETTIVO

Leggere:

👉 “Dove stiamo andando?”

---

## FINANZE DOVRÀ GESTIRE

✔ saldi iniziali  
✔ simulazione futura  
✔ stipendi  
✔ fondi  
✔ ricorrenze  
✔ pressione economica  
✔ andamento storico  
✔ margine reale futuro  

---

## PRINCIPIO

Finanze NON rappresenta:

❌ movimenti reali

Rappresenta:

✔ simulazione della sostenibilità futura.

---

# MODULO SPESE

Stato: DEFINIZIONE FILOSOFICA COMPLETATA

---

## OBIETTIVO

Leggere:

👉 “Cosa è successo davvero?”

---

## SPESE DOVRÀ GESTIRE

✔ spese reali  
✔ categorie  
✔ persone  
✔ metodo pagamento  
✔ note  
✔ storico reale  

---

## ESEMPI

- benzina
- farmacia
- supermercato
- pizza
- Amazon
- assicurazione
- revisione
- prelievi

---

# STRUTTURA PERSONE ECONOMICHE

Decisione ufficiale:

Il sistema deve già conoscere:

✔ Matteo  
✔ Chiara  
✔ Alice  

anche se Alice oggi non ha ancora:

- conto
- spese autonome
- entrate

👉 struttura già predisposta per evoluzione futura.

---

# STATISTICHE — NUOVA DIREZIONE

Statistiche diventa:

👉 lettura globale della vita reale del sistema

e NON semplice modulo grafici.

---

## STATISTICHE LEGGERÀ FUTURAMENTE

✔ calendario  
✔ supporto  
✔ copertura  
✔ spese  
✔ finanze  
✔ salute  
✔ IPS  

---

# DIREZIONE OPERATIVA

I moduli:

✔ devono crescere insieme  
✔ restare separati inizialmente  
✔ collegarsi gradualmente  

👉 “app dentro app dentro app”

finché emergerà naturalmente la forma reale finale.

---

# ROADMAP BLOCCO FINANZE / SPESE

☑ Separazione Finanze vs Spese  
☑ Distinzione previsione vs realtà  
☑ Filosofia umana consolidata  
☑ Struttura persone economiche definita  
☑ Ricorrenze definite come previsione  
☑ Statistiche riconosciuto come modulo centrale futuro  

⬜ Creazione docs dedicati Finanze  
⬜ Creazione docs dedicati Spese  
⬜ Definizione struttura minima Finanze v1  
⬜ Definizione struttura minima Spese v1  
⬜ Dashboard economica minimale v1  
⬜ Collegamento futuro Statistiche ↔ Finanze ↔ Spese