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

- [ ] Alle Suiten, Formatter und Linter laufen ohne Fehler.
- [ ] E2E-Szenario grün.
- [ ] iOS-Verifikation: CI-Lauf grün oder ehrlich als ausstehend dokumentiert.
- [ ] `docs/` und `Roadmap/README.md` sind aktuell.

## Offene Fragen / Annahmen

- Manuelle Geräteprüfung der Gradient-Widgets auf Android liegt beim Nutzer.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):**
- **Learnings & Stolpersteine:**
- **Wichtige Entscheidungen und ihre Gründe:**
- **Auswirkungen auf Folge-Tasks:**
- **Hinweise zu Tests und Befehlen:**
