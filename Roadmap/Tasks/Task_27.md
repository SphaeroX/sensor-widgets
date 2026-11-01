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

- [ ] IAQ-Szenario lässt sich ohne Tippen von Feldnamen zusammenklicken (Widget-Test).
- [ ] Freitext-Fallback je Variable funktioniert.
- [ ] Formel-Editor erscheint bei allen Typen und Multi-Value-Zeilen.
- [ ] Bestehende Editor-Tests unverändert grün.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Mehrere Variablen aus unterschiedlichen Measurements: Schema-Abfragen je Measurement könnten viele Requests erzeugen; Lazy-Loading beim Öffnen des Pickers (Annahme).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):**
- **Learnings & Stolpersteine:**
- **Wichtige Entscheidungen und ihre Gründe:**
- **Auswirkungen auf Folge-Tasks:**
- **Hinweise zu Tests und Befehlen:**
