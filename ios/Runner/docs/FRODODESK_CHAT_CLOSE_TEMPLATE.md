# FRODODESK — CHAT CLOSE TEMPLATE UFFICIALE (v3.0)

Questo template va usato alla fine di ogni chat FrodoDesk.

Serve per garantire:

- documentazione aggiornata  
- allineamento con codice reale  
- continuità tra chat  
- zero perdita di stato logico  
- protezione dei dati reali dell’utente  

---

## 📦 BLOCCO DI CHIUSURA

Quando vuoi chiudere la chat scrivi:

Chiudiamo la chat.  
Quali file docs dobbiamo aggiornare?

File disponibili:

- docs/FRODODESK_ARCHITECTURE.md  
- docs/FRODODESK_CHAT_CLOSE_TEMPLATE.md  
- docs/FRODODESK_CHAT_TEMPLATE.md  
- docs/FRODODESK_DEV_GUIDE.md  
- docs/FRODODESK_PROJECT_MEMORY.md  
- docs/FRODODESK_ROADMAP.md  
- docs/FRODODESK_RULES.md  
- docs/FRODODESK_SYSTEM_STATE.md  

---

## 📦 PROCEDURA COMPLETA

### 1️⃣ Frodo analizza la chat e richiede i file

Frodo analizza tutta la chat appena svolta, incrociando sempre con lo stato reale del codice quando disponibile, e verifica se sono state fatte modifiche a:

- codice del progetto  
- struttura del sistema  
- roadmap di sviluppo  
- regole operative  
- stato del sistema  

👉 In base a questa analisi, Frodo deve:

- identificare quali file docs devono essere aggiornati  
- richiedere esplicitamente SOLO quei file  

Formato risposta obbligatorio:

Mandami questi file da aggiornare:

- nome_file  
- nome_file  
- nome_file  

⚠️ Regole:

- mai chiedere tutti i file automaticamente  
- solo quelli realmente coinvolti  
- decisione basata sulla chat reale  

---

### 2️⃣ Matteo invia i file reali

Regole:

- file completi  
- uno alla volta  
- presi dalla cartella /docs  
- mai ricostruiti  

---

### 3️⃣ Frodo restituisce i file aggiornati

Per ogni file ricevuto Frodo restituisce:

FILE AGGIORNATO  
nome_file  

(contenuto completo)

Regole:

- mai pezzi di file  
- sempre file intero  
- pronto da copiare  

---

### 4️⃣ Matteo aggiorna la cartella docs

Copia i file dentro:

/docs  

del progetto FrodoDesk.

Poi scrive:

👉 “Fatto”

---

### 5️⃣ Procedura di salvataggio (attivata da Frodo)

Dopo il “Fatto”:

Frodo fornisce i comandi Git da eseguire:

git add .  
git commit -m "docs update"  
git push  

Obiettivo:

- allineamento locale/remoto  
- continuità tra chat  
- sicurezza stato progetto  

---

### 6️⃣ BACKUP DATI (gestito da Frodo quando serve)

Frodo deve valutare automaticamente se c’è rischio perdita dati.

Se rileva rischio (es. debug, clean, modifiche strutturali):

👉 deve attivare il backup dati proponendo:

Salvataggio di:

- malattia a periodo  
- ferie  
- eventi Alice  
- eventi reali  
- rete supporto  
- quarta squadra  
- override  

Formato iniziale:

👉 JSON esportabile (anche manuale)

⚠️ Regola:

- non obbligatorio sempre  
- obbligatorio quando c’è rischio  

---

### 7️⃣ Controllo finale

Verificare:

- file docs aggiornati ✔  
- copiati nella cartella `/docs` ✔  
- commit eseguito ✔  
- push eseguito ✔  
- eventuale backup dati eseguito ✔  

---

### 8️⃣ Chiusura operativa della chat

Frodo deve:

- verificare nuovamente lo stato della chat  
- confermare che non ci sono altri file docs da aggiornare  

Frase obbligatoria:

👉 “Confermo che non ci sono altri file docs da aggiornare.”

Solo dopo:

- chat chiusa correttamente  
- continuità garantita  
- nuova chat sicura  

---

## 🎯 RISULTATO

- zero perdita di stato logico  
- zero perdita dati reali  
- docs sempre allineati al codice  
- Git sempre aggiornato  
- flusso automatico  
- controllo totale  

---

## 📌 NOTA FONDAMENTALE

La fonte di verità del sistema resta sempre:

➡ il codice reale del progetto  

I file nella cartella /docs servono per:

- continuità tra chat  
- memoria del progetto  
- organizzazione dello sviluppo  