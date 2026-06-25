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

---

# 🌍 EVOLUZIONE STRUTTURALE — PROMEMORIA MULTI FAMIGLIA

## PRINCIPIO

Il modulo Promemoria non deve dipendere da persone predefinite.

I nomi:

- Matteo
- Chiara
- Alice

devono essere considerati esempi della famiglia attuale.

---

## DIREZIONE FUTURA

Ogni promemoria dovrà poter essere associato a:

- una persona
- più persone
- l'intera famiglia

indipendentemente dai nomi utilizzati.

---

## ESEMPI FUTURI

- Comprare quaderni → Figlio 1
- Visita dentista → Figlio 2
- Pagare assicurazione → Matteo
- Riunione scuola → Chiara
- Prenotare vacanze → Famiglia

---

## CLOUD

I promemoria dovranno essere sincronizzati automaticamente tra:

- PC
- telefono
- tablet

utilizzando la stessa sorgente dati condivisa.

---

## NOTIFICHE FUTURE

Ogni membro della famiglia potrà scegliere quali promemoria ricevere.

Esempi:

✔ solo propri

✔ propri + famiglia

✔ tutti

---

## NOTA

Questa evoluzione NON è prioritaria nella fase attuale.

Priorità attuale:

✔ stabilizzazione calendario reale
✔ consolidamento moduli esistenti
✔ utilizzo quotidiano del sistema

La trasformazione multi-famiglia verrà affrontata successivamente.