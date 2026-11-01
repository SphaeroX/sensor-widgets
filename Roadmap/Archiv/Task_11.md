> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_11.md` ➔ `RUN_Task_11.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_11: Schema-Modelle (`InfluxFieldInfo` / `fieldType`) & InfluxDB-v2-Fehlerdiagnose

## 1. Ziel & Zweck des Tasks
- **Fokus:** Erweiterung der Domain- und Influx-Datenschicht um typisierte Feld-Metadaten (`fieldKey` + `fieldType` aus `SHOW FIELD KEYS`), verlässliche Erkennung von InfluxDB-Statement-Fehlern (insbesondere fehlende InfluxDB-v2-DBRP-Mappings bei HTTP 200 mit `results[0].error`) in `testConnection` sowie verständliche, token-maskierte Fehlermeldungen für die UI.
- **Erwartetes Ergebnis:** `InfluxFieldInfo`, erweiterter `InfluxResponseParser.parseFieldInfos`, `InfluxApiClient.fetchFieldInfos`, gehärtetes `InfluxApiClient.testConnection` und `InfluxErrorFormatter` – vollständig per TDD getestet und zu 100 % abwärtskompatibel zu allen bestehenden Tests.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_10` sind abgeschlossen und unter `Roadmap/Archiv/` archiviert.
- **Betroffene Komponenten / Dateien:**
  - `lib/domain/models/influx_field_info.dart` *(neu)*
  - `lib/domain/errors/influx_error_formatter.dart` *(neu)*
  - `lib/data/influx/influx_response_parser.dart`
  - `lib/data/influx/influx_api_client.dart`
  - `test/domain/models/influx_field_info_test.dart` *(neu)*
  - `test/domain/errors/influx_error_formatter_test.dart` *(neu)*
  - `test/data/influx/influx_response_parser_test.dart`
  - `test/data/influx/influx_api_client_test.dart`
- **Relevante globale Infos:** Siehe `../README.md` (Kapitel 3 & 4: InfluxDB v2 DBRP-Besonderheit & Token-Redaction).

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [x] Datei in `RUN_Task_11.md` umbenennen.
   - [x] Bestehende Implementierungen in `lib/data/influx/` sowie Fixtures unter `fixtures/influx/show_field_keys_response.json` und `fixtures/influx/error_query_response.json` sichten.
2. **Domain-Modell `InfluxFieldInfo` per TDD:**
   - [x] **Red:** Schreibe Unit-Tests in `test/domain/models/influx_field_info_test.dart`:
     - Speichert `key` (z. B. `'temperature'`) und `type` (normalisiert lowercase, z. B. `'float'`, `'integer'`, `'unsigned'`, `'boolean'`, `'string'`, Fallback `'unknown'`).
     - Getter `bool get isNumeric` liefert `true` für `'float'`, `'integer'`, `'unsigned'` (sowie `'unknown'`, damit Felder ohne bekannten Typ nicht fälschlich als inkompatibel blockiert werden) und `false` für `'string'` und `'boolean'`.
     - Wertgleichheit (`==`, `hashCode`) und lesbares `toString()`.
   - [x] **Green:** Implementiere `lib/domain/models/influx_field_info.dart`.
3. **Parser-Erweiterung `parseFieldInfos` per TDD:**
   - [x] **Red:** Ergänze Tests in `test/data/influx/influx_response_parser_test.dart`:
     - `parseFieldInfos` liest `fixtures/influx/show_field_keys_response.json` und liefert `InfluxFieldInfo(key: 'co2', type: 'float')`, `humidity`, `pressure`, `temperature`.
     - Behandelt Antworten mit gemischten Typen (`float`, `integer`, `string`, `boolean`), fehlender `fieldType`-Spalte (`type: 'unknown'`) sowie leere `series` (`[]`) und Statement-Errors (`InfluxQueryException`).
     - Bestehendes `parseFieldKeys` bleibt unverändert erhalten!
   - [x] **Green:** Implementiere `parseFieldInfos` in `lib/data/influx/influx_response_parser.dart`.
4. **Client-Erweiterung (`fetchFieldInfos` & `testConnection` Statement-Error-Check) per TDD:**
   - [x] **Red:** Ergänze Tests in `test/data/influx/influx_api_client_test.dart`:
     - `fetchFieldInfos` sendet `SHOW FIELD KEYS FROM "<measurement>"` und gibt `List<InfluxFieldInfo>` zurück.
     - `testConnection` gibt bei HTTP 200 mit leerem Ergebnis (`{"results": [{"statement_id": 0}]}`) weiterhin `true` zurück (**Abwärtskompatibilität zum bestehenden Test wahren!**), wirft aber bei einem InfluxDB-Statement-Error (`{"results": [{"statement_id": 0, "error": "database not found: my_bucket"}]}`) eine `InfluxQueryException` (mit maskiertem Token).
   - [x] **Green:** Implementiere `fetchFieldInfos` und nutze `_responseParser.parseMeasurements(json)` (bzw. Error-Check) in `testConnection` innerhalb von `lib/data/influx/influx_api_client.dart`.
5. **Benutzerfreundliche Fehlerdiagnose (`InfluxErrorFormatter`) per TDD:**
   - [x] **Red:** Schreibe Unit-Tests in `test/domain/errors/influx_error_formatter_test.dart`:
     - Übersetzt `InfluxAuthException` in verständlichen deutschen Hinweis (Token / Leseberechtigung für Bucket prüfen).
     - Übersetzt `InfluxQueryException` mit `"database not found"` in einen gezielten Hinweis für InfluxDB v2 (Bucket-Name prüfen bzw. v1-DBRP-Mapping für den Bucket sicherstellen).
     - Übersetzt `InfluxNotFoundException` und `InfluxNetworkException` in klare URL-/Erreichbarkeits-Hinweise.
     - Stellt sicher, dass niemals ein übergebenes Token im formatierten Text auftaucht.
   - [x] **Green:** Implementiere `lib/domain/errors/influx_error_formatter.dart`.
   - [x] **Refactor:** Code formatieren und Linter prüfen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] `SHOW FIELD KEYS` liefert über `fetchFieldInfos` sowohl Feldnamen als auch Influx-Datentypen (`InfluxFieldInfo`).
  - [x] `testConnection` erkennt Statement-Fehler in HTTP-200-Antworten zuverlässig, akzeptiert aber weiterhin leere valide Datenbanken/Buckets.
  - [x] `InfluxErrorFormatter` erzeugt für alle Fehlerfälle benutzerfreundliche deutsche Meldungen inkl. InfluxDB-v2-DBRP-Hinweis ohne Token-Leak.
- **Testing-Pflicht (im Ordner `test/`):**
  - [x] Neue und erweiterte Unit-Tests unter `test/domain/` und `test/data/influx/` sind grün.
  - [x] Kein bestehender Test wurde gelöscht oder abgeschwächt (`AGENTS.md` Regel 1).
  - [x] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` laufen mit 0 Fehlern durch.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] Folge-Tasks in `Roadmap/Tasks/` (`Task_12`–`Task_15`), `Roadmap/README.md` und ggf. `docs/` geprüft und bei Bedarf aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_11.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `InfluxFieldInfo` (`lib/domain/models/influx_field_info.dart`) speichert `key` und `type`. Um `const` Konstruktoren zu unterstützen, wird der rohe String im Feld gespeichert und beim Zugriff über den Getter `type` getrimmt und lowercase normalisiert. `isNumeric` ist `true` für `float`, `integer`, `unsigned` sowie `unknown` (Fallback).
  - `InfluxResponseParser.parseFieldInfos(Map<String, dynamic> json)` wertet `columns` (`fieldKey`, `fieldType`) aus und baut die typisierte Liste. `parseFieldKeys` bleibt parallel für volle Abwärtskompatibilität erhalten.
  - `InfluxApiClient.fetchFieldInfos(...)` führt `SHOW FIELD KEYS FROM "<m>"` aus und gibt `List<InfluxFieldInfo>` zurück.
  - `InfluxApiClient.testConnection(...)` ruft intern `_responseParser.parseMeasurements(json)` auf, sodass InfluxDB v2 HTTP-200-Statement-Fehler (`results[0].error`) sauber zu einer `InfluxQueryException` führen. Leere Datenbanken (`results: [{statement_id: 0}]`) geben weiterhin `true` zurück.
  - `InfluxErrorFormatter.format(Object error, {String? token})` (`lib/domain/errors/influx_error_formatter.dart`) liefert präzise deutsche Fehlermeldungen (z. B. DBRP-Mapping-Hinweis bei "database not found") und maskiert Tokens über `maskToken`.
- **Stolpersteine & gelöste Probleme:**
  - In Dart können `const` Konstruktoren keine String-Methoden wie `.trim()` oder `.toLowerCase()` im Initializer ausführen; dies wurde elegant über ein privates Feld `_rawType` und normalisierenden Getter `type` gelöst.
  - `InfluxNetworkException` kann Verbindungsdetails enthalten; `InfluxErrorFormatter` bindet diese Details maskiert ein, damit Benutzer konkrete Netzwerkdiagnosen (z. B. Timeout, Host unreachable) erhalten.
- **Wichtige Hinweise für die Folge-Tasks:**
  - In `Task_12` (`SchemaDiscoveryController`) kann `fetchFieldInfos` aufgerufen werden, um `List<InfluxFieldInfo>` in den State aufzunehmen.
  - Zur Fehleranzeige im UI/Controller `InfluxErrorFormatter.format(e, token: connectionToken)` verwenden.
  - Auf Windows liegt das Flutter SDK unter `C:\Users\MGasc\flutter\bin` (`$env:PATH = "C:\Users\MGasc\flutter\bin;$env:PATH"`).
