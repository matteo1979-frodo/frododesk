# FRODODESK — PERSONE VIVE + EVENTI ALICE REALI

Ultimo aggiornamento: 7 Maggio 2026

---

# OBIETTIVO

Avviare la nuova fase strutturale di FrodoDesk:

1. trasformare gli Eventi Alice da semplici eventi calendario a eventi reali del motore
2. preparare il sistema al concetto di Persone vive nel tempo

---

# PRINCIPIO BASE

FrodoDesk non deve solo salvare eventi.

Deve capire cosa significano nella realtà.

Il sistema suggerisce.  
La decisione resta sempre umana.

---

# REGOLA ARCHITETTURALE

Da ora NON si appesantisce ulteriormente:

`lib/screens/calendario_screen_stepa.dart`

Il calendario può restare UI principale, ma le nuove logiche devono essere separate.

---

# STRUTTURA FUTURA EVENTI ALICE

Cartella proposta:

`lib/logic/alice_events/`

File progressivi previsti:

- `alice_event_behavior.dart`
- `alice_event_category.dart`
- `alice_event_rules.dart`
- `alice_event_engine.dart`

Regola:

un file alla volta  
nessun mega-refactor  
prima modello/regole  
poi motore  
poi collegamento UI

---

# TIPI EVENTO ALICE

## 1. Evento passivo

Esempi:

- compiti
- studio
- videogiochi
- amica a casa

Non genera:

- accompagnamento
- ritiro
- spostamento

Può generare:

- occupazione Alice
- conflitto con altri eventi

---

## 2. Evento logistico

Esempi:

- pallavolo
- musica
- dentista
- compleanno

Genera:

- accompagnamento
- ritiro
- possibile occupazione genitore
- possibile conflitto turno/evento
- possibile impatto copertura

---

## 3. Evento accompagnato

Esempio:

- Alice al seguito

Significato:

- Alice segue un genitore
- non crea buco
- il sistema registra chi la porta
- può risolvere una situazione reale

---

## 4. Evento autonomo futuro

Non implementare ora.

Servirà quando Alice crescerà.

Esempi futuri:

- Alice resta sola a casa
- Alice va sola a un’attività
- Alice torna sola

---

# PERSONE VIVE NEL SISTEMA

Nuova idea strutturale:

le persone non devono essere solo nomi fissi.

Devono avere un profilo.

Esempi dati futuri:

- nome
- data di nascita
- età calcolata nel tempo
- ruolo familiare
- autonomia
- condizioni salute
- disponibilità reale

---

# ESEMPIO ALICE

Alice è nata il:

`06/12/2018`

Il giorno:

`06/12/2030`

compie 12 anni.

Da quel momento il motore potrebbe permettere nuove regole, per esempio:

- Alice può restare a casa da sola in alcuni cambi turno
- Matteo può fare una commissione breve
- Alice non richiede sempre copertura adulta continua

Non implementare ora.

Preparare solo la struttura mentale.

---

# ESEMPIO MATTEO / CHIARA

Il profilo persona potrà servire in futuro per:

- salute
- età
- visite
- stanchezza
- disponibilità reale
- limiti fisici
- pressione familiare

---

# ORDINE OPERATIVO CNC

## STEP 1

Creare la base concettuale Eventi Alice reali.

## STEP 2

Creare il primo file separato:

`lib/logic/alice_events/alice_event_behavior.dart`

## STEP 3

Definire cosa genera ogni evento:

- occupa Alice
- richiede accompagnamento
- richiede ritiro
- impatta copertura
- può essere autonomo
- può essere accompagnato

## STEP 4

Collegare il motore senza cambiare subito tutta la UI.

## STEP 5

Solo dopo, aggiornare il calendario.

---

# PRINCIPIO FINALE

Il rischio non è solo avere file grandi.

Il rischio vero è mischiare:

- UI
- comportamento reale
- regole del motore

Da ora gli Eventi Alice devono iniziare ad avere una loro architettura.