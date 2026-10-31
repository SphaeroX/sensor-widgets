# Projektübersicht & Roadmap-Gedächtnis (`sensor-widgets`)

Diese Datei ist das zentrale, projektübergreifende Gedächtnis des Projekts. Sie enthält alle globalen Informationen, Architekturvorgaben und den aktuellen Entwicklungsstand. Sie wird von allen KI-Agenten im Projektverlauf kontinuierlich gepflegt und aktualisiert (ergänzend zu den Dokumenten in `docs/`).

---

## 1. Klares Projektziel

### 1.1 Was die Software tut
- **Produktvision:** Eine quelloffene (MIT) Mobile-App für Android und iOS (`sensor_widgets`), die als komfortables Konfigurations-Dashboard für zahlreiche native Homescreen-Widgets dient, welche Messdaten aus InfluxDB (Cloud TSM/Serverless sowie Self-Hosted v1/v2/v3) direkt im Hintergrund abrufen und darstellen.
- **Hauptfunktionen:**
  - **6 native Widget-Typen:**
    1. `single_value`: Einzelwert mit Einheit und Zeitstempel.
    2. `history_chart`: Verlaufsdiagramm über einen wählbaren Zeitraum.
    3. `indicator_lamp`: Indikatorlampe mit Schwellenwert-Umschaltung (`>` oder `<`).
    4. `multi_value`: Multi-Wert-Übersicht (z. B. ein Raum mit mehreren Sensoren).
    5. `aggregate`: Aggregatwert (`MIN`, `MAX`, `MEAN`) über einen Zeitraum.
    6. `gauge_bar`: Pegel-/Balken- oder Gauge-Anzeige mit Min/Max und Farbzonen.
  - **Verbindungsverwaltung:** Verwaltung mehrerer InfluxDB-Instanzen (URL, Datenbank/Bucket, API-Token) inkl. Live-Verbindungstest.
  - **Kombinierter Widget-Konfigurator:** Schema-Discovery per InfluxQL (`SHOW MEASUREMENTS`, `SHOW FIELD KEYS`, `SHOW TAG KEYS`, `SHOW TAG VALUES`) mit jederzeit nutzbarem Freitext-Fallback sowie Live-Vorschau.
  - **Autarke Hintergrund-Widgets:** Native Umsetzung in Kotlin/Jetpack Glance (Android) und SwiftUI/WidgetKit (iOS 17+), die im Plattform-Zyklus (~15–30 Min.) direkt gegen die InfluxDB v1-kompatible HTTP-API (`/query`) abfragen.

### 1.2 Zieldefinition & Erfolgskriterien (Production Ready)
- [x] Flutter-App verwaltet Verbindungen und alle 6 Widget-Typen fehlerfrei und persistiert Tokens sicher (`EncryptedSharedPreferences` / iOS App Group Keychain) sowie Widget-Definitionen im Shared Storage (`home_widget`).
- [x] Sprachübergreifend identische InfluxQL-Generierung und Response-Parsing (Dart, Kotlin, Swift), abgesichert durch gemeinsame Fixtures in `fixtures/influx/`.
- [x] Vollständige native Android-Widgets (Jetpack Glance + `WorkManager` + Config-Activity) für alle 6 Typen.
- [x] Vollständige native iOS-Widgets (SwiftUI + WidgetKit + `AppIntentConfiguration` + `EntityQuery`) für alle 6 Typen, reproduzierbar gebaut und getestet über GitHub Actions (`macos-latest`).
- [x] Strikte TDD-Abdeckung (Dart `flutter_test`/`integration_test`, Android `JUnit`, iOS `XCTest`) sowie fehlerfreie Linter (`flutter analyze`, `dart format`, `ktlint`, `swiftlint`).

---

## 2. Aktueller Status

* **Status:** Vollständig abgeschlossen (`Task_01` bis `Task_10` erledigt)
* **Aktiver Task:** Keiner (Projekt ist produktionsreif)
* **Fortschritt:** 10 / 10 Tasks abgeschlossen (100 %)

