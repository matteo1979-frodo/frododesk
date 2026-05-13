FRODODESK — RULES

Ultimo aggiornamento: 4 Maggio 2026 (Eventi Globali V1 + Memoria Evento Persistente)

---

IDENTITÀ DEL SISTEMA

FrodoDesk è un sistema di controllo familiare e motore decisionale preventivo.

Non è:

un semplice calendario  
una semplice app turni  
un semplice gestionale spese  

È un sistema che simula la realtà della vita familiare per rendere visibile la pressione prima che diventi problema.

---

PRINCIPIO FONDAMENTALE

Il sistema suggerisce.  
La decisione resta sempre umana.

---

RUOLI

Utente

Responsabile di:

visione strategica  
decisione finale  

---

Frodo

Responsabile di:

architettura sistema  
metodo CNC  
coerenza tecnica  

---

FILOSOFIA DI SVILUPPO

Regole fondamentali:

un passo alla volta  
micro-step  
prima struttura poi estetica  
prima stabilità poi estensione  

Ogni blocco deve essere stabile prima di passare al successivo.

Il progetto segue la logica CNC (Costruzione Non Caotica).

---

REGOLA FILE REALI

Matteo invia sempre il file reale corrente presente nel progetto.

Frodo modifica solo quel file reale.

È vietato:

ricostruire file grandi basandosi sulla memoria  
ipotizzare il contenuto di file non inviati  
sostituire file interi senza partire dal file reale  

Obiettivo:

0 rischio.

---

REGOLA OPERATIVA CHAT

Durante lo sviluppo:

Matteo invia il file reale.  
Frodo restituisce lo stesso file completo modificato.  
Matteo copia e testa nell’app reale.

Mai saltare passaggi.

---

REGOLA “UN PASSO ALLA VOLTA”

Quando Matteo chiede una modifica o verifica:

Frodo deve:

indicare un solo passo  
attendere risposta  
non anticipare passi successivi  

Se vengono dati più passi insieme si rompe la logica CNC.

---

REGOLA TEST

Ogni modifica deve essere testata sull’app reale.

Comando standard:

flutter run -d edge --web-port 8080

---

REGOLA CHIUSURA CHAT

Quando si sta per chiudere una chat di sviluppo:

Matteo scrive:

“Chiudiamo la chat. Quali file docs dobbiamo aggiornare?”

Frodo analizza la chat corrente e indica solo i file che devono davvero essere aggiornati.

Non è obbligatorio aggiornare sempre tutti i file.

Dipende dal lavoro fatto nella chat.

Esempi:

modifica architettura → FRODODESK_ARCHITECTURE.md  
modifica roadmap → FRODODESK_ROADMAP.md  
modifica stato progetto → FRODODESK_SYSTEM_STATE.md  
nuove regole operative → FRODODESK_RULES.md  

Matteo invia solo i file richiesti.

Frodo restituisce ogni file completo aggiornato, pronto da copiare nella cartella docs.

---

PROCEDURA UFFICIALE — CHIUSURA CHAT FRODODESK

(aggiornata con richiesta file + backup dati)

1️⃣ Matteo avvia la chiusura

Matteo scrive:

Chiudiamo la chat. Quali file docs dobbiamo aggiornare?

2️⃣ Frodo analizza la chat e richiede i file

Frodo analizza tutta la chat e verifica modifiche a:

codice  
struttura  
roadmap  
regole  
stato sistema  

👉 Poi DEVE rispondere:

Mandami questi file da aggiornare:

- nome_file  
- nome_file  

⚠️ Solo quelli realmente coinvolti

3️⃣ Matteo invia i file reali

Regole fondamentali:

sempre file completo  
uno alla volta  
mai versioni ricostruite  
presi dalla cartella /docs  

4️⃣ Frodo restituisce i file aggiornati

Formato obbligatorio:

FILE AGGIORNATO  
nome_file  

(contenuto completo)

