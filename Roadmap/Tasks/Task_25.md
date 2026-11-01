# Task_25: Native Pipeline Android & iOS: Formel für Zeitreihen und alle Typen

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_25.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die Zeit-Bucket-Pipeline aus Task_24 läuft auch in den nativen Widgets (Kotlin/Glance und Swift/WidgetKit). Verlaufschart, Aggregat, Gauge und Lampe zeigen formelberechnete Werte, Fehler werden lesbar angezeigt.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_23 und Task_24 abgeschlossen.
- **Relevantes Vorwissen:** Android: `worker/WidgetRefreshWorker.kt`, `glance/`, `model/`, `storage/`. iOS: `Timeline/SensorTimelineProvider.swift`, `Models/`, `Views/`. iOS-Code ist nur durch einen grünen GitHub-Actions-Lauf verifiziert; lokal wird nichts über iOS behauptet. Gemeinsame Fixtures liefern erwartete Antworten und Ergebnisse.

## Umfang

**Gehört dazu:**

- Kotlin: Query-Builder, Bucket-Zusammenführung, `gapPolicy`, Formelberechnung, UI-State-Mapping.
- Swift: dasselbe im Timeline-Provider und den Views.
- Fehlerzustände je Bucket/Widget lesbar (Fehlerzeile statt Absturz oder 0).
- Fixture-Tests mit denselben Mehrfachreihen-Antworten wie Dart.

**Gehört nicht dazu:**

- Gradient/Styling (Task_29 bis Task_32).
- Multi-Value-Formeln (Task_26).

## Umsetzungsschritte

1. Datei in `RUN_Task_25.md` umbenennen.
2. Fixtures aus Task_24 lesen.
3. Android per TDD umsetzen (Query, Kombination, Mapper).
4. iOS per TDD schreiben (nur CI-verifizierbar).
5. Offline-/Fehlerpfade testen (Netzwerkfehler, leere Reihen, einzelne fehlende Variable).

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `android/app/src/test/...` (QueryBuilder, Worker, UiStateMapper).
- `ios/SensorWidgetsExtensionTests/` (nur CI).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Android-Widgets liefern für das IAQ-Fixture dieselbe Reihe wie Dart (Test belegt).
- [ ] Swift-Code und -Tests sind geschrieben; CI-Ergebnis ist festgehalten oder als ausstehend markiert.
- [ ] Fehlerzustände sind getestet.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Glance-Charts: wie viele Punkte rendert die aktuelle Android-Chart-Darstellung performant? Bucket-Obergrenze aus Task_24 hier gegenprüfen.

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
