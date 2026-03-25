FRODODESK — RULES

Ultimo aggiornamento: 24 Marzo 2026


IDENTITÀ DEL SISTEMA

FrodoDesk è un sistema di controllo familiare e motore decisionale preventivo.

Non è:

un semplice calendario  
una semplice app turni  
un semplice gestionale spese  

È un sistema che simula la realtà della vita familiare per rendere visibile la pressione prima che diventi problema.


PRINCIPIO FONDAMENTALE

Il sistema suggerisce.  
La decisione resta sempre umana.


RUOLI

Utente

Responsabile di:

visione strategica  
decisione finale  


Frodo

Responsabile di:

architettura sistema  
metodo CNC  
coerenza tecnica  


FILOSOFIA DI SVILUPPO

Regole fondamentali:

un passo alla volta  
micro-step  
prima struttura poi estetica  
prima stabilità poi estensione  

Ogni blocco deve essere stabile prima di passare al successivo.

Il progetto segue la logica CNC (Costruzione Non Caotica).


REGOLA FILE REALI

Matteo invia sempre il file reale corrente presente nel progetto.

Frodo modifica solo quel file reale.

È vietato:

ricostruire file grandi basandosi sulla memoria  
ipotizzare il contenuto di file non inviati  
sostituire file interi senza partire dal file reale  

Obiettivo:

0 rischio.


REGOLA OPERATIVA CHAT

Durante lo sviluppo:

Matteo invia il file reale.  
Frodo restituisce lo stesso file completo modificato.  
Matteo copia e testa nell’app reale.

Mai saltare passaggi.


REGOLA “UN PASSO ALLA VOLTA”

Quando Matteo chiede una modifica o verifica:

Frodo deve:

indicare un solo passo  
attendere risposta  
non anticipare passi successivi  

Se vengono dati più passi insieme si rompe la logica CNC.


REGOLA TEST

Ogni modifica deve essere testata sull’app reale.

Comando standard:

flutter run -d edge --web-port 8080


REGOLA CHIUSURA CHAT

Quando si sta per chiudere una chat di sviluppo:

Matteo scrive:

“Chiudiamo la chat. Quali file docs dobbiamo aggiornare?”

Frodo analizza la chat corrente e indica solo i file che devono davvero essere aggiornati.

Non è obbligatorio aggiornare sempre tutti i file.

Dipende dal lavoro fatto nella chat.

Esempi:

modifica architettura → FRODODESK_ARCHITECTURE.md  
modifica roadmap → FRODODESK_ROADMAP.md  
modifica stato progetto → FRODODESK_SYSTEM_STATE.md  
nuove regole operative → FRODODESK_RULES.md  

Matteo invia solo i file richiesti.

Frodo restituisce ogni file completo aggiornato, pronto da copiare nella cartella docs.


PROCEDURA UFFICIALE — CHIUSURA CHAT FRODODESK

(aggiornata con richiesta file + backup dati)

1️⃣ Matteo avvia la chiusura

Matteo scrive:

Chiudiamo la chat. Quali file docs dobbiamo aggiornare?


2️⃣ Frodo analizza la chat e richiede i file

Frodo analizza tutta la chat e verifica modifiche a:

codice  
struttura  
roadmap  
regole  
stato sistema  

👉 Poi DEVE rispondere:

Mandami questi file da aggiornare:

- nome_file  
- nome_file  

⚠️ Solo quelli realmente coinvolti


3️⃣ Matteo invia i file reali

Regole fondamentali:

sempre file completo  
uno alla volta  
mai versioni ricostruite  
presi dalla cartella /docs  


4️⃣ Frodo restituisce i file aggiornati

Formato obbligatorio:

FILE AGGIORNATO  
nome_file  

(contenuto completo)

⚠️ Mai pezzi di file


5️⃣ Matteo aggiorna la cartella docs

Copia i file nella cartella:

/docs  

Poi scrive:

👉 “Fatto”


6️⃣ Salvataggio Git (obbligatorio)

Frodo fornisce i comandi:

git add .  
git commit -m "docs update"  
git push  


7️⃣ BACKUP DATI (quando necessario)

Se Frodo rileva rischio perdita dati (clean, debug, modifiche):

👉 deve attivare backup dati

Contenuti:

- malattia a periodo  
- ferie  
- eventi Alice  
- eventi reali  
- rete supporto  
- quarta squadra  
- override  

Formato:

👉 JSON esportabile

⚠️ Non sempre obbligatorio, ma obbligatorio se c’è rischio


8️⃣ Controllo finale

Verificare:

file docs aggiornati ✔  
copiati ✔  
commit ✔  
push ✔  
backup (se necessario) ✔  


9️⃣ Conferma finale di Frodo

Frodo deve dire:

“Confermo che non ci sono altri file docs da aggiornare.”

Solo dopo la chat è chiusa.


REGOLA OBIETTIVO DOCUMENTAZIONE

