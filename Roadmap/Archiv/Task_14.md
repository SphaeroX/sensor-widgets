> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_14.md` ➔ `RUN_Task_14.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_14: Interaktiver `TagFilterEditor` & `MultiFieldSelector` (Chips & Checkbox-Sheet)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Entwicklung von zwei spezialisierten Editor-Komponenten für die bisher fehlende bzw. rein textbasierte Auswahl:
  1. **`TagFilterEditor`:** Geführte Auswahl optionaler Tag-Filter (`Map<String, String>`, z. B. `room = living_room`, `entity_id = ...`) direkt aus den per `SHOW TAG KEYS` und `SHOW TAG VALUES` geladenen Datenbank-Metadaten, dargestellt als löschbare/bearbeitbare Chips.
  2. **`MultiFieldSelector`:** Komfortable Mehrfachauswahl geladener Fields (`List<SensorQueryItem>`) per Checkboxen im durchsuchbaren Bottom-Sheet inklusive Datentyp-Badges (`float`, `integer`, …) und optionaler Anpassung von Anzeigename (`label`) und Einheit (`unit`) für `WidgetType.multiValue`.
- **Erwartetes Ergebnis:** Zwei isoliert getestete Material-3-Komponenten unter `lib/presentation/widgets/editor/`, die nahtlos mit dem Schema-State aus `Task_12` zusammenarbeiten.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_11`, `Task_12` und `Task_13` müssen abgeschlossen und in `Roadmap/Archiv/` archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/widgets/editor/tag_filter_editor.dart` *(neu)*
  - `lib/presentation/widgets/editor/multi_field_selector.dart` *(neu)*
  - `test/presentation/widgets/editor/tag_filter_editor_test.dart` *(neu)*
  - `test/presentation/widgets/editor/multi_field_selector_test.dart` *(neu)*
- **Relevante globale Infos:** Siehe `../README.md`, `lib/domain/models/sensor_query_item.dart` und Learnings aus `Task_11`–`Task_13`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [x] Datei in `RUN_Task_14.md` umbenennen.
   - [x] Learnings aus `Task_11`–`Task_13` sowie `lib/domain/models/sensor_query_item.dart` lesen.
2. **Komponente 1: `TagFilterEditor` per TDD entwickeln:**
   - [x] **Red:** Schreibe Widget-Tests in `test/presentation/widgets/editor/tag_filter_editor_test.dart`:
     - Zeigt vorhandene Filter (`{'room': 'living_room'}`) als `InputChip`s (`room = living_room`) mit Löschen-Icon (`onDeleted` entfernt den Eintrag).
     - Zeigt Lade-/Fehlerstatus und Neu-Laden-Button für `tagKeys` an (bzw. Hinweis „Zuerst Measurement wählen“, falls noch kein Measurement ausgewählt ist).
     - Tipp auf `+ Filter hinzufügen` öffnet ein geführtes Auswahl-Sheet:
       1. Auswahl eines **Tag-Keys** aus den geladenen `tagKeys` (durchsuchbar + Option zur manuellen Eingabe).
       2. Automatisches Nachladen (`onLoadTagValues(tagKey)`) und Anzeigen der zugehörigen **Tag-Values** (mit Lade-Spinner, Fehleranzeige/Reload, Suchfeld und manueller Eingabe-Option).
       3. Antippen eines Tag-Values fügt das Paar `key: value` hinzu und schließt das Sheet.
   - [x] **Green:** Implementiere `lib/presentation/widgets/editor/tag_filter_editor.dart`.
