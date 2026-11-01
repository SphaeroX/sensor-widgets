# Task_22: Formel-Kontrakt v2 & Dart-Evaluator (Funktionen, Bedingungen, Zwischenformeln)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_22.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Der Formel-Evaluator versteht neben `+ - * / ( )` auch Funktionen (`min` und `max` mit beliebig vielen Argumenten ab 1, z. B. `min(a, b, c, d)` für den IAQ, `clamp`, `abs`, `pow`, `sqrt`, `ln`, `log10`, `exp`, `round`, `floor`, `ceil`), Vergleichsoperatoren (`<`, `>`, `<=`, `>=`, `==`, `!=`), `if(bedingung, a, b)`, die Konstanten `pi` und `e` sowie benannte Zwischenformeln (Schritte), die auf frühere Schritte und Variablen verweisen. Damit lässt sich z. B. ein IAQ in mehreren Schritten rechnen.

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

- [x] Alle Funktionen, Vergleiche, `if`, Konstanten und Schritte werden korrekt ausgewertet (Fixture-Test grün).
- [x] Fehlerfälle liefern explizite, unterscheidbare Fehler statt 0.0.
- [x] Alte Widget-JSONs ohne `formulaSteps` und alte Formeln verhalten sich unverändert.
- [x] Fixtures enthalten alle Fälle für die Kotlin-/Swift-Umsetzung.
- [x] `docs/architecture.md` beschreibt den Kontrakt v2.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Genaue Syntax der Schritte (z. B. `voc = ...` als Text pro Zeile oder strukturierte Liste im JSON) – Annahme: strukturierte Liste im JSON, im Editor als Zeilen dargestellt.
- Rundungsregeln und Dezimaltrenner (Annahme: Punkt in der Formel, Anzeige formatiert über `decimalPlaces`).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Evaluator als Recursive-Descent-Parser mit AST neu geschrieben (statt Shunting-Yard), Public API unverändert, `steps:` ergänzt. Neu: `lib/domain/models/formula_step.dart`, `WidgetDefinition.formulaSteps`, Fehlercodes in `formula_exception.dart`, `FormulaEvaluator.validateSteps`, Positionsangabe in `validateSyntax`. `FormulaCalculationService` reicht `formulaSteps` an den Evaluator durch. Fixtures: neue Abschnitte `v2_valid_cases` und `v2_error_cases` (v1-Abschnitte unverändert, damit bestehende Kotlin/Swift-Tests weiterlaufen).
- **Learnings & Stolpersteine:** `if` ist lazy (Guard `if(B == 0, -1, A / B)`). `round` rundet weg von null (Kotlin `Math.round` und Swift `.rounded()` verhalten sich bei negativen .5 unterschiedlich, explizit nachbauen). `log10` als `ln(x)/ln10` (Fixture-Toleranz 1e-9). Variablen/Steps haben Vorrang vor `pi`/`e`. Unäres `+` ist bewusst nicht erlaubt (`A ++ B` bleibt Syntaxfehler).
- **Wichtige Entscheidungen und ihre Gründe:** Vergleiche liefern 1.0/0.0, damit alles `double` bleibt. Nicht-endliche Ergebnisse sind `domain_error`, nie stilles NaN/0.0.
- **Auswirkungen auf Folge-Tasks:** Task_23 muss beide Fixture-Abschnitte plus Step-Semantik (Reihenfolge, Duplikat/Vorwärtsreferenz = `step_reference_error`) in Kotlin und Swift nachbauen. Task_27 kann `validateSteps` und die Positionsangabe im Editor nutzen.
- **Hinweise zu Tests und Befehlen:** `flutter test test/domain` (neu: `formula_evaluator_v2_test.dart`, `formula_step_test.dart`, `widget_definition_steps_test.dart`, `formula_calculation_service_steps_test.dart`). Beim parallelen Lauf trat einmal ein sporadischer "loading"-Fehler auf, der beim Einzellauf nicht reproduzierbar war.