⚠️ Mai pezzi di file

5️⃣ Matteo aggiorna la cartella docs

Copia i file nella cartella:

/docs  

Poi scrive:

👉 “Fatto”

6️⃣ Salvataggio Git (obbligatorio)

Frodo fornisce i comandi:

git add .  
git commit -m "docs update"  
git push  

7️⃣ BACKUP DATI (quando necessario)

Se Frodo rileva rischio perdita dati (clean, debug, modifiche):

👉 deve attivare backup dati

Contenuti:

- malattia a periodo  
- ferie  
- eventi Alice  
- eventi reali  
- rete supporto  
- quarta squadra  
- override  

Formato:

👉 JSON esportabile

⚠️ Non sempre obbligatorio, ma obbligatorio se c’è rischio

8️⃣ Controllo finale

Verificare:

file docs aggiornati ✔  
copiati ✔  
commit ✔  
push ✔  
backup (se necessario) ✔  

9️⃣ Conferma finale di Frodo

Frodo deve dire:

“Confermo che non ci sono altri file docs da aggiornare.”

Solo dopo la chat è chiusa.

---

REGOLA OBIETTIVO DOCUMENTAZIONE

La cartella docs deve permettere di:

cambiare chat senza perdere contesto  
capire subito lo stato  
ripartire immediatamente  

---

⚠️ REGOLA FONDAMENTALE DEL SISTEMA

La fonte di verità resta:

➡ codice reale

Se docs ≠ codice → vale codice

---

REGOLA DECISIONALE — CONFLITTO TURNO ↔ EVENTO

Quando un evento cade dentro un turno:

👉 è conflitto reale

Il sistema deve:

- evidenziare sovrapposizione  
- mostrare turno  
- mostrare fascia  
- aiutare decisione  

Azioni:

- permesso  
- ferie  
- cambio turno  
- spostamento evento  

---

NUOVE REGOLE — MALATTIA

Distinzione obbligatoria:

Malattia leggera:
- può muoversi  
- può accompagnare Alice  

Malattia a letto:
- non può uscire  
- non disponibile  

---

REGOLA BLOCCANTE

Se stato = Malattia a letto:

👉 vietato cambio turno / override

Sistema deve bloccare o avvisare

---

REGOLA INPS

Durante malattia:

Fasce obbligatorie:

10:00–12:00  
17:00–19:00  

Sistema deve:

- considerare non disponibile  
- segnalare conflitti  
- permettere violazione consapevole  

---

REGOLA “IGNORA RISCHIO”

In caso di violazione INPS:

👉 mostrare:

“Ignora rischio”

Permette azione ma segnala rischio

---

EVOLUZIONE FUTURA MOTORE

Il conflitto evento ↔ turno dipenderà dallo stato:

normale → conflitto pieno  
malattia → valutazione diversa  

(non ancora implementato)

---

# 🔴 NUOVA REGOLA STRUTTURALE — NOTTE / POST-NOTTE

(Introdotta 19 Marzo 2026)

Quando un giorno è marcato come turno NOTTE (`N`):

👉 quel giorno NON rappresenta solo la notte che parte alle 22:00

Ma deve rappresentare SEMPRE tre componenti reali:

1. coda della notte precedente → 00:00–06:30  
2. indisponibilità post-notte → 00:00–14:30  
3. nuova notte la sera → 21:00–06:30  

---

## Regola operativa

👉 Il post-notte è sempre presente se il giorno è `N`

È una **regola fisica della persona**.

---

## Implicazioni

- NON disponibile fino alle 14:30  
- genera buchi reali  
- niente copertura falsa  

---

# 🔥 NUOVA REGOLA STRUTTURALE — AZIONI SENZA SOLUZIONI (CONSOLIDATA)

## PRINCIPIO

Il sistema NON deve proporre soluzioni operative.

## COMPORTAMENTO CORRETTO

