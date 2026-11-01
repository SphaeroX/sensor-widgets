# Regelwerk für KI-Agenten (`Roadmap/AGENTS.md`)

Dieses Dokument definiert verbindliche Arbeitsanweisungen für alle KI-Agenten, die an der Roadmap von `sensor-widgets` arbeiten. Es gilt **zusätzlich und komplementär** zur Root-Datei [`/AGENTS.md`](../AGENTS.md) sowie den Dokumenten in [`/docs/`](../docs/). Jede Anweisung ist strikt und ohne Ausnahme einzuhalten.

---

## 1. Ordner-Logik & Struktur

Das Projekt besitzt eine feste Verzeichnisstruktur für das Aufgaben-, Fixture- und Testmanagement:

```text
<Projekt-Root>/
├── AGENTS.md           # Globale Projekt- & TDD-Grundregeln
├── docs/               # Lebende Projektdokumentation (immer aktuell halten!)
├── fixtures/influx/    # Sprachübergreifende InfluxDB-JSON-Testfixtures (Dart, Kotlin, Swift)
├── test/               # Permanente Dart/Flutter Unit- & Widget-Test-Suite (spiegelt lib/)
├── integration_test/   # Permanente Flutter E2E-Tests
├── android/            # Android-App, Jetpack Glance Widgets & JUnit-Tests (app/src/test/)
├── ios/                # iOS-App, WidgetKit Extension & XCTests (CI-validiert)
└── Roadmap/
    ├── README.md       # Projektübergreifendes Gedächtnis & Status
    ├── AGENTS.md       # Dieses Regelwerk (immer bindend)
    ├── Tasks/          # Offene und aktuell bearbeitete Aufgaben (z. B. Task_01.md, RUN_Task_02.md)
    └── Archiv/         # Vollständig erledigte, getestete und archivierte Aufgaben
```

* **`Roadmap/Tasks/`**: Enthält **ausschließlich** offene Tasks und genau den einen Task, der aktuell bearbeitet wird.
* **`Roadmap/Archiv/`**: Enthält **ausschließlich** vollständig abgeschlossene Aufgaben, bei denen alle Tests und Linter grün sind und der Abschluss-Workflow durchlaufen wurde.
* **Test-Verzeichnisse (`test/`, `android/app/src/test/`, `ios/`, `fixtures/influx/`)**: Hier wird über den gesamten Projektverlauf hinweg eine permanente, kontinuierlich wachsende Test-Suite aufgebaut (gemäß [`docs/testing.md`](../docs/testing.md)).

---

## 2. Strikte Reihenfolge der Aufgaben

* Alle Aufgaben im Ordner `Roadmap/Tasks/` sind numerisch fortlaufend geordnet (z. B. `Task_01.md` bis `Task_15.md`).
* Die Aufgaben **MÜSSEN streng sequenziell in dieser Reihenfolge** abgearbeitet werden.
* Es ist verboten, Tasks zu überspringen oder an späteren Tasks zu arbeiten, solange der vorherige Task nicht vollständig abgeschlossen und ins Archiv verschoben wurde.

---

## 3. Start-Prozedur: Das `RUN`-Kürzel

Bevor auch nur eine einzige Zeile Code geschrieben, gelöscht oder geändert wird, muss der aktuelle Task als laufend markiert werden:

1. **Allererste Aktion beim Start:** Benenne die Datei des aktuellen Tasks im Ordner `Roadmap/Tasks/` um, indem du das Präfix `RUN_` voranstellst.
   * *Beispiel:* Aus `Task_01.md` wird `RUN_Task_01.md`.
2. Dadurch ist für jeden Entwickler und jeden nachfolgenden KI-Agenten sofort auf Dateisystemebene ersichtlich, welcher Task gerade aktiv in Bearbeitung ist.
3. Es darf **niemals mehr als ein Task gleichzeitig** mit `RUN_` markiert sein.

---

## 4. Informations-Trennung & Doku-Pflicht

Um Redundanzen, Kontext-Überlauf und Informationsverlust zu vermeiden, gilt eine klare Trennung:

* **Taskspezifische Informationen:**
  * Gehören ausschließlich in die jeweilige Task-Datei (z. B. `RUN_Task_01.md`).
  * Dazu zählen: isolierte Implementierungsschritte, modulinterne Details, lokale Fehlermeldungen und Notizen.
