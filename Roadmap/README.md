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
  - **Verbindungsverwaltung:** Verwaltung mehrerer InfluxDB-Instanzen (URL, Datenbank/Bucket, API-Token) inkl. Live-Verbindungstest mit Statement-Error-Prüfung.
  - **Benutzerfreundlicher, geführter Widget-Konfigurator (Meilenstein 2 UX-Upgrade):**
    - Automatischer Datenbankabruf der verfügbaren **Measurements**, **Fields** (inkl. `fieldType`: `float`, `integer`, `string`, `boolean`) sowie **Tag-Keys** und **Tag-Values** per InfluxQL.
    - Komfortable Auswahl per Antippen über ein **durchsuchbares Bottom-Sheet** (`SearchableSchemaPicker`) mit manuellem Freitext-Umschalter als Fallback.
    - Interaktive Auswahl optionaler **Tag-Filter** (`WHERE room = 'living_room'`, `entity_id = ...`) als Chips per Klick aus den geladenen DB-Tags.
    - **Multi-Select-Auswahl** (Checkboxen/Chips inkl. Datentyp-Anzeige und optionalem Label/Unit) für `multi_value`-Widgets sowie Markierung/Filterung numerischer Felder bei Zahlen-Widgets.
    - Transparente **Lade-Anzeige**, verständliche **Fehlermeldung** (inkl. Diagnose-Hinweis für InfluxDB v2 Bucket/DBRP-Mappings statt stillschweigend leerer Listen) und manueller **Neu-Laden-Button** (`↻`).
  - **Autarke Hintergrund-Widgets:** Native Umsetzung in Kotlin/Jetpack Glance (Android) und SwiftUI/WidgetKit (iOS 17+), die im Plattform-Zyklus (~15–30 Min.) direkt gegen die InfluxDB v1-kompatible HTTP-API (`/query`) abfragen.

### 1.2 Zieldefinition & Erfolgskriterien
- [x] **Meilenstein 1 (`Task_01`–`Task_10`):** Vollständige Basis-App, Persistenz-Bridge (`home_widget` + Secure Storage), alle 6 Widget-Typen nativ auf Android & iOS, Cross-Platform-Fixtures & CI/CD.
- [x] **Meilenstein 2 (`Task_11`–`Task_15`):** Benutzerfreundliche Schema-Auswahl im Widget-Editor:
  - [x] `SHOW FIELD KEYS` wertet sowohl `fieldKey` als auch `fieldType` (`InfluxFieldInfo`) aus; `testConnection` und Schema-Abfragen erkennen InfluxDB-Statement-Errors (z. B. `database not found` bei fehlendem InfluxDB-v2-DBRP-Mapping).
  - [x] Reaktiver Discovery-State liefert echte Lade-, Treffer-, Leer- und Fehlerzustände (mit Token-Maskierung und Reload-Trigger) statt stiller leerer Listen.
  - [x] Measurements und Fields lassen sich direkt per Antippen im durchsuchbaren Bottom-Sheet auswählen (mit jederzeit umschaltbarem Freitext-Fallback).
  - [x] Tag-Filter (`tagFilters`) und Multi-Value-Felder (`items`) lassen sich komplett ohne Tippen aus den geladenen DB-Metadaten zusammenklicken.
  - [x] 100 % Abwärtskompatibilität zum JSON-Schema `widget_definitions_v1` sowie grüne TDD-Testsuite (`flutter test`, `flutter analyze`, `dart format`).
- [x] **Meilenstein 3 (`Task_16`–`Task_20`):** Lokale Formel-Berechnung & Variablen-Mapping:
  - [x] Shared Kontrakt & mathematischer Evaluator (AST/Shunting-Yard) konsistent in Dart, Kotlin und Swift.
  - [x] Multi-Source InfluxQL Datenabfrage (kombinierte Queries für gleiches Measurement, Sub-Queries für unterschiedliche Measurements/Tags).
  - [x] Formel-Editor & Variablen-Mapping im Flutter Widget-Editor mit Syntax-Check und Live-Vorschau.
  - [x] Native Widget-Integration (Android Glance & iOS WidgetKit) inkl. transparenter Fehleranzeige bei Division durch 0 oder fehlenden Werten.
  - [x] End-to-End Verifikation & Dokumentation.
