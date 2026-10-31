> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_07.md` ➔ `RUN_Task_07.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_07: Android Native Core: Kotlin InfluxQL-Client, Parser, Shared-Storage-Reader & Refresh-Worker

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung der gesamten nativen Android-Hintergrundlogik in Kotlin: Deserialisierung des Widget-Definitions-Schemas (`v1`), Auslesen der Verbindungen & Tokens aus `SharedPreferences` / `EncryptedSharedPreferences`, InfluxQL-Query-Generierung, JSON-Response-Parser, Schwellenwert-Berechnung sowie `WorkManager`-Hintergrundaktualisierung.
- **Erwartetes Ergebnis:** Vollständig mit JUnit gegen `fixtures/influx/` und `fixtures/widget_definitions/` getestete Kotlin-Klassen in `android/app/src/main/kotlin/...`.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_06` müssen abgeschlossen und archiviert sein (insb. Schema aus `Task_02`, Query-Templates aus `Task_03`, Storage-Keys aus `Task_04`).
- **Betroffene Komponenten / Dateien:**
  - `android/app/build.gradle(.kts)`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/model/*.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxQlBuilder.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxResponseParser.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/influx/InfluxHttpClient.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/storage/WidgetStorageReader.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/worker/WidgetRefreshWorker.kt`
  - `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/*Test.kt`
- **Relevante globale Infos:** Siehe `../README.md`, `fixtures/influx/` und `fixtures/widget_definitions/`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_07.md` umbenennen.
   - [ ] Learnings aus `Task_02`, `Task_03` und `Task_04` prüfen.
   - [ ] Android-Abhängigkeiten in `android/app/build.gradle(.kts)` prüfen/ergänzen (`androidx.work:work-runtime-ktx`, `androidx.glance:glance-appwidget`, `org.jetbrains.kotlinx:kotlinx-serialization-json` oder `org.json` / `gson`, `junit`, `kotlinx-coroutines-test`).
2. **Kotlin Domain-Modelle & Widget-JSON-Parser per TDD (JUnit):**
   - [ ] **Red:** Schreibe `WidgetDefinitionParserTest.kt` in `android/app/src/test/...`, der `../../fixtures/widget_definitions/widget_definitions_v1.json` einliest und alle 6 Widget-Typen sowie die Schwellenwert-Auswertung (`ThresholdEvaluatorTest.kt`) prüft.
   - [ ] **Green:** Implementiere die Kotlin-Modelle und den Parser.
3. **Kotlin InfluxQL-Builder & InfluxDB-Response-Parser per TDD (JUnit):**
   - [ ] **Red:** Schreibe `InfluxQlBuilderTest.kt` und `InfluxResponseParserTest.kt`, die **exakt dieselben** InfluxQL-Queries wie Dart (`Task_03`) abprüfen und alle Dateien aus `../../fixtures/influx/*.json` parsen.
   - [ ] **Green:** Implementiere `InfluxQlBuilder.kt`, `InfluxResponseParser.kt` und `InfluxHttpClient.kt` (mit Token-Redaction in Fehlermeldungen!).
4. **SharedStorageReader & WidgetRefreshWorker per TDD:**
   - [ ] **Red:** Schreibe Unit-Tests für das Zusammenführen von Verbindungs-Metadaten (`HomeWidgetPreferences`), API-Token (`FlutterSecureStorage` / `EncryptedSharedPreferences`) und Widget-Definitionen sowie das Caching des letzten abgefragten Werts pro Widget-ID.
   - [ ] **Green:** Implementiere `WidgetStorageReader.kt` und `WidgetRefreshWorker.kt` (periodischer 15-Minuten-Job via `WorkManager` + One-Time-Expedited-Job bei manuellem Refresh).
   - [ ] **Refactor:** `ktlint` über den gesamten Kotlin-Code laufen lassen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Kotlin parst `fixtures/widget_definitions/widget_definitions_v1.json` und sämtliche `fixtures/influx/*.json` identisch zur Dart-Implementierung.
  - [ ] `WidgetStorageReader` liest die von `home_widget` und `flutter_secure_storage` geschriebenen Daten unter den exakten Keys aus `Task_02`/`Task_04` aus.
  - [ ] `WidgetRefreshWorker` speichert die abgerufenen Ergebnisse (inkl. Timestamp und etwaiger Fehlercodes) im lokalen Widget-State-Cache.
- **Testing-Pflicht (`android/app/src/test/`):**
  - [ ] `cd android && ./gradlew test` läuft vollständig grün.
  - [ ] `ktlint "android/**/*.kt"` meldet 0 Verstöße.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle JUnit-Tests (`cd android && ./gradlew test`) und Dart-Tests (`flutter test`) sind grün.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_07.md` ➔ `Task_07.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Stolpersteine & gelöste Probleme:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Wichtige Hinweise für die Folge-Tasks:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
