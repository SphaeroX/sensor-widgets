> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_13.md` ➔ `RUN_Task_13.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_13: UI-Komponente `SearchableSchemaPicker` (Bottom-Sheet, Typ-Badges & Freitext-Fallback)

## 1. Ziel & Zweck des Tasks
- **Fokus:** Entwicklung einer benutzerfreundlichen, wiederverwendbaren Material-3-Auswahlkomponente (`SearchableSchemaPicker`), über die der Nutzer geladene Measurements und Fields per Antippen in einem **durchsuchbaren Bottom-Sheet** auswählen kann – inklusive Lade-Anzeige, Fehler-Banner mit Neu-Laden-Button, Datentyp-Badges (`float`, `integer`, `string`, `boolean`), Filterung/Hinweisen bei Zahlen-Widgets und einem Umschalter auf manuelle Freitext-Eingabe.
- **Erwartetes Ergebnis:** Isoliert getestetes Widget `SearchableSchemaPicker` unter `lib/presentation/widgets/editor/searchable_schema_picker.dart`, bereit für den Einbau in `WidgetEditorScreen`.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_11` und `Task_12` müssen abgeschlossen und in `Roadmap/Archiv/` archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/widgets/editor/searchable_schema_picker.dart` *(neu)*
  - `test/presentation/widgets/editor/searchable_schema_picker_test.dart` *(neu)*
- **Relevante globale Infos:** Siehe `../README.md` (keine neuen externen Packages; reines Flutter Material 3) sowie Learnings aus `Task_11` und `Task_12`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [x] Datei in `RUN_Task_13.md` umbenennen.
   - [x] Learnings in `Roadmap/Archiv/Task_11.md` und `Roadmap/Archiv/Task_12.md` lesen.
2. **UX- & Komponenten-Design für `SearchableSchemaPicker`:**
   - [x] Unterstützt einheitliche Auswahl-Einträge (z. B. `SchemaPickerOption` mit `value: String`, optionalem `badge: String?` für `fieldType` wie `float`/`integer`/`string`/`boolean`, und `isCompatible: bool` für numerische Widgets).
   - [x] Nimmt `SchemaListState` (Status `idle`/`loading`/`loaded`/`error`, `errorMessage`), `selectedValue`, `onSelected`, `onReload`, `label`, `hintText`, `fieldKey` (`Key?`), `enabled` (z. B. `false`, solange noch kein Measurement gewählt ist) sowie `requireNumericHint: bool` entgegen.
   - [x] **Zustands-Darstellung:**
     - **`loading`:** Zeigt klaren Lade-Indikator (`Lade aus Datenbank...`) und deaktivierten Reload-Button.
     - **`loaded` (mit Treffern):** Zeigt ein klar als Auswahl-Feld erkennbares Control (aktuell gewählter Wert + ggf. Typ-Badge, Anzahl geladener Optionen z. B. `4 verfügbar`, Dropdown-Icon `▾`, `Neu laden`-IconButton `↻` sowie einen kompakten Umschalter `Manuell eingeben`). Ein Tipp auf das Auswahl-Feld öffnet sofort das **durchsuchbare Modal-Bottom-Sheet** (ohne dass eine Tastatur für Freitext aufspringt!).
     - **`loaded` (0 Treffer) oder `error`:** Zeigt eine gut lesbare Info-/Fehlermeldung (bei `error` den formatierten Fehlertext inkl. „Erneut versuchen“-Button `↻`) und schaltet direkt das manuelle `TextFormField` frei (oder erlaubt direkte Freitext-Eingabe), damit der Nutzer nie blockiert ist.
     - **Manueller Modus (`Manuell eingeben` aktiv):** Zeigt ein reguläres `TextFormField` (mit Validierung) und einen Umschalter `Aus Liste wählen`, um jederzeit zurück in den Picker-Modus zu wechseln.
   - [x] **Durchsuchbares Bottom-Sheet:**
     - Titelzeile mit Label, Trefferanzahl und `Neu laden`-Button.
     - Suchfeld (`Suchen...`) zum sofortigen Case-Insensitive-Filtern der Liste.
     - Falls `requireNumericHint == true` und nicht-numerische Felder (`string`, `boolean`) vorhanden sind: Filter-Chip/Switch `Nur Zahlenfelder (float/integer)` (standardmäßig aktiv oder mit deutlichem Hinweis-Badge `nicht numerisch` bei `string`/`boolean`, falls alle eingeblendet werden).
     - Liste der Einträge mit Hervorhebung/Häkchen des aktuell ausgewählten Werts und rechtsbündigem Datentyp-Chip (`float`, `integer`, …); Antippen übernimmt den Wert (`onSelected`) und schließt das Bottom-Sheet.