| Task-ID | Titel | Status | Verantwortlicher Agent / Info |
| :--- | :--- | :--- | :--- |
| `Task_01` | Projekt-Scaffolding, Toolchain-Pinning & CI/CD-Grundgerüst | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_01.md` |
| `Task_02` | Shared Kontrakt: Widget-Definitions-Schema (v1) & Test-Fixtures | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_02.md` |
| `Task_03` | Dart InfluxQL Query-Builder, Parser & HTTP-Client | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_03.md` |
| `Task_04` | Persistenz- & Bridge-Layer (Secure Token & Shared Storage) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_04.md` |
| `Task_05` | Flutter Dashboard UI – Teil 1: Verbindungsverwaltung | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_05.md` |
| `Task_06` | Flutter Dashboard UI – Teil 2: Widget-Konfigurator & Live-Vorschau | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_06.md` |
| `Task_07` | Android Native Core: Kotlin InfluxQL-Client, Parser & Worker | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_07.md` |
| `Task_08` | Android Jetpack Glance Widgets (Alle 6 Widget-Typen) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_08.md` |
| `Task_09` | iOS Native Core & WidgetKit Extension (XcodeGen & SwiftUI) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_09.md` |
| `Task_10` | E2E-Integrationstests, Offline-Resilienz & Production-Polish | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_10.md` |

*(Hinweis: Sobald ein Task ins `Archiv/` verschoben wird, wird der Status hier auf `Erledigt` gesetzt.)*

---

## 3. Taskübergreifende Entwicklungsinfos

Dieses Kapitel wird von den KI-Agenten fortlaufend aktualisiert, sobald architekturelle Entscheidungen getroffen oder globale Schnittstellen definiert werden. Beachte zusätzlich zwingend die Dateien in `docs/`!

### 3.1 Tech-Stack & Frameworks
- **App-Framework:** Flutter (Dart), Package-Name `sensor_widgets`, Bundle-ID / Application-ID `io.github.mgasc.influx_sensor_widgets`.
- **Mindest-Plattformen:** Android `minSdk 26` (Android 8.0+), iOS `17.0+`.
- **State-Management & DI:** `flutter_riverpod`.
- **Bridge & Storage:**
  - `home_widget` für das Teilen der JSON-Widget-Definitionen (Android `SharedPreferences`, iOS `UserDefaults` in App Group `group.io.github.mgasc.influx_sensor_widgets`).
  - `flutter_secure_storage` / native Keystore- & Keychain-Zugriffe für InfluxDB-API-Tokens (`EncryptedSharedPreferences` auf Android, App Group Keychain auf iOS).
- **Native Widgets:**
  - **Android:** Kotlin + Jetpack Glance (`androidx.glance:glance-appwidget`) + `WorkManager`.
  - **iOS:** Swift + SwiftUI + WidgetKit + Swift Charts + `AppIntents` (`AppIntentConfiguration`), verwaltet über XcodeGen (`ios/project.yml` bzw. CI-Skript).
- **Datenbank-Abfrage:** InfluxDB HTTP API v1-Kompatibilitäts-Endpunkt (`GET/POST /query?db=<bucket>&q=<influxql>&epoch=ms`, Header `Authorization: Token <token>`).
- **Testing-Frameworks:**
  - Dart: `flutter_test`, `integration_test`, `mocktail`
  - Android: `JUnit 4/5`, `kotlinx-coroutines-test`
  - iOS: `XCTest` / `Swift Testing` (Ausführung ausschließlich in GitHub Actions auf `macos-latest`)