✔ rileva il problema  
✔ spiega il problema  
✔ mostra il perché  
✔ porta al punto corretto  

## COMPORTAMENTO VIETATO

❌ suggerire azioni  
❌ decidere al posto dell’utente  

---

# 🔴 NUOVA REGOLA CRITICA — COPERTURA FESTIVI (1 MAGGIO 2026)

## Problema emerso

Nei giorni festivi:

👉 Alice risultava a casa  
👉 ma il sistema poteva NON generare buco  

## Regola corretta

👉 Se Alice è a casa (anche festivo):

SI applica SEMPRE la regola copertura

## Implicazione

✔ festivo ≠ giorno speciale  
✔ festivo ≠ copertura automatica  
✔ festivo segue stessa logica reale  

## Principio finale

👉 La copertura NON dipende dalla scuola  
👉 Dipende SOLO da: presenza reale degli adulti  

---

# 🔴 NUOVA REGOLA — COERENZA HOME ↔ CALENDARIO

## Principio

👉 La Home deve mostrare ESATTAMENTE ciò che il calendario mostra

## Regola

✔ stesso buco  
✔ stessa fascia  
✔ stessi motivi  

## Vietato

❌ Home dice OK ma calendario ha buco  
❌ spiegazioni diverse  

## Obiettivo

👉 una sola verità nel sistema  

---

# 🔴 NUOVA REGOLA — POPUP AZIONI

## Comportamento obbligatorio

Il popup deve mostrare:

✔ problema reale  
✔ fascia oraria  
✔ spiegazione reale  
✔ motivi (Matteo fuori, Chiara fuori, ecc.)  

✔ bottone: "Vai al problema"  

## Vietato

❌ suggerimenti operativi  
❌ azioni automatiche  

## Obiettivo

👉 rendere il problema chiaro  
👉 NON risolverlo automaticamente  

---

# 🔴 NUOVA REGOLA — COERENZA SPIEGAZIONE BUCHI

## Principio

La spiegazione deve essere:

✔ identica tra:
- Home popup  
- Buchi del giorno (calendario)

## Obiettivo

👉 evitare doppie logiche  
👉 evitare confusione  

---

# 🔴 REGOLA CRITICA — CONTINUITÀ DOCUMENTALE (21 Marzo 2026)

(file NON deve mai essere ridotto)

✔ sempre completo  
✔ mai riassunto  
✔ mai semplificato  

👉 memoria viva del sistema  

---

# 🔴 NUOVA REGOLA CRITICA — COPERTURA REALE TEMPORALE

Una copertura è valida SOLO se copre completamente l’intervallo.

supportStart ≤ gapStart  
AND  
supportEnd ≥ gapEnd  

👉 niente coperture parziali  

---

## PRINCIPIO FINALE

👉 Il sistema NON deve mai “pensare che basti”  
👉 Deve verificare che COPRA davvero  
---

# 🔴 NUOVA REGOLA STRUTTURALE — HOME V1.1 (3 Maggio 2026)

## PRINCIPIO

La Home deve separare SEMPRE:

👉 stato reale di oggi  
👉 problemi futuri  

---

## REGOLA

### OGGI

Se oggi è coperto:

✔ icona verde  
✔ testo: "Nessuna criticità oggi"  
✔ nessun falso problema  

---

### FUTURO

Se esiste un problema nei giorni successivi:

✔ deve essere mostrato  
✔ deve essere visibile subito  
✔ deve essere cliccabile  

Esempio:

"Prossimo problema copertura → sabato 30 maggio 13:00–14:30"

---

## VIETATO

❌ nascondere problemi futuri  
❌ dire "tutto ok" se esiste un problema dopo  
❌ creare falso allarme oggi  

---

## REGOLA CRITICA

❌ eliminata definitivamente la logica:

"Nessun problema nei prossimi 30 giorni"

---

## COMPORTAMENTO CORRETTO

