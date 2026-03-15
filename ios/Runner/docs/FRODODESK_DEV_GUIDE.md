# FRODODESK — DEVELOPMENT GUIDE

Ultimo aggiornamento: 14 Marzo 2026

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