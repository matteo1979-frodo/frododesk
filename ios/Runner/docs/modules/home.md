# 🏠 MODULO HOME — FRODODESK

## 🎯 STATO ATTUALE

HOME DASHBOARD V1.1 COMPLETA — OGGI VS PROSSIMO PROBLEMA SEPARATI

---

## 🧠 IDENTITÀ

La Home NON è più una lista.

È:

- cruscotto reale della giornata
- punto di ingresso al sistema
- sintesi visiva dello stato familiare
- primo livello decisionale del sistema

---

## 🔧 STRUTTURA

### 1. Stato sistema (OGGI + Copertura reale)
- stato reale di oggi
- segnale visivo immediato
- frase decisionale della giornata
- eventuale prossimo problema futuro separato
- accesso rapido al calendario / copertura

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

⚠️ Da evolvere nella prossima fase:
- trasformare “Prossimi 7 giorni” in “Prossimi 30 giorni”

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
- distinguere sempre oggi da futuro

---

## 🚀 STATO

✔ Funzionante  
✔ Collegato ai dati reali  
✔ Usabile nella vita reale  
✔ UI stabilizzata e coerente  
✔ separazione oggi / futuro validata  

---

## ⚡ OBIETTIVO IN 3 SECONDI

Quando apro la Home devo capire subito:

1) La giornata è sotto controllo o no  
2) Se c’è un problema oggi, qual è  
3) Se non c’è problema oggi, qual è il prossimo problema futuro  
4) Dove devo entrare per gestirlo  

Se non risponde a queste domande → la Home non funziona

---

## 🧠 LOGICA DECISIONALE (UFFICIALE)

La Home NON descrive.

👉 La Home decide cosa guardare.

---

## 🔥 FRASE PRINCIPALE (CORE DELLA HOME)

La Home deve sempre mostrare UNA frase principale riferita a OGGI.

### ✔ Caso OK oggi
"Nessuna criticità oggi"

### ⚠ Caso problema oggi
"Oggi: Alice non coperta"

---

## 🔥 NUOVA REGOLA STRUTTURALE — OGGI VS FUTURO

La Home deve separare sempre:

### OGGI
- definisce lo stato principale della Home
- determina colore/icona principale
- se è tutto ok → verde
- se c’è problema → rosso

### FUTURO
- non deve trasformare la Home in rosso
- non deve creare falso allarme
- deve essere mostrato in una card separata
- deve essere cliccabile

Esempio:

"Prossimo problema copertura: Alice scoperta sabato 30 maggio 13:00–14:30"

---

## 🎨 SEGNALE VISIVO (UFFICIALE)

La Home deve usare un segnale visivo IMMEDIATO:

### ✔ TUTTO OK OGGI
- colore: verde
- icona: 😌 / 👍
- significato: puoi stare tranquillo oggi
- frase: "Nessuna criticità oggi"

### ⚠ PROBLEMA OGGI
- colore: rosso
- icona: ✋
- significato: fermati → qui c’è qualcosa da gestire

👉 questo elemento deve essere:
- più visivo del testo
- riconoscibile in meno di 1 secondo

---

## ⚙️ FONTE DATI (DECISIONE ARCHITETTURALE)

La frase principale NON usa IPS.

👉 Usa direttamente:
CoverageEngine

IPS resta non ancora pienamente allineato e non deve guidare da solo la verità della Home.

---

## 📌 LOGICA BASE

- leggere i buchi reali della giornata
- capire se oggi esiste un problema attivo o futuro nella giornata
- se oggi è tutto ok, cercare il primo problema futuro
- mostrare oggi come stato principale
- mostrare il futuro come avviso separato

---

## ⏱️ LOGICA TEMPO REALE (CRITICA)

La Home deve distinguere il TEMPO:

### PASSATO
- il problema è finito
- NON deve influenzare la decisione

### PRESENTE
- il problema è in corso
- deve essere evidenziato come ATTIVO

### FUTURO OGGI
- il problema deve ancora accadere oggi
- può rendere la Home rossa se riguarda la giornata corrente

### FUTURO OLTRE OGGI
- NON rende la Home rossa
- viene mostrato come prossimo problema separato

