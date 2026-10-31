> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_02.md` ➔ `RUN_Task_02.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_02: Shared Kontrakt: Widget-Definitions-Schema (v1), Storage-Keys & Test-Fixtures

## 1. Ziel & Zweck des Tasks
- **Fokus:** Definition des plattformübergreifenden Datenkontrakts zwischen Flutter-Dashboard, Android-Widgets (Kotlin) und iOS-Widgets (Swift) sowie Aufbau der gemeinsamen InfluxDB-Testfixtures in `fixtures/influx/`.
- **Erwartetes Ergebnis:** Vollständige JSON-Fixtures für alle Abfrage- und Fehlerszenarien in `fixtures/influx/`, dokumentierte Storage-Keys und `schemaVersion: 1` Spezifikation sowie per TDD getestete Dart-Domain-Modelle (inkl. Schwellenwert- und Validierungslogik).

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` muss abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `fixtures/influx/*.json`
  - `fixtures/widget_definitions/*.json` (Referenz-Fixtures für das Widget-JSON-Format v1, damit Dart, Kotlin und Swift exakt dasselbe JSON parsen)
  - `lib/core/constants/storage_keys.dart`
  - `lib/domain/models/influx_connection.dart`
  - `lib/domain/models/widget_type.dart`
  - `lib/domain/models/threshold_rule.dart`
  - `lib/domain/models/widget_definition.dart`
  - `lib/domain/models/sensor_data_point.dart`
  - `test/domain/models/*_test.dart`
  - `docs/architecture.md`, `docs/conventions.md`
- **Relevante globale Infos:** Siehe `../README.md`. Änderungen am Widget-Definitions-Format betreffen später `Task_07` (Kotlin) und `Task_09` (Swift).

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_02.md` umbenennen.
   - [ ] Learnings aus `Roadmap/Archiv/Task_01.md` prüfen.
2. **InfluxDB & Widget-Definition Test-Fixtures anlegen (`fixtures/`):**
   - [ ] Erstelle realistische (ausschließlich fiktive Hostnamen/Sensoren nutzende!) InfluxDB v1 JSON-Responses in `fixtures/influx/`:
     - `single_value_response.json` (1 Datenpunkt mit Zeitstempel `epoch=ms` und Wert)
     - `history_series_response.json` (Zeitreihe mit mehreren Datenpunkten für `history_chart`)
     - `multi_series_room_response.json` (mehrere Serien/Sensoren für `multi_value`)
     - `aggregate_min_max_mean_response.json` (aggregierte Werte `min`, `max`, `mean` für `aggregate`)
     - `show_measurements_response.json`, `show_field_keys_response.json`, `show_tag_keys_response.json`, `show_tag_values_response.json` (für Schema-Discovery)
     - `empty_result_response.json` (valide Response, aber leeres `series`-Array)
     - `error_query_response.json` (InfluxDB Query-Error-JSON `{"error": "..."}`)
   - [ ] Erstelle in `fixtures/widget_definitions/widget_definitions_v1.json` eine Referenz-JSON-Datei, die alle 6 Widget-Typen (`single_value`, `history_chart`, `indicator_lamp`, `multi_value`, `aggregate`, `gauge_bar`) im exakten `v1`-Format abbildet.
3. **Storage-Keys & Schema-Konstanten definieren:**
   - [ ] **Red:** Test für `StorageKeys` und Schema-Version schreiben (`test/core/constants/storage_keys_test.dart`).
   - [ ] **Green:** `lib/core/constants/storage_keys.dart` implementieren (App Group ID `group.io.github.mgasc.influx_sensor_widgets`, Android SharedPreferences Name, Keys für `widget_definitions_v1`, `connections_metadata_v1`, Token-Key-Präfix, Cache-Key-Präfix).
4. **Domain-Modelle per TDD umsetzen:**
   - [ ] **Red:** Unit-Tests in `test/domain/models/` für `InfluxConnection`, `WidgetType`, `TimeRange`, `AggregateFunction`, `ThresholdOperator` (`greaterThan`, `lessThan`), `ThresholdRule`, `SensorQueryItem` (für Multi-Value) und `WidgetDefinition` schreiben – inklusive Roundtrip-Serialisierung gegen `fixtures/widget_definitions/widget_definitions_v1.json` sowie Schwellenwert-Auswertung (`evaluateThreshold`).
   - [ ] **Green:** Domain-Modelle in `lib/domain/models/` implementieren (unveränderlich/immutable, typsicheres `toJson()`/`fromJson()`, klare Validierungsmethoden, keine Token-Ausgabe in `toString()`!).
   - [ ] **Refactor:** Code bereinigen und Dokumentation des v1-JSON-Schemas in `docs/architecture.md` ergänzen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Alle 6 Widget-Typen (`single_value`, `history_chart`, `indicator_lamp`, `multi_value`, `aggregate`, `gauge_bar`) sind vollständig im Modell und in `fixtures/widget_definitions/widget_definitions_v1.json` abgebildet.
  - [ ] `InfluxConnection.toString()` maskiert das Token (`***`), sodass niemals versehentlich ein Token geloggt werden kann.
  - [ ] Schwellenwert-Evaluator prüft `>` und `<` inkl. Grenzwerte (`==`, `NaN`) deterministisch.
- **Testing-Pflicht (`test/`):**
  - [ ] Neue Tests unter `test/domain/models/` prüfen Serialisierung, Deserialisierung, Schema-Migration/Version-Check und Fixture-Kompatibilität.
  - [ ] `flutter test`, `dart format --set-exit-if-changed .` und `flutter analyze` sind grün.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests unter `test/` sind grün.
- [ ] Das JSON-Schema v1 und die Storage-Keys sind in `docs/architecture.md` und `Roadmap/README.md` dokumentiert.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Tasks (`Task_03`, `Task_07`, `Task_09`) auf Konsistenz mit dem Schema geprüft.
- [ ] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_02.md`) und nach `Roadmap/Archiv/` verschieben.

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
