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

- [x] Android-Widgets liefern für das IAQ-Fixture dieselbe Reihe wie Dart (Test belegt).
- [x] Swift-Code und -Tests sind geschrieben; CI-Ergebnis ist festgehalten oder als ausstehend markiert.
- [x] Fehlerzustände sind getestet.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Glance-Charts: wie viele Punkte rendert die aktuelle Android-Chart-Darstellung performant? Bucket-Obergrenze aus Task_24 hier gegenprüfen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Android und iOS spiegeln die Dart-Pipeline aus Task_24: Bucket-Query (`fill(null)`), `parseBucketedFields`, `DurationUtils`, `FormulaSeriesCalculator` (`combine`, `aggregate`, `summarizeErrors`), `gapPolicy` im Modell, Worker/Timeline-Provider fuer Verlaufschart und Aggregat mit Formel, Warnzeile bei Teilfehlern. Einzelwert/Lampe/Gauge nutzen weiter den Letztwert-Pfad (Task_19). Kein Rendering-Umbau noetig: Glance/WidgetKit lesen weiter `points`/`aggregates`.
- **Learnings & Stolpersteine:** Windows: `./gradlew test` scheitert wiederholt an Dateisperren in `build/app/intermediates/assets/debug`; vorher `rm -rf build/app/intermediates/assets/debug build/app/test-results` ausfuehren. `./gradlew :app:ktlintFormat` behebt ktlint-Funde automatisch. Die Android-Obergrenze von 300 Buckets wurde nicht auf Glance-Render-Performance geprueft (Chart nutzt normalisierte Punkte, nicht Bitmap pro Punkt); bei Task_30 (Gradient-Bitmap) erneut pruefen.
- **Wichtige Entscheidungen und ihre Gründe:** Gleiche Rundung wie Dart (half away from zero, max 2 Dezimalstellen) in Kotlin und Swift selbst implementiert, nicht `Math.round`.
- **Auswirkungen auf Folge-Tasks:** Task_26 (Multi-Value-Formel pro Zeile) kann `FormulaEvaluator.evaluate(..., steps)` und die Gruppierungslogik der Calculator-Objekte wiederverwenden. Task_29/30 koennen auf `points` im Cache aufbauen.
- **Hinweise zu Tests und Befehlen:** Android: `cd android && ./gradlew test :app:ktlintCheck --offline`. iOS: nur CI (`FormulaSeriesTests`).
