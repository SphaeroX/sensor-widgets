> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_01.md` ➔ `RUN_Task_01.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_01: Projekt-Scaffolding, Toolchain-Pinning & CI/CD-Grundgerüst

## 1. Ziel & Zweck des Tasks
- **Fokus:** Initialisierung des Flutter-Projekts (`sensor_widgets`) für Android und iOS im Repository-Root, Zusammenführung bestehender Konfigurationsdateien, Einbindung der vereinbarten Kern-Dependencies, Einrichtung der Linter (`flutter analyze`, `ktlint`, `swiftlint`) sowie Aufbau der GitHub Actions CI-Pipeline (inkl. macOS-Runner für iOS).
- **Erwartetes Ergebnis:** Ein lauffähiges, sauber gelintetes Grundgerüst mit verifizierten Kommandozeilen-Befehlen, dokumentierten SDK-/Package-Versionen in `docs/architecture.md` und einem ersten grünen Smoke-Test in `test/`.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** Keine (Start-Task der Roadmap)
- **Betroffene Komponenten / Dateien:**
  - `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.editorconfig`, `.swiftlint.yml`
  - `lib/main.dart`, `lib/app.dart`
  - `test/app_smoke_test.dart`
  - `android/build.gradle(.kts)`, `android/app/build.gradle(.kts)`
  - `ios/` (Basis-Setup für iOS 17.0+)
  - `.github/workflows/ci.yml`
  - `docs/architecture.md`, `docs/testing.md`, `docs/code-style.md`, `AGENTS.md`
- **Relevante globale Infos:** Siehe `../README.md` sowie `docs/architecture.md` ("First implementation step").

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung & Sicherung bestehender Dateien:**
   - [ ] Datei in `RUN_Task_01.md` umbenennen.
   - [ ] Bestehende `.gitignore`, `.editorconfig` und ggf. `analysis_options.yaml` prüfen/sichern, damit sie durch `flutter create` nicht ungewollt überschrieben werden.
2. **Flutter-Scaffolding & Plattform-Konfiguration:**
   - [ ] `flutter create --project-name sensor_widgets --org io.github.mgasc --platforms android,ios .` ausführen (oder Package-ID auf `io.github.mgasc.influx_sensor_widgets` in `android/app/build.gradle*` und `ios/` setzen).
   - [ ] `.gitignore` und `analysis_options.yaml` sauber zusammenführen (strikte Dart-Linter-Regeln aktivieren).
   - [ ] Android `minSdk` auf `26` setzen; iOS Deployment Target in `ios/Podfile` / Projekt auf `17.0` setzen.
3. **Kern-Dependencies einbinden (`pubspec.yaml`):**
   - [ ] Produktions-Dependencies hinzufügen: `flutter_riverpod`, `home_widget`, `flutter_secure_storage`, `http`.
   - [ ] Dev-Dependencies hinzufügen: `mocktail`, `flutter_lints`.
   - [ ] `flutter pub get` ausführen und exakte Versionen prüfen.
4. **Linter & CI/CD einrichten:**
   - [ ] `.swiftlint.yml` im Root anlegen (Regeln für `ios/`).
   - [ ] `ktlint` in Gradle (oder per CLI-Step) für `android/**/*.kt` konfigurieren und JUnit-Target in `android/app/build.gradle*` sicherstellen.
   - [ ] `.github/workflows/ci.yml` erstellen mit 3 Jobs:
     1. `dart`: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`
     2. `android`: `cd android && ./gradlew test` sowie `ktlint`
     3. `ios` (auf `macos-latest`): `swiftlint`, `flutter build ios --simulator --no-codesign` und `xcodebuild test` Vorbereitung.
5. **TDD Smoke-Test & Basis-App-Shell:**
   - [ ] **Red:** Schreibe `test/app_smoke_test.dart`, der prüft, dass `ProviderScope` und `SensorWidgetsApp` fehlerfrei starten und den App-Titel `Sensor Widgets` rendern.
   - [ ] **Green:** Implementiere die minimale `SensorWidgetsApp` in `lib/app.dart` und `lib/main.dart`.
   - [ ] **Refactor:** Entferne den generierten Counter-Boilerplate-Code vollständig.
6. **Dokumentation aktualisieren:**
   - [ ] Gepinnte Flutter-SDK-Version, Package-Versionen, Bundle-ID und verifizierte Test-/Linter-Befehle in `docs/architecture.md`, `docs/testing.md`, `docs/code-style.md` und `/AGENTS.md` eintragen (Hinweise `> Unverified` dort entfernen, wo lokal verifiziert).

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] App kompiliert für Dart/Android mit `io.github.mgasc.influx_sensor_widgets` und `minSdk 26`.
  - [ ] Alle vereinbarten Kern-Dependencies sind in `pubspec.yaml` installiert.
  - [ ] `.github/workflows/ci.yml` ist vollständig und syntaktisch valide.
- **Testing-Pflicht:**
  - [ ] `flutter test test/app_smoke_test.dart` läuft grün.
  - [ ] `dart format --set-exit-if-changed .` und `flutter analyze` melden 0 Fehler/Warnungen.
  - [ ] `cd android && ./gradlew test` läuft fehlerfrei durch.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` und `android/` sind grün.
- [x] `docs/` wurde mit den verifizierten Befehlen und gepinnten Versionen aktualisiert.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und bei Bedarf aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_01.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - Flutter 3.47.9 und Dart 3.13.7 sowie OpenJDK 17 wurden eingerichtet.
  - Namespace und Application ID wurden einheitlich auf `io.github.mgasc.influx_sensor_widgets` gesetzt (in `android/app/build.gradle.kts` und `ios/Runner.xcodeproj/project.pbxproj`).
  - Android `minSdk` wurde auf 26 gesetzt, iOS `IPHONEOS_DEPLOYMENT_TARGET` auf 17.0.
  - CI-Workflows eingerichtet: `.github/workflows/ci.yml` (Dart, Android JUnit + ktlint + APK build, iOS Simulator build) und `.github/workflows/release.yml` (automatischer Release-APK Build, SHA256-Checksummen, Artifact-Upload und GitHub Release Veröffentlichung).
- **Stolpersteine & gelöste Probleme:**
  - `ktlint` bemängelt standardmäßig Unterstriche in Package-Namen (`standard:package-name`). In `.editorconfig` wurde `ktlint_standard_package-name = disabled` hinzugefügt, da die Application ID `io.github.mgasc.influx_sensor_widgets` fest vereinbart ist.
  - Gradle benötigt `sdk.dir` in `android/local.properties` oder `ANDROID_HOME`.
- **Wichtige Hinweise für die Folge-Tasks:**
  - In `Task_02` können die JSON-Fixtures und Schemas unter `fixtures/influx/` definiert werden.
  - Die Linter-Befehle `dart format --set-exit-if-changed .`, `flutter analyze` und `cd android && ./gradlew test :app:ktlintCheck` sind voll verifiziert und müssen vor jedem Task-Abschluss grün sein.
