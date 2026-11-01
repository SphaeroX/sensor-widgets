> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_15.md` ➔ `RUN_Task_15.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_15: Integration in `WidgetEditorScreen`, Lifecycle-Bugfix & End-to-End-Verifikation

## 1. Ziel & Zweck des Tasks
- **Fokus:** Vollständige Integration des reaktiven Schema-Controllers (`Task_12`), des `SearchableSchemaPicker` (`Task_13`) sowie des `TagFilterEditor` und `MultiFieldSelector` (`Task_14`) in `WidgetEditorScreen` – inklusive Behebung des bisherigen `setState`-in-`build`-Lifecycle-Bugs, sauberem Vorbefüllen & Nachladen im Bearbeitungsmodus (`widgetToEdit`) und End-to-End-Absicherung über alle 6 Widget-Typen.
- **Erwartetes Ergebnis:** Ein durchgängig benutzerfreundlicher Widget-Konfigurator, in dem nach Auswahl einer Datenquelle Measurements, Fields und Tag-Filter automatisch aus der InfluxDB geladen und bequem per Klick ausgewählt werden können – bei komplett grüner Test- und Linter-Suite sowie aktueller Dokumentation.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_11` bis `Task_14` müssen abgeschlossen und in `Roadmap/Archiv/` archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/screens/editor/widget_editor_screen.dart`
  - `test/presentation/screens/editor/widget_editor_screen_test.dart`
  - `test/e2e_dashboard_flow_test.dart` *(nur neue Tests ergänzen – bestehende Tests strikt nach `/AGENTS.md` Regel 1 schützen!)*
  - `docs/architecture.md`, `docs/testing.md`, `docs/project-brief.md`
  - `Roadmap/README.md`
- **Relevante globale Infos:** Siehe `../README.md`, `/AGENTS.md` (Regel 1 & 2) und alle Learnings aus `Task_11`–`Task_14`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung & Analyse bestehender Tests:**
   - [ ] Datei in `RUN_Task_15.md` umbenennen.
   - [ ] Alle Learnings aus `Roadmap/Archiv/Task_11.md` bis `Task_14.md` lesen.
   - [ ] **WICHTIG (`/AGENTS.md` Regel 1 – Schutz bestehender Tests):** Lies `test/presentation/screens/editor/widget_editor_screen_test.dart` und `test/e2e_dashboard_flow_test.dart` genau!
     - Beide bestehenden Testdateien prüfen `find.byKey(const Key('widget_measurement_field'))` und `find.byKey(const Key('widget_field_field'))` und rufen `tester.enterText(...)` darauf auf.
     - Stelle entweder sicher, dass diese Keys und `enterText` kompatibel bleiben, **ODER** – falls ein bestehender Test in `e2e_dashboard_flow_test.dart` wegen des bewussten UI-Wechsels vom Textfeld zum Bottom-Sheet-Picker auf das Antippen des Pickers umgestellt werden soll – **erkläre dem Nutzer gemäß `/AGENTS.md` Regel 1 vorab genau warum und hole seine ausdrückliche Freigabe ein**, bevor irgendeine Zeile eines bestehenden Tests geändert wird!
2. **TDD – Neue Widget- & Integrations-Tests für den geführten Editor-Flow schreiben:**
   - [ ] **Red:** Ergänze neue Tests in `test/presentation/screens/editor/widget_editor_screen_test.dart`:
     - **Automatischer Abruf & Auswahl per Klick:** Sobald `WidgetEditorScreen` öffnet, werden automatisch die Measurements der aktiven Verbindung geladen; Antippen von Measurement `'climate'` im Picker lädt automatisch Fields (`InfluxFieldInfo`) und Tag-Keys; Antippen von Field `'temperature'` übernimmt das Feld ohne jegliche Tastatureingabe.
     - **Tag-Filter-Auswahl & Speicherung:** Hinzufügen eines Tag-Filters (`room = living_room`) über `TagFilterEditor` speichert `tagFilters: {'room': 'living_room'}` in der erzeugten `WidgetDefinition` (und nutzt diese auch bei Klick auf „Vorschau laden“!).
     - **Multi-Value-Auswahl:** Wechsel auf `WidgetType.multiValue` zeigt `MultiFieldSelector`; Auswahl mehrerer geladener Felder erzeugt valide `SensorQueryItem`-Einträge in `WidgetDefinition.items`.
     - **Edit-Modus (`widgetToEdit`):** Beim Öffnen eines bestehenden Widgets mit gesetztem `measurement`, `field`, `tagFilters` und/oder `items` bleiben alle Werte erhalten, und im Hintergrund werden sowohl Measurements als auch die Fields & Tag-Keys des bestehenden Measurements automatisch nachgeladen.
     - **Fehler- & Reload-Verhalten:** Schlägt der DB-Abruf fehl (z. B. InfluxDB v2 `database not found`), wird die Fehlermeldung inkl. Neu-Laden-Button im Editor angezeigt; ein Klick auf Neu-Laden lädt erfolgreich nach, und der Freitext-Fallback funktioniert jederzeit.
     - **Kein ungewolltes Auto-Verhalten:** Die Live-Vorschau lädt nur bei Klick auf „Vorschau laden“, und ein leerer/ausgefüllter Widget-Titel wird durch die Schema-Auswahl nicht ungefragt überschrieben.
