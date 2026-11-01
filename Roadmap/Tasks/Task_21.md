# Task_21: Bugfix: Dashboard-Layout (Liste scrollt unter die AppBar)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_21.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Auf dem Dashboard (`WidgetsDashboardScreen`) wird die Widget-Liste oben unter der AppBar abgeschnitten, darunter bleibt viel leere Fläche (Nutzer-Screenshot: erste Karte angeschnitten, `MULTI_VALUE • environment [Multi]` ragt unter die Leiste). Das Layout muss korrekt sein: Inhalt beginnt unterhalb der AppBar, scrollt sauber, Leerzustand und Liste sind sauber dargestellt.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Keine (erster Task des Meilensteins 4).
- **Relevantes Vorwissen:** `lib/presentation/screens/dashboard/widgets_dashboard_screen.dart`. Bugfix beginnt zwingend mit einem Test, der den Fehler reproduziert (Widget-Test, der die Position der ersten Karte relativ zur AppBar prüft, auch mit vielen Einträgen und kleinem Viewport). Die Ursache ist noch unbekannt (z. B. `extendBody`/`SafeArea`/Padding, verschachtelte Scroll-Views). Das große Redesign folgt erst in Task_31, hier nur die Fehlerbehebung.

## Umfang

**Gehört dazu:**

- Ursache im Dashboard-Layout finden und beheben.
- Reproduzierender Widget-Test (Red), dann Fix (Green).
- Prüfen, ob der Widget-Editor und die Verbindungs-Screens denselben Fehler haben, und ggf. mitbeheben.

**Gehört nicht dazu:**

- Visuelles Redesign, Typ-Kacheln (Task_31).
- Änderungen an Widget-Logik oder Kontrakt.

## Umsetzungsschritte

1. Datei in `RUN_Task_21.md` umbenennen.
2. Layout-Code lesen, Hypothese zur Ursache formulieren.
3. Failing Widget-Test schreiben (kleiner Viewport, 1 bis 10 Widgets, Leerzustand).
4. Minimalen Fix umsetzen, Test grün.
5. Gleiche Prüfung für Editor- und Verbindungs-Screens, bei Befund jeweils erst Test.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/presentation/screens/dashboard/widgets_dashboard_screen_test.dart` (erweitern, bestehende Tests nicht ändern).
- Falls der Editor betroffen ist: `test/presentation/screens/editor/widget_editor_screen_test.dart`.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] Erste Karte liegt vollständig unterhalb der AppBar, belegt durch Widget-Test.
- [ ] Test schlug vor dem Fix nachweislich fehl.
- [ ] Liste ist scrollbar und Leerzustand ist sauber zentriert.
- [ ] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Ursache unbekannt; falls sie nur auf einem echten Gerät auftritt (z. B. Edge-to-Edge/System-Insets Android 15), im Test per `MediaQuery`-Padding simulieren und das hier festhalten.

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
