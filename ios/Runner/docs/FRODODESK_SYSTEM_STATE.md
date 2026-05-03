# FRODODESK — SYSTEM STATE

Ultimo aggiornamento: 1 Maggio 2026 (Home azionabile V1 consolidata + festivi corretti)

---

# IDENTITÀ DEL PROGETTO

FrodoDesk è un sistema di simulazione della realtà familiare progettato per:

- visualizzare la situazione reale del giorno
- rilevare problemi prima che accadano
- supportare decisioni operative nella gestione familiare

Principio fondamentale:

👉 Il sistema suggerisce  
👉 La decisione resta sempre umana

---

# FILOSOFIA DI SVILUPPO

Il sistema è costruito con filosofia CNC (Costruzione Non Caotica):

- un passo alla volta
- zero modifiche multiple insieme
- ogni blocco deve essere stabile prima di passare al successivo
- lavoro sempre su file reali

---

# FASE ATTUALE DEL PROGETTO

🔥 CALENDARIO REALE COMPLETO + COPERTURA REALE + HOME AZIONABILE V1 CONSOLIDATA

Il sistema è:

✔ utilizzabile nella vita reale  
✔ testato su casi concreti  
✔ stabile nei motori principali  
✔ coerente tra motore → calendario → Home  
✔ capace di trasformare un buco reale in problema visibile dalla Home  
✔ capace di spiegare nel popup il perché del problema  
✔ coerente anche nei giorni festivi senza scuola  

---

# 🧠 EVOLUZIONE STRUTTURALE

Il sistema ha fatto il passaggio chiave:

❌ prima → simulazione parziale  
✔ ora → simulazione reale della giornata  

Nuova evoluzione:

❌ prima → Home solo informativa  
✔ ora → Home orientata all’azione immediata  

---

# 🔥 BLOCCO SCUOLA

Stato: COMPLETATO

---

## RISULTATO

✔ SchoolStore attivo  
✔ Periodi funzionanti  
✔ Orari letti correttamente  
✔ Stato Alice coerente  
✔ Support network validato  
✔ UI allineata al motore  
✔ giorni festivi riconosciuti correttamente come “nessuna scuola prevista”  

👉 La scuola è ora fonte unica di verità

---

# 🔥 BLOCCO COPERTURA REALE

Stato: COMPLETATO / CONSOLIDATO

---

## REGOLA FONDAMENTALE

Alice è considerata **A CASA** quando NON è:

- a scuola
- in evento valido
- fuori casa per attività reale

---

## REGOLA COPERTURA

Se Alice è a casa:

👉 deve essere SEMPRE coperta da:

- Matteo
- Chiara
- Supporto
- Sandra (solo se attiva)

Se nessuno copre:

👉 ❌ BUCO REALE

---

## CAMBIAMENTO CHIAVE

✔ controllo esteso su tutta la giornata  
❌ NON più limitato a fasce Sandra  
❌ NON più legato solo alla scuola  
✔ valido anche nei giorni festivi  
✔ valido anche quando Alice è a casa perché scuola chiusa / festa / weekend  

---

## RISULTATO

✔ Buchi reali corretti  
✔ Eventi reali influenzano la copertura  
✔ Supporto integrato correttamente  
✔ Calendario coerente  
✔ Home coerente  
✔ test 1 Maggio validato: giorno festivo, nessuna scuola, genitori fuori per evento 14:00–18:00 → buco rilevato correttamente  

👉 Sistema finalmente affidabile

---

# 🔥 BLOCCO HOME AZIONABILE V1

Stato: IMPLEMENTAZIONE COMPLETATA E TESTATA

---

## RISULTATO

La Home ora:

✔ legge i buchi reali della copertura  
✔ mostra il problema copertura nella card principale  
✔ indica quanti problemi ci sono oggi  
✔ mostra il primo buco da gestire  
✔ bottone principale: **RISOLVI**  
✔ apre un popup con il problema  
✔ nel popup mostra:
   - numero problema
   - fascia oraria
   - spiegazione del perché
   - bottone **Vai al problema**