---

## 📌 COMPORTAMENTO ATTESO

### ✔ Se oggi NON ci sono problemi
"Nessuna criticità oggi"

### ✔ Se oggi è tutto ok ma esiste un problema futuro
Home resta verde  
Sotto compare card:

"Prossimo problema copertura: Alice scoperta [giorno] [orario]"

### ✔ Se problema in corso oggi
"Oggi: Alice non coperta"

### ✔ Se problema futuro oggi
"Oggi: Alice non coperta" / problema copertura del giorno

---

## 🚫 COSA NON FARE

- non usare testi generici
- non usare descrizioni lunghe
- non usare linguaggio tecnico
- non mostrare problemi già finiti
- non dire “nessun problema nei prossimi 30 giorni” se esiste un problema futuro
- non trasformare un problema futuro in falso allarme oggi

---

## 🚫 REGOLA IMPORTANTE

La Home NON deve proporre soluzioni generiche.

❌ NO:
- suggerimenti tipo “attiva Sandra”
- suggerimenti vaghi
- decisioni automatiche

✔ SÌ:
- mostrare il problema
- portare nel punto giusto per risolverlo

👉 le soluzioni stanno nei moduli (Calendario / Copertura)

---

## 🟠 CARD PROSSIMO PROBLEMA

Quando oggi è tutto ok ma esiste un problema futuro:

- la card principale resta verde
- compare una card piccola sotto
- mostra modulo, giorno, orario
- pulsante “VAI”
- porta direttamente al giorno corretto del calendario

Questa card è un avviso preventivo, non un allarme.

---

## 📈 PROSSIMA EVOLUZIONE

FASE 1 — HOME VIVA

- migliorare leggibilità giornata
- migliorare chiarezza informazioni
- rafforzare collegamenti
- usare solo dati reali esistenti

FASE 2 — EVENTI GLOBALI

- trasformare “Nei 7 giorni” in “Prossimi 30 giorni”
- creare accesso a eventi futuri lunghi
- creare accesso a eventi passati
- preparare base per archivio / storico

---

## 🎯 PROSSIMO STEP (DECISO)

👉 Trasformare la card “Nei 7 giorni” in “Prossimi 30 giorni”.

Solo questo.

Dopo:

👉 progettare “Archivio eventi” con:
- eventi passati
- eventi futuri
- raggruppamento per anni
- base futura per categorie

---

## 🧠 NOTA

Questo è il momento in cui FrodoDesk:

👉 passa da sistema tecnico → sistema decisionale reale  
👉 passa da “mostra dati” → “ti dice cosa guardare prima”  
👉 distingue il presente dal futuro senza creare ansia inutile  

---

## 🔄 AGGIORNAMENTO 5 Maggio 2026

### EVENTI GLOBALI + MEMORIA EVENTO + STRUTTURA MODULI

---

## 🔥 EVENTI GLOBALI — INTEGRAZIONE

✔ aggiunta sezione "Eventi globali" nella Home  
✔ accesso da Panoramica oggi  
✔ apertura popup dedicato  

✔ struttura:

- Eventi passati (base creata)  
- Eventi anno corrente (funzionante)  
- Eventi futuri (base creata)  

---

## 🧠 NAVIGAZIONE EVENTI

✔ anno → mesi → eventi → dettaglio  
✔ mesi in griglia visiva (non lista)  
✔ conteggio eventi per mese  
✔ mesi senza eventi disattivati  

---

## 🧠 SCHEDA EVENTO (NUOVO)

✔ apertura evento da Home  
✔ visualizzazione:

- data leggibile  
- orario  
- partecipanti  

✔ campo memoria evento  

---

## 🧠 MEMORIA EVENTO

✔ scrittura note evento  
✔ modifica note  
✔ salvataggio persistente  

✔ verifica reale completata (resta dopo riavvio)

---

## 🧠 EVENTI MULTI-PERSONA

✔ ogni evento può avere più partecipanti  
✔ visualizzazione nomi in Home  
✔ coerenza con motore copertura  

---

## 🧱 DECISIONE STRUTTURALE — HOME

👉 confermata regola:

Home NON deve contenere logiche complesse  