La cartella docs deve permettere di:

cambiare chat senza perdere contesto  
capire subito lo stato  
ripartire immediatamente  


⚠️ REGOLA FONDAMENTALE DEL SISTEMA

La fonte di verità resta:

➡ codice reale

Se docs ≠ codice → vale codice


REGOLA DECISIONALE — CONFLITTO TURNO ↔ EVENTO

Quando un evento cade dentro un turno:

👉 è conflitto reale

Il sistema deve:

- evidenziare sovrapposizione  
- mostrare turno  
- mostrare fascia  
- aiutare decisione  

Azioni:

- permesso  
- ferie  
- cambio turno  
- spostamento evento  


NUOVE REGOLE — MALATTIA

Distinzione obbligatoria:

Malattia leggera:
- può muoversi  
- può accompagnare Alice  

Malattia a letto:
- non può uscire  
- non disponibile  


REGOLA BLOCCANTE

Se stato = Malattia a letto:

👉 vietato cambio turno / override

Sistema deve bloccare o avvisare


REGOLA INPS

Durante malattia:

Fasce obbligatorie:

10:00–12:00  
17:00–19:00  

Sistema deve:

- considerare non disponibile  
- segnalare conflitti  
- permettere violazione consapevole  


REGOLA “IGNORA RISCHIO”

In caso di violazione INPS:

👉 mostrare:

“Ignora rischio”

Permette azione ma segnala rischio


EVOLUZIONE FUTURA MOTORE

Il conflitto evento ↔ turno dipenderà dallo stato:

normale → conflitto pieno  

malattia → valutazione diversa  

(non ancora implementato)


# 🔴 NUOVA REGOLA STRUTTURALE — NOTTE / POST-NOTTE

(Introdotta 19 Marzo 2026)

Quando un giorno è marcato come turno NOTTE (`N`):

👉 quel giorno NON rappresenta solo la notte che parte alle 22:00

Ma deve rappresentare SEMPRE tre componenti reali:

1. coda della notte precedente  
   → 00:00–06:30  

2. indisponibilità post-notte  
   → 00:00–14:30 (regola obbligatoria)

3. nuova notte la sera  
   → 21:00–06:30  

---

## Regola operativa

👉 Il post-notte è sempre presente se il giorno è `N`

Non dipende da:

- Alice (scuola / vacanza / malattia)
- Sandra
- eventi reali

È una **regola fisica della persona**.

---

## Implicazioni sul sistema

Il motore deve:

- considerare la persona NON disponibile fino alle 14:30
- generare correttamente i buchi mattina/pranzo
- NON permettere copertura falsa dopo la notte
- mantenere coerenza tra tutti gli scenari (Alice scuola / vacanza / malattia)

---

## Obiettivo

👉 evitare falsi positivi di copertura  
👉 allineare il sistema alla realtà fisica del recupero post-notte  


REGOLA — APERTURA CHAT FRODODESK

Ogni nuova chat deve iniziare con:

1) FRODODESK — RIPRESA SVILUPPO  
2) SYSTEM_STATE  
3) RULES  
4) file su cui si lavora  
5) file reale  

Poi si parte.
---

# REGOLA CRITICA — CONTINUITÀ DOCUMENTALE (21 Marzo 2026)

## ERRORE DA NON RIPETERE

Durante questa chat è stato commesso un errore grave:

👉 restituzione di un file docs **parziale e ridotto**
invece del file completo aggiornato.

Esempio reale:

- file originale ~700+ righe
- file restituito ~200 righe

Questo comportamento è **inaccettabile per FrodoDesk**.

---

## PRINCIPIO ASSOLUTO

FrodoDesk NON è un progetto normale.

È un sistema che vive di:

👉 memoria completa  
👉 continuità totale  
👉 contesto accumulato  

---

## REGOLA OPERATIVA OBBLIGATORIA

Quando Frodo aggiorna un file docs deve:

✔ restituire SEMPRE il file completo  
✔ mantenere TUTTO il contenuto esistente  
✔ aggiungere solo le nuove parti  
✔ NON semplificare  
✔ NON riassumere  
✔ NON “ripulire” il file  
✔ NON riorganizzare autonomamente  

---

## VIETATO

❌ accorciare il file  
❌ riscrivere il file “più pulito”  
❌ perdere dettagli storici  
❌ eliminare sezioni esistenti  
❌ reinterpretare il contenuto  

---

## MOTIVO

La nuova chat deve poter:

👉 leggere il file come se questa chat non fosse mai stata chiusa  

Se il file viene ridotto:

👉 si perde memoria  
👉 si perde contesto  
👉 si rompe il sistema  

---

## REGOLA FINALE

👉 I file docs sono memoria viva del sistema  
👉 NON devono mai essere compressi o semplificati  

Qualsiasi aggiornamento deve essere:

👉 SOLO AGGIUNTA  
👉 MAI SOSTITUZIONE E RENDERE SEMPRE FILE INTERO
---

