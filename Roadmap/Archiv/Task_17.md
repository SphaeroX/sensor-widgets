> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_17.md` ➔ `RUN_Task_17.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`), `android/app/src/test/` oder `ios/` abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_17: Multi-Source Datenabfrage & Berechnungs-Pipeline

## 1. Ziel & Zweck des Tasks
- **Fokus:** Erweiterung der Abfragelogik und Daten-Pipeline, sodass alle in den `formulaVariables` definierten Eingangsdaten aus InfluxDB beschafft, den Variablen zugeordnet und über den `FormulaEvaluator` zu einem finalen numerischen Wert verrechnet werden.
- **Erwartetes Ergebnis:**
  - Intelligente InfluxQL-Abfrage: Wenn Variablen aus demselben Measurement stammen, erfolgt eine kombinierte Abfrage (`SELECT fieldA, fieldB FROM measurement ... LIMIT 1`). Wenn Variablen unterschiedliche Measurements oder Tag-Filter haben, werden die Werte über parallele bzw. sequentielle Sub-Queries ermittelt.
  - Integration in den Dart Influx-Service (`InfluxQueryService` / `InfluxApiClient`), in den Android Glance Background-Worker (`WidgetUpdateWorker`) und in die iOS Timeline-Pipeline.
  - Robuste Fehlererkennung, wenn einzelne Variablen-Werte in der DB fehlen (`null` / leere Series).

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_16` (Datenmodelle & `FormulaEvaluator`) abgeschlossen.
- **Betroffene Komponenten / Dateien:**
  - `lib/data/influx/influx_query_builder.dart`
  - `lib/data/influx/influx_query_service.dart` *(bzw. passender Service/Client)*
  - `lib/domain/services/formula_calculation_service.dart` *(neu)*
  - `test/data/influx/influx_query_builder_test.dart`
  - `test/domain/services/formula_calculation_service_test.dart` *(neu)*
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxClient.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/worker/WidgetUpdateWorker.kt`
  - `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxClientTest.kt`

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_17.md` umbenennen.
   - [ ] Erkenntnisse aus `Roadmap/Archiv/Task_16.md` einsehen.
2. **Query-Builder Erweiterung per TDD (Dart):**
   - [ ] **Red:** Schreibe Tests in `test/data/influx/influx_query_builder_test.dart`:
     - Erzeugt Multi-Field-Query bei Variablen aus gleichem Measurement (`SELECT f1, f2 FROM m WHERE ... ORDER BY time DESC LIMIT 1`).
     - Erzeugt saubere Einzelfragen für abweichende Measurements oder Tag-Filter.
   - [ ] **Green:** Implementiere die Builder-Methoden in `lib/data/influx/influx_query_builder.dart`.
3. **`FormulaCalculationService` per TDD (Dart):**
   - [ ] **Red:** Schreibe Tests in `test/domain/services/formula_calculation_service_test.dart`:
     - Löst für ein `WidgetDefinition` mit `formula` und `formulaVariables` die benötigten Abfragen aus.
     - Weist die zurückgegebenen Werte den Variablennamen (`A`, `B`, ...) zu.
     - Berechnet das Ergebnis via `FormulaEvaluator.evaluate`.
     - Wirft verständliche Fehler (z. B. `MissingVariableValueException`), falls ein Sensorwert in InfluxDB nicht vorhanden ist.
   - [ ] **Green:** Implementiere `lib/domain/services/formula_calculation_service.dart`.
4. **Android Native Pipeline (Kotlin):**
   - [ ] **Red:** Schreibe Tests in `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxClientTest.kt`:
     - Abfrage mehrerer Felder und Mapping auf Variablen.
     - Verrechnung mit `FormulaEvaluator`.
   - [ ] **Green:** Implementiere die Logik im Kotlin Influx-Client und binde sie in den `WidgetUpdateWorker` ein.
5. **iOS Native Pipeline (Swift):**
   - [ ] Binde die Abfrage- und Verrechnungslogik in den iOS InfluxDB-Client und Timeline-Provider ein.
6. **Refactoring & Code Quality:**
   - [ ] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` ausführen.
   - [ ] `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck` ausführen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- [x] Widgets mit Formel berechnen den korrekten numerischen Wert aus simulierten InfluxDB-Antworten.
- [x] Wenn eine Variable nicht auflösbar ist (keine Daten in DB), wird ein klarer Fehlerzustand erzeugt und nicht kommentarlos `0` oder `null` eingesetzt.
- [x] Reine Single-Field-Widgets ohne Formel funktionieren unverändert weiter ohne Overhead.
- [x] Alle Unit- und Integrationstests sind grün.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` und `android/` sind grün.
- [x] Erkenntnisse in Sektion 6 eingetragen.
- [x] `Roadmap/Tasks/Task_18.md` und `Roadmap/README.md` geprüft.
- [x] Datei umbenennen (`RUN_` entfernen) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **Multi-Source Pipeline Implementierung:**
  - `FormulaCalculationService` (`lib/domain/services/formula_calculation_service.dart`) gruppiert Variablen nach Target-Measurement und Tag-Filtern (`$m||$tagsKey`). Variablen desselben Targets werden in einer einzigen `SELECT f1, f2 FROM ... LIMIT 1` Abfrage gebündelt. Variablen aus unterschiedlichen Measurements oder mit individuellen Tag-Filtern werden in getrennten Sub-Queries aufgelöst.
  - Fehlt ein Wert in der Datenbank-Antwort, wird sofort eine `MissingVariableException(variableName)` geworfen, anstatt stumm 0 einzusetzen.
- **Android Background Worker & iOS Timeline:**
  - `WidgetRefreshWorker.kt` prüft `widget.formula` und `widget.formulaVariables`. Liegt eine Formel vor, werden die Variablen abgefragt, per `FormulaEvaluator.evaluate` berechnet und im `widget_cache` gespeichert. Bei Fehlern wird ein strukturierter JSON-Error (`{"error": "...", "timestamp": ...}`) im Cache hinterlegt.
  - `SensorTimelineProvider.swift` führt dieselbe Logik für WidgetKit auf iOS aus.
- **Hinweise für Task 18:**
  - In `Task_18` (`FormulaEditorSection` im `WidgetEditorScreen`) kann `FormulaCalculationService` direkt genutzt werden, um beim Antippen von „Vorschau laden“ das Formelergebnis live anzuzeigen.
  - Variablen können standardmäßig aus dem aktuellen Measurement gewählt werden (mit Option, ein abweichendes Measurement oder Tag-Filter über den bestehenden `SearchableSchemaPicker` zu definieren).