- [x] **Meilenstein 4 (`Task_21`–`Task_33`, bis auf zurückgestelltes `Task_21`):** Formeln für alle Widgets, Gradienten & Styling:
  - [x] Dashboard-Layout-Bugfix (Liste scrollt unter die AppBar): nicht reproduzierbar, durch Regressionstests abgesichert (siehe `Task_21`).
  - [x] Formel-Kontrakt v2: Funktionen (`min`, `max`, `clamp`, `abs`, `pow`, `sqrt`, `ln`, `log10`, `exp`, `round`, `floor`, `ceil`), Vergleiche, `if(...)`, Konstanten und benannte Zwischenformeln, identisch in Dart, Kotlin, Swift.
  - [x] Formel auf Zeitreihen (Zeit-Buckets per `GROUP BY time`) für Verlaufschart und vor der Aggregation beim Aggregat; Gauge und Lampe rechnen die Formel aus den aktuellsten Werten; Formel pro Multi-Value-Zeile.
  - [x] Variablen per Picker aus dem DB-Schema wählbar (kein manuelles Tippen von Feldnamen), Formel-Editor bei allen Typen, In-App-Hilfe mit Vorlagen (z. B. IAQ).
  - [x] Frei konfigurierbarer Farbverlauf nach Wert im Verlaufschart (Dart, Android, iOS).
  - [x] Styling: App-UI-Redesign (Material 3, Hell/Dunkel, Typ-Kacheln), Widget-Optik pro Widget, Vorschau-Parität (Typ-Dropdown bleibt vorerst, siehe `Task_31`).

---

## 2. Aktueller Status

* **Status:** Meilensteine 1 bis 4 umgesetzt
* **Aktiver Task:** Keiner (alle Tasks abgearbeitet)
* **Fortschritt:** 33 / 33 Tasks abgeschlossen (Meilenstein 1: 10/10 · Meilenstein 2: 5/5 · Meilenstein 3: 5/5 · Meilenstein 4: 13/13)

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
| `Task_11` | Schema-Modelle (`InfluxFieldInfo` / `fieldType`) & InfluxDB-v2-Fehlerdiagnose | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_11.md` |
| `Task_12` | Reaktiver Schema-Discovery-State (Laden, Fehlerdiagnose & Reload) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_12.md` |
| `Task_13` | UI-Komponente `SearchableSchemaPicker` (Bottom-Sheet, Typ-Badges & Freitext-Fallback) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_13.md` |
| `Task_14` | Interaktiver `TagFilterEditor` & `MultiFieldSelector` (Chips & Checkbox-Sheet) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_14.md` |
| `Task_15` | Integration in `WidgetEditorScreen`, Lifecycle-Bugfix & End-to-End-Verifikation | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_15.md` |
| `Task_16` | Shared Kontrakt & Cross-Platform Formel-Evaluator (Dart, Kotlin, Swift) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_16.md` |
| `Task_17` | Multi-Source Datenabfrage & Berechnungs-Pipeline | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_17.md` |
| `Task_18` | Flutter UI: Formel-Editor & Variablen-Mapping | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_18.md` |
| `Task_19` | Native Widget-Integration (Android Glance & iOS WidgetKit) & Fehlerzustände | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_19.md` |
| `Task_20` | End-to-End Verifikation, CI/CD & Dokumentation | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_20.md` |
| `Task_21` | Bugfix: Dashboard-Layout (Liste scrollt unter die AppBar) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_21.md` (Fehler nicht reproduzierbar, nur Regressionstests; siehe Task) |
| `Task_22` | Formel-Kontrakt v2 & Dart-Evaluator (Funktionen, Bedingungen, Zwischenformeln) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_22.md` |
| `Task_23` | Evaluator-Parität in Kotlin und Swift | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_23.md` (Kotlin lokal grün, Swift wartet auf CI) |
| `Task_24` | Zeit-Bucket-Pipeline (Dart): Formel im Verlaufschart, Aggregat, Gauge, Lampe | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_24.md` |
| `Task_25` | Native Pipeline Android & iOS: Formel für Zeitreihen und alle Typen | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_25.md` |
| `Task_26` | Multi-Value: Formel pro Zeile (Dart, Android, iOS) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_26.md` |
| `Task_27` | Editor: Variablen per Picker, Formel für alle Typen, Zwischenformeln | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_27.md` |
| `Task_28` | Hilfe-Seite & Formel-Vorlagen (z. B. IAQ) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_28.md` |
| `Task_29` | Gradient- und Chart-Style-Kontrakt + Dart-Chart & Vorschau | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_29.md` |
| `Task_30` | Native Gradienten & Chart-Style (Android Glance, iOS WidgetKit) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_30.md` (Optik auf Geraet nicht geprueft) |
| `Task_31` | App-UI-Redesign (Dashboard, Editor, Typ-Kacheln, Hell/Dunkel) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_31.md` (Dropdown bleibt, siehe Task) |
| `Task_32` | Widget-Optik pro Widget mit Vorschau-Parität | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_32.md` (Optik auf Geraeten nicht geprueft) |
| `Task_33` | End-to-End-Verifikation, CI & Dokumentation (Meilenstein 4) | `Erledigt` | Archiviert in `Roadmap/Archiv/Task_33.md` |

