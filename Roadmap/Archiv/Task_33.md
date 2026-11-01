# Task_33: End-to-End-Verifikation, CI & Dokumentation (Meilenstein 4)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_33.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Meilenstein 4 ist durchgängig abgesichert und dokumentiert: IAQ-Verlaufschart mit Formel, Zeit-Buckets und Gradient als E2E-Szenario, vollständige Test-/Lint-Läufe, aktuelle Doku.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_21 bis Task_32 abgeschlossen.
- **Relevantes Vorwissen:** Vorbild: Task_20 (Archiv). Integrationstests in `integration_test/`, CI-Konfiguration in `.github/workflows/`. iOS-Code ist nur durch einen grünen GitHub-Actions-Lauf verifiziert; lokal wird nichts über iOS behauptet.

## Umfang

**Gehört dazu:**

- E2E-Test: Verlaufschart anlegen, Variablen per Picker wählen, IAQ-Vorlage übernehmen, Gradient konfigurieren, speichern, JSON im Bridge-Storage prüfen.
- Regressionstests für alte Widget-JSONs (v1 aus Meilenstein 1 bis 3).
- CI auf neue Fixtures und Tests prüfen (Android und iOS), CI-Ergebnis für iOS auswerten und festhalten.
- Doku: `docs/architecture.md`, `docs/project-brief.md`, `docs/testing.md`, `Roadmap/README.md` auf Stand bringen.

**Gehört nicht dazu:**

- Neue Features.

## Umsetzungsschritte

1. Datei in `RUN_Task_33.md` umbenennen.
2. Erkenntnisse der Tasks 21 bis 32 sichten.
3. E2E-Test per TDD schreiben.
4. Regressions-Fixtures ergänzen.
5. Komplettlauf: `flutter pub get`, `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`, `cd android && ./gradlew test`, `./gradlew :app:ktlintCheck`.
6. Dokumentation aktualisieren, README: Meilenstein 4 abschließen.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `integration_test/formula_gradient_flow_test.dart` (neu), Regressionstests mit alten Fixtures.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] Alle Suiten, Formatter und Linter laufen ohne Fehler.
- [x] E2E-Szenario grün.
- [x] iOS-Verifikation: CI-Lauf grün oder ehrlich als ausstehend dokumentiert.
- [x] `docs/` und `Roadmap/README.md` sind aktuell.

## Offene Fragen / Annahmen

- Manuelle Geräteprüfung der Gradient-Widgets auf Android liegt beim Nutzer.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** E2E-Test `test/e2e_formula_gradient_flow_test.dart` (headless) plus Geraete-Wrapper `integration_test/formula_gradient_flow_test.dart`; Regressionstests fuer alte Widget-JSONs; `docs/` (project-brief, testing, architecture) und `Roadmap/README.md` aktualisiert. **Der E2E-Test deckte zwei echte Luecken auf:** (1) `FormulaEditorSection` setzte beim Uebernehmen einer Vorlage Controller waehrend des Builds ("setState() called during build"), behoben mit Test `formula_editor_section_external_update_test.dart`; (2) `gapPolicy` war in Dart/Kotlin/Swift umgesetzt, aber im Editor nicht einstellbar, ergaenzt als Karte "Luecken im Verlauf" mit Test `widget_editor_screen_gap_policy_test.dart`.
- **Learnings & Stolpersteine:** Lazy-Listen (Hilfe-Screen) brauchen im Test `scrollUntilVisible` statt `ensureVisible`. Der gesamte Meilenstein ist nur durch Zusammenspiel der drei Plattformen abgesichert; Kotlin laeuft lokal, Swift nur in CI.
- **Wichtige Entscheidungen und ihre Gründe:** Der E2E-Test liegt in `test/` (laeuft ohne Geraet in CI) und wird von `integration_test/` wiederverwendet, analog zum bestehenden Formel-Flow-Test.
- **Auswirkungen auf Folge-Tasks:** Keine offenen Roadmap-Tasks ausser `Task_21`. Offen fuer den Nutzer: (a) `Task_21` Dashboard-Layout-Bug mit Screenshot/Geraetedaten reproduzieren; (b) Entfernen des Typ-Dropdowns `widget_type_dropdown` (nur nach Freigabe fuer die Anpassung dreier bestehender Tests); (c) manuelle Geraetepruefung von Gradient und Optik (Android und iOS).
- **Hinweise zu Tests und Befehlen:** Komplettlauf: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`, `cd android && ./gradlew test :app:ktlintCheck`; iOS und Gesamt-CI: GitHub Actions (`CI`-Workflow).