✔ oggi = verità immediata  
✔ futuro = visibile e navigabile  
✔ click → calendario giorno corretto  

---

## OBIETTIVO

👉 colpo d’occhio reale  
👉 zero bug cognitivi  
👉 zero interpretazioni  
---

# 🔴 NUOVA REGOLA STRUTTURALE — EVENTI GLOBALI (4 MAGGIO 2026)

## PRINCIPIO

Gli eventi devono essere navigabili nel tempo.

## STRUTTURA

✔ anno  
✔ mesi  
✔ eventi  
✔ dettaglio evento  

## OBIETTIVO

👉 trasformare il calendario in sistema esplorabile  
👉 permettere visione globale del tempo  

## STATO ATTUALE

✔ RealEventStore integrato  
❌ Eventi Alice NON ancora inclusi  

## REGOLA FUTURA

👉 tutti gli eventi devono confluire in un unico sistema globale  

---

# 🔴 NUOVA REGOLA CRITICA — MEMORIA EVENTI (4 MAGGIO 2026)

## PRINCIPIO

Gli eventi NON sono più solo dati temporanei.

👉 diventano memoria reale persistente

## REGOLA

✔ ogni evento deve poter salvare note  
✔ le note devono essere persistenti dopo riavvio  
✔ store e UI devono essere coerenti  

## VIETATO

❌ perdita memoria  
❌ dati temporanei non salvati  

## SIGNIFICATO

👉 FrodoDesk inizia a costruire storico reale della vita  

---

# 🔴 NUOVA REGOLA STRUTTURALE — ARCHITETTURA MODULARE HOME (5 Maggio 2026)

## PRINCIPIO

La Home NON deve contenere logiche complesse.

👉 Deve orchestrare, NON eseguire.

---

## REGOLA

✔ Home legge dati dai moduli  
✔ Home mostra stato e decisione  
✔ Home indirizza l’utente  

❌ Home NON deve:
- contenere logiche pesanti
- calcolare statistiche complesse
- gestire grafici
- duplicare logiche dei moduli

---

## STRUTTURA CORRETTA

- Home → orchestratore  
- Moduli → logica reale  

Esempio:

✔ Statistiche → modulo dedicato  
✔ Copertura → CoverageEngine  
✔ Eventi → Store + Engine  

---

## OBIETTIVO

👉 mantenere il sistema stabile  
👉 evitare file enormi  
👉 permettere evoluzione senza rompere la struttura  

---

# 🔴 NUOVA REGOLA — EVENTI COME MEMORIA (5 Maggio 2026)

## PRINCIPIO

Gli eventi NON sono più temporanei.

👉 diventano memoria reale persistente

---

## REGOLA

✔ ogni evento deve poter salvare note  
✔ le note devono essere persistenti  
✔ la modifica deve aggiornare lo store reale  

---

## VIETATO

❌ eventi senza persistenza  
❌ perdita dati dopo riavvio  
❌ memoria solo visiva  

---

## SIGNIFICATO

👉 FrodoDesk diventa storico reale della vita  

---

# 🔴 NUOVA REGOLA — NAVIGAZIONE TEMPORALE EVENTI (5 Maggio 2026)

## PRINCIPIO

Gli eventi devono essere navigabili nel tempo.

---

## STRUTTURA OBBLIGATORIA

✔ anno  
✔ mesi  
✔ eventi  
✔ dettaglio  

---

## REGOLA TEMPORALE

✔ anno corrente = presente  
✔ anni precedenti = passato  
✔ anni successivi = futuro  

---

## OBIETTIVO

👉 permettere visione completa della vita nel tempo  
👉 costruire base per storico e analisi  

---

# 🔴 NUOVA REGOLA — MODULO STATISTICHE (5 Maggio 2026)

## PRINCIPIO

Le statistiche NON appartengono alla Home.

---

## REGOLA

✔ devono vivere in un modulo separato  
✔ devono essere basate su dati reali  
✔ devono essere visualizzate con grafici  

