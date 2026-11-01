> [!IMPORTANT]
> ### 🚨 PFLICHTANWEISUNG VOR ARBEITSBEGINN
> 1. **Lies als allererstes die Regeldateien:** Konsultiere `../AGENTS.md` im Ordner `Roadmap/` sowie `/AGENTS.md` im Projekt-Root und befolge ausnahmslos alle darin festgelegten Regeln (insbesondere striktes TDD)!
> 2. **Allererste Aktion – Datei umbenennen:** Benenne diese Datei als **allererste Aktion** um und stelle das Kürzel `RUN_` voran (`Task_19.md` ➔ `RUN_Task_19.md`), **NOCH BEVOR** irgendeine Zeile Code geschrieben oder geändert wird!
> 3. **Testing-Suite:** Alle Tests müssen permanent im Projekt-Testverzeichnis unter `test/` (spiegelt `lib/`), `android/app/src/test/` oder `ios/` abgelegt werden.
> 4. **Vor der Archivierung:** Bevor dieser Task nach erfolgreichem Testing ins `Archiv/` verschoben wird, müssen Sektion 6 am Ende dieser Datei ausgefüllt sowie die Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und aktualisiert werden!

---

# Task_19: Native Widget-Integration (Android Glance & iOS WidgetKit) & Fehlerzustände

## 1. Ziel & Zweck des Tasks
- **Fokus:** Native Auswertung der Formel im Hintergrund-Zyklus der Widgets auf Android und iOS sowie transparente visuelle Darstellung von Formel- und Berechnungsfehlern auf dem Homescreen.
- **Erwartetes Ergebnis:**
  - Android Jetpack Glance Widgets (`SingleValueWidget`, `IndicatorLampWidget`, `GaugeBarWidget`, `AggregateWidget`) nutzen den vorberechneten Wert aus der Formel.
  - iOS WidgetKit Widgets nutzen den Formelwert in ihren Views.
  - Klare Fehleranzeige auf dem Homescreen bei mathematischen oder Datenfehlern (z. B. `Fehler: /0`, `Fehlender Wert`, `Formelfehler`), anstatt stillschweigend alte Werte anzuzeigen oder abzustürzen.

---

## 2. Kontext & Abhängigkeiten
- **Vorausgehende Tasks:** `Task_16`, `Task_17` und `Task_18` abgeschlossen.
- **Betroffene Komponenten / Dateien:**
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/glance/` (alle Glance-Widgets)
  - `android/app/src/main/kotlin/io/github/mgasc/influx_sensor_widgets/worker/WidgetUpdateWorker.kt`
  - `android/app/src/test/kotlin/io/github/mgasc/influx_sensor_widgets/glance/` (Glance Tests)
  - `ios/Runner/Widgets/` (WidgetKit Extensions)
  - `ios/RunnerTests/` (Swift Widget Tests)

---

## 3. Detaillierte Implementierungsschritte
1. **Vorbereitung:**
   - [ ] Datei in `RUN_Task_19.md` umbenennen.
   - [ ] Android Glance Widget Layouts und Error-States in `android/app/src/main/kotlin/.../glance/` untersuchen.
2. **Android Glance Integration & Error-State per TDD:**
   - [ ] **Red:** Schreibe JUnit-Tests in `android/app/src/test/kotlin/.../worker/WidgetUpdateWorkerTest.kt`:
     - Testet erfolgreichen Durchlauf eines Widgets mit Formel (z. B. `(A + B) / 2`).
     - Testet Division durch Null: Widget-Zustand wechselt auf Fehleranzeige `Fehler: Division durch 0`.
     - Testet fehlenden Messwert: Fehleranzeige `Fehler: Variable fehlt`.
   - [ ] **Green:** Implementiere die Übergabe des Formelergebnisses und der Fehler-Payload an das Glance-UI.
   - [ ] Testlauf: `cd android && ./gradlew test`.
3. **iOS WidgetKit Integration & Error-State:**
   - [ ] Aktualisiere SwiftUI Timeline-Provider und Views für iOS 17+.
   - [ ] Implementiere analoge Fehler-Badges/Text für die WidgetKit-Darstellung.
4. **Refactoring & Code Quality:**
   - [ ] `cd android && ./gradlew :app:ktlintCheck` ausführen.
   - [ ] `flutter test` ausführen, um Seiteneffekte auszuschließen.

---

## 4. Akzeptanzkriterien & Testing-Vorgaben
- [ ] Android- und iOS-Widgets zeigen berechnete Werte korrekt mit Einheit und Dezimalstellen an.
- [ ] Schwellenwerte (`ThresholdRule`) und Pegelanzeigen (`GaugeBar`) reagieren auf das Ergebnis der Formel.
- [ ] Bei Berechnungsfehlern zeigt das Widget einen lesbaren Fehlerstatus an.
- [ ] Alle Android-JUnit-Tests und Dart-Tests sind grün.

---

## 5. Abschluss-Checkliste vor der Archivierung
- [ ] Alle Tests unter `test/` und `android/` sind grün.
- [ ] Erkenntnisse in Sektion 6 eingetragen.
- [ ] `Roadmap/Tasks/Task_20.md` und `Roadmap/README.md` geprüft.
- [ ] Datei umbenennen (`RUN_` entfernen) und nach `Roadmap/Archiv/` verschieben.

---

## 6. Erkenntnisse & Learnings für nachfolgende Tasks
- **Glance & Native Error States:**
  - `WidgetRefreshWorker` fängt Auswertungs- und Abfragefehler (`FormulaException`, `MissingVariableException`, HTTP-Fehler) und speichert diese mit einem strukturierten Fehlerobjekt `{"error": e.message, "timestamp": ...}` in den SharedPreferences-Cache.
  - `WidgetUiStateMapper` liest diesen Fehler und befüllt `WidgetUiState.errorMessage`, wodurch Glance's `ErrorView` auf dem Homescreen transparent rot Fehler anzeigt (z. B. `Fehlende Variable: B`, `Division durch Null`).
  - `WidgetRefreshWorkerTest` deckt Berechnungen mit Single-Value, Indikator-Lampe (`isActive`-Berechnung) und Fehlerfälle ab.
  - In iOS WidgetKit wurden `IndicatorLampWidgetView`, `GaugeBarWidgetView`, `AggregateWidgetView` und `MultiValueWidgetView` mit einheitlichen roten Fehler-Badges/Texten ausgestattet.
