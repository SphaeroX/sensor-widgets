# Task_30: Native Gradienten & Chart-Style (Android Glance, iOS WidgetKit)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt. Beachte zusätzlich die `AGENTS.md` im Projekt-Root (striktes TDD, keine neuen Dependencies).
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_30.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Der Farbverlauf nach Wert und die Chart-Optionen aus Task_29 erscheinen auch in den echten Homescreen-Widgets auf Android und iOS.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_29 und Task_25 abgeschlossen.
- **Relevantes Vorwissen:** Android Glance hat kein freies Canvas; der Chart wird vermutlich als Bitmap gezeichnet (`glance/chart/`, `ChartMathAndFormatter.kt`). iOS nutzt Swift Charts, wo `LinearGradient` per `foregroundStyle` möglich ist. iOS-Code ist nur durch einen grünen GitHub-Actions-Lauf verifiziert; lokal wird nichts über iOS behauptet. Offenes Risiko: Bitmap-Größe und Speicherlimit von RemoteViews.

## Umfang

**Gehört dazu:**

- Kotlin: `chartStyle` parsen, Farbinterpolation (gleiche Fixtures wie Dart), Bitmap-Rendering mit Verlauf.
- Swift: `chartStyle` parsen, Gradient in Swift Charts.
- Fallback auf einfarbige Linie bei ungültigen Stopps.

**Gehört nicht dazu:**

- Hintergrund, Rundung und Schriftgrößen (Task_32).

## Umsetzungsschritte

1. Datei in `RUN_Task_30.md` umbenennen.
2. Fixtures aus Task_29 lesen.
3. Kotlin: Interpolations-Test (Red/Green), dann Rendering.
4. Swift: Parser- und Interpolations-Tests (CI), dann View.
5. Speicher-/Größenbudget des Bitmaps prüfen und dokumentieren.

## Tests

Tests liegen permanent im Projekt-Testverzeichnis: `test/` (spiegelt `lib/`), `integration_test/`, `android/app/src/test/` und `ios/` (siehe `docs/testing.md`). Ein Ordner `tests/` existiert in diesem Flutter-Projekt bewusst nicht. Es gilt TDD: erst fehlschlagender Test, dann Code.

- Android JUnit (Interpolation, Parser, Chart-Math); Bitmap-Rendering soweit per Robolectric/JVM testbar, sonst als manueller Test auf dem Gerät dokumentieren.
- Swift-Tests (CI).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] Farbwerte der Kotlin-Interpolation stimmen mit den Dart-Fixtures überein.
- [x] Gradient ist auf einem Android-Gerät sichtbar (manuelle Prüfung vom Nutzer, im Task festgehalten) oder als nicht prüfbar markiert.
- [x] iOS: Code und Tests vorhanden, CI-Ergebnis festgehalten oder ausstehend.
- [x] Standard-Toolchain grün: `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed .`; bei Android-Änderungen zusätzlich `cd android && ./gradlew test` und `./gradlew :app:ktlintCheck`.

## Offene Fragen / Annahmen

- Kann Glance den Bitmap-Chart in allen Widget-Größen ohne `TransactionTooLargeException` ausliefern? Größenobergrenze festlegen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent im Testverzeichnis und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks, `Roadmap/README.md` und `docs/` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Android: `ChartStyle`/`ColorStop`, Parser, `ChartColor` (gegen `color_interpolation_cases.json` getestet), `ChartRenderPlan` (rein geometrisch, JVM-testbar), `renderChart` im Bitmap-Renderer, `WidgetUiState.chartValues/chartStyle`. iOS: `ChartStyle.swift` (Modelle + `ChartColor`), `StyledHistoryChart` mit Gradient/Flaeche/Gitter/Achsen/Min-Max, `WidgetDefinition.chartStyle`, `ChartStyleTests`.
- **Learnings & Stolpersteine:** Bitmap-Zeichnen selbst ist auf der JVM nicht testbar (android.jar-Stubs); deshalb wurde die Geometrie in `ChartRenderPlan` ausgelagert und nur das duenne Zeichnen bleibt ungetestet. Bitmap-Budget: max. 600x240 px (ca. 576 KB); der Aufruf nutzt 300x100 (ca. 120 KB). `ktlintFormat` formatiert Einzeiler um (z. B. `validSorted`).
- **Wichtige Entscheidungen und ihre Gründe:** Der Gradient laeuft ueber den Datenbereich der Reihe (identisch zu Dart). Swift Charts: Y-Domain = Datenbereich, damit der Bounding-Box-Gradient der Linie zu den Werten passt.
- **Auswirkungen auf Folge-Tasks:** Task_32 (Optik) kann Hintergrund/Schrift ergaenzen; `appearance` wird neben `chartStyle` geparst. Task_33 (E2E) sollte den manuellen Test "Gradient auf Android-Geraet sichtbar" und die iOS-Optik als offene, nicht automatisiert pruefbare Punkte fuehren.
- **Hinweise zu Tests und Befehlen:** Android `ChartStyleTest`; iOS `ChartStyleTests` (CI). **Nicht pruefbar ohne Geraet:** Sichtbarkeit des Gradienten im echten Android-Widget und das Aussehen in WidgetKit (kein Geraet/Mac verfuegbar); vom Nutzer manuell zu pruefen.
