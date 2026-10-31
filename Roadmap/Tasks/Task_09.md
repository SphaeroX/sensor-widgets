> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD und Regel 4: **iOS kann lokal nicht ausgeführt werden**)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_09.md` ➔ `RUN_Task_09.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_09: iOS Native Core & WidgetKit Extension (XcodeGen, Swift Parser, AppIntents & SwiftUI Views)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung der gesamten nativen iOS-Schicht (iOS 17.0+): Swift-Datenmodelle, InfluxQL-Query-Builder, JSON-Response-Parser, App-Group-Storage- & Keychain-Reader, `AppIntentConfiguration` mit `EntityQuery` zur Widget-Auswahl, `TimelineProvider` sowie SwiftUI-Views (inkl. Swift Charts) für alle 6 Widget-Typen. Reproduzierbare Einbindung des Widget-Extension- & XCTest-Targets für GitHub Actions (`macos-latest`).
- **Erwartetes Ergebnis:** Vollständiger, SwiftLint-konformer Swift-Code und XCTests gegen `fixtures/influx/` und `fixtures/widget_definitions/`, eingebunden in `.github/workflows/ci.yml`.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_08` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `ios/SensorWidgetsExtension/Models/WidgetModels.swift`
  - `ios/SensorWidgetsExtension/Influx/InfluxQlBuilder.swift`
  - `ios/SensorWidgetsExtension/Influx/InfluxResponseParser.swift`
  - `ios/SensorWidgetsExtension/Influx/InfluxHttpClient.swift`
  - `ios/SensorWidgetsExtension/Storage/SharedGroupStorage.swift`
  - `ios/SensorWidgetsExtension/Intents/SelectWidgetIntent.swift`
  - `ios/SensorWidgetsExtension/Timeline/SensorTimelineProvider.swift`
  - `ios/SensorWidgetsExtension/Views/SensorWidgetViews.swift`
  - `ios/SensorWidgetsExtension/SensorWidgetsBundle.swift`
  - `ios/SensorWidgetsTests/InfluxWidgetCoreTests.swift`
  - `ios/Package.swift` (und/oder XcodeGen/Ruby-xcodeproj-Setup für CI)
  - `.github/workflows/ci.yml`
  - `docs/architecture.md`, `docs/testing.md`
- **Relevante globale Infos:** Siehe `../README.md` und `/AGENTS.md` (Regel 4: Es gibt keinen lokalen Mac; behaupte niemals, iOS-Code sei lokal ausgeführt worden!).

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_09.md` umbenennen.
   - [ ] Learnings aus `Task_02`, `Task_03`, `Task_04` und `Task_07` prüfen.
2. **Swift Core-Logik & XCTests (TDD-Struktur für CI):**
   - [ ] Strukturierung der Core-Logik (`Models`, `InfluxQlBuilder`, `InfluxResponseParser`, `ThresholdEvaluator`), sodass sie sowohl vom WidgetKit-Extension-Target als auch vom Test-Target (`xcodebuild test` / `swift test` auf macOS-CI) direkt getestet werden kann.
   - [ ] Schreibe `ios/SensorWidgetsTests/InfluxWidgetCoreTests.swift` zuerst (Red-Spezifikation):
     - Lädt `fixtures/widget_definitions/widget_definitions_v1.json` und prüft alle 6 Widget-Typen.
     - Prüft `InfluxQlBuilder` auf identische InfluxQL-Strings wie in Dart (`Task_03`) und Kotlin (`Task_07`).
     - Lädt und parst alle Dateien aus `fixtures/influx/*.json`.
     - Prüft Schwellenwert-Auswertung und Token-Redaction in Fehlermeldungen.
   - [ ] Implementiere `WidgetModels.swift`, `InfluxQlBuilder.swift`, `InfluxResponseParser.swift` und `InfluxHttpClient.swift` (Green).
3. **App Group Storage, Keychain & AppIntents (iOS 17+):**
   - [ ] Implementiere `SharedGroupStorage.swift`:
     - Liest Verbindungs-Metadaten und Widget-Definitionen aus `UserDefaults(suiteName: "group.io.github.mgasc.influx_sensor_widgets")`.
     - Liest das API-Token aus der iOS Keychain (kompatibel mit den `IOSOptions` von `flutter_secure_storage` aus `Task_04`).
     - Speichert/liest den letzten bekannten Messwert im lokalen App-Group-Cache für Offline-Resilienz.
   - [ ] Implementiere `SelectWidgetIntent.swift` (`WidgetConfigurationIntent` + `WidgetDefinitionEntity` + `EntityQuery`), sodass Nutzer beim Bearbeiten des iOS-Widgets aus der dynamischen Liste der in der Flutter-App angelegten Widgets wählen können.
4. **TimelineProvider & SwiftUI Views für alle 6 Widget-Typen:**
   - [ ] Implementiere `SensorTimelineProvider.swift` (`AppIntentTimelineProvider`): führt den Netzwerk-Request im Hintergrund durch und plant das nächste Timeline-Reload budgetschonend (z. B. `.after(Date().addingTimeInterval(15 * 60))`).
   - [ ] Implementiere `SensorWidgetViews.swift` (nutzt SwiftUI & `Charts` ab iOS 17):
     - `SingleValueWidgetView`, `HistoryChartWidgetView` (mit `Chart { LineMark / AreaMark }`), `IndicatorLampWidgetView`, `MultiValueWidgetView`, `AggregateWidgetView`, `GaugeBarWidgetView` (mit `Gauge` / Progress-Bar) sowie `containerBackground(for: .widget)`.
5. **CI-Workflow (`.github/workflows/ci.yml`) & Dokumentation:**
   - [ ] Konfiguriere den `ios`-Job in `.github/workflows/ci.yml` so, dass auf `macos-latest`:
     1. `swiftlint` ausgeführt wird,
     2. die Swift-Core-Unit-Tests gegen `fixtures/` ausgeführt werden (`swift test` / `xcodebuild test`),
     3. das Widget-Extension-Target reproduzierbar (per `xcodeproj`-Skript oder `xcodegen`) eingebunden und mit `flutter build ios --simulator --no-codesign` gebaut wird.
   - [ ] Dokumentiere das Setup und den Status transparent in `docs/architecture.md` und `docs/testing.md`.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Alle 6 Widget-Typen, `AppIntentConfiguration`, `EntityQuery`, `TimelineProvider` und Keychain/AppGroup-Reader sind in Swift vollständig implementiert.
  - [ ] Swift-Code hält sich strikt an `.swiftlint.yml` und das v1-JSON-Schema aus `Task_02`.
- **Testing-Pflicht (`ios/` & CI):**
  - [ ] `ios/SensorWidgetsTests/InfluxWidgetCoreTests.swift` deckt alle Fixtures aus `fixtures/influx/` und `fixtures/widget_definitions/` ab.
  - [ ] Wahrheitsgemäße Dokumentation: Da lokal kein Mac vorhanden ist, wird klar dokumentiert, welche Prüfungen lokal liefen und dass die iOS-Ausführung über den GitHub Actions Workflow (`ci.yml`) erfolgt.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle lokal ausführbaren Suiten (`flutter test`, `flutter analyze`, `./gradlew test`, `ktlint`) sind grün und die iOS-CI-Konfiguration ist vollständig.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Task (`Task_10`) und `Roadmap/README.md` sowie `docs/` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_09.md` ➔ `Task_09.md`) und nach `Roadmap/Archiv/` verschieben.

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