✔ permette il passaggio verso il calendario  

---

## DECISIONE STRUTTURALE

La Home NON deve essere solo una dashboard.

La Home deve diventare:

👉 centro operativo della giornata  
👉 motore di priorità  
👉 punto che dice cosa fare ora  

---

## REGOLA UX PRINCIPALE

Quando c’è un problema principale:

👉 la Home deve mostrare UNA cosa sola da fare

Esempio:

- ORA: Alice non coperta
- Alle 18:00 serve copertura per Alice
- Oggi: problema copertura

---

## FLUSSO DECISO

1. Home mostra problema principale  
2. Bottone unico: **RISOLVI**  
3. Popup spiega il problema  
4. Bottone unico nel popup: **Vai al problema**  
5. Apertura calendario nel giorno corretto  
6. Decisione finale umana  

---

## REGOLA DECISIONALE

Il sistema:

✔ spiega il problema  
✔ porta nel punto giusto  
❌ NON propone soluzioni operative automatiche  

Le soluzioni restano umane.

Esempi di soluzioni umane:

- spostare evento
- prendere permesso
- chiedere ferie
- attivare supporto
- modificare organizzazione familiare

---

## NOTA IMPORTANTE

La prima implementazione è nata sulla copertura, ma il concetto NON deve restare limitato alla copertura.

Questo è il primo prototipo del futuro:

👉 STRATO AZIONI UNIVERSALE

---

# 🔥 STRATO AZIONI UNIVERSALE (FUTURO)

Stato: DEFINITO CONCETTUALMENTE, NON ANCORA IMPLEMENTATO

---

## IDENTITÀ

Lo strato azioni universale dovrà trasformare qualsiasi problema reale in:

👉 problema → spiegazione → vai al punto → decisione umana

---

## ESEMPI FUTURI

Il sistema dovrà gestire problemi come:

- Alice non coperta
- assicurazione auto da pagare
- assicurazione non pagata
- bollo in scadenza
- gomme da cambiare
- gomme non cambiate da troppo tempo
- visite o impegni critici
- problemi economici futuri
- scadenze familiari importanti

---

## STRUTTURA DESIDERATA HOME FUTURA

### BLOCCO SOPRA

Una sola priorità:

👉 “Dimmi cosa devo fare ora”

Esempi:

- ORA: Alice non coperta
- Oggi: problema urgente da gestire
- Tutto sotto controllo

---

### BLOCCO SOTTO

Quando la situazione immediata è sotto controllo:

👉 mostrare problemi futuri

Esempio:

> Situazione sotto controllo  
> Occhio: hai 3 problemi nei prossimi 30 giorni

Ogni voce futura dovrà avere:

- titolo problema
- breve spiegazione
- bottone “Vai”
- apertura del punto corretto

---

## PRINCIPIO STRUTTURALE

La Home deve distinguere:

- problemi immediati
- problemi futuri
- problemi lenti / manutentivi

---

# 📚 STORICO / ANALISI ANNUALE

Stato: IDEA EMERSA, NON ANCORA IMPLEMENTATA

---

## OBIETTIVO FUTURO

Creare una sezione storica capace di analizzare, a partire dal 1 Gennaio dell’anno corrente:

- eventi già fatti
- eventi futuri
- promemoria già completati
- promemoria ancora aperti
- carico familiare
- ricorrenze
- andamento organizzativo reale

---

## PRINCIPIO

Lo storico NON deve essere solo archivio.

Deve diventare:

👉 memoria operativa del sistema  
👉 lettura della vita reale già passata  
👉 base per capire carichi, abitudini, problemi ricorrenti  

---

## ESEMPI FUTURI

Il sistema potrà dire:

