> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_10.md` ➔ `RUN_Task_10.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `integration_test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_10: End-to-End Integrationstests, Offline-Resilienz, Security-Audit & Production-Polish

## 1. Ziel & Zweck des Tasks
- **Fokus:** Abschluss der Production-Implementierung durch End-to-End-Integrationstests des gesamten App-Flows, Härtung von Edge-Cases (Offline-Caching, Export/Import bzw. Backup der Widget-Definitionen ohne Tokens, Token-Redaction-Audit across Dart/Kotlin/Swift), vollständige Linter-/Test-Abnahme und finale Synchronisation aller Dokumente in `docs/` sowie `README.md`.
- **Erwartetes Ergebnis:** Ein produktionsreifes, vollständig getestetes und lückenlos dokumentiertes Open-Source-Repository.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_09` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `integration_test/app_e2e_test.dart`
  - `test/core/security/token_redaction_audit_test.dart`
  - `test/core/contract/cross_platform_schema_contract_test.dart`
  - `docs/architecture.md`, `docs/testing.md`, `docs/code-style.md`, `docs/conventions.md`, `docs/project-brief.md`
  - `README.md` (Projekt-Root für Open-Source-Nutzer & Entwickler)
  - `Roadmap/README.md`
- **Relevante globale Infos:** Siehe `../README.md` und `/AGENTS.md`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [x] Datei in `RUN_Task_10.md` umbenennen.
   - [x] Alle Learnings aus `Task_01` bis `Task_09` im Ordner `Roadmap/Archiv/` sichten.
2. **Cross-Platform-Kontrakt- & Security-Tests per TDD:**
   - [x] **Red:** Schreibe `test/core/security/token_redaction_audit_test.dart` und `test/core/contract/cross_platform_schema_contract_test.dart`:
     - Prüft, dass bei keinem Exception-Typ, keinem `toString()` und keinem JSON-Export im Shared Storage ein API-Token im Klartext enthalten ist.
     - Prüft, dass die Storage-Keys und JSON-Feldnamen in Dart (`lib/core/constants/storage_keys.dart`), Kotlin (`WidgetStorageReader.kt`) und Swift (`SharedGroupStorage.swift`) zu 100 % übereinstimmen!
   - [x] **Green:** Behebe etwaige Abweichungen sofort in allen Schichten.
3. **End-to-End Flow-Tests (`integration_test/` & umfassender Flow-Test in `test/`):**
   - [x] **Red:** Schreibe `integration_test/app_e2e_test.dart` (sowie einen ohne Emulator ausführbaren Full-App-Flow-Test in `test/e2e_dashboard_flow_test.dart`):
     - App starten (leerer Zustand) ➔ Verbindung anlegen & testen ➔ alle 6 Widget-Typen nacheinander über den Konfigurator erstellen (inkl. Schema-Discovery & Live-Vorschau) ➔ prüfen, dass das resultierende JSON im `SharedWidgetStore` valide ist und der Refresh-Trigger ausgelöst wurde.
   - [x] **Green:** Stelle sicher, dass der gesamte Flow reibungslos durchläuft.
4. **Dokumentation & Release-Readiness abschließen:**
   - [x] Aktualisiere alle Dateien in `docs/` (`architecture.md`, `testing.md`, `code-style.md`, `conventions.md`, `project-brief.md`), sodass keine veralteten "Open decisions" oder "Unverified"-Blöcke mehr offen sind (außer explizit als CI-only markierten iOS-Befehlen).
   - [x] Erstelle eine übersichtliche Root-`README.md` (Setup, Architektur-Überblick, unterstützte InfluxDB-Versionen, Widget-Typen, Lizenz-Hinweis MIT).
   - [x] Führe alle lokalen Qualitäts-Checks aus:
     - `dart format --set-exit-if-changed .`
     - `flutter analyze`
     - `flutter test`
     - `cd android && ./gradlew test`
     - `ktlint "android/**/*.kt"`

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] End-to-End-Konfigurationsflow für Verbindungen und alle 6 Widget-Typen läuft fehlerfrei.
  - [x] Cross-Platform-Kontrakt-Test bestätigt identische Storage-Keys und JSON-Strukturen in Dart, Kotlin und Swift.
  - [x] Alle Dokumente in `docs/` spiegeln den finalen Stand der Anwendung wider.
- **Testing-Pflicht:**
  - [x] Gesamte Dart-Test-Suite (`flutter test`) und Android-Test-Suite (`cd android && ./gradlew test`) sind zu 100 % grün.
  - [x] Alle Linter und Formatter laufen ohne Warnungen oder Fehler durch.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/`, `integration_test/` und `android/app/src/test/` sind grün.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] `Roadmap/README.md` auf `10 / 10 Tasks abgeschlossen` aktualisiert.
- [x] Datei umbenennen (`RUN_Task_10.md` ➔ `Task_10.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **Wichtige Architekturentscheidungen & Details:**
  - Cross-Platform-Kontrakt-Tests (`test/core/contract/cross_platform_schema_contract_test.dart`) verifizieren statisch und dynamisch, dass alle Storage-Keys (`widget_definitions_v1`, `connections_metadata_v1`, `influx_token_`, `widget_cache_`), App-Group-IDs und Schema-v1-Envelope-Formate zwischen Dart, Kotlin (`WidgetStorageReader.kt`) und Swift (`SharedGroupStorage.swift`) 1:1 identisch sind.
  - Security-Audit-Tests (`test/core/security/token_redaction_audit_test.dart`) sichern ab, dass niemals API-Tokens in unverschlüsselten JSON-Objekten, `toString()`-Ausgaben oder Fehlermeldungen auftauchen (`***` Redaction).
  - Der Release-Build (`flutter build apk --release`) wurde erfolgreich lokal gebaut (50.3MB APK) und in GitHub Actions (`.github/workflows/release.yml`) so automatisiert, dass Tags (`v*.*.*`) und manuelle Dispatches fertige APKs mit SHA256-Checksums als Release-Assets bereitstellen.
- **Stolpersteine & gelöste Probleme:**
  - Redundanter Widget-Refresh: Sowohl `WidgetDefinitionRepository._saveWidgetsEnvelope` als auch `WidgetsController.saveWidget` riefen `notifyWidgetsUpdated()` auf. Die Bereinigung stellt sicher, dass Native Widget Updates exakt einmal pro Mutation getriggert werden.
  - State-Synchronisation: `ConnectionsController` aktualisiert nun `state = AsyncValue.data(...)` direkt nach Speichern/Löschen, wodurch Dashboard und Connection-Listen sofort ohne Verzögerung reagieren.
- **Wichtige Hinweise für zukünftige Releases:**
  - Für GitHub Releases: Einfach einen Git-Tag erstellen und pushen (z. B. `git tag v1.0.0 && git push origin v1.0.0`), woraufhin der Release-Workflow automatisch die signierte/release-geprüfte APK baut, die Checksumme errechnet und das GitHub Release publiziert.
  - Optionaler nächster Schritt für Play Store / App Store: Signing-Schlüssel konfigurieren (`android/key.properties` bzw. Apple Developer Distribution Profil).
