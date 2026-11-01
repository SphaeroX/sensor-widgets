> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_16.md` ➔ `RUN_Task_16.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`), `android/app/src/test/` oder `ios/` abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_16: Shared Kontrakt & Cross-Platform Formel-Evaluator (Dart, Kotlin, Swift)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Schaffung des gemeinsamen Datenmodells und der mathematischen Auswertungslogik für benutzerdefinierte Berechnungsformeln vor der Widget-Anzeige.
- **Erwartetes Ergebnis:**
  - Erweiterung des JSON-Schemas `widget_definitions_v1` in `WidgetDefinition` um optionale Felder `formula` (String) und `formulaVariables` (Liste/Map von Variablen mit ihren Quellen).
  - Implementierung eines deterministischen, schlanken mathematischen Evaluators (AST / Shunting-Yard) in **Dart**, **Kotlin** und **Swift**, der Grundrechenarten (`+`, `-`, `*`, `/`), Klammern `(...)`, Unärminus (`-x`), Gleitkommazahlen und Variablenbuchstaben (`A`-`Z`) unterstützt.
  - Sprachübergreifende Test-Fixtures unter `fixtures/formula/evaluator_cases.json` zur Verifikation in allen drei Plattformen.
  - Präzise Fehlerklassen (`DivisionByZeroException`, `FormulaSyntaxException`, `MissingVariableException`).

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_15` abgeschlossen und im `Roadmap/Archiv/`.
- **Betroffene Komponenten / Dateien:**
  - `fixtures/formula/evaluator_cases.json` *(neu)*
  - `lib/domain/models/formula_variable.dart` *(neu)*
  - `lib/domain/models/widget_definition.dart` *(Erweiterung um formula & formulaVariables)*
  - `lib/domain/formula/formula_evaluator.dart` *(neu)*
  - `lib/domain/formula/formula_exception.dart` *(neu)*
  - `test/domain/models/formula_variable_test.dart` *(neu)*
  - `test/domain/models/widget_definition_test.dart` *(Ergänzungstests)*
  - `test/domain/formula/formula_evaluator_test.dart` *(neu)*
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/formula/FormulaEvaluator.kt` *(neu)*
  - `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/formula/FormulaEvaluatorTest.kt` *(neu)*
  - `ios/Runner/Formula/FormulaEvaluator.swift` *(neu)*
  - `ios/RunnerTests/FormulaEvaluatorTests.swift` *(neu)*

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_16.md` umbenennen.
   - [ ] Erstelle `fixtures/formula/evaluator_cases.json` mit repräsentativen Testfällen:
     - Einfache Addition, Subtraktion, Multiplikation, Division: `A + B`, `A - B`, `A * B`, `A / B`.
     - Punkt-vor-Strich und Klammern: `(A + B + C) / 3`, `A + B * C`, `(A - B) * (C + 2)`.
     - Unäres Minus und Dezimalzahlen: `-A + 1.5`, `A * (-0.5)`.
     - Fehlerfälle: Division durch 0 (`A / 0`), Syntaxfehler (`(A +`), Unbekannte/fehlende Variable (`A + B` mit nur `A` übergeben).
2. **Domain-Modelle per TDD (Dart):**
   - [ ] **Red:** Schreibe Tests in `test/domain/models/formula_variable_test.dart` und `test/domain/models/widget_definition_test.dart`:
     - `FormulaVariable` speichert `name` (z. B. `'A'`), optional `measurement` (falls abweichend), `field` (z. B. `'temp'`), optionale `tagFilters` (`Map<String, String>?`) und optionales `label`.
     - JSON-Serialisierung / Deserialisierung (`toJson`, `fromJson`, `==`, `hashCode`).
     - `WidgetDefinition` akzeptiert optionale `formula` (`String?`) und `formulaVariables` (`List<FormulaVariable>?`), serialisiert/deserialisiert diese und bleibt bei alten JSONs vollständig abwärtskompatibel.
   - [ ] **Green:** Implementiere `lib/domain/models/formula_variable.dart` und erweitere `lib/domain/models/widget_definition.dart`.
