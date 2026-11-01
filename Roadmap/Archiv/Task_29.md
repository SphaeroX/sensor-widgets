# Task_29: Gradient- und Chart-Style-Kontrakt + Dart-Chart & Vorschau

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_29.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Der Verlaufschart kann die Linie nach Y-Wert einfärben (frei konfigurierbare Farb-Stopps, z. B. 0 rot, 50 gelb, 100 grün, Richtung beliebig) und optional eine Fläche mit passendem Verlauf füllen. Zusätzliche Chart-Optionen: Gitter, Achsenbeschriftung, Min/Max-Markierung.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_24 abgeschlossen.
- **Relevantes Vorwissen:** Neuer optionaler Kontrakt-Block `chartStyle` (`colorStops: [{value, color}]`, `fillArea`, `showGrid`, `showAxes`, `markMinMax`, `lineWidth`). Kontrakt-Änderungen sind rein additiv (neue optionale Felder); `schemaVersion` bleibt 1 und alte Fixtures parsen unverändert. Farben als `#RRGGBB`. Dart-Seite rendert per `CustomPainter` (keine neue Dependency). Vorschau im Editor nutzt denselben Painter.

## Umfang

**Gehört dazu:**

- Kontrakt und Dart-Modell `ChartStyle`, Fixtures (Dart, Kotlin und Swift lesen sie in Task_30).
- Farb-Interpolation zwischen Stopps als reine Funktion (per Test abgesichert, Grenzfälle: Wert unter/über erstem/letztem Stopp, nur ein Stopp, unsortierte Stopps).
- Chart-Painter mit Gradient entlang der Y-Achse.
- Editor-Abschnitt „Farbverlauf“: Stopps hinzufügen/löschen, Wert und Farbe setzen, Presets (grün nach rot, rot nach grün).

**Gehört nicht dazu:**

- Native Umsetzung (Task_30).
- Allgemeine Widget-Optik (Task_32).

## Umsetzungsschritte

1. Datei in `RUN_Task_29.md` umbenennen.
2. Farb-Interpolation per TDD.
3. Modell und JSON per TDD.
4. Painter: Golden- oder Painter-Tests soweit praktikabel.
5. Editor-UI und Vorschau anbinden.
6. Fixtures für native Seiten anlegen.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- `test/domain/models/chart_style_test.dart`, `test/presentation/widgets/preview/chart_painter_test.dart`, Editor-Widget-Tests.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] Farbwert zu Y-Wert wird korrekt interpoliert (Tests inkl. Grenzfälle).
- [x] Vorschau zeigt Verlauf nach Wert, belegt durch Painter-/Widget-Test.
- [x] Widgets ohne `chartStyle` sehen unverändert aus.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Bei Gradient je Y-Wert vs. je Segment: Annahme Verlauf kontinuierlich je Höhe, Linie hoch=rot oder grün wird allein durch die Stopps bestimmt.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `ChartStyle`/`ColorStop`, Farb-Interpolation und Gradient-Aufbau, `HistoryChartPainter`, `ChartStyleEditor`, Vorschau-Anbindung, Editor-Integration, Fixtures (`widget_definition_chart_style.json`, `color_interpolation_cases.json`). Painter-Tests laufen ueber einen aufzeichnenden `Canvas` (kein Golden, plattformunabhaengig).
- **Learnings & Stolpersteine:** `Colors.blue` (MaterialColor) ist nicht `==` zu einer gleichfarbigen `Color`: in Tests `toARGB32()` vergleichen. Widget-Tests, die zwei Editor-Varianten nacheinander pumpen, brauchen einen `UniqueKey` am `ProviderScope`, sonst bleibt der State erhalten.
- **Wichtige Entscheidungen und ihre Gründe:** Farbe wird hex-textbasiert eingegeben (kein Color-Picker-Package, keine neue Dependency). Fuellung nutzt denselben Gradient mit Alpha 0x59. Gradient laeuft ueber den sichtbaren Datenbereich (min..max der Reihe).
- **Auswirkungen auf Folge-Tasks:** Task_30 muss `chartStyle` in Kotlin und Swift parsen und `interpolateColor`/`buildGradient` anhand von `fixtures/chart/color_interpolation_cases.json` nachbauen; Rundung half away from zero. Task_32 kann `appearance` neben `chartStyle` ergaenzen; Task_31 beachtet die Keys `chart_style_editor`, `preset_*`, `color_stop_*`.
- **Hinweise zu Tests und Befehlen:** `flutter test test/domain/chart test/domain/models/chart_style_test.dart test/presentation/widgets/preview/history_chart_painter_test.dart test/presentation/widgets/editor/chart_style_editor_test.dart`.