3. **Implementierung in `WidgetEditorScreen` (`Green` & `Refactor`):**
   - [ ] **Lifecycle-Bugfix:** Entferne den synchronen `_loadMeasurements()`-Aufruf mitten aus `build()`! Initialisiere die erste Verbindung und den automatischen Schema-Abruf sauber außerhalb von `build()` (z. B. über `ref.listenManual` auf `connectionsControllerProvider` / Post-Frame-Callback).
   - [ ] Binde `SearchableSchemaPicker` für **Measurement** und **Single-Field** (`requireNumericHint: true` für numerische Widget-Typen), `MultiFieldSelector` für `WidgetType.multiValue` sowie `TagFilterEditor` für optionale **Tag-Filter** ein.
   - [ ] Beim Wechsel des Measurements: Prüfe/aktualisiere abhängige Field- und Tag-Auswahlen sinnvoll und triggere automatisch das Nachladen der Fields & Tag-Keys.
   - [ ] Übergib `_tagFilters` (bzw. `null`, wenn leer) und `_multiItems` (`List<SensorQueryItem>`) vollständig in `_buildCurrentDefinition()`.
4. **Gesamt-Verifikation & Dokumentations-Abschluss:**
   - [x] Führe alle Qualitäts-Checks aus:
     - `flutter test`
     - `flutter analyze`
     - `dart format --set-exit-if-changed .`
   - [x] Prüfe und aktualisiere `docs/architecture.md`, `docs/project-brief.md` (und ggf. `docs/testing.md`) sowie `Roadmap/README.md` auf den finalen Stand von Meilenstein 2.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] Nach Auswahl/Vorhandensein einer InfluxDB-Verbindung lassen sich Measurements, Fields (Einzel- und Multi-Value inkl. Datentyp-Anzeige) sowie optionale Tag-Filter komplett per Antippen aus der Datenbank konfigurieren – ohne manuelles Abtippen.
  - [x] Kein `setState() called during build`-Fehler; Bearbeiten bestehender Widgets (`widgetToEdit`) lädt Schema-Optionen sauber vor und erhält alle gespeicherten Felder und Tag-Filter.
  - [x] Ladeanzeige, InfluxDB-v2-taugliche Fehlermeldungen, Neu-Laden-Button und manueller Freitext-Fallback funktionieren lückenlos.
  - [x] Der `widget_definitions_v1`-Kontrakt für Android- und iOS-Hintergrundwidgets bleibt zu 100 % gewahrt (`cross_platform_schema_contract_test.dart` grün).
- **Testing-Pflicht (im Ordner `test/`):**
  - [x] Komplette Dart-Test-Suite (`flutter test`) ist zu 100 % grün.
  - [x] `flutter analyze` und `dart format --set-exit-if-changed .` melden 0 Fehler/Warnungen.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Alle Dokumente in `docs/` sind aktuell und präzise.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] `Roadmap/README.md` auf `15 / 15 Tasks abgeschlossen` aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_15.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `WidgetEditorScreen` integriert jetzt nahtlos den `EditorSchemaController`, `SearchableSchemaPicker`, `TagFilterEditor` und `MultiFieldSelector`.
  - Der synchrone `_loadMeasurements()`-Aufruf mitten aus `build()` wurde vollständig eliminiert. Stattdessen wird der Schema-Abruf sauber initialisiert (Post-Frame-Callback in `initState` bzw. `ref.listen` auf `connectionsControllerProvider`).
  - Durch Beibehaltung von `TextFormField(key: const Key('widget_measurement_field'))` und `TextFormField(key: const Key('widget_field_field'))` im `SearchableSchemaPicker` bleibt 100 % Abwärtskompatibilität zu bestehenden E2E- und Widget-Tests erhalten, die `enterText` aufrufen.
  - `TagFilterEditor` arbeitet reaktiv mit `ValueNotifier<Map<String, SchemaListState<String>>>`, wodurch neu geladene Tag-Werte im geöffneten modalen Bottom-Sheet sofort und ohne Re-Opening sichtbar werden.
  - Beim Editieren eines bestehenden Widgets (`widgetToEdit`) werden vorhandene Werte in Measurement, Field, Tag-Filtern (`tagFilters`) und Multi-Items (`items`) vollständig erhalten und die zugehörigen Schema-Optionen im Hintergrund asynchron vorgeladen.

- **Stolpersteine & gelöste Probleme:**
  - *Flutter Material 3 Surface Deprecation:* `colorScheme.surfaceVariant` ist veraltet; `surfaceContainerHighest` wurde eingesetzt.
  - *Bottom-Sheet-Rebuilds:* Modale Bottom-Sheets leben in einem eigenen Routen-Kontext und rebuilden sich bei State-Änderungen des aufrufenden State-Objekts nicht automatisch. Durch die Übergabe eines `ValueNotifier` und `ValueListenableBuilder` im Bottom-Sheet wurde dies sauber gelöst.
  - *Unstubbed Mocks in Tests:* In bestehenden Unit-Tests, in denen `fetchFieldInfos` oder `fetchTagKeys` auf gemockten Clients nicht gestubbt waren, fingen Fallback-Routinen Null-Futures sicher ab (`_loadFieldInfos`, `_loadTagKeysSafe`).

- **Wichtige Hinweise für zukünftige Erweiterungen:**
  - Der `widget_definitions_v1`-Kontrakt bleibt unangetastet. Native Android- (Glance) und iOS-Widgets (WidgetKit) greifen direkt auf die durch den Editor gespeicherten Felder zu.
  - Sollte InfluxDB v3 / IOx oder erweiterte Aggregatfunktionen hinzukommen, ist `InfluxApiClient` der zentrale Einstiegspunkt; der `EditorSchemaController` und `SearchableSchemaPicker` können unverändert wiederverwendet werden.