---

## OBIETTIVO

👉 lettura immediata dei dati  
👉 supporto decisionale visivo  

---

## DIREZIONE FUTURA

Le statistiche includeranno:

- copertura  
- supporto  
- eventi  
- finanze  
- salute  
- attività familiari  

---

## PRINCIPIO CHIAVE

👉 i grafici sono uno strumento decisionale, non estetico

---

# 🔴 NUOVA REGOLA STRUTTURALE — PERSON DETAIL PANEL VIVO (6 Maggio 2026)

## PRINCIPIO

Le schede persona NON devono essere popup statici.

👉 Devono diventare radar vivi della persona.

---

## COMPORTAMENTO OBBLIGATORIO

Ogni PersonDetailPanel deve:

✔ mostrare il mese reale  
✔ mostrare stato reale persona  
✔ mostrare eventi/stati nel tempo  
✔ permettere navigazione diretta al calendario reale  

---

## MINI CALENDARIO

Il mini calendario persona deve essere:

✔ cliccabile  
✔ coerente col motore reale  
✔ collegato al giorno reale del calendario  

---

## REGOLA NAVIGAZIONE

Click su un giorno:

👉 apre direttamente CalendarioScreenStepAStabile sul giorno corretto

---

## REGOLA VISIVA

Il mini calendario NON deve mostrare solo colori.

Deve usare:

✔ pallini stato  
✔ icone contestuali  
✔ significato immediato  

Esempi:

- ferie
- malattia
- notte
- centro estivo
- vacanza
- scuola chiusa
- evento reale

---

## PRINCIPIO UX

La UI deve permettere lettura immediata della vita reale.

NON:

❌ popup vuoti  
❌ schermate decorative  

MA:

✔ navigazione reale  
✔ lettura rapida  
✔ accesso immediato al problema/giorno

---

## DIREZIONE FUTURA

Il PersonDetailPanel diventa:

👉 radar personale operativo del sistema

e sarà base futura per:

- conflitti
- storico persona
- statistiche persona
- timeline reale
- pressione personale
- memoria eventi

---

## STATO

✔ implementato  
✔ compilazione verificata  
✔ testato su app reale  
✔ navigazione giorno funzionante  
✔ icone contestuali funzionanti  
✔ integrazione AliceEventStore funzionante

# 🔴 NUOVA REGOLA STRUTTURALE — EVENTI ALICE COMPORTAMENTALI (8 Maggio 2026)

## PRINCIPIO

Gli Eventi Alice NON sono più semplici eventi calendario.

👉 rappresentano comportamento reale della presenza di Alice.

---

## COMPORTAMENTI UFFICIALI

Il sistema supporta:

✔ passive  
✔ logistic  
✔ accompanied  
✔ futureAutonomous

---

## EVENTO PASSIVO

Evento in cui Alice:

✔ resta nello stesso luogo  
✔ è occupata  
✔ richiede supervisione adulta  

❌ NON richiede accompagnamento

---

## EVENTO LOGISTICO

Evento in cui Alice:

✔ è fuori casa  
✔ richiede accompagnamento  
✔ richiede ritiro  
✔ può generare conflitti reali  

---

## EVENTO ACCOMPAGNATO

Evento in cui:

✔ Alice segue un adulto reale  

Esempi:

- Matteo
- Chiara

---

## REGOLA STRUTTURALE

Evento accompagnato:

Evento Alice
→ genera automaticamente companion coverage

---

## REGOLA CICLO EVENTO

Il lifecycle evento deve restare coerente.

Quindi:

✔ creazione evento → crea companion
✔ modifica evento → aggiorna companion
✔ eliminazione evento → elimina companion

---

## REGOLA CRITICA

Le companion generate automaticamente da evento:

❌ NON devono essere modificabili dai controlli manuali

Per modificarle:

👉 si modifica l’evento sorgente

