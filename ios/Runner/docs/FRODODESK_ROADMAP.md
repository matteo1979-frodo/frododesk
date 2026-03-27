FRODODESK — ROADMAP

Ultimo aggiornamento: 25 Marzo 2026

OBIETTIVO GENERALE

FrodoDesk deve diventare un sistema di controllo familiare che simula la realtà della vita quotidiana per aiutare a prevenire problemi prima che accadano.

Lo sviluppo segue filosofia CNC:
un passo alla volta, blocchi stabili prima di passare al successivo.

FASE ATTUALE

Calendario reale — consolidamento logica copertura + rifinitura UI.

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

✔ AGGIORNAMENTO 17 Marzo 2026

Risolto problema critico nella simulazione reale:

- il sistema ora gestisce correttamente la copertura combinata Matteo + Chiara
- gli eventi temporanei (visite) non generano più falsi buchi
- il motore rileva correttamente buchi reali (es. 09:30–10:00)

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

---

# 🔥 AGGIORNAMENTO — 25 MARZO 2026 (ALLINEAMENTO REALE + PULIZIA ROADMAP)

## Stato reale aggiornato

Durante le ultime chat è emerso chiaramente che:

- molte parti segnate come "da fare" sono in realtà già completate e funzionanti
- il sistema è più avanti rispetto a quanto indicato in roadmap

In particolare:

✔ conflitti turno ↔ evento → già funzionanti e validati in app reale  
✔ gestione permesso → già operativa e stabile  
✔ copertura combinata → stabile  
✔ eventi Alice → stabilizzati  
✔ Sandra → funzionante su tutte le fasce  

👉 Questo comporta una revisione pratica della roadmap:

la fase non è più di costruzione logica base  
ma di **uso reale + rifinitura UX/UI**

---

## Nuovo focus reale della fase

La priorità NON è più:

- aggiungere logica
- costruire nuovi motori

La priorità è:

👉 rendere il sistema **veloce da leggere e usare nella vita reale**

---

## BLOCCO C — stato reale aggiornato

Stato: **FUNZIONALMENTE COMPLETO (LOGICA)**  
Stato UI: **IN RIFINITURA**

Il blocco Eventi Reali non è più da costruire, ma da:

- rendere più leggibile
- integrare meglio nella UI
- velocizzare l’uso

---

## BLOCCO D — CALENDARIO REALE COMPLETO

Stato: **ATTIVO (FASE REALE)**

Questo blocco è ora la fase dominante del progetto.

Non è più solo "previsto", ma già in uso reale.

---

## PRIORITÀ ATTUALE — UX/UI

Focus attuale:

- riduzione scroll
- maggiore compattezza
- lettura immediata della giornata
- meno elementi inutili visivamente
- più chiarezza causa → effetto

---

## INTERVENTI UI GIÀ FATTI (VALIDATI)

✔ separazione in 3 blocchi:
- Realtà del giorno
- Alice / Scuola
- Buchi / Decisioni

✔ Periodi salvati Alice collapsable

✔ Banner Stato Alice in cima alla card

✔ Permesso come azione rapida dentro Turni

✔ Fonte turno visibile (Quarta squadra, override, ecc.)

✔ Debug UI rimosso

✔ Metodo file grandi a blocchi consolidato

---

## PROBLEMI REALI EMERSI (UX)

Situazione reale attuale:

- schermata ancora troppo lunga
- card Alice / Scuola ancora troppo estesa
- alcune informazioni ridondanti
- necessità di lettura più immediata

---

## PROSSIMO PASSO OPERATIVO

👉 NON toccare la logica

👉 lavorare SOLO sulla UI

### Obiettivo preciso:

**accorciare e semplificare la card "Alice / Scuola"**

Motivo:

- è il blocco più lungo
- impatta direttamente sull’usabilità reale
- rallenta la lettura della giornata

---

## DECISIONE IMPORTANTE

👉 NON lavorare ora su:

- causa evento Alice nei Buchi del giorno

Motivo:

- è già presente nel titolo del buco
- non è una priorità reale
- non migliora l’uso quanto la semplificazione UI

---

## DIREZIONE CORRETTA

Fase attuale:

👉 **OTTIMIZZAZIONE USO REALE**

Non:

❌ sviluppo logico  
❌ nuove feature  
❌ espansione sistema  

Ma:

✔ pulizia  
✔ velocità  
✔ leggibilità  
✔ utilizzo quotidiano  

---

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

# STATO ATTUALE

Sistema stabile.

✔ Logica copertura reale corretta  
✔ Bug falsi buchi risolto  
✔ Rilevazione buchi reali funzionante  
✔ Conflitti turno ↔ evento funzionanti  
✔ Permesso operativo e stabile  
✔ Eventi Alice stabilizzati  
✔ Sandra funzionante su tutte le fasce  

⏸️ Da completare:

- semplificazione UI card Alice / Scuola
- riduzione lunghezza schermata
- miglioramento leggibilità immediata