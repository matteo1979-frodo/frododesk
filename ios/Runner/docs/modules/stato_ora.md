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

# 🔄 AGGIORNAMENTO 11 Maggio 2026

## 🔥 EVOLUZIONE — PRESENZA REALE ALICE

Lo stato di Alice NON deve più essere derivato solo da:

- scuola
- centro estivo
- evento attivo

👉 ma dalla presenza reale simulata nel tempo.

---

## NUOVO PRINCIPIO

La domanda reale del sistema diventa:

👉 “Dove si trova Alice ORA?”

NON:

❌ “Che evento ha?”

---

## NUOVI STATI PREVISTI

Alice può risultare:

✔ a casa  
✔ a scuola  
✔ al centro estivo  
✔ dentro evento Alice  
✔ accompagnata da adulto  
✔ dentro evento reale multi-persona  
✔ coperta da supporto  
⬜ autonoma futura  

---

## 🔥 NUOVA REGOLA — EVENTO REALE CON ALICE

Se Alice partecipa a un evento reale:

👉 durante quell’intervallo NON è considerata a casa.

---

## CASO IMPORTANTE

Evento reale:

- Matteo
- Chiara
- Alice

Prima:

❌ Alice risultava a casa  
❌ possibile falso buco copertura  

Ora:

✔ Alice è considerata dentro l’evento reale  
✔ nessun falso buco  
✔ Home e Calendario coerenti  

---

## 🔥 DIREZIONE STRUTTURALE

Lo Stato Ora dovrà evolvere verso un motore unico:

`alice_presence_engine.dart`

Responsabilità futura:

✔ determinare presenza reale Alice  
✔ fornire stato coerente a:
- CoverageEngine
- Home
- Stato Ora
- IPS futuro

---

## PRINCIPIO ARCHITETTURALE

La presenza reale di Alice NON deve essere ricostruita in più punti del sistema.

👉 Una sola verità centrale.