---

## PRINCIPIO ARCHITETTURALE

La relazione:

Alice ↔ adulto

deve vivere nel motore reale e NON nella sola UI.

---

## DIREZIONE FUTURA

Gli eventi logistici evolveranno verso:

✔ accompagnamento reale
✔ ritiro reale
✔ disponibilità reale adulto
✔ conflitti logistici
✔ supporto reale
✔ Alice al seguito intelligente

---

# 🔴 NUOVA REGOLA STRUTTURALE — PRESENZA REALE ALICE (11 Maggio 2026)

## PRINCIPIO

Alice NON deve essere trattata solo come:

- evento calendario
- etichetta
- presenza implicita

Alice deve essere trattata come entità reale con posizione/stato nel tempo.

---

## DOMANDA CENTRALE

Ogni motore che ragiona su Alice deve poter rispondere a:

👉 “Dove si trova realmente Alice in questa fascia?”

---

## STATI REALI POSSIBILI

Alice può essere:

✔ a casa  
✔ a scuola  
✔ al centro estivo  
✔ dentro evento Alice  
✔ accompagnata da adulto  
✔ dentro evento reale familiare  
✔ coperta da rete supporto  
⬜ autonoma futura  

---

# 🔴 NUOVA REGOLA — EVENTO REALE CON ALICE

## PRINCIPIO

Se un Evento Reale coinvolge Alice:

👉 Alice è dentro quell’evento.

---

## REGOLA

Se un evento reale ha tra i partecipanti:

- Alice

allora, durante l’intervallo dell’evento:

✔ Alice NON è considerata a casa  
✔ NON viene generato buco “Alice a casa”  
✔ Home NON deve mostrare falso problema  
✔ Calendario NON deve mostrare falso buco  

---

## CASO FAMILIARE

Se un evento reale coinvolge:

- Matteo
- Chiara
- Alice

allora il sistema deve interpretare:

✔ famiglia insieme fuori casa

NON:

❌ Matteo fuori  
❌ Chiara fuori  
❌ Alice sola a casa  

---

# 🔴 NUOVA REGOLA — HOME ↔ CALENDARIO ↔ COVERAGE

## PRINCIPIO

Home, Calendario e CoverageEngine devono leggere la stessa verità.

---

## REGOLA

La Home NON deve ricostruire a mano logiche diverse da quelle del motore.

Ogni volta che un problema appare nel Calendario:

✔ deve apparire coerentemente in Home se rilevante  
✔ deve sparire in Home se risolto nel Calendario  
✔ deve portare al giorno corretto  
✔ deve rispettare supporto reale e copertura reale  

---

## BUG RISOLTO

Caso:

- Beatrice copre 08:05–08:25
- buco accompagnamento scuola risolto nel Calendario

Prima:

❌ Home continuava a segnalare problema

Ora:

✔ Home non segnala più il problema  
✔ togliendo Beatrice il problema ricompare  
✔ rimettendola il problema sparisce  

---

# 🔴 NUOVA REGOLA — MOTORE PRESENZA REALE ALICE

## PRINCIPIO

La logica di presenza Alice deve essere centralizzata.

---

## REGOLA OPERATIVA FUTURA

Creare:

`alice_presence_engine.dart`

Responsabilità:

✔ determinare presenza reale Alice  
✔ determinare se Alice è a casa  
✔ determinare se Alice è dentro evento reale  
✔ determinare se Alice è accompagnata  
✔ determinare se Alice è coperta da supporto  
✔ fornire una sola verità a CoverageEngine, Home e IPS  

---

## VIETATO

❌ duplicare logiche presenza Alice in Home  
❌ duplicare logiche presenza Alice nel Calendario  
❌ aggiungere patch sparse senza motore centrale  
❌ far decidere alla UI dove si trova Alice  

---

## OBIETTIVO

Una sola verità:

👉 presenza reale Alice

letta da:

- CoverageEngine
- Home
- Calendario
- IPS futuro
- Statistiche future

---

# 🔴 NUOVA PRIORITÀ ROADMAP

Prima di riallineare IPS o aggiungere nuove UI:

👉 completare il Motore Presenza Reale Alice.

IPS verrà dopo, quando la presenza Alice sarà centralizzata.

---

# 🔴 AGGIORNAMENTO 12 MAGGIO 2026 — PRESENCE ENGINE ATTIVO

## PRINCIPIO

Il Motore Presenza Reale Alice non è più solo previsto.

È stato creato ed è attivo tramite:

`alice_presence_engine.dart`

---

## REGOLA STRUTTURALE AGGIORNATA

CoverageEngine NON deve tornare ad accumulare logiche dirette sulla presenza Alice.

La regola corretta è:

👉 CoverageEngine chiede al PresenceEngine  
👉 PresenceEngine interpreta dove si trova Alice  
👉 CoverageEngine usa il risultato per generare buchi e copertura  

---

## STATI PRESENZA ATTUALI

Il modello `AlicePresenceState` supporta:

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

## REGOLA TEMPORALE PRESENZA

La presenza Alice non deve essere valutata solo “a giornata”.

Deve essere valutata per fascia temporale reale.

Domanda corretta:

👉 “Dove si trova Alice in questa fascia?”

Non:

❌ “Che tipo di giorno è oggi?”  

---

## REGOLA SCUOLA

La scuola non vale automaticamente per tutto il giorno.

La scuola vale solo sulla fascia temporale reale:

- ingresso
- permanenza scuola
- rientro

Fuori da quella fascia, Alice può tornare a essere:

- a casa
- in evento
- accompagnata
- sotto supporto
- al centro estivo
- altro stato futuro

---

## REGOLA CENTRO ESTIVO

Il centro estivo non vale automaticamente per tutto il giorno.

Il centro estivo deve essere interpretato come:

1. ingresso / logistica  
2. permanenza reale  
3. uscita / rientro  
4. casa dopo centro estivo  

---

## FIX STRUTTURALE CENTRO ESTIVO

Caso risolto:

- centro estivo fino alle 16:30
- rientro logistico 20 minuti
- genitori entrambi non disponibili
- fascia Sandra sera separata

Comportamento corretto:

✔ buco uscita centro estivo 16:30–16:50  
✔ buco Alice a casa dopo centro estivo 16:50–21:00  
✔ buco fascia Sandra sera 21:00–22:35  
✔ supporto reale può spezzare i buchi  

---

## REGOLA SUPPORTO

La rete supporto è distinta da Sandra.

- Supporto = persone della rete supporto
- Sandra = categoria separata con fasce dedicate

Il supporto è valido solo se:

✔ è attivo  
✔ è abilitato nel giorno  
✔ copre completamente la fascia reale  

---

## REGOLA PRESENZA RELAZIONALE

Alice può essere accompagnata da un adulto reale.

Questo non è solo “copertura”.

È stato di presenza relazionale:

👉 Alice + adulto

Il sistema deve mantenere distinta:

- Alice a casa
- Alice accompagnata
- Alice coperta da supporto
- Alice dentro evento
- Alice al centro estivo
- Alice a scuola

---

## REGOLA ANTI-DOPPIONE

Da ora, ogni nuova logica sulla presenza di Alice deve essere valutata prima nel PresenceEngine.

Vietato aggiungere nuove patch sparse in:

❌ Home  
❌ Calendario  
❌ CoverageEngine  
❌ UI  

senza prima verificare se appartengono al PresenceEngine.

---

## REGOLA DI PROGRESSIONE

Prima di lavorare su Home o IPS:

1. consolidare PresenceEngine  
2. ripulire CoverageEngine dai residui legacy  
3. verificare casi reali  
4. solo dopo collegare Home alla stessa verità  
5. solo dopo riallineare IPS  