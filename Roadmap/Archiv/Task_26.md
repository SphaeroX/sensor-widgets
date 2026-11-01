# Task_26: Multi-Value: Formel pro Zeile (Dart, Android, iOS)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_26.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Jede Zeile eines Multi-Value-Widgets kann optional eine eigene Formel samt Variablen (und Zwischenschritten) haben. Zeilen ohne Formel verhalten sich wie bisher.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_25 abgeschlossen.
- **Relevantes Vorwissen:** `SensorQueryItem` (`lib/domain/models/sensor_query_item.dart`) hat heute Measurement, Field, Tags, Label, Unit. Der Kontrakt wird um optionale `formula`, `formulaVariables`, `formulaSteps` je Item erweitert; Native Parser in Kotlin/Swift ebenfalls. Kontrakt-Änderungen sind rein additiv (neue optionale Felder); `schemaVersion` bleibt 1 und alte Fixtures parsen unverändert.

## Umfang

**Gehört dazu:**

- Kontrakt, Dart-Modell, Kotlin- und Swift-Parser, Fixtures.
- Abfrage- und Berechnungs-Pipeline je Zeile (Einzelwert, aktuellster Bucket).
- Fehler nur in der betroffenen Zeile anzeigen, übrige Zeilen bleiben sichtbar.
- Vorschau im Editor zeigt Zeilenergebnisse.

**Gehört nicht dazu:**

- Editor-UI für die Zeilen-Formel (Task_27).

## Umsetzungsschritte

1. Datei in `RUN_Task_26.md` umbenennen.
2. Fixtures für Multi-Value mit Zeilenformeln anlegen.
3. Dart: Modell, Pipeline per TDD.
4. Kotlin und Swift: Parser und Berechnung per TDD.
5. Fehlerisolierung pro Zeile testen.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/domain/models/sensor_query_item_test.dart`, `test/domain/services/...`.
- Android JUnit für Parser/Worker, Swift-Tests (CI).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] Multi-Value-Zeile mit Formel zeigt das berechnete Ergebnis, andere Zeilen unverändert (Tests).
- [x] Fehler in einer Zeile blockiert die anderen nicht.
- [x] Alte Multi-Value-JSONs werden unverändert gelesen.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Soll eine Zeile Variablen anderer Zeilen referenzieren dürfen? Annahme: nein, jede Zeile ist eigenständig.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Kontrakt `SensorQueryItem.formula/formulaVariables/formulaSteps` in Dart, Kotlin, Swift; Dart-Service `calculateItemFormula`, Controller-Vorschau mit Zeilenfehlern (`multiErrors`) und Fehler-Chips in `WidgetLivePreviewCard`; Kotlin `FormulaSeriesCalculator.calculateItemLatest`, Worker/Mapper (`valueErrors`); Swift `calculateItemLatest`/`evaluateItem`, Provider und `MultiValueWidgetView`. Kotlin-Parser auf Helfer (`parseItem`, `parseFormulaVariables`, `parseFormulaSteps`) refaktoriert.
- **Learnings & Stolpersteine:** Zeilen mit Formel brauchen weiterhin ein eindeutiges `field` (Zeilen-ID). Eine Zeile mit Formel erzeugt eine eigene Abfrage je Variablengruppe; Zeilen sind bewusst unabhaengig (keine Variablen anderer Zeilen).
- **Wichtige Entscheidungen und ihre Gründe:** Nur der aktuellste Wert je Variable (kein Zeit-Bucket), wie in der Aufgabe gefordert.
- **Auswirkungen auf Folge-Tasks:** Task_27 muss im Editor fuer jede Multi-Value-Zeile `formula`, `formulaVariables`, `formulaSteps` bearbeitbar machen und beim Speichern `field` als Zeilen-ID eindeutig setzen.
- **Hinweise zu Tests und Befehlen:** `flutter test test/domain/models/sensor_query_item_formula_test.dart test/presentation/controllers/widgets_controller_multi_formula_test.dart`; Android `WidgetRefreshWorkerMultiFormulaTest`; iOS `FormulaMultiRowTests` (CI).
