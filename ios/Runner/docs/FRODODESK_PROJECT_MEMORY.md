# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: Aprile 2026 (post fix scuola motore + support network)

---

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

👉 Il sistema suggerisce  
👉 La decisione resta sempre umana

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

👉 deve essere segnalato come conflitto reale

La risoluzione è sempre umana:

- cambiare turno
- prendere ferie o permesso
- spostare l’evento

---

## Filosofia del calendario

Il calendario FrodoDesk non è un calendario eventi.

È una:

👉 simulazione operativa della realtà familiare

Serve per:

- evidenziare problemi reali
- spiegare perché accadono
- anticipare decisioni

---

# STATO REALE DEL SISTEMA (APRILE 2026)

✔ motore di copertura stabile  
✔ gestione turni reale affidabile  
✔ modello notte/post-notte corretto  
✔ eventi Alice funzionanti  
✔ centro estivo sopra vacanza consolidato  
✔ Sandra coerente su tutte le fasce  
✔ calendario utilizzabile nella vita reale  

👉 fase “stabilità logica” completata

---

# PASSAGGIO DI FASE

Il progetto è passato da:

❌ costruzione motore  
👉 a  
✔ utilizzo reale + miglioramento continuo  

👉 FrodoDesk è ora uno strumento reale

---

# 🔥 BLOCCO SCUOLA — STATO REALE

## Fase attuale

👉 STRUTTURA COMPLETATA  
👉 MOTORE COLLEGATO  
👉 UI ALLINEATA  
👉 LOGICA TEMPORALE CORRETTA  

---

## Problema iniziale (RISOLTO)

La gestione scuola manuale causava:

- confusione uscita/rientro
- doppie azioni
- incoerenza sistema

---

## 🔥 BUG CRITICO RISOLTO (STATO ALICE)

Sintomi precedenti:

❌ Alice risultava “fuori • scuola” anche nei giorni OFF  
❌ popup incoerente (scuola mostrata ma non reale)  
❌ mismatch tra:
- stato Alice
- eventi giornata
- configurazione scuola  

---

## CAUSA

❌ duplicazione logica (UI + motore)  
❌ utilizzo funzioni legacy non allineate  
❌ più punti di calcolo dello stato Alice  

---

## SOLUZIONE IMPLEMENTATA

✔ centralizzazione logica su SchoolStore  
✔ introduzione controllo reale giorno scuola  
✔ rimozione logica duplicata  
✔ allineamento UI → motore  

👉 UNA SOLA VERITÀ

---

## 🔥 FIX STRUTTURALE — ORARI REALI SCUOLA

Problema:

❌ il sistema utilizzava fallback fissi (es. 08:25)  
❌ ingresso/uscita non sempre coerenti col periodo reale  

Soluzione:

✔ ingresso letto da SchoolStore  
✔ uscita letta da SchoolStore  
✔ rientro calcolato automaticamente (+20 min)  

---

## 🔥 FIX CRITICO — VALIDAZIONE COPERTURA

Problema:

❌ il sistema considerava copertura valida solo perché esisteva un supporto attivo  
❌ NON controllava se la fascia oraria era realmente coperta  

Esempio reale:

Sandra 07:00–08:25  
copriva ingresso 09:05–09:25 ❌

---

## SOLUZIONE

✔ validazione supporto basata su intervallo reale  
✔ eliminazione fallback orari fissi nel controllo copertura  

---

## PRINCIPIO STRUTTURALE (NUOVO)

👉 La copertura è valida SOLO se il tempo coincide

NON basta:
❌ supporto attivo  

Serve:
✔ copertura reale della fascia  

---

## RISULTATO

✔ buchi coerenti con la realtà  
✔ supporto validato correttamente  
✔ eliminati falsi positivi di copertura  

👉 comportamento finalmente realistico

---

# STRUTTURA BLOCCO SCUOLA

## 1️⃣ Sistema a periodi

✔ Elementari  
✔ Medie  
✔ futuri cicli  

---

## 2️⃣ Orario settimanale

✔ ingresso reale  
✔ uscita reale  
✔ completamente modificabile  
✔ letto dal motore  

