> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_03.md` ➔ `RUN_Task_03.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_03: Dart InfluxQL Query-Builder, Response-Parser & HTTP-Client (mit Schema-Discovery)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung der gesamten InfluxDB-Kommunikationsschicht in Dart: deterministischer InfluxQL-Query-Builder (für alle 6 Widget-Typen + Schema-Discovery), JSON-Response-Parser gegen die gemeinsamen Fixtures aus `fixtures/influx/` sowie v1-kompatibler HTTP-Client (`/query`).
- **Erwartetes Ergebnis:** Vollständig unittested Dart-Services, die der Flutter-App Verbindungstests, Schema-Discovery (Measurements, Fields, Tags) und Live-Vorschauen im Widget-Konfigurator ermöglichen.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` und `Task_02` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/data/influx/influxql_query_builder.dart`
  - `lib/data/influx/influx_response_parser.dart`
  - `lib/data/influx/influx_api_client.dart`
  - `lib/domain/errors/influx_exception.dart`
  - `test/data/influx/influxql_query_builder_test.dart`
  - `test/data/influx/influx_response_parser_test.dart`
  - `test/data/influx/influx_api_client_test.dart`
- **Relevante globale Infos:** Siehe `../README.md` und `fixtures/influx/`. Die hier definierten InfluxQL-Query-Muster dienen als Referenz für Kotlin (`Task_07`) und Swift (`Task_09`).

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_03.md` umbenennen.
   - [ ] Learnings aus `Task_02` (insb. Fixture-Namen und Domain-Modelle) lesen.
2. **InfluxQL Query-Builder per TDD (`InfluxQlQueryBuilder`):**
   - [ ] **Red:** Schreibe `test/data/influx/influxql_query_builder_test.dart` für:
     - Einzelwert / Indikatorlampe / Gauge (`SELECT "<field>" FROM "<measurement>" WHERE <tag_filters> ORDER BY time DESC LIMIT 1`)
     - Verlaufsdiagramm (`SELECT MEAN("<field>") FROM "<measurement>" WHERE time > now() - <range> AND <tag_filters> GROUP BY time(<bucketInterval>) fill(none)`)
     - Aggregat (`SELECT MIN("<field>") AS "min", MAX("<field>") AS "max", MEAN("<field>") AS "mean" FROM "<measurement>" WHERE time > now() - <range> ...`)
     - Multi-Value (Sammelabfrage oder Semikolon-separierte Multi-Statement-Query `q=SELECT ...; SELECT ...`)
     - Schema-Discovery (`SHOW MEASUREMENTS`, `SHOW FIELD KEYS FROM "<m>"`, `SHOW TAG KEYS FROM "<m>"`, `SHOW TAG VALUES FROM "<m>" WITH KEY = "<k>"`)
     - Escaping von Anführungszeichen (`"` in Identifiern, `'` in Tag-String-Werten) zur Verhinderung von fehlerhaften Queries / Injection.
   - [ ] **Green:** Implementiere `InfluxQlQueryBuilder` in `lib/data/influx/influxql_query_builder.dart`.
3. **InfluxDB Response-Parser per TDD (`InfluxResponseParser`):**
   - [ ] **Red:** Schreibe `test/data/influx/influx_response_parser_test.dart`, der **alle** Dateien aus `fixtures/influx/*.json` lädt und prüft (Single Value, Time Series, Multi-Series, Aggregates, Schema-Listen, Empty Result, Query Error, ungültiges JSON).
   - [ ] **Green:** Implementiere `InfluxResponseParser` und typisierte Fehlerklassen in `lib/domain/errors/influx_exception.dart`.
4. **InfluxDB HTTP-Client per TDD (`InfluxApiClient`):**
   - [ ] **Red:** Schreibe `test/data/influx/influx_api_client_test.dart` mit gemocktem `http.Client` (`mocktail`):
     - Prüft korrekten Aufruf von `<baseUrl>/query?db=<database>&q=<query>&epoch=ms`
     - Prüft Header `Authorization: Token <token>` und `Accept: application/json`
     - Prüft Fehlerbehandlung für HTTP 401/403 (Auth-Fehler), 404, 500, Netzwerk-/Timeout-Fehler sowie die strikte Redaction des Tokens in sämtlichen geworfenen Exceptions!
   - [ ] **Green:** Implementiere `InfluxApiClient` in `lib/data/influx/influx_api_client.dart`.
   - [ ] **Refactor:** Dokumentiere die exakten InfluxQL-Query-Templates in `Roadmap/README.md`, damit `Task_07` (Kotlin) und `Task_09` (Swift) identische Queries erzeugen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] Alle Fixtures aus `fixtures/influx/` werden fehlerfrei geparst.
  - [x] Bei Fehlern wird niemals der `Authorization`-Header oder das API-Token in Exception-Messages geleakt.
  - [x] Schema-Discovery-Methoden (`fetchMeasurements`, `fetchFieldKeys`, `fetchTagKeys`, `fetchTagValues`) und `testConnection()` funktionieren zuverlässig.
- **Testing-Pflicht (`test/`):**
  - [x] 100 % der Query-Typen und Fehlerpfade sind durch Unit-Tests unter `test/data/influx/` abgedeckt (keine Live-Netzwerkaufrufe in Tests!).
  - [x] `flutter test`, `dart format --set-exit-if-changed .` und `flutter analyze` laufen fehlerfrei.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse (insb. exakte InfluxQL-Query-Strings für Kotlin/Swift) in Sektion 6 und `Roadmap/README.md` dokumentiert.
- [x] Folge-Tasks in `Roadmap/Tasks/` geprüft und aktualisiert.
- [x] Datei umbenennen (`RUN_Task_03.md` ➔ `Task_03.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `InfluxQlQueryBuilder` baut standardisierte, deterministische InfluxQL v1-Queries mit alphabetisch sortierten Tag-Filtern und String/Identifier-Escaping (`\"` für Identifier, `\'` für Tag-Werte).
  - `InfluxResponseParser` deckt alle 6 Widget-Typen sowie Schema-Discovery ab und toleriert fehlende oder leere Zeitreihen ohne Laufzeitabstürze.
  - `InfluxApiClient` maskiert API-Tokens konsequent mit `***` in allen Fehlermeldungen und Exceptions (`InfluxAuthException`, `InfluxNetworkException`, `InfluxQueryException`, `InfluxParseException`).
- **Stolpersteine & gelöste Probleme:**
  - Tag-Filter müssen alphabetisch sortiert werden, damit Queries sprachübergreifend deterministisch und testbar sind.
- **Wichtige Hinweise für die Folge-Tasks:**
  - `Task_04` (Persistenz & Bridge-Layer) kann nun `InfluxApiClient` für Verbindungstests und Token-Persistenz einbinden.
  - Die InfluxQL-Muster in `Roadmap/README.md` müssen 1:1 in Kotlin (`Task_07`) und Swift (`Task_09`) übernommen werden.
