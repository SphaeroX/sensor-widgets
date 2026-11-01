# Task_31: App-UI-Redesign (Dashboard, Editor, Typ-Kacheln, Hell/Dunkel)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_31.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die App wirkt modern und konsistent: Material-3-Theme mit Hell- und Dunkelmodus, gestaltete Widget-Karten im Dashboard (Typ-Icon, Titel, Kurzinfo, Mini-Vorschau-Platzhalter), Widget-Typ im Editor als Kachelauswahl mit Icon statt Dropdown, übersichtlichere Editor-Abschnitte (Karten, Gruppierung, Stepper oder Abschnittstitel).

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_21 abgeschlossen.
- **Relevantes Vorwissen:** Keine neuen Dependencies. Bestehende Selektoren und Texte in Tests möglichst erhalten; falls ein bestehender Test wegen der Dropdown-zu-Kachel-Änderung nicht mehr passt, nicht ändern, sondern zuvor erklären und Freigabe einholen (Root-`AGENTS.md`, Regel 1). Das Theme liegt zentral in `lib/core/`.

## Umfang

**Gehört dazu:**

- Zentrales `ThemeData` (Farbschema, Typografie, Karten, Eingabefelder) für hell und dunkel, Systemmodus.
- Dashboard-Karten und Leerzustand.
- Typ-Kachelauswahl im Editor (Kacheln mit Icon, Name und Kurzbeschreibung).
- Konsistente Abstände, Barrierefreiheit (Kontrast, Touch-Größen, Semantics).

**Gehört nicht dazu:**

- Optik der Homescreen-Widgets (Task_32).
- Neue Funktionalität.

## Umsetzungsschritte

1. Datei in `RUN_Task_31.md` umbenennen.
2. Bestehende Screen-Tests lesen und deren Selektoren sichern.
3. Theme per Widget-Test (Dark/Light) einführen.
4. Dashboard-Karte und Kachelauswahl per TDD bauen.
5. Editor-Abschnitte gestalten.
6. Regressionslauf, Screenshots für `docs/` optional.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/core/theme_test.dart`, `test/presentation/screens/dashboard/...`, `test/presentation/screens/editor/...` (nur ergänzen).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Hell- und Dunkelmodus funktionieren, belegt durch Widget-Tests.
- [ ] Typ-Auswahl erfolgt über Kacheln, alle sechs Typen wählbar.
- [ ] Keine bestehenden Tests geändert oder abgeschwächt (sonst mit Freigabe dokumentiert).
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Farbidentität/Branding: Annahme dezentes Blau/Teal als Seed-Color; der Nutzer kann auf Wunsch eine Farbe vorgeben.

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