---

## 3️⃣ Calcolo automatico

👉 accompagnamento = ingresso - 20 min  
👉 rientro = uscita + 20 min  

✔ NON salvati  
✔ sempre calcolati  

---

## PRINCIPIO FONDAMENTALE

Separazione obbligatoria:

- dati reali = scuola  
- logica = calcoli temporali  

👉 mai mescolare

---

## STATO MOTORE

✔ CoverageEngine legge SchoolStore  
✔ orari reali rispettati  
✔ support network validato correttamente  

👉 MOTORE STABILE E COERENTE

---

# ⚠️ BUG ATTIVO IDENTIFICATO

👉 USCITA ANTICIPATA NON IMPATTA IL MOTORE

Sintomo:

- UI aggiornata correttamente  
- decisione scuola aggiornata  
- ❌ buco NON si chiude  

Causa:

👉 uscita anticipata non letta dal CoverageEngine  

---

# STATO UI (POST FIX)

✔ stato Alice corretto  
✔ popup allineato  
✔ eventi coerenti  
✔ scuola coerente con motore  

---

# IMPATTO STRATEGICO

Alice ora è:

✔ entità strutturata  
✔ guidata da sistema reale  
✔ non più manuale  

---

# DIREZIONE DEL SISTEMA

Evoluzione:

❌ simulazione approssimativa  
👉  
✔ simulazione reale basata sul tempo  

---

# STATO DEL PROGETTO

✔ sistema stabile  
✔ motore affidabile  
✔ copertura coerente  
✔ scuola completamente integrata  

🔥 aperto:

👉 uscita anticipata nel motore

---

# PROSSIMI STEP REALI

A — collegare uscita anticipata al motore  
B — verifica chiusura buchi  
C — test reale completo  
D — rifinitura UI  

---

# PRINCIPIO OPERATIVO

✔ un passo alla volta  
✔ modifica isolata  
✔ test immediato  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — FIX USCITA ANTICIPATA: collegare l’orario reale al motore di copertura e verificare la chiusura corretta dei buchi.

---

# 🔄 AGGIORNAMENTO 5 Maggio 2026

## HOME + EVENTI GLOBALI + MEMORIA EVENTI

---

## 🔥 NUOVO PASSAGGIO STRUTTURALE

Il sistema ha fatto un salto importante:

❌ prima → eventi come dati temporanei  
✔ ora → eventi come memoria reale persistente  

---

## 🧠 EVENTI GLOBALI

Introdotto sistema di navigazione nel tempo:

✔ anno  
✔ mesi (griglia visiva)  
✔ eventi del mese  
✔ dettaglio evento  

---

## SIGNIFICATO

👉 il sistema non mostra più solo “oggi”  
👉 permette di navigare nella vita nel tempo  

---

## 🧠 MEMORIA EVENTI

Ogni evento ora può contenere:

✔ note  
✔ dettagli reali  
✔ memoria personale  

✔ salvataggio persistente  
✔ disponibile dopo riavvio  

---

## SIGNIFICATO

👉 nasce lo storico reale della famiglia  
👉 base futura per analisi e statistiche  

---

## 🧠 EVENTI MULTI-PERSONA

Introdotto supporto:

✔ più persone per evento  
✔ integrazione con copertura  
✔ lettura corretta nel motore  

---

## RISULTATO

✔ eventi più realistici  
✔ copertura più precisa  
✔ maggiore coerenza sistema  

---

## 🧱 ARCHITETTURA DECISA

Decisione importante:

👉 le funzionalità complesse NON devono stare nella Home  

✔ Home = vista  
✔ moduli = logica  

---

## 🔥 NASCITA MODULO STATISTICHE

Decisione ufficiale:

✔ creare modulo dedicato  
✔ NON sviluppare dentro Home  

---

## SIGNIFICATO

👉 FrodoDesk non è più solo simulazione  
👉 diventa sistema di analisi della vita reale  

---

## DIREZIONE FUTURA

Il sistema evolverà verso:

- storico eventi  
- analisi comportamento familiare  
- lettura visiva tramite grafici  
- supporto decisionale avanzato  

---

## STATO

✔ stabile  
✔ testato su app reale  
✔ memoria eventi funzionante  
✔ Eventi Globali funzionanti  
✔ struttura pronta per evoluzione

---

# 🔄 AGGIORNAMENTO 6 Maggio 2026

## 📊 MODULO STATISTICHE — CONSOLIDAMENTO STRUTTURALE

---

## 🧠 FILOSOFIA DEFINITA

Decisione ufficiale:

👉 le statistiche NON devono essere dashboard finte  

✔ devono leggere SOLO moduli reali vivi  
✔ devono essere conseguenza naturale del sistema reale  
✔ devono rappresentare memoria e lettura evolutiva della famiglia  

---

## ⏳ NUOVA LETTURA DEL TEMPO

Decisione strutturale importante:

❌ eliminati concetti tecnici:
- ultimi 7 giorni
- ultimi 30 giorni

✔ sostituiti da:
- Giorno
- Settimana
- Mese
- Anno

---

## SIGNIFICATO

FrodoDesk deve leggere il tempo come lo leggono le persone reali.

NON:
- dashboard tecnica
- analytics generica

MA:
- oggi
- questa settimana
- questo mese
- quest’anno

---

## 📈 SUPPORTO FAMILIARE — EVOLUZIONE STATISTICHE SANDRA

Implementato:

✔ popup andamento completo  
✔ confronto periodo precedente  
✔ navigazione temporale reale  
✔ grafico adattivo multi-periodo  

---

## MODALITÀ IMPLEMENTATE

✔ Giorno  
✔ Settimana  
✔ Mese  
✔ Anno  

---

## COMPORTAMENTO GRAFICI

✔ adattamento automatico al periodo  
✔ confronto storico reale  
✔ confronto anno ↔ anno precedente  
✔ confronto mese ↔ mese precedente  
✔ confronto settimana ↔ settimana precedente  
✔ confronto giorno ↔ giorno precedente  

✔ scala grafico corretta anche con anni futuri vuoti  

---

## 🧱 PRINCIPIO STRUTTURALE DEFINITO

Le statistiche NON possiedono logiche autonome.

👉 La verità vive nei moduli sorgente:

- Calendario
- Copertura
- Costi
- IPS
- Eventi
- Salute
- Supporto

Il modulo Statistiche:
✔ legge  
✔ aggrega  
✔ confronta  
✔ visualizza  

---

## 🧠 EVOLUZIONE DEL PROGETTO

Nuovo passaggio concettuale:

❌ prima → statistiche come grafici separati  
✔ ora → statistiche come memoria storica intelligente del sistema  

---

## 🔮 DIREZIONE FUTURA DECISA

Ordine operativo ufficiale:

1. Calendario reale completo  
2. Rifiniture intelligenti UX/realtà  
3. Modulo Costi / Finanze  
4. Espansione Statistiche come lettura naturale dei moduli vivi  

---

## 🧩 MODULI FUTURI COLLEGABILI

Le statistiche saranno estese a:

- Costi
- Copertura
- IPS
- Eventi
- Salute
- Auto
- Pressione familiare
- Trend economici

---

## STATO

✔ stabile  
✔ testato su app reale  
✔ popup adattivo funzionante  
✔ struttura statistica consolidata  
✔ base pronta per espansione multi-modulo

---

# 🔄 AGGIORNAMENTO 7 Maggio 2026

## 👤 PERSON DETAIL PANEL — MINI CALENDARI VIVI

---

## 🧠 NUOVA EVOLUZIONE STRUTTURALE

Le schede persona della Home si sono evolute da:

❌ popup informative statiche

👉 a

✔ radar personali vivi collegati al sistema reale

---

## 🔥 PERSON DETAIL PANEL

Ogni persona ora possiede:

✔ mini calendario mensile reale  
✔ stato giornata  
✔ navigazione mese  
✔ accesso diretto ai giorni reali  

---

## 🧱 COLLEGAMENTO DIRETTO CALENDARIO

Implementato:

