> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_12.md` ➔ `RUN_Task_12.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_12: Reaktiver Schema-Discovery-State (Laden, Fehlerdiagnose & Reload)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Ausbau der Schema-Discovery-Logik von stillschweigend leeren Listen (`catch (_) => []`) hin zu einem expliziten, reaktiven Zustandsmodell für den Widget-Editor: Lade-Status, geladene Einträge (`Measurements`, `InfluxFieldInfo`-Liste, `TagKeys`, `TagValues`), verständliche Fehlermeldung (über `InfluxErrorFormatter`), Race-Condition-Schutz bei schnellem Verbindungs-/Measurement-Wechsel sowie gezielte `reload`-Aktionen.
- **Erwartetes Ergebnis:** Ein sauber getesteter, reaktiver Discovery-State/Controller (Riverpod), der kaskadierendes Laden (`Connection` ➔ `Measurements`, `Measurement` ➔ `Fields` + `TagKeys`, `TagKey` ➔ `TagValues`) und Reloads steuert, während die bestehenden Methoden auf `SchemaDiscoveryController` zu 100 % abwärtskompatibel bleiben.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_11` muss abgeschlossen und in `Roadmap/Archiv/Task_11.md` archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/controllers/schema_discovery_controller.dart`
  - *(optional ergänzend)* `lib/presentation/controllers/schema_discovery_state.dart`
  - `test/presentation/controllers/schema_discovery_controller_test.dart`
- **Relevante globale Infos:** Siehe `../README.md` und Learnings aus `Roadmap/Archiv/Task_11.md`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [x] Datei in `RUN_Task_12.md` umbenennen.
   - [x] Sektion 6 in `Roadmap/Archiv/Task_11.md` sowie die bestehenden Tests in `test/presentation/controllers/schema_discovery_controller_test.dart` und `test/e2e_dashboard_flow_test.dart` lesen.
2. **Typisiertes Zustandsmodell `SchemaListState<T>` & `EditorSchemaState` entwerfen:**
   - [x] Definiere einen generischen, unveränderlichen Zustand `SchemaListState<T>` mit Status (`idle`, `loading`, `loaded`, `error`), `List<T> items` und `String? errorMessage` (inkl. Hilfs-Getter `isLoading`, `hasError`, `isEmptyLoaded`).
   - [x] Definiere den aggregierten Zustand für den Editor (`selectedConnectionId`, `selectedMeasurement`, `measurements: SchemaListState<String>`, `fields: SchemaListState<InfluxFieldInfo>`, `tagKeys: SchemaListState<String>`, `tagValuesByKey: Map<String, SchemaListState<String>>`).
3. **TDD – Unit-Tests für Discovery-Ergebnisse, Kaskade, Reload & Fehlerfälle:**
   - [x] **Red:** Erweitere `test/presentation/controllers/schema_discovery_controller_test.dart` (ohne bestehende Tests zu verändern!):
     - `selectConnection(connectionId)` setzt `measurements` auf `loading`, lädt Measurements und setzt `fields` / `tagKeys` / `tagValuesByKey` sauber zurück.
     - `selectMeasurement(measurement)` lädt parallel `fields` (`List<InfluxFieldInfo>`) und `tagKeys` (`List<String>`).
     - `loadTagValues(tagKey)` lädt die Werte für den jeweiligen `tagKey` und legt sie unter `tagValuesByKey[tagKey]` ab.
     - Fehlerfall (z. B. `InfluxAuthException`, `InfluxNetworkException`, `InfluxQueryException('database not found: ...')`, fehlende Verbindung oder fehlendes Token): Status wechselt auf `error` mit einer über `InfluxErrorFormatter` formatierten, token-freien deutschen Fehlermeldung!
     - `reloadMeasurements()`, `reloadFieldsAndTags()` und `reloadTagValues(tagKey)` triggern einen erneuten Abruf und wechseln bei Erfolg von `error` auf `loaded`.
     - **Mock-Abwärtskompatibilität:** Falls in älteren Tests (wie `test/e2e_dashboard_flow_test.dart`) ein `MockInfluxApiClient` nur `fetchFieldKeys` statt `fetchFieldInfos` stubbt (und `fetchFieldInfos` dadurch `NoSuchMethodError` / `TypeError` wirft), fällt der Controller automatisch auf `fetchFieldKeys` zurück und mappt die Strings auf `InfluxFieldInfo(key: k, type: 'unknown')` – echte `InfluxException`s werden hingegen regulär als `error`-State gemeldet!
     - **Race-Condition-Schutz:** Wechselt der Nutzer die Connection oder das Measurement während ein alter Request noch läuft, überschreibt die verspätete Antwort nicht den neuen State.
