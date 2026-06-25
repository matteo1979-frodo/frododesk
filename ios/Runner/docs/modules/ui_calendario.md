# FRODODESK — MODULO UI CALENDARIO

Ultimo aggiornamento: 30 Marzo 2026

---

# IDENTITÀ DEL MODULO

Questo modulo descrive la struttura reale della schermata calendario di FrodoDesk.

Obiettivo:

- rendere leggibile la giornata
- ridurre il caos visivo
- separare realtà, stato Alice e decisioni
- permettere uso reale rapido

La UI non è decorazione.

👉 È parte del sistema decisionale

---

# PRINCIPIO FONDAMENTALE

La schermata deve:

- mostrare la realtà
- aiutare a capire velocemente
- non sommergere l’utente
- mantenere separati i livelli logici

---

# STRUTTURA GENERALE ATTUALE

La schermata calendario è organizzata in 3 blocchi principali:

1. **REALTÀ DEL GIORNO**
2. **ALICE / SCUOLA**
3. **BUCHI / DECISIONI**

Questa struttura è stata validata come più chiara rispetto alla colonna lunga unica.

---

# BLOCCO 1 — REALTÀ DEL GIORNO

Contiene:

- turni
- eventi adulti
- stato persone
- azioni operative sui turni

Scelta UI consolidata:

👉 Quarta Squadra non è più un blocco separato  
👉 vive dentro la card Turni

---

# BLOCCO 2 — ALICE / SCUOLA

Contiene:

- stato dominante di Alice
- decisioni scuola/copertura
- periodi Alice
- eventi Alice reali
- editor eventi Alice

Questo blocco è diventato centrale nella nuova fase del progetto.

---

# BLOCCO 3 — BUCHI / DECISIONI

Contiene:

- buchi reali del giorno
- spiegazioni
- conflitti
- azioni operative

Questo blocco deve restare chiaro e leggibile.

---

# SEZIONI APRI/CHIUDI

Scelta UI consolidata:

- sezioni comprimibili attive
- header cliccabili
- contenuti nascosti quando chiusi
- riduzione scroll iniziale

Stato verificato in app:

✔ funzionante  
✔ utile  
✔ da mantenere

---

# STATO ALICE

Decisione consolidata:

👉 lo stato dominante di Alice deve essere visibile subito

Per questo esiste un banner nella card Alice / Scuola.

Esempi:

- Vacanza
- Malattia
- Centro estivo
- Scuola chiusa
- Gita / evento speciale

---

# COLORI STATO ALICE

Logica cromatica consolidata:

- Malattia → rosso
- Scuola chiusa → arancione
- Vacanza → teal
- Centro estivo → verde

Principio:

👉 il colore rappresenta l’impatto reale sulla giornata

---

# PERIODI SALVATI ALICE

Decisione UI consolidata:

- blocco collapsable
- chiuso = nessun contenuto mostrato
- aperto = lista completa o messaggio “Nessun periodo salvato”

Obiettivo:

- evitare lista infinita
- ridurre altezza schermata

---

# EVENTI ALICE REALI — UI ATTUALE

Stato attuale:

✔ bottone “Aggiungi evento Alice”  
✔ editor base apri/chiudi  
✔ TextField nome evento  
✔ bottone “Salva evento”  
✔ lista eventi mostrata in card  

Esempio reale validato:

👉 pallavolo (18:00–20:00)

---

# PRINCIPIO UI EVENTI ALICE

La card deve restare pulita.

Quindi:

- lista compatta visibile
- dettagli extra da spostare in futuro in livello dedicato
- note e informazioni lunghe non devono sporcare il blocco principale

---

# PERMESSO — DECISIONE STRUTTURALE UI

Permesso NON è stato persona.

Permesso è:

👉 azione operativa sulla giornata

Per questo è stato spostato nella card Turni.

---

# FONTE TURNO VISIBILE

Decisione consolidata:

la card Turni deve mostrare da dove deriva il turno attuale.

Esempi:

- Quarta squadra
- Nuova rotazione
- Cambio turno solo oggi
- Cambio turno periodo

---

# DIREZIONE UI ATTUALE

La UI è in fase di:

- alleggerimento
- chiarezza
- leggibilità reale
- riduzione scroll

---

# STATO ATTUALE DEL MODULO

✔ struttura a 3 blocchi attiva  
✔ sezioni comprimibili attive  
✔ card Alice più leggibile  
✔ periodi Alice collapsable  
✔ banner Stato Alice attivo  
✔ editor Eventi Alice base funzionante  

---

# NON ANCORA FATTO

- editor eventi Alice completo
- modifica eventi Alice
- rimozione eventi Alice
- selezione orario reale
- selezione categoria
- note evento in dettaglio
- rifinitura grafica finale

---

# PROSSIMO PASSO UI

Dopo il collegamento Eventi Alice → copertura:

