> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_08.md` ➔ `RUN_Task_08.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent in den dafür vorgesehenen Test-Ordnern (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`) abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_08: Android Jetpack Glance Widgets: Alle 6 Widget-Typen & Konfigurations-Activity

## 1. Ziel & Zweck des Tasks
- **Fokus:** Implementierung der nativen Android-Homescreen-Widgets mit Jetpack Glance für alle 6 Widget-Typen inklusive Canvas-Bitmap-Rendering für Verlaufsdiagramme (`history_chart`) und Gauges (`gauge_bar`), einer Widget-Konfigurations-Activity (Auswahl der in der Flutter-App erstellten Widget-Definition beim Platzieren auf dem Homescreen) sowie Manifest-Registrierung.
- **Erwartetes Ergebnis:** Fertig registrierte, optisch ansprechende und mit Unit-Tests für ViewModel-/Formatierungs-/Chart-Skalierungslogik abgesicherte Android-Widgets.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_01` bis `Task_07` müssen abgeschlossen und archiviert sein.
- **Betroffene Komponenten / Dateien:**
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/res/xml/sensor_widget_info.xml`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/SensorGlanceAppWidget.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/SensorGlanceWidgetReceiver.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/SensorWidgetConfigActivity.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/chart/ChartMathAndFormatter.kt`
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/chart/NativeChartBitmapRenderer.kt`
  - `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/glance/*Test.kt`
- **Relevante globale Infos:** Siehe `../README.md` und `docs/architecture.md`.

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_08.md` umbenennen.
   - [ ] Learnings aus `Task_07` prüfen.
2. **Chart-Skalierung, Wert-Formatierung & UI-State-Mapping per TDD (JUnit):**
   - [ ] **Red:** Schreibe `ChartMathAndFormatterTest.kt` und `WidgetUiStateMapperTest.kt` in `android/app/src/test/...` für:
     - Normalisierung von Zeitreihen-Punkten auf `[0.0 .. 1.0]` Koordinaten (inkl. Edge-Cases: nur 1 Punkt, alle Werte identisch / `min == max`, negative Werte, leere Liste).
     - Prozentuale Berechnung und Clamping (`0% .. 100%`) für `gauge_bar`.
     - Formatierung von Messwerten, Einheiten und relativen/absoluten Zeitstempeln (`HH:mm`).
     - Mapping von gebundenen `appWidgetId`s auf die zugehörige `WidgetDefinition` und den gecachten Messwert.
   - [ ] **Green:** Implementiere `ChartMathAndFormatter.kt` und `WidgetUiStateMapper.kt`.
3. **Jetpack Glance Composables & Bitmap-Renderer für alle 6 Typen:**
   - [ ] Implementiere `NativeChartBitmapRenderer.kt` (zeichnet auf einem Android `Canvas` eine saubere Sparkline/Verlaufskurve mit Farbverlauf für `history_chart` bzw. einen Fortschrittsbogen/Balken für `gauge_bar` zur Anzeige als `Image` in Glance).
   - [ ] Implementiere in `SensorGlanceAppWidget.kt` die Views für:
     1. `single_value`: Titel, großer formatierter Messwert + Einheit, Zeitstempel, Refresh-Button.
     2. `history_chart`: Titel, aktueller Letztwert, gerenderte Verlaufskurve, Min/Max-Legende.
     3. `indicator_lamp`: Titel, leuchtender Status-Indikator (Farbe je nach Schwellenwert `>` / `<`), aktueller Messwert.
     4. `multi_value`: Raum-/Gruppentitel und kompakte Zeilen/Grid für die konfigurierten Einzelsensoren.
     5. `aggregate`: Titel, Zeitraum-Badge und `MIN` / `AVG` / `MAX` Werte.
     6. `gauge_bar`: Titel, visueller Balken/Gauge zwischen `min` und `max` mit Schwellenwert-Farbe und Wert.
   - [ ] Integriere saubere Zustände für „Noch nicht konfiguriert“, „Lade Daten...“ und „Verbindungsfehler (zeigt letzten gecachten Wert + Warn-Icon)“.
4. **Widget-Konfigurations-Activity & AndroidManifest:**
   - [ ] Implementiere `SensorWidgetConfigActivity.kt`, die beim Hinzufügen eines Widgets auf dem Android-Homescreen alle in der Flutter-App angelegten `WidgetDefinition`s auflistet, die Auswahl an die `appWidgetId` bindet, sofort einen ersten Refresh via `WidgetRefreshWorker` anstößt und `RESULT_OK` zurückgibt.
   - [ ] Registriere `SensorGlanceWidgetReceiver` und `SensorWidgetConfigActivity` in `AndroidManifest.xml` sowie `res/xml/sensor_widget_info.xml` (`updatePeriodMillis="1800000"`, `resizeMode="horizontal|vertical"`).

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- **Funktionale Kriterien:**
  - [ ] Alle 6 Widget-Typen sind in Jetpack Glance vollständig implementiert.
  - [ ] Mehrere Instanzen des Widgets auf dem Homescreen können über die Config-Activity unterschiedlichen `WidgetDefinition`-IDs zugewiesen werden.
  - [ ] Tipp auf den Refresh-Button im Widget triggert eine sofortige Aktualisierung; Tipp auf das Widget öffnet die App.
- **Testing-Pflicht (`android/app/src/test/`):**
  - [ ] `cd android && ./gradlew test` sowie `cd android && ./gradlew assembleDebug` (oder `flutter build apk --debug`) laufen fehlerfrei durch.
  - [ ] `ktlint "android/**/*.kt"` meldet 0 Fehler.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Android- und Dart-Tests sind grün.
- [ ] Erkenntnisse in Sektion 6 (unten) vollständig eingetragen.
- [ ] Folge-Tasks in `Roadmap/Tasks/` und `Roadmap/README.md` geprüft und aktualisiert.
- [ ] Datei umbenennen (`RUN_Task_08.md` ➔ `Task_08.md`) und nach `Roadmap/Archiv/` verschieben.

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
