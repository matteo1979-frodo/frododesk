FRODODESK — ROADMAP

Ultimo aggiornamento: 15 Marzo 2026

OBIETTIVO GENERALE

FrodoDesk deve diventare un sistema di controllo familiare che simula la realtà della vita quotidiana per aiutare a prevenire problemi prima che accadano.

Lo sviluppo segue filosofia CNC:
un passo alla volta, blocchi stabili prima di passare al successivo.

FASE ATTUALE

Calendario reale — rifinitura e consolidamento UI.

Obiettivo della fase:

rendere il calendario completamente utilizzabile nella vita reale.

Il calendario deve funzionare come se l’app fosse solo questo.

CRITERI DI MATURITÀ DEL CALENDARIO

Il calendario è considerato maturo quando funzionano davvero nella vita reale:

Persistenza dati completa

Eventi reali gestiti correttamente

Conflitti gravi rilevati in anticipo

Visione futura reale (ferie, vacanze scuola, ecc.)

Solo dopo si passerà agli altri moduli.

BLOCCO A — FONDAMENTA SISTEMA

Stato: COMPLETATO

Contiene:

architettura modulare

store separati

motore turni

motore copertura

override giornalieri

ferie lunghe

malattia a periodo

rete supporto

quarta squadra

Motori attivi:

TurnEngine
CoverageEngine
EmergencyDayLogic
FourthShiftCycleLogic

BLOCCO B — SPIEGAZIONE REALTÀ

Stato: COMPLETATO

Funzioni attive:

buchi del giorno

spiegazione umana dei buchi

pallino copertura

aggiornamento automatico copertura

BLOCCO C — EVENTI REALI

Stato: IN SVILUPPO

Funzioni già implementate:

gestione eventi reali nel calendario

visualizzazione eventi sotto i turni

popup eventi multipli

eventi famiglia / generali

rilevazione conflitto turno ↔ evento

Nuova logica conflitti (decisione 15 Marzo 2026)

Quando un evento cade dentro un turno di lavoro, il sistema genera un conflitto reale.

Il conflitto può avere tre stati:

🔴 Conflitto aperto

Evento dentro il turno e nessuna decisione valida.

Esempio:

Conflitto reale turno / evento — Chiara
Visita 13:00–15:30

🟠 Conflitto parzialmente coperto

Una decisione esiste ma non copre tutta la sovrapposizione tra evento e turno.

Esempio:

Conflitto parzialmente coperto — Chiara
Coperto con permesso 13:00–15:00
Resta scoperta la fascia 15:00–15:30 dentro il turno di lavoro

🟢 Conflitto risolto

La decisione copre completamente la parte del turno coinvolta.

Esempio:

Conflitto risolto — Chiara
Risolto con permesso 13:00–15:30
Ordine sviluppo conflitti

1️⃣ Permesso
2️⃣ Ferie
3️⃣ Turno cambiato
4️⃣ Evento spostato

Attualmente si sta implementando la logica completa del caso Permesso.

Funzioni ancora da completare:

pannello decisione conflitto

modifica evento direttamente dal conflitto

collegamento eventi alla simulazione copertura

BLOCCO D — CALENDARIO REALE COMPLETO

Funzioni previste:

integrazione completa eventi

gestione visite

gestione viaggi

gestione impegni reali

eventi Alice scuola completi

eventi con durata reale

BLOCCO E — CONFLITTI AVANZATI

Funzioni previste:

rilevazione conflitti turni stesso giorno

rilevazione conflitti turni consecutivi

simulazione settimana futura

simulazione pressione futura

BLOCCO F — SISTEMA IPS

IPS = Indice Pressione Sistema

Obiettivo:

mostrare quanto il sistema familiare è sotto pressione nei prossimi giorni.

IPS deve essere:

unico numero

comprensibile

spiegabile

MODULI FUTURI (DOPO CALENDARIO MATURO)
FINANZE

Funzioni previste:

saldo Matteo

saldo Chiara

saldo totale

proiezione anno

simulazione spese future

SPESE

Funzioni previste:

spese familiari

categorizzazione

collegamento con calendario

SALUTE

Funzioni previste:

parametri base

attività fisica

monitoraggio salute familiare

AUTO

Funzioni previste:

manutenzione

scadenze

costi auto

STATISTICHE / STORICO

Funzioni previste:

analisi utilizzo supporto

ore Sandra

utilizzo rete supporto

statistiche familiari