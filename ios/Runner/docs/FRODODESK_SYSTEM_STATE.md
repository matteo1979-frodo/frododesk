# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 12 Maggio 2026  
(BLOCCO G — Motore Presenza Reale Alice)

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

Il sistema è costruito con filosofia CNC:

- un passo alla volta
- zero modifiche multiple insieme
- ogni blocco deve essere stabile prima di passare al successivo
- lavoro sempre su file reali
- motore prima
- UI dopo
- test reale continuo

---

# FASE ATTUALE DEL PROGETTO

🔥 CALENDARIO REALE COMPLETO  
🔥 COPERTURA REALE CONSOLIDATA  
🔥 HOME AZIONABILE V1.1 CONSOLIDATA  
🔥 EVENTI GLOBALI V1  
🔥 MODULO STATISTICHE AVVIATO  
🔥 MOTORE PRESENZA REALE ALICE IN CONSOLIDAMENTO

Il sistema è:

✔ utilizzabile nella vita reale  
✔ testato su casi concreti  
✔ stabile nei motori principali  
✔ coerente tra motore → calendario → Home  
✔ capace di distinguere oggi e problemi futuri  
✔ capace di trasformare un buco reale in problema visibile  
✔ capace di portare direttamente al giorno del problema  
✔ capace di navigare eventi nel tempo  
✔ capace di salvare memoria reale sugli eventi  
✔ entrato nella fase di simulazione presenza reale Alice  

---

# EVOLUZIONE STRUTTURALE

Il sistema ha fatto questi passaggi:

❌ simulazione parziale  
✔ simulazione reale della giornata  

❌ Home solo informativa  
✔ Home operativa e gerarchica  

❌ eventi temporanei  
✔ eventi come memoria persistente  

🔥 NUOVO PASSAGGIO:

❌ Alice come semplice evento/calendario  
✔ Alice come presenza reale nel tempo  

---

# BLOCCO SCUOLA

Stato: COMPLETATO

✔ SchoolStore attivo  
✔ Periodi funzionanti  
✔ Orari letti correttamente  
✔ Stato Alice coerente  
✔ Support network validato  
✔ UI allineata al motore  
✔ Giorni festivi riconosciuti correttamente  

---

# BLOCCO COPERTURA REALE

Stato: COMPLETATO / CONSOLIDATO

---

## REGOLA FONDAMENTALE

Alice deve essere coperta quando è realmente a casa.

La copertura dipende da:

- Matteo
- Chiara
- rete supporto
- Sandra se attiva nella fascia corretta
- eventi reali
- scuola
- centro estivo
- accompagnamento
- rientro reale a casa

---

## RISULTATO

✔ Buchi reali corretti  
✔ Eventi reali influenzano la copertura  
✔ Supporto integrato correttamente  
✔ Calendario coerente  
✔ Home coerente  
✔ giorni festivi corretti  
✔ Sandra separata dalla rete supporto  

---

# BLOCCO HOME AZIONABILE V1.1

Stato: COMPLETATO E VALIDATO

La Home:

✔ legge i buchi reali della copertura  
✔ separa stato reale di oggi e problema futuro  
✔ mostra il problema principale  
✔ apre il calendario sul giorno corretto  
✔ non propone soluzioni automatiche  
✔ mantiene decisione umana  

---

# BLOCCO EVENTI GLOBALI

Stato: IMPLEMENTATO V1

✔ navigazione anno → mesi → eventi  
✔ mesi in griglia  
✔ dettaglio evento  
✔ memoria evento persistente  
✔ eventi multi-persona  

Limite attuale:

❌ Eventi Alice non ancora completamente integrati negli Eventi Globali

---

# BLOCCO STATISTICHE

Stato: AVVIATO / BASE STRUTTURALE CONSOLIDATA

Principio:

👉 le statistiche leggono solo dati reali vivi  
👉 non inventano dati  
👉 sono supporto decisionale, non decorazione

Struttura temporale:

