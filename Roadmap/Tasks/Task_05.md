> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_05.md` ➔ `RUN_Task_05.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_05: Flutter Dashboard UI – Teil 1: Verbindungsverwaltung & Live-Verbindungstest

## 1. Ziel & Zweck des Tasks
- **Fokus:** Umsetzung der Benutzeroberfläche und der Riverpod-Controller zur Verwaltung von InfluxDB-Verbindungen (Liste, Anlegen, Bearbeiten, Löschen, Live-Verbindungstest).
- **Erwartetes Ergebnis:** Vollständig getestete Screens und Dialoge/Formulare für die Verbindungsverwaltung mit klarer Formularvalidierung, maskierter Token-Eingabe und Live-Test gegen `InfluxApiClient`.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_04` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `lib/presentation/controllers/connections_controller.dart`
  - `lib/presentation/screens/connections/connections_list_screen.dart`
  - `lib/presentation/screens/connections/connection_form_screen.dart`
  - `test/presentation/controllers/connections_controller_test.dart`
  - `test/presentation/screens/connections/connections_screens_test.dart`
- **Relevante globale Infos:** Siehe `../README.md`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_05.md` umbenennen.
   - [ ] Learnings aus `Task_03` und `Task_04` lesen.
2. **ConnectionsController per TDD (`flutter_riverpod`):**
   - [ ] **Red:** Schreibe `test/presentation/controllers/connections_controller_test.dart` für das Laden, Hinzufügen, Aktualisieren, Löschen und Testen (`testConnection`) einer InfluxDB-Verbindung.
   - [ ] **Green:** Implementiere `ConnectionsController` (`AsyncNotifier` / `StateNotifier`) in `lib/presentation/controllers/connections_controller.dart`.
3. **Verbindungs-Liste & Formular-UI per TDD (Widget-Tests):**
   - [ ] **Red:** Schreibe Widget-Tests in `test/presentation/screens/connections/connections_screens_test.dart`:
     - Empty-State wird angezeigt, wenn noch keine Verbindung existiert.
     - Formular-Validierung prüft Pflichtfelder (Name, gültige `http://` oder `https://` URL, Datenbank/Bucket, API-Token).
     - Token-Feld ist standardmäßig maskiert (`obscureText: true`) mit Toggle zum Anzeigen.
     - Klick auf „Verbindung testen“ ruft den Controller auf und zeigt Erfolg (z. B. Anzahl gefundener Measurements) oder eine verständliche Fehlermeldung (ohne Token!) an.
     - Speichern legt die Verbindung über den Controller an und kehrt zur Liste zurück; Löschen erfordert eine Bestätigung (insb. falls Widgets die Verbindung referenzieren).
   - [ ] **Green:** Implementiere `ConnectionsListScreen` und `ConnectionFormScreen` (Material 3 Design, übersichtlich für Mobile).
   - [ ] **Refactor:** UI-Komponenten und Navigation in `lib/app.dart` einbinden.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Nutzer können beliebig viele InfluxDB-Verbindungen anlegen, bearbeiten, testen und löschen.
  - [ ] Beim Bearbeiten einer bestehenden Verbindung kann das gespeicherte Token beibehalten oder neu gesetzt werden.
  - [ ] Fehlermeldungen beim Verbindungstest sind klar verständlich (401/403 Auth, 404 DB nicht gefunden, Timeout/Netzwerk).
- **Testing-Pflicht (`test/`):**
  - [ ] Controller-Unit-Tests und Flutter-Widget-Tests unter `test/presentation/` decken alle Zustände (Loading, Empty, Data, Error, Form Validation) ab.
  - [ ] `flutter test`, `dart format --set-exit-if-changed .` und `flutter analyze` sind grün.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests unter `test/` sind grün.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_05.md` ➔ `Task_05.md`) und nach `Roadmap/Archiv/` verschieben.

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
