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