*(Hinweis: Sobald ein Task ins `Archiv/` verschoben wird, wird der Status hier auf `Erledigt` gesetzt.)*

---

## 3. Taskübergreifende Entwicklungsinfos

Dieses Kapitel wird von den KI-Agenten fortlaufend aktualisiert, sobald architekturelle Entscheidungen getroffen oder globale Schnittstellen definiert werden. Beachte zusätzlich zwingend die Dateien in `docs/`!

### 3.1 Tech-Stack & Frameworks
- **App-Framework:** Flutter (Dart), Package-Name `sensor_widgets`, Bundle-ID / Application-ID `io.github.mgasc.influx_sensor_widgets`.
- **Mindest-Plattformen:** Android `minSdk 26` (Android 8.0+), iOS `17.0+`.
- **State-Management & DI:** `flutter_riverpod` (keine neuen externen Packages ohne ausdrückliche Rücksprache mit dem Nutzer!).
- **Bridge & Storage:**
  - `home_widget` für das Teilen der JSON-Widget-Definitionen (Android `SharedPreferences`, iOS `UserDefaults` in App Group `group.io.github.mgasc.influx_sensor_widgets`).
  - `flutter_secure_storage` / native Keystore- & Keychain-Zugriffe für InfluxDB-API-Tokens (`EncryptedSharedPreferences` auf Android, App Group Keychain auf iOS).
- **Native Widgets:**
  - **Android:** Kotlin + Jetpack Glance (`androidx.glance:glance-appwidget`) + `WorkManager`.
  - **iOS:** Swift + SwiftUI + WidgetKit + Swift Charts + `AppIntents` (`AppIntentConfiguration`), verwaltet über `ios/Package.swift` / Xcode-Projekt.
- **Datenbank-Abfrage:** InfluxDB HTTP API v1-Kompatibilitäts-Endpunkt (`GET /query?db=<bucket>&q=<influxql>&epoch=ms`, Header `Authorization: Token <token>`).
- **Testing-Frameworks:**
  - Dart: `flutter_test`, `integration_test`, `mocktail`
  - Android: `JUnit 4/5`, `kotlinx-coroutines-test`
  - iOS: `XCTest` / `Swift Testing` (Ausführung ausschließlich in GitHub Actions auf `macos-latest`)

### 3.2 Globale Architektur & Designentscheidungen
- **Strikte Entkopplung:** Die Flutter-App ist ausschließlich das Konfigurations-Dashboard. Native Widgets führen ihre HTTP-Requests und das Rendering selbstständig im Hintergrund aus.
- **Unveränderter Widget-Definitions-Kontrakt (`schemaVersion: 1`):**
  - Meilenstein 2 (`Task_11`–`Task_15`) ändert das JSON-Format in `widget_definitions_v1` **nicht**! `WidgetDefinition` besitzt bereits `measurement`, `field`, `tagFilters` (`Map<String, String>?`) und `items` (`List<SensorQueryItem>?`), die von Android und iOS bereits vollständig ausgewertet werden.
