FRODODESK — RULES

Ultimo aggiornamento: 13 Maggio 2026
(PresenceEngine attivo + consolidamento CoverageEngine)

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

È una regola fisica della persona.

---

## Implicazioni

- NON disponibile fino alle 14:30
- genera buchi reali
- niente copertura falsa

---

# 🔥 NUOVA REGOLA STRUTTURALE — AZIONI SENZA SOLUZIONI

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

# 🔴 NUOVA REGOLA CRITICA — COPERTURA FESTIVI

## REGOLA

👉 Se Alice è a casa (anche festivo):

SI applica SEMPRE la regola copertura

## PRINCIPIO FINALE

👉 La copertura NON dipende dalla scuola
👉 Dipende SOLO dalla presenza reale degli adulti

---

# 🔴 NUOVA REGOLA — COERENZA HOME ↔ CALENDARIO

## PRINCIPIO

👉 La Home deve mostrare ESATTAMENTE ciò che il calendario mostra

## REGOLA

✔ stesso buco
✔ stessa fascia
✔ stessi motivi

## VIETATO

❌ Home dice OK ma calendario ha buco
❌ spiegazioni diverse

---

# 🔴 NUOVA REGOLA — POPUP AZIONI

## COMPORTAMENTO OBBLIGATORIO

Il popup deve mostrare:

✔ problema reale
✔ fascia oraria
✔ spiegazione reale
✔ motivi (Matteo fuori, Chiara fuori, ecc.)

✔ bottone: "Vai al problema"

## VIETATO

❌ suggerimenti operativi
❌ azioni automatiche

---

# 🔴 NUOVA REGOLA — COERENZA SPIEGAZIONE BUCHI

## PRINCIPIO

La spiegazione deve essere identica tra:

- Home popup
- Buchi del giorno

---

# 🔴 REGOLA CRITICA — CONTINUITÀ DOCUMENTALE

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

# 🔴 NUOVA REGOLA STRUTTURALE — HOME V1.1

## PRINCIPIO

La Home deve separare SEMPRE:

👉 stato reale di oggi
👉 problemi futuri

---

## COMPORTAMENTO CORRETTO

✔ oggi = verità immediata
✔ futuro = visibile e navigabile
✔ click → calendario giorno corretto

---

# 🔴 NUOVA REGOLA STRUTTURALE — EVENTI GLOBALI

## PRINCIPIO

Gli eventi devono essere navigabili nel tempo.

## STRUTTURA

✔ anno
✔ mesi
✔ eventi
✔ dettaglio

---

# 🔴 NUOVA REGOLA CRITICA — MEMORIA EVENTI

## PRINCIPIO

Gli eventi NON sono più solo dati temporanei.

👉 diventano memoria reale persistente

---

# 🔴 NUOVA REGOLA STRUTTURALE — ARCHITETTURA MODULARE HOME

## PRINCIPIO

La Home NON deve contenere logiche complesse.

👉 Deve orchestrare, NON eseguire.

---

# 🔴 NUOVA REGOLA — MODULO STATISTICHE

## PRINCIPIO

Le statistiche NON appartengono alla Home.

👉 devono vivere in un modulo separato

---

# 🔴 NUOVA REGOLA STRUTTURALE — PERSON DETAIL PANEL VIVO

## PRINCIPIO

Le schede persona NON devono essere popup statici.

👉 Devono diventare radar vivi della persona.

---

# 🔴 NUOVA REGOLA STRUTTURALE — EVENTI ALICE COMPORTAMENTALI

## PRINCIPIO

Gli Eventi Alice NON sono più semplici eventi calendario.

👉 rappresentano comportamento reale della presenza di Alice.

---

## COMPORTAMENTI UFFICIALI

✔ passive
✔ logistic
✔ accompanied
✔ futureAutonomous

---

# 🔴 NUOVA REGOLA STRUTTURALE — PRESENZA REALE ALICE

## PRINCIPIO

Alice NON deve essere trattata solo come:

- evento calendario
- etichetta
- presenza implicita

Alice deve essere trattata come entità reale con posizione/stato nel tempo.

---

