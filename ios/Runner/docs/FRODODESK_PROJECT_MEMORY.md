# FRODODESK — PROJECT MEMORY

Ultimo aggiornamento: 20 Luglio 2026
(H6 in corso — memoria architetturale e formalizzazione Metodo CNC)

━━━━━━━━━━━━━━━━━━

# IDENTITÀ DEL PROGETTO

━━━━━━━━━━━━━━━━━━

FrodoDesk è un sistema di simulazione della realtà familiare.

Il suo obiettivo non è organizzare appuntamenti.

Il suo obiettivo è comprendere il comportamento della vita quotidiana e aiutare la famiglia a prendere decisioni migliori.

Il progetto continua ad evolvere seguendo un principio immutabile:

👉 il sistema osserva

👉 interpreta

👉 suggerisce

👉 la decisione resta sempre umana.

FrodoDesk NON è:

❌ un calendario

❌ un planner turni

❌ un gestionale

❌ un home banking

❌ un semplice insieme di schermate

È invece:

✔ simulatore della stabilità familiare

✔ motore di prevenzione

✔ interprete della pressione familiare

✔ ecosistema di motori specializzati

✔ piattaforma destinata ad evolvere verso un sistema multi-famiglia.

━━━━━━━━━━━━━━━━━━

# FILOSOFIA FONDAMENTALE

━━━━━━━━━━━━━━━━━━

Ogni nuova funzione deve nascere osservando un problema reale della vita quotidiana.

Mai partire dalla tecnologia.

Sempre partire dalla realtà.

Il progetto continua a seguire il principio:

"La vita reale decide.

Il software si adatta."

━━━━━━━━━━━━━━━━━━

# ARCHITETTURA EVOLUTIVA

━━━━━━━━━━━━━━━━━━

Durante H5 è stata consolidata definitivamente una nuova struttura.

Store

↓

Engine

↓

Builder

↓

ViewModel

↓

Widget

Ogni livello ha una responsabilità precisa.

Store

→ conserva i dati.

Engine

→ interpreta il dominio.

Builder

→ prepara i dati.

ViewModel

→ espone dati pronti per la UI.

Widget

→ visualizza.

La UI non deve più contenere logica di business.

━━━━━━━━━━━━━━━━━━

# PRINCIPIO DI SVILUPPO

━━━━━━━━━━━━━━━━━━

Le regole consolidate diventano:

✔ piccoli passi

✔ una responsabilità alla volta

✔ commit frequenti

✔ sempre verde prima del commit

✔ comportamento invariato durante il refactoring

✔ evitare mega-refactor

✔ nessun file creato senza una destinazione architetturale chiara

✔ fermarsi quando emerge un dubbio progettuale

Il codice deve diventare progressivamente più semplice senza perdere stabilità.

━━━━━━━━━━━━━━━━━━

# EVOLUZIONE DEL PROGETTO

━━━━━━━━━━━━━━━━━━

Il progetto ha attraversato le seguenti trasformazioni.

Planner Turni

↓

Calendario Reale

↓

Coverage Engine

↓

Presence Engine

↓

Home Operativa

↓

Motore Economico

↓

Observation Engine

↓

Planner Decision Engine

↓

Architettura a responsabilità separate

La milestone H5 rappresenta il primo refactoring architetturale sistematico dell'intero progetto.

Non introduce nuove funzioni.

Introduce un nuovo modo di costruire FrodoDesk.

━━━━━━━━━━━━━━━━━━

# MEMORIA DELLA MILESTONE H5

━━━━━━━━━━━━━━━━━━

H5 nasce con un obiettivo preciso.

Ridurre la complessità del Calendario senza modificarne il comportamento.

Durante H5 vengono introdotti per la prima volta:

✔ Widget specializzati

✔ ViewModel

✔ Builder

✔ separazione stabile delle responsabilità

✔ schermate sempre più orientate al ruolo di orchestratore.

Il principio più importante emerso durante questa fase è:

"La schermata coordina.

Non pensa."

Questo rappresenta uno dei cambiamenti architetturali più importanti dalla nascita del progetto.

━━━━━━━━━━━━━━━━━━

# ORIGINE DEL METODO CNC

━━━━━━━━━━━━━━━━━━

Il Metodo CNC nasce da un'intuizione originaria del progetto ispirata all'esperienza reale con la programmazione delle macchine a controllo numerico.

