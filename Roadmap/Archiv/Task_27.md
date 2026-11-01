# Task_27: Editor: Variablen per Picker auswählen, Formel für alle Typen, Zwischenformeln

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_27.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Im Widget-Editor muss kein Feldname mehr getippt werden. Jede Formelvariable wählt Measurement, Field und Tags per `SearchableSchemaPicker` aus den geladenen DB-Metadaten (Freitext bleibt als Fallback). Der Formel-Editor steht bei allen Widget-Typen und Multi-Value-Zeilen zur Verfügung, inklusive Zwischenformeln, Namens-/Funktionsvorschlägen und Syntax-Check mit Fehlerposition.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_24 abgeschlossen (Task_26 sollte für die Zeilen-Formel fertig sein).
- **Relevantes Vorwissen:** `lib/presentation/widgets/editor/formula_editor_section.dart`, `searchable_schema_picker.dart`, `tag_filter_editor.dart`, `lib/presentation/controllers/schema_discovery_controller.dart`, `lib/presentation/screens/editor/widget_editor_screen.dart`. Bestehende Editor-Tests dürfen nur mit Freigabe geändert werden; Selektoren und Fallbacks abwärtskompatibel halten.

## Umfang

**Gehört dazu:**

- Variablen-Karte: Name (A, B, ... oder frei), Measurement-Picker, Field-Picker, Tag-Filter-Chips, Label, mit Schema aus der Verbindung.
- Schema-Laden je Measurement der Variable (Cache), Lade-/Fehlerzustände wie in Meilenstein 2.
- Zwischenformeln als Zeilenliste (Name, Ausdruck), Ergebniszeile markiert.
- Eingabehilfe: Chips zum Einfügen von Variablen-, Schritt- und Funktionsnamen an der Cursorposition.
- Formel-Abschnitt für alle sechs Typen und je Multi-Value-Zeile.
- Live-Syntax-Check und Vorschau-Ergebnis.

**Gehört nicht dazu:**

- Hilfe-Seite (Task_28).
- Visuelles Redesign (Task_31).

## Umsetzungsschritte

1. Datei in `RUN_Task_27.md` umbenennen.
2. Bestehende Editor-Tests und Controller lesen.
3. Widget-Tests für die Variablen-Karte (Picker statt Textfeld) schreiben, dann bauen.
4. Zwischenformel-UI und Einfüge-Chips per TDD.
5. Formel-Abschnitt in den Editor aller Typen und Zeilen integrieren.
6. Regressionslauf aller Editor-Tests.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/presentation/widgets/editor/formula_editor_section_test.dart` (erweitern).
- `test/presentation/screens/editor/widget_editor_screen_test.dart` (nur ergänzen).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] IAQ-Szenario lässt sich ohne Tippen von Feldnamen zusammenklicken (Widget-Test).
- [x] Freitext-Fallback je Variable funktioniert.
- [x] Formel-Editor erscheint bei allen Typen und Multi-Value-Zeilen.
- [x] Bestehende Editor-Tests unverändert grün.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Mehrere Variablen aus unterschiedlichen Measurements: Schema-Abfragen je Measurement könnten viele Requests erzeugen; Lazy-Loading beim Öffnen des Pickers (Annahme).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Neue Variablen-Dialog-Logik mit Pickern (Measurement, Field, Tag-Key/Value, Label), Zwischenschritt-Liste, Einfuege-Chips (horizontal scrollbar, um den bestehenden Tests keine Hoehe zu nehmen), Positionsangabe im Syntaxfehler, `getFieldInfos` im `SchemaDiscoveryController`, Formel-Zeilen-Karte fuer Multi-Value im `WidgetEditorScreen`. Abweichung: Schema wird per injizierbaren Loadern je Variable geladen (nicht ueber `EditorSchemaController`), ohne Cache; veraltete Antworten werden per Request-Zaehler verworfen.
- **Learnings & Stolpersteine:** `SearchableSchemaPicker` ist ein `TextFormField` mit Sheet: Freitext funktioniert immer, daher blieben die alten Keys (`variable_field_input` etc.) und Tests unveraendert. Beim Tippen in Picker wird bei jedem Zeichen `onSelected` (und damit der Loader) aufgerufen; bei sehr langsamen Servern kann das viele Requests erzeugen (bei Bedarf Debounce nachruesten). `InputChip`-Loeschicon explizit gesetzt (`Icons.cancel`).
- **Wichtige Entscheidungen und ihre Gründe:** Formel-Zeilen bekommen `field = formula_<n>` als eindeutige ID; Zeilen-Validierung beim Speichern (Snackbar) statt Blockade im Formular.
- **Auswirkungen auf Folge-Tasks:** Task_28 kann Vorlagen als `(formula, variables, steps)`-Tripel anbieten und ueber `onFormulaChanged/onVariablesChanged/onStepsChanged` bzw. `_formulaRows` einspielen. Task_31 (Redesign) beachtet die Keys der neuen Widgets.
- **Hinweise zu Tests und Befehlen:** `flutter test test/presentation/widgets/editor test/presentation/screens/editor`.
