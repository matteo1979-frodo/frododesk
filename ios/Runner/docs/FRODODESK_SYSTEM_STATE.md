# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 16 Marzo 2026

# STATO GENERALE DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Il sistema è costruito con filosofia CNC (Costruzione Non Caotica):

ogni blocco deve essere stabile prima di passare al successivo.

# STATO ATTUALE DELLO SVILUPPO

Fase attuale:

Calendario reale — consolidamento operativo.

Il calendario è il cuore del sistema e deve funzionare in modo affidabile nella vita reale prima di introdurre altri moduli.

Checkpoint tecnico raggiunto:

- UI calendario stabilizzata
- metodo `_cardTurni()` riparato
- bottoni gestione turni ripristinati
- introduzione struttura override turni
- primo salvataggio Git stabile dopo modifica struttura turni
- dialog **Nuova rotazione** collegato al sistema reale
- `TurnEngine` collegato correttamente a `rotationOverrideStore`
- logica rotazione nuova verificata in memoria con comportamento coerente
- persistenza `RotationOverrideStore` implementata
- caricamento `rotationOverrideStore.load()` collegato in `CoreStore.init()`
- test reale completato: la nuova rotazione resta attiva dopo chiusura e riavvio app
- aggiunto bottone UI **Rimuovi nuova rotazione attiva**
- rimozione mirata della nuova rotazione per persona selezionata (**Matteo** / **Chiara**)
- conflitto turno ↔ evento visibile nella card Turni
- spiegazione conflitto attiva con stato, turno e fascia in sovrapposizione
- segnale rapido sotto la riga turno: **⚠ Conflitto con turno**
- commit Git creato e push GitHub completato

# MOTORI ATTIVI

TurnEngine

CoverageEngine

EmergencyDayLogic

FourthShiftCycleLogic

# STORE PRINCIPALI

OverrideStore

TurnOverrideStore

RotationOverrideStore

RealEventStore

AliceEventStore

SupportNetworkStore

FeriePeriodStore

DiseasePeriodStore

FourthShiftStore

SettingsStore

# FUNZIONALITÀ ATTUALI

Il sistema gestisce:

- turni lavoro automatici
- quarta squadra
- riposo post-notte
- eventi reali calendario
- eventi Alice scuola
- rete di supporto
- copertura Sandra
- rilevazione buchi giornata
- override giornalieri
- ferie lunghe
- malattia a periodo
- override turni giornalieri
- override turni a periodo
- nuova rotazione turni persistente
- rimozione mirata della nuova rotazione attiva
- rilevazione conflitto turno ↔ evento
- spiegazione del conflitto nella UI Turni
- indicatore rapido conflitto sotto la riga del turno

# GERARCHIA SISTEMA TURNI

Il motore turni applica la seguente gerarchia:

Override giornaliero  
↓  
Override periodo  
↓  
Nuova rotazione  
↓  
Quarta squadra  
↓  
Rotazione base

Questa gerarchia garantisce che una modifica manuale abbia sempre priorità sulla rotazione automatica.

# GESTIONE MODIFICA TURNI

La UI attuale del calendario include quattro strumenti operativi:

- Cambio turno (solo oggi)
- Cambio turno (periodo)
- Nuova rotazione
- Rimuovi nuova rotazione attiva

### Nuova rotazione turni

È stato introdotto il dialog operativo **Nuova rotazione** nel calendario.

Questa funzione permette di impostare una nuova rotazione turni personale quando
la rotazione standard dell’azienda non è più valida.

Parametri della rotazione:

- Persona (Matteo / Chiara)
- Data di inizio
- Turno iniziale (Mattina / Pomeriggio / Notte)

Questa funzione è separata da:

- Quarta squadra
- Override giornalieri
- Override periodo

### Rimozione nuova rotazione attiva

È stato aggiunto un comando UI dedicato:

**Rimuovi nuova rotazione attiva**

Comportamento:

- chiede quale persona selezionare (**Matteo** / **Chiara**)
- rimuove solo la nuova rotazione attiva della persona scelta
- non tocca l’eventuale nuova rotazione dell’altra persona
- dopo la rimozione, il motore torna automaticamente alla gerarchia normale del sistema turni

Questa rimozione è mirata e non è un reset totale ambiguo.

# LOGICA ATTUALE NUOVA ROTAZIONE

La nuova rotazione è collegata al motore turni reale.

Regola implementata e verificata:

- ciclo a blocchi **5-5-5**
- sequenza: **Mattina → Notte → Pomeriggio**
- il turno iniziale scelto nel dialog diventa il punto di partenza del ciclo
- sabato e domenica risultano **OFF**
- sabato e domenica **non contano** nel conteggio dei 5 giorni lavorativi
- la rotazione viene letta con priorità superiore a Quarta Squadra e rotazione base
- il sistema usa `RotationOverrideStore` come sorgente per il `TurnEngine`

Esempio:

- 5 giorni lavorativi Mattina
- poi 5 giorni lavorativi Notte
- poi 5 giorni lavorativi Pomeriggio
- poi il ciclo ricomincia

# STATO IMPLEMENTAZIONE NUOVA ROTAZIONE

Stato reale al termine della sessione:

UI dialog: ✅ completata  
Salvataggio nello store: ✅ completato  
Collegamento `CoreStore` → `TurnEngine`: ✅ completato  
Lettura da parte del motore turni: ✅ completata  
Logica 5-5-5 con weekend OFF fuori conteggio: ✅ completata  
Persistenza dopo riavvio / riapertura app: ✅ implementata e verificata  
Rimozione mirata da UI: ✅ implementata e verificata  
Test reale in app: ✅ superato  

Conclusione attuale:

**Nuova rotazione: funzione completa (creazione, lettura, persistenza, rimozione mirata).**

# CONFLITTO TURNO ↔ EVENTO

Il sistema rileva automaticamente quando:

evento ∩ turno ≠ ∅

cioè quando un evento cade dentro un turno di lavoro.

Il controllo è attivo nella card **Turni** e usa:

- turno reale letto dal `TurnEngine`
- eventi reali letti da `RealEventStore`
- eventuale stato giornaliero / permesso già presente
- calcolo della fascia reale di sovrapposizione

# STATI DEL CONFLITTO

Decisione di progetto — 15 Marzo 2026.

Il conflitto può avere tre stati.

🔴 Conflitto aperto

Evento dentro il turno e nessuna decisione valida.

🟠 Conflitto parzialmente coperto

Una decisione esiste ma non copre tutta la sovrapposizione tra evento e turno.

Esempio:

Coperto con permesso 13:00–15:00

Resta scoperta la fascia 15:00–15:30 dentro il turno.

🟢 Conflitto risolto

La decisione copre completamente la sovrapposizione tra evento e turno.

# STATO ATTUALE IMPLEMENTAZIONE CONFLITTO

Attualmente il sistema:

- rileva correttamente quando un evento cade dentro il turno
- mostra un box conflitto dedicato nella card **Turni**
- mostra:
  - titolo conflitto
  - stato del conflitto
  - turno interessato
  - fascia reale in conflitto
- mostra sotto la riga del turno un indicatore rapido:

**⚠ Conflitto con turno**

Test reale verificato in app:

- turno Matteo: **Mattina 06:00–14:00**
- evento Matteo: **visita 12:30–13:30**
- risultato: conflitto correttamente segnalato in UI

# ORDINE IMPLEMENTAZIONE

1. Permesso
2. Ferie
3. Turno cambiato
4. Evento spostato

Attualmente è attiva la base del caso **Permesso** e la rilevazione conflitto evento ↔ turno è stata verificata in UI.

# PROSSIMO PASSO SVILUPPO

Prossimo step ufficiale:

**continuare il lavoro sul conflitto turno ↔ evento**

Focus del prossimo blocco:

- rifinire la logica decisionale del conflitto
- estendere il comportamento in base allo stato reale della persona
- valutare la differenza tra:
  - conflitto operativo vero
  - situazione da rivalutare

# NOTA PROGETTUALE EMERSA IN QUESTA CHAT

È emersa una decisione progettuale importante per l’evoluzione del motore:

se la persona è in **malattia leggera** o **malattia a letto**, il conflitto evento ↔ turno non dovrebbe necessariamente essere trattato sempre come rosso pieno.

Possibile evoluzione futura:

- stato normale → conflitto rosso
- malattia → valutazione più morbida / gialla / “evento da rivalutare”

Questa logica non è ancora implementata nel codice ma va considerata come direzione progettuale ufficiale per il motore decisionale.

# CHIUSURA STATO SESSIONE

Stato reale al termine di questa chat:

- nuova rotazione completata
- persistenza verificata
- rimozione mirata UI verificata
- conflitto turno ↔ evento visibile e funzionante
- sistema salvato in Git e GitHub
- prossimo lavoro da riprendere in chat nuova: **conflitto turno ↔ evento**