Nel modello CNC, il programma principale non riscrive ogni lavorazione nel proprio flusso.

Coordina invece sottoprogrammi specializzati, richiamati quando servono.

Esempio concettuale:

programma principale
↓
richiama lavorazione specializzata
↓
centratura
↓
foratura
↓
filettatura

Lo stesso principio diventa parte permanente dell'identità architetturale di FrodoDesk:

- la Screen o il componente principale orchestra;
- le responsabilità autonome appartengono a moduli specializzati;
- una logica già esistente viene richiamata e non duplicata;
- i moduli devono avere confini chiari e responsabilità riconoscibili;
- non si frammenta il codice senza motivo;
- l'evoluzione avviene attraverso micro-step verificabili.

La memoria storica importante è che il Metodo CNC non ha mai significato soltanto "un passo alla volta".

Il micro-step rappresenta il metodo operativo.

Il modello programma principale + sottoprogrammi rappresenta invece il suo principio architetturale.

Durante H5 e soprattutto H6, FrodoDesk ha progressivamente trasformato questa intuizione originaria in architettura concreta attraverso Store, Engine, Builder, ViewModel, Widget e Screen orchestratrici.

La definizione tecnica ufficiale del Metodo CNC appartiene a `FRODODESK_ARCHITECTURE.md`.

Le regole operative appartengono a `FRODODESK_RULES.md`.

Questa sezione conserva invece l'origine, il significato e la memoria storica del principio.

━━━━━━━━━━━━━━━━━━

# MEMORIA ARCHITETTURALE

━━━━━━━━━━━━━━━━━━

Durante H5 il progetto raggiunge una nuova maturità.

Per la prima volta viene separato chiaramente il concetto di:

• struttura del sistema

da

• funzionalità del sistema.

Questa distinzione diventa permanente.

Il progetto non crescerà più aggiungendo codice alle schermate.

Crescerà costruendo livelli sempre più indipendenti.

━━━━━━━━━━━━━━━━━━

# RESPONSABILITÀ DEI LIVELLI

━━━━━━━━━━━━━━━━━━

Store

Responsabilità:

✔ conservare i dati

✔ notificare modifiche

✔ rappresentare la sorgente unica della verità

Non deve:

❌ interpretare i dati

❌ costruire UI

❌ prendere decisioni

---

Engine

Responsabilità:

✔ interpretare la realtà

✔ applicare le regole

✔ prendere decisioni sul dominio

✔ rispondere a domande reali

Non deve:

❌ conoscere widget

❌ conoscere schermate

❌ costruire elementi grafici

---

Builder

Responsabilità:

✔ trasformare risultati complessi

✔ preparare dati

✔ semplificare la UI

✔ creare Snapshot

✔ creare ViewModel

Non deve:

❌ contenere logica di business principale

---

ViewModel

Responsabilità:

✔ rappresentare esattamente ciò che la UI deve mostrare

✔ eliminare logica dai widget

✔ migliorare leggibilità

Non deve:

❌ accedere agli Store

❌ prendere decisioni

---

Widget

Responsabilità:

✔ mostrare informazioni

✔ gestire input utente

✔ inoltrare callback

Non deve:

❌ interpretare dati

❌ conoscere il dominio

❌ contenere logiche decisionali

━━━━━━━━━━━━━━━━━━

# LEZIONI APPRESE DURANTE H5

━━━━━━━━━━━━━━━━━━

H5 ha insegnato alcune regole che diventano parte del DNA del progetto.

Lezione 1

Mai fare refactoring "alla cieca".

Prima comprendere.

Poi modificare.

---

Lezione 2

Una estrazione è corretta solo se riduce davvero una responsabilità.

Non basta spostare codice.

---

Lezione 3

I ViewModel devono nascere prima dei widget.

Mai il contrario.

---

Lezione 4

I Builder devono preparare dati.

Non devono diventare nuovi Engine.

---

Lezione 5

Ogni commit deve rappresentare un punto stabile.

Mai lasciare il progetto in uno stato intermedio.

---

Lezione 6

La semplicità è un risultato.

Non un punto di partenza.

━━━━━━━━━━━━━━━━━━

# EVOLUZIONE DEL CALENDARIO

━━━━━━━━━━━━━━━━━━