✔ mostra dati  
✔ guida decisione  
✔ collega ai moduli  

❌ NON deve:
- calcolare logiche pesanti  
- contenere grafici  
- duplicare motore  

---

## 🔥 NUOVO MODULO — STATISTICHE

✔ aggiunta card “Statistiche” nei moduli  

✔ decisione ufficiale:

- modulo separato  
- NON sviluppato dentro Home  

---

## SIGNIFICATO

👉 la Home resta pulita  
👉 il sistema cresce a blocchi  

---

## DIREZIONE

Le statistiche saranno:

- basate su dati reali  
- visualizzate con grafici  
- utili per decisioni  

---

## STATO

✔ Eventi Globali funzionanti  
✔ Memoria evento attiva  
✔ multi-persona attiva  
✔ Home stabile  
✔ struttura pronta per evoluzione moduli

---

## 🔄 AGGIORNAMENTO 7 Maggio 2026

### PERSON DETAIL PANEL — MINI CALENDARI PERSONALI VIVI

✔ introdotta evoluzione strutturale delle schede persona nella Home  
✔ ogni persona ora possiede una vista personale mensile reale  
✔ calendario mini interattivo collegato al Calendario principale  

---

## 🧠 PERSON DETAIL PANEL

La scheda persona NON è più una semplice popup informativa.

È diventata:

- mini radar personale
- vista rapida del mese
- accesso diretto ai giorni reali
- sintesi visuale stato persona

---

## 🔥 FUNZIONI IMPLEMENTATE

✔ apertura calendario sul giorno selezionato  
✔ tap sui giorni del mini calendario  
✔ collegamento diretto al Calendario reale  
✔ apertura automatica sul giorno corretto  

✔ navigazione mesi avanti/indietro  
✔ stato "oggi" evidenziato  
✔ legenda dinamica separata per Alice/adulti  

---

## 👨 MATTEO / 👩 CHIARA

Mini calendario collegato a:

✔ turni reali  
✔ ferie  
✔ malattia  

### Colori

- giallo → mattina
- arancione → pomeriggio
- blu → notte
- verde → ferie
- rosso → malattia
- grigio → riposo

### Icone

✔ mattina  
✔ pomeriggio  
✔ notte  
✔ ferie  
✔ malattia  
✔ riposo

---

## 👧 ALICE — EVOLUZIONE STRUTTURALE

La scheda Alice ora legge:

✔ SchoolStore  
✔ AliceEventStore  
✔ AliceSpecialEventStore  
✔ DiseasePeriodStore  

---

## 🔥 STATI ALICE IMPLEMENTATI

✔ scuola normale  
✔ vacanza  
✔ scuola chiusa  
✔ centro estivo  
✔ evento / attività  
✔ uscita anticipata  
✔ malattia  

---

## 🎨 COLORI ALICE

- blu → scuola
- verde → centro estivo
- teal → evento / attività
- arancione → uscita anticipata
- viola → vacanza
- grigio → scuola chiusa
- rosso → malattia

---

## 🧠 ICONE ALICE

✔ scuola  
✔ spiaggia/vacanza  
✔ centro estivo  
✔ malattia  
✔ evento sportivo/attività  
✔ uscita anticipata  
✔ scuola chiusa  

---

## 🔥 DECISIONE STRUTTURALE IMPORTANTE

Weekend e giorni senza scuola normale NON sono automaticamente "vacanza".

Distinzione ufficiale:

✔ vacanza reale  
✔ scuola chiusa  
✔ weekend  
✔ eventi Alice  
✔ centro estivo  

restano concetti separati nel sistema.

---

## 🧱 SIGNIFICATO ARCHITETTURALE

La Home evolve da:

"dashboard con dati"

a:

"sistema vivo navigabile persona per persona"

---

## 🚀 STATO

✔ stabile  
✔ compilazione verificata  
✔ test reale completato  
✔ navigazione funzionante  
✔ persistenza funzionante  
✔ UI coerente validata

---

# 🔄 AGGIORNAMENTO — MAGGIO 2026

## 🔥 HOME ↔ COVERAGE ENGINE ALLINEATI

Corretta incoerenza critica tra:

- Calendario
- Home
- CoverageEngine