✔ Giorno  
✔ Settimana  
✔ Mese  
✔ Anno  

---

# BLOCCO G — MOTORE PRESENZA REALE ALICE

Stato: IN CONSOLIDAMENTO AVANZATO

---

## OBIETTIVO

Centralizzare la domanda:

👉 “Dove si trova realmente Alice in questa fascia?”

---

## FILE / COMPONENTI CREATI

✔ `lib/logic/alice_presence_engine.dart`  
✔ `lib/models/alice_presence_state.dart`  

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

## COMPLETATO NEL BLOCCO G

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
☑ centralizzare accesso eventi temporizzati Alice  
☑ centralizzare copertura rete supporto  
☑ centralizzare controllo evento reale Alice  
☑ CoverageEngine ridotto a consumatore progressivo del PresenceEngine  

---

# BUG CENTRO ESTIVO RISOLTO

Caso reale testato:

- centro estivo attivo
- uscita 16:30
- rientro logistico 20 minuti
- Matteo e Chiara entrambi pomeriggio
- supporto parziale possibile
- Sandra sera separata

Prima:

❌ uscita centro estivo mostrata fino alle 18:00  
❌ mancava il buco casa 16:50–21:00  

Ora:

✔ uscita centro estivo 16:30–16:50  
✔ Alice a casa dopo centro estivo 16:50–21:00  
✔ fascia Sandra sera 21:00–22:35 separata  
✔ supporto reale spezza correttamente i buchi  

Checkpoint:

`summer-camp-real-home-gaps`

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione eventi reali corretta  
✔ gestione supporto corretta  
✔ gestione Alice a casa corretta  
✔ gestione giorni festivi corretta  
✔ buchi reali letti dalla Home  
✔ PresenceEngine inizia a guidare la logica Alice  

---

# STATO EVENTI ALICE

✔ AliceEventStore attivo  
✔ AliceSpecialEventStore attivo  
✔ eventi integrati nel motore  
✔ eventi accompagnati funzionanti  
✔ companion automatiche funzionanti  
✔ cleanup lifecycle funzionante  
✔ eventi temporizzati letti dal PresenceEngine  
❌ non ancora completamente integrati negli Eventi Globali  

---

# MOTORI ATTIVI

- TurnEngine  
- CoverageEngine  
- AlicePresenceEngine  
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
- AliceCompanionStore  
- SupportNetworkStore  
- FeriePeriodStore  
- DiseasePeriodStore  
- FourthShiftStore  
- SettingsStore  
- DaySettingsStore  
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

Nota:

👉 Home non è ancora guidata direttamente dal PresenceEngine.

---

# STATO IPS

⚠️ NON ancora coerente con il sistema reale

Decisione:

👉 IPS resta rimandato fino al completamento del Motore Presenza Reale Alice.

---

# PROSSIMA FASE OPERATIVA

Non fare Home.  
Non fare IPS.

Prossimo fronte:

👉 continuare la pulizia di CoverageEngine dai residui legacy presenza Alice.

In particolare:

⬜ eliminare altri doppioni logici  
⬜ valutare spostamento segmentazione eventi/tagli fascia  
⬜ verificare logiche presenza Alice ancora dirette dentro `analyzeDayV2()`  
⬜ solo dopo → Home guidata dal PresenceEngine  

---

# DIREZIONE OPERATIVA

✔ un passo alla volta  
✔ motore prima  
✔ UI dopo  
✔ test reale continuo  
✔ decisione sempre umana  
✔ file reali sempre  
✔ nessun mega-refactor  

---

# SIGNIFICATO ATTUALE

FrodoDesk ora non sta più solo leggendo eventi.

Sta iniziando a modellare:

👉 presenza reale familiare  
👉 presenza relazionale  
👉 stato Alice nel tempo  
👉 copertura reale dinamica  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — BLOCCO G: PresenceEngine già attivo, CoverageEngine in progressiva pulizia. Prossimo passo: eliminare residui legacy di presenza Alice dentro CoverageEngine senza toccare Home e senza riallineare IPS.
---

