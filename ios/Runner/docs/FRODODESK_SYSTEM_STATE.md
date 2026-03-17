# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 17 Marzo 2026

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

Checkpoint tecnico aggiornato:

- UI calendario stabilizzata
- metodo `_cardTurni()` riparato
- bottoni gestione turni ripristinati
- introduzione struttura override turni
- nuova rotazione turni completa (creazione, lettura, persistenza, rimozione)
- conflitto turno ↔ evento visibile nella card Turni
- introduzione gestione conflitto risolto anche tramite **Ferie**
- correzione logica Alice scuola vs vacanza (`AliceEventStore.isSchoolNormalDay`)
- fix crash UI `TextEditingController disposed`
- sistema stabile in esecuzione reale
- verifica profonda completata sul motore di copertura reale
- controllata tutta la catena logica:
  - `_busyShiftsFromRealEventsForPerson`
  - `OverrideApply.applyToBusyShifts`
  - `_isFasciaCovered`
  - `isTimeCovered`
  - `_uncoveredHomeSegments`
- confermato che la copertura combinata Matteo + Chiara è coerente anche nei segmenti intermedi
- verifica finale eseguita in app reale con esito corretto: **Copertura OK**

# 🔥 FIX CRITICO COMPLETATO (17 Marzo 2026)

## Problema

Caso reale:

- Chiara in ferie
- evento reale Chiara 09:00–10:00
- Matteo presente fino alle 13:00
- Chiara rientra alle 10:00

RISULTATO ERRATO (prima):

→ BUCO 07:30–16:25  
→ RISCHIO ALICE A CASA  

## Comportamento corretto

- 07:30–09:00 → Chiara presente
- 09:00–10:00 → Matteo presente
- 10:00+ → Chiara torna disponibile

→ Alice **non è mai sola**  
→ Copertura **OK tutto il giorno**

## Soluzione implementata

Aggiornata la logica in:

- `coverage_logic.dart`
- `coverage_engine.dart`

Ora il sistema:

- combina correttamente la presenza Matteo + Chiara
- gestisce eventi temporanei (visite)
- gestisce rientro dopo evento
- elimina falsi buchi Alice

## Verifica reale effettuata

✔ Caso 1  
Chiara ferie + visita → COPERTURA OK

✔ Caso 2  
Chiara visita + Matteo visita sovrapposta →  
BUCO reale rilevato → 09:30–10:00

✔ Verifica aggiuntiva di solidità  
Controllata manualmente l’intera catena del motore di copertura sui punti critici senza trovare incoerenze residue.

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
- gestione conflitto risolto tramite:
  - permesso
  - ferie
- spiegazione del conflitto nella UI Turni
- indicatore rapido conflitto sotto la riga del turno
- copertura combinata reale Matteo + Chiara ✔

# GERARCHIA SISTEMA TURNI

Override giornaliero  
↓  
Override periodo  
↓  
Nuova rotazione  
↓  
Quarta squadra  
↓  
Rotazione base  

# LOGICA CONFLITTO TURNO ↔ EVENTO

Il sistema rileva automaticamente quando:

evento ∩ turno ≠ ∅

e classifica:

🔴 Conflitto aperto  
🟠 Conflitto parziale  
🟢 Conflitto risolto  

Supporto attivo:

- Permesso ✔
- Ferie ✔

# STATO UI

File:

`calendario_screen_stepa.dart`

Situazione attuale:

- UI stabilizzata e funzionante
- nessun errore di compilazione

✔ Miglioramento introdotto:

- rimozione dettagli buchi dal box principale
- introduzione popup su "Buchi del giorno"
- visualizzazione dettagli solo su richiesta utente
- aggiunta indicatori visivi ⚠ nelle cause del buco

Risultato:

- UI più pulita
- migliore leggibilità
- separazione tra sintesi (box) e dettaglio (popup)

# STATO GENERALE

Sistema stabile e utilizzabile.

Logica copertura:
✔ corretta  
✔ verificata su casi reali  
✔ senza falsi positivi  
✔ controllata nei punti logici più delicati  
✔ confermata in app reale  

UI:
✔ più pulita  
✔ più leggibile  
✔ comportamento coerente con uso reale  

# PROSSIMO PASSO

- integrazione Eventi Reali nei Turni
- lettura eventi del giorno da `RealEventStore`
- visualizzazione accanto ai turni di Matteo e Chiara
- trattamento come conflitti reali, non come semplice informazione

File previsto:

`lib/screens/calendario_screen_stepa.dart`