3. **Dart FormulaEvaluator per TDD:**
   - [ ] **Red:** Schreibe Tests in `test/domain/formula/formula_evaluator_test.dart` basierend auf `fixtures/formula/evaluator_cases.json`.
   - [ ] **Green:** Implementiere `lib/domain/formula/formula_evaluator.dart` und Fehlerklassen:
     - Tokenizer / Lexer für Zahlen, Operatoren (`+`, `-`, `*`, `/`), Klammern `(`, `)` und Bezeichner (`[A-Za-z_][A-Za-z0-9_]*`).
     - Parser / Evaluator (Shunting-Yard oder rekursiver Abstieg) zur Berechnung mit gegebener Variablen-Map `Map<String, double>`.
     - Saubere Exceptions bei Syntaxfehlern, fehlenden Variablen und Division durch 0.
4. **Android Kotlin FormulaEvaluator per TDD:**
   - [ ] **Red:** Schreibe JUnit-Tests in `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/formula/FormulaEvaluatorTest.kt`, die dieselbe Logik und Fixtures prüfen.
   - [ ] **Green:** Implementiere `FormulaEvaluator.kt` in `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/formula/`.
   - [ ] Testlauf: `cd android && ./gradlew test`.
5. **iOS Swift FormulaEvaluator:**
   - [ ] Implementiere `FormulaEvaluator.swift` und entsprechende XCTests / Swift Testing in `ios/RunnerTests/FormulaEvaluatorTests.swift`.
   - [ ] Verifikation über die bestehende Test-Struktur.
6. **Refactoring & Code Quality:**
   - [ ] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` ausführen.
   - [ ] `cd android && ./gradlew :app:ktlintCheck` ausführen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- [x] Alle Testfälle in `fixtures/formula/evaluator_cases.json` werden in Dart und Kotlin mit identischen Ergebnissen bestanden.
- [x] Division durch 0 und Syntaxfehler werfen dedizierte Exceptions und führen niemals zu unkontrollierten App-Abstürzen.
- [x] Abwärtskompatibilität: Alle bestehenden Tests in `test/` laufen ohne Änderungen erfolgreich durch.
- [x] Linter & Formatter (`flutter analyze`, `dart format`, `ktlintCheck`) sind fehlerfrei.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` und `android/` sind grün.
- [x] Erkenntnisse in Sektion 6 eingetragen.
- [x] `Roadmap/Tasks/Task_17.md` und `Roadmap/README.md` geprüft.
- [x] Datei umbenennen (`RUN_` entfernen) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **Architektur & Evaluator-Implementierung:**
  - `FormulaEvaluator` wurde in Dart (`lib/domain/formula/formula_evaluator.dart`), Kotlin (`FormulaEvaluator.kt`) und Swift (`FormulaEvaluator.swift`) auf Basis eines Shunting-Yard-Algorithmus umgesetzt.
  - Variablen werden anhand von Bezeichnern (`[A-Za-z_][A-Za-z0-9_]*`) extrahiert (`extractVariables`), und Syntax-Validierung (`validateSyntax`) gibt verständliche Fehlermeldungen zurück.
  - Unterstützt Unärminus (`-A`, `A * -B`, `-10.5 + 2`) und beliebige Klammerungen.
  - Division durch Null wirft `DivisionByZeroException`, fehlende/null Variablen `MissingVariableException`, Syntaxfehler `FormulaSyntaxException`.
- **Datenmodell & Abwärtskompatibilität:**
  - `FormulaVariable` speichert `name`, `field`, optionales `measurement`, `tagFilters` und `label`.
  - `WidgetDefinition` besitzt optionale `formula` und `formulaVariables`. Wenn `formula` gesetzt ist, ist das Widget gültig, sofern `formulaVariables` nicht leer ist (auch ohne klassisches Einzelfeld `field`).
  - Alle 122 bestehenden Tests liefen ohne Änderungen erfolgreich durch.
- **Hinweise für Task 17:**
  - In `Task_17` kann für Widgets mit `formulaVariables` geprüft werden, ob alle Variablen aus demselben Measurement stammen: Ist dies der Fall, genügt eine einzige InfluxQL-Abfrage (`SELECT var1, var2 FROM ... LIMIT 1`). Andernfalls werden parallele/sequentielle Sub-Queries für jedes abweichende Measurement/TagFilter ausgeführt und in `variables: Map<String, Double>` gemappt.
