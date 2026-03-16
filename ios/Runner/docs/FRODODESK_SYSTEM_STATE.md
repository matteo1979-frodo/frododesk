# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 15 Marzo 2026

---

# STATO GENERALE DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Il sistema è costruito con filosofia CNC (Costruzione Non Caotica):

ogni blocco deve essere stabile prima di passare al successivo.

---

# STATO ATTUALE DELLO SVILUPPO

Fase attuale:

Calendario reale — consolidamento operativo.

Il calendario è il cuore del sistema e deve funzionare in modo affidabile nella vita reale prima di introdurre altri moduli.

---

# MOTORI ATTIVI

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

---

# STORE PRINCIPALI

OverrideStore  
RealEventStore  
AliceEventStore  
SupportNetworkStore  
FeriePeriodStore  
DiseasePeriodStore  
FourthShiftStore  
SettingsStore  

---

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

---

# CONFLITTO TURNO ↔ EVENTO

Il sistema rileva automaticamente quando:

evento ∩ turno ≠ ∅

cioè quando un evento cade dentro un turno di lavoro.

---

# STATI DEL CONFLITTO

Decisione di progetto — 15 Marzo 2026.

Il conflitto può avere tre stati.

---

🔴 Conflitto aperto

Evento dentro il turno e nessuna decisione valida.

---

🟠 Conflitto parzialmente coperto

Una decisione esiste ma non copre tutta la sovrapposizione tra evento e turno.

Esempio:

Coperto con permesso 13:00–15:00  
Resta scoperta la fascia 15:00–15:30 dentro il turno.

---

🟢 Conflitto risolto

La decisione copre completamente la sovrapposizione tra evento e turno.

---

# ORDINE IMPLEMENTAZIONE

1. Permesso  
2. Ferie  
3. Turno cambiato  
4. Evento spostato  

Attualmente si sta implementando la logica completa del caso **Permesso**.

---

# PROSSIMO PASSO SVILUPPO

Implementazione della funzione di valutazione conflitto turno ↔ evento per il caso Permesso.