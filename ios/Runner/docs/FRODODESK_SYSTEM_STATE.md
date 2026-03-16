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

# MOTORI ATTIVI

TurnEngine

CoverageEngine

EmergencyDayLogic

FourthShiftCycleLogic

# STORE PRINCIPALI

OverrideStore

TurnOverrideStore

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

# GERARCHIA SISTEMA TURNI

Il motore turni ora applica la seguente gerarchia:

Override giornaliero  
↓  
Override periodo  
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

Il pulsante **Nuova rotazione** è stato introdotto per preparare la futura gestione delle rotazioni turni personalizzate.

Attualmente il pulsante è presente in UI ma la logica completa di creazione rotazione sarà implementata negli step successivi.

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

Implementazione della funzione di valutazione conflitto turno ↔ evento per il caso Permesso.

Successivamente verrà completata la gestione:

- cambio turno strutturato
- nuova rotazione turni
- risoluzione completa conflitto evento-turno