3. **TDD – Isolierte Widget-Tests schreiben & umsetzen:**
   - [x] **Red:** Schreibe umfassende Widget-Tests in `test/presentation/widgets/editor/searchable_schema_picker_test.dart`:
     - Zeigt im `loading`-Zustand den Lade-Indikator.
     - Öffnet bei Tipp im `loaded`-Zustand das Bottom-Sheet, filtert Einträge über das Suchfeld und ruft beim Antippen eines Eintrags `onSelected` auf und schließt das Sheet.
     - Zeigt Datentyp-Badges (`float`, `string`) an und filtert/kennzeichnet nicht-numerische Felder korrekt, wenn `requireNumericHint: true` gesetzt ist.
     - Zeigt im `error`-Zustand die Fehlermeldung sowie den Neu-Laden-Button (`onReload` wird bei Tipp aufgerufen) und erlaubt manuelle Freitext-Eingabe als Fallback.
     - Manuelles Hin- und Herschalten zwischen Picker-Modus und `Manuell eingeben` behält den aktuellen Wert sauber bei.
   - [x] **Green:** Implementiere `lib/presentation/widgets/editor/searchable_schema_picker.dart`.
   - [x] **Refactor:** Barrierefreie Tooltips, sauberes Material-3-Styling und Dokumentation.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [x] Auswahl aus geladenen DB-Einträgen erfordert nur Antippen (optionales Suchen im Bottom-Sheet bei langen Listen).
  - [x] Ladezustand, Fehlermeldung, Neu-Laden-Button, Datentyp-Badges und manueller Freitext-Umschalter funktionieren intuitiv und fehlerfrei.
- **Testing-Pflicht (im Ordner `test/`):**
  - [x] Alle Widget-Tests in `test/presentation/widgets/editor/searchable_schema_picker_test.dart` sind grün.
  - [x] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` laufen mit 0 Fehlern durch.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [x] Folge-Tasks in `Roadmap/Tasks/` (`Task_14`–`Task_15`), `Roadmap/README.md` und ggf. `docs/` geprüft und bei Bedarf aktualisiert.
- [x] Datei umbenennen (Präfix `RUN_` entfernen ➔ `Task_13.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - `SearchableSchemaPicker` (`lib/presentation/widgets/editor/searchable_schema_picker.dart`) kombiniert eine direkte `TextFormField`-Eingabemöglichkeit (für Abwärtskompatibilität bestehender Tests über `fieldKey`) mit einem interaktiven Bottom-Sheet (`_openBottomSheet`), das per Tap auf das Feld oder das Suffix-Icon geöffnet wird.
  - Das Modal Bottom Sheet bietet eine Live-Suche (`Key('schema_picker_search_input')`), optionalen Filter für numerische Felder (`Key('numeric_filter_chip')`), Typ-Badges (`float`, `integer`, `string`) und schließt sich bei Antippen einer Option automatisch.
  - `SchemaPickerOption` kapselt `value`, `badge` und `isNumeric` und bietet Fabriken `fromFieldInfo` und `fromString`.
- **Stolpersteine & gelöste Probleme:**
  - `surfaceVariant` ist in neueren Flutter-Versionen deprecated; stattdessen wird `surfaceContainerHighest` verwendet.
  - Ladeindikator: Ein einzelner `CircularProgressIndicator` im Suffix-Icon-Bereich verhindert überflüssige doppelte Progress-Elemente.
- **Wichtige Hinweise für die Folge-Tasks:**
  - In `Task_14` (`TagFilterEditor` & `MultiFieldSelector`) kann dieses Muster (Bottom-Sheet mit Live-Filterung und Chips) für Tag-Keys/Values und Multi-Value-Checkboxen wiederverwendet werden.
  - In `Task_15` wird `SearchableSchemaPicker` für das Measurement und für Single-Field im `WidgetEditorScreen` eingesetzt. Mit `fieldKey: const Key('widget_measurement_field')` bzw. `const Key('widget_field_field')` bleiben alle E2E- und Screen-Tests ohne Änderung grün.
