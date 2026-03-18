FRODODESK — RULES

Ultimo aggiornamento: 17 Marzo 2026


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

Questa procedura va eseguita ogni volta che si chiude una chat di sviluppo FrodoDesk per garantire che la documentazione del progetto resti coerente con il codice reale.

1️⃣ Matteo avvia la chiusura

Matteo scrive:

Chiudiamo la chat. Quali file docs dobbiamo aggiornare?


2️⃣ Frodo analizza la chat

Frodo analizza tutta la chat appena svolta e verifica se sono state fatte modifiche a:

codice del progetto  
struttura del sistema  
roadmap di sviluppo  
regole operative  
decisioni architetturali  

In base a questo decide quali file nella cartella /docs devono essere aggiornati.

⚠️ Non è automatico che siano sempre tutti.


3️⃣ Matteo invia i file reali

Matteo invia i file reali presenti nel progetto.

Regole fondamentali:

sempre file completo  
uno alla volta  
mai versioni ricostruite a memoria  
devono essere i file reali presenti nella cartella /docs  


4️⃣ Frodo restituisce i file aggiornati

Per ogni file ricevuto Frodo restituisce:

file completo  
file aggiornato  
file pronto da incollare  

Formato risposta:

FILE AGGIORNATO  
nome_file

(con dentro il contenuto completo aggiornato)

⚠️ Regola assoluta:

mai pezzi di file  
sempre file intero


5️⃣ Matteo aggiorna la cartella docs

Matteo copia i file aggiornati nella cartella:

/docs

del progetto FrodoDesk.


6️⃣ Salvataggio obbligatorio (Git)

Dopo aver aggiornato i file docs, eseguire SEMPRE:

git add .  
git commit -m "docs update"  
git push

Questo passaggio garantisce:

- allineamento tra locale e remoto  
- possibilità di cambiare chat senza perdere stato  
- continuità completa del progetto  


7️⃣ Controllo finale

Verificare sempre:

- file docs aggiornati ✔  
- copiati nella cartella `/docs` ✔  
- commit eseguito ✔  
- push eseguito ✔  


8️⃣ Conferma finale di Frodo

Prima della chiusura definitiva della chat:

Frodo controlla nuovamente lo stato della chat e conferma:

“Confermo che non ci sono altri file docs da aggiornare.”

Solo dopo questa conferma la chat può essere considerata chiusa correttamente.


REGOLA OBIETTIVO DOCUMENTAZIONE

La cartella docs deve sempre permettere di:

cambiare chat senza perdere il contesto  
capire immediatamente lo stato del progetto  
sapere da dove ripartire nello sviluppo  


⚠️ REGOLA FONDAMENTALE DEL SISTEMA

La fonte di verità del sistema resta sempre:

➡ il codice reale del progetto

I file nella cartella /docs servono per:

continuità tra chat  
stato del sistema  
decisioni strutturali  
roadmap di sviluppo  

Se docs e codice non coincidono, vale sempre:

➡ il codice reale


REGOLA DECISIONALE — CONFLITTO TURNO ↔ EVENTO

Quando un evento cade dentro un turno di lavoro, il sistema deve trattarlo come **conflitto reale** e non come semplice informazione.

Il sistema deve:

- segnalare chiaramente la sovrapposizione
- mostrare il turno coinvolto
- mostrare la fascia oraria in conflitto
- aiutare l’utente a prendere una decisione operativa

Possibili azioni operative:

- prendere permesso
- prendere ferie
- cambiare turno
- spostare evento


EVOLUZIONE FUTURA DEL MOTORE DECISIONALE

Durante lo sviluppo è emersa una regola progettuale importante:

il conflitto evento ↔ turno non deve sempre essere valutato allo stesso modo.

Il sistema dovrà considerare **lo stato reale della persona**.

Esempio concettuale:

stato normale → conflitto rosso pieno  

malattia leggera / malattia a letto →  
valutazione più morbida (evento da rivalutare)

Motivazione:

una visita medica può essere compatibile con uno stato di malattia.

Questa logica non è ancora implementata nel codice ma è registrata come direzione evolutiva del motore decisionale FrodoDesk.


REGOLA — APERTURA CHAT FRODODESK

Ogni nuova chat FrodoDesk deve iniziare con questa sequenza:

1) Messaggio  
FRODODESK — RIPRESA SVILUPPO  

2) Incollare  
docs/FRODODESK_SYSTEM_STATE.md  

3) Incollare  
docs/FRODODESK_RULES.md  

4) Indicare il file su cui si lavora  

5) Incollare il file reale  

Solo dopo si riprende lo sviluppo.