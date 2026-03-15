# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 14 Marzo 2026

---

# FASE ATTUALE

Calendario reale – rifinitura e consolidamento UI.

Obiettivo della fase:

rendere il calendario completamente utilizzabile nella vita reale prima di sviluppare altri moduli.

Moduli futuri previsti ma non ancora in sviluppo:

- Finanze
- Spese
- Salute
- Auto
- Statistiche / Storico

Decisione strutturale confermata:

👉 prima completare e testare il calendario nella vita reale.

---

# MOTORI ATTIVI

TurnEngine  
CoverageEngine  
EmergencyDayLogic  
FourthShiftCycleLogic  

---

# STORE ATTIVI

OverrideStore  
DiseasePeriodStore  
FeriePeriodStore  
SupportNetworkStore  
RealEventStore  
AliceEventStore  

---

# COSA IL SISTEMA SIMULA GIÀ

Il calendario oggi gestisce correttamente:

- turni lavoro
- quarta squadra
- riposo post-notte
- ferie lunghe
- malattia a periodo
- eventi reali
- eventi Alice / scuola
- rete di supporto
- copertura Sandra / Babysitter
- buchi reali giornata
- conflitti eventi
- conflitti turni stesso giorno

Persistenza dati verificata funzionante.

Repository GitHub attivo:

matteo1979-frodo/frododesk

---

# FILE ATTUALMENTE IN LAVORAZIONE

lib/screens/calendario_screen_stepa.dart

---

# MICRO-STEP COMPLETATO IN QUESTA CHAT

Popup eventi extra nei Turni.

Funzione creata:

_showExtraEventsDialog

Posizionamento:

dentro la classe

_CalendarioScreenStepAStabileState

subito sopra la graffa finale `}` della classe.

Intervento effettuato:

- solo UI
- nessuna modifica a motori
- nessuna modifica agli store
- nessuna modifica alla logica di sistema

---

# STATO TEST APP

App avviata con:

flutter run -d edge --web-port 8080

Schermata verificata:

Turni.

Visualizzazione attuale:

- evento principale sotto il turno
- link `+1 altro evento`
- popup eventi funzionante

La UI non è ancora identica al mock originale ma il sistema è stabile.

Decisione presa:

👉 per ora lasciarla così e proseguire con i prossimi step.

---

# IDEA NUOVA EMERSA IN QUESTA CHAT

Evento generale / famiglia nel calendario.

Esempio reale:

Fiera dei fiori  
17–18–19 Aprile

Tipo evento previsto:

personKey = family  
oppure  
personKey = generale

Decisione architetturale:

✔ usare lo stesso sistema eventi attuale  
✔ non creare nuovi store  
✔ riutilizzare `RealEventStore`

---

# PROSSIMO STEP CNC

Integrare eventi generali / famiglia nel calendario.

Passo operativo previsto:

verificare il form di creazione eventi reali per permettere:

personKey = family

---

# FRASE DI RIATTIVAZIONE PROSSIMA CHAT

Ripartiamo da FrodoDesk — eventi generali/famiglia nel calendario.

File di lavoro previsto:

lib/screens/calendario_screen_stepa.dart