### 3.2 Globale Architektur & Designentscheidungen
- **Strikte Entkopplung:** Die Flutter-App ist ausschließlich das Konfigurations-Dashboard. Native Widgets führen ihre HTTP-Requests und das Rendering selbstständig im Hintergrund aus (`HomeWidget.renderFlutterWidget` wird für Charts **nicht** genutzt, da es im Hintergrund nicht zuverlässig funktioniert).
- **Verzeichnisstruktur im Root:**
  - `lib/`: Flutter-Quellcode (`domain/`, `data/`, `presentation/`, `core/`)
  - `test/`: Permanente Dart Unit- & Widget-Test-Suite (spiegelt `lib/`)
  - `integration_test/`: End-to-End Integrationstests der Flutter-App
  - `android/`: Android-Projekt inkl. Glance-Widgets und JUnit-Tests unter `android/app/src/test/`
  - `ios/`: iOS-Projekt inkl. WidgetKit-Extension und XCTests
  - `fixtures/influx/`: Sprachübergreifende InfluxDB-Response-Fixtures für Dart-, Kotlin- und Swift-Tests
  - `docs/`: Verbindliche Projektdokumentation (`architecture.md`, `testing.md`, `code-style.md`, `conventions.md`, `project-brief.md`)
  - `Roadmap/`: Projektorganisation und Task-Steuerung
- **Schnittstellen & Datenformate:**
  - Jede Änderung am Widget-Definitions-JSON-Format oder den Shared-Storage-Keys muss **immer im selben Schritt** in Dart, Kotlin, Swift und den Fixtures nachgezogen werden.
  - **Verbindliche InfluxQL-Templates (sprachübergreifend für Dart, Kotlin, Swift):**
    - Single / Lamp / Gauge: `SELECT "<field>" FROM "<measurement>" [WHERE <tagFilters>] ORDER BY time DESC LIMIT 1`
    - History Chart: `SELECT MEAN("<field>") AS "mean" FROM "<measurement>" WHERE time > now() - <range> [AND <tagFilters>] GROUP BY time(<bucket>) fill(none)`
    - Aggregate: `SELECT MIN("<field>") AS "min", MAX("<field>") AS "max", MEAN("<field>") AS "mean" FROM "<measurement>" WHERE time > now() - <range> [AND <tagFilters>]`
    - Multi-Value: `SELECT "<field1>", "<field2>", ... FROM "<measurement>" [WHERE <tagFilters>] ORDER BY time DESC LIMIT 1`
    - Schema Discovery: `SHOW MEASUREMENTS`, `SHOW FIELD KEYS FROM "<m>"`, `SHOW TAG KEYS FROM "<m>"`, `SHOW TAG VALUES FROM "<m>" WITH KEY = "<k>"`

### 3.3 Konventionen & Best Practices
- **TDD (Test-Driven Development) ist Pflicht:** Zuerst fehlschlagenden Test schreiben (Red), dann minimalen Produktionscode (Green), dann Refactoring. Maximal 3 Reparaturversuche pro fehlschlagendem Test, danach Stopp & Bericht. Bestehende Tests niemals abschwächen oder löschen.
- **Code-Style & Linter:**
  - `dart format --set-exit-if-changed .` und `flutter analyze`
  - `ktlint "android/**/*.kt"`
  - `swiftlint` (in CI)
- **Doku-Aktualität:** Änderungen an Architektur, Befehlen oder Konventionen müssen sofort in `docs/` UND `Roadmap/README.md` aktualisiert werden.

---

## 4. Auffälligkeiten & Details

* **Sicherheit & Zugriffsschutz:**
  - Das Repository ist öffentlich (MIT). **Niemals** echte Tokens, echte Hostnamen oder Signaturzertifikate committen oder in Logs ausgeben!
  - Alle Fehler- und Debug-Logs müssen `Authorization`-Header und Tokens konsequent maskieren (`***`).
* **Plattform- / Umgebungs-Besonderheiten:**
  - **Kein lokaler Mac / kein iPhone:** iOS-Code kann lokal auf Windows nicht kompiliert oder getestet werden. iOS-Verifikation erfolgt ausschließlich über GitHub Actions. Behaupte niemals, iOS-Code sei verifiziert, solange CI ihn nicht ausgeführt hat!
  - **Markenrecht:** Vermeide „Influx“ oder „InfluxDB“ im sichtbaren App-Namen und Store-Listing (Arbeitstitel/Anzeigename: `Sensor Widgets`).
* **Offene globale Notizen:**
  - Vor dem Hinzufügen neuer Dependencies (über die in `Task_01` definierten Kernpakete hinaus) muss immer Rücksprache mit dem Nutzer gehalten werden (siehe Root-`AGENTS.md`).
