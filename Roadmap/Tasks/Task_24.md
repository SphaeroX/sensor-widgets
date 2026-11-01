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

- [ ] IAQ-Szenario (mehrere Variablen, Zwischenschritte) liefert im Verlaufschart eine berechnete Reihe in Dart-Tests.
- [ ] Lücken werden gemäß `gapPolicy` behandelt, Division durch 0 und fehlende Werte erzeugen sichtbare Fehler.
- [ ] Aggregat/Gauge/Lampe berechnen Formel vor Aggregation, belegt durch Tests.
- [ ] Widgets ohne Formel verhalten sich unverändert (Regressionstests grün).
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Performance/Datenmenge: maximale Bucket-Anzahl pro Abfrage begrenzen (Annahme: 300 Punkte).
- `fill(previous)` ist nicht in jeder InfluxDB-Version identisch; Verhalten gegen v1/v2-Kompatibilitäts-API prüfen.

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
