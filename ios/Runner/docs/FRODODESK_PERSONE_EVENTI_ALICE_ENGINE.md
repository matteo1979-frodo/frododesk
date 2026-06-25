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
---

# BLOCCO G — MOTORE PRESENZA REALE ALICE

Stato aggiornato reale — Maggio 2026

---

## OBIETTIVO REALE DEL BLOCCO G

Trasformare la presenza Alice da:
- semplice evento calendario
- semplice fascia oraria

a:

- stato reale temporale
- interpretabile dal motore
- compatibile con:
  - accompagnamento
  - support network
  - eventi reali
  - scuola
  - centro estivo
  - copertura reale

---

# PRESENCE ENGINE

Creato:

`alice_presence_engine.dart`

Il PresenceEngine sta diventando il proprietario progressivo della presenza Alice.

CoverageEngine deve progressivamente diventare:

- consumatore puro della presenza
- motore copertura
- NON interprete della logica Alice

---

# STATI PRESENZA ATTUALI

Attualmente gestiti:

☑ home
☑ school
☑ timedEvent
☑ realEvent
☑ summerCamp
☑ accompanied
☑ support

Previsti in futuro:

⬜ outsideWithFamily
⬜ autonomousFuture

---

# CENTRALIZZAZIONI COMPLETATE

Completato:

☑ centralizzazione accompagnamento Alice
☑ centralizzazione companion overlap
☑ centralizzazione companion end
☑ centralizzazione support network
☑ centralizzazione controllo eventi reali Alice
☑ centralizzazione eventi temporizzati Alice

CoverageEngine legge progressivamente PresenceEngine invece di leggere direttamente gli store.

---

# DEBUG REALE COMPLETATO

Completato fix strutturale:

☑ duplicazione buchi serali legacy
☑ conflitto Sandra/eventi reali
☑ support network parziale
☑ segmentazione reale dei gap

Caso reale verificato:

- evento 21:00–22:30
- supporto 21:00–22:00

Risultato corretto:

- residuo reale 22:00–22:30

Il motore ora usa progressivamente:
- range reali
- segmentazione reale
- copertura reale

e non più fasce legacy statiche.

---

# DIREZIONE STRUTTURALE

CoverageEngine deve progressivamente:

❌ smettere di interpretare Alice
❌ smettere di leggere CompanionStore direttamente
❌ smettere di segmentare manualmente la presenza
❌ smettere di mischiare:
   - logica Sandra
   - support network
   - eventi reali

e diventare:

✔ interprete copertura
✔ lettore range reali
✔ consumatore PresenceEngine
✔ motore buchi
✔ NON proprietario presenza Alice

---

# 🌍 AGGIORNAMENTO STRATEGICO — PERSONE VIVE UNIVERSALI

Decisione Giugno 2026:

Il concetto di "Persone vive" non riguarda più solo Alice, Matteo e Chiara.

Diventa una delle basi strutturali future di FrodoDesk.

---

## PRINCIPIO

Ogni persona del sistema dovrà esistere come entità reale, configurabile e indipendente dai nomi attuali.

La famiglia attuale:

- Matteo
- Chiara
- Alice

è il primo caso reale di collaudo.

Non è la struttura definitiva del sistema.

---

## MODELLO FUTURO

FrodoDesk dovrà permettere a ogni famiglia di creare le proprie persone.

Esempi:

- genitore
- figlio
- nonno
- babysitter
- caregiver
- supporto esterno
- allenatore
- insegnante
- consulente

Ogni persona potrà avere:

- profilo
- ruolo
- relazioni
- disponibilità
- permessi
- presenza reale
- eventi collegati

---

## PERSONE E CONTESTI MULTIPLI

Una persona potrà appartenere a più contesti.

Esempio:

Sandra può avere:

- il proprio FrodoDesk familiare
- accesso limitato alla famiglia Matteo

ma solo per i moduli autorizzati.

Esempio autorizzazione:

✔ copertura Alice

❌ finanze

❌ spese

❌ dati privati

---

## ACCESSI E PROPOSTE

Gli utenti esterni autorizzati non devono necessariamente modificare direttamente i dati della famiglia.

Possono proporre modifiche.

Esempi:

- Sandra propone disponibilità fino alle 18:00
- Allenatore propone spostamento allenamento
- Insegnante propone modifica attività
- Supporto familiare propone disponibilità

L'amministratore o il membro autorizzato della famiglia può:

✔ accettare

✔ rifiutare

✔ valutare l'impatto su calendario, copertura e conflitti

---

## COORDINAMENTO TRA FAMIGLIE

FrodoDesk potrà evolvere da semplice sistema familiare a sistema di coordinamento della vita reale.

Esempio:

Allenatore modifica allenamento:

- prima: martedì e giovedì 16:00–18:00
- dopo: mercoledì 17:00–19:00

Le famiglie autorizzate ricevono la proposta.

Ogni famiglia può accettare.

Il sistema verifica automaticamente:

- calendario
- copertura
- turni
- conflitti
- disponibilità adulti

L'organizzatore vede lo stato:

- confermato
- in attesa
- problema logistico

senza vedere i dati privati della famiglia.

---

## FILOSOFIA

FrodoDesk non deve diventare solo un calendario.

Deve diventare progressivamente:

👉 un sistema di coordinamento della vita reale.

La decisione resta sempre umana.

Il sistema:

✔ riceve proposte

✔ valuta impatti

✔ segnala problemi

✔ protegge i dati privati

✔ aiuta le famiglie a coordinarsi

senza sostituirsi alle persone.