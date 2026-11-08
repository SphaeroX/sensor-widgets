# Testing strategy

> When to read: before writing tests or changing test configuration.

## Test suites
- Dart/Flutter: `flutter_test` (unit and widget tests), `integration_test`, `mocktail` for mocks.
- iOS widget logic: XCTest or Swift Testing. Runs only in CI on macOS because there is no local Mac.
- Android widget logic: JUnit 4/5 with kotlinx-coroutines-test.

Reason: one standard suite per language, all runnable from the command line.

## TDD workflow (mandatory)
1. Red: write a test, run it, confirm it fails.
2. Green: write the minimal code until it passes.
3. Refactor: clean up; tests stay green.

## Commands

Verified in project environment:

```bash
flutter test                                                    # all Dart tests
flutter test test/path/to/file_test.dart                        # one file
flutter test --plain-name "<test name>"                         # one test
flutter test integration_test                                   # needs an emulator or device (wraps the headless flows of test/)
cd android && ./gradlew test                                    # all Android unit tests
cd android && ./gradlew :app:testDebugUnitTest --tests "<fully.qualified.Class>"  # one Android test class
cd android && ./gradlew :app:ktlintCheck                        # ktlint check
```

iOS (CI only via `macos-latest` runner):

```bash
swift test --package-path ios                                    # Swift unit tests against fixtures
xcodebuild test -workspace ios/Runner.xcworkspace -scheme <scheme> -destination 'platform=iOS Simulator,name=<device>'
```

Agents cannot run iOS tests locally. Push and read the GitHub Actions result.

