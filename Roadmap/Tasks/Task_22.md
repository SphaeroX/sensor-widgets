# Task_22: Formel-Kontrakt v2 & Dart-Evaluator (Funktionen, Bedingungen, Zwischenformeln)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_22.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Der Formel-Evaluator versteht neben `+ - * / ( )` auch Funktionen (`min`, `max`, `clamp`, `abs`, `pow`, `sqrt`, `ln`, `log10`, `exp`, `round`, `floor`, `ceil`), Vergleichsoperatoren (`<`, `>`, `<=`, `>=`, `==`, `!=`), `if(bedingung, a, b)`, die Konstanten `pi` und `e` sowie benannte Zwischenformeln (Schritte), die auf frühere Schritte und Variablen verweisen. Damit lässt sich z. B. ein IAQ in mehreren Schritten rechnen.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_21 abgeschlossen (nicht technisch zwingend, aber Reihenfolge einhalten).
- **Relevantes Vorwissen:** Bestand: `lib/domain/formula/formula_evaluator.dart`, `lib/domain/models/formula_variable.dart`, `lib/domain/services/formula_calculation_service.dart`, Fixtures `fixtures/formula/evaluator_cases.json`. Kontrakt-Regel aus `AGENTS.md`: Dart, Kotlin, Swift und Fixtures im selben Change. Dieser Task liefert Kontrakt, Fixtures und die Dart-Seite; Kotlin/Swift folgen in Task_23 (Fixtures müssen dafür bereits alle neuen Fälle enthalten). Fehler niemals still auf 0.0 abfangen.

## Umfang

**Gehört dazu:**

- Neues optionales Feld `formulaSteps` (`List<FormulaStep>`: `name`, `expression`, optional `label`) in `WidgetDefinition`; die letzte Zeile bzw. `formula` liefert das Ergebnis. Kontrakt-Änderungen sind rein additiv (neue optionale Felder); `schemaVersion` bleibt 1 und alte Fixtures parsen unverändert.
- Tokenizer/Parser/Evaluator um Funktionen, Vergleiche, `if`, Konstanten und Schritt-Referenzen erweitern, inklusive klarer Fehler (unbekannte Funktion, falsche Argumentzahl, Zyklus/Vorwärtsreferenz, Domain-Fehler wie `ln(0)` oder `sqrt(-1)`, Division durch 0).
- Fixtures `fixtures/formula/evaluator_cases.json` um alle neuen Fälle (inkl. Fehlerfälle mit erwartetem Fehlercode) erweitern.
- Validierung in `WidgetDefinition.isValid` und Syntax-Check für den Editor (Fehlerposition und Meldung).

**Gehört nicht dazu:**

- Kotlin- und Swift-Implementierung (Task_23).
- Editor-UI (Task_27).
- Zeitreihen-Berechnung (Task_24).

## Umsetzungsschritte

1. Datei in `RUN_Task_22.md` umbenennen.
2. `docs/architecture.md` und Fixtures lesen.
3. Fixtures zuerst erweitern, Dart-Test, der sie lädt, schlägt fehl (Red).
4. Tokenizer, Parser und Evaluator schrittweise erweitern (Green), je Funktionsgruppe ein Zyklus.
5. `FormulaStep`-Modell, JSON-(De)Serialisierung und Validierung per TDD.
6. Fehlertypen vereinheitlichen und in `docs/architecture.md` den Formel-Kontrakt v2 dokumentieren.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/domain/formula/formula_evaluator_test.dart` (neue Fälle, bestehende unverändert).
- `test/domain/models/widget_definition_test.dart` (Roundtrip `formulaSteps`, Abwärtskompatibilität).
- Fixture-getriebener Test über `fixtures/formula/evaluator_cases.json`.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Alle Funktionen, Vergleiche, `if`, Konstanten und Schritte werden korrekt ausgewertet (Fixture-Test grün).
- [ ] Fehlerfälle liefern explizite, unterscheidbare Fehler statt 0.0.
- [ ] Alte Widget-JSONs ohne `formulaSteps` und alte Formeln verhalten sich unverändert.
- [ ] Fixtures enthalten alle Fälle für die Kotlin-/Swift-Umsetzung.
- [ ] `docs/architecture.md` beschreibt den Kontrakt v2.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Genaue Syntax der Schritte (z. B. `voc = ...` als Text pro Zeile oder strukturierte Liste im JSON) – Annahme: strukturierte Liste im JSON, im Editor als Zeilen dargestellt.
- Rundungsregeln und Dezimaltrenner (Annahme: Punkt in der Formel, Anzeige formatiert über `decimalPlaces`).

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
