FRODODESK — RULES

Ultimo aggiornamento: 1 Maggio 2026 (Home azionabile consolidata + fix festivi + coerenza popup)

---

IDENTITÀ DEL SISTEMA

FrodoDesk è un sistema di controllo familiare e motore decisionale preventivo.

Non è:

un semplice calendario  
una semplice app turni  
un semplice gestionale spese  

È un sistema che simula la realtà della vita familiare per rendere visibile la pressione prima che diventi problema.

---

PRINCIPIO FONDAMENTALE

Il sistema suggerisce.  
La decisione resta sempre umana.

---

RUOLI

Utente

Responsabile di:

visione strategica  
decisione finale  

---

Frodo

Responsabile di:

architettura sistema  
metodo CNC  
coerenza tecnica  

---

FILOSOFIA DI SVILUPPO

Regole fondamentali:

un passo alla volta  
micro-step  
prima struttura poi estetica  
prima stabilità poi estensione  

Ogni blocco deve essere stabile prima di passare al successivo.

Il progetto segue la logica CNC (Costruzione Non Caotica).

---

REGOLA FILE REALI

Matteo invia sempre il file reale corrente presente nel progetto.

Frodo modifica solo quel file reale.

È vietato:

ricostruire file grandi basandosi sulla memoria  
ipotizzare il contenuto di file non inviati  
sostituire file interi senza partire dal file reale  

Obiettivo:

0 rischio.

---

REGOLA OPERATIVA CHAT

Durante lo sviluppo:

Matteo invia il file reale.  
Frodo restituisce lo stesso file completo modificato.  
Matteo copia e testa nell’app reale.

Mai saltare passaggi.

---

REGOLA “UN PASSO ALLA VOLTA”

Quando Matteo chiede una modifica o verifica:

Frodo deve:

indicare un solo passo  
attendere risposta  
non anticipare passi successivi  

Se vengono dati più passi insieme si rompe la logica CNC.

---

REGOLA TEST

Ogni modifica deve essere testata sull’app reale.

Comando standard:

flutter run -d edge --web-port 8080

---

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

---

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

---

REGOLA OBIETTIVO DOCUMENTAZIONE

La cartella docs deve permettere di:

cambiare chat senza perdere contesto  
capire subito lo stato  
ripartire immediatamente  

---

⚠️ REGOLA FONDAMENTALE DEL SISTEMA

La fonte di verità resta:

➡ codice reale

Se docs ≠ codice → vale codice

---

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

---

NUOVE REGOLE — MALATTIA

Distinzione obbligatoria:

Malattia leggera:
- può muoversi  
- può accompagnare Alice  

Malattia a letto:
- non può uscire  
- non disponibile  

---

REGOLA BLOCCANTE

Se stato = Malattia a letto:

👉 vietato cambio turno / override

Sistema deve bloccare o avvisare

---

REGOLA INPS

Durante malattia:

Fasce obbligatorie:

10:00–12:00  
17:00–19:00  

Sistema deve:

- considerare non disponibile  
- segnalare conflitti  
- permettere violazione consapevole  

---

REGOLA “IGNORA RISCHIO”

In caso di violazione INPS:

👉 mostrare:

“Ignora rischio”

Permette azione ma segnala rischio

---

EVOLUZIONE FUTURA MOTORE

Il conflitto evento ↔ turno dipenderà dallo stato:

normale → conflitto pieno  
malattia → valutazione diversa  

(non ancora implementato)

---

# 🔴 NUOVA REGOLA STRUTTURALE — NOTTE / POST-NOTTE

(Introdotta 19 Marzo 2026)

Quando un giorno è marcato come turno NOTTE (`N`):

👉 quel giorno NON rappresenta solo la notte che parte alle 22:00

Ma deve rappresentare SEMPRE tre componenti reali:

1. coda della notte precedente → 00:00–06:30  
2. indisponibilità post-notte → 00:00–14:30  
3. nuova notte la sera → 21:00–06:30  

---

## Regola operativa

👉 Il post-notte è sempre presente se il giorno è `N`

È una **regola fisica della persona**.

---

## Implicazioni

- NON disponibile fino alle 14:30  
- genera buchi reali  
- niente copertura falsa  

---

# 🔥 NUOVA REGOLA STRUTTURALE — AZIONI SENZA SOLUZIONI (CONSOLIDATA)

## PRINCIPIO

Il sistema NON deve proporre soluzioni operative.

## COMPORTAMENTO CORRETTO

✔ rileva il problema  
✔ spiega il problema  
✔ mostra il perché  
✔ porta al punto corretto  

## COMPORTAMENTO VIETATO

❌ suggerire azioni  
❌ decidere al posto dell’utente  

---

# 🔴 NUOVA REGOLA CRITICA — COPERTURA FESTIVI (1 MAGGIO 2026)

## Problema emerso

Nei giorni festivi:

👉 Alice risultava a casa  
👉 ma il sistema poteva NON generare buco  

## Regola corretta

👉 Se Alice è a casa (anche festivo):

SI applica SEMPRE la regola copertura

## Implicazione

✔ festivo ≠ giorno speciale  
✔ festivo ≠ copertura automatica  
✔ festivo segue stessa logica reale  

## Principio finale

👉 La copertura NON dipende dalla scuola  
👉 Dipende SOLO da: presenza reale degli adulti  

---

# 🔴 NUOVA REGOLA — COERENZA HOME ↔ CALENDARIO

## Principio

👉 La Home deve mostrare ESATTAMENTE ciò che il calendario mostra

## Regola

✔ stesso buco  
✔ stessa fascia  
✔ stessi motivi  

## Vietato

❌ Home dice OK ma calendario ha buco  
❌ spiegazioni diverse  

## Obiettivo

👉 una sola verità nel sistema  

---

# 🔴 NUOVA REGOLA — POPUP AZIONI

## Comportamento obbligatorio

Il popup deve mostrare:

✔ problema reale  
✔ fascia oraria  
✔ spiegazione reale  
✔ motivi (Matteo fuori, Chiara fuori, ecc.)  

✔ bottone: "Vai al problema"  

## Vietato

❌ suggerimenti operativi  
❌ azioni automatiche  

## Obiettivo

👉 rendere il problema chiaro  
👉 NON risolverlo automaticamente  

---

# 🔴 NUOVA REGOLA — COERENZA SPIEGAZIONE BUCHI

## Principio

La spiegazione deve essere:

✔ identica tra:
- Home popup  
- Buchi del giorno (calendario)

## Obiettivo

👉 evitare doppie logiche  
👉 evitare confusione  

---

# 🔴 REGOLA CRITICA — CONTINUITÀ DOCUMENTALE (21 Marzo 2026)

(file NON deve mai essere ridotto)

✔ sempre completo  
✔ mai riassunto  
✔ mai semplificato  

👉 memoria viva del sistema  

---

# 🔴 NUOVA REGOLA CRITICA — COPERTURA REALE TEMPORALE

Una copertura è valida SOLO se copre completamente l’intervallo.

supportStart ≤ gapStart  
AND  
supportEnd ≥ gapEnd  

👉 niente coperture parziali  

---

## PRINCIPIO FINALE

👉 Il sistema NON deve mai “pensare che basti”  
👉 Deve verificare che COPRA davvero  