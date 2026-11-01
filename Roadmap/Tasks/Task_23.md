# Task_23: Evaluator-Parität in Kotlin und Swift

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_23.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Der erweiterte Formel-Evaluator aus Task_22 liefert in Kotlin (Android) und Swift (iOS) exakt dieselben Ergebnisse und Fehler wie in Dart, geprüft über dieselben Fixtures.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_22 abgeschlossen (Kontrakt v2, Fixtures).
- **Relevantes Vorwissen:** Bestehende native Evaluatoren aus Task_16 unter `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/` und `ios/SensorWidgetsExtension/`. Das Parsen von `formulaSteps` im nativen `WidgetDefinitionParser` bzw. in `WidgetModels.swift` gehört hierher. iOS-Code ist nur durch einen grünen GitHub-Actions-Lauf verifiziert; lokal wird nichts über iOS behauptet.

## Umfang

**Gehört dazu:**

- Kotlin: Evaluator und `WidgetDefinitionParser` um Funktionen, Vergleiche, `if`, Konstanten, Schritte und Fehler erweitern.
- Swift: dasselbe in der Widget-Extension.
- Beide Seiten laden `fixtures/formula/evaluator_cases.json` und `fixtures/` für Widget-Definitionen mit `formulaSteps`.
- Sicherstellen, dass numerische Ergebnisse (Rundung, Gleitkomma) übereinstimmen, notfalls mit definierter Toleranz in den Fixtures.

**Gehört nicht dazu:**

- Datenabfrage und Zeit-Buckets (Task_25).
- UI-Änderungen.

## Umsetzungsschritte

1. Datei in `RUN_Task_23.md` umbenennen.
2. Kotlin: Fixture-Test schreiben (Red), Evaluator erweitern (Green).
3. Swift: analog (Tests laufen nur in CI; Code defensiv und gegen Fixtures schreiben).
4. Parser für `formulaSteps` je Plattform per Test.
5. `docs/architecture.md` und `docs/testing.md` aktualisieren, falls neue Testbefehle nötig sind.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `android/app/src/test/kotlin/.../formula/FormulaEvaluatorTest.kt` (Fixture-getrieben) und `WidgetDefinitionParserTest.kt`.
- `ios/SensorWidgetsExtensionTests/` (XCTest/Swift Testing, nur CI).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `cd android && ./gradlew test` ist grün und enthält alle Fixture-Fälle.
- [ ] Swift-Tests sind geschrieben; Verifikation steht aus, bis die CI-Ausführung vorliegt (Ergebnis im Task festhalten).
- [ ] Alte Widget-JSONs werden unverändert geparst.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Gleitkomma-Abweichungen zwischen Dart, Kotlin und Swift bei `pow`, `ln`, `exp`: Toleranz in den Fixtures festlegen (Annahme: 1e-9 relativ).

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
