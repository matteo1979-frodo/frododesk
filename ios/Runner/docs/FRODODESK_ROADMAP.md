# FRODODESK — ROADMAP

Ultimo aggiornamento: 14 Marzo 2026

## OBIETTIVO GENERALE

FrodoDesk deve diventare un sistema di controllo familiare che simula la realtà della vita quotidiana per aiutare a prevenire problemi prima che accadano.

Lo sviluppo segue filosofia CNC:
un passo alla volta, blocchi stabili prima di passare al successivo.

---

# FASE ATTUALE

Calendario reale — rifinitura e consolidamento UI.

Obiettivo della fase:
rendere il calendario completamente utilizzabile nella vita reale.

Il calendario deve funzionare come se l’app fosse **solo questo**.

---

# CRITERI DI MATURITÀ DEL CALENDARIO

Il calendario è considerato maturo quando funzionano davvero nella vita reale:

1. Persistenza dati completa  
2. Eventi reali gestiti correttamente  
3. Conflitti gravi rilevati in anticipo  
4. Visione futura reale (ferie, vacanze scuola, ecc.)

Solo dopo si passerà agli altri moduli.

---

# BLOCCO A — FONDAMENTA SISTEMA

Stato: COMPLETATO

Contiene:

- architettura modulare
- store separati
- motore turni
- motore copertura
- override giornalieri
- ferie lunghe
- malattia a periodo
- rete supporto
- quarta squadra

Motori attivi:

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

---

# BLOCCO B — SPIEGAZIONE REALTÀ

Stato: COMPLETATO

Funzioni attive:

- buchi del giorno
- spiegazione umana dei buchi
- pallino copertura
- aggiornamento automatico copertura

---

# BLOCCO C — EVENTI REALI

Stato: IN SVILUPPO

Funzioni previste:

- gestione eventi reali nel calendario
- eventi che influenzano disponibilità persone
- eventi che possono generare buchi reali
- rilevazione sovrapposizione eventi
- collegamento eventi ai turni

---

# BLOCCO D — CALENDARIO REALE COMPLETO

Funzioni previste:

- integrazione completa eventi
- gestione visite
- gestione viaggi
- gestione impegni reali
- eventi Alice scuola completi
- eventi con durata reale

---

# BLOCCO E — CONFLITTI AVANZATI

Funzioni previste:

- rilevazione conflitti turni stesso giorno
- rilevazione conflitti turni consecutivi
- simulazione settimana futura
- simulazione pressione futura

---

# BLOCCO F — SISTEMA IPS

IPS = Indice Pressione Sistema

Obiettivo:

mostrare quanto il sistema familiare è sotto pressione nei prossimi giorni.

IPS deve essere:

- unico numero
- comprensibile
- spiegabile

---

# MODULI FUTURI (DOPO CALENDARIO MATURO)

## FINANZE

Funzioni previste:

- saldo Matteo
- saldo Chiara
- saldo totale
- proiezione anno
- simulazione spese future

---

## SPESE

Funzioni previste:

- spese familiari
- categorizzazione
- collegamento con calendario

---

## SALUTE

Funzioni previste:

- parametri base
- attività fisica
- monitoraggio salute familiare

---

## AUTO

Funzioni previste:

- manutenzione
- scadenze
- costi auto

---

## STATISTICHE / STORICO

Funzioni previste:

- analisi utilizzo supporto
- ore Sandra
- utilizzo rete supporto
- statistiche familiari