- quanti eventi sono stati gestiti da gennaio
- quali persone hanno avuto più impegni
- quanti promemoria sono rimasti aperti
- quali problemi si ripetono spesso
- quali periodi dell’anno sono più pesanti

---

# STATO COPERTURA

✔ motore stabile  
✔ combinazione Matteo + Chiara corretta  
✔ gestione eventi reali corretta  
✔ gestione supporto corretta  
✔ gestione Alice a casa corretta  
✔ gestione giorni festivi corretta  
✔ buchi reali letti dalla Home  
✔ popup RISOLVI coerente con “Buchi del giorno” del calendario  
✔ spiegazione del buco visibile anche dalla Home  

---

# STATO EVENTI ALICE

✔ AliceEventStore attivo  
✔ AliceSpecialEventStore attivo  
✔ eventi integrati nel motore  
✔ nessun falso positivo  

---

# MOTORI ATTIVI

- TurnEngine  
- CoverageEngine  
- EmergencyDayLogic  
- FourthShiftCycleLogic  

---

# STORE PRINCIPALI

- CoreStore  
- OverrideStore  
- TurnOverrideStore  
- RotationOverrideStore  
- RealEventStore  
- AliceEventStore  
- AliceSpecialEventStore  
- SupportNetworkStore  
- FeriePeriodStore  
- DiseasePeriodStore  
- FourthShiftStore  
- SettingsStore  
- SummerCampScheduleStore  
- SummerCampSpecialEventStore  
- SchoolStore  

---

# STATO UI

✔ calendario funzionante  
✔ eventi reali integrati  
✔ stato Alice coerente  
✔ Home collegata al motore reale  
✔ Home capace di mostrare azioni rapide da buchi reali  
✔ popup azioni rapide testato  
✔ popup coerente con spiegazione “Buchi del giorno” del calendario  
✔ passaggio Home → popup → calendario verificato  

---

# ⚠️ STATO IPS

👉 NON ancora coerente con il sistema reale

Problema:

- non legge ancora pienamente i buchi reali
- usa logiche parziali
- non rappresenta ancora tutta la realtà
- non è ancora il motore unico delle priorità Home

---

# 🎯 PROSSIMA FASE

🔥 CONSOLIDAMENTO DOCUMENTI + NUOVA FASE STORICO

---

## OBIETTIVO IMMEDIATO

Chiudere correttamente lo stato stabile raggiunto.

Da fare:

1. aggiornare documenti reali
2. segnare come completato il popup Home RISOLVI
3. segnare come corretta la gestione festivi + Alice a casa
4. preparare nuova chat con file coerenti

---

## OBIETTIVO SUCCESSIVO

Avviare ragionamento sullo storico:

✔ eventi dal 1 Gennaio  
✔ eventi futuri  
✔ promemoria completati e aperti  
✔ lettura annuale della vita familiare  
✔ base futura per statistiche e analisi  

---

# DIREZIONE OPERATIVA

NON fare:

❌ modifiche multiple  
❌ salti di fase  
❌ logiche duplicate  
❌ UI senza base dati  
❌ soluzioni automatiche decise dal sistema  
❌ popup pieni di scelte operative premature  

Fare:

✔ un passo alla volta  
✔ motore prima  
✔ UI dopo  
✔ test reale continuo  
✔ Home orientata all’azione  
✔ decisione sempre umana  
✔ documenti aggiornati partendo sempre dai file reali forniti dall’utente  

---

# SIGNIFICATO ATTUALE

Il sistema ora:

👉 NON simula più  
👉 legge la realtà  
👉 spiega il problema  
👉 porta l’utente verso il punto da gestire  
👉 lascia la decisione finale all’umano  

---

# FRASE DI RIPARTENZA UFFICIALE

Ripartiamo da FrodoDesk — HOME AZIONABILE V1 consolidata: popup RISOLVI funzionante, festivi corretti, copertura reale coerente. Prossima fase: aggiornamento documenti e avvio ragionamento sullo storico annuale.