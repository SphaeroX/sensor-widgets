> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_18.md` ➔ `RUN_Task_18.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_18: Flutter UI: Formel-Editor & Variablen-Mapping

## 1. Ziel & Zweck des Tasks
- **Fokus:** Benutzerfreundliche Konfiguration von Formeln im `WidgetEditorScreen`.
- **Erwartetes Ergebnis:**
  - Neuer UI-Bereich „Berechnungsformel verwenden (optional)“ mit Toggle/Switch im Widget-Editor.
  - Dynamische Variablenverwaltung: Hinzufügen von Variablen (`A`, `B`, `C`...), Auswahl der Datenquelle (Feld im aktuellen Measurement oder individuelles Measurement + Tags via `SearchableSchemaPicker`).
  - Formel-Eingabefeld mit Syntax-Highlighting/Validierung (zeigt sofort an, ob die Formel syntaktisch valide ist und alle verwendeten Variablen definiert sind).
  - Anbindung an den Button „Vorschau laden“: Anzeige des berechneten Live-Werts oder präziser Fehlermeldung bei Formelproblemen.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_16` und `Task_17` abgeschlossen.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/screens/editor/widget_editor_screen.dart`
  - `lib/presentation/widgets/editor/formula_editor_section.dart` *(neu)*
  - `lib/presentation/widgets/editor/formula_variable_tile.dart` *(neu)*
  - `lib/presentation/controllers/widget_editor_controller.dart`
  - `test/presentation/screens/editor/widget_editor_screen_test.dart`
  - `test/presentation/widgets/editor/formula_editor_section_test.dart` *(neu)*

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_18.md` umbenennen.
   - [ ] Vorhandene Editor-Struktur in `lib/presentation/screens/editor/` analysieren.
2. **`FormulaEditorSection` Widget per TDD:**
   - [ ] **Red:** Schreibe Widget-Tests in `test/presentation/widgets/editor/formula_editor_section_test.dart`:
     - Ein-/Ausschalten des Formelmodus per Switch.
     - Rendert Eingabefeld für mathematische Ausdrücke.
     - Zeigt Fehlerbadge/Hinweistext bei ungültiger Formelsyntax (z. B. fehlende Klammer `(A + B`).
     - Zeigt Warnung an, wenn eine Variable in der Formel genutzt wird, die nicht definiert ist (z. B. `C` in `A + B + C`).
     - Ermöglicht Hinzufügen und Entfernen von Variablen-Slots (`A`, `B`, ...).
   - [ ] **Green:** Implementiere `lib/presentation/widgets/editor/formula_editor_section.dart` und `formula_variable_tile.dart`.
3. **Controller-Integration (`WidgetEditorController`):**
   - [ ] **Red:** Erweitere State- und Controller-Tests in `test/presentation/controllers/`:
     - Aktualisieren von `formula` und `formulaVariables`.
     - Validierungslogik vor dem Speichern (`isFormulaValid`).
     - Berechnung des Vorschauwerts über `FormulaCalculationService`.
   - [ ] **Green:** Implementiere Controller-Logik.
4. **Integration in `WidgetEditorScreen`:**
   - [ ] Platziere `FormulaEditorSection` sauber im bestehenden Editor-Layout (unterhalb der Feld-/Schema-Auswahl).
   - [ ] Stelle sicher, dass für Widgets ohne Formel alles exakt wie gewohnt funktioniert (Abwärtskompatibilität bestehender Tests).
   - [ ] Ergänze E2E-Editor-Tests in `test/presentation/screens/editor/widget_editor_screen_test.dart`.
5. **Refactoring & Code Quality:**
   - [ ] `flutter test`, `flutter analyze` und `dart format --set-exit-if-changed .` fehlerfrei durchführen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- [x] Nutzer können im Editor Formeln mit Variablen anlegen, anpassen und löschen.
- [x] Ungültige Formeln verhindern das versehentliche Speichern und zeigen einen klaren Hinweistext.
- [x] „Vorschau laden“ berechnet den echten Live-Wert über die Influx-Schnittstelle.
- [x] Alle bestehenden Widget-Editor-Tests bleiben grün.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [x] Alle Tests unter `test/` sind grün.
- [x] Erkenntnisse in Sektion 6 eingetragen.
- [x] `Roadmap/Tasks/Task_19.md` und `Roadmap/README.md` geprüft.
- [x] Datei umbenennen (`RUN_` entfernen) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **UI-Integration & Validierung:**
  - `FormulaEditorSection` (`lib/presentation/widgets/editor/formula_editor_section.dart`) stellt den Switch „Berechnungsformel verwenden“ bereit. Bei Aktivierung wird automatisch die erste Variable `A` angelegt, falls noch keine Variablen existieren.
  - Das Formelfeld validiert live mit `FormulaEvaluator.validateSyntax` und prüft, ob alle referenzierten Variablen auch in der Variablenliste definiert sind. Nicht definierte Variablen werden als Warnung hervorgehoben.
  - Beim Speichern in `WidgetEditorScreen` wird sichergestellt, dass bei aktiviertem Formelmodus eine syntaktisch korrekte Formel und mindestens eine Variable vorhanden sind.
  - Das Einzelfeld (`field`) ist bei aktiver Formel optional, da die Variablen die Quellfelder festlegen.
  - `WidgetsController.fetchPreviewData` nutzt `FormulaCalculationService`, sodass auch im Editor der Live-Preview-Wert direkt die Formelauswertung widerspiegelt.
- **Hinweise für Task 19:**
  - In `Task_19` wird sichergestellt, dass die nativen Layouts (Android Glance und iOS WidgetKit Views) Fehlermeldungen bei mathematischen Auswertungsfehlern (Division durch 0, leere DB-Antwort) prominent und lesbar anzeigen (`error` / `errorMessage`).
