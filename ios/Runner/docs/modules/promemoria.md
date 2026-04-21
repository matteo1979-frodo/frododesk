# MODULO — PROMEMORIA

## IDENTITÀ

Il modulo Promemoria gestisce attività giornaliere legate alla realtà familiare.

Non è una semplice todo list.

È una traccia temporale reale delle azioni da svolgere e svolte.

---

## STRUTTURA DATI

Ogni promemoria contiene:

- id
- persona (Matteo, Chiara, Alice, Famiglia)
- testo
- done
- createdDay (giorno creazione)
- completedDay (giorno completamento, opzionale)

---

## REGOLE BASE

### Creazione
- il promemoria nasce in un giorno preciso (`createdDay`)

### Visibilità

Un promemoria è visibile in un giorno se:

- è stato creato prima o in quel giorno
- NON è stato completato prima di quel giorno

---

## LOGICA TEMPORALE

### Caso 1 — Non completato
- viene mostrato nei giorni successivi
- continua finché non viene completato

### Caso 2 — Completato
- nel giorno di completamento → appare come completato
- nei giorni precedenti → appare NON completato
- nei giorni successivi → NON appare

---

## REGOLA STORICO

Lo storico rappresenta la realtà:

- creazione ≠ completamento
- il sistema non altera il passato

---

## UI

- divisione per persona
- popup per visualizzazione lista
- checkbox con stato dinamico per giorno
- modifica / elimina / spunta collegati allo store

---

## FILOSOFIA

Il sistema suggerisce  
La decisione resta umana

---

## ESTENSIONI FUTURE

- riporta manuale a domani
- etichetta "non fatto da ieri"
- priorità promemoria
- collegamento IPS (pressione operativa)