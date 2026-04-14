# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: Aprile 2026

## IDENTITÀ DEL PROGETTO

FrodoDesk è un sistema di controllo familiare progettato per simulare la realtà della vita quotidiana e prevenire situazioni di pressione familiare prima che diventino problemi reali.

Non è un semplice calendario o un planner turni.

È un sistema che combina:

- simulazione dei turni
- disponibilità reale delle persone
- eventi familiari
- rete di supporto
- rilevazione automatica dei buchi

per offrire una visione reale della giornata e del futuro.

👉 Il sistema suggerisce  
👉 La decisione resta sempre umana

---

# PERSONE MODELLO

Famiglia principale:

Matteo  
Chiara  
Alice  

Rete di supporto:

Sandra  
altri supporti configurabili

---

# STRATI DEL SISTEMA

Work layer
- turni lavoro
- quarta squadra
- riposo post-notte

Family layer
- eventi Alice
- eventi familiari
- eventi personali
- centro estivo

Availability layer
- malattia
- ferie
- override giornalieri

Support layer
- rete supporto
- copertura Sandra

Coverage layer
- rilevazione buchi
- spiegazione copertura

---

# PRINCIPIO DI SVILUPPO

Il calendario deve diventare completamente utilizzabile nella vita reale prima di espandere il sistema.

Solo dopo si svilupperanno altri moduli come finanze, salute e statistiche.

---

# DECISIONI ARCHITETTURALI IMPORTANTI

## Conflitti reali

Il sistema non deve nascondere i conflitti della vita reale.

Quando un evento reale cade dentro un turno di lavoro:

👉 deve essere segnalato come conflitto reale

La risoluzione è sempre umana:

- cambiare turno
- prendere ferie o permesso
- spostare l’evento

---

## Filosofia del calendario

Il calendario FrodoDesk non è un calendario eventi.

È una:

👉 simulazione operativa della realtà familiare

Serve per:

- evidenziare problemi reali
- spiegare perché accadono
- anticipare decisioni

---

# STATO REALE DEL SISTEMA (APRILE 2026)

✔ motore di copertura stabile  
✔ gestione turni reale affidabile  
✔ modello notte/post-notte corretto  
✔ eventi Alice funzionanti  
✔ centro estivo sopra vacanza consolidato  
✔ Sandra coerente su tutte le fasce  
✔ calendario utilizzabile nella vita reale  

👉 fase “stabilità logica” completata

---

# PASSAGGIO DI FASE

Il progetto è passato da:

❌ costruzione motore  
👉 a  
✔ utilizzo reale + miglioramento continuo  

👉 FrodoDesk è ora uno strumento reale

---

# 🔥 BLOCCO SCUOLA — STATO REALE

## Fase attuale

👉 STRUTTURA COMPLETATA  
👉 MOTORE COLLEGATO  
👉 UI NON ANCORA ALLINEATA

---

## Problema iniziale (risolto)

La gestione scuola manuale causava:

- confusione uscita/rientro
- doppie azioni
- incoerenza sistema

---

## Soluzione implementata

### 1️⃣ Sistema a periodi

✔ Elementari  
✔ Medie  
✔ futuri cicli  

Ogni periodo contiene:

- nome
- data inizio/fine
- configurazione settimanale

---

### 2️⃣ Orario settimanale

Per ogni giorno:

- attivo / non attivo  
- ingresso  
- uscita reale  

✔ completamente modificabile  
✔ salvato correttamente  
✔ letto dal sistema  

---

### 3️⃣ Calcolo automatico

👉 rientro = uscita + 20 minuti  

✔ NON salvato  
✔ sempre calcolato  

---

## PRINCIPIO FONDAMENTALE

Separazione obbligatoria:

- uscita reale = dato umano  
- rientro = dato logico  

👉 mai mescolare

---

## LOGICA ATTUALE CORRETTA

Ordine:

1. Eventi Alice
2. Eventi Alice temporanei
3. Periodo scuola attivo
4. Orario settimanale
5. Motore copertura

---

## STATO MOTORE

✔ CoverageEngine legge SchoolStore  
✔ giorni attivi/off rispettati  
✔ orari letti dal periodo  
✔ copertura coerente  

👉 MOTORE OK

---

## PROBLEMA ATTUALE (CRITICO)

⚠️ UI NON ALLINEATA

Sintomi:

- “Stato Alice: scuola normale” anche quando non dovrebbe
- “Alice fuori · scuola” incoerente
- mismatch tra:
  - box scuola
  - stato Alice
  - copertura reale

👉 causa:

❌ UI usa ancora vecchie funzioni/logiche  
✔ motore usa nuova struttura  

---

## CONCLUSIONE TECNICA

Sistema attuale:

✔ dati corretti  
✔ logica corretta  
❌ visualizzazione parzialmente errata  

👉 serve allineamento UI → motore

---

# IMPATTO STRATEGICO

Alice ora è:

✔ entità strutturata del sistema  
✔ non più gestita manualmente  
✔ equivalente a un turno  

---

# DIREZIONE DEL SISTEMA

Evoluzione:

❌ inserimento manuale  
👉  
✔ sistema automatico + decisione umana  

---

# PRINCIPIO GUIDA

FrodoDesk NON deve:

❌ far lavorare l’utente ogni giorno  

Deve:

✔ automatizzare  
✔ mostrare la realtà  
✔ lasciare la decisione  

---

# STATO DEL PROGETTO

✔ sistema stabile  
✔ motore affidabile  
✔ copertura reale coerente  
✔ eventi Alice funzionanti  
✔ scuola strutturata  
✔ settimana scuola modificabile  
✔ motore collegato alla scuola  

🔥 aperto:

👉 allineamento UI stato Alice

---

# PROSSIMI STEP REALI

1️⃣ Analisi UI calendario  
→ trovare dove legge stato Alice

2️⃣ Eliminazione logica vecchia  
→ sostituire con lettura da SchoolStore

3️⃣ Allineamento completo  
→ stato Alice = motore reale

---

# DOPO QUESTO STEP

👉 sistema scuola completamente chiuso  
👉 base pronta per IPS e decisioni avanzate  

---

# PRINCIPIO OPERATIVO

✔ un passo alla volta  
✔ modifica isolata  
✔ test immediato  
✔ nessuna anticipazione  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — ALLINEAMENTO UI STATO ALICE: eliminare completamente le vecchie letture e collegare la UI al sistema scuola e al motore reale.