4. **Implementierung & Refactoring:**
   - [x] **Green:** Implementiere das State-Modell und den Riverpod-Notifier/Controller (z. B. `editorSchemaControllerProvider.autoDispose`) in `lib/presentation/controllers/`.
   - [x] Behalte die bisherigen einfachen Methoden (`getMeasurements`, `getFieldKeys`, `getTagKeys`, `getTagValues`) auf `SchemaDiscoveryController` bei, damit alle bestehenden Aufrufer und Tests unverändert grün bleiben.
   - [x] **Refactor:** Saubere Dokumentation und Typprüfung.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] Jeder Schema-Abruf (Measurements, Fields mit Typ, Tag-Keys, Tag-Values) bildet Lade-, Treffer-, Leer- und Fehlerzustände explizit ab.
  - [x] Manuelles Neu-Laden (`reload...`) funktioniert auf allen Ebenen.
  - [x] Kaskadierende Wechsel und veraltete asynchrone Antworten sind gegen Race-Conditions geschützt.
- **Testing-Pflicht (im Ordner `test/`):**
  - [x] Alle neuen und bestehenden Tests in `test/presentation/controllers/schema_discovery_controller_test.dart` laufen grün.
  - [x] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` melden 0 Fehler.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] Folge-Tasks in `Roadmap/Tasks/` (`Task_13`–`Task_15`), `Roadmap/README.md` und ggf. `docs/` geprüft und bei Bedarf aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_12.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `SchemaListState<T>` (`lib/presentation/controllers/schema_discovery_state.dart`) kapselt `status` (`idle`, `loading`, `loaded`, `error`), `items` und `errorMessage` mit Hilfs-Gettern `isLoading`, `hasError`, `isLoaded`, `isEmptyLoaded`.
  - `EditorSchemaState` fasst die gesamte kaskadierende Schema-Hierarchie für ein Widget zusammen: `selectedConnectionId`, `selectedMeasurement`, `measurements`, `fields`, `tagKeys` und `tagValuesByKey`.
  - `EditorSchemaController` (`lib/presentation/controllers/schema_discovery_controller.dart`) verwaltet diesen Zustand reaktiv über `editorSchemaControllerProvider.autoDispose`.
  - Automatische Abwärtskompatibilität für Mocks: Wenn `fetchFieldInfos` `NoSuchMethodError` oder `TypeError` wirft, fällt der Controller transparent auf `fetchFieldKeys` zurück. Echte InfluxDB-Fehler (`InfluxException`) werden hingegen formatiert und in den Error-State überführt.
  - Race-Conditions werden mit Request-Counters (`_connectionRequestId`, `_measurementRequestId`) unterdrückt, sodass veraltete langsame Server-Antworten den neueren Selektionszustand niemals überschreiben können.
- **Stolpersteine & gelöste Probleme:**
  - In Tests mit `autoDispose`-Providern muss eine aktive Subscription (`container.listen(provider, (_, _) {})`) gehalten werden, wenn asynchrone Delays (`Future.delayed`) auftreten, damit Riverpod den Notifier nicht vorzeitig disposed.
- **Wichtige Hinweise für die Folge-Tasks:**
  - In `Task_13` (`SearchableSchemaPicker`) und `Task_14` (`TagFilterEditor` & `MultiFieldSelector`) können Widgets `ref.watch(editorSchemaControllerProvider)` nutzen, um direkt auf `measurements`, `fields`, `tagKeys` und `tagValuesByKey` zuzugreifen.
  - Der Neu-Laden-Button im UI ruft direkt `ref.read(editorSchemaControllerProvider.notifier).reloadMeasurements()`, `reloadFieldsAndTags()` oder `reloadTagValues(k)` auf.
