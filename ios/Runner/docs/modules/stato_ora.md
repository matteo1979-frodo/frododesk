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