✔ tap sul giorno  
✔ apertura automatica Calendario reale  
✔ posizionamento sul giorno corretto  

---

## 👨 MATTEO / 👩 CHIARA

Mini calendario collegato a:

✔ turni reali  
✔ ferie  
✔ malattia  

---

## 👧 ALICE — NUOVA STRUTTURA REALE

La scheda Alice ora legge contemporaneamente:

✔ SchoolStore  
✔ AliceEventStore  
✔ AliceSpecialEventStore  
✔ DiseasePeriodStore  

---

## 🔥 DISTINZIONE STRUTTURALE IMPORTANTE

Decisione ufficiale consolidata:

❌ weekend ≠ vacanza  
❌ scuola chiusa ≠ vacanza  

Il sistema ora distingue:

✔ vacanza reale  
✔ scuola chiusa  
✔ weekend  
✔ centro estivo  
✔ eventi attività Alice  

---

## 🎨 STATI VISIVI ALICE

Implementati:

- scuola
- vacanza
- scuola chiusa
- centro estivo
- evento attività
- uscita anticipata
- malattia

con:

✔ colori dedicati  
✔ icone dedicate  
✔ lettura immediata visiva  

---

## 🧠 SIGNIFICATO ARCHITETTURALE

Nuovo passaggio evolutivo:

❌ Home come dashboard statica

👉

✔ Home come sistema vivo navigabile persona per persona

---

## 🔥 DECISIONE STRUTTURALE NUOVA

Il prossimo step ufficiale NON sarà UI.

Sarà:

👉 conflitti intelligenti reali

Il sistema dovrà iniziare a:

✔ rilevare incompatibilità reali  
✔ spiegare conflitti  
✔ evidenziare problemi decisionali veri  

Esempi:

- evento dentro turno
- due eventi Alice incompatibili
- copertura impossibile
- conflitto lavoro ↔ vita reale

---

## PRINCIPIO

FrodoDesk NON deve nascondere i conflitti.

👉 Deve renderli leggibili e comprensibili.

La decisione resta sempre umana.

---

## 🚀 STATO

✔ stabile  
✔ compilazione verificata  
✔ test reale completato  
✔ mini calendari vivi funzionanti  
✔ navigazione giorno → calendario funzionante  
✔ struttura pronta per conflitti intelligenti

# 🔄 AGGIORNAMENTO 8 Maggio 2026

## 🧠 EVENTI ALICE — EVOLUZIONE COMPORTAMENTALE REALE

Il sistema ha introdotto una nuova evoluzione strutturale:

❌ prima → eventi Alice come semplici elementi calendario

👉

✔ ora → eventi Alice come comportamento reale della presenza di Alice

---

## 🔥 COMPORTAMENTI INTRODOTTI

Nuovi tipi strutturali:

✔ passive  
✔ logistic  
✔ accompanied  
✔ futureAutonomous

---

## 🧱 EVENTI PASSIVI

Rappresentano:

- compiti
- studio
- gioco
- attività in casa

Comportamento:

✔ Alice occupata
✔ resta nello stesso luogo
✔ richiede supervisione adulta

---

## 🚗 EVENTI LOGISTICI

Rappresentano:

- sport
- visite
- attività esterne
- musica

Comportamento:

✔ Alice fuori casa
✔ accompagnamento necessario
✔ ritiro necessario
✔ possibile conflitto reale

---

## 👨 EVENTI ACCOMPAGNATI

Nuovo passaggio fondamentale:

✔ Alice può seguire un adulto reale

Esempi:

- Alice con Matteo
- Alice con Chiara

---

## 🔗 COLLEGAMENTO COPERTURA

Implementato collegamento reale:

Evento accompagnato
→ AliceCompanionStore
→ copertura reale

---

## 🔄 SINCRONIZZAZIONE LIFECYCLE

Il sistema sincronizza automaticamente:

✔ creazione
✔ modifica
✔ cambio orario
✔ cambio adulto
✔ eliminazione

---

## 🧠 NUOVA DISTINZIONE STRUTTURALE

Il sistema distingue ora:

✔ companion manuali
✔ companion generate automaticamente da evento

---

## 🔥 SIGNIFICATO EVOLUTIVO

Questo è il primo vero sistema relazionale:

Alice ↔ adulto ↔ copertura

all’interno del motore reale FrodoDesk.

---

## 🚀 DIREZIONE FUTURA DECISA

Prossimo step ufficiale:

👉 EVENTI LOGISTICI → accompagnamento e ritiro reali

Obiettivi:

✔ chi accompagna
✔ chi ritira
✔ disponibilità reale adulto
✔ conflitti logistici
✔ supporto necessario
✔ Alice al seguito come soluzione reale

---

# 🔄 AGGIORNAMENTO 11 Maggio 2026

## 🔥 HOME + COPERTURA + EVENTI ALICE — ALLINEAMENTO STRUTTURALE

In questa fase è stato corretto un problema architetturale importante:

❌ Home e Calendario potevano leggere la copertura con logiche diverse  
❌ la Home poteva mostrare falsi problemi futuri  
❌ alcuni problemi risolti da rete supporto restavano visibili come aperti  

---

## ✅ FIX: HOME ↔ CALENDARIO ↔ COVERAGEENGINE

La Home è stata riallineata al motore reale di copertura.

Ora:

✔ il prossimo problema futuro viene letto dal motore coerente col Calendario  
✔ la rete supporto reale viene riconosciuta anche in Home  
✔ se un supporto copre davvero la fascia, il problema sparisce  
✔ se il supporto viene tolto, il problema ricompare  
✔ il pulsante “VAI” porta al giorno corretto  

Tag Git:

- `home-support-network-sync`

---

## ✅ FIX: SUPPORTO REALE PER ACCOMPAGNAMENTO SCUOLA

Caso reale validato:

- Beatrice attiva 08:00–08:30
- buco scuola 08:05–08:25

Risultato corretto:

✔ Calendario passa da rosso ad arancione/coperto  
✔ Home non mostra più il problema come aperto  
✔ togliendo Beatrice il problema ricompare  
✔ rimettendo Beatrice il problema sparisce  

---

## ✅ FIX: ALICE DENTRO EVENTO REALE

Corretto falso buco:

evento reale con partecipanti:

- Matteo
- Chiara
- Alice

Prima il motore interpretava:

❌ Matteo fuori  
❌ Chiara fuori  
❌ Alice a casa senza copertura  

Ora il motore interpreta correttamente:

✔ Alice è dentro l’evento reale  
✔ la famiglia è insieme fuori casa  
✔ non viene generato buco “Alice a casa”  
✔ Home non segnala falso rischio  

Implementata funzione strutturale:

- `_isAliceInsideRealEvent()`

usata dentro `analyzeDayV2()`.

Tag Git:

- `alice-real-event-presence`

---

## 🧠 PRINCIPIO NUOVO CONSOLIDATO

Evento reale multi-persona con Alice ≠ Alice sola a casa.

Il motore deve distinguere sempre:

- genitore fuori casa
- Alice a casa

da:

- famiglia insieme dentro evento reale

---

## 🚀 NUOVA FASE UFFICIALE

# MOTORE PRESENZA REALE ALICE

La prossima fase non deve aggiungere solo UI.

Deve centralizzare la domanda:

👉 “Dove si trova realmente Alice?”

Obiettivo:

✔ creare una sorgente unica della presenza Alice  
✔ evitare logiche duplicate tra Home, Calendario e CoverageEngine  
✔ preparare IPS futuro più maturo  
✔ rendere il sistema più stabile e meno soggetto a bug fantasma  

---

## ROADMAP PROSSIMA FASE

☑ Evento logistico Alice: accompagnamento / ritiro  
☑ Logistica incompleta visibile in Calendario  
☑ Logistica incompleta visibile in Home  
☑ Supporto reale sincronizzato Home / Calendario  
☑ Alice dentro evento reale = niente falso buco  
☑ Salvataggi Git e tag fatti  