- **UX-Vorgaben für die Schema-Auswahl (`Task_11`–`Task_15`):**
  - **Kein ungewolltes Auto-Verhalten:** Die Live-Vorschau wird weiterhin gezielt über den Button „Vorschau laden“ ausgelöst, und der Widget-Titel wird **nicht** automatisch überschrieben.
  - **Bottom-Sheet-Picker + Freitext-Umschalter:** Sobald Schema-Daten geladen sind, wählt der Nutzer Measurements, Fields und Tags bequem per Antippen aus einem durchsuchbaren Bottom-Sheet. Ein klarer Umschalter („Manuell eingeben“ / „Aus Liste wählen“) erlaubt jederzeit den Wechsel in ein Freitextfeld.
  - **Feld-Datentypen (`InfluxFieldInfo`):** `SHOW FIELD KEYS FROM "<m>"` liefert `["fieldKey", "fieldType"]` (`float`, `integer`, `boolean`, `string`). In der Auswahl wird der Datentyp als Badge angezeigt; bei numerischen Widgets (`single_value`, `history_chart`, `indicator_lamp`, `aggregate`, `gauge_bar`) werden numerische Felder (`float`, `integer`) hervorgehoben bzw. nicht-numerische Felder (`string`, `boolean`) gekennzeichnet/optional filterbar gemacht.
  - **Explizites Status- & Fehler-Feedback:** Lade-Spinner während laufender Abfragen, verständliche Fehlermeldung mit **Neu-Laden-Button** bei Netzwerk-/Auth-/Query-Fehlern (niemals Fehler still verschlucken!).
- **Verzeichnisstruktur im Root:**
  - `lib/`: Flutter-Quellcode (`domain/`, `data/`, `presentation/`, `core/`)
  - `test/`: Permanente Dart Unit- & Widget-Test-Suite (spiegelt `lib/`)
  - `integration_test/`: End-to-End Integrationstests der Flutter-App
  - `android/`: Android-Projekt inkl. Glance-Widgets und JUnit-Tests unter `android/app/src/test/`
  - `ios/`: iOS-Projekt inkl. WidgetKit-Extension und XCTests
  - `fixtures/influx/`: Sprachübergreifende InfluxDB-Response-Fixtures für Dart-, Kotlin- und Swift-Tests
  - `docs/`: Verbindliche Projektdokumentation (`architecture.md`, `testing.md`, `code-style.md`, `conventions.md`, `project-brief.md`)
  - `Roadmap/`: Projektorganisation und Task-Steuerung

### 3.3 Konventionen & Best Practices
- **TDD (Test-Driven Development) ist Pflicht:** Zuerst fehlschlagenden Test schreiben (Red), dann minimalen Produktionscode (Green), dann Refactoring. Maximal 3 Reparaturversuche pro fehlschlagendem Test, danach Stopp & Bericht.
- **Schutz bestehender Tests (`AGENTS.md` Regel 1):** Bestehende Tests niemals eigenmächtig löschen, abschwächen oder ändern, um grün zu werden! Falls ein bestehender UI-Test (z. B. `test/e2e_dashboard_flow_test.dart` oder `test/presentation/screens/editor/widget_editor_screen_test.dart`) wegen des bewussten UI-Wechsels von Textfeld auf Bottom-Sheet-Picker angepasst werden müsste, entweder den Fallback/Selektor abwärtskompatibel halten oder **zuvor dem Nutzer erklären warum und Freigabe einholen**.
- **Code-Style & Linter:**
  - `dart format --set-exit-if-changed .` und `flutter analyze`
  - `cd android && ./gradlew :app:ktlintCheck`
  - `swiftlint` (in CI)
- **Doku-Aktualität:** Änderungen an Architektur, Befehlen oder Konventionen müssen sofort in `docs/` UND `Roadmap/README.md` aktualisiert werden.

### 3.4 Meilenstein 3: Formel-Engine & Multi-Source Berechnung
- **Erweiterter Kontrakt (`widget_definitions_v1`):**
  - Optionale Felder: `formula` (`String?`) und `formulaVariables` (`List<FormulaVariable>?`).
  - Jede `FormulaVariable` definiert `name` (`A`, `B`, ...), optionales `measurement` (Fallback auf Widget-Measurement), `field`, optionale `tagFilters` und optionales `label`.
  - Abwärtskompatibel: Fehlt `formula`, verhält sich jedes Widget exakt wie bisher.