* **Projekt- und taskübergreifende Informationen:**
  * Gehören in die `Roadmap/README.md` sowie die passende Fachdatei unter `docs/` (`architecture.md`, `testing.md`, `code-style.md`, `conventions.md`, `project-brief.md`).
  * Wenn ein Task Auswirkungen auf andere Teile des Projekts hat (z. B. genaue Package-Versionen, Storage-Keys, JSON-Schema, Test-Befehle), **müssen** `Roadmap/README.md` und `docs/` sofort im selben Schritt aktualisiert werden.

---

## 5. Strikte TDD- & Testing-Pflicht

1. **Red ➔ Green ➔ Refactor:** Schreibe **immer** zuerst einen fehlschlagenden Test (Red), führe ihn aus, schreibe dann den minimalen Produktionscode (Green) und räume anschließend auf (Refactor). Kein Produktionscode ohne vorherigen fehlschlagenden Test!
2. **Test-Integrität:** Ändere, lösche oder schwäche niemals einen bestehenden Test ab, um ihn grün zu bekommen. Repariere die Implementierung. Falls ein Test fachlich falsch ist, erkläre warum und frage den Nutzer um Freigabe.
3. **Repair-Budget:** Maximal **3 Reparaturversuche** pro fehlschlagendem Test – danach sofort stoppen und dem Nutzer berichten (welche Tests, was versucht wurde, vermutete Ursache).
4. **Speicherort:**
   * Dart-Tests permanent unter `test/` (spiegelt `lib/`) bzw. `integration_test/`.
   * Kotlin-Tests permanent unter `android/app/src/test/`.
   * Swift-Tests permanent im iOS-Test-Target unter `ios/`.
   * Gemeinsame InfluxDB-Antwortdaten unter `fixtures/influx/`.
5. **iOS-Besonderheit:** Auf dem lokalen Windows-System können keine iOS-Tests ausgeführt werden. Behaupte niemals, iOS-Code sei lokal getestet worden; nutze für iOS die GitHub-Actions-Pipeline.

---

## 6. Abschluss- und Archivierungs-Workflow

Wenn alle Tests und Linter für den aktuellen Task erfolgreich bestanden sind, darf die Task-Datei **NICHT** einfach verschoben werden. Es müssen zwingend folgende **drei Schritte in exakter Reihenfolge** durchgeführt werden:

### Schritt 1: Erkenntnisse dokumentieren
* Öffne die aktuelle Task-Datei (`RUN_Task_XX.md`).
* Navigiere zur Sektion `## 6. Erkenntnisse & Learnings für nachfolgende Tasks` ganz unten in der Datei.
* Dokumentiere dort präzise:
  * Wichtige technische Erkenntnisse und Designentscheidungen während der Umsetzung.
  * Unerwartete Besonderheiten, Fallstricke oder gelöste Probleme.
  * Konkrete Hinweise (Dateipfade, Klassennamen, Keys), die spätere Agenten bei den Folge-Tasks berücksichtigen müssen.

### Schritt 2: Folge-Tasks & Doku prüfen & anpassen
* Analysiere die verbleibenden Tasks im Ordner `Roadmap/Tasks/` (`Task_XX+1.md`, `Task_XX+2.md`, etc.) sowie `Roadmap/README.md` und `docs/`.
* Prüfe: Haben sich Signaturen, Datenstrukturen, Abhängigkeiten oder Befehle geändert?
* **Passe die Folge-Tasks, `Roadmap/README.md` und `docs/` bei Bedarf sofort an**, damit nachfolgende Agenten auf einem validen, aktuellen Plan aufbauen.

### Schritt 3: Verschieben ins Archiv
* Entferne das `RUN_`-Kürzel aus dem Dateinamen (z. B. `RUN_Task_01.md` wieder zu `Task_01.md` umbenennen).
* Verschiebe die Datei nun aus `Roadmap/Tasks/` in den Ordner `Roadmap/Archiv/`.
* Aktualisiere in `Roadmap/README.md` den aktuellen Status (Status des Tasks auf `Erledigt`, Fortschrittszähler erhöhen).
* Erst jetzt ist der Task offiziell abgeschlossen und der nächste nummerierte Task darf nach der Start-Prozedur (Regel 3) begonnen werden.
