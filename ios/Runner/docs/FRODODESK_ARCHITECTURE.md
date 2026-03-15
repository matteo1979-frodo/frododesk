# FRODODESK — ARCHITECTURE

Ultimo aggiornamento: 14 Marzo 2026

## PRINCIPIO ARCHITETTURALE

FrodoDesk è costruito con architettura modulare.

Ogni parte del sistema vive in moduli indipendenti.

Obiettivo:
modificare un blocco senza rompere gli altri.

Regola fondamentale:
la logica non deve vivere dentro la UI.

---

# STRUTTURA GENERALE PROGETTO

Struttura principale del progetto:

lib/
 ├─ models
 ├─ logic
 │   ├─ engines
 │   └─ stores
 ├─ widgets
 ├─ screens

Nota:
la cartella `logic` contiene sia i motori del sistema sia gli store che gestiscono lo stato.

---

# MODELS

I models rappresentano le strutture dati del sistema.

Contengono solo dati, senza logica complessa.

Esempi:

DayOverride  
DiseasePeriod  
RealEvent  
WeekIdentity  

---

# LOGIC

La cartella `logic` contiene la logica reale del sistema.

Qui non deve vivere la UI.

La logica è divisa in due grandi gruppi:

- engines
- stores

---

# ENGINES (MOTORI)

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

---

# STORES (STATO SISTEMA)

OverrideStore  
DiseasePeriodStore  
FeriePeriodStore  
SupportNetworkStore  
RealEventStore  
AliceEventStore  

---

# UI

La UI collega i moduli senza mescolare la logica.

Schermata principale attuale:

Calendario reale.

File principale:

lib/screens/calendario_screen_stepa.dart