# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 17 Marzo 2026

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

---

# AGGIORNAMENTO — 17 Marzo 2026

## Copertura reale (fix critico validato)

Risolto un caso reale complesso nella gestione della copertura:

Scenario:
- Chiara in ferie
- evento reale Chiara 09:00–10:00
- Matteo presente fino alle 13:00

Problema:
il sistema generava un falso buco “Alice a casa” nonostante la copertura reale fosse continua.

Causa:
la copertura non considerava correttamente la continuità tra Matteo e Chiara nei cambi di presenza durante la giornata.

Soluzione strutturale:
- eventi reali integrati nei busy shifts anche in presenza di ferie/malattia
- segmentazione completa della giornata in micro-fasce temporali
- utilizzo coerente di `isTimeCovered` su copertura combinata multi-persona
- verifica della copertura reale su ogni segmento (non solo sulla fascia intera)

Risultato:
- eliminati i falsi positivi
- copertura coerente con la realtà fisica della giornata
- comportamento stabile anche nei cambi intermedi (staffetta tra persone)

Validazione:
il motore di copertura è stato controllato nei punti critici:

- costruzione busy shifts (turni + eventi reali)
- applicazione override
- logica `_isFasciaCovered`
- funzione `isTimeCovered`
- segmentazione `_uncoveredHomeSegments`

e testato direttamente sull’app reale con esito corretto.

Stato attuale:
la logica di copertura è considerata **affidabile per uso reale**.