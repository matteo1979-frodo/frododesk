# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: Aprile 2026 (post fix scuola motore + support network)

---

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
👉 UI ALLINEATA  
👉 LOGICA TEMPORALE CORRETTA  

---

## Problema iniziale (RISOLTO)

La gestione scuola manuale causava:

- confusione uscita/rientro
- doppie azioni
- incoerenza sistema

---

## 🔥 BUG CRITICO RISOLTO (STATO ALICE)

Sintomi precedenti:

❌ Alice risultava “fuori • scuola” anche nei giorni OFF  
❌ popup incoerente (scuola mostrata ma non reale)  
❌ mismatch tra:
- stato Alice
- eventi giornata
- configurazione scuola  

---

## CAUSA

❌ duplicazione logica (UI + motore)  
❌ utilizzo funzioni legacy non allineate  
❌ più punti di calcolo dello stato Alice  

---

## SOLUZIONE IMPLEMENTATA

✔ centralizzazione logica su SchoolStore  
✔ introduzione controllo reale giorno scuola  
✔ rimozione logica duplicata  
✔ allineamento UI → motore  

👉 UNA SOLA VERITÀ

---

## 🔥 FIX STRUTTURALE — ORARI REALI SCUOLA

Problema:

❌ il sistema utilizzava fallback fissi (es. 08:25)  
❌ ingresso/uscita non sempre coerenti col periodo reale  

Soluzione:

✔ ingresso letto da SchoolStore  
✔ uscita letta da SchoolStore  
✔ rientro calcolato automaticamente (+20 min)  

---

## 🔥 FIX CRITICO — VALIDAZIONE COPERTURA

Problema:

❌ il sistema considerava copertura valida solo perché esisteva un supporto attivo  
❌ NON controllava se la fascia oraria era realmente coperta  

Esempio reale:

Sandra 07:00–08:25  
copriva ingresso 09:05–09:25 ❌

---

## SOLUZIONE

✔ validazione supporto basata su intervallo reale  
✔ eliminazione fallback orari fissi nel controllo copertura  

---

## PRINCIPIO STRUTTURALE (NUOVO)

👉 La copertura è valida SOLO se il tempo coincide

NON basta:
❌ supporto attivo  

Serve:
✔ copertura reale della fascia  

---

## RISULTATO

✔ buchi coerenti con la realtà  
✔ supporto validato correttamente  
✔ eliminati falsi positivi di copertura  

👉 comportamento finalmente realistico

---

# STRUTTURA BLOCCO SCUOLA

## 1️⃣ Sistema a periodi

✔ Elementari  
✔ Medie  
✔ futuri cicli  

---

## 2️⃣ Orario settimanale

✔ ingresso reale  
✔ uscita reale  
✔ completamente modificabile  
✔ letto dal motore  

---

## 3️⃣ Calcolo automatico

👉 accompagnamento = ingresso - 20 min  
👉 rientro = uscita + 20 min  

✔ NON salvati  
✔ sempre calcolati  

---

## PRINCIPIO FONDAMENTALE

Separazione obbligatoria:

- dati reali = scuola  
- logica = calcoli temporali  

👉 mai mescolare

---

## STATO MOTORE

✔ CoverageEngine legge SchoolStore  
✔ orari reali rispettati  
✔ support network validato correttamente  

👉 MOTORE STABILE E COERENTE

---

# ⚠️ BUG ATTIVO IDENTIFICATO

👉 USCITA ANTICIPATA NON IMPATTA IL MOTORE

Sintomo:

- UI aggiornata correttamente  
- decisione scuola aggiornata  
- ❌ buco NON si chiude  

Causa:

👉 uscita anticipata non letta dal CoverageEngine  

---

# STATO UI (POST FIX)

✔ stato Alice corretto  
✔ popup allineato  
✔ eventi coerenti  
✔ scuola coerente con motore  

---

# IMPATTO STRATEGICO

Alice ora è:

✔ entità strutturata  
✔ guidata da sistema reale  
✔ non più manuale  

---

# DIREZIONE DEL SISTEMA

Evoluzione:

❌ simulazione approssimativa  
👉  
✔ simulazione reale basata sul tempo  

---

# STATO DEL PROGETTO

✔ sistema stabile  
✔ motore affidabile  
✔ copertura coerente  
✔ scuola completamente integrata  

🔥 aperto:

👉 uscita anticipata nel motore

---

# PROSSIMI STEP REALI

A — collegare uscita anticipata al motore  
B — verifica chiusura buchi  
C — test reale completo  
D — rifinitura UI  

---

# PRINCIPIO OPERATIVO

✔ un passo alla volta  
✔ modifica isolata  
✔ test immediato  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — FIX USCITA ANTICIPATA: collegare l’orario reale al motore di copertura e verificare la chiusura corretta dei buchi.

---

# 🔄 AGGIORNAMENTO 5 Maggio 2026

## HOME + EVENTI GLOBALI + MEMORIA EVENTI

---

## 🔥 NUOVO PASSAGGIO STRUTTURALE

Il sistema ha fatto un salto importante:

❌ prima → eventi come dati temporanei  
✔ ora → eventi come memoria reale persistente  

---

## 🧠 EVENTI GLOBALI

Introdotto sistema di navigazione nel tempo:

✔ anno  
✔ mesi (griglia visiva)  
✔ eventi del mese  
✔ dettaglio evento  

---

## SIGNIFICATO

👉 il sistema non mostra più solo “oggi”  
👉 permette di navigare nella vita nel tempo  

---

## 🧠 MEMORIA EVENTI

Ogni evento ora può contenere:

✔ note  
✔ dettagli reali  
✔ memoria personale  

✔ salvataggio persistente  
✔ disponibile dopo riavvio  

---

## SIGNIFICATO

👉 nasce lo storico reale della famiglia  
👉 base futura per analisi e statistiche  

---

## 🧠 EVENTI MULTI-PERSONA

Introdotto supporto:

✔ più persone per evento  
✔ integrazione con copertura  
✔ lettura corretta nel motore  

---

## RISULTATO

✔ eventi più realistici  
✔ copertura più precisa  
✔ maggiore coerenza sistema  

---

## 🧱 ARCHITETTURA DECISA

Decisione importante:

👉 le funzionalità complesse NON devono stare nella Home  

✔ Home = vista  
✔ moduli = logica  

---

## 🔥 NASCITA MODULO STATISTICHE

Decisione ufficiale:

✔ creare modulo dedicato  
✔ NON sviluppare dentro Home  

---

## SIGNIFICATO

👉 FrodoDesk non è più solo simulazione  
👉 diventa sistema di analisi della vita reale  

---

## DIREZIONE FUTURA

Il sistema evolverà verso:

- storico eventi  
- analisi comportamento familiare  
- lettura visiva tramite grafici  
- supporto decisionale avanzato  

---

## STATO

✔ stabile  
✔ testato su app reale  
✔ memoria eventi funzionante  
✔ Eventi Globali funzionanti  
✔ struttura pronta per evoluzione