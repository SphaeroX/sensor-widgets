# Task_28: Hilfe-Seite & Formel-Vorlagen (z. B. IAQ)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_28.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Eine In-App-Hilfe erklärt Formeln (Variablen, Funktionen, Bedingungen, Zwischenschritte, Fehlermeldungen) mit Beispielen. Fertige Vorlagen, u. a. ein IAQ-Verlauf (VOC- und CO2-Rohwerte auf 0 bis 100 skalieren und zum IAQ verrechnen), lassen sich per Tipp in den Editor übernehmen.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_27 abgeschlossen.
- **Relevantes Vorwissen:** Die Funktionsliste kommt aus Task_22. Keine neuen Packages; reines Flutter Material. Texte kommen aus einer zentralen Stelle (z. B. `lib/presentation/help/`), damit Funktionsliste und Hilfe nicht auseinanderlaufen (Test prüft, dass jede Evaluator-Funktion in der Hilfe vorkommt).

## Umfang

**Gehört dazu:**

- Hilfe-Screen, erreichbar aus dem Formel-Editor und dem Dashboard-Menü.
- Vorlagenkatalog mit Beschreibung, Variablenplatzhaltern und Zwischenschritten.
- Vorlage übernehmen: Schritte und Formel werden eingetragen, Variablen müssen noch per Picker zugeordnet werden (klarer Hinweis).
- Test: Hilfe deckt alle unterstützten Funktionen ab.

**Gehört nicht dazu:**

- Mehrsprachigkeit über das bestehende Maß hinaus.

## Umsetzungsschritte

1. Datei in `RUN_Task_28.md` umbenennen.
2. Hilfe-Inhalte und Vorlagen als Daten modellieren (Test zuerst).
3. Screen und Navigation per Widget-Test bauen.
4. Übernahme der Vorlage in den Editor testen.
5. Vorlagen-Formeln durch den Evaluator mit Beispielwerten verifizieren (Test).

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/presentation/help/help_screen_test.dart`, `test/presentation/help/formula_templates_test.dart`.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Jede Evaluator-Funktion hat einen Hilfeeintrag (automatischer Test).
- [ ] IAQ-Vorlage rechnet mit Beispielwerten korrekt (Test).
- [ ] Vorlage lässt sich im Editor übernehmen und anschließend anpassen.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Genaue IAQ-Formel (Skalierung VOC/CO2, Gewichtung) ist sensor- und geschmacksabhängig; der Nutzer liefert oder bestätigt sie. Bis dahin Platzhaltergewichtung, klar als Beispiel markiert.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):**
- **Learnings & Stolpersteine:**
- **Wichtige Entscheidungen und ihre Gründe:**
- **Auswirkungen auf Folge-Tasks:**
- **Hinweise zu Tests und Befehlen:**
