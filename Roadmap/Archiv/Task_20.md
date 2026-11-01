> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_20.md` ➔ `RUN_Task_20.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`), `android/app/src/test/` oder `ios/` abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_20: End-to-End Verifikation, CI/CD & Dokumentation

## 1. Ziel & Zweck des Tasks
- **Fokus:** Umfassende End-to-End-Qualitätssicherung des gesamten Meilensteins 3 (Lokale Formelberechnung), Regressionstests, Absicherung von Edge-Cases sowie Aktualisierung der Projektdokumentation.
- **Erwartetes Ergebnis:**
  - E2E-Integrationstests in `integration_test/` decken den Erstellungs- und Speicherfluss eines Widgets mit Formelberechnung vollständig ab.
  - Dokumentation in `docs/architecture.md`, `docs/project-brief.md` und `Roadmap/README.md` ist vollständig auf dem Stand des neuen Funktionsumfangs.
  - Komplette Test-Suiten (Dart, Android Gradle, Linter, Formatter) laufen mit 0 Fehlern durch.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_16` bis `Task_19` abgeschlossen.
- **Betroffene Komponenten / Dateien:**
  - `integration_test/formula_widget_flow_test.dart` *(neu)*
  - `docs/architecture.md`
  - `docs/project-brief.md`
  - `Roadmap/README.md`

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_20.md` umbenennen.
   - [ ] Erkenntnisse aus den Tasks 16 bis 19 sichten.
2. **Integrationstests per TDD:**
   - [ ] Erstelle `integration_test/formula_widget_flow_test.dart`:
     - Testet den gesamten Flow: Öffnen des Widget-Editors -> Aktivieren der Formel -> Hinzufügen von Variablen `A` und `B` -> Eingabe Formel `(A + B) / 2` -> Speichern -> Validierung des gespeicherten JSON im Bridge-Storage.
3. **Edge-Case & Robustheits-Tests:**
   - [ ] Negative Zahlen / Minuskombinationen (z. B. `--A`, `A * -1`).
   - [ ] Extrem große/kleine Gleitkommazahlen und Rundung über `decimalPlaces`.
   - [ ] Gleichzeitige Verwendung von Schwellenwerten (`threshold`) bei berechneten Werten.
4. **Dokumentations-Update:**
   - [ ] `docs/architecture.md`: Dokumentation der Formel-Engine (Shunting-Yard, sprachübergreifende Konsistenz, Error Handling).
   - [ ] `docs/project-brief.md`: Aktualisierung des Widget-Katalogs um die Berechnungsoption.
   - [ ] `Roadmap/README.md`: Meilenstein 3 als abgeschlossen dokumentieren.
5. **Abschluss-Verifikation der Toolchain:**
   - [ ] `flutter pub get`
   - [ ] `flutter test`
   - [ ] `flutter analyze`
   - [ ] `dart format --set-exit-if-changed .`
   - [ ] `cd android && ./gradlew test`
   - [ ] `cd android && ./gradlew :app:ktlintCheck`

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- [ ] Alle Test-Suiten (Dart Unit-, Widget-, Integrationstests, Android JUnit) laufen grün durch.
- [ ] Formatter und Linter melden 0 Warnungen und 0 Fehler.
- [ ] Dokumentation in `docs/` und `Roadmap/README.md` ist vollständig aktuell.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests sind grün.
- [ ] Erkenntnisse in Sektion 6 eingetragen.
- [ ] `Roadmap/README.md` Status auf `Erledigt` gesetzt.
- [ ] Datei umbenennen (`RUN_` entfernen) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **End-to-End Verifikation & Robustheit:**
  - `test/formula_widget_flow_test.dart` und `integration_test/formula_widget_flow_test.dart` testen den lückenlosen Ablauf vom Hinzufügen eines Widgets im Dashboard über die Formel-Aktivierung, Variablenkonfiguration (`A`, `B` mit Feldzuweisung und Dialog), Formeleingabe (`A - B`) bis hin zur Speicherung im Shared Storage (`widget_definitions_v1`).
  - Edge-Cases wie Unärminus (`-A`, `-(-A)`), Multiplikation mit negativen Faktoren (`A * -1`), große Zahlenwerte und Division durch Null wurden mit zusätzlichen Tests in `formula_evaluator_test.dart` abgesichert.
  - Dokumentation in `docs/architecture.md`, `docs/project-brief.md` und `Roadmap/README.md` ist vollständig synchronisiert und Meilenstein 3 ist offiziell als erledigt dokumentiert.