Il Calendario rappresenta il primo modulo completamente rifattorizzato secondo la nuova filosofia.

L'evoluzione è stata:

Calendario monolitico

↓

Widget dedicati

↓

ViewModel

↓

Builder

↓

Schermata orchestratrice

Il comportamento dell'applicazione è rimasto invariato.

È cambiata solamente l'organizzazione del codice.

Questo risultato rappresenta il modello da seguire per le future milestone.

━━━━━━━━━━━━━━━━━━

# H5 — RISULTATO STRATEGICO

━━━━━━━━━━━━━━━━━━

Il valore principale di H5 non consiste nel numero di file creati.

Consiste nell'aver individuato il metodo corretto per evolvere FrodoDesk senza rompere il comportamento esistente.

Da questo momento il progetto dispone di una metodologia di refactoring consolidata.

Questo rappresenta uno dei patrimoni più importanti dell'intero progetto.

━━━━━━━━━━━━━━━━━━

# H6 — MEMORIA DI PROGETTAZIONE

━━━━━━━━━━━━━━━━━━

Con la conclusione di H5 viene presa una decisione importante.

H6 NON rappresenta la continuazione del refactoring della UI.

H6 rappresenta l'inizio del refactoring della business logic.

Questa distinzione diventa ufficiale.

H5

↓

ridurre la complessità delle schermate

H6

↓

ridurre la complessità dei motori.

━━━━━━━━━━━━━━━━━━

# DECISIONE STRATEGICA

━━━━━━━━━━━━━━━━━━

Durante H5 è emersa una lezione fondamentale.

Molti grandi metodi presenti nel progetto non devono essere spezzati semplicemente in altri metodi.

Devono essere trasformati in motori autonomi.

Il refactoring corretto non consiste nello spostare righe.

Consiste nello spostare responsabilità.

━━━━━━━━━━━━━━━━━━

# DIREZIONE H6

━━━━━━━━━━━━━━━━━━

La milestone H6 seguirà un ordine preciso.

Non verranno scelti i lavori "più facili".

Verranno scelti quelli che riducono maggiormente la complessità del progetto.

L'ordine ufficiale diventa:

1.

FamilyNow

↓

riduzione della logica del metodo
_buildFamilyNowSnapshot()

---

2.

Coverage Engine

↓

eliminazione delle ultime duplicazioni

---

3.

Presence Engine

↓

pulizia definitiva

---

4.

Business Builder

↓

centralizzazione della preparazione dati

---

5.

Snapshot Builder

↓

riduzione ulteriore delle responsabilità delle schermate

━━━━━━━━━━━━━━━━━━

# REGOLE H6

━━━━━━━━━━━━━━━━━━

Durante H6 dovranno essere rispettate nuove regole.

✔ nessun Builder viene creato senza sapere esattamente quale responsabilità avrà;

✔ nessun file resta "mezzo iniziato";

✔ una responsabilità viene completata prima di iniziarne un'altra;

✔ ogni estrazione termina con compilazione verde;

✔ ogni estrazione termina con commit Git;

✔ nessuna modifica contemporanea a più moduli.

━━━━━━━━━━━━━━━━━━

# ERRORI DA NON RIPETERE

━━━━━━━━━━━━━━━━━━

H5 ha evidenziato alcuni errori metodologici.

Essi diventano memoria permanente del progetto.

Errore:

creare componenti prima di aver definito l'architettura.

Correzione:

prima progettare,
poi creare.

---

Errore:

iniziare un Builder senza sapere dove terminerà.

Correzione:

ogni Builder nasce solo quando la sua collocazione è definitiva.

---

Errore:

cambiare strategia durante una milestone.

Correzione:

la roadmap di una milestone viene fissata prima di iniziare.

Eventuali modifiche vengono fatte solo all'inizio della milestone successiva.

---

Errore:

spostare codice solamente per ridurre il numero di righe.

Correzione:

ogni estrazione deve diminuire realmente la responsabilità della schermata o del motore.

━━━━━━━━━━━━━━━━━━

# NUOVA FILOSOFIA DI LAVORO

━━━━━━━━━━━━━━━━━━

Il progetto non verrà più guidato dal numero di file.

Sarà guidato dal numero di responsabilità.

L'obiettivo non è avere tanti file.

L'obiettivo è avere componenti semplici,
leggibili,
indipendenti
e facilmente verificabili.

