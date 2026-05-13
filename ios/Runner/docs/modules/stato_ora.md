# FRODODESK — MODULO STATO ORA

## 🎯 OBIETTIVO

Rappresentare lo stato reale della famiglia in un preciso istante temporale.

⚠️ NON il giorno intero  
⚠️ NON previsione  
👉 ma il momento reale simulato

---

## 🧠 PRINCIPIO

STATO ORA =

giorno selezionato  
+  
ora attuale reale

---

## 👨 Matteo

Priorità:

1. malattia a letto → occupato
2. ferie → libero
3. evento attivo → occupato • evento
4. turno attivo → occupato • turno
5. default → libero

---

## 👩 Chiara

Identico a Matteo.

---

## 👧 Alice

Priorità:

1. evento reale attivo → fuori
2. centro estivo (fascia oraria) → fuori
3. scuola normale (fascia oraria) → fuori
4. vacanza / chiusura / malattia → a casa
5. default → a casa

---

## ⚙️ REGOLE TECNICHE

- uso di `DateTime.now()` → SOLO per orario
- uso di `_selectedDay` → per giorno simulato
- costruzione:

```dart
DateTime(
  _selectedDay.year,
  _selectedDay.month,
  _selectedDay.day,
  now.hour,
  now.minute
)

---

# 🔄 AGGIORNAMENTO 12 Maggio 2026

## 🔥 PRESENCE ENGINE ATTIVO

Lo Stato Ora NON deve più ricostruire manualmente la presenza Alice.

È ora collegato al sistema:

`alice_presence_engine.dart`

---

# 🧠 NUOVO PRINCIPIO

La domanda reale del sistema è:

👉 “Dove si trova Alice in questo preciso istante?”

NON:

❌ “Che tipo di giorno è?”  
❌ “Che evento ha oggi?”  

---

# 🔥 SORGENTE UNICA DI VERITÀ

La presenza Alice viene determinata centralmente dal:

`AlicePresenceEngine`

Lo Stato Ora deve leggere:

✔ presenza reale  
✔ accompagnamento  
✔ supporto  
✔ scuola  
✔ centro estivo  
✔ eventi reali  
✔ eventi temporizzati  

senza ricostruire logiche duplicate.

---

# 🔥 MODELLO PRESENZA ATTIVO

Introdotto ufficialmente:

`AlicePresenceState`

Stati attivi:

✔ home  
✔ school  
✔ timedEvent  
✔ realEvent  
✔ summerCamp  
✔ accompanied  
✔ support  

Stati futuri:

⬜ outsideWithFamily  
⬜ autonomousFuture  

---

# 👧 ALICE — NUOVA PRIORITÀ REALE

La priorità non è più basata solo sul “tipo giornata”.

Ora è basata sulla presenza reale temporale.

Ordine corretto:

1. evento reale multi-persona → realEvent
2. evento temporizzato → timedEvent
3. accompagnamento → accompanied
4. supporto reale → support
5. centro estivo → summerCamp
6. scuola → school
7. fallback → home

---

# 🔥 EVENTI REALI FAMILIARI

Caso:

Evento reale con:

- Matteo
- Chiara
- Alice

Comportamento corretto:

✔ Alice dentro evento reale  
✔ Alice NON a casa  
✔ nessun falso buco  
✔ Stato Ora coerente con Coverage e Home  

---

# 🔥 SUPPORTO REALE

Il supporto non è più semplice informazione UI.

Ora influenza realmente la presenza Alice.

Una persona supporto è valida solo se:

✔ attiva  
✔ abilitata nel giorno  
✔ copre completamente la fascia reale  

---

# 🔥 CENTRO ESTIVO — LETTURA REALE

Il centro estivo viene ora interpretato temporalmente.

Il sistema distingue:

1. uscita verso centro estivo  
2. permanenza reale  
3. rientro logistico  
4. Alice a casa dopo il rientro  

---

# FIX IMPORTANTE — CASA DOPO CENTRO ESTIVO

Caso reale corretto:

Prima:

❌ Alice risultava fuori troppo a lungo  

Ora:

✔ ritorno casa corretto  
✔ Alice torna nello stato `home`
✔ da quel momento torna la regola copertura reale  

---

# 🔥 PRINCIPIO ARCHITETTURALE CONSOLIDATO

Lo Stato Ora NON deve:

❌ interpretare manualmente eventi Alice  
❌ decidere da solo se Alice è a casa  
❌ duplicare logiche PresenceEngine  

Deve:

✔ leggere la presenza reale centrale  

---

# 🎯 OBIETTIVO STRUTTURALE

Una sola verità condivisa tra:

- CoverageEngine
- Home
- Stato Ora
- Calendario
- IPS futuro
- Statistiche future

---

# 📌 STATO ATTUALE

COMPLETATI:

☑ PresenceEngine creato  
☑ modello presenza creato  
☑ supporto reale centralizzato  
☑ eventi temporizzati centralizzati  
☑ eventi reali centralizzati  
☑ CoverageEngine collegato  
☑ Stato Ora riallineato concettualmente  

RESTA:

⬜ eliminazione residui legacy  
⬜ Home completamente guidata dal PresenceEngine  
⬜ test presenza reale complessi  
⬜ riallineamento IPS futuro  