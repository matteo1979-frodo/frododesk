# 🏠 MODULO HOME — FRODODESK

## 🎯 STATO ATTUALE

HOME DASHBOARD V1 COMPLETA

---

## 🧠 IDENTITÀ

La Home NON è più una lista.

È:

- cruscotto reale della giornata
- punto di ingresso al sistema
- sintesi visiva dello stato familiare

---

## 🔧 STRUTTURA

### 1. Stato sistema (IPS + Copertura reale)
- livello sistema (verde/giallo/rosso)
- frase decisionale della giornata (PRIORITARIA)
- spiegazione sintetica
- accesso dettaglio
- azioni rapide (calendario, copertura)

👉 La frase decisionale è l’elemento più importante della Home

---

### 2. Panoramica oggi
- numero promemoria
- numero eventi
- persone coinvolte
- giorni con eventi futuri

---

### 3. Oggi
- promemoria raggruppati per persona
- visualizzazione compatta
- accesso diretto al calendario
- eventi del giorno sintetizzati

---

### 4. Prossimi 7 giorni
- solo giorni con eventi
- visualizzazione compatta
- evidenza del primo evento

---

### 5. Moduli
- accesso visivo ai moduli sistema
- stato (attivo / disponibile / futuro)

---

## 🧱 PRINCIPI

- NON duplicare il calendario
- NON mostrare tutto
- mostrare solo ciò che serve
- permettere accesso rapido alle decisioni

---

## 🚀 STATO

✔ Funzionante  
✔ Collegato ai dati reali  
✔ Usabile nella vita reale  
✔ UI stabilizzata e coerente  

---

## ⚡ OBIETTIVO IN 3 SECONDI

Quando apro la Home devo capire subito:

1) La giornata è sotto controllo o no  
2) Se c’è un problema, qual è  
3) Dove devo entrare per risolverlo  

Se non risponde a queste 3 domande → la Home non funziona

---

## 🧠 LOGICA DECISIONALE (NUOVA — UFFICIALE)

La Home NON descrive.

👉 La Home decide cosa guardare.

---

## 🔥 FRASE PRINCIPALE (CORE DELLA HOME)

La Home deve sempre mostrare UNA frase:

### ✔ Caso OK
"Nessun problema oggi"

### ⚠ Caso problema
"Alle 16:30 Alice non coperta"

---

## ⚙️ FONTE DATI (DECISIONE ARCHITETTURALE)

La frase principale NON usa IPS.

👉 Usa direttamente:
CoverageEngine

---

## 📌 LOGICA BASE

- leggere i buchi reali della giornata
- prendere il primo buco rilevante
- trasformarlo in frase semplice
- mostrarlo nella SystemStatusCard

---

## ⏱️ LOGICA TEMPO REALE (NUOVA — CRITICA)

La Home deve distinguere il TEMPO:

### PASSATO
- il problema è finito
- NON deve più influenzare la decisione

### PRESENTE
- il problema è in corso
- deve essere segnalato come attivo

### FUTURO
- il problema deve ancora accadere
- deve guidare la decisione

---

## 📌 COMPORTAMENTO ATTESO

### ✔ Se NON ci sono problemi futuri
"Nessun problema da ora in poi"

### ✔ Se c’è un problema futuro
"Alle HH:MM serve copertura per Alice"

### ✔ (Step successivo)
Se problemi già passati:
- devono essere considerati risolti
- NON devono comparire come errore attivo

---

## 🚫 COSA NON FARE

- non usare testi generici
- non usare descrizioni lunghe
- non usare linguaggio tecnico
- non mostrare problemi già finiti

---

## 📈 PROSSIMA EVOLUZIONE

FASE 1 — HOME VIVA

- migliorare leggibilità giornata
- migliorare chiarezza informazioni
- rafforzare collegamenti
- usare solo dati reali esistenti

---

## 🎯 PROSSIMO STEP (DECISO)

👉 Rendere la SystemStatusCard intelligente:

- distinguere PASSATO / PRESENTE / FUTURO
- mostrare solo problemi rilevanti ORA
- trasformare il sistema in guida decisionale reale

---

## 🧠 NOTA

Questo è il momento in cui FrodoDesk:

👉 passa da sistema tecnico → sistema decisionale reale  
👉 passa da “mostra dati” → “ti dice cosa fare”