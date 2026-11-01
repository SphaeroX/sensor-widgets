# Task_24: Zeit-Bucket-Pipeline (Dart): Formel im Verlaufschart, Aggregat, Gauge, Lampe

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_24.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die Formel funktioniert für Zeitreihen. Beim Verlaufschart werden alle Variablen per `GROUP BY time(Intervall)` in gleiche Zeit-Buckets gemittelt und die Formel je Bucket berechnet. Bei Aggregat, Gauge und Indikatorlampe wird die Formel je Bucket/Zeitpunkt berechnet und danach MIN/MAX/MEAN bzw. Anzeige/Schwellenwert angewendet.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_22 abgeschlossen.
- **Relevantes Vorwissen:** Bestehend: Multi-Source-Abfrage und `FormulaCalculationService` (Task_17, aktuell nur Einzelwert-Pfad). `lib/data/influx/` (Query-Builder, Parser, Client) und die Vorschau in `lib/presentation/widgets/preview/widget_live_preview_card.dart`. Im Verlaufschart haben Variablen verschiedene Zeitstempel (z. B. VOC und CO2 aus unterschiedlichen Measurements), daher Zeit-Buckets.

## Umfang

**Gehört dazu:**

- Query-Builder: je Variable `SELECT mean(field) ... GROUP BY time(Intervall) fill(...)`; Intervall aus `aggregationInterval` bzw. sinnvoller Standard aus `timeRange`.
- Neues optionales Feld `gapPolicy` (`skip` | `previous`), Standard `skip`. Kontrakt-Änderungen sind rein additiv (neue optionale Felder); `schemaVersion` bleibt 1 und alte Fixtures parsen unverändert.
- Zeitreihen-Kombination: Buckets zusammenführen, Formel je Bucket, Bucket mit fehlenden Variablen gemäß `gapPolicy`, Fehler je Bucket sichtbar machen (kein stilles 0).
- Aggregat/Gauge/Lampe: Formel vor Aggregation.
- Live-Vorschau zeigt die berechnete Reihe.

**Gehört nicht dazu:**

- Native Umsetzung (Task_25).
- Formel pro Multi-Value-Zeile (Task_26).
- Editor-UI für Variablen (Task_27).

## Umsetzungsschritte

1. Datei in `RUN_Task_24.md` umbenennen.
2. Bestehende Pipeline und Parser lesen.
3. Tests für Query-Builder (mehrere Variablen, Buckets, fill) schreiben, dann implementieren.
4. Tests für das Zusammenführen der Reihen und `gapPolicy` schreiben, dann implementieren.
5. Aggregat/Gauge/Lampe an die Reihen-Pipeline anbinden.
6. Vorschau-Karte anpassen und Widget-Tests ergänzen.
7. Fixtures `fixtures/influx/` um Mehrfachreihen-Antworten erweitern (für Task_25).

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/data/influx/influx_query_builder_test.dart`, `test/domain/services/formula_calculation_service_test.dart` (Zeitreihen, Lücken, Fehler).
- Widget-Test der Live-Vorschau.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] IAQ-Szenario (mehrere Variablen, Zwischenschritte) liefert im Verlaufschart eine berechnete Reihe in Dart-Tests.
- [x] Lücken werden gemäß `gapPolicy` behandelt, Division durch 0 und fehlende Werte erzeugen sichtbare Fehler.
- [x] Aggregat/Gauge/Lampe berechnen Formel vor Aggregation, belegt durch Tests.
- [x] Widgets ohne Formel verhalten sich unverändert (Regressionstests grün).
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Performance/Datenmenge: maximale Bucket-Anzahl pro Abfrage begrenzen (Annahme: 300 Punkte).
- `fill(previous)` ist nicht in jeder InfluxDB-Version identisch; Verhalten gegen v1/v2-Kompatibilitäts-API prüfen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `DurationUtils`, `InfluxQlQueryBuilder.buildBucketedMultiFieldQuery`, `InfluxResponseParser.parseBucketedFields`, `WidgetDefinition.gapPolicy`, `FormulaCalculationService.calculateSeries/calculateAggregate` (+ `FormulaSeriesResult`, `FormulaBucketError`), Controller (`fetchPreviewData` fuer Verlauf und Aggregat mit Formel), Vorschau-Hinweis fuer fehlerhafte Buckets. Abweichung: `fill(null)` statt `fill(none/previous)` in der Abfrage, Luecken werden in Dart behandelt (versionsunabhaengig). Einzelwert, Lampe und Gauge bleiben beim Letztwert-Pfad (nichts zu aggregieren).
- **Learnings & Stolpersteine:** Der Flutter-Formatter formatiert neue Tests um; nach `dart format .` laufen sie unveraendert. Das Bash-Tool bricht bei Heredocs mit Anfuehrungszeichen/Umlauten ab: Dateien mit dem Write-Tool anlegen.
- **Wichtige Entscheidungen und ihre Gründe:** Maximal 300 Buckets durch Vergroebern des Intervalls statt Fehler. Bucket-Fehler sind nicht fatal solange mindestens ein Bucket gelingt.
- **Auswirkungen auf Folge-Tasks:** Task_25 muss dieselbe Logik in Kotlin und Swift nachbauen (Query, `gapPolicy`, Fixture `bucketed_multi_field_response.json`, Erwartung: skip -> [40, 100], previous -> [40, 50, 100] fuer das IAQ-Beispiel aus `formula_series_service_test.dart`) und `gapPolicy` in den nativen Modellen/Parsern ergaenzen.
- **Hinweise zu Tests und Befehlen:** `flutter test test/domain/services/formula_series_service_test.dart test/data/influx/bucketed_series_test.dart test/core/utils/duration_utils_test.dart`.