## DOMANDA CENTRALE

👉 “Dove si trova realmente Alice in questa fascia?”

---

## STATI REALI POSSIBILI

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

Durante l’intervallo dell’evento:

✔ Alice NON è considerata a casa
✔ NON viene generato falso buco casa
✔ Home NON deve mostrare falso problema
✔ Calendario NON deve mostrare falso buco

---

# 🔴 NUOVA REGOLA — HOME ↔ CALENDARIO ↔ COVERAGE

## PRINCIPIO

Home, Calendario e CoverageEngine devono leggere la stessa verità.

---

## REGOLA

La Home NON deve ricostruire logiche diverse dal motore.

---

# 🔴 NUOVA REGOLA — MOTORE PRESENZA REALE ALICE

## PRINCIPIO

La logica presenza Alice deve essere centralizzata.

---

## MOTORE ATTIVO

È stato creato:

`alice_presence_engine.dart`

---

## RESPONSABILITÀ

Il PresenceEngine deve:

✔ determinare presenza reale Alice
✔ determinare se Alice è a casa
✔ determinare se Alice è dentro evento reale
✔ determinare se Alice è accompagnata
✔ determinare se Alice è coperta da supporto
✔ fornire una sola verità a:
- CoverageEngine
- Home
- Calendario
- IPS futuro

---

## STATI PRESENZA ATTUALI

`AlicePresenceState`

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

## REGOLA TEMPORALE PRESENZA

La presenza Alice deve essere valutata per fascia reale.

Domanda corretta:

👉 “Dove si trova Alice in questa fascia?”

NON:

❌ “Che tipo di giorno è oggi?”

---

## REGOLA SCUOLA

La scuola vale solo sulla fascia reale:

- ingresso
- permanenza
- rientro

Fuori da quella fascia Alice può tornare:

- a casa
- in evento
- accompagnata
- sotto supporto
- al centro estivo

---

## REGOLA CENTRO ESTIVO

Il centro estivo deve essere interpretato come:

1. ingresso/logistica
2. permanenza reale
3. uscita/rientro
4. casa dopo centro estivo

---

## REGOLA SUPPORTO

La rete supporto è distinta da Sandra.

- Supporto = rete supporto
- Sandra = categoria separata

Il supporto è valido solo se:

✔ attivo
✔ abilitato nel giorno
✔ copre completamente la fascia

---

## REGOLA PRESENZA RELAZIONALE

Alice può essere:

✔ accompagnata da adulto
✔ dentro evento familiare
✔ coperta da supporto
✔ a casa
✔ a scuola
✔ al centro estivo

Questi stati NON devono essere fusi.

---

## REGOLA ANTI-DOPPIONE

Ogni nuova logica presenza Alice deve essere valutata PRIMA nel PresenceEngine.

Vietato aggiungere patch sparse in:

❌ Home
❌ Calendario
❌ CoverageEngine
❌ UI

senza prima verificare il PresenceEngine.

---

## REGOLA DI PROGRESSIONE

Prima di lavorare su:

- Home avanzata
- IPS

serve:

1. consolidare PresenceEngine
2. ripulire CoverageEngine dai residui legacy
3. verificare casi reali
4. collegare tutto alla stessa verità

---

# 🔴 NUOVA REGOLA — COVERAGEENGINE CONSUMATORE

## PRINCIPIO

CoverageEngine NON deve più interpretare direttamente Alice.

Deve diventare:

✔ motore copertura puro
✔ interprete buchi reali
✔ consumatore del PresenceEngine

---

## VIETATO

❌ leggere CompanionStore direttamente
❌ segmentare manualmente Alice
❌ duplicare presenza Alice
❌ ricostruire stati Alice

---

## DIREZIONE STRUTTURALE

PresenceEngine
↓
CoverageEngine
↓
Home / Calendario / IPS futuro

---

# 🔴 NUOVA REGOLA — BUG FANTASMA COPERTURA

## PRINCIPIO

Un buco NON deve mai esistere se:

✔ supporto copre davvero
✔ Alice è dentro evento reale
✔ Alice è accompagnata
✔ Alice non è realmente a casa