---

## 🐛 BUG RISOLTO

Prima:

la Home poteva mostrare:

"Prossimo problema copertura"

anche quando:

- il Calendario risultava coperto
- la rete supporto copriva realmente la fascia

👉 Home e Calendario NON leggevano la stessa verità.

---

## ✅ FIX STRUTTURALE

La Home ora usa:

- stessi range reali
- stessa logica copertura
- stessi SchoolCoverChoice effettivi
- stessa lettura rete supporto

del Calendario.

---

## 🔧 NUOVA REGOLA

La Home NON deve:

- reinterpretare la copertura
- semplificare la logica
- avere fallback diversi

👉 deve leggere la stessa verità del motore.

---

## 🔥 CONSEGUENZA ARCHITETTURALE

La Home evolve definitivamente da:

"dashboard con riassunti"

a:

"vista decisionale del motore reale"

---

## ✅ EVENTI REALI MULTI-PERSONA

Nuova regola introdotta:

se un Evento Reale coinvolge:

- Matteo
- Chiara
- Alice

ALLORA:

✔ Alice è considerata dentro evento reale  
✔ NON viene generato buco casa  
✔ NON compare falso problema Home  

---

## 🧠 PRINCIPIO REALTÀ

Evento familiare condiviso ≠ Alice sola a casa

---

## 🔥 STATO RAGGIUNTO

✔ Home sincronizzata col motore reale  
✔ Supporto reale coerente  
✔ Eventi multi-persona coerenti  
✔ Eliminati falsi problemi Home  
✔ Navigazione “Vai” coerente col giorno reale  

---

## 🚀 NUOVA FASE UFFICIALE

# MOTORE PRESENZA REALE ALICE

Direzione ufficiale:

creare una sorgente unica che definisce:

👉 dove si trova Alice realmente

e far leggere da lì:

- CoverageEngine
- Home
- IPS futuro
- conflitti
- supporto
- logica accompagnamento

---

## 📌 ROADMAP AGGIORNATA

☑ Home ↔ Coverage allineati  
☑ Supporto reale sincronizzato  
☑ Alice dentro evento reale = no falso buco  
☑ Eventi multi-persona coerenti  

⬜ alice_presence_engine.dart
⬜ stato presenza centralizzato
⬜ rimozione doppioni logici
⬜ lettura unica presenza Alice
⬜ IPS presenza-aware
⬜ conflitti presenza reale

---

# 🌍 EVOLUZIONE STRUTTURALE — HOME MULTI FAMIGLIA

## NUOVA DIREZIONE UFFICIALE

La Home attuale è costruita sulla famiglia:

- Matteo
- Chiara
- Alice

Questa struttura è considerata temporanea.

L'obiettivo finale del sistema è permettere a qualsiasi famiglia di costruire la propria realtà.

---

## PRINCIPIO

Quando una persona installa FrodoDesk deve poter:

✔ creare una nuova famiglia

✔ scegliere il nome della famiglia

✔ inserire i membri

✔ costruire la propria struttura reale

senza alcun dato predefinito.

---

## IDENTITÀ DINAMICA

La Home non dovrà più leggere:

- Matteo
- Chiara
- Alice

ma:

👉 i membri effettivamente presenti nella famiglia.

Esempi:

- Famiglia Rossi
- Famiglia Bianchi
- Famiglia Verdi

oppure:

- coppia senza figli
- famiglia con 1 figlio
- famiglia con 4 figli
- famiglia con persone anziane
- famiglia con caregiver

---

## CLOUD

La Home dovrà leggere una sorgente dati condivisa.

Lo stesso stato dovrà essere visibile da:

- telefono
- PC
- tablet

senza procedure manuali di esportazione/importazione.

---

## NOTIFICHE FUTURE

La Home dovrà diventare il punto di arrivo delle notifiche di sistema.

Esempi:

✔ evento modificato

✔ copertura modificata

✔ nuovo impegno familiare

✔ nuova attività figlio

✔ modifica turni

---

## PRINCIPIO GUIDA

La Home deve diventare:

👉 la porta d'ingresso della vita reale della famiglia

non della famiglia Matteo-Chiara-Alice.
