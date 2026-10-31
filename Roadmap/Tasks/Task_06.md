> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_06.md` ➔ `RUN_Task_06.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_06: Flutter Dashboard UI – Teil 2: Widget-Übersicht, Konfigurator & Live-Vorschau

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung des Herzstücks der Flutter-App: die Dashboard-Übersicht aller konfigurierten Widgets sowie der geführte Widget-Konfigurator für alle 6 Widget-Typen inklusive kombinierter Schema-Discovery (Dropdowns + Freitext-Fallback) und Live-Daten-Vorschau.
- **Erwartetes Ergebnis:** Vollständige, mit Widget- und Controller-Tests abgesicherte UI zum Erstellen, Bearbeiten, Duplizieren, Löschen und Live-Vorschauen aller 6 Widget-Typen.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_05` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/controllers/widgets_controller.dart`
  - `lib/presentation/controllers/schema_discovery_controller.dart`
  - `lib/presentation/screens/dashboard/widgets_dashboard_screen.dart`
  - `lib/presentation/screens/editor/widget_editor_screen.dart`
  - `lib/presentation/widgets/preview/widget_live_preview_card.dart`
  - `test/presentation/controllers/widgets_controller_test.dart`
  - `test/presentation/controllers/schema_discovery_controller_test.dart`
  - `test/presentation/screens/editor/widget_editor_screen_test.dart`
- **Relevante globale Infos:** Siehe `../README.md`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_06.md` umbenennen.
   - [ ] Learnings aus `Task_03`, `Task_04` und `Task_05` lesen.
2. **SchemaDiscoveryController & WidgetsController per TDD:**
   - [ ] **Red:** Schreibe Unit-Tests in `test/presentation/controllers/schema_discovery_controller_test.dart` und `widgets_controller_test.dart` für:
     - Asynchrones Nachladen von Measurements, Field Keys, Tag Keys und Tag Values bei Auswahl einer Verbindung.
     - Fehlertolerantes Verhalten (wenn der Server beim Bearbeiten offline ist, fällt die Auswahl ohne Crash auf den Freitext-Modus zurück).
     - Live-Vorschau-Abfrage (`fetchPreviewData`) für die aktuell im Editor eingestellte `WidgetDefinition`.
     - Speichern, Duplizieren, Löschen und manuelles „Alle Widgets aktualisieren“ (`triggerNativeRefresh`).
   - [ ] **Green:** Implementiere beide Controller in `lib/presentation/controllers/`.
3. **Dashboard-Übersicht & Widget-Editor per TDD:**
   - [ ] **Red:** Schreibe Widget-Tests in `test/presentation/screens/editor/widget_editor_screen_test.dart`:
     - Auswahl zwischen allen 6 Widget-Typen (`single_value`, `history_chart`, `indicator_lamp`, `multi_value`, `aggregate`, `gauge_bar`) blendet dynamisch die passenden Konfigurationsfelder ein:
       - `history_chart`: Zeitraum-Auswahl (`1h`, `6h`, `24h`, `7d`, `30d`).
       - `indicator_lamp`: Operator (`>` / `<`), Schwellenwert, aktive/inaktive Farbe bzw. Status-Label.
       - `multi_value`: Liste mehrerer Sensor-Abfragen (Label, Measurement, Field, Tag-Filter, Einheit) für z. B. einen Raum.
       - `aggregate`: Zeitraum + Funktion (`MIN`, `MAX`, `MEAN` oder alle drei).
       - `gauge_bar`: `minValue`, `maxValue`, Einheit, optionale Farbzonen/Schwellenwerte.
     - Umschaltung / Kombinierte Eingabe zwischen geladenen Schema-Vorschlägen (Dropdown/Autocomplete) und direkter Freitext-Eingabe funktioniert nahtlos.
     - Die Live-Vorschau-Karte (`WidgetLivePreviewCard`) zeigt die abgefragten Testdaten im gewählten Widget-Stil an.
   - [ ] **Green:** Implementiere `WidgetsDashboardScreen`, `WidgetEditorScreen` und `WidgetLivePreviewCard`.
   - [ ] **Refactor:** Hauptnavigation zwischen Dashboard und Verbindungsverwaltung finalisieren.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Jeder der 6 Widget-Typen lässt sich komplett konfigurieren, in der Live-Vorschau testen und im Shared Storage speichern.
  - [ ] Schema-Discovery lädt vorhandene Measurements/Fields/Tags per InfluxQL; Freitext-Eingabe ist jederzeit möglich.
- **Testing-Pflicht (`test/`):**
  - [ ] Alle Controller- und Screen-Tests unter `test/presentation/` laufen grün.
  - [ ] `flutter test`, `dart format --set-exit-if-changed .` und `flutter analyze` melden 0 Fehler.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests unter `test/` sind grün.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_06.md` ➔ `Task_06.md`) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
<!-- DIESE SEKTION MUSS VOM BEARBEITENDEN AGENTEN VOR DER ARCHIVIERUNG AUSGEFÜLLT WERDEN! -->
*Hier dokumentiert der Agent wichtige Erkenntnisse, Stolpersteine, Architekturanpassungen und Schnittstellen-Details, die für nachfolgende Agenten bei späteren Tasks unverzichtbar sind:*

- **Wichtige Architekturentscheidungen & Details:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Stolpersteine & gelöste Probleme:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
- **Wichtige Hinweise für die Folge-Tasks:**
  - *[Wird vom Agenten nach der Implementierung ausgefüllt]*