# 🔄 AGGIORNAMENTO 14 Maggio 2026
(BLOCCO G — Consolidamento avanzato PresenceEngine)

---

# CAMBIO STRUTTURALE IN CORSO

Il progetto è entrato nella fase:

👉 “CoverageEngine come consumatore puro del PresenceEngine”

Questo significa:

❌ CoverageEngine non deve più interpretare direttamente Alice  
❌ CoverageEngine non deve più leggere CompanionStore  
❌ CoverageEngine non deve più segmentare manualmente la presenza Alice  

e deve diventare:

✔ motore copertura reale  
✔ interprete buchi  
✔ lettore presenza reale già costruita dal PresenceEngine  

---

# NUOVA DIREZIONE ARCHITETTURALE

Nuovo flusso strutturale:

AlicePresenceEngine  
↓  
CoverageEngine  
↓  
Calendario / Home / IPS futuro

---

# CONSOLIDAMENTO STEP G3

## COMPLETATO

☑ centralizzazione accompagnamento Alice
☑ centralizzazione overlap accompagnamento
☑ centralizzazione companion end
☑ centralizzazione support network reale
☑ centralizzazione eventi reali Alice
☑ centralizzazione eventi temporizzati Alice

---

# NUOVE API ATTIVE

Introdotte nel PresenceEngine:

✔ `isAliceAccompaniedDuringRange()`
✔ `aliceCompanionEndForRange()`

CoverageEngine ora usa queste API invece di leggere direttamente:

- CompanionStore
- overlap manuali
- companion end legacy

---

# PULIZIA DIPENDENZE DIRETTE

Eliminato:

☑ `_getAliceCompanionEnd()`

CoverageEngine NON legge più direttamente CompanionStore in:

☑ `_isFasciaCovered()`
☑ `_uncoveredHomeSegments()`
☑ filtro finale `analyzeDayV2()`

---

# FIX STRUTTURALE — DUPLICAZIONE BUCHI LEGACY

## Caso reale testato

- evento reale 21:00–22:30
- supporto reale 21:00–22:00

Risultato errato precedente:

❌ doppio buco:
- 21:00–22:30
- 22:00–22:30

---

# CAUSA IDENTIFICATA

CoverageEngine continuava a generare:

- gap legacy completo
- fascia Sandra legacy

anche dopo la segmentazione reale del support network.

---

# FIX APPLICATO

Aggiunto filtro anti-duplicazione strutturale.

Il motore ora verifica:

✔ presenza gap Alice reale già esistente
✔ stessa fascia iniziale

e impedisce la creazione del doppione legacy.

---

# RISULTATO

Ora il sistema genera correttamente:

✔ SOLO il residuo reale:
22:00–22:30

---

# SIGNIFICATO STRUTTURALE

Questo conferma il cambio architetturale reale:

❌ fasce statiche legacy
❌ blocchi artificiali
❌ simulazioni rigide

→ sostituiti progressivamente da:

✔ range reali
✔ segmentazione reale
✔ presenza reale
✔ supporto reale parziale
✔ accompagnamento reale

---

# STATO ATTUALE DEL MOTORE

CoverageEngine:

✔ legge progressivamente PresenceEngine
✔ usa supporto reale segmentato
✔ usa accompagnamento centralizzato
✔ usa eventi reali centralizzati
✔ evita doppioni legacy serali

PresenceEngine:

✔ proprietario progressivo presenza Alice
✔ proprietario accompagnamento
✔ proprietario supporto reale
✔ proprietario stato presenza nel tempo

---

# RESIDUI LEGACY ANCORA PRESENTI

⬜ segmentazione manuale dentro `analyzeDayV2()`
⬜ tagli fascia legacy
⬜ logiche “Alice a casa dopo...”
⬜ letture dirette residue store Alice

---

# DECISIONE OPERATIVA

NON lavorare ancora su:

❌ Home
❌ IPS

Continuare invece:

👉 consolidamento STEP G3
👉 eliminazione residui legacy CoverageEngine
👉 separazione definitiva presenza Alice / copertura

---

# STATO STRUTTURALE REALE

FrodoDesk sta passando da:

❌ calendario con logiche sparse

a:

✔ simulatore presenza familiare reale
✔ presenza relazionale
✔ copertura dinamica reale
✔ interpretazione temporale reale della giornata

---

# FRASE DI RIPARTENZA AGGIORNATA

Ripartiamo da FrodoDesk — BLOCCO G consolidamento avanzato: PresenceEngine proprietario progressivo della presenza Alice, CoverageEngine in pulizia legacy. Prossimo passo: eliminare segmentazioni manuali residue dentro analyzeDayV2() senza toccare ancora Home e IPS.
---

# 🔄 AGGIORNAMENTO 14 Maggio 2026
(BLOCCO FINANZE / SPESE — Fondazione Concettuale)

---

# NUOVA FASE STRUTTURALE APERTA

Decisione ufficiale:

FrodoDesk entra nella fase di fondazione dei moduli:

- Finanze
- Spese

MA:

⚠️ senza abbandonare la crescita parallela del Calendario reale.

---

# PRINCIPIO STRUTTURALE DECISO

I moduli devono crescere insieme.

NON:

❌ completare totalmente un modulo prima degli altri

MA:

✔ far crescere il sistema in modo organico
✔ moduli separati ma collegabili
✔ evoluzione progressiva condivisa

---

# DISTINZIONE UFFICIALE — FINANZE vs SPESE

## FINANZE

Domanda:

👉 “Dove stiamo andando?”

Finanze rappresenta:

✔ simulazione futura
✔ sostenibilità
✔ pressione economica
✔ previsione
✔ fondi
✔ andamento futuro

---

## SPESE

Domanda:

👉 “Cosa è successo davvero?”

Spese rappresenta:

✔ memoria reale del denaro
✔ movimenti reali
✔ comportamento reale
✔ storico reale

---

# PRINCIPIO FONDAMENTALE CONSOLIDATO

# PREVISIONE ≠ REALTÀ

Esempi:

✔ Netflix prevista ≠ pagamento reale
✔ assicurazione prevista ≠ importo reale futuro
✔ stipendio stimato ≠ stipendio reale ricevuto

---

# DECISIONE IMPORTANTE — CONTROLLO UMANO

Il sistema:

✔ può simulare
✔ può prevedere
✔ può avvisare
✔ può mostrare pressione

MA:

❌ non decide
❌ non blocca
❌ non vieta spese

Anche in presenza di:

- rischio
- saldo basso
- fondi esauriti
- pressione economica alta

👉 la decisione resta sempre umana.

---

# PERSONE ECONOMICHE DEL SISTEMA

La struttura economica deve già conoscere:

✔ Matteo
✔ Chiara
✔ Alice

anche se Alice oggi:

- non ha conto
- non ha entrate
- non ha spese autonome

Questo serve a preparare:

✔ crescita futura
✔ statistiche
✔ evoluzione sistema

---

# SALDI

Decisione strutturale:

✔ saldo iniziale inserito manualmente
✔ aggiornamento reale periodico manuale
✔ sistema deve ricordare di riallineare il saldo reale ogni alcuni mesi

---

# STIPENDI

Decisione ufficiale:

✔ simulazione automatica possibile
✔ utilizzo statistiche storiche possibile

MA:

✔ conferma reale manuale ogni mese

Il sistema NON deve inventare il denaro reale disponibile.

---

# SPESE IMPREVEDIBILI

Il sistema deve convivere con:

✔ benzina variabile
✔ prelievi
✔ spese improvvise
✔ acquisti casuali
✔ emergenze

---

# RUOLO FUTURO DELLE STATISTICHE

Nuova direzione consolidata:

Statistiche diventerà:

✔ lettura del passato
✔ lettura del presente
✔ lettura evolutiva futura

leggendo:

- spese
- finanze
- fondi
- categorie
- comportamenti
- trend familiari

---

# DIREZIONE ARCHITETTURALE

In questa fase:

✔ Finanze
✔ Spese
✔ Statistiche

devono crescere separati ma compatibili.

Principio:

👉 “app dentro app dentro app”

ovvero:

✔ moduli indipendenti
✔ responsabilità chiare
✔ collegamenti progressivi
✔ nessun mega-modulo monolitico

---

# STATO ATTUALE

✔ filosofia Finanze definita
✔ filosofia Spese definita
✔ distinzione previsione/realtà consolidata
✔ struttura persone definita
✔ controllo umano consolidato
✔ direzione statistica chiarita

---

# PROSSIMO PASSO OPERATIVO

Definire:

⬜ struttura dati minima Finanze
⬜ struttura dati minima Spese
⬜ primi modelli reali
⬜ prime dashboard minimali

SENZA ancora collegare:

❌ IPS
❌ Home avanzata
❌ automazioni pesanti

---

# FRASE DI RIPARTENZA AGGIORNATA

Ripartiamo da FrodoDesk — fondazione moduli Finanze e Spese: definizione strutture dati minime, separazione previsione/realtà e crescita parallela dei moduli senza perdere la filosofia “decisione sempre umana”.

---

# 🔄 AGGIORNAMENTO 15 Maggio 2026
(BLOCCO FINANZE V1 — Modello economico visivo funzionante)

---

# NUOVO STATO MODULO FINANZE

Il modulo Finanze è passato da:

❌ fondazione concettuale

a:

✔ Finanze V1 visiva funzionante  
✔ modello dati economico avviato  
✔ card Home attiva  
✔ popup navigabili  
✔ ricorrenze economiche vive  
✔ struttura ancora basata su dati demo  

---

# COMPONENTI CREATI / ATTIVI

Sono stati creati e collegati i primi file del modulo Finanze:

✔ `lib/models/finance_person.dart`  
✔ `lib/models/finance_balance.dart`  
✔ `lib/models/finance_fund.dart`  
✔ `lib/models/finance_recurring_item.dart`  
✔ `lib/models/finance_snapshot.dart`  
✔ `lib/stores/finance_store.dart`  
✔ `lib/stores/finance_demo_data.dart`  

---

# FINANCESTORE

`FinanceStore` ora gestisce:

✔ persone economiche  
✔ saldi  
✔ fondi  
✔ ricorrenze  
✔ snapshot  
✔ saldo totale  
✔ fondi totali  
✔ entrate previste  
✔ uscite previste  
✔ margine mensile previsto  
✔ stato pressione  
✔ riepilogo testuale  
✔ caricamento demo controllato  

---

# PERSONE ECONOMICHE

Il sistema economico conosce:

✔ Matteo  
✔ Chiara  
✔ Alice  

Alice resta già predisposta come entità economica futura anche se oggi non ha:

- conto reale
- entrate
- spese autonome

---

# SALDI

Introdotto modello saldi con:

✔ persona collegata  
✔ saldo iniziale  
✔ saldo corrente  
✔ data aggiornamento  

Stato attuale:

⚠️ saldi ancora demo.

Prossimo passo:

👉 sostituire i demo con saldo reale Matteo e saldo reale Chiara.

---

# FONDI

Introdotto modello fondi con:

✔ id  
✔ nome  
✔ descrizione  
✔ importo  
✔ protetto / non protetto  

Fondi demo attuali:

- Emergenze
- Fondo Auto

UI funzionante:

✔ popup Fondi  
✔ dettaglio singolo fondo  
✔ messaggio diverso per fondo protetto / non protetto  

---

# RICORRENZE ECONOMICHE VIVE

`FinanceRecurringItem` è diventato un oggetto economico avanzato.

Ogni ricorrenza contiene:

✔ id  
✔ nome  
✔ descrizione  
✔ importo previsto  
✔ prossima scadenza  
✔ entrata / uscita  
✔ tipo ricorrenza  
✔ categoria  
✔ conferma manuale richiesta  
✔ obbligatorietà  
✔ pressione economica  
✔ stato previsto / confermato  
✔ variabilità  
✔ stabilità  
✔ priorità pagamento  
✔ protezione  
✔ rischio sospensione  

---

# DISTINZIONI STRUTTURALI ATTIVE

Il sistema ora distingue:

✔ previsto  
✔ confermato  
✔ obbligatorio  
✔ facoltativo  
✔ stabile  
✔ instabile  
✔ protetto  
✔ non protetto  
✔ pressione economica  
✔ priorità pagamento  
✔ rischio sospensione  
✔ fisso  
✔ variabile  

---

# ESEMPIO STRUTTURALE — NETFLIX

Netflix non è più solo:

- nome
- importo

ma viene letto come:

✔ uscita prevista  
✔ ricorrenza mensile  
✔ categoria intrattenimento  
✔ facoltativa  
✔ pressione bassa  
✔ prevista  
✔ priorità bassa  
✔ non protetta  
✔ stabile  
✔ rischio sospensione basso  
✔ descrizione leggibile  

Significato:

👉 FrodoDesk legge comportamento economico nel tempo, non solo movimenti.

---

# ESEMPIO STRUTTURALE — STIPENDI

Gli stipendi Matteo / Chiara sono modellati come:

✔ entrate previste  
✔ mensili  
✔ protette  
✔ stabili  
✔ da confermare manualmente  
✔ previste il giorno 5 del mese  

Decisione reale:

👉 il riferimento contrattuale dello stipendio è il giorno 5.

Anche se nella realtà può arrivare il 3 o il 4, il sistema usa il giorno 5 come data strutturale prevista.

---

# HOME FINANZE

La card Finanze nella Home ora:

✔ non è più solo decorativa  
✔ mostra saldo totale  
✔ mostra margine previsto  
✔ legge dati dal FinanceStore  
✔ apre il popup Finanze  

---

# NAVIGAZIONE FINANZE V1

Percorsi funzionanti:

Home  
→ Finanze  
→ Saldo totale  
→ saldi persone

Home  
→ Finanze  
→ Fondi  
→ singolo fondo

Home  
→ Finanze  
→ Entrate previste  
→ singola entrata

Home  
→ Finanze  
→ Uscite previste  
→ singola uscita

Home  
→ Finanze  
→ Margine previsto

---

# UI FINANZE

Introdotto componente:

`_financeBadge()`

per evitare duplicazioni e iniziare la modularizzazione UI.

Badge attualmente usati:

- DA CONFERMARE
- PREVISTO
- FACOLTATIVA
- PRESSIONE BASSA
- PRIORITÀ BASSA
- NON PROTETTA
- STABILE
- RISCHIO BASSO
- PROTETTA

---

# NOTA UI TEMPORANEA

Durante la costruzione veloce del modello:

alcuni badge/logiche delle Uscite sono stati temporaneamente presenti anche nelle Entrate.

Decisione ufficiale:

❌ NON rifinire ora.

In futuro:

✔ separare UI Entrate  
✔ separare UI Uscite  
✔ creare badge coerenti per ciascun tipo  

---

# NON ANCORA FATTO

Non è ancora presente:

❌ persistenza reale Finanze  
❌ inserimento/modifica da UI  
❌ saldi reali  
❌ fondi reali  
❌ ricorrenze reali  
❌ collegamento Spese  
❌ collegamento Statistiche  
❌ collegamento IPS economico  

---

# STATO ATTUALE FINANZE

Finanze V1 è:

✔ visibile  
✔ navigabile  
✔ collegata alla Home  
✔ stabile in compilazione  
✔ basata su dati demo  
✔ senza persistenza reale  
✔ pronta per passare ai dati reali  

---

# PROSSIMA FASE OPERATIVA

Dopo salvataggio Git/tag:

👉 sostituire i dati demo con dati reali Finanze.

Ordine operativo deciso:

1. saldo reale Matteo  
2. saldo reale Chiara  
3. fondi reali  
4. ricorrenze reali  
5. solo dopo modifica/inserimento da UI  

---

# DIREZIONE OPERATIVA CONFERMATA

Non fare ancora:

❌ IPS economico  
❌ Statistiche economiche  
❌ Spese  
❌ persistenza complessa  
❌ grafica definitiva  

Fare prima:

✔ rendere reali i dati Finanze  
✔ mantenere il modulo separato  
✔ continuare un passo alla volta  
✔ non rompere Home / Calendario / PresenceEngine  

---

# FRASE DI RIPARTENZA AGGIORNATA

Ripartiamo da FrodoDesk — Finanze V1 visiva funzionante: Home collegata al FinanceStore, popup navigabili, ricorrenze economiche vive ancora su dati demo. Prossimo passo: sostituire i demo con dati reali Finanze partendo dai saldi Matteo/Chiara, senza toccare IPS, Statistiche o Spese.
---

# 🔄 AGGIORNAMENTO 22 Maggio 2026
(BLOCCO FINANZE — Dashboard temporale annuale)

---

# NUOVA FASE UI FINANZE

Il modulo Finanze entra nella fase:

👉 “lettura temporale economica della famiglia”

La dashboard non deve più essere:

❌ lista verticale tecnica  
❌ semplice elenco card economiche  

ma:

✔ simulazione temporale leggibile  
✔ visione pressione futura  
✔ navigazione economica nel tempo  

---

# EVOLUZIONE INTRODOTTA

Sono state introdotte:

✔ card mesi compatte  
✔ stati mese visivi  
✔ pressione economica sintetica  
✔ colori stato economico  
✔ struttura annuale Gennaio → Dicembre  
✔ base navigazione anni  
✔ popup mese più dashboard e meno lista  

---

# STATI MESE

Ogni mese ora può essere:

✔ stabile  
✔ pressione  
✔ critico  

con:

- colore dedicato
- margine economico
- stato sintetico

---

# OBIETTIVO STRUTTURALE

La dashboard Finanze evolve verso:

✔ timeline economica reale  
✔ heatmap pressione economica  
✔ simulazione sostenibilità annuale  
✔ lettura temporale del rischio familiare  
✔ pressione futura leggibile nel tempo  

---

# PROBLEMA ATTUALMENTE APERTO

La navigazione anni è stata introdotta ma NON è ancora stabile.

Problemi emersi:

🟡 gestione `selectedYear`
🟡 builder annuale ancora fragile
🟡 rischio perdita popup dettaglio mese
🟡 blocco UI troppo grande per patch sicure

---

# DECISIONE OPERATIVA

❌ NON continuare con patch rapide.

✔ Fare refactor completo e sicuro del blocco:
`Pressione temporale`

Approccio deciso:

- blocco intero
- 0 rischio
- preservazione popup mese
- preservazione logica economica
- futura separazione widget/dashboard

---

# STATO REALE ATTUALE

✔ mesi annuali visibili  
✔ dashboard economica più leggibile  
✔ popup mese più coerente  
✔ struttura temporale introdotta  

🟡 navigazione anni ancora instabile

---

# DIREZIONE OPERATIVA

NON fare ancora:

❌ grafici avanzati  
❌ heatmap completa  
❌ statistiche economiche evolute  
❌ IPS economico  

Fare prima:

✔ consolidamento dashboard annuale
✔ consolidamento navigazione anni
✔ refactor sicuro UI temporale
✔ separazione futura widget/dashboard

---

# FRASE DI RIPARTENZA AGGIORNATA

Ripartiamo da FrodoDesk — Dashboard Finanze temporale annuale: mesi Gennaio→Dicembre visibili, stati economici introdotti, popup mese più dashboard. Prossimo passo: refactor sicuro del blocco “Pressione temporale” per stabilizzare la navigazione anni senza perdere popup e logica economica.
