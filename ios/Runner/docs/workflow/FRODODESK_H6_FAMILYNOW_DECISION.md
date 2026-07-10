# FRODODESK — H6 FamilyNow Decision

Versione: Luglio 2026  
Stato: Decisione architetturale consolidata

---

# OBIETTIVO

Completare il refactoring di FamilyNow alleggerendo realmente `calendario_screen_stepa.dart` e impedendo alla UI di interpretare lo stato dei membri della famiglia.

La decisione finale rimane sempre umana.

---

# DECISIONE ARCHITETTURALE

Non verranno creati tre Builder separati per Matteo, Chiara e Alice.

`MatteoNowBuilder` è considerato superato perché troppo specifico e perché non svolge una vera responsabilità di Builder.

La struttura ufficiale sarà:

```text
FamilyNowSnapshot
        ↓
FamilyNowViewModelBuilder
        ↓
FamilyNowViewModel
        ├── matteo: FamilyMemberNowViewModel
        ├── chiara: FamilyMemberNowViewModel
        └── alice: FamilyMemberNowViewModel
        ↓
FamilyNowCard
```

---

# RESPONSABILITÀ

## FamilyNowSnapshot

Contenitore tecnico prodotto dalla logica.

Contiene dati già calcolati:

- stato attuale;
- label;
- busy / fuori;
- turno;
- visual;
- copertura;
- emergenza;
- IPS.

Non contiene Widget.

Non contiene logica grafica.

---

## FamilyMemberNowViewModel

Rappresenta un singolo membro nella UI.

Campi definitivi:

```dart
final String name;
final String label;
final StatusVisual visual;
final bool busy;
final bool isAlice;
final String? turnLabel;
```

Per Matteo e Chiara:

```dart
isAlice: false
turnLabel: valorizzato
```

Per Alice:

```dart
isAlice: true
turnLabel: null
```

Gli eventi `past / current / future` non entrano ancora in questo modello.

Quella responsabilità sarà progettata separatamente per i dialog di dettaglio.

---

## FamilyNowViewModel

Diventa:

```dart
final FamilyMemberNowViewModel matteo;
final FamilyMemberNowViewModel chiara;
final FamilyMemberNowViewModel alice;
final bool emergency;
```

Non avrà più campi duplicati separati per label e visual.

---

## FamilyNowViewModelBuilder

È l'unico componente che trasforma:

```text
FamilyNowSnapshot
```

in:

```text
FamilyNowViewModel
```

Costruisce i tre `FamilyMemberNowViewModel`.

Non verrà creato un `FamilyMemberNowBuilder` separato.

---

## FamilyNowCard

Riceve un solo:

```dart
FamilyNowViewModel model
```

e usa direttamente:

```dart
model.matteo.busy
model.matteo.label
model.matteo.visual
```

Non deduce più lo stato da stringhe come:

```dart
startsWith("occupato")
```

La UI visualizza.

Non interpreta.

---

# DECISIONE SU MATTEONOWBUILDER

Il file:

```text
lib/logic/calendar/builders/matteo_now_builder.dart
```

è ufficialmente superato.

Non verrà completato.

Non verrà riutilizzato.

Verrà eliminato insieme al relativo import solo dopo che il nuovo `FamilyNowViewModelBuilder` sarà collegato e il progetto compilerà correttamente.

---

# ORDINE OPERATIVO UFFICIALE

1. Creare `family_member_now_view_model.dart`.
2. Riscrivere `family_now_view_model.dart`.
3. Creare `family_now_view_model_builder.dart`.
4. Aggiornare `family_now_card.dart`.
5. Collegare `FamilyNowCard` dentro il calendario.
6. Verificare UI e compilazione.
7. Eliminare `matteo_now_builder.dart` e il suo import.
8. Commit Git.

---

# METODO DI LAVORO

Ogni passaggio deve seguire:

1. modifica completa del file o blocco;
2. compilazione;
3. `flutter analyze`;
4. verifica nell'app;
5. solo dopo passaggio successivo.

Nessun file lasciato a metà.

Nessun cambio di strategia durante questo blocco H6.