La semplicità diventa una caratteristica strutturale del progetto,
non un obiettivo estetico.

━━━━━━━━━━━━━━━━━━

# DNA DI SVILUPPO UFFICIALE

━━━━━━━━━━━━━━━━━━

Durante H5 il progetto ha raggiunto una maturità che modifica definitivamente il modo di sviluppare FrodoDesk.

Non esiste più la distinzione tra:

"scrivere codice"

e

"fare architettura".

Ogni modifica deve rispettare contemporaneamente:

✔ correttezza funzionale

✔ semplicità

✔ responsabilità unica

✔ leggibilità

✔ possibilità di evoluzione futura

Il codice non deve semplicemente funzionare.

Deve raccontare chiaramente cosa sta facendo.

━━━━━━━━━━━━━━━━━━

# PRINCIPI PERMANENTI

━━━━━━━━━━━━━━━━━━

Prima comprendere.

Poi progettare.

Poi modificare.

Mai il contrario.

---

Ogni responsabilità deve avere una casa precisa.

Se non è chiaro dove appartenga una logica,
non va ancora estratta.

---

Ogni nuova classe deve poter essere descritta con una frase.

Se servono più frasi,
probabilmente contiene più responsabilità.

---

Ogni schermata deve tendere a diventare un orchestratore.

Le schermate coordinano.

I motori decidono.

I Builder preparano.

I ViewModel descrivono.

I Widget mostrano.

━━━━━━━━━━━━━━━━━━

# DEFINIZIONE DI "COMPLETATO"

━━━━━━━━━━━━━━━━━━

Una milestone viene considerata conclusa solo quando sono vere tutte queste condizioni.

✔ comportamento invariato

✔ compilazione pulita

✔ nessuna regressione

✔ commit Git eseguito

✔ codice più semplice rispetto all'inizio

✔ responsabilità ridotte

✔ documentazione aggiornata

Se manca uno solo di questi punti,
la milestone non è conclusa.

━━━━━━━━━━━━━━━━━━

# MEMORIA DEL METODO DI LAVORO

━━━━━━━━━━━━━━━━━━

Il metodo che ha prodotto i risultati migliori durante H5 diventa il metodo ufficiale del progetto.

Sequenza operativa:

1.

Analizzare.

2.

Progettare.

3.

Effettuare una modifica molto piccola.

4.

Compilare.

5.

Verificare il comportamento.

6.

Commit Git.

7.

Solo dopo iniziare il passo successivo.

Mai eseguire due refactoring importanti contemporaneamente.

Mai lasciare lavoro incompleto.

Mai interrompere una responsabilità a metà.

━━━━━━━━━━━━━━━━━━

# STATO DEL PROGETTO

━━━━━━━━━━━━━━━━━━

FrodoDesk è oggi un ecosistema composto da moduli indipendenti.

Le fondamenta architetturali possono essere considerate stabili.

Le evoluzioni future non dovranno aggiungere complessità.

Dovranno ridurla.

L'obiettivo non è aumentare il numero delle funzionalità.

L'obiettivo è aumentare la qualità del sistema.

━━━━━━━━━━━━━━━━━━

# VISIONE FUTURA

━━━━━━━━━━━━━━━━━━

Il progetto continuerà a svilupparsi seguendo questo ordine.

1.

Consolidare.

2.

Semplificare.

3.

Generalizzare.

4.

Aprire il sistema a qualunque famiglia.

La famiglia Matteo-Chiara-Alice rimane il laboratorio reale.

Ma ogni nuova scelta dovrà essere compatibile con il futuro modello multi-famiglia.

━━━━━━━━━━━━━━━━━━

# FRASE UFFICIALE DI RIPARTENZA

Ripartiamo da FrodoDesk.

H5 è conclusa.

L'architettura del Calendario è stata profondamente migliorata mantenendo il comportamento invariato.

La milestone successiva sarà H6.

H6 non introdurrà nuove funzionalità.

Il suo obiettivo sarà trasferire progressivamente la business logic dai grandi metodi ai motori dedicati, seguendo rigorosamente il metodo consolidato durante H5:

piccoli passi,
una responsabilità alla volta,
sempre verde,
sempre verificato,
sempre documentato.

━━━━━━━━━━━━━━━━━━

FINE DOCUMENTO