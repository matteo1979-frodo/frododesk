# FRODODESK — DEVELOPMENT GUIDE

Ultimo aggiornamento: 15 Marzo 2026

Questo documento spiega come lavorare sul progetto FrodoDesk.

Serve per mantenere ordine, sicurezza e continuità nello sviluppo.

---

# PRINCIPIO FONDAMENTALE

La fonte di verità tecnica è sempre il codice reale nel progetto.

La documentazione serve per guidare lo sviluppo, ma se diverge dal codice vale sempre il codice.

---

# STRUTTURA DOCUMENTAZIONE

La documentazione vive nella cartella:

docs/

File principali:

FRODODESK_SYSTEM_STATE.md  
FRODODESK_RULES.md  
FRODODESK_ROADMAP.md  
FRODODESK_ARCHITECTURE.md  

---

# CICLO DI LAVORO

Lo sviluppo segue il ciclo:

Lavoro su micro-step  
↓  
Test reale  
↓  
CHIUSURA CHAT FRODODESK  
↓  
Aggiornamento documentazione  
↓  
Nuova chat

---

# REGOLA MICRO-STEP

Ogni modifica deve essere piccola e isolata.

Mai fare più modifiche grandi nello stesso passo.

Questo riduce il rischio di rompere il sistema.

---

# REGOLA FILE REALI

Quando si lavora con assistenza AI:

Matteo invia sempre il file reale corrente presente nel progetto.

Frodo modifica solo quel file reale.

Mai ricostruire file grandi basandosi sulla memoria.

Obiettivo:

0 rischio.

---

# REGOLA TEST

Ogni modifica deve essere testata sull’app reale.

Comando standard avvio app:

flutter run -d edge --web-port 8080

---

# REGOLA RIAPERTURA CHAT

Quando si riapre una nuova chat di sviluppo FrodoDesk, la sequenza è sempre:

1. Scrivere:

FRODODESK — RIPRESA SVILUPPO

2. Incollare:

FRODODESK_SYSTEM_STATE.md

3. Indicare il file su cui si lavora

4. Incollare il file reale completo

5. Scrivere:

OK

Da quel momento lo sviluppo riprende con micro-step.
---

# AGGIORNAMENTO — 24 MARZO 2026

## GESTIONE FILE GRANDI / ANTI-TIMEOUT

Durante lo sviluppo di FrodoDesk è stato consolidato un nuovo metodo operativo per i file molto grandi, in particolare per file come:

`lib/screens/calendario_screen_stepa.dart`

quando superano dimensioni tali da rendere instabile la risposta completa in un solo messaggio.

### Problema reale emerso

Con file molto lunghi può succedere che:

- il file completo venga inviato dall’utente correttamente
- Frodo riesca a lavorarci
- ma la risposta completa in un solo blocco vada in timeout o si interrompa

Questo crea rischio di:

- messaggi troncati
- perdita di continuità
- confusione nel copia/incolla
- rallentamento del lavoro

---

## Nuovo metodo ufficiale

Da ora in avanti si distingue in modo operativo tra due casi.

### 1. Micro modifica

Esempi:

- cambio testo
- singola riga
- piccola sostituzione
- fix minimo

Metodo corretto:

- intervento chirurgico
- modifica puntuale
- nessuna riscrittura dell’intero file se non serve

---

### 2. Modifica strutturale

Esempi:

- riorganizzazione UI
- nuovi blocchi
- spostamento sezioni
- collapsable / espansioni
- modifiche visive ampie su file grandi

Metodo corretto:

1. Matteo invia il file reale completo
2. Frodo lavora sull’intero file
3. Frodo restituisce il file completo spezzato in blocchi

Formato operativo consigliato:

- BLOCCO 1
- BLOCCO 2
- BLOCCO 3

Matteo:

- svuota il file originale
- incolla i blocchi nell’ordine
- salva
- testa subito in app reale

---

## Regola pratica anti-timeout

Se il file è troppo grande per una risposta unica:

- NON tentare di forzare un solo blocco
- usare direttamente la modalità a blocchi
- preferire blocchi più corti e stabili piuttosto che blocchi troppo lunghi

Principio operativo:

👉 meglio 2–3 blocchi perfetti che 1 risposta troncata

---

## Decisione di continuità

Questo metodo è stato validato nella pratica reale come soluzione più affidabile per continuare a lavorare su FrodoDesk senza perdere controllo.

Da considerare quindi metodo ufficiale di sviluppo quando il file reale è troppo lungo per essere restituito in un unico messaggio in modo stabile.