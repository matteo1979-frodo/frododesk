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
- nuova rotazione turni (in memoria, non ancora persistente)

# GERARCHIA SISTEMA TURNI

Il motore turni ora applica la seguente gerarchia:

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

La UI attuale del calendario include tre strumenti operativi:

- Cambio turno (solo oggi)
- Cambio turno (periodo)
- Nuova rotazione

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

# LOGICA ATTUALE NUOVA ROTAZIONE

La nuova rotazione è ora collegata al motore turni reale.

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
Test reale in app nella stessa sessione: ✅ superato  
Persistenza dopo riavvio / riapertura app: ❌ non ancora implementata

Conclusione attuale:

**Nuova rotazione: logica e motore OK, persistenza ancora da implementare.**

# CONFLITTO TURNO ↔ EVENTO

Il sistema rileva automaticamente quando:

evento ∩ turno ≠ ∅

cioè quando un evento cade dentro un turno di lavoro.

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

# ORDINE IMPLEMENTAZIONE

1. Permesso
2. Ferie
3. Turno cambiato
4. Evento spostato

Attualmente si sta implementando la logica completa del caso **Permesso**.

# PROSSIMO PASSO SVILUPPO

Rendere persistente `RotationOverrideStore`, così la **Nuova rotazione** resti attiva anche dopo chiusura o riavvio dell’app.

Successivamente verrà completata la gestione:

- persistenza nuova rotazione
- rimozione / reset rotazione da UI
- risoluzione completa conflitto evento-turno