# Task_32: Widget-Optik pro Widget (Farben, Hintergrund, Schrift, Rundung) mit Vorschau-Parität

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_32.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Pro Widget lassen sich Optik-Parameter einstellen: Hintergrundfarbe/-transparenz, Akzent- und Textfarbe, Schriftgrößen-Stufe, Eckenrundung, Linienstärke. Android, iOS und die Live-Vorschau im Editor stellen dies gleich dar.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_30 und Task_31 abgeschlossen.
- **Relevantes Vorwissen:** Neuer optionaler Kontrakt-Block `appearance` (`backgroundColor`, `backgroundOpacity`, `textColor`, `accentColor`, `fontScale`, `cornerRadius`). Kontrakt-Änderungen sind rein additiv (neue optionale Felder); `schemaVersion` bleibt 1 und alte Fixtures parsen unverändert. Native Widgets haben plattformbedingte Grenzen (Glance: Corner-Radius je nach Android-Version). iOS-Code ist nur durch einen grünen GitHub-Actions-Lauf verifiziert; lokal wird nichts über iOS behauptet.

## Umfang

**Gehört dazu:**

- Kontrakt, Dart-Modell, Fixtures, Kotlin-/Swift-Parser.
- Editor-Abschnitt „Aussehen“ mit Farbwähler (ohne neues Package, z. B. Palette + Hex-Feld) und Reglern.
- Vorschau-Karte folgt denselben Parametern.
- Native Umsetzung in Glance und SwiftUI mit definierten Defaults (alte Widgets bleiben optisch gleich).

**Gehört nicht dazu:**

- Neue Widget-Typen.
- Chart-Gradient (bereits Task_29/30).

## Umsetzungsschritte

1. Datei in `RUN_Task_32.md` umbenennen.
2. Fixtures und Modell per TDD.
3. Editor-UI und Vorschau per Widget-Test.
4. Kotlin: Mapper-Tests, dann Glance-Umsetzung.
5. Swift: Tests (CI), dann Views.
6. Plattformgrenzen in `docs/architecture.md` dokumentieren.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- Dart: Modell, Editor, Vorschau. Android JUnit: UiStateMapper/Parser. Swift: CI.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Alle `appearance`-Werte werden in Dart, Kotlin und Swift gelesen (Fixture-Tests).
- [ ] Vorschau spiegelt die Einstellungen.
- [ ] Widgets ohne `appearance` sehen aus wie vorher.
- [ ] Plattformgrenzen sind dokumentiert.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Welche Parameter sind dem Nutzer wichtig? Annahme: obige Liste; bei Bedarf vor Beginn mit dem Nutzer abgleichen.

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