- **Cross-Platform Mathe-Evaluator:**
  - Tokenizer + Parser/Evaluator (Shunting-Yard / AST) für `+`, `-`, `*`, `/`, `(...)`, Unärminus und Dezimalzahlen in **Dart**, **Kotlin** und **Swift**.
  - Identische Auswertung und Tests über `fixtures/formula/evaluator_cases.json`.
- **Fehlerbehandlung:**
  - Niemals stiller Fallback auf `0.0`. Division durch 0 oder fehlende Sensorwerte führen zu expliziten Fehlerzuständen, die sowohl im Flutter-Dashboard als auch auf den Android Glance & iOS WidgetKit Widgets gut lesbar signalisiert werden.

### 3.5 Meilenstein 4: Geplante Kontrakt-Erweiterungen (alle optional, `schemaVersion` bleibt 1)
- `formulaSteps` (`name`, `expression`, `label?`): Zwischenformeln, auch je Multi-Value-Item (`formula`, `formulaVariables`, `formulaSteps` je `SensorQueryItem`).
- `gapPolicy` (`skip` | `previous`): Lückenbehandlung der Zeit-Buckets.
- `chartStyle` (`colorStops [{value,color}]`, `fillArea`, `showGrid`, `showAxes`, `markMinMax`, `lineWidth`) und `appearance` (`backgroundColor`, `backgroundOpacity`, `textColor`, `accentColor`, `fontScale`, `cornerRadius`).
- Jede Kontrakt-Änderung ändert Dart, Kotlin, Swift und Fixtures im selben Task. Alte Widget-JSONs müssen unverändert funktionieren.
- Testordner dieses Flutter-Projekts ist `test/` (plus `integration_test/`, `android/app/src/test/`, `ios/`); ein Ordner `tests/` existiert bewusst nicht.
- Gradient/Bitmap auf Android Glance ist ein bekanntes technisches Risiko (Bitmap-Größe in RemoteViews), siehe `Task_30`.

---

## 4. Auffälligkeiten & Details

* **InfluxDB v2 & v1-Kompatibilitäts-API (`/query`):**
  - InfluxDB v2 nutzt intern **Buckets** und stellt InfluxQL (`SHOW MEASUREMENTS`, `SHOW FIELD KEYS`, `SELECT ...`) über **DBRP-Mappings** (Database & Retention Policy, meist automatisch als virtuelles Mapping mit Bucket-Name) bereit.
  - Wichtig: Bei fehlendem DBRP-Mapping oder falschem Bucket-Namen antwortet InfluxDB v2 auf `/query` oft mit **HTTP 200 OK**, legt den Fehler aber in `results[0].error` ab (z. B. `"database not found: my_bucket"`). Sowohl `testConnection` als auch die Schema-Discovery müssen Statement-Level-Errors sauber erkennen und dem Nutzer einen hilfreichen Hinweis (Bucket-Name / DBRP-Mapping prüfen) anzeigen!
* **Sicherheit & Zugriffsschutz:**
  - Das Repository ist öffentlich (MIT). **Niemals** echte Tokens, echte Hostnamen oder Signaturzertifikate committen oder in Logs/UI-Fehlermeldungen ausgeben (`InfluxApiClient.maskToken` konsequent nutzen!).
* **Plattform- / Umgebungs-Besonderheiten:**
  - **Kein lokaler Mac / kein iPhone:** iOS-Code kann lokal auf Windows nicht kompiliert oder getestet werden. Behaupte niemals, iOS-Code sei verifiziert, solange CI ihn nicht ausgeführt hat!
  - **Markenrecht:** Vermeide „Influx“ oder „InfluxDB“ im sichtbaren App-Namen und Store-Listing (Anzeigename: `Sensor Widgets`).
* **Keine neuen Dependencies ohne Rückfrage:**
  - Alle neuen UI-Komponenten (`SearchableSchemaPicker`, Bottom-Sheets, Chips, Filter) werden mit reinem Flutter Material 3 (`flutter/material.dart`) und `flutter_riverpod` ohne externe Zusatzpakete umgesetzt.