# AGGIORNAMENTO — 24 MARZO 2026

## REGOLA FILE GRANDI / RISPOSTE BLOCCATE

Durante lo sviluppo reale di FrodoDesk è emerso un problema critico:

👉 i file molto lunghi (es. calendario_screen_stepa.dart) possono causare:
- timeout risposta
- messaggi troncati
- errore “tempo di consegna scaduto”
- perdita continuità operativa

---

## NUOVA REGOLA OPERATIVA

Quando si lavora su file molto grandi:

### CASO 1 — MODIFICA PICCOLA

👉 usare micro-step normale

- modifica singola riga
- sostituzione puntuale
- fix chirurgico

---

### CASO 2 — MODIFICA STRUTTURALE

👉 usare modalità a blocchi

Procedura obbligatoria:

1) Matteo invia file reale completo  
2) Frodo lavora sull’intero file  
3) Frodo restituisce file completo diviso in blocchi  

Formato:

BLOCCO 1  
BLOCCO 2  
BLOCCO 3  

---

## REGOLA DI SICUREZZA

Matteo deve:

- cancellare file originale  
- incollare blocchi in ordine  
- salvare  
- testare subito  

---

## REGOLA ANTI-ERRORE CRITICO

È vietato:

❌ tentare di inviare file enorme in un solo blocco se instabile  
❌ lasciare risposta a metà  
❌ generare file incompleto  

---

## PRINCIPIO OPERATIVO

👉 meglio più blocchi completi che un file troncato  

---

## VALIDAZIONE

Questo metodo è stato:

✔ testato in reale  
✔ necessario per continuità  
✔ adottato come standard ufficiale FrodoDesk  

---

## AGGIUNTA ALLA REGOLA FILE REALI

Quando necessario:

👉 “file completo” = può essere restituito in più blocchi

purché:

- nessuna parte venga persa  
- ordine corretto mantenuto  
- contenuto completo garantito  

---

# AGGIORNAMENTO — 24 MARZO 2026 (REGOLA BLOCCHI GRANDI DEFINITIVA)

## Nuova regola definitiva

Da questo momento, quando un file è grande, la restituzione deve seguire una procedura ancora più rigida.

Questa regola vale per:

- file del sistema
- file docs
- qualsiasi file lungo restituito da Frodo

---

## Limite massimo per blocco

Ogni blocco restituito deve restare entro circa:

👉 **1200 righe massime**

Questo serve per ridurre il rischio di:

- troncamento
- timeout
- perdita di porzioni finali
- risposta instabile

---

## Procedura obbligatoria a blocchi

Quando il file è lungo:

1. Frodo invia **BLOCCO 1**
2. Matteo cancella il file vecchio e incolla **BLOCCO 1**
3. Matteo scrive: **OK**
4. Frodo invia **BLOCCO 2**
5. Matteo incolla **BLOCCO 2**
6. Matteo scrive: **OK**
7. si continua così fino all’ultimo blocco

Solo dopo l’ultimo blocco Frodo deve dichiarare chiaramente che il file è completo.

---

## Divieto operativo

È vietato:

❌ inviare un file lungo tutto insieme se il rischio di troncamento è alto  
❌ inviare blocchi troppo lunghi  
❌ saltare il passaggio di conferma “OK” tra un blocco e il successivo  
❌ lasciare all’utente il dubbio se il file sia finito o no  

---

## Principio di sicurezza

Per FrodoDesk vale questa regola:

👉 meglio più blocchi piccoli, ordinati e sicuri  
che un file unico incompleto o instabile

---

## Regola finale consolidata

Qualsiasi file grosso deve essere:

- completo
- ordinato
- diviso in blocchi
- consegnato con conferma “OK” tra i blocchi
- senza mai superare circa 1200 righe per blocco

Questa è da considerare regola strutturale ufficiale del metodo FrodoDesk.
---

## 🔥 REGOLA OPERATIVA — AZIONI REVERSIBILI (25 Marzo 2026)

Nel sistema FrodoDesk, ogni azione operativa proposta all’utente deve essere:

- attivabile
- disattivabile
- reversibile
- trasparente

### Divieto assoluto

Il sistema NON deve mai:

- applicare automaticamente una soluzione definitiva
- nascondere lo stato reale originale
- impedire il ritorno al problema iniziale (es. buco)

### Principio fondamentale

👉 Il sistema suggerisce  
👉 L’utente decide  
👉 L’utente può sempre tornare indietro

### Applicazione concreta

Esempio:

“Porta Alice con Matteo / Chiara”

Deve:

- risolvere il buco quando attivo
- far riapparire il buco quando disattivato

### Significato strutturale

Le azioni nel sistema NON sono modifiche permanenti.

Sono:

👉 simulazioni operative temporanee

### Obiettivo

- mantenere sempre visibile la realtà
- permettere confronto tra soluzioni
- evitare automatismi che falsano la percezione del sistema