---

## CASI RISOLTI

✔ falso buco Alice durante evento reale multi-persona
✔ falso problema Home con supporto reale valido
✔ doppio buco serale dovuto a segmentazione errata
✔ buco post-centro-estivo incoerente

---

# 🔴 DIREZIONE OPERATIVA ATTUALE

NON fare:

❌ IPS
❌ mega-refactor
❌ Home avanzata

Fare:

✔ consolidamento PresenceEngine
✔ cleanup CoverageEngine
✔ eliminazione doppioni legacy
✔ test reali continui
✔ centralizzazione presenza Alice

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — PresenceEngine attivo, CoverageEngine in progressiva pulizia. Prossimo passo: eliminare residui legacy presenza Alice dentro CoverageEngine senza toccare Home e senza riallineare IPS.
---

# 🔴 NUOVA REGOLA STRUTTURALE — FINANZE vs SPESE

## PRINCIPIO

Finanze e Spese NON sono lo stesso modulo.

Devono nascere separati.

---

## FINANZE

Domanda:

👉 “Dove stiamo andando?”

Finanze rappresenta:

✔ simulazione futura  
✔ sostenibilità  
✔ pressione economica  
✔ fondi  
✔ previsione  

---

## SPESE

Domanda:

👉 “Cosa è successo davvero?”

Spese rappresenta:

✔ memoria reale del denaro  
✔ movimenti reali  
✔ storico reale  
✔ comportamento economico reale  

---

# 🔴 NUOVA REGOLA FONDAMENTALE — PREVISIONE ≠ REALTÀ

Una previsione NON equivale a realtà economica.

Esempi:

✔ Netflix prevista ≠ pagamento reale  
✔ stipendio stimato ≠ stipendio ricevuto  
✔ assicurazione prevista ≠ importo reale futuro  

---

# 🔴 NUOVA REGOLA — CONTROLLO UMANO ECONOMICO

Il sistema economico:

✔ può simulare  
✔ può avvisare  
✔ può mostrare rischio  
✔ può mostrare pressione  

MA:

❌ non decide  
❌ non blocca  
❌ non vieta spese  

Anche se:

- il saldo cala
- i fondi si svuotano
- la simulazione peggiora
- la pressione cresce

👉 la decisione resta sempre umana.

---

# 🔴 NUOVA REGOLA — SALDI REALI

I saldi economici:

✔ partono da inserimento manuale reale  
✔ devono poter essere riallineati manualmente  

Il sistema NON deve assumere automaticamente che la simulazione coincida col saldo reale.

---

# 🔴 NUOVA REGOLA — STIPENDI

Gli stipendi possono essere:

✔ simulati
✔ stimati
✔ previsti tramite storico

MA:

✔ il valore reale mensile deve essere confermato manualmente.

---

# 🔴 NUOVA REGOLA — SPESE IMPREVEDIBILI

Il sistema deve convivere con spese impossibili da prevedere.

Esempi:

- benzina variabile
- prelievi
- emergenze
- acquisti casuali

Il sistema deve:

✔ registrarle
✔ imparare statisticamente
✔ mostrarne il peso storico

MA:

❌ non fingere previsione perfetta.

---

# 🔴 NUOVA REGOLA STRUTTURALE — MODULI ECONOMICI

Finanze, Spese e Statistiche devono crescere:

✔ separati
✔ modulari
✔ collegabili progressivamente

Principio architetturale:

👉 “app dentro app dentro app”

---

# 🔴 NUOVA REGOLA — STATISTICHE ECONOMICHE

Statistiche deve diventare:

✔ lettura del passato
✔ lettura del presente
✔ lettura evolutiva futura

leggendo:

- spese reali
- finanze
- fondi
- categorie
- trend familiari

---

# 🔴 NUOVA REGOLA — PERSONE ECONOMICHE

Il sistema economico deve già conoscere:

✔ Matteo
✔ Chiara
✔ Alice

anche se Alice oggi non possiede ancora:

- conto
- entrate
- spese autonome

Questo per permettere:

✔ crescita futura
✔ statistiche evolutive
✔ coerenza sistema