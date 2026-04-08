# FRODODESK — MODULO EVENTI ALICE

Ultimo aggiornamento: 8 Aprile 2026

---

## IDENTITÀ DEL MODULO

Questo modulo gestisce gli **Eventi Alice reali/speciali**, cioè gli eventi della vita reale di Alice che possono influenzare:

- la presenza reale
- la copertura
- le decisioni familiari
- il linguaggio del sistema

---

## 🔥 STATO ATTUALE — EVOLUZIONE MODULO

Gli Eventi Alice NON sono più solo informativi.

👉 Sono entità:
- persistenti
- modificabili
- con impatto reale sul sistema

👉 🔥 NUOVO (APRILE 2026):
- collegamento reale con **linguaggio stato Alice**
- collegamento reale con **copertura**
- base per sistema visivo (emoji + colori)
- prime etichette umane collegate al nome vero evento

---

## 🧠 ARCHITETTURA — 3 LIVELLI (FONDAMENTALE)

Il modulo ora segue questa separazione:

### 1️⃣ LOGICA
→ dove si trova Alice realmente

### 2️⃣ LINGUAGGIO
→ come il sistema descrive lo stato

### 3️⃣ VISUALE
→ emoji + colore (status_visual)

---

## 🔧 IMPLEMENTAZIONE ATTUALE (LINGUAGGIO REALE)

Il placeholder temporaneo è stato superato.

Ora il linguaggio legge realmente:

- stato periodo Alice
- eventi Alice temporizzati
- eventi reali Alice
- categorie evento
- fallback testuale quando necessario

Schema logico attuale:

```dart
final isAliceSick = alicePeriodNow?.type == AliceEventType.sickness;

final String aliceNowLabel = aliceIsOutNow
    ? (activeAliceSpecialEventNow != null
          ? _aliceOutsideLabelFromText(
              activeAliceSpecialEventNow!.label,
              category: activeAliceSpecialEventNow!.category,
            )
          : activeAliceRealEventNow != null
          ? _aliceOutsideLabelFromText(activeAliceRealEventNow!.title)
          : (alicePeriodNow?.type == AliceEventType.summerCamp
                ? "fuori • centro estivo"
                : "fuori • scuola"))
    : (isAliceSick ? "a casa • malata" : "a casa");
    ✅ SUPERATO
Prima
final isSchoolNow = aliceIsOutNow;
Problema
isSchoolNow NON era reale
Alice risultava “fuori • scuola” anche quando non doveva
il weekend veniva letto male
Ora
weekend corretto
evento reale letto
categoria evento letta
stato Alice coerente
🎯 RISULTATO ATTUALE RAGGIUNTO

Alice ora può generare automaticamente:

"fuori • scuola"
"fuori • centro estivo"
"fuori • sport"
"fuori • attività"
"fuori • visita"
"fuori • gita"
"a casa • malata"
"a casa"

👉 senza modificare la UI
👉 senza toccare status_visual

🔒 REGOLA FONDAMENTALE
NON modificare la UI
NON toccare status_visual
il linguaggio deve nascere dalla logica reale
🧠 CATEGORIE EVENTI ALICE

Scelta strutturale fissata:

school
health
sport
activity
other
Traduzione attuale
school → fuori • scuola
health → fuori • visita
sport → fuori • sport
activity → fuori • attività
other → fallback testuale / fallback umano

👉 decisione ufficiale: sport e activity restano distinti

🧠 LOGICA SCUOLA DINAMICA

Gli orari scuola NON sono più fissi.

📍 ENTRATA
orario reale (es: 08:25)
buffer: -20 minuti

👉 fascia reale:
08:05 – 08:25

📍 USCITA
orario reale (es: 16:25)
buffer: +20 minuti

👉 fascia reale:
16:25 – 16:45

📍 USCITA ANTICIPATA

Se attiva:

👉 sostituisce completamente l’uscita scuola

Usata da:

UI
CoverageEngine
Sandra
buchi reali
🍽️ PRANZO — LOGICA DINAMICA

Prima:
❌ fisso 13:00–14:30

Ora:

👉 dinamico

start = uscita anticipata (se presente)
fallback = 13:00
👶 SANDRA — ALLINEAMENTO

Sandra NON usa più orari fissi.

👉 legge:

uscita anticipata
fasce reali
CoverageEngine
⚠️ PRINCIPIO SISTEMA

TUTTO usa la stessa fonte:

UI
CoverageEngine
decisioni
Sandra

👉 nessun valore duplicato

🔥 LOGICA EVENTI ALICE → COPERTURA

Un evento Alice genera impatto reale sul motore.

1️⃣ DURANTE EVENTO
Alice NON è a casa
2️⃣ PRIMA EVENTO
verifica accompagnamento
3️⃣ DOPO EVENTO
verifica ritiro
4️⃣ DOPO RITIRO
Alice torna nel suo stato reale di giornata
⏱️ BUFFER EVENTI ALICE

Decisione ufficiale fissata:

👉 per gli eventi Alice temporizzati usare:

20 minuti prima
20 minuti dopo

Quindi:

pre-evento = accompagnamento
post-evento = ritiro
🧠 PRINCIPIO REALTÀ

Un evento Alice NON occupa automaticamente il genitore per tutta la sua durata.

Regola corretta:

accompagnamento = vincolo reale
evento = Alice fuori, ma non per forza genitore occupato
ritiro = vincolo reale

👉 questa distinzione è stata riconosciuta come fondamentale durante la chat

🔥 ESEMPIO REALE VALIDATO

Caso testato:

Alice in vacanza
evento danza in mezzo alla giornata
sistema prima produceva lettura troppo grossolana
sistema poi corretto fino a ottenere buchi più coerenti:
ritiro evento
ritorno a casa
🧾 LINGUAGGIO UMANO EVENTI

Miglioramento già introdotto:

prima:

Ritiro Alice evento

ora:

Ritiro Alice danza
Accompagnamento Alice danza

👉 il sistema usa il label reale dell’evento

Questo rende il motore molto più umano e leggibile.

⚠️ DECISIONE IMPORTANTE EMERSA

NON sempre conviene unire i buchi.

Per esempio:

ritiro evento
Alice a casa dopo evento

possono richiedere soluzioni diverse:

Sandra solo per ritiro
supporto solo per casa dopo
genitore solo per uno dei due

👉 quindi priorità operativa > estetica

🧠 PRIORITÀ TESTO — REGOLA FISSATA

Distinzione emersa come fondamentale:

1️⃣ Stato giorno dominante

Esempi:

vacanza
malattia
scuola chiusa

Se Alice è a casa per stato giorno:
👉 è giusto che prevalga lo stato giorno

Esempio corretto:

Alice a casa (Vacanza)
2️⃣ Evento temporale

Esempi:

scuola
danza
sport
visite

L’evento domina solo nel suo intervallo reale.

Fuori da quell’intervallo:
👉 Alice torna a casa

E in certi casi il linguaggio corretto può essere:

Alice a casa dopo scuola
Alice a casa dopo danza
🧠 SCOPERTA STRUTTURALE DELLA CHAT

Regola chiave emersa e validata:

👉 lo stato giorno NON deve schiacciare la realtà temporale

Esempio corretto:

Alice a scuola 08:30–16:30
rientro 16:30–16:50
dopo 16:50:
NON deve restare “a scuola”
deve diventare “Alice a casa dopo scuola”
🧩 MODELLO EVENTO

Campi:

id
label
category
date
start
end
note
enabled
🧠 STATO REALE
✔ COMPLETATO
model ✔
store ✔
CoreStore ✔
editor ✔
multi-evento ✔
persistenza ✔
conflitti ✔
UI eventi ✔
🔥 COMPLETATO RECENTE
orari scuola dinamici ✔
uscita anticipata ✔
pranzo dinamico ✔
Sandra dinamica ✔
linguaggio Alice reale ✔
weekend fix ✔
categorie stabili ✔
impatto reale eventi Alice sulla copertura ✔
etichette umane per accompagnamento / ritiro ✔
🚧 NON ANCORA FATTO
LOGICA

⬜ trasformare scuola da stato giorno a evento temporale reale (PROSSIMO STEP)

LINGUAGGIO

⬜ completare in modo definitivo il comportamento “Alice a casa dopo scuola” / “Alice a casa dopo evento” secondo priorità stato giorno vs evento

UI

⬜ rifinitura

SISTEMA

⬜ conflitti forti turni/eventi
⬜ suggerimenti automatici
⬜ IPS completo

🚀 FUTURO
Alice al seguito
suggerimenti intelligenti
eventi ricorrenti
statistiche
🎯 STATO MODULO

🟡 IN COSTRUZIONE AVANZATA

già raggiunto
sistema reale ✔
linguaggio base ✔
collegamento eventi → stato Alice ✔
collegamento eventi → copertura ✔
linguaggio umano eventi ✔
prossimo fronte vero
scuola come evento temporale reale
rientro da scuola gestito come realtà temporale
linguaggio “Alice a casa dopo scuola”

Aspetto il tuo **“fatto”**. Dopo ti mando il blocco nuova chat perfetto.