👉 rifinitura UI del blocco Eventi Alice

Ordine corretto:

1. collegamento al motore
2. rifinitura interfaccia

---

# FRASE DI RIPARTENZA

Ripartiamo da FrodoDesk — UI calendario stabile a 3 blocchi con card Alice/Scuola centrale e editor base Eventi Alice già funzionante. Prossimo passo UI: rifinire il blocco Eventi Alice dopo il collegamento al motore di copertura.

# 🔄 AGGIORNAMENTO 8 Maggio 2026

## 👧 EVENTI ALICE — COMPORTAMENTI REALI UI

La UI Eventi Alice si è evoluta da:

❌ semplice lista eventi

👉

✔ rappresentazione comportamento reale di Alice

---

## 🔥 NUOVI COMPORTAMENTI VISIBILI

La UI mostra ora:

✔ comportamento evento
✔ significato reale
✔ impatto copertura
✔ supervisione adulta
✔ stato fuori casa

---

## 🧱 EVENTI ACCOMPAGNATI

Nuova funzionalità UI:

✔ selezione adulto accompagnatore

Supportati:

- Matteo
- Chiara

---

## 🔗 COLLEGAMENTO VISIVO COPERTURA

Evento accompagnato:

✔ genera automaticamente:
"Alice con Matteo"
oppure
"Alice con Chiara"

nel blocco Buchi / Decisioni.

---

## 🔥 DISTINZIONE UI IMPORTANTE

Le companion generate automaticamente da evento:

❌ NON mostrano più il bottone manuale "Togli Alice"

Per modificarle:

👉 si modifica direttamente l’evento Alice sorgente

---

## 🧠 SIGNIFICATO STRUTTURALE

La UI non mostra più solo eventi.

👉 mostra relazioni reali tra:
- Alice
- adulto
- copertura

---

## 🚀 DIREZIONE UI FUTURA

Prossimo step ufficiale:

👉 eventi logistici con:
- accompagnamento reale
- ritiro reale
- conflitti logistici
- disponibilità adulto
- supporto necessario

---

## STATO

✔ stabile
✔ compilazione verificata
✔ test reale completato
✔ sync UI ↔ companion funzionante
✔ lifecycle coerente

---

# 🌍 EVOLUZIONE STRUTTURALE — UI MULTI FAMIGLIA

## DECISIONE UFFICIALE (GIUGNO 2026)

La UI attuale è stata costruita utilizzando la famiglia:

- Matteo
- Chiara
- Alice

come caso reale di utilizzo.

Questi nomi NON devono essere considerati elementi strutturali della UI.

---

## PRINCIPIO

La UI deve rappresentare:

👉 la realtà della famiglia attiva

e NON una famiglia specifica.

---

## STRUTTURA FUTURA

Ogni famiglia dovrà poter:

✔ creare i propri membri

✔ definire i propri ruoli

✔ configurare la propria realtà

senza modifiche alla UI.

---

## ESEMPI FUTURI

La UI dovrà poter rappresentare correttamente:

- coppia senza figli
- famiglia con 1 figlio
- famiglia con 4 figli
- famiglia con anziani
- famiglia con caregiver
- famiglia con supporti esterni

utilizzando la stessa struttura.

---

## EVENTI PERSONA

L'attuale blocco:

"ALICE / SCUOLA"

deve essere considerato il primo prototipo di un futuro sistema più generale.

Direzione futura:

👉 Eventi Persona

dove ogni persona della famiglia può avere:

- scuola
- sport
- visite
- lavoro
- attività
- impegni

senza dipendere dal nome Alice.

---

## CLOUD

La UI dovrà funzionare in modo identico su:

- PC
- telefono
- tablet

leggendo sempre la stessa sorgente dati condivisa.

---

## NOTIFICHE FUTURE

La UI diventerà il punto di arrivo delle notifiche provenienti dai vari moduli.

Esempi:

✔ modifica turno

✔ modifica copertura

✔ nuovo evento

✔ modifica evento

✔ nuova attività figlio

✔ richiesta proveniente da utenti esterni autorizzati

---

## ACCESSI FUTURI

La UI dovrà adattarsi automaticamente ai permessi dell'utente.

Esempio:

### Amministratore

vede tutte le funzioni

### Adulto

vede solo le funzioni autorizzate

### Accesso limitato

vede soltanto i moduli consentiti

---

## FILOSOFIA

La UI non deve essere costruita per Matteo.

La UI non deve essere costruita per Alice.

La UI deve essere costruita per rappresentare la vita reale di qualsiasi famiglia.

---

## NOTA

Questa evoluzione NON modifica le priorità attuali.

Priorità attuale:

✔ completamento calendario reale

✔ consolidamento PresenceEngine

✔ test vita reale quotidiana

✔ stabilizzazione moduli esistenti

La trasformazione cloud e multi-famiglia verrà affrontata in una fase successiva.