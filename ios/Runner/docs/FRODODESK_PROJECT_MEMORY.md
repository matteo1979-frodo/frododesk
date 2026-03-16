# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 15 Marzo 2026

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

il calendario deve segnalarlo chiaramente come **conflitto reale**.

La risoluzione richiede sempre una decisione umana:

- cambiare turno
- prendere ferie o permesso
- spostare l’evento

Il sistema non decide al posto dell’utente.

---

## Filosofia del calendario

Il calendario FrodoDesk non è solo un calendario eventi.

È una **simulazione operativa della realtà familiare**.

Il suo compito è:

- evidenziare problemi reali
- spiegare perché accadono
- aiutare a prendere decisioni prima che diventino emergenze.