## Milestone 4 coverage
- End-to-end (headless, runs in `flutter test`): `test/e2e_formula_gradient_flow_test.dart` builds an IAQ history chart purely by tapping (type tile, IAQ template, schema pickers for the variables, gap policy, gradient preset, area fill, appearance) and inspects the stored bridge JSON; `integration_test/formula_gradient_flow_test.dart` runs the same flow on a device.
- Widget as code: `test/domain/widget_code/widget_code_codec_test.dart` (encode/decode/validation), `test/presentation/help/formula_llm_prompt_test.dart` (prompts, incl. decoding the prompt's JSON example), `test/presentation/screens/editor/widget_editor_code_test.dart` (code area in the editor: always visible, apply, errors, copy). The system share sheet is not covered (injected via `onSharePrompt` in tests).
- Regression of old widget JSONs: `test/domain/models/widget_definition_regression_test.dart` (milestone 1 to 3 fixtures must parse and must not gain milestone 4 fields).
- Shared contract fixtures read by Dart, Kotlin and Swift: `fixtures/formula/evaluator_cases.json` (`v2_*` sections), `fixtures/chart/color_interpolation_cases.json`, `fixtures/influx/bucketed_multi_field_response.json`, `fixtures/widget_definitions/widget_definition_{formula_steps,multi_formula,chart_style,appearance}.json`.
- Threshold notifications: `fixtures/alerts/evaluation_cases.json` is run by `alerts/AlertEvaluatorTest.kt` and `ios/SensorWidgetsTests/AlertTests.swift`; format fixture `fixtures/widget_definitions/widget_definition_alerts.json` by those two and `test/domain/models/alert_rule_test.dart`. Also `alerts/AlertMessageTest.kt`, `worker/WidgetRefreshWorkerAlertTest.kt` (once per crossing over several refreshes, MockWebServer), `test/presentation/widgets/editor/alert_rules_editor_test.dart`, `test/presentation/screens/editor/widget_editor_screen_alerts_test.dart` (permission service mocked via `notificationPermissionProvider`), `test/data/platform/notification_permission_test.dart` (mocked method channel). Not automatable: the real permission prompt and notification posting (`AlertNotifier`, `MainActivity`, `AppDelegate`). Manual check on Android: add a rule below the current value, allow notifications, tap ↻, a notification must appear once; a second ↻ must not repeat it.
- Plain HTTP on Android: `ManifestNetworkTest.kt` reads `src/main/AndroidManifest.xml` and requires `usesCleartextTraffic`. Manual check: an `http://` connection, place a widget, tap ↻, the timestamp must change.
- Dashboard card live data: `test/presentation/screens/dashboard/widgets_dashboard_live_preview_test.dart`.
- Tag filter sheet: `tag_filter_editor_test.dart` covers scrolling a long tag-value list (`tag_filter_sheet_body`).
- Network error grace: `worker/NetworkErrorGraceTest.kt`, `worker/WidgetRefreshWorkerNetworkTest.kt` (server started and shut down, so connecting fails), Swift `AlertTests` (grace section). Manual check: flight mode, tap ↻, the last values must stay.
- Android widget sizing, picker insets and refresh notification: `glance/WidgetSizingTest.kt` (incl. the ↻ tap target size), `glance/ConfigScreenInsetsTest.kt`, `worker/WidgetRefreshRunnerTest.kt` (JVM unit tests). The Glance/WorkManager wiring itself (receiver scheduling, `refreshAll`, `SizeMode.Exact` recomposition on resize) needs a device: place a history chart widget, resize it (chart must grow), tap ↻ (timestamp must change within seconds), add a widget via the picker (title and first entry must not sit under the status bar).
- Windows tip: if `./gradlew test` fails with "Unable to delete directory" or "AccessDeniedException" (directories under `build/` can carry the ReadOnly attribute; clearing it with PowerShell `Attributes -band -bnot ReadOnly` also works), remove `build/app/intermediates/assets/debug` and `build/app/test-results` (and clear ReadOnly under `build/app`, e.g. `tmp/kotlin-classes`) and run again; `./gradlew :app:ktlintFormat` fixes ktlint findings.
- Not automatable here (documented manual checks): gradient and appearance in a real Android widget (Glance bitmap/background, corner radius below Android 12) and in WidgetKit (needs a device or Mac).

## Release tooling
- `test/tool/verify_release_signing_test.dart` covers the fingerprint parsing of `tool/verify_release_signing.dart` with keytool output (German locale) and apksigner output: upload key, debug key, unsigned. Manual check against real files: `dart run tool/verify_release_signing.dart <file> android/upload-cert.sha256` (for APKs set `ANDROID_HOME`).
- The fastlane lane and the Play upload (`.github/workflows/play-internal.yml`) are not testable locally (no Ruby, needs the Play service account); they are verified only by a real workflow run.

## Localization
- `test/flutter_test_config.dart` simulates a German device (`localesTestValue = [de_DE]`) before every Dart test, because most widget tests assert the German texts. Test `MaterialApp`s pass `AppLocalizations.localizationsDelegates` and `supportedLocales`. Tests of the English UI call `useEnglishDeviceLocale()` (`test/l10n/english_locale.dart`); the connection screen tests run in English.
- Pure Dart tests that need texts use `lookupAppLocalizations(const Locale('de'))` (or `'en'`).
- `test/l10n/app_locale_test.dart`: language resolution (German, Austrian German, English, Hindi falls back to English, a later supported language wins). `test/l10n/english_*_test.dart`: English screens, editor cards, help and prompts. `test/l10n/formula_error_text_test.dart`: every `FormulaErrorKind` in both languages.
- `integration_test/` wrappers pin German in `setUp`, because devices can use any language (not run locally, needs a device).
- Android: JVM tests have no Android resources, so `l10n/TestTexts.kt` reads `src/main/res/values*/strings.xml` directly (`TestTexts.german`/`english`, missing texts fall back to English like Android). `l10n/WidgetTextsTest.kt` checks that `values-de` has exactly the keys of `values`.
- iOS: `WidgetTextsTests.swift` (language choice, fallback, completeness, English texts); `AlertTests` and `FormulaSeriesTests` set `WidgetTexts.current = .german` in `setUp`. CI only.
- Windows: `flutter gen-l10n` refuses to write when `lib/l10n` or `lib/l10n/generated` carries the ReadOnly attribute ("doesn't allow reading and writing"); clear it (PowerShell `Attributes -band -bnot ReadOnly`) and run again.

## README screenshots
- `screenshot_test/` (outside `test/`, so plain `flutter test` skips it and runs with the default English locale) renders the README images into `docs/screenshots/*.png`: one image per widget type (`WidgetLivePreviewCard` with fixed demo data) and app screens (dashboard, add connection, widget editor with live preview, formula templates, formula editor, formula preview) driven by taps like the e2e tests.
- Run: `flutter test screenshot_test`. CI: `.github/workflows/screenshots.yml` (manual `workflow_dispatch`) runs the same command on Ubuntu and commits changed PNGs.
- `support/screenshot_harness.dart`: loads Roboto and the Material icons from the Flutter SDK (`bin/cache/artifacts/material_fonts`, found via `FLUTTER_ROOT` or the `flutter_tester` path; Roboto also stands in for `monospace`), fakes storage, token store and `InfluxApiClient` (deterministic SEN66-like data), and installs `WriteOnlyGoldenComparator`, which only writes images and never compares them (font rendering differs between machines). These are not regression tests.
- The SDK Roboto lacks subscript digits (e.g. `₂`), which render as boxes in screenshots only; demo titles use `CO2`.

## Which tests to run when
- Changes in `lib/`: the Dart tests of that area.
- Changes in `android/`: the Android unit tests.
- Changes in `ios/`: the iOS tests via CI.
- Changes to shared fixtures or the widget-definition format: all three suites.

## Done criteria
A task is done when all of this holds:
1. Tests of the affected area pass (commands above).
2. Format and lint are clean (commands in `docs/code-style.md`).
3. No existing test was changed, deleted, or weakened unless explicitly requested.

## Hard rules
- On a failing test, fix the implementation, not the test.
- At most 3 repair attempts per failing test; then stop and report.
- If an existing test must change: state the reason and wait for approval.

## Test structure
- Test types: unit and widget tests; integration tests only for core flows; native unit tests for query, parse, and threshold logic.
- Location: Dart tests in `test/` mirroring `lib/`; integration tests in `integration_test/`; native tests in the platform test targets.
- Naming: `<file>_test.dart`; Swift `<Type>Tests`; Kotlin `<Type>Test`.
- Test data: InfluxDB responses come from the shared fixtures (see `docs/conventions.md`). Automated tests never call a live InfluxDB.

---
Maintenance: update this file immediately when the testing suite or strategy changes.
