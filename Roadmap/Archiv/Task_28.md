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

- [x] Jede Evaluator-Funktion hat einen Hilfeeintrag (automatischer Test).
- [x] IAQ-Vorlage (SEN66, `min` über vier Teil-Scores) rechnet mit Beispielwerten korrekt (Test, inkl. Fall, dass der schlechteste Score das Ergebnis bestimmt).
- [x] Vorlage lässt sich im Editor übernehmen und anschließend anpassen.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- **Vom Nutzer vorgegeben (Gesamtformel):** `IAQ_gesamt = min(S_CO2, S_VOC, S_PM2.5, S_RH)`, also der schlechteste Teil-Score bestimmt den Gesamt-Score. Die Vorlage „IAQ (Sensirion SEN66)“ bildet das als Zwischenschritte ab: `s_co2`, `s_voc`, `s_pm25`, `s_rh`, Ergebnis `min(s_co2, s_voc, s_pm25, s_rh)`. Variablen: `co2` (ppm), `voc` (VOC-Index), `pm25` (µg/m³), `rh` (% relative Feuchte).
- **Entschieden (Nutzer überlässt die Schwellen dem Agenten, Bedingung: in der App umsetzbar):** Die Teil-Scores (0 bis 100) sind lineare Rampen, begrenzt mit `clamp`. Sie nutzen nur Funktionen aus Task_22 (`clamp`, `abs`, `min`) und stehen als normale Zwischenschritte im Editor, die der Nutzer direkt ändern kann:
  - `s_co2 = clamp(100 * (2000 - co2) / 1400, 0, 100)` (600 ppm = 100, 2000 ppm = 0)
  - `s_voc = clamp(100 * (250 - voc) / 150, 0, 100)` (VOC-Index 100 = 100, 250 = 0)
  - `s_pm25 = clamp(100 * (35 - pm25) / 30, 0, 100)` (5 µg/m³ = 100, 35 = 0)
  - `s_rh = clamp(100 - 100 * abs(rh - 50) / 30, 0, 100)` (50 % = 100, 20 % oder 80 % = 0)
  - Ergebnis: `min(s_co2, s_voc, s_pm25, s_rh)`
- **Umsetzbarkeit:** Der Test wertet die Vorlage mit dem echten Dart-Evaluator (Task_22) aus, nicht mit einer Sonderlogik. Die Schwellen sind als Zahlen in den Schritten sichtbar und editierbar; der Hilfetext erklärt, wo man sie anpasst. Falls Task_22 Konstanten/Parameter (z. B. `co2_gut = 600`) umsetzt, nutzt die Vorlage diese, sonst bleiben es Literale.
- Die Vorlage braucht `min` mit beliebig vielen Argumenten (siehe Task_22).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Hilfe-Daten und Vorlagen (`formula_help_content.dart`), `FormulaHelpScreen`, Hilfe-Button im Formel-Editor (Vorlage uebernehmen) und im Dashboard, `FormulaEvaluator.functionNames`, Speichern-Sperre bei Variablen ohne Feld. Vorlagen: IAQ SEN66 (Schwellen wie in der Task-Beschreibung), Celsius in Fahrenheit, Mittelwert zweier Sensoren.
- **Learnings & Stolpersteine:** `scrollUntilVisible` laesst Elemente teilweise sichtbar; vor `tap` zusaetzlich `ensureVisible` aufrufen. Beispiel-Formeln der Hilfe duerfen keine Variablen enthalten (Test wertet sie mit leerer Variablenmenge aus), z. B. `abs(0 - 3)` statt `abs(-3)`.
- **Wichtige Entscheidungen und ihre Gründe:** Vorlagenvariablen haben leeres `field`; der Nutzer ordnet sie per Picker zu (Hinweis per SnackBar). Bereits zugeordnete Variablen gleichen Namens bleiben erhalten.
- **Auswirkungen auf Folge-Tasks:** Task_31 (Redesign) muss die Hilfe-Schaltflaechen (Keys `formula_help_button`, `open_formula_help_btn`) behalten.
- **Hinweise zu Tests und Befehlen:** `flutter test test/presentation/help test/presentation/screens/dashboard/widgets_dashboard_help_test.dart`.