3. **Komponente 2: `MultiFieldSelector` per TDD entwickeln:**
   - [x] **Red:** Schreibe Widget-Tests in `test/presentation/widgets/editor/multi_field_selector_test.dart`:
     - Zeigt ausgewählte `List<SensorQueryItem>` übersichtlich als Liste/Chips (mit Feldname, optional editierbarem Label/Einheit und Entfernen-Button).
     - Tipp auf `Felder auswählen` öffnet ein durchsuchbares Multi-Select-Bottom-Sheet mit allen geladenen `InfluxFieldInfo`-Einträgen, Checkboxen und Datentyp-Badges (`float`, `integer`, `string`, `boolean`).
     - An- und Abhaken mehrerer Felder aktualisiert die Auswahl; beim Bestätigen bleiben bereits vergebene benutzerdefinierte `label`/`unit`-Werte bestehender Felder erhalten!
     - Bietet Lade-/Fehlerstatus mit `Neu laden`-Button sowie eine Fallback-Möglichkeit `+ Manuelles Feld hinzufügen`, falls die Datenbank offline ist.
     - Validiert, dass mindestens 1 Feld ausgewählt wurde.
   - [x] **Green:** Implementiere `lib/presentation/widgets/editor/multi_field_selector.dart`.
   - [x] **Refactor:** Einheitliches UI-Erscheinungsbild analog zu `SearchableSchemaPicker` aus `Task_13`.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] Tag-Filter (`WHERE <tagKey> = '<tagValue>'`) lassen sich mit wenigen Klicks komplett aus der Datenbank auswählen, anzeigen und wieder löschen.
  - [x] Multi-Value-Felder lassen sich per Checkbox-Liste inkl. Datentyp-Anzeige auswählen und mit optionalem Label/Unit versehen (inkl. Offline-Freitext-Fallback).
- **Testing-Pflicht (im Ordner `test/`):**
  - [x] Alle Widget-Tests in `tag_filter_editor_test.dart` und `multi_field_selector_test.dart` sind grün.
  - [x] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` laufen mit 0 Fehlern durch.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] Folge-Task `Roadmap/Tasks/Task_15.md`, `Roadmap/README.md` und ggf. `docs/` geprüft und bei Bedarf aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_14.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `TagFilterEditor` (`lib/presentation/widgets/editor/tag_filter_editor.dart`) rendert aktive Tag-Filter als `InputChip`s mit Löschen-Icon (`Icons.close`). Das geführte Bottom-Sheet führt den Nutzer von der Key-Auswahl (mit automatischem Nachladen der Values über `onLoadTagValues(key)`) zur Value-Auswahl, bietet aber jederzeit direkte Freitextfelder für Key und Value als Fallback an.
  - `MultiFieldSelector` (`lib/presentation/widgets/editor/multi_field_selector.dart`) verwaltet `List<SensorQueryItem>`. Im Multi-Select-Bottom-Sheet können Felder per Checkbox ausgewählt werden; bereits vergebene `label`- und `unit`-Werte bleiben erhalten. Ein Dialog für manuelle Felder (`add_manual_multi_field_button`) steht ebenfalls zur Verfügung.
- **Stolpersteine & gelöste Probleme:**
  - `InputChip` Delete-Icon: In Flutter Material 3 wird `deleteIcon: const Icon(Icons.close, size: 16)` explizit angegeben, damit es plattformübergreifend und in Tests über `find.byIcon(Icons.close)` präzise angesteuert werden kann.
  - Eindeutige Bottom-Sheet-Titel (`Felder aus Datenbank auswählen`) verhindern Konflikte mit gleichnamigen Button-Labels.
- **Wichtige Hinweise für die Folge-Tasks:**
  - In `Task_15` wird im `WidgetEditorScreen`:
    - `TagFilterEditor` für alle Widget-Typen (unterhalb von Measurement/Field) eingebunden.
    - `MultiFieldSelector` für `WidgetType.multiValue` anstelle von Single-Field `SearchableSchemaPicker` angezeigt.
    - Synchrones Aufrufen von `_loadMeasurements()` während `build()` im `WidgetEditorScreen` muss wie in Task 15 beschrieben durch ein geordnetes Lifecycle-Event (`listenManual` / `addPostFrameCallback`) ersetzt werden.
