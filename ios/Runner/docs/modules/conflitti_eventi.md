# FRODODESK — MODULO CONFLITTI EVENTI

---

## 🎯 OBIETTIVO

Gestire i conflitti tra:

- turni di lavoro
- eventi reali
- stato reale delle persone (malattia, ferie, ecc.)

---

## 🧠 PRINCIPIO

Il sistema:

- rileva automaticamente i conflitti
- NON prende decisioni al posto dell’utente
- permette deroga consapevole

---

## ⚠️ TIPI DI CONFLITTO

### 1. Turno vs Evento
Evento dentro fascia di lavoro

### 2. Stato bloccante vs Evento
Esempio:
- malattia a letto
- evento fuori casa

---

## 🚨 STATO BLOCCANTE

Malattia a letto:

- impedisce uscita
- impedisce copertura
- genera conflitto reale con eventi esterni

---

## 🎨 STATI UI

### 🔴 Rosso
Conflitto reale non risolto

### 🟡 Giallo
Decisione forzata (deroga consapevole)

---

## 🟡 USCITA IMPRESCINDIBILE

Azione disponibile quando:

- esiste conflitto reale
- evento non rimandabile

Effetto:

- il sistema NON blocca
- registra la scelta
- cambia stato UI

---

## 🧠 FILOSOFIA

Il sistema:

- protegge l’utente dagli errori
- ma lascia sempre la decisione finale

👉 “Consapevolezza prima di automazione”

---

## 🚀 PROSSIMI SVILUPPI

- persistenza decisioni forzate
- integrazione con IPS
- storico decisioni
- conflitti evento ↔ stato senza turno