⬜ Creare `alice_presence_engine.dart`  
⬜ Definire stati Alice: casa / scuola / evento / accompagnata / supporto  
⬜ Far leggere CoverageEngine dal nuovo motore presenza  
⬜ Far leggere Home dallo stesso motore  
⬜ Pulire doppioni logici oggi sparsi tra Home e Calendario  
⬜ Aggiungere test: Alice in evento familiare, supporto, logistica mancante  
⬜ Solo dopo: collegamento IPS più maturo  

---

## STATO ATTUALE

✔ Home coerente con Calendario  
✔ CoverageEngine più realistico  
✔ Eventi multi-persona letti meglio  
✔ Rete supporto validata realmente  
✔ Alice non è più solo “nome evento”, ma inizia a essere entità presente nel motore  

---

## FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — Motore presenza reale Alice: creare `alice_presence_engine.dart` come sorgente unica per decidere dove si trova Alice e ridurre le logiche duplicate tra Home, Calendario e CoverageEngine.
# 🔄 AGGIORNAMENTO 12–13 Maggio 2026

## 🔥 MOTORE PRESENZA REALE ALICE — CONSOLIDAMENTO

Il progetto ha fatto un nuovo salto strutturale.

❌ prima:
CoverageEngine interpretava direttamente la presenza Alice

✔ ora:
la presenza Alice viene progressivamente centralizzata nel nuovo:

`alice_presence_engine.dart`

---

## 🧠 NUOVA DOMANDA STRUTTURALE

Il sistema ora ragiona sulla domanda:

👉 “Dove si trova realmente Alice in questa fascia?”

e NON più solo su eventi o calendario.

---

## ✅ STATI PRESENZA INTRODOTTI

È stato introdotto:

`AlicePresenceState`

Stati attivi:

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Stati futuri previsti:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

## 🔗 CENTRALIZZAZIONI COMPLETATE

CoverageEngine ora legge dal PresenceEngine per:

✔ eventi temporizzati Alice  
✔ eventi reali Alice  
✔ supporto reale  
✔ scuola  
✔ centro estivo  
✔ accompagnamento Alice  

---

## 👨‍👩‍👧 PRESENZA RELAZIONALE

Nuovo passaggio importante:

Alice non è più solo “a casa” o “fuori”.

Ora il sistema distingue:

✔ Alice con adulto  
✔ Alice dentro evento reale familiare  
✔ Alice coperta da supporto reale  
✔ Alice realmente a casa  

---

## 🔥 FIX REALI IMPORTANTI

Corretti bug strutturali reali:

✔ falso buco “Alice a casa” durante eventi multi-persona  
✔ incoerenza Home ↔ Calendario  
✔ supporto reale parziale non validato correttamente  
✔ buco post centro estivo corretto (16:50–21:00)  
✔ separazione reale fascia Sandra sera  

---

## 🧱 NUOVA DIREZIONE STRUTTURALE

CoverageEngine deve progressivamente:

❌ interpretare Alice direttamente  
❌ leggere CompanionStore direttamente  
❌ segmentare manualmente presenza Alice  

e diventare:

✔ consumatore del PresenceEngine  
✔ motore copertura puro  
✔ interprete dei buchi reali  

---

## 🎯 STATO ATTUALE REALE

✔ PresenceEngine attivo  
✔ CoverageEngine collegato  
✔ Home coerente col motore reale  
✔ eventi multi-persona realistici  
✔ supporto reale validato correttamente  
✔ accompagnamento Alice centralizzato  
✔ motore presenza in consolidamento avanzato  

---

## 🚀 DIREZIONE PROSSIMA

NON lavorare ancora su:

❌ Home avanzata  
❌ IPS reale  

Prossimo lavoro corretto:

👉 eliminare i residui legacy presenza Alice dentro CoverageEngine.

In particolare:

- segmentazione eventi
- tagli temporali
- logiche manuali dentro `analyzeDayV2()`

---

## 🧠 SIGNIFICATO EVOLUTIVO

FrodoDesk non sta più solo leggendo eventi.

Sta iniziando a modellare:

✔ presenza reale familiare  
✔ presenza relazionale  
✔ posizione reale nel tempo